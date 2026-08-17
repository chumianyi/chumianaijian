import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/editor_controller.dart';
import 'controllers/app_controller.dart';
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppController()..init()),
        ChangeNotifierProvider(create: (_) => EditorController()..init()),
      ],
      child: Consumer<AppController>(
        builder: (context, appController, _) {
          return MaterialApp(
            title: '初眠爱剪',
            debugShowCheckedModeBanner: false,
            theme: NeumorphismTheme.lightTheme,
            // 全局UI缩放：通过builder覆盖MediaQuery的textScaler
            builder: (context, child) {
              final mediaQuery = MediaQuery.of(context);
              return MediaQuery(
                data: mediaQuery.copyWith(
                  textScaler: TextScaler.linear(appController.uiScale),
                ),
                child: child!,
              );
            },
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
