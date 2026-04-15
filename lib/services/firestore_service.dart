import 'package:cloud_firestore/cloud_firestore.dart';

/// Thin Firestore helper used by AppProvider to read/write collections.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── User ─────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists ? doc.data() : null;
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) =>
      _db.collection('users').doc(uid).update(data);

  // ── Crops ─────────────────────────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> cropsStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('crops')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Future<void> addCrop(String uid, Map<String, dynamic> crop) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('crops')
        .add({...crop, 'createdAt': FieldValue.serverTimestamp()});
  }

  Future<void> updateCrop(
          String uid, String cropId, Map<String, dynamic> data) =>
      _db
          .collection('users')
          .doc(uid)
          .collection('crops')
          .doc(cropId)
          .update(data);

  Future<void> deleteCrop(String uid, String cropId) =>
      _db.collection('users').doc(uid).collection('crops').doc(cropId).delete();

  // ── Community Posts ───────────────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> communityPostsStream() {
    return _db
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Future<void> addPost(Map<String, dynamic> post) async {
    await _db.collection('posts').add({
      ...post,
      'createdAt': FieldValue.serverTimestamp(),
      'likes': 0,
      'liked': false,
      'comments_count': 0,
    });
  }

  Future<void> togglePostLike(
      String postId, bool currentlyLiked, int currentLikes) {
    return _db.collection('posts').doc(postId).update({
      'liked': !currentlyLiked,
      'likes': currentlyLiked ? currentLikes - 1 : currentLikes + 1,
    });
  }

  // ── Marketplace Products ──────────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> productsStream() {
    return _db
        .collection('products')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  /// Seed initial products if the collection is empty (run once).
  Future<void> seedProductsIfEmpty(
      List<Map<String, dynamic>> seedData) async {
    final snap = await _db.collection('products').limit(1).get();
    if (snap.docs.isEmpty) {
      final batch = _db.batch();
      for (final p in seedData) {
        final ref = _db.collection('products').doc();
        batch.set(ref, {...p, 'createdAt': FieldValue.serverTimestamp()});
      }
      await batch.commit();
    }
  }
}
