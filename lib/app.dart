import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';

class UncertainEnvelopesApp extends StatelessWidget {
  const UncertainEnvelopesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'uncertain-envelopes-2',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const Scaffold(
        body: Center(
          child: Text('uncertain-envelopes-2'),
        ),
      ),
    );
  }
}
