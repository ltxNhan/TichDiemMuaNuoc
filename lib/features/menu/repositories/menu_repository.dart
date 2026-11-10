import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/topping_model.dart';

class MenuRepository {
  final DioClient _dioClient;

  MenuRepository(this._dioClient);

  bool get _isSupabaseConfigured {
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  // ==========================================
  // 1. QUẢN LÝ DANH MỤC (CATEGORIES) SUPABASE
  // ==========================================

  Future<List<CategoryModel>> getCategories() async {
    // 1. Ưu tiên lấy từ Supabase (bảng categories)
    if (_isSupabaseConfigured) {
      try {
        final supabase = Supabase.instance.client;
        final res = await supabase
            .from('categories')
            .select()
            .order('display_order', ascending: true);

        if (res.isNotEmpty) {
          final list = res.map((json) => CategoryModel.fromJson(json)).toList();
          if (!list.any((c) => c.id == 1 || c.name.toLowerCase() == 'tất cả')) {
            list.insert(
              0,
              const CategoryModel(
                id: 1,
                name: 'Tất cả',
                iconName: 'all_inclusive',
                displayOrder: 0,
                isActive: true,
              ),
            );
          }
          _fallbackCategories = List<CategoryModel>.from(list);
          return List<CategoryModel>.from(list);
        }
      } catch (e) {
        debugPrint('Supabase getCategories error: $e');
      }
    }

    // 2. Thử qua REST API / Dio
    try {
      final response = await _dioClient.dio.get(AppEndpoints.categories);
      if (response.data['success'] == true) {
        final list = response.data['data'] as List;
        return list.map((json) => CategoryModel.fromJson(json)).toList();
      }
    } catch (_) {}

    // 3. Fallback: Luôn tạo bản sao List mới
    return List<CategoryModel>.from(_fallbackCategories);
  }

  Future<CategoryModel> addCategory(CategoryModel category) async {
    CategoryModel finalCategory = category;

    if (_isSupabaseConfigured) {
      try {
        final supabase = Supabase.instance.client;
        final insertData = <String, dynamic>{
          'name': category.name,
          'icon_name': category.iconName,
          'display_order': category.displayOrder,
          'is_active': category.isActive,
        };

        final res = await supabase
            .from('categories')
            .insert(insertData)
            .select()
            .single();

        finalCategory = CategoryModel.fromJson(res);
      } catch (e) {
        debugPrint('Supabase addCategory error: $e');
      }
    }

    final idx = _fallbackCategories.indexWhere(
      (c) => c.id == finalCategory.id || c.name.toLowerCase() == finalCategory.name.toLowerCase(),
    );
    if (idx != -1) {
      _fallbackCategories[idx] = finalCategory;
    } else {
      _fallbackCategories.add(finalCategory);
    }

    return finalCategory;
  }

  Future<void> updateCategory(CategoryModel category) async {
    if (_isSupabaseConfigured) {
      try {
        final supabase = Supabase.instance.client;
        await supabase
            .from('categories')
            .update({
              'name': category.name,
              'icon_name': category.iconName,
              'display_order': category.displayOrder,
              'is_active': category.isActive,
            })
            .eq('id', category.id);
      } catch (e) {
        debugPrint('Supabase updateCategory error: $e');
      }
    }

    final idx = _fallbackCategories.indexWhere((c) => c.id == category.id);
    if (idx != -1) {
      _fallbackCategories[idx] = category;
    }
  }

  Future<void> deleteCategory(int id) async {
    if (_isSupabaseConfigured) {
      try {
        final supabase = Supabase.instance.client;
        await supabase.from('categories').delete().eq('id', id);
      } catch (e) {
        debugPrint('Supabase deleteCategory error: $e');
      }
    }

    _fallbackCategories.removeWhere((c) => c.id == id);
  }

  Future<void> toggleCategoryActive(int id, bool isActive) async {
    if (_isSupabaseConfigured) {
      try {
        final supabase = Supabase.instance.client;
        await supabase
            .from('categories')
            .update({'is_active': isActive})
            .eq('id', id);
      } catch (e) {
        debugPrint('Supabase toggleCategoryActive error: $e');
      }
    }

    final idx = _fallbackCategories.indexWhere((c) => c.id == id);
    if (idx != -1) {
      final current = _fallbackCategories[idx];
      _fallbackCategories[idx] = current.copyWith(isActive: isActive);
    }
  }

  // ==========================================
  // 2. QUẢN LÝ MÓN ĂN (PRODUCTS) SUPABASE
  // ==========================================

  Future<List<ProductModel>> getProducts({int? categoryId, String? search, bool? bestsellerOnly}) async {
    // 1. Ưu tiên lấy từ Supabase bảng products
    if (_isSupabaseConfigured) {
      try {
        final supabase = Supabase.instance.client;
        var query = supabase.from('products').select();

        if (categoryId != null && categoryId != 1) {
          query = query.eq('category_id', categoryId);
        }
        if (bestsellerOnly == true) {
          query = query.eq('is_bestseller', true);
        }

        final res = await query.order('id', ascending: false);
        if (res.isNotEmpty) {
          var list = res.map((json) => ProductModel.fromJson(json)).toList();
          if (search != null && search.isNotEmpty) {
            final q = search.toLowerCase();
            list = list
                .where((p) => p.name.toLowerCase().contains(q) || (p.description?.toLowerCase().contains(q) ?? false))
                .toList();
          }
          if (categoryId == null || categoryId == 1) {
            _fallbackProducts = List<ProductModel>.from(list);
          }
          return List<ProductModel>.from(list);
        }
      } catch (e) {
        debugPrint('Supabase getProducts error: $e');
      }
    }

    // 2. Thử qua REST API / Dio
    try {
      final queryParams = <String, dynamic>{};
      if (categoryId != null && categoryId != 1) queryParams['category_id'] = categoryId;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (bestsellerOnly == true) queryParams['bestseller'] = true;

      final response = await _dioClient.dio.get(
        AppEndpoints.products,
        queryParameters: queryParams,
      );

      if (response.data['success'] == true) {
        final list = response.data['data'] as List;
        return list.map((json) => ProductModel.fromJson(json)).toList();
      }
    } catch (_) {}

    // 3. Fallback: Luôn clone list mới để không chia sẻ tham chiếu
    var list = List<ProductModel>.from(_fallbackProducts);
    if (categoryId != null && categoryId != 1) {
      list = list.where((p) => p.categoryId == categoryId).toList();
    }
    if (bestsellerOnly == true) {
      list = list.where((p) => p.isBestseller).toList();
    }
    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      list = list
          .where((p) => p.name.toLowerCase().contains(q) || (p.description?.toLowerCase().contains(q) ?? false))
          .toList();
    }
    return List<ProductModel>.from(list);
  }

  Future<ProductModel> addProduct(ProductModel product) async {
    ProductModel finalProduct = product;

    if (_isSupabaseConfigured) {
      try {
        final supabase = Supabase.instance.client;
        final insertData = <String, dynamic>{
          'category_id': product.categoryId,
          'name': product.name,
          'description': product.description,
          'base_price': product.basePrice,
          'image_url': product.imageUrl,
          'is_bestseller': product.isBestseller,
          'is_available': product.isAvailable,
        };

        final res = await supabase
            .from('products')
            .insert(insertData)
            .select()
            .single();

        finalProduct = ProductModel.fromJson(res);
      } catch (e) {
        debugPrint('Supabase addProduct error: $e');
      }
    }

    final idx = _fallbackProducts.indexWhere((p) => p.id == finalProduct.id);
    if (idx != -1) {
      _fallbackProducts[idx] = finalProduct;
    } else {
      _fallbackProducts.insert(0, finalProduct);
    }

    return finalProduct;
  }

  Future<void> updateProduct(ProductModel product) async {
    if (_isSupabaseConfigured) {
      try {
        final supabase = Supabase.instance.client;
        await supabase
            .from('products')
            .update({
              'category_id': product.categoryId,
              'name': product.name,
              'description': product.description,
              'base_price': product.basePrice,
              'image_url': product.imageUrl,
              'is_bestseller': product.isBestseller,
              'is_available': product.isAvailable,
            })
            .eq('id', product.id);
      } catch (e) {
        debugPrint('Supabase updateProduct error: $e');
      }
    }

    final idx = _fallbackProducts.indexWhere((p) => p.id == product.id);
    if (idx != -1) {
      _fallbackProducts[idx] = product;
    }
  }

  Future<void> deleteProduct(int id) async {
    // Xóa trực tiếp khỏi Supabase
    if (_isSupabaseConfigured) {
      try {
        final supabase = Supabase.instance.client;
        await supabase.from('products').delete().eq('id', id);
      } catch (e) {
        debugPrint('Supabase deleteProduct error: $e');
      }
    }

    _fallbackProducts.removeWhere((p) => p.id == id);
  }

  Future<void> toggleAvailability(int id, bool newStatus) async {
    if (_isSupabaseConfigured) {
      try {
        final supabase = Supabase.instance.client;
        await supabase
            .from('products')
            .update({'is_available': newStatus})
            .eq('id', id);
      } catch (e) {
        debugPrint('Supabase toggleAvailability error: $e');
      }
    }

    final idx = _fallbackProducts.indexWhere((p) => p.id == id);
    if (idx != -1) {
      _fallbackProducts[idx] = _fallbackProducts[idx].copyWith(isAvailable: newStatus);
    }
  }

  void updatePrice(int id, double price) {
    if (_isSupabaseConfigured) {
      try {
        Supabase.instance.client
            .from('products')
            .update({'base_price': price})
            .eq('id', id);
      } catch (_) {}
    }
    final idx = _fallbackProducts.indexWhere((p) => p.id == id);
    if (idx != -1) {
      _fallbackProducts[idx] = _fallbackProducts[idx].copyWith(basePrice: price);
    }
  }

  Future<List<ToppingModel>> getToppings() async {
    try {
      final response = await _dioClient.dio.get(AppEndpoints.toppings);
      if (response.data['success'] == true) {
        final list = response.data['data'] as List;
        return list.map((json) => ToppingModel.fromJson(json)).toList();
      }
    } catch (_) {}
    return List<ToppingModel>.from(_fallbackToppings);
  }

  // Production Fallback Data
  static List<CategoryModel> _fallbackCategories = [
    const CategoryModel(id: 1, name: 'Tất cả', iconName: 'all_inclusive', displayOrder: 1, isActive: true),
    const CategoryModel(id: 2, name: 'Cà phê', iconName: 'coffee', displayOrder: 2, isActive: true),
    const CategoryModel(id: 3, name: 'Trà sữa', iconName: 'local_cafe', displayOrder: 3, isActive: true),
    const CategoryModel(id: 4, name: 'Trà trái cây', iconName: 'eco', displayOrder: 4, isActive: true),
    const CategoryModel(id: 5, name: 'Đá xay', iconName: 'ac_unit', displayOrder: 5, isActive: true),
    const CategoryModel(id: 6, name: 'Bánh & Snack', iconName: 'cake', displayOrder: 6, isActive: true),
  ];

  static const List<ToppingModel> _fallbackToppings = [
    ToppingModel(id: 1, name: 'Trân châu đen dẻo', price: 10000, isAvailable: true),
    ToppingModel(id: 2, name: 'Trân châu trắng giòn 3Q', price: 10000, isAvailable: true),
    ToppingModel(id: 3, name: 'Kem Cheese Macchiato béo mặn', price: 15000, isAvailable: true),
    ToppingModel(id: 4, name: 'Thạch dừa non tươi', price: 8000, isAvailable: true),
    ToppingModel(id: 5, name: 'Pudding trứng phô mai', price: 12000, isAvailable: true),
    ToppingModel(id: 6, name: 'Hạt sen Huế hầm đường phèn', price: 15000, isAvailable: true),
    ToppingModel(id: 7, name: 'Đào ngâm giòn ngọt (3 miếng)', price: 12000, isAvailable: true),
  ];

  static const List<ProductSizeModel> _drinkSizes = [
    ProductSizeModel(id: 1, productId: 0, sizeName: 'S', extraPrice: 0),
    ProductSizeModel(id: 2, productId: 0, sizeName: 'M', extraPrice: 6000),
    ProductSizeModel(id: 3, productId: 0, sizeName: 'L', extraPrice: 12000),
  ];

  static const List<ProductSizeModel> _snackSizes = [
    ProductSizeModel(id: 1, productId: 0, sizeName: 'Tiêu chuẩn', extraPrice: 0),
  ];

  static List<ProductModel> _fallbackProducts = [
    // ==========================================
    // 1. CÀ PHÊ (CATEGORY 2)
    // ==========================================
    ProductModel(
      id: 101,
      categoryId: 2,
      name: 'Cà Phê Muối Biển',
      description: 'Cà phê Robusta Đắk Lắk đậm đà hòa quyện cùng lớp kem muối biển béo mặn độc quyền BrewPoint',
      basePrice: 38000,
      imageUrl: 'https://images.unsplash.com/photo-1517701550927-30cf4ba1dba5?auto=format&fit=crop&w=600&q=80',
      isBestseller: true,
      isAvailable: true,
      sizes: _drinkSizes,
      availableToppings: _fallbackToppings,
    ),
    ProductModel(
      id: 102,
      categoryId: 2,
      name: 'Cà Phê Sữa Phin Đậm Đà',
      description: 'Phin truyền thống chắt lọc tinh hoa hạt Robusta Buôn Ma Thuột hòa quyện sữa đặc béo ngọt thơm ngậy',
      basePrice: 32000,
      imageUrl: 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?auto=format&fit=crop&w=600&q=80',
      isBestseller: true,
      isAvailable: true,
      sizes: _drinkSizes,
      availableToppings: _fallbackToppings,
    ),
    ProductModel(
      id: 103,
      categoryId: 2,
      name: 'Bạc Xỉu 3 Tầng Kem Sữa',
      description: 'Sự hòa quyện 3 tầng đẹp mắt giữa sữa đặc ngọt ngào, sữa tươi thanh trùng và lớp cà phê espresso thơm dịu',
      basePrice: 35000,
      imageUrl: 'https://images.unsplash.com/photo-1541167760496-1628856ab772?auto=format&fit=crop&w=600&q=80',
      isBestseller: false,
      isAvailable: true,
      sizes: _drinkSizes,
      availableToppings: _fallbackToppings,
    ),
    ProductModel(
      id: 104,
      categoryId: 2,
      name: 'Cold Brew Cam Vàng Mật Ong',
      description: 'Cà phê ủ lạnh 16 giờ từ hạt Arabica Cầu Đất kết hợp lát cam vàng mọng nước và mật ong hoa rừng thanh mát',
      basePrice: 48000,
      imageUrl: 'https://images.unsplash.com/photo-1517701604599-bb29b565090c?auto=format&fit=crop&w=600&q=80',
      isBestseller: false,
      isAvailable: true,
      sizes: _drinkSizes,
      availableToppings: _fallbackToppings,
    ),
    ProductModel(
      id: 105,
      categoryId: 2,
      name: 'Americano Đá Tươi Mát',
      description: 'Double shot espresso pha loãng với nước tinh khiết và đá lạnh, lưu giữ trọn vẹn hương vị hạt cà phê mộc',
      basePrice: 32000,
      imageUrl: 'https://images.unsplash.com/photo-1551030173-122aabc4489c?auto=format&fit=crop&w=600&q=80',
      isBestseller: false,
      isAvailable: true,
      sizes: _drinkSizes,
      availableToppings: _fallbackToppings,
    ),

    // ==========================================
    // 2. TRÀ SỮA (CATEGORY 3)
    // ==========================================
    ProductModel(
      id: 201,
      categoryId: 3,
      name: 'Trà Sữa Hoàng Gia Ceylon',
      description: 'Vị trà đen Ceylon thượng hạng kết hợp cùng sữa tươi béo ngậy và trân châu đường đen dẻo dai',
      basePrice: 45000,
      imageUrl: 'https://images.unsplash.com/photo-1558857563-b37cf5a7c2a7?auto=format&fit=crop&w=600&q=80',
      isBestseller: true,
      isAvailable: true,
      sizes: _drinkSizes,
      availableToppings: _fallbackToppings,
    ),
    ProductModel(
      id: 202,
      categoryId: 3,
      name: 'Cloudy Matcha Latte',
      description: 'Bột matcha Uji Nhật Bản nguyên chất với lớp foam sữa tươi bồng bềnh mịn màng, thơm mát thanh tao',
      basePrice: 52000,
      imageUrl: 'https://images.unsplash.com/photo-1536256263959-770b48d82b0a?auto=format&fit=crop&w=600&q=80',
      isBestseller: true,
      isAvailable: true,
      sizes: _drinkSizes,
      availableToppings: _fallbackToppings,
    ),
    ProductModel(
      id: 203,
      categoryId: 3,
      name: 'Hồng Trà Sữa Trân Châu Hoàng Kim',
      description: 'Cốt trà đỏ truyền thống nấu từ lá chè cổ thụ Tây Bắc, thơm lừng hương hoa cỏ mật ong và trân châu hoàng kim dai giòn',
      basePrice: 42000,
      imageUrl: 'https://images.unsplash.com/photo-1576092768241-dec231879fc3?auto=format&fit=crop&w=600&q=80',
      isBestseller: false,
      isAvailable: true,
      sizes: _drinkSizes,
      availableToppings: _fallbackToppings,
    ),
    ProductModel(
      id: 204,
      categoryId: 3,
      name: 'Ô Long Sữa Nướng Phô Mai',
      description: 'Trà Ô Long rang lửa mộc đậm hương khói caramel kết hợp lớp phô mai béo mặn sánh mịn phủ trên mặt ly',
      basePrice: 48000,
      imageUrl: 'https://images.unsplash.com/photo-1594488518042-498c47a505e6?auto=format&fit=crop&w=600&q=80',
      isBestseller: false,
      isAvailable: true,
      sizes: _drinkSizes,
      availableToppings: _fallbackToppings,
    ),

    // ==========================================
    // 3. TRÀ TRÁI CÂY (CATEGORY 4)
    // ==========================================
    ProductModel(
      id: 301,
      categoryId: 4,
      name: 'Trà Đào Cam Sả Tươi',
      description: 'Hương trà lài thanh khiết hòa quyện cùng đào miếng giòn ngọt, cam vàng mọng nước và mùi thơm sả tươi giải nhiệt đỉnh cao',
      basePrice: 45000,
      imageUrl: 'https://images.unsplash.com/photo-1556679343-c7306c1976bc?auto=format&fit=crop&w=600&q=80',
      isBestseller: true,
      isAvailable: true,
      sizes: _drinkSizes,
      availableToppings: _fallbackToppings,
    ),
    ProductModel(
      id: 302,
      categoryId: 4,
      name: 'Trà Vải Lài Thạch Sen Tuyết',
      description: 'Trà hoa lài hữu cơ kết hợp trái vải thiều mọng nước giòn ngọt cùng thạch sen tuyết thanh nhiệt cơ thể',
      basePrice: 46000,
      imageUrl: 'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?auto=format&fit=crop&w=600&q=80',
      isBestseller: true,
      isAvailable: true,
      sizes: _drinkSizes,
      availableToppings: _fallbackToppings,
    ),
    ProductModel(
      id: 303,
      categoryId: 4,
      name: 'Trà Dâu Tằm Macchiato',
      description: 'Dâu tằm Đà Lạt ủ đường phèn thanh mát kết hợp lớp macchiato kem cheese béo mặn ngậy đầu lưỡi',
      basePrice: 49000,
      imageUrl: 'https://images.unsplash.com/photo-1544787219-7f47ccb76574?auto=format&fit=crop&w=600&q=80',
      isBestseller: false,
      isAvailable: true,
      sizes: _drinkSizes,
      availableToppings: _fallbackToppings,
    ),
    ProductModel(
      id: 304,
      categoryId: 4,
      name: 'Trà Xoài Nhiệt Đới Nha Đam',
      description: 'Vị xoài cát Hòa Lộc ngọt lịm kết hợp nha đam giòn sần sật và chanh leo chua thanh tươi mới',
      basePrice: 42000,
      imageUrl: 'https://images.unsplash.com/photo-1534353473418-4cfa6c56fd38?auto=format&fit=crop&w=600&q=80',
      isBestseller: false,
      isAvailable: true,
      sizes: _drinkSizes,
      availableToppings: _fallbackToppings,
    ),

    // ==========================================
    // 4. ĐÁ XAY (CATEGORY 5)
    // ==========================================
    ProductModel(
      id: 401,
      categoryId: 5,
      name: 'Freeze Trà Xanh Bồng Bềnh',
      description: 'Matcha Uji Nhật xay nhuyễn mịn cùng sữa tươi và đá tuyết, phủ lớp kem bông tuyết whipping cream béo ngậy',
      basePrice: 55000,
      imageUrl: 'https://images.unsplash.com/photo-1572490122747-3968b75cc699?auto=format&fit=crop&w=600&q=80',
      isBestseller: true,
      isAvailable: true,
      sizes: _drinkSizes,
      availableToppings: _fallbackToppings,
    ),
    ProductModel(
      id: 402,
      categoryId: 5,
      name: 'Cà Phê Cốt Dừa Đá Xay',
      description: 'Nước cốt dừa Bến Tre béo thơm xay tuyết mát lạnh hòa quyện dòng espresso Robusta đắng đậm quyến rũ',
      basePrice: 52000,
      imageUrl: 'https://images.unsplash.com/photo-1578314670119-9ce7c3b99335?auto=format&fit=crop&w=600&q=80',
      isBestseller: false,
      isAvailable: true,
      sizes: _drinkSizes,
      availableToppings: _fallbackToppings,
    ),
    ProductModel(
      id: 403,
      categoryId: 5,
      name: 'Chocolate Cookie Crunch Freeze',
      description: 'Sốt socola đen thượng hạng xay cùng bánh quy oreo giòn rụm và sốt caramel thơm nức bùi béo',
      basePrice: 58000,
      imageUrl: 'https://images.unsplash.com/photo-1563805042-7684c019e1cb?auto=format&fit=crop&w=600&q=80',
      isBestseller: false,
      isAvailable: true,
      sizes: _drinkSizes,
      availableToppings: _fallbackToppings,
    ),

    // ==========================================
    // 5. BÁNH & SNACK (CATEGORY 6)
    // ==========================================
    ProductModel(
      id: 501,
      categoryId: 6,
      name: 'Croissant Bơ Tỏi Nướng Giòn',
      description: 'Bánh sừng bò nướng nóng giòn tan thơm lừng bơ Pháp nhập khẩu và sốt tỏi tây ngò rí đậm vị',
      basePrice: 32000,
      imageUrl: 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?auto=format&fit=crop&w=600&q=80',
      isBestseller: true,
      isAvailable: true,
      sizes: _snackSizes,
      availableToppings: const [],
    ),
    ProductModel(
      id: 502,
      categoryId: 6,
      name: 'Bánh Tiramisu Ý Cacao',
      description: 'Lớp bánh ladyfinger thấm đẫm rượu cà phê và kem phô mai mascarpone rắc bột cacao nguyên chất thơm bùi',
      basePrice: 42000,
      imageUrl: 'https://images.unsplash.com/photo-1571877227200-a0d98ea607e9?auto=format&fit=crop&w=600&q=80',
      isBestseller: true,
      isAvailable: true,
      sizes: _snackSizes,
      availableToppings: const [],
    ),
    ProductModel(
      id: 503,
      categoryId: 6,
      name: 'Mousse Chanh Leo Phô Mai',
      description: 'Cốt bánh mềm mịn chua ngọt thanh tao từ chanh leo tươi kết hợp phô mai cream cheese béo ngậy tan trong miệng',
      basePrice: 38000,
      imageUrl: 'https://images.unsplash.com/photo-1587314168485-3236d6710814?auto=format&fit=crop&w=600&q=80',
      isBestseller: false,
      isAvailable: true,
      sizes: _snackSizes,
      availableToppings: const [],
    ),
    ProductModel(
      id: 504,
      categoryId: 6,
      name: 'Bánh Mì Que Cay Hải Phòng (2 cái)',
      description: 'Bánh mì que nướng giòn rụm nhân pate gan heo béo bùi và tương ớt cay nồng chuẩn vị đặc sản Hải Phòng',
      basePrice: 22000,
      imageUrl: 'https://images.unsplash.com/photo-1509722747041-616f39b57569?auto=format&fit=crop&w=600&q=80',
      isBestseller: false,
      isAvailable: true,
      sizes: _snackSizes,
      availableToppings: const [],
    ),
  ];
}
