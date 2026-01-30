import 'package:flutter/material.dart';

import '../../../../core/localization/app_lang.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Жаттығу тарихы', 'История тренировок')),
      ),
      body: const Center(
        child: SizedBox.shrink(),
      ),
    );
  }
}
