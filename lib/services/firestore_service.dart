import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/wine.dart';

class FirestoreService {
  static const _col = 'wines';

  static bool get _ready => Firebase.apps.isNotEmpty;

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Stream<List<Wine>> watchWines() {
    if (!_ready) return Stream.value([]);
    return _db
        .collection(_col)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((s) => s.docs.map(Wine.fromFirestore).toList());
  }

  Future<List<Wine>> getWines() async {
    if (!_ready) return [];
    final s = await _db
        .collection(_col)
        .orderBy('timestamp', descending: true)
        .get();
    return s.docs.map(Wine.fromFirestore).toList();
  }

  Future<String> addWine(Wine wine) async {
    if (!_ready) return 'demo-id';
    final ref = await _db.collection(_col).add(wine.toFirestore());
    return ref.id;
  }

  Future<void> deleteWine(String id) async {
    if (!_ready) return;
    await _db.collection(_col).doc(id).delete();
  }
}
