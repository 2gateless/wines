import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/wine.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class AddWineScreen extends StatefulWidget {
  final File imageFile;
  final WineInfo wineInfo;

  const AddWineScreen(
      {super.key, required this.imageFile, required this.wineInfo});

  @override
  State<AddWineScreen> createState() => _AddWineScreenState();
}

class _AddWineScreenState extends State<AddWineScreen> {
  late final _nameCtrl =
      TextEditingController(text: widget.wineInfo.name);
  late final _originCtrl =
      TextEditingController(text: widget.wineInfo.origin);
  late final _grapeCtrl =
      TextEditingController(text: widget.wineInfo.grape);
  late final _charCtrl =
      TextEditingController(text: widget.wineInfo.characteristics);
  final _placeCtrl = TextEditingController();
  final _reviewCtrl = TextEditingController();

  DateTime _date = DateTime.now();
  double _rating = 3;
  bool _isSaving = false;

  final _storage = StorageService();
  final _firestore = FirestoreService();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _originCtrl.dispose();
    _grapeCtrl.dispose();
    _charCtrl.dispose();
    _placeCtrl.dispose();
    _reviewCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('와인 기록')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Label image preview
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(widget.imageFile,
                  height: 200, fit: BoxFit.cover, width: double.infinity),
            ),
            const SizedBox(height: 24),

            _SectionLabel('AI 분석 결과 (수정 가능)'),
            const SizedBox(height: 12),
            _field('와인 이름 *', _nameCtrl),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _field('원산지', _originCtrl)),
              const SizedBox(width: 10),
              Expanded(child: _field('포도 품종', _grapeCtrl)),
            ]),
            const SizedBox(height: 10),
            _field('특징', _charCtrl, maxLines: 2),

            const SizedBox(height: 24),
            const Divider(color: AppTheme.divider),
            const SizedBox(height: 24),

            _SectionLabel('내 기록'),
            const SizedBox(height: 12),

            _DatePicker(
                date: _date,
                onChanged: (d) => setState(() => _date = d)),
            const SizedBox(height: 10),
            _field('장소', _placeCtrl, hint: '어디서 마셨나요?'),
            const SizedBox(height: 10),
            _field('후기', _reviewCtrl,
                hint: '한 줄 후기를 남겨보세요...', maxLines: 3),
            const SizedBox(height: 16),

            _RatingPicker(
              rating: _rating,
              onChanged: (r) => setState(() => _rating = r),
            ),

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('저장하기'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl,
          {String? hint, int maxLines = 1}) =>
      TextField(
          controller: ctrl,
          maxLines: maxLines,
          decoration:
              InputDecoration(labelText: label, hintText: hint));

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('와인 이름을 입력해주세요')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final imageUrl =
          await _storage.uploadWineImage(widget.imageFile);

      final wine = Wine(
        id: '',
        name: _nameCtrl.text.trim(),
        origin: _originCtrl.text.trim(),
        grape: _grapeCtrl.text.trim(),
        characteristics: _charCtrl.text.trim(),
        foodPairing: widget.wineInfo.foodPairing,
        imageUrl: imageUrl,
        date: _date,
        place: _placeCtrl.text.trim().isEmpty
            ? null
            : _placeCtrl.text.trim(),
        review: _reviewCtrl.text.trim().isEmpty
            ? null
            : _reviewCtrl.text.trim(),
        rating: _rating,
        timestamp: DateTime.now(),
      );

      await _firestore.addWine(wine);

      if (mounted) {
        Navigator.of(context).popUntil((r) => r.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('와인이 기록되었습니다 🍷')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('저장 실패: $e')));
      }
    }
  }
}

// ── Private widgets ────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppTheme.textSecondary,
          letterSpacing: 1));
}

class _DatePicker extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  const _DatePicker({required this.date, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: Theme.of(ctx)
                  .colorScheme
                  .copyWith(primary: AppTheme.burgundy),
            ),
            child: child!,
          ),
        );
        if (picked != null) onChanged(picked);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppTheme.divider),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          const Icon(Icons.calendar_today_outlined,
              size: 17, color: AppTheme.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              DateFormat('yyyy년 M월 d일').format(date),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const Icon(Icons.chevron_right,
              color: AppTheme.textSecondary, size: 18),
        ]),
      ),
    );
  }
}

class _RatingPicker extends StatelessWidget {
  final double rating;
  final ValueChanged<double> onChanged;

  const _RatingPicker({required this.rating, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('평점',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
                letterSpacing: 1)),
        const SizedBox(height: 10),
        Row(
          children: List.generate(
            5,
            (i) => GestureDetector(
              onTap: () => onChanged(i + 1.0),
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Icon(
                  i < rating.round()
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: AppTheme.gold,
                  size: 36,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
