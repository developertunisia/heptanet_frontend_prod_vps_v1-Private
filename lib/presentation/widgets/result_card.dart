import 'package:flutter/material.dart';

class ResultCard extends StatelessWidget {
  final bool isSuccess;
  final String message;

  const ResultCard({
    super.key,
    required this.isSuccess,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSuccess ? Colors.grey[100] : Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSuccess ? Colors.black87 : Colors.red,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle_outline : Icons.cancel_outlined,
            color: isSuccess ? Colors.black87 : Colors.red,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isSuccess ? Colors.black87 : Colors.red[900],
              ),
            ),
          ),
        ],
      ),
    );
  }
}