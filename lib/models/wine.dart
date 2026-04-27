import 'package:cloud_firestore/cloud_firestore.dart';

class WineInfo {
  final String name;
  final String origin;
  final String grape;
  final String characteristics;
  final List<String> foodPairing;

  const WineInfo({
    required this.name,
    required this.origin,
    required this.grape,
    required this.characteristics,
    required this.foodPairing,
  });

  factory WineInfo.fromJson(Map<String, dynamic> json) => WineInfo(
        name: (json['name'] as String?) ?? '알 수 없음',
        origin: (json['origin'] as String?) ?? '알 수 없음',
        grape: (json['grape'] as String?) ?? '알 수 없음',
        characteristics: (json['characteristics'] as String?) ?? '',
        foodPairing: json['foodPairing'] is List
            ? List<String>.from(json['foodPairing'] as List)
            : [],
      );

  static WineInfo empty() => const WineInfo(
        name: '',
        origin: '',
        grape: '',
        characteristics: '',
        foodPairing: [],
      );
}

class Wine {
  final String id;
  final String name;
  final String origin;
  final String grape;
  final String characteristics;
  final List<String> foodPairing;
  final String? imageUrl;
  final DateTime date;
  final String? place;
  final String? review;
  final double? rating;
  final DateTime timestamp;

  const Wine({
    required this.id,
    required this.name,
    required this.origin,
    required this.grape,
    required this.characteristics,
    required this.foodPairing,
    this.imageUrl,
    required this.date,
    this.place,
    this.review,
    this.rating,
    required this.timestamp,
  });

  factory Wine.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Wine(
      id: doc.id,
      name: (d['name'] as String?) ?? '',
      origin: (d['origin'] as String?) ?? '',
      grape: (d['grape'] as String?) ?? '',
      characteristics: (d['characteristics'] as String?) ?? '',
      foodPairing: d['foodPairing'] is List
          ? List<String>.from(d['foodPairing'] as List)
          : [],
      imageUrl: d['imageUrl'] as String?,
      date: d['date'] is Timestamp
          ? (d['date'] as Timestamp).toDate()
          : DateTime.now(),
      place: d['place'] as String?,
      review: d['review'] as String?,
      rating: (d['rating'] as num?)?.toDouble(),
      timestamp: d['timestamp'] is Timestamp
          ? (d['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'origin': origin,
        'grape': grape,
        'characteristics': characteristics,
        'foodPairing': foodPairing,
        'imageUrl': imageUrl,
        'date': Timestamp.fromDate(date),
        'place': place,
        'review': review,
        'rating': rating,
        'timestamp': Timestamp.fromDate(timestamp),
      };

  Wine copyWith({
    String? name,
    String? origin,
    String? grape,
    String? characteristics,
    List<String>? foodPairing,
    String? imageUrl,
    DateTime? date,
    String? place,
    String? review,
    double? rating,
  }) =>
      Wine(
        id: id,
        name: name ?? this.name,
        origin: origin ?? this.origin,
        grape: grape ?? this.grape,
        characteristics: characteristics ?? this.characteristics,
        foodPairing: foodPairing ?? this.foodPairing,
        imageUrl: imageUrl ?? this.imageUrl,
        date: date ?? this.date,
        place: place ?? this.place,
        review: review ?? this.review,
        rating: rating ?? this.rating,
        timestamp: timestamp,
      );
}
