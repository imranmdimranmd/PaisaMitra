import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Where the user wants to go after using the notification.
enum NotificationTarget { transactions, addIncome, addExpense }

/// Always-on notification with two quick-action buttons:
///  * "Add Income"  -> opens the new income entry screen
///  * "Add Expense" -> opens the new expense entry screen
/// Tapping the notification itself opens the Transactions (Home) screen.
///
/// It runs as an Android foreground service so it can't be swiped away.
class ExpenseNotificationService {
  ExpenseNotificationService._();

  static final ExpenseNotificationService instance =
      ExpenseNotificationService._();

  static const int notificationId = 1001;
  static const String payload = 'transactions';
  static const String actionIncome = 'add_income';
  static const String actionExpense = 'add_expense';

  static const String channelId = 'paisa_mitra_quick_add';
  static const String channelName = 'Paisa Mitra quick add';
  static const String channelDescription =
      'Persistent notification to quickly add income or expense';

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _serviceStarted = false;
  Future<void>? _initFuture;

  /// Sets up the plugin and shows the notification. Never throws and never
  /// waits on the permission dialog, so a notification problem can't stop
  /// the app from starting.
  Future<void> initialize({
    required void Function(NotificationTarget target) onTarget,
  }) {
    return _initFuture ??= _initialize(onTarget);
  }

  void _dispatch(
    NotificationResponse response,
    void Function(NotificationTarget target) onTarget,
  ) {
    switch (response.actionId) {
      case actionIncome:
        onTarget(NotificationTarget.addIncome);
        break;
      case actionExpense:
        onTarget(NotificationTarget.addExpense);
        break;
      default:
        if (response.payload == payload) {
          onTarget(NotificationTarget.transactions);
        }
    }
  }

  Future<void> _initialize(
    void Function(NotificationTarget target) onTarget,
  ) async {
    // Try the dedicated status-bar icon first, fall back to the launcher icon.
    for (final icon in ['@drawable/ic_stat_budget', '@mipmap/ic_launcher']) {
      try {
        await _notifications.initialize(
          InitializationSettings(android: AndroidInitializationSettings(icon)),
          onDidReceiveNotificationResponse: (r) => _dispatch(r, onTarget),
        );
        break;
      } catch (e) {
        debugPrint('Notification init with $icon failed: $e');
      }
    }

    try {
      final android = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(const AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDescription,
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
        showBadge: false,
      ));
      // Fire and forget: the system dialog must not block app start-up.
      unawaited(android?.requestNotificationsPermission());
    } catch (e) {
      debugPrint('Notification channel setup failed: $e');
    }

    // App was cold-started by tapping the notification or one of its buttons.
    try {
      final launch = await _notifications.getNotificationAppLaunchDetails();
      final response = launch?.notificationResponse;
      if ((launch?.didNotificationLaunchApp ?? false) && response != null) {
        _dispatch(response, onTarget);
      }
    } catch (e) {
      debugPrint('Launch details failed: $e');
    }

    try {
      await _show();
    } catch (e) {
      debugPrint('Notification show failed: $e');
    }
  }

  AndroidNotificationDetails get _details => AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        autoCancel: false,
        onlyAlertOnce: true,
        playSound: false,
        enableVibration: false,
        showWhen: false,
        category: AndroidNotificationCategory.status,
        visibility: NotificationVisibility.public,
        styleInformation: const BigTextStyleInformation(
          'Tap a button to add a new income or expense.',
        ),
        actions: const <AndroidNotificationAction>[
          AndroidNotificationAction(
            actionIncome,
            'Add Income',
            showsUserInterface: true,
            cancelNotification: false,
          ),
          AndroidNotificationAction(
            actionExpense,
            'Add Expense',
            showsUserInterface: true,
            cancelNotification: false,
          ),
        ],
      );

  Future<void> _show() async {
    const title = 'Paisa Mitra';
    const body = 'Tap a button to add a new income or expense.';

    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (!_serviceStarted && android != null) {
      // Foreground service => notification stays even if the user swipes.
      try {
        await android.startForegroundService(
          notificationId,
          title,
          body,
          notificationDetails: _details,
          payload: payload,
          foregroundServiceTypes: {
            AndroidServiceForegroundType.foregroundServiceTypeSpecialUse,
          },
        );
        _serviceStarted = true;
        return;
      } catch (e) {
        debugPrint('Foreground service failed, using plain notification: $e');
      }
    }

    await _notifications.show(
      notificationId,
      title,
      body,
      NotificationDetails(android: _details),
      payload: payload,
    );
  }

  Future<void> cancel() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (_serviceStarted) {
      await android?.stopForegroundService();
      _serviceStarted = false;
    }
    await _notifications.cancel(notificationId);
  }
}
