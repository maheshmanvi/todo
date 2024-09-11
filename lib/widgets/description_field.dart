import 'package:flutter/material.dart';
import 'package:todo/controllers/add_edit_task_controller.dart';

import '../utils/app_constants.dart';

class MyDescription extends StatelessWidget {
  final AddEditTaskController controller;
  const MyDescription({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: AppConstants.descriptionHintText,
          hintStyle: TextStyle(fontSize: 18.0, color: Colors.grey[900], fontWeight: FontWeight.w400),
          border: InputBorder.none,
          // hintStyle: TextStyle(
          //   fontSize: 18.0,
          //   color: Colors.grey[600],
          //   fontWeight: FontWeight.normal,
          // ),
        ),
        onChanged: (value) => controller.description.value = value,
        controller: TextEditingController(text: controller.description.value),
        style: TextStyle(fontSize: 18.0, color: Colors.grey[900], fontWeight: FontWeight.w400,),
        maxLines: null,
        textInputAction: TextInputAction.next,
      ),
    );
  }
}