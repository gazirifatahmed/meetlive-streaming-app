import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../../../../constants/constants.dart';
import '../../../../constants/layout_constant.dart';
import '../../../../widgets/after/castom appbar.dart';
import '../../accountInfornation/views/widget/CastomBtton.dart';
import '../controllers/myprofile_controller.dart';
import 'nickname].dart';

class Nickname extends StatelessWidget {
  const Nickname({super.key});

  @override
  Widget build(BuildContext context) {
    MyprofileController myprofileController = Get.put(MyprofileController());
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Nick name',
      ),
      body: Column(
        children: [
          SizedBox(
            height: kHeight * 0.02,
          ),
          WordCountTextField1(
            controller: myprofileController.nameController,
          ),
          SizedBox(
            height: kHeight * 0.02,
          ),
          CastomAppButton(
            onPressed: () {
              // Get the input text
              myprofileController.profileUpdate(
                id: (authController.userProfile.value.user!.id ?? 0).toInt(),
              );
            },
            buttonText: 'Submit',
          ),
        ],
      ),
    );
  }
}
