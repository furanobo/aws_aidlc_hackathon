enum RecordSource { manual, autoDetected }
enum CategoryType { food, lifestyle }

class ActivityCategory {
  final String categoryId;
  final String name;
  final CategoryType type;
  final int basePoints;
  final String iconKey;
  final int sortOrder;

  ActivityCategory({
    required this.categoryId,
    required this.name,
    required this.type,
    required this.basePoints,
    required this.iconKey,
    required this.sortOrder,
  });

  factory ActivityCategory.fromJson(Map<String, dynamic> json) {
    return ActivityCategory(
      categoryId: json['categoryId'],
      name: json['name'],
      type: json['type'] == 'FOOD' ? CategoryType.food : CategoryType.lifestyle,
      basePoints: json['basePoints'],
      iconKey: json['iconKey'] ?? '',
      sortOrder: json['sortOrder'] ?? 0,
    );
  }
}

class ActivityRecord {
  final String recordId;
  final String categoryId;
  final RecordSource source;
  final int points;
  final String? memo;
  final String recordedAt;
  final String? syncStatus; // for local cache: PENDING / SYNCED

  ActivityRecord({
    required this.recordId,
    required this.categoryId,
    required this.source,
    required this.points,
    this.memo,
    required this.recordedAt,
    this.syncStatus,
  });

  factory ActivityRecord.fromJson(Map<String, dynamic> json) {
    return ActivityRecord(
      recordId: json['recordId'],
      categoryId: json['categoryId'],
      source: json['source'] == 'AUTO_DETECTED' ? RecordSource.autoDetected : RecordSource.manual,
      points: json['points'],
      memo: json['memo'],
      recordedAt: json['recordedAt'],
    );
  }

  Map<String, dynamic> toJson() => {
    'recordId': recordId,
    'categoryId': categoryId,
    'memo': memo,
    'recordedAt': recordedAt,
  };
}
