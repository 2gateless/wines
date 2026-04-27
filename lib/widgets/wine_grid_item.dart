import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/wine.dart';
import '../theme/app_theme.dart';

class WineGridItem extends StatelessWidget {
  final Wine wine;
  final VoidCallback onTap;

  const WineGridItem({super.key, required this.wine, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 4,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
                child: wine.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: wine.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: AppTheme.cream),
                        errorWidget: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    wine.name.isEmpty ? '(이름 없음)' : wine.name,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, height: 1.2),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('yyyy.MM.dd').format(wine.date),
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary),
                  ),
                  if (wine.rating != null) ...[
                    const SizedBox(height: 4),
                    _StarRow(rating: wine.rating!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: AppTheme.cream,
        child: const Center(
          child: Icon(Icons.wine_bar_outlined,
              color: AppTheme.burgundy, size: 36),
        ),
      );
}

class _StarRow extends StatelessWidget {
  final double rating;
  const _StarRow({required this.rating});

  @override
  Widget build(BuildContext context) => Row(
        children: List.generate(
          5,
          (i) => Icon(
            i < rating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
            color: AppTheme.gold,
            size: 13,
          ),
        ),
      );
}
