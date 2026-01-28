import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:bcrypt/bcrypt.dart';

import 'db.dart'; // <-- подключаем db.dart

void main() async {
  await initDb();  // <-- инициализация БД

  final router = Router();

  router.post('/register', (Request request) async {
    final payload = jsonDecode(await request.readAsString());
    final email = payload['email'];
    final password = payload['password'];
    final name = payload['name'];

    if (email == null || password == null || name == null) {
      return Response(400, body: 'Все поля обязательны');
    }

    final existingUser = await usersCollection!.findOne({'email': email});
    if (existingUser != null) return Response(400, body: 'Пользователь уже существует');

    final hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());
    await usersCollection!.insert({'name': name, 'email': email, 'password': hashedPassword});

    return Response.ok('Регистрация успешна');
  });

  router.post('/login', (Request request) async {
    final payload = jsonDecode(await request.readAsString());
    final email = payload['email'];
    final password = payload['password'];

    if (email == null || password == null) return Response(400, body: 'Email и пароль обязательны');

    final user = await usersCollection!.findOne({'email': email});
    if (user == null) return Response(400, body: 'Пользователь не найден');

    final isValid = BCrypt.checkpw(password, user['password']);
    if (!isValid) return Response(400, body: 'Неверный пароль');

    return Response.ok(jsonEncode({'name': user['name'], 'email': user['email']}), headers: {'Content-Type': 'application/json'});
  });
