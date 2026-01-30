import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart';

final db = Db(
  Platform.environment['MONGO_URI'] ??
      'mongodb+srv://span:1234@cluster0.h047ox6.mongodb.net/madina?appName=Cluster0',
);
DbCollection? usersCollection;
DbCollection? workoutsCollection;

Future<void> initDb() async {
  await db.open();
  usersCollection = db.collection('users');
  workoutsCollection = db.collection('workouts');
  print('MongoDB connected');
}
