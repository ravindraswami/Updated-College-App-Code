import 'package:flutter/material.dart';

/// StatusBadge — matches the FormsListScreen's expected 'Pending' / 'Approved' / 'Completed'
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  Color get _bg {
    switch (status) {
      case 'Approved':
        return Colors.blue.shade50;
      case 'Completed':
        return Colors.green.shade50;
      case 'Rejected':
        return Colors.red.shade50;
      default:
        return Colors.amber.shade50;
    }
  }

  Color get _fg {
    switch (status) {
      case 'Approved':
        return Colors.blue.shade700;
      case 'Completed':
        return Colors.green.shade700;
      case 'Rejected':
        return Colors.red.shade700;
      default:
        return Colors.amber.shade800;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _fg.withOpacity(0.4)),
      ),
      child: Text(
        status,
        style: TextStyle(color: _fg, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
