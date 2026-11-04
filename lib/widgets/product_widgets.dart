import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/nav.dart';
import '../app/routes.dart';
import '../app/theme.dart';
import '../data/catalog.dart';
import '../state/app_state.dart';
import 'common.dart';
import 'feedback.dart';

/// Adds a product (in its default or chosen size) to the bag and tells the customer.
void addToBag(BuildContext context, Product p, {int? optionId, int qty = 1}) {
  final error = context.appRead.addProduct(p, optionId: optionId, qty: qty);
  if (error != null) {
    HapticFeedback.heavyImpact();
    toast(context, error);
    return;
  }
  HapticFeedback.mediumImpact();
  toast(context, '${p.name} added to your bag', action: 'View bag', onAction: () => go(context, R.bag));
}

/// Bottom sheet to choose size and quantity before adding to the bag.
Future<void> showAddToBagSheet(BuildContext context, Product p) async {
  int? option = p.defaultOption?.id;
  var qty = 1;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) {
        final app = ctx.appRead;
        final stock = p.stockFor(option);
        final soldOut = p.soldOutFor(option);
        final maxQty = (stock ?? app.config.maxLineQuantity).clamp(1, app.config.maxLineQuantity);
        if (qty > maxQty) qty = maxQty;
        final unit = p.priceFor(option);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                ClipRRect(borderRadius: BorderRadius.circular(12), child: NetImage(p.imageUrl, width: 64, height: 64, fallback: fallbackFor(p))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.name, style: T.display(24), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('${p.labelFor(option)} · ${money(unit)}', style: T.tiny()),
                  ]),
                ),
              ]),
              if (p.options.length > 1) ...[
                const SizedBox(height: 16),
                Text('Size', style: T.sans(12, weight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final o in p.options)
                    ChoiceChip(
                      label: Text(o.soldOut ? '${o.label} · sold out' : '${o.label} · ${money(o.price)}'),
                      selected: o.id == option,
                      onSelected: o.soldOut ? null : (_) => set(() => option = o.id),
                      selectedColor: AppColors.pink,
                      labelStyle: T.sans(12, color: o.id == option ? AppColors.berry : AppColors.ink, weight: FontWeight.w600),
                    ),
                ]),
              ],
              const SizedBox(height: 16),
              Row(children: [
                Text('Quantity', style: T.sans(12, weight: FontWeight.w600)),
                const Spacer(),
                if (!soldOut) QtyStepper(value: qty, min: 1, max: maxQty, onChanged: (v) => set(() => qty = v)),
              ]),
              if (stock != null && !soldOut && stock <= 5)
                Padding(padding: const EdgeInsets.only(top: 6), child: Text('Only $stock left', style: T.sans(11.5, color: AppColors.berry, weight: FontWeight.w600))),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.berry, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: soldOut
                      ? null
                      : () {
                          Navigator.pop(ctx);
                          addToBag(context, p, optionId: option, qty: qty);
                        },
                  child: Text(soldOut ? 'Sold out' : 'Add to bag · ${money(unit * qty)}', style: T.sans(14.5, color: AppColors.white, weight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
        );
      },
    ),
  );
}

/// Shop photo from the website (or a bundled picture while it loads / if it fails).
class NetImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String fallback;
  const NetImage(this.url, {super.key, this.width, this.height, this.fit = BoxFit.cover, this.fallback = Img.sweets});

  @override
  Widget build(BuildContext context) {
    final u = url ?? '';
    Widget asset() => Image.asset(fallback, width: width, height: height, fit: fit);
    if (u.startsWith('assets/')) return Image.asset(u, width: width, height: height, fit: fit);
    if (!u.startsWith('http')) return asset();
    return Image.network(
      u,
      width: width,
      height: height,
      fit: fit,
      filterQuality: FilterQuality.medium,
      loadingBuilder: (context, child, progress) => progress == null ? child : Container(width: width, height: height, color: AppColors.peach),
      errorBuilder: (_, __, ___) => asset(),
    );
  }
}

/// Bundled picture that best matches a product's category (used as the fallback).
String fallbackFor(Product p) => switch (p.category?.slug) {
      'snacks' => Img.namkeen,
      'milk-products' => Img.milkSweets,
      'regional' => Img.milkSweets,
      _ => Img.sweets,
    };

class ProductCard extends StatelessWidget {
  final Product product;
  const ProductCard(this.product, {super.key});

  @override
  Widget build(BuildContext context) {
    final soldOut = product.soldOut;
    final inBag = context.app.qtyInBag(product.id);
    return Material(
      color: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(64), bottom: Radius.circular(16)),
        side: BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => go(context, R.product, args: product),
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Hero(
              tag: 'product-${product.id}',
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(58), bottom: Radius.circular(10)),
                child: AspectRatio(
                  aspectRatio: 1.45,
                  child: Stack(fit: StackFit.expand, children: [
                    NetImage(product.imageUrl, fallback: fallbackFor(product)),
                    if (soldOut)
                      Container(
                        color: const Color(0x99FFF9ED),
                        alignment: Alignment.center,
                        child: Text('Sold out', style: T.sans(12, color: AppColors.berry, weight: FontWeight.w700)),
                      ),
                  ]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(5, 12, 3, 4),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(product.name, style: T.display(21), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(product.subtitle, style: T.tiny(), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 10),
                if (inBag > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('$inBag in your bag', style: T.sans(11, color: AppColors.berry, weight: FontWeight.w600)),
                  ),
                Row(children: [
                  Expanded(
                    child: Text(product.priceLabel.isNotEmpty ? product.priceLabel : money(product.price),
                        style: T.sans(13.5, color: AppColors.teal, weight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  Material(
                    color: soldOut ? AppColors.border : AppColors.berry,
                    borderRadius: BorderRadius.circular(7),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(7),
                      onTap: soldOut ? null : () => showAddToBagSheet(context, product),
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

/// Loading / error / empty states used by every screen that waits for the server.
class LoadState extends StatelessWidget {
  final bool loading;
  final String? error;
  final VoidCallback? onRetry;
  final String? empty;
  const LoadState({super.key, this.loading = false, this.error, this.onRetry, this.empty});

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.berry))),
      );
    }
    final text = error ?? empty ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(children: [
        Icon(error != null ? Icons.wifi_off_rounded : Icons.inbox_outlined, size: 40, color: AppColors.border),
        const SizedBox(height: 12),
        Text(text, textAlign: TextAlign.center, style: T.body()),
        if (error != null && onRetry != null) ...[
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: Text('Try again', style: T.sans(13, color: AppColors.berry, weight: FontWeight.w700))),
        ],
      ]),
    );
  }
}
