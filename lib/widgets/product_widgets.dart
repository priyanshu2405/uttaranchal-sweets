import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/nav.dart';
import '../app/routes.dart';
import '../app/theme.dart';
import '../data/catalog.dart';
import '../state/app_state.dart';
import 'feedback.dart';

void addToBag(BuildContext context, Product p, {String? weight, int qty = 1}) {
  HapticFeedback.mediumImpact();
  context.appRead.addProduct(p, weight: weight, qty: qty);
  toast(context, '${p.name} added to your bag', action: 'View bag', onAction: () => go(context, R.bag));
}

class ProductCard extends StatelessWidget {
  final Product product;
  const ProductCard(this.product, {super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(64), bottom: Radius.circular(16)),
        side: BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => go(context, R.product, args: product.id),
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Hero(
              tag: 'product-${product.id}',
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(58), bottom: Radius.circular(10)),
                child: AspectRatio(aspectRatio: 1.45, child: Image.asset(product.image, fit: BoxFit.cover)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(5, 12, 3, 4),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(product.name, style: T.display(21), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(product.subtitle, style: T.tiny(), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: Text(rupees(product.price500g), style: T.sans(13.5, color: AppColors.teal, weight: FontWeight.w700))),
                  Material(
                    color: AppColors.berry,
                    borderRadius: BorderRadius.circular(7),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(7),
                      onTap: () => addToBag(context, product),
                      child: const SizedBox(width: 30, height: 30, child: Icon(Icons.add_rounded, color: AppColors.white, size: 20)),
                    ),
                  ),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Two-column grid that sizes rows to their content (never overflows on
/// small phones or large accessibility text).
class ProductGrid extends StatelessWidget {
  final List<Product> products;
  const ProductGrid(this.products, {super.key});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < products.length; i += 2) {
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: ProductCard(products[i])),
          const SizedBox(width: 12),
          Expanded(child: i + 1 < products.length ? ProductCard(products[i + 1]) : const SizedBox()),
        ]),
      ));
    }
    return Column(children: rows);
  }
}
