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
import './screens/security_screen.dart';
import './widgets/pin_gate.dart';
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
  ExpenseNotificationService.instance
      .initialize(onTarget: _handleNotificationTarget);

  runApp(MyApp());
}

/// Runs [action] as soon as the Navigator exists (matters on a cold start
/// from the notification, when the UI isn't built yet).
void _whenNavigatorReady(void Function(NavigatorState nav) action,
    [int tries = 0]) {
  final nav = navigatorKey.currentState;
  if (nav != null) {
    action(nav);
  } else if (tries < 100) {
    Future.delayed(const Duration(milliseconds: 100),
        () => _whenNavigatorReady(action, tries + 1));
  }
}

void _handleNotificationTarget(NotificationTarget target) {
  _whenNavigatorReady((nav) {
    nav.popUntil((route) => route.isFirst); // Home = transactions
    if (target == NotificationTarget.addIncome) {
      nav.push(MaterialPageRoute(
          builder: (_) => const NewTransaction(initialIsIncome: true)));
    } else if (target == NotificationTarget.addExpense) {
      nav.push(MaterialPageRoute(builder: (_) => const NewTransaction()));
    }
  });
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
              IncomeScreen.routeName: (_) =>
                  const PinGate(title: 'Income', child: IncomeScreen()),
              SecurityScreen.routeName: (_) => const SecurityScreen(),
              BackupRestoreScreen.routeName: (_) => const BackupRestoreScreen(),
            },
          );
        });
  }
}
