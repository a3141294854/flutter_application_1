


import 'package:flutter/material.dart';
import '../widget/target_device_scan_button.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue.shade50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: TargetDeviceScanButton(
                  onTap: () => print('hello world'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}