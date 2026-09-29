import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';

/// Always-on notification that shows this month's expense and income.
///
/// It runs as an Android foreground service so it cannot be swiped away,
/// and tapping it opens the app on the Transactions (Home) screen.
class ExpenseNotificationService {
  ExpenseNotificationService._();

  static final ExpenseNotificationService instance =
      ExpenseNotificationService._();

  static const int notificationId = 1001;
  static const String payload = 'transactions';
  static const String channelId = 'paisa_mitra_summary';
  static const String channelName = 'Paisa Mitra summary';
  static const String channelDescription =
      'Persistent expense and income summary';

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _serviceStarted = false;

  final NumberFormat _money =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  Future<void>? _initFuture;

  /// Sets up the plugin. Never throws and never waits on the permission
  /// dialog, so a notification problem can't stop the app from starting.
  Future<void> initialize({required void Function() onTap}) {
    return _initFuture ??= _initialize(onTap);
  }

  Future<void> _initialize(void Function() onTap) async {
    void handle(NotificationResponse response) {
      if (response.payload == payload) onTap();
    }

    // Try the dedicated status-bar icon first, fall back to the launcher icon.
    for (final icon in ['@drawable/ic_stat_budget', '@mipmap/ic_launcher']) {
      try {
        await _notifications.initialize(
          InitializationSettings(android: AndroidInitializationSettings(icon)),
          onDidReceiveNotificationResponse: handle,
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
      );

  Future<void> showSummary({
    required int expense,
    required int income,
  }) async {
    try {
      await _initFuture;
      await _show(expense, income);
    } catch (e) {
      debugPrint('Notification update failed: $e');
    }
  }

  Future<void> _show(int expense, int income) async {
    final month = DateFormat('MMMM').format(DateTime.now());
    final title = '$month • Expense ${_money.format(expense)}';
    final body =
        'Income ${_money.format(income)}  •  Balance ${_money.format(income - expense)}';

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
      } catch (_) {
        // Fall back to a plain ongoing notification below.
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
