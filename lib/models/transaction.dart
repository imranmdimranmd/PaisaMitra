import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../DBhelp/dbhelper.dart';
import '../services/expense_notification_service.dart';

class Transaction {
  final String id;
  final String title;
  final int amount;
  final DateTime date;
  final String category;
  final String? subcategory;
  final bool isIncome;

  const Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    this.subcategory,
    this.isIncome = false,
  });

  Map<String, dynamic> toMap(Transaction t) {
    return {
      'id': t.id,
      'title': t.title,
      'amount': t.amount,
      'date': t.date.toIso8601String(),
      'category': t.category,
      'subcategory': t.subcategory,
      'type': t.isIncome ? 'income' : 'expense',
    };
  }
}

class Transactions with ChangeNotifier {
  List<Transaction> _transactions = [];

  List<Transaction> get transactions => [..._transactions];

  int getTotal(List<Transaction> transaction) => transaction
      .where((item) => !item.isIncome)
      .fold(0, (sum, item) => sum + item.amount);

  int getTotalIncome(List<Transaction> transaction) => transaction
      .where((item) => item.isIncome)
      .fold(0, (sum, item) => sum + item.amount);

  List<Transaction> get expenses =>
      _transactions.where((item) => !item.isIncome).toList();

  Future<void> _refreshNotification() async {
    final now = DateTime.now();
    final thisMonth = _transactions
        .where((t) => t.date.year == now.year && t.date.month == now.month)
        .toList();
    ExpenseNotificationService.instance.showSummary(
      expense: getTotal(thisMonth),
      income: getTotalIncome(thisMonth),
    );
  }

  void addTransactions(Transaction transaction) {
    _transactions.add(transaction);
    notifyListeners();
    DBHelper.insert(transaction);
    _refreshNotification();
  }

  void updateTransaction(Transaction transaction) {
    final index = _transactions.indexWhere((t) => t.id == transaction.id);
    if (index >= 0) {
      _transactions[index] = transaction;
    }
    notifyListeners();
    DBHelper.insert(transaction);
    _refreshNotification();
  }

  List<Transaction> monthlyTransactions(String month, String year) {
    return _transactions.where((trx) {
      if (trx.isIncome) return false;
      if (DateFormat('yyyy').format(trx.date) == year &&
          DateFormat('MMM').format(trx.date) == month) {
        return true;
      }
      return false;
    }).toList();
  }

  List<Transaction> yearlyTransactions(String year) {
    return _transactions.where((trx) {
      if (trx.isIncome) return false;
      return DateFormat('yyyy').format(trx.date) == year;
    }).toList();
  }

  List<Transaction> dailyTransactions() {
    return _transactions.where((trx) {
      if (trx.isIncome) return false;
      return DateUtils.isSameDay(DateTime.now(), trx.date);
    }).toList();
  }

  List<Transaction> get rescentTransactions {
    return transactions.where((tx) {
      if (tx.isIncome) return false;
      return tx.date.isAfter(DateTime.now().subtract(const Duration(days: 7)));
    }).toList();
  }

  Future<void> fetchTransactions() async {
    final fetchedData = await DBHelper.fetch();
    _transactions = fetchedData
        .map(
          (item) => Transaction(
            id: item['id'],
            title: item['title'],
            amount: item['amount'],
            date: DateTime.parse(item['date']),
            category: item['category'],
            subcategory: item['subcategory'] as String?,
            isIncome: item['type'] == 'income',
          ),
        )
        .toList();
    _transactions.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
    _refreshNotification();
  }

  void deleteTransaction(String id) {
    final item = _transactions.firstWhere((item) => item.id == id);
    _transactions.remove(item);
    notifyListeners();
    DBHelper.delete(id);
    _refreshNotification();
  }

  List<Map<String, Object>> firstSixMonthsTransValues(
      List<Transaction> trans, int year) {
    return List.generate(6, (index) {
      final months = [
        DateTime.january,
        DateTime.february,
        DateTime.march,
        DateTime.april,
        DateTime.may,
        DateTime.june,
      ];
      final monthsTitle = [
        'january',
        'february',
        'march',
        'april',
        'may',
        'june',
      ];
      final perMonth = months[index];
      var totalSum = 0;
      for (var i = 0; i < trans.length; i++) {
        if (trans[i].date.month == perMonth && trans[i].date.year == year) {
          totalSum += trans[i].amount;
        }
      }
      return {
        'amount': totalSum.toDouble(),
        'month': monthsTitle[index],
      };
    });
  }

  List<Map<String, Object>> lastSixMonthsTransValues(
      List<Transaction> trans, int year) {
    return List.generate(6, (index) {
      final months = [
        DateTime.july,
        DateTime.august,
        DateTime.september,
        DateTime.october,
        DateTime.november,
        DateTime.december,
      ];
      final monthsTitle = [
        'july',
        'august',
        'september',
        'october',
        'november',
        'december',
      ];
      final perMonth = months[index];
      var totalSum = 0;
      for (var i = 0; i < trans.length; i++) {
        if (trans[i].date.month == perMonth && trans[i].date.year == year) {
          totalSum += trans[i].amount;
        }
      }
      return {
        'amount': totalSum.toDouble(),
        'month': monthsTitle[index],
      };
    });
  }
}
