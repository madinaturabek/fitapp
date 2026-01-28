// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
//
// // ============ СТРАНИЦА ВХОДА/РЕГИСТРАЦИИ ============
//
// class AuthPage extends StatefulWidget {
//   const AuthPage({super.key});
//
//   @override
//   State<AuthPage> createState() => _AuthPageState();
// }
//
// class _AuthPageState extends State<AuthPage> {
//   bool _isLogin = true; // true = вход, false = регистрация
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _nameController = TextEditingController();
//   bool _obscurePassword = true;
//
//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     _nameController.dispose();
//     super.dispose();
//   }
//
//   void _handleAuth() {
//     HapticFeedback.mediumImpact();
//
//     // TODO: Здесь будет реальная авторизация через API/Firebase
//     // Пока просто переходим на профиль
//
//     Navigator.pushReplacementNamed(context, '/profile');
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               Color(0xFF0d111d),
//               Color(0xFF1a1f3a),
//               Color(0xFF0d111d),
//             ],
//           ),
//         ),
//         child: SafeArea(
//           child: CustomScrollView(
//             physics: const BouncingScrollPhysics(),
//             slivers: [
//               SliverFillRemaining(
//                 hasScrollBody: false,
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 24),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       const Spacer(),
//
//                       // Логотип/Иконка
//                       Container(
//                         width: 100,
//                         height: 100,
//                         decoration: BoxDecoration(
//                           gradient: const LinearGradient(
//                             colors: [Color(0xFF00D9FF), Color(0xFFFA0F54)],
//                           ),
//                           borderRadius: BorderRadius.circular(30),
//                         ),
//                         child: const Icon(
//                           Icons.fitness_center_rounded,
//                           size: 50,
//                           color: Colors.white,
//                         ),
//                       ),
//
//                       const SizedBox(height: 32),
//
//                       // Заголовок
//                       Text(
//                         _isLogin ? 'Вход' : 'Регистрация',
//                         style: const TextStyle(
//                           fontSize: 32,
//                           fontWeight: FontWeight.w700,
//                           color: Colors.white,
//                           letterSpacing: -0.5,
//                         ),
//                       ),
//
//                       const SizedBox(height: 8),
//
//                       Text(
//                         _isLogin
//                             ? 'Войдите в свой аккаунт'
//                             : 'Создайте новый аккаунт',
//                         style: const TextStyle(
//                           fontSize: 15,
//                           color: Colors.white60,
//                         ),
//                       ),
//
//                       const SizedBox(height: 40),
//
//                       // Форма
//                       if (!_isLogin)
//                         _buildTextField(
//                           controller: _nameController,
//                           label: 'Имя',
//                           icon: Icons.person_outline_rounded,
//                           keyboardType: TextInputType.name,
//                         ),
//
//                       if (!_isLogin) const SizedBox(height: 16),
//
//                       _buildTextField(
//                         controller: _emailController,
//                         label: 'Email',
//                         icon: Icons.email_outlined,
//                         keyboardType: TextInputType.emailAddress,
//                       ),
//
//                       const SizedBox(height: 16),
//
//                       _buildTextField(
//                         controller: _passwordController,
//                         label: 'Пароль',
//                         icon: Icons.lock_outline_rounded,
//                         isPassword: true,
//                         obscureText: _obscurePassword,
//                         onTogglePassword: () {
//                           setState(() => _obscurePassword = !_obscurePassword);
//                         },
//                       ),
//
//                       if (_isLogin) const SizedBox(height: 12),
//
//                       if (_isLogin)
//                         Align(
//                           alignment: Alignment.centerRight,
//                           child: TextButton(
//                             onPressed: () {
//                               HapticFeedback.lightImpact();
//                               // TODO: Восстановление пароля
//                             },
//                             child: const Text(
//                               'Забыли пароль?',
//                               style: TextStyle(
//                                 color: Color(0xFF00D9FF),
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           ),
//                         ),
//
//                       const SizedBox(height: 32),
//
//                       // Кнопка входа/регистрации
//                       GestureDetector(
//                         onTap: _handleAuth,
//                         child: Container(
//                           width: double.infinity,
//                           padding: const EdgeInsets.symmetric(vertical: 16),
//                           decoration: BoxDecoration(
//                             gradient: const LinearGradient(
//                               colors: [Color(0xFF00D9FF), Color(0xFF4a90e2)],
//                             ),
//                             borderRadius: BorderRadius.circular(14),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: const Color(0xFF00D9FF).withOpacity(0.3),
//                                 blurRadius: 20,
//                                 offset: const Offset(0, 10),
//                               ),
//                             ],
//                           ),
//                           child: Center(
//                             child: Text(
//                               _isLogin ? 'Войти' : 'Зарегистрироваться',
//                               style: const TextStyle(
//                                 fontSize: 17,
//                                 fontWeight: FontWeight.w700,
//                                 color: Colors.white,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//
//                       const SizedBox(height: 24),
//
//                       // Разделитель
//                       Row(
//                         children: [
//                           Expanded(
//                             child: Container(
//                               height: 1,
//                               color: Colors.white24,
//                             ),
//                           ),
//                           const Padding(
//                             padding: EdgeInsets.symmetric(horizontal: 16),
//                             child: Text(
//                               'или',
//                               style: TextStyle(color: Colors.white54),
//                             ),
//                           ),
//                           Expanded(
//                             child: Container(
//                               height: 1,
//                               color: Colors.white24,
//                             ),
//                           ),
//                         ],
//                       ),
//
//                       const SizedBox(height: 24),
//
//                       // Социальные сети
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           _buildSocialButton(Icons.g_mobiledata_rounded),
//                           const SizedBox(width: 16),
//                           _buildSocialButton(Icons.apple_rounded),
//                           const SizedBox(width: 16),
//                           _buildSocialButton(Icons.facebook_rounded),
//                         ],
//                       ),
//
//                       const Spacer(),
//
//                       // Переключение вход/регистрация
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Text(
//                             _isLogin
//                                 ? 'Нет аккаунта?'
//                                 : 'Уже есть аккаунт?',
//                             style: const TextStyle(
//                               color: Colors.white60,
//                               fontSize: 15,
//                             ),
//                           ),
//                           TextButton(
//                             onPressed: () {
//                               setState(() => _isLogin = !_isLogin);
//                               HapticFeedback.selectionClick();
//                             },
//                             child: Text(
//                               _isLogin ? 'Зарегистрироваться' : 'Войти',
//                               style: const TextStyle(
//                                 color: Color(0xFF00D9FF),
//                                 fontSize: 15,
//                                 fontWeight: FontWeight.w700,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//
//                       const SizedBox(height: 16),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String label,
//     required IconData icon,
//     TextInputType? keyboardType,
//     bool isPassword = false,
//     bool obscureText = false,
//     VoidCallback? onTogglePassword,
//   }) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.05),
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(
//           color: Colors.white.withOpacity(0.1),
//           width: 1,
//         ),
//       ),
//       child: TextField(
//         controller: controller,
//         obscureText: isPassword && obscureText,
//         keyboardType: keyboardType,
//         style: const TextStyle(color: Colors.white, fontSize: 16),
//         decoration: InputDecoration(
//           labelText: label,
//           labelStyle: const TextStyle(color: Colors.white54),
//           prefixIcon: Icon(icon, color: const Color(0xFF00D9FF)),
//           suffixIcon: isPassword
//               ? IconButton(
//             onPressed: onTogglePassword,
//             icon: Icon(
//               obscureText
//                   ? Icons.visibility_off_outlined
//                   : Icons.visibility_outlined,
//               color: Colors.white54,
//             ),
//           )
//               : null,
//           border: InputBorder.none,
//           contentPadding: const EdgeInsets.symmetric(
//             horizontal: 20,
//             vertical: 16,
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSocialButton(IconData icon) {
//     return GestureDetector(
//       onTap: () => HapticFeedback.lightImpact(),
//       child: Container(
//         width: 56,
//         height: 56,
//         decoration: BoxDecoration(
//           color: Colors.white.withOpacity(0.05),
//           borderRadius: BorderRadius.circular(14),
//           border: Border.all(
//             color: Colors.white.withOpacity(0.1),
//             width: 1,
//           ),
//         ),
//         child: Icon(
//           icon,
//           color: Colors.white,
//           size: 28,
//         ),
//       ),
//     );
//   }
// }
