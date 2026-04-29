import 'package:flutter/material.dart';
import '../models/wine.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/wine_grid_item.dart';
import 'scan_screen.dart';
import 'chat_screen.dart';
import 'wine_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _GalleryTab(firestoreService: _firestoreService),
          const ChatScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: '내 와인',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: '소믈리에',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScanScreen()),
              ),
              tooltip: '와인 스캔',
              child: const Icon(Icons.camera_alt_outlined),
            )
          : null,
    );
  }
}

class _GalleryTab extends StatelessWidget {
  final FirestoreService firestoreService;
  const _GalleryTab({required this.firestoreService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WINES')),
      body: StreamBuilder<List<Wine>>(
        stream: firestoreService.watchWines().handleError((_) {}),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.burgundy));
          }
          final wines = snapshot.data ?? [];

          if (wines.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wine_bar_outlined,
                      size: 72,
                      color: AppTheme.burgundy.withOpacity(0.25)),
                  const SizedBox(height: 20),
                  const Text(
                    '첫 번째 와인을 기록해보세요',
                    style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 16,
                        letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '아래 카메라 버튼을 눌러 시작하세요',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            itemCount: wines.length,
            itemBuilder: (context, i) => WineGridItem(
              wine: wines[i],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => WineDetailScreen(wine: wines[i])),
              ),
            ),
          );
        },
      ),
    );
  }
}
