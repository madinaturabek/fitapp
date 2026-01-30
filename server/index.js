const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const { MongoClient, ObjectId } = require('mongodb');
const nodemailer = require('nodemailer');

const app = express();
app.use(cors());
app.use(express.json({ limit: '5mb' }));

const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/madina';
const MONGO_DB = process.env.MONGO_DB || 'madina';
const MAIL_HOST = process.env.MAIL_HOST;
const MAIL_PORT = Number(process.env.MAIL_PORT || 587);
const MAIL_USER = process.env.MAIL_USER;
const MAIL_PASS = process.env.MAIL_PASS;
const MAIL_FROM = process.env.MAIL_FROM || MAIL_USER;

function validatePassword(password) {
  if (password.length < 6) return 'Минимум 6 символов';
  if (!/[A-Z]/.test(password)) return 'Нужна заглавная буква';
  if (!/[a-z]/.test(password)) return 'Нужна строчная буква';
  if (!/[0-9]/.test(password)) return 'Нужна цифра';
  if (!/[^A-Za-z0-9]/.test(password)) {
    return 'Нужен спец. символ';
  }
  return null;
}

function createTransporter() {
  if (!MAIL_HOST || !MAIL_USER || !MAIL_PASS) return null;
  return nodemailer.createTransport({
    host: MAIL_HOST,
    port: MAIL_PORT,
    secure: MAIL_PORT === 465,
    auth: {
      user: MAIL_USER,
      pass: MAIL_PASS,
    },
  });
}

let client;
let db;
let users;
let workouts;
let resets;

async function initDb() {
  client = new MongoClient(MONGO_URI);
  await client.connect();
  db = client.db(MONGO_DB);
  users = db.collection('users');
  workouts = db.collection('workouts');
  resets = db.collection('password_resets');
  await resets.createIndex({ email: 1, code: 1 }, { unique: true, sparse: true });
  await resets.createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 });
}

app.post('/register', async (req, res) => {
  try {
    const { email, password, name } = req.body || {};
    if (!email || !password || !name) {
      return res.status(400).send('Все поля обязательны');
    }

    const passError = validatePassword(String(password));
    if (passError) return res.status(400).send(passError);

    const existing = await users.findOne({ email });
    if (existing) return res.status(400).send('Пользователь уже существует');

    const hash = await bcrypt.hash(password, 10);
    await users.insertOne({ name, email, password: hash });
    return res.json({ name, email });
  } catch (err) {
    console.error('register error', err);
    return res.status(500).send('Ошибка сервера');
  }
});

app.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body || {};
    if (!email || !password) return res.status(400).send('Email и пароль обязательны');

    const user = await users.findOne({ email });
    if (!user) return res.status(400).send('Пользователь не найден');

    const ok = await bcrypt.compare(password, user.password);
    if (!ok) return res.status(400).send('Неверный пароль');

    return res.json({ name: user.name, email: user.email });
  } catch (err) {
    console.error('login error', err);
    return res.status(500).send('Ошибка сервера');
  }
});

app.get('/users', async (req, res) => {
  try {
    const { email } = req.query || {};
    if (!email) return res.status(400).send('email обязателен');
    const user = await users.findOne({ email });
    if (!user) return res.status(404).send('Пользователь не найден');
    return res.json({ name: user.name, email: user.email });
  } catch (err) {
    console.error('users error', err);
    return res.status(500).send('Ошибка сервера');
  }
});

app.post('/request_reset_code', async (req, res) => {
  const { email } = req.body || {};
  if (!email) return res.status(400).send('Email обязателен');

  const user = await users.findOne({ email });
  if (!user) return res.status(400).send('Пользователь не найден');

  const transporter = createTransporter();
  if (!transporter) return res.status(500).send('Почтовый сервис не настроен');

  const code = String(Math.floor(100000 + Math.random() * 900000));
  const expiresAt = new Date(Date.now() + 10 * 60 * 1000);

  await resets.deleteMany({ email });
  await resets.insertOne({ email, code, expiresAt });

  await transporter.sendMail({
    from: MAIL_FROM,
    to: email,
    subject: 'Код для сброса пароля',
    text: `Ваш код: ${code}. Он действует 10 минут.`,
  });

  return res.json({ status: 'sent' });
});

app.post('/reset_password', async (req, res) => {
  const { email, code, newPassword } = req.body || {};
  if (!email || !code || !newPassword) {
    return res.status(400).send('Email, код и новый пароль обязательны');
  }

  const passError = validatePassword(String(newPassword));
  if (passError) return res.status(400).send(passError);

  const record = await resets.findOne({ email, code: String(code) });
  if (!record) return res.status(400).send('Неверный код');

  const hash = await bcrypt.hash(newPassword, 10);
  await users.updateOne({ email }, { $set: { password: hash } });
  await resets.deleteMany({ email });

  return res.json({ status: 'ok' });
});

app.post('/change_password', async (req, res) => {
  try {
    const { email, currentPassword, newPassword } = req.body || {};
    if (!email || !currentPassword || !newPassword) {
      return res.status(400).send('Email, текущий и новый пароль обязательны');
    }

    const passError = validatePassword(String(newPassword));
    if (passError) return res.status(400).send(passError);

    const user = await users.findOne({ email });
    if (!user) return res.status(400).send('Пользователь не найден');

    const ok = await bcrypt.compare(String(currentPassword), user.password);
    if (!ok) return res.status(400).send('Неверный текущий пароль');

    const hash = await bcrypt.hash(String(newPassword), 10);
    await users.updateOne({ email }, { $set: { password: hash } });
    return res.json({ status: 'ok' });
  } catch (err) {
    console.error('change_password error', err);
    return res.status(500).send('Ошибка сервера');
  }
});

app.post('/workouts', async (req, res) => {
  const payload = req.body || {};
  const userEmail = payload.userEmail;
  if (!userEmail) return res.status(400).send('userEmail обязателен');

  payload.createdAt = new Date().toISOString();
  await workouts.insertOne(payload);
  return res.json({ status: 'ok' });
});

app.get('/workouts', async (req, res) => {
  const email = req.query.email;
  if (!email) return res.status(400).send('email обязателен');

  const items = await workouts
    .find({ userEmail: email })
    .sort({ date: -1 })
    .toArray();

  const normalized = items.map((item) => {
    const map = { ...item };
    map.id = String(map._id);
    delete map._id;
    return map;
  });

  return res.json(normalized);
});

app.get('/workouts/:id', async (req, res) => {
  const { id } = req.params;
  if (!ObjectId.isValid(id)) return res.status(400).send('Некорректный id');

  const item = await workouts.findOne({ _id: new ObjectId(id) });
  if (!item) return res.status(404).send('Не найдено');

  const map = { ...item };
  map.id = String(map._id);
  delete map._id;
  return res.json(map);
});

const port = Number(process.env.PORT || 3000);

initDb()
  .then(() => {
    app.listen(port, '0.0.0.0', () => {
      console.log(`Server running on http://0.0.0.0:${port}`);
    });
  })
  .catch((err) => {
    console.error('DB init failed', err);
    process.exit(1);
  });
