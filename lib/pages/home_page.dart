import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.dashboard_outlined, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text("这里是推荐音乐内容区域", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
