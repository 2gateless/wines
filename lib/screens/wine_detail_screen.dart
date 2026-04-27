import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/wine.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class WineDetailScreen extends StatelessWidget {
  final Wine wine;

  const WineDetailScreen({super.key, required this.wine});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          wine.name.isEmpty ? '와인 상세' : wine.name,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context),
            tooltip: '삭제',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero image
            if (wine.imageUrl != null)
              CachedNetworkImage(
                imageUrl: wine.imageUrl!,
                height: 320,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: 320,
                  color: AppTheme.cream,
                  child: const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.burgundy)),
                ),
                errorWidget: (_, __, ___) => Container(
                  height: 200,
                  color: AppTheme.cream,
                  child: const Icon(Icons.wine_bar_outlined,
                      size: 64, color: AppTheme.burgundy),
                ),
              )
            else
              Container(
                height: 200,
                color: AppTheme.cream,
                child: const Center(
                  child: Icon(Icons.wine_bar_outlined,
                      size: 72, color: AppTheme.burgundy),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(wine.name,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w700, height: 1.2)),
                  const SizedBox(height: 6),
                  Text(
                    [
                      if (wine.origin.isNotEmpty) wine.origin,
                      if (wine.grape.isNotEmpty) wine.grape,
                    ].join(' · '),
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 14),
                  ),

                  if (wine.rating != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < wine.rating!.round()
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: AppTheme.gold,
                          size: 22,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 22),
                  const Divider(color: AppTheme.divider),
                  const SizedBox(height: 22),

                  // Wine characteristics
                  if (wine.characteristics.isNotEmpty) ...[
                    _InfoRow(label: '특징', value: wine.characteristics),
                    const SizedBox(height: 16),
                  ],

                  if (wine.foodPairing.isNotEmpty) ...[
                    const Text('어울리는 음식',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: wine.foodPairing
                          .map((f) => Chip(label: Text(f)))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  const Divider(color: AppTheme.divider),
                  const SizedBox(height: 16),

                  // User notes
                  _InfoRow(
                    label: '마신 날',
                    value: DateFormat('yyyy년 M월 d일').format(wine.date),
                    icon: Icons.calendar_today_outlined,
                  ),
                  if (wine.place != null && wine.place!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _InfoRow(
                      label: '장소',
                      value: wine.place!,
                      icon: Icons.place_outlined,
                    ),
                  ],
                  if (wine.review != null && wine.review!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _InfoRow(
                      label: '후기',
                      value: wine.review!,
                      icon: Icons.format_quote_rounded,
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('삭제'),
        content: const Text('이 와인 기록을 삭제하시겠습니까?'),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소')),
          TextButton(
            onPressed: () async {
              await FirestoreService().deleteWine(wine.id);
              if (ctx.mounted) {
                Navigator.of(ctx).pop(); // dialog
                Navigator.of(ctx).pop(); // detail
              }
            },
            child: const Text('삭제',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;

  const _InfoRow({required this.label, required this.value, this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                      letterSpacing: 0.5)),
              const SizedBox(height: 3),
              Text(value,
                  style: const TextStyle(fontSize: 15, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}
