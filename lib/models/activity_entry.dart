import 'enums.dart';
import '../utils/date_utils.dart';

class ActivityEntry {
  final int? id;
  final DateTime date;
  final ActivityType type;
  final int durationMinutes;
  final double caloriesBurned;

  const ActivityEntry({
    this.id,
    required this.date,
    required this.type,
    required this.durationMinutes,
    required this.caloriesBurned,
  });

  factory ActivityEntry.fromMap(Map<String, dynamic> map) {
    return ActivityEntry(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      type: ActivityType.fromDb(map['type'] as String),
      durationMinutes: map['durationMinutes'] as int,
      caloriesBurned: (map['caloriesBurned'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': dateKey(date),
      'type': type.name,
      'durationMinutes': durationMinutes,
      'caloriesBurned': caloriesBurned,
    };
  }

  ActivityEntry copyWith({
    int? id,
    DateTime? date,
    ActivityType? type,
    int? durationMinutes,
    double? caloriesBurned,
  }) {
    return ActivityEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      type: type ?? this.type,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
    );
  }
}
