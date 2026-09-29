import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import './screens/home_screen.dart';
import './screens/new_transaction.dart';
import './models/transaction.dart';
import './models/categories.dart';
import './screens/categories_screen.dart';
import './screens/backup_restore_screen.dart';
import './screens/budgets_screen.dart';
import './screens/income_screen.dart';
import './services/expense_notification_service.dart';

import 'package:provider/provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitDown,
    DeviceOrientation.portraitUp,
  ]);

  // Not awaited: notification setup must never block the first frame.
  // Tapping the notification returns to Home, the Transactions screen.
  ExpenseNotificationService.instance.initialize(
    onTap: () {
      navigatorKey.currentState?.popUntil((route) => route.isFirst);
    },
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => Transactions()),
          ChangeNotifierProvider(create: (_) => Categories()..load()),
        ],
        builder: (context, child) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            title: 'Paisa Mitra',
            theme: ThemeData(
              primaryColor: const Color(0xFFA80852),
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFFA80852),
                secondary: const Color(0xFF4C6FFF),
              ),
              scaffoldBackgroundColor: const Color(0xFFF1F2F4),
              fontFamily: 'Quicksand',
              textTheme: ThemeData.light().textTheme.copyWith(
                    headlineLarge: const TextStyle(
                      fontFamily: 'OpenSans',
                      fontSize: 18,
                      color: Color(0xFF1D2125),
                      fontWeight: FontWeight.bold,
                    ),
                    labelLarge: const TextStyle(
                      color: Color(0xFF1D2125),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                elevation: 0,
                iconTheme: IconThemeData(color: Color(0xFF1D2125)),
                titleTextStyle: TextStyle(
                  fontFamily: 'OpenSans',
                  fontSize: 24,
                  color: Color(0xFF1D2125),
                ),
              ),
            ),
            routes: {
              HomeScreen.routeName: (_) => HomeScreen(),
              NewTransaction.routeName: (_) => NewTransaction(),
              CategoriesScreen.routeName: (_) => const CategoriesScreen(),
              BudgetsScreen.routeName: (_) => const BudgetsScreen(),
              IncomeScreen.routeName: (_) => const IncomeScreen(),
              BackupRestoreScreen.routeName: (_) => const BackupRestoreScreen(),
            },
          );
        });
  }
}
