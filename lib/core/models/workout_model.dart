class WorkoutModel {
  final String id;
  final String type;
  final String name;
  final DateTime date;
  final int durationSeconds;
  final double distance;
  final int calories;
  final int steps;
  final int avgHeartRate;
  final double avgSpeed;
  final double pace;

  WorkoutModel({
    required this.id,
    required this.type,
    required this.name,
    required this.date,
    required this.durationSeconds,
    required this.distance,
    required this.calories,
    required this.steps,
    required this.avgHeartRate,
    required this.avgSpeed,
    required this.pace,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'date': date.toIso8601String(),
      'durationSeconds': durationSeconds,
      'distance': distance,
      'calories': calories,
      'steps': steps,
      'avgHeartRate': avgHeartRate,
      'avgSpeed': avgSpeed,
      'pace': pace,
    };
  }

  factory WorkoutModel.fromJson(Map<String, dynamic> json) {
    return WorkoutModel(
      id: json['id'],
      type: json['type'],
      name: json['name'],
      date: DateTime.parse(json['date']),
      durationSeconds: json['durationSeconds'],
      distance: json['distance'],
      calories: json['calories'],
      steps: json['steps'],
      avgHeartRate: json['avgHeartRate'],
      avgSpeed: json['avgSpeed'],
      pace: json['pace'],
    );
  }
}
