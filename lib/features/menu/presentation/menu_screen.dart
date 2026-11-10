import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/custom_toast.dart';
import '../models/product_model.dart';
import '../providers/menu_provider.dart';
import 'widgets/customization_bottom_sheet.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _getCategoryIcon(String? iconName) {
    switch (iconName) {
      case 'local_cafe':
        return Icons.local_cafe_rounded;
      case 'coffee':
        return Icons.coffee_rounded;
      case 'eco':
        return Icons.eco_rounded;
      case 'ac_unit':
        return Icons.ac_unit_rounded;
      case 'cake':
        return Icons.cake_rounded;
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'fastfood':
        return Icons.fastfood_rounded;
      case 'icecream':
        return Icons.icecream_rounded;
      case 'local_drink':
        return Icons.local_drink_rounded;
      default:
        return Icons.all_inclusive_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final menu = Provider.of<MenuProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        title: const Text('Thực đơn BrewPoint', style: AppTextStyles.headlineMedium),
      ),
      body: Column(
        children: [
          // 1. Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white, fontSize: 13.5),
                onChanged: (val) => menu.setSearchQuery(val),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm trà sữa, cà phê muối, cold brew...',
                  hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryGold, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16, color: AppColors.textMuted),
                          onPressed: () {
                            _searchController.clear();
                            menu.setSearchQuery('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // 2. Category Tabs Horizontal Scroll
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: menu.categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = menu.categories[index];
                final isSelected = menu.selectedCategoryId == cat.id;
                final productCount = cat.id == 1
                    ? menu.allProducts.length
                    : menu.allProducts.where((p) => p.categoryId == cat.id).length;

                return GestureDetector(
                  onTap: () => menu.selectCategory(cat.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.brewGreen : AppColors.cardDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primaryGold : AppColors.divider,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getCategoryIcon(cat.iconName),
                          size: 16,
                          color: isSelected ? AppColors.primaryGold : AppColors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          cat.name,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                        if (productCount > 0) ...[
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withOpacity(0.2)
                                  : Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$productCount',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // 3. Products Grid View
          Expanded(
            child: menu.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGold))
                : menu.products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off_rounded, size: 48, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            Text('Không tìm thấy đồ uống phù hợp', style: AppTextStyles.bodyMedium),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.72,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: menu.products.length,
                        itemBuilder: (context, index) {
                          final product = menu.products[index];
                          return _buildProductCard(context, product);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, ProductModel product) {
    final isAvailable = product.isAvailable;

    return GestureDetector(
      onTap: () {
        if (!isAvailable) {
          CustomToast.showError(
            context,
            'Món "${product.name}" đã bán hết hẹn bạn vào hôm sau nhé!',
          );
          return;
        }
        CustomizationBottomSheet.show(context, product);
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAvailable ? AppColors.divider : Colors.redAccent.withOpacity(0.35),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with Badges
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Image.network(
                        product.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.surfaceDark,
                          child: const Icon(Icons.local_cafe, color: AppColors.primaryGold, size: 36),
                        ),
                      ),
                    ),
                  ),
                  if (product.isBestseller)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.brewGreen,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.primaryGold),
                        ),
                        child: const Text('BESTSELLER', style: TextStyle(color: AppColors.primaryGold, fontSize: 9.5, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  // Overlay khi đã bán hết
                  if (!isAvailable)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.68),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Text(
                              'ĐÃ BÁN HẾT',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Content Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: isAvailable ? Colors.white : Colors.white60,
                    ),
                  ),
                  const SizedBox(height: 3),
                  if (!isAvailable)
                    const Text(
                      'Đã bán hết hẹn bạn vào hôm sau',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFFFF6B6B),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else if (product.description != null)
                    Text(
                      product.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall,
                    ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        CurrencyFormatter.format(product.basePrice),
                        style: isAvailable
                            ? AppTextStyles.price
                            : AppTextStyles.price.copyWith(color: AppColors.textMuted),
                      ),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isAvailable ? AppColors.brewGreen : Colors.white10,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isAvailable ? Icons.add : Icons.block_rounded,
                          color: isAvailable ? AppColors.primaryGold : Colors.redAccent.withOpacity(0.7),
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
