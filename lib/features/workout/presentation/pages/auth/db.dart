import 'package:mongo_dart/mongo_dart.dart';

final db = Db('mongodb://localhost:27017/fitness_app');
DbCollection? usersCollection;

Future<void> initDb() async {
  await db.open();
  usersCollection = db.collection('users');
  print('MongoDB connected');
}
