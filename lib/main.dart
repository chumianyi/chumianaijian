import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/editor_controller.dart';
import 'theme/neumorphism_theme.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ChumianAijianApp());
}

class ChumianAijianApp extends StatelessWidget {
  const ChumianAijianApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EditorController()..init(),
      child: MaterialApp(
        title: '初眠爱剪',
        debugShowCheckedModeBanner: false,
        theme: NeumorphismTheme.lightTheme,
        home: const HomeScreen(),
      ),
    );
  }
}
