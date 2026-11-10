import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../../../core/widgets/login_required_dialog.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../cart_checkout/models/cart_item_model.dart';
import '../../../cart_checkout/providers/cart_provider.dart';
import '../../models/product_model.dart';
import '../../models/topping_model.dart';

class CustomizationBottomSheet extends StatefulWidget {
  final ProductModel product;

  const CustomizationBottomSheet({super.key, required this.product});

  static Future<void> show(BuildContext context, ProductModel product) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CustomizationBottomSheet(product: product),
    );
  }

  @override
  State<CustomizationBottomSheet> createState() => _CustomizationBottomSheetState();
}

class _CustomizationBottomSheetState extends State<CustomizationBottomSheet> {
  late String _selectedSize;
  String _selectedSugar = '100%';
  String _selectedIce = '100%';
  final Set<ToppingModel> _selectedToppings = {};
  int _quantity = 1;
  final TextEditingController _noteController = TextEditingController();

  final List<String> _sugarOptions = ['0%', '30%', '50%', '70%', '100%'];
  final List<String> _iceOptions = ['0%', '50%', '100%'];

  @override
  void initState() {
    super.initState();
    // Default size is 'M' if exists, else first size
    if (widget.product.sizes.any((s) => s.sizeName == 'M')) {
      _selectedSize = 'M';
    } else if (widget.product.sizes.isNotEmpty) {
      _selectedSize = widget.product.sizes.first.sizeName;
    } else {
      _selectedSize = 'M';
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  double get _currentUnitPrice {
    double price = widget.product.basePrice;
    final sizeObj = widget.product.sizes.where((s) => s.sizeName == _selectedSize);
    if (sizeObj.isNotEmpty) {
      price += sizeObj.first.extraPrice;
    }
    for (final top in _selectedToppings) {
      price += top.price;
    }
    return price;
  }

  double get _totalPrice => _currentUnitPrice * _quantity;

  void _onAddToCart() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isGuest) {
      LoginRequiredDialog.show(
        context,
        title: 'HÃY ĐĂNG NHẬP ĐỂ MUA HÀNG',
        message: 'Bạn đang ở chế độ Khách vãng lai. Vui lòng đăng nhập tài khoản để đặt món, nhận ưu đãi và tích điểm thưởng!',
      );
      return;
    }

    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    final item = CartItemModel(
      productId: widget.product.id,
      productName: widget.product.name,
      imageUrl: widget.product.imageUrl,
      sizeName: _selectedSize,
      sugarLevel: _selectedSugar,
      iceLevel: _selectedIce,
      quantity: _quantity,
      unitPrice: _currentUnitPrice,
      selectedToppings: _selectedToppings.toList(),
      itemNote: _noteController.text.trim(),
    );

    cartProvider.addItem(item);
    Navigator.of(context).pop();
    CustomToast.showSuccess(context, 'Đã thêm "${widget.product.name}" vào giỏ hàng!');
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Alert if Out of Stock
                  if (!widget.product.isAvailable)
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: Colors.redAccent, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Món này đã bán hết hôm nay, hẹn bạn vào hôm sau nhé!',
                              style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Product Summary Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          widget.product.imageUrl,
                          width: 84,
                          height: 84,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 84,
                            height: 84,
                            color: AppColors.cardDark,
                            child: const Icon(Icons.local_cafe, color: AppColors.primaryGold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.product.name, style: AppTextStyles.headlineMedium),
                            const SizedBox(height: 4),
                            Text(
                              CurrencyFormatter.format(widget.product.basePrice),
                              style: AppTextStyles.price,
                            ),
                            if (widget.product.description != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                widget.product.description!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodySmall,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.divider),

                  // 1. Size Selection
                  const SizedBox(height: 8),
                  const Text('Chọn kích cỡ (Size)', style: AppTextStyles.titleMedium),
                  const SizedBox(height: 10),
                  Row(
                    children: (widget.product.sizes.isNotEmpty
                            ? widget.product.sizes
                            : [
                                const ProductSizeModel(id: 1, productId: 1, sizeName: 'S', extraPrice: 0),
                                const ProductSizeModel(id: 2, productId: 1, sizeName: 'M', extraPrice: 6000),
                                const ProductSizeModel(id: 3, productId: 1, sizeName: 'L', extraPrice: 12000),
                              ])
                        .map((size) {
                      final isSelected = _selectedSize == size.sizeName;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedSize = size.sizeName),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.brewGreen : AppColors.cardDark,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppColors.primaryGold : AppColors.divider,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Size ${size.sizeName}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  size.extraPrice > 0 ? '+${CurrencyFormatter.format(size.extraPrice)}' : 'Chuẩn',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isSelected ? AppColors.primaryGold : AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  // 2. Sugar Level
                  const SizedBox(height: 20),
                  const Text('Mức đường', style: AppTextStyles.titleMedium),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _sugarOptions.map((sugar) {
                      final isSelected = _selectedSugar == sugar;
                      return ChoiceChip(
                        label: Text(sugar),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _selectedSugar = sugar),
                        selectedColor: AppColors.brewGreen,
                        backgroundColor: AppColors.cardDark,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        side: BorderSide(
                          color: isSelected ? AppColors.primaryGold : AppColors.divider,
                        ),
                      );
                    }).toList(),
                  ),

                  // 3. Ice Level
                  const SizedBox(height: 20),
                  const Text('Mức đá', style: AppTextStyles.titleMedium),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _iceOptions.map((ice) {
                      final isSelected = _selectedIce == ice;
                      return ChoiceChip(
                        label: Text(ice == '0%' ? 'Không đá' : (ice == '50%' ? '50% đá' : 'Đá chuẩn (100%)')),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _selectedIce = ice),
                        selectedColor: AppColors.brewGreen,
                        backgroundColor: AppColors.cardDark,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        side: BorderSide(
                          color: isSelected ? AppColors.primaryGold : AppColors.divider,
                        ),
                      );
                    }).toList(),
                  ),

                  // 4. Toppings
                  const SizedBox(height: 20),
                  const Text('Chọn thêm Topping', style: AppTextStyles.titleMedium),
                  const SizedBox(height: 8),
                  Column(
                    children: widget.product.availableToppings.map((topping) {
                      final isSelected = _selectedToppings.contains(topping);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: AppColors.cardDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.primaryGold.withOpacity(0.6) : AppColors.divider,
                          ),
                        ),
                        child: CheckboxListTile(
                          value: isSelected,
                          activeColor: AppColors.primaryGold,
                          checkColor: Colors.black,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          title: Text(
                            topping.name,
                            style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            '+${CurrencyFormatter.format(topping.price)}',
                            style: const TextStyle(fontSize: 12, color: AppColors.primaryGold),
                          ),
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                _selectedToppings.add(topping);
                              } else {
                                _selectedToppings.remove(topping);
                              }
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),

                  // 5. Special Note
                  const SizedBox(height: 14),
                  const Text('Ghi chú cho Barista pha chế', style: AppTextStyles.titleMedium),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: TextField(
                      controller: _noteController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'Ví dụ: Cho nhiều sữa đặc, rót riêng kem cheese...',
                        hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Bottom Bar: Quantity & Total & Add Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.cardDark,
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Quantity Stepper
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 18, color: Colors.white),
                          onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                        ),
                        Text(
                          '$_quantity',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 18, color: AppColors.primaryGold),
                          onPressed: () => setState(() => _quantity++),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Add To Cart Button with dynamic total
                  Expanded(
                    child: CustomButton(
                      text: !widget.product.isAvailable
                          ? 'ĐÃ BÁN HẾT HẸN BẠN VÀO HÔM SAU'
                          : (auth.isGuest
                              ? 'ĐĂNG NHẬP ĐỂ MUA • ${CurrencyFormatter.format(_totalPrice)}'
                              : 'THÊM • ${CurrencyFormatter.format(_totalPrice)}'),
                      onPressed: widget.product.isAvailable ? _onAddToCart : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
