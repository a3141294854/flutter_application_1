// lib/app.dart
import 'package:flutter/material.dart';
import 'page/home.dart';  // 导入你的首页

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '我的扫描应用',  // 应用名称
      theme: ThemeData(
        primarySwatch: Colors.blue,  // 主题色
        useMaterial3: true,  // 使用 Material 3 设计
      ),
      home: const HomePage(),  // 设置首页
      debugShowCheckedModeBanner: false,  // 去掉右上角 debug 标签
    );
  }
}