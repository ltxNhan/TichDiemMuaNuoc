import 'package:flutter/material.dart';

import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/topping_model.dart';
import '../repositories/menu_repository.dart';

class MenuProvider extends ChangeNotifier {
  final MenuRepository _repository;

  List<CategoryModel> _categories = [];
  List<ProductModel> _allProducts = [];
  List<ProductModel> _products = [];
  List<ProductModel> _bestsellers = [];
  List<ToppingModel> _toppings = [];

  int _selectedCategoryId = 1;
  String _searchQuery = '';
  bool _isLoading = false;

  MenuProvider(this._repository) {
    loadInitialData();
  }

  List<CategoryModel> get categories => _categories;
  List<ProductModel> get allProducts => _allProducts;
  List<ProductModel> get products => _products;
  List<ProductModel> get bestsellers => _bestsellers;
  List<ToppingModel> get toppings => _toppings;
  int get selectedCategoryId => _selectedCategoryId;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;

  Future<void> loadInitialData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final fetchedCats = await _repository.getCategories();
      final seenCatIds = <int>{};
      final uniqueCats = <CategoryModel>[];
      for (final c in fetchedCats) {
        if (!seenCatIds.contains(c.id)) {
          seenCatIds.add(c.id);
          uniqueCats.add(c);
        }
      }
      _categories = uniqueCats;

      _toppings = await _repository.getToppings();

      final fetchedProducts = await _repository.getProducts();
      final seenProdIds = <int>{};
      final uniqueProducts = <ProductModel>[];
      for (final p in fetchedProducts) {
        if (!seenProdIds.contains(p.id)) {
          seenProdIds.add(p.id);
          uniqueProducts.add(p);
        }
      }
      _allProducts = uniqueProducts;
      _bestsellers = _allProducts.where((p) => p.isBestseller).toList();
      await fetchProducts();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectCategory(int categoryId) async {
    if (_selectedCategoryId == categoryId) return;
    _selectedCategoryId = categoryId;
    await fetchProducts();
  }

  Future<void> setSearchQuery(String query) async {
    _searchQuery = query;
    await fetchProducts();
  }

  Future<void> fetchProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final rawList = await _repository.getProducts(
        categoryId: _selectedCategoryId,
        search: _searchQuery,
      );
      final seenIds = <int>{};
      final uniqueList = <ProductModel>[];
      for (final p in rawList) {
        if (!seenIds.contains(p.id)) {
          seenIds.add(p.id);
          uniqueList.add(p);
        }
      }
      _products = uniqueList;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleProductAvailability(int productId) {
    final idx = _allProducts.indexWhere((p) => p.id == productId);
    if (idx != -1) {
      final newStatus = !_allProducts[idx].isAvailable;
      _repository.toggleAvailability(productId, newStatus);

      _allProducts[idx] = _allProducts[idx].copyWith(isAvailable: newStatus);

      final pIdx = _products.indexWhere((p) => p.id == productId);
      if (pIdx != -1) {
        _products[pIdx] = _products[pIdx].copyWith(isAvailable: newStatus);
      }

      final bIdx = _bestsellers.indexWhere((p) => p.id == productId);
      if (bIdx != -1) {
        _bestsellers[bIdx] = _bestsellers[bIdx].copyWith(
          isAvailable: newStatus,
        );
      }

      notifyListeners();
    }
  }

  void addProduct(ProductModel product) {
    _repository.addProduct(product);

    // Kiểm tra xem đã có trong _allProducts chưa, tuyệt đối không chèn trùng lặp
    final existingIdx = _allProducts.indexWhere((p) => p.id == product.id);
    if (existingIdx != -1) {
      _allProducts[existingIdx] = product;
    } else {
      _allProducts.insert(0, product);
    }

    // Dedup _allProducts theo ID
    final seenIds = <int>{};
    final uniqueAll = <ProductModel>[];
    for (final p in _allProducts) {
      if (!seenIds.contains(p.id)) {
        seenIds.add(p.id);
        uniqueAll.add(p);
      }
    }
    _allProducts = uniqueAll;

    // Cập nhật lại _products hiển thị
    if (product.categoryId == _selectedCategoryId || _selectedCategoryId == 1) {
      final pIdx = _products.indexWhere((p) => p.id == product.id);
      if (pIdx != -1) {
        _products[pIdx] = product;
      } else {
        _products.insert(0, product);
      }
    }

    if (product.isBestseller) {
      final bIdx = _bestsellers.indexWhere((p) => p.id == product.id);
      if (bIdx != -1) {
        _bestsellers[bIdx] = product;
      } else {
        _bestsellers.insert(0, product);
      }
    }

    notifyListeners();
  }

  void updateProduct(ProductModel product) {
    _repository.updateProduct(product);

    final allIdx = _allProducts.indexWhere((p) => p.id == product.id);
    if (allIdx != -1) {
      _allProducts[allIdx] = product;
    }

    final pIdx = _products.indexWhere((p) => p.id == product.id);
    if (pIdx != -1) {
      if (product.categoryId == _selectedCategoryId ||
          _selectedCategoryId == 1) {
        _products[pIdx] = product;
      } else {
        _products.removeAt(pIdx);
      }
    } else if (product.categoryId == _selectedCategoryId ||
        _selectedCategoryId == 1) {
      _products.insert(0, product);
    }

    _bestsellers.removeWhere((p) => p.id == product.id);
    if (product.isBestseller) {
      _bestsellers.add(product);
    }

    notifyListeners();
  }

  void deleteProduct(int productId) {
    _repository.deleteProduct(productId);
    _allProducts.removeWhere((p) => p.id == productId);
    _products.removeWhere((p) => p.id == productId);
    _bestsellers.removeWhere((p) => p.id == productId);
    notifyListeners();
  }

  void updateProductPrice(int productId, double newPrice) {
    _repository.updatePrice(productId, newPrice);

    _allProducts = _allProducts.map((p) {
      if (p.id == productId) {
        return p.copyWith(basePrice: newPrice);
      }
      return p;
    }).toList();

    _products = _products.map((p) {
      if (p.id == productId) {
        return p.copyWith(basePrice: newPrice);
      }
      return p;
    }).toList();

    _bestsellers = _bestsellers.map((p) {
      if (p.id == productId) {
        return p.copyWith(basePrice: newPrice);
      }
      return p;
    }).toList();

    notifyListeners();
  }

  void addCategory(CategoryModel category) {
    _repository.addCategory(category);

    final existingIdx = _categories.indexWhere(
      (c) =>
          c.id == category.id ||
          c.name.trim().toLowerCase() == category.name.trim().toLowerCase(),
    );

    if (existingIdx != -1) {
      _categories[existingIdx] = category;
    } else {
      _categories.add(category);
    }

    final seenIds = <int>{};
    final uniqueCats = <CategoryModel>[];
    for (final c in _categories) {
      if (!seenIds.contains(c.id)) {
        seenIds.add(c.id);
        uniqueCats.add(c);
      }
    }
    _categories = uniqueCats;

    _categories.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    notifyListeners();
  }

  void updateCategory(CategoryModel category) {
    _repository.updateCategory(category);
    final idx = _categories.indexWhere((c) => c.id == category.id);
    if (idx != -1) {
      _categories[idx] = category;
      _categories.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    }
    notifyListeners();
  }

  void deleteCategory(int categoryId) {
    _repository.deleteCategory(categoryId);
    _categories.removeWhere((c) => c.id == categoryId);
    if (_selectedCategoryId == categoryId) {
      _selectedCategoryId = 1;
      fetchProducts();
    } else {
      notifyListeners();
    }
  }

  void toggleCategoryActive(int categoryId) {
    final idx = _categories.indexWhere((c) => c.id == categoryId);
    if (idx != -1) {
      final current = _categories[idx];
      final newStatus = !current.isActive;
      _categories[idx] = current.copyWith(isActive: newStatus);
      notifyListeners();
      _repository.toggleCategoryActive(categoryId, newStatus);
    }
  }
}
