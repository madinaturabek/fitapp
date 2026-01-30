import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:bcrypt/bcrypt.dart';
import 'package:mongo_dart/mongo_dart.dart';

import 'db.dart'; // <-- подключаем db.dart

Middleware _cors() {
  return (innerHandler) {
    return (request) async {
      const corsHeaders = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type',
        'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
      };

      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: corsHeaders);
      }

      final response = await innerHandler(request);
      return response.change(headers: corsHeaders);
    };
  };
}

String? _validatePassword(String password) {
  if (password.length < 6) return 'Минимум 6 символов';
  if (!RegExp(r'[A-Z]').hasMatch(password)) return 'Нужна заглавная буква';
  if (!RegExp(r'[a-z]').hasMatch(password)) return 'Нужна строчная буква';
  if (!RegExp(r'[0-9]').hasMatch(password)) return 'Нужна цифра';
  if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_+=\\-\\[\\]\\\\/`~;]').hasMatch(password)) {
    return 'Нужен спец. символ';
  }
  return null;
}

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

    final passError = _validatePassword(password.toString());
    if (passError != null) {
      return Response(400, body: passError);
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

  router.post('/reset_password', (Request request) async {
    final payload = jsonDecode(await request.readAsString());
    final email = payload['email'];
    final newPassword = payload['newPassword'];

    if (email == null || newPassword == null) {
      return Response(400, body: 'Email и новый пароль обязательны');
    }

    final passError = _validatePassword(newPassword.toString());
    if (passError != null) {
      return Response(400, body: passError);
    }

    final user = await usersCollection!.findOne({'email': email});
    if (user == null) return Response(400, body: 'Пользователь не найден');

    final hashedPassword = BCrypt.hashpw(newPassword, BCrypt.gensalt());
    await usersCollection!.updateOne(
      where.eq('email', email),
      modify.set('password', hashedPassword),
    );

    return Response.ok('Пароль обновлен');
  });

  router.post('/workouts', (Request request) async {
    final payload = jsonDecode(await request.readAsString());
    final userEmail = payload['userEmail'];
    if (userEmail == null || userEmail.toString().isEmpty) {
      return Response(400, body: 'userEmail обязателен');
    }

    payload['createdAt'] = DateTime.now().toIso8601String();
    await workoutsCollection!.insert(payload);
    return Response.ok(jsonEncode({'status': 'ok'}), headers: {'Content-Type': 'application/json'});
  });

  router.get('/workouts', (Request request) async {
    final email = request.url.queryParameters['email'];
    if (email == null || email.isEmpty) {
      return Response(400, body: 'email обязателен');
    }

    final items = await workoutsCollection!
        .find(where.eq('userEmail', email).sortBy('date', descending: true))
        .toList();

    final normalized = items.map((item) {
      final map = Map<String, dynamic>.from(item);
      final id = map['_id'];
      if (id is ObjectId) {
        map['id'] = id.toHexString();
      }
      map.remove('_id');
      return map;
    }).toList();

    return Response.ok(jsonEncode(normalized), headers: {'Content-Type': 'application/json'});
  });

  router.get('/workouts/<id>', (Request request, String id) async {
    ObjectId? objectId;
    try {
      objectId = ObjectId.parse(id);
    } catch (_) {
      return Response(400, body: 'Некорректный id');
    }

    final item = await workoutsCollection!.findOne(where.id(objectId));
    if (item == null) return Response(404, body: 'Не найдено');

    final map = Map<String, dynamic>.from(item);
    map['id'] = (map['_id'] as ObjectId).toHexString();
    map.remove('_id');
    return Response.ok(jsonEncode(map), headers: {'Content-Type': 'application/json'});
  });

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(_cors())
      .addHandler(router);

  final server = await io.serve(handler, '0.0.0.0', 3000);
  // ignore: avoid_print
  print('Server running on http://${server.address.host}:${server.port}');
}
