import 'package:flutter/material.dart';
import 'package:todo/controllers/add_edit_task_controller.dart';

import '../utils/app_constants.dart';

class MyTitle extends StatelessWidget {
  final AddEditTaskController controller;
  const MyTitle({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: AppConstants.titleHintText,
          hintStyle: TextStyle(fontSize: 22.0, color: Colors.grey[900], fontWeight: FontWeight.w500,),
          border: InputBorder.none,
        ),
        onChanged: (value) => controller.title.value = value,
        controller: TextEditingController(text: controller.title.value),
        style: TextStyle(fontSize: 22.0, color: Colors.grey[900], fontWeight: FontWeight.w500,),
        maxLines: null,
        textInputAction: TextInputAction.next,
      ),
    );
  }
}
