import 'package:flutter/material.dart';

class AlertError extends StatelessWidget {
  final String message;
  final VoidCallback? onClose;
  const AlertError(this.message, {super.key, this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade400),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onClose != null)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              splashRadius: 18,
              onPressed: onClose,
              tooltip: 'Close',
            ),
        ],
      ),
    );
  }
}
