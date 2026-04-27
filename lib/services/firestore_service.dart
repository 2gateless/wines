import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/wine.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;
  static const _col = 'wines';

  Stream<List<Wine>> watchWines() => _db
      .collection(_col)
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Wine.fromFirestore).toList());

  Future<List<Wine>> getWines() async {
    final s = await _db
        .collection(_col)
        .orderBy('timestamp', descending: true)
        .get();
    return s.docs.map(Wine.fromFirestore).toList();
  }

  Future<String> addWine(Wine wine) async {
    final ref = await _db.collection(_col).add(wine.toFirestore());
    return ref.id;
  }

  Future<void> deleteWine(String id) =>
      _db.collection(_col).doc(id).delete();
}
