import 'package:paisa_mitra/screens/home_screen.dart';
import 'package:paisa_mitra/screens/categories_screen.dart';
import 'package:paisa_mitra/screens/backup_restore_screen.dart';
import 'package:paisa_mitra/screens/budgets_screen.dart';
import 'package:paisa_mitra/screens/income_screen.dart';
import 'package:paisa_mitra/screens/security_screen.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AppDrawer extends StatelessWidget {
  final int total;

  const AppDrawer({
    Key? key,
    required this.total,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/app_logo.png',
                  width: 34,
                  height: 34,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Paisa Mitra',
                style: Theme.of(context).appBarTheme.titleTextStyle,
              ),
            ],
          ),
        ),
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Expanded(
              child: ListView(
                shrinkWrap: true,
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.home),
                    title: const Text("Home"),
                    onTap: () {
                      Navigator.of(context)
                          .pushReplacementNamed(HomeScreen.routeName);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.category_outlined),
                    title: const Text("Categories"),
                    onTap: () {
                      Navigator.of(context).pushNamed(CategoriesScreen.routeName);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.account_balance_wallet_outlined),
                    title: const Text("Budgets"),
                    onTap: () => Navigator.of(context).pushNamed(BudgetsScreen.routeName),
                  ),
                  ListTile(
                    leading: const Icon(Icons.trending_up),
                    title: const Text("Income"),
                    onTap: () => Navigator.of(context).pushNamed(IncomeScreen.routeName),
                  ),
                  ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: const Text("Security (PIN)"),
                    onTap: () => Navigator.of(context).pushNamed(SecurityScreen.routeName),
                  ),
                  ListTile(
                    leading: const Icon(Icons.backup_outlined),
                    title: const Text("Backup & Restore"),
                    onTap: () {
                      Navigator.of(context)
                          .pushNamed(BackupRestoreScreen.routeName);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.mail),
                    title: Text("Contact Us"),
                    onTap: () async {
                      Navigator.of(context).pop();

                      try {
                        final Uri emailUri = Uri.parse(
                            'mailto:mohammadimran393@gmail.com?subject=Paisa%20Mitra%20Support&body=Contact Reason: ');

                        if (await canLaunchUrl(emailUri)) {
                          await launchUrl(emailUri);
                        } else {
                          // Fallback: show simple dialog with just email
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('Contact Us'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Email us at:'),
                                    SizedBox(height: 10),
                                    SelectableText(
                                      'mohammadimran393@gmail.com',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text('Close'),
                                  ),
                                ],
                              );
                            },
                          );
                        }
                      } catch (e) {
                        // Show simple dialog if anything goes wrong
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Contact Us'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Email us at:'),
                                  SizedBox(height: 10),
                                  SelectableText(
                                    'mohammadimran393@gmail.com',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Text('Close'),
                                ),
                              ],
                            );
                          },
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Text(
                    'Total: ₹$total',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
