import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/official_message_controller.dart';

class DummymessageView extends GetView {
  const DummymessageView({super.key});

  @override
  Widget build(BuildContext context) {
    final officialMessageController = Get.put(OfficialMessageController());
    return Scaffold(
      appBar: buildAppBar(),
      // body: Body(),
      body: Center(
          child: FutureBuilder(
              future: officialMessageController.fetchRecharge(),
              builder: (context, snapshot) {
                return Obx(() {
                  return ListView.builder(
                      itemCount:
                          officialMessageController.recharageMessageList.length,
                      itemBuilder: (context, index) {
                        return officialMessageController
                                    .recharageMessageList[index]['info'] ==
                                'recharge coins from admin'
                            ? Container(
                                decoration: BoxDecoration(
                                    color: Colors.deepPurple,
                                    borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.all(5),
                                margin: const EdgeInsets.only(
                                    top: 2, left: 5, bottom: 10, right: 80),
                                height: 100,
                                width: 300,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Text(
                                      '🎉 Recharge Successful: ${officialMessageController.recharageMessageList[index]['amount']} Diamond Added to Your Balance! 📱',
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    const Text(
                                      'Please check your balance and enjoy it.!',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                              )
                            : Container();
                      });
                });
              })),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            onPressed: () => Get.back(),
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.grey,
            ),
            constraints: const BoxConstraints(
              maxHeight: 24,
              maxWidth: 24,
            ),
          ),
          const SizedBox(
            width: 4,
          ),
          const SizedBox(
            width: 250,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Shokh Live Recharge",
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
