import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/cp_controller.dart';

class CpView extends GetView<CpController> {
  const CpView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CpView'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'CpView is working',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
