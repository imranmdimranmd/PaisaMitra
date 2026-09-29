import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../models/transaction.dart';
import './transactions/daily_spendings.dart';
import './transactions/monthly_spendings.dart';
import './transactions/yearly_spendings.dart';
import './new_transaction.dart';
import '../widgets/app_drawer.dart';
import './transactions/weekly_spendings.dart';
import '../widgets/dashboard_summary_cards.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/';
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = new TabController(initialIndex: 0, length: 4, vsync: this);
  }

  @override
  void dispose() {
    super.dispose();
    tabController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Home",
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        bottom: new TabBar(
          unselectedLabelColor: Colors.grey,
          labelColor: Colors.black,
          indicatorColor: Theme.of(context).primaryColorDark,
          tabs: <Widget>[
            new Tab(
              text: "Daily",
            ),
            new Tab(
              text: "Weekly",
            ),
            new Tab(
              text: 'Monthly',
            ),
            new Tab(
              text: 'Yearly',
            ),
          ],
          controller: tabController,
        ),
      ),
      body: Column(
        children: [
          Consumer<Transactions>(
            builder: (context, trx, _) => DashboardSummaryCards(
              transactions: trx,
            ),
          ),
          Expanded(
            child: FutureBuilder(
              future: Provider.of<Transactions>(context, listen: false)
                  .fetchTransactions(),
              builder: (ctx, snapshot) =>
                  (snapshot.connectionState == ConnectionState.waiting)
                      ? Center(child: CircularProgressIndicator())
                      : TabBarView(
                          children: <Widget>[
                            new DailySpendings(),
                            new WeeklySpendings(),
                            new MonthlySpendings(),
                            new YearlySpendings(),
                          ],
                          controller: tabController,
                        ),
            ),
          ),
        ],
      ),
      drawer: Consumer<Transactions>(
        builder: (context, trx, child) {
          return AppDrawer(total: trx.getTotal(trx.transactions));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).pushNamed(NewTransaction.routeName),
        tooltip: 'Add transaction',
        child: const Icon(Icons.add),
      ),
    );
  }
}
