import 'package:flutter/material.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 100, color: Colors.grey),
          SizedBox(height: 20),
          Text("Detailed Analytics Coming Soon", style: TextStyle(fontSize: 20, color: Colors.grey)),
        ],
      ),
    );
  }
}