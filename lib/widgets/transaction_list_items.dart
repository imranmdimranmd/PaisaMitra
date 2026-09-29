import 'package:paisa_mitra/models/transaction.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../screens/new_transaction.dart';

class TransactionListItems extends StatefulWidget {
  final Transaction trx;
  final Function dltTrxItem;

  const TransactionListItems({
    Key? key,
    required this.trx,
    required this.dltTrxItem,
  }) : super(key: key);
  @override
  _TransactionListItemsState createState() => _TransactionListItemsState();
}

class _TransactionListItemsState extends State<TransactionListItems> {
  Future<void> _confirmDelete(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Are you sure'),
        content:
            const Text('Do you really want to delete this transaction?'),
        actions: [
          TextButton(
              onPressed: () {
                widget.dltTrxItem(widget.trx.id);
                Navigator.pop(context);
              },
              child: Text(
                'Yes',
                style:
                    TextStyle(fontSize: 20, color: Theme.of(context).primaryColor),
              )),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'No',
                style: TextStyle(fontSize: 20),
              ))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryLabel = widget.trx.category;
    final subcategoryLabel = widget.trx.subcategory?.trim() ?? '';
    final subtitle = subcategoryLabel.isEmpty
        ? categoryLabel
        : '$categoryLabel • $subcategoryLabel';
    final avatarInitial =
        categoryLabel.isNotEmpty ? categoryLabel[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor.withOpacity(.15),
            child: Text(
              avatarInitial,
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.trx.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade600),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat.yMMMd().format(widget.trx.date),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${widget.trx.amount}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Theme.of(context).primaryColorDark,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(Icons.edit,
                        size: 20, color: Theme.of(context).primaryColor),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            NewTransaction(existingTransaction: widget.trx),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(Icons.delete,
                        size: 20, color: Theme.of(context).colorScheme.error),
                    onPressed: () => _confirmDelete(context),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
