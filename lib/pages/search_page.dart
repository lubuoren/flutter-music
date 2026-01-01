import 'package:flutter/material.dart';

class SearchPage extends StatelessWidget {
  final String query;
  final VoidCallback onBack;

  const SearchPage({super.key, required this.query, required this.onBack});

  @override
  Widget build(BuildContext context) {
    // 移除 Scaffold 和 AppBar，它现在是一个纯内容组件
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '“$query” 的搜索结果',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const Divider(),
          const Expanded(child: Center(child: Text("搜索结果列表加载中..."))),
        ],
      ),
    );
  }
}
