import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/wine.dart';
import '../services/gemini_service.dart';
import '../theme/app_theme.dart';
import 'add_wine_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  Uint8List? _imageBytes;
  WineInfo? _wineInfo;
  bool _isAnalyzing = false;
  final _gemini = GeminiService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('와인 스캔')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ImagePickerArea(imageBytes: _imageBytes, onPick: _pickImage),
            const SizedBox(height: 20),

            if (_imageBytes != null && _wineInfo == null && !_isAnalyzing)
              ElevatedButton.icon(
                onPressed: _analyze,
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: const Text('AI로 와인 분석하기'),
              ),

            if (_isAnalyzing) ...[
              const SizedBox(height: 8),
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: AppTheme.burgundy),
                    SizedBox(height: 14),
                    Text(
                      'AI가 와인 라벨을 분석 중...',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],

            if (_wineInfo != null) ...[
              const SizedBox(height: 4),
              _WineInfoCard(wineInfo: _wineInfo!),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _goToAdd,
                child: const Text('이 와인 기록하기'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => setState(() {
                  _wineInfo = null;
                  _imageBytes = null;
                }),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                  side: const BorderSide(color: AppTheme.divider),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                ),
                child: const Text('다시 스캔'),
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined,
                    color: AppTheme.burgundy),
                title: const Text('카메라로 찍기'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: AppTheme.burgundy),
                title: const Text('갤러리에서 선택'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null) return;

    final picker = ImagePicker();
    final picked =
        await picker.pickImage(
          source: source,
          imageQuality: 80, // 와인 라벨 인식에 충분한 품질
          maxWidth: 800,    // Gemini 768px 타일 기준으로 비용 최소화
          maxHeight: 800,   // 세로도 제한하여 타일 수 억제
        );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _wineInfo = null;
    });
  }

  Future<void> _analyze() async {
    if (_imageBytes == null) return;
    setState(() => _isAnalyzing = true);

    final info = await _gemini.analyzeLabel(_imageBytes!);

    setState(() {
      _wineInfo = info ?? WineInfo.empty();
      _isAnalyzing = false;
    });

    if (info == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('분석에 실패했습니다. 더 선명한 사진으로 다시 시도해보세요.'),
      ));
    }
  }

  void _goToAdd() {
    if (_wineInfo == null || _imageBytes == null) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AddWineScreen(imageBytes: _imageBytes!, wineInfo: _wineInfo!),
      ),
    );
  }
}

// ── Private widgets ────────────────────────────────────────────────────────

class _ImagePickerArea extends StatelessWidget {
  final Uint8List? imageBytes;
  final VoidCallback onPick;

  const _ImagePickerArea({required this.imageBytes, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPick,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 260,
        decoration: BoxDecoration(
          color: AppTheme.cream,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: imageBytes != null ? AppTheme.burgundy : AppTheme.divider,
            width: imageBytes != null ? 2 : 1,
          ),
        ),
        child: imageBytes != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Image.memory(imageBytes!, fit: BoxFit.cover,
                    width: double.infinity),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_outlined,
                      size: 52,
                      color: AppTheme.burgundy.withOpacity(0.45)),
                  const SizedBox(height: 14),
                  const Text(
                    '라벨 사진을 찍거나 선택하세요',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '탭하여 시작',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
      ),
    );
  }
}

class _WineInfoCard extends StatelessWidget {
  final WineInfo wineInfo;

  const _WineInfoCard({required this.wineInfo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.burgundy.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.auto_awesome,
                size: 16, color: AppTheme.burgundy),
            const SizedBox(width: 8),
            const Text(
              'AI 분석 결과',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.burgundy,
                  fontSize: 14),
            ),
          ]),
          const SizedBox(height: 14),
          _Row('이름', wineInfo.name),
          _Row('원산지', wineInfo.origin),
          _Row('품종', wineInfo.grape),
          if (wineInfo.characteristics.isNotEmpty)
            _Row('특징', wineInfo.characteristics),
          if (wineInfo.foodPairing.isNotEmpty)
            _Row('페어링', wineInfo.foodPairing.join(' · ')),
        ],
      ),
    );
  }

  Widget _Row(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 52,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary)),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(fontSize: 14, height: 1.4)),
            ),
          ],
        ),
      );
}
