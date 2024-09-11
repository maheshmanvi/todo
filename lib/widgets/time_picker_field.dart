import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:todo/controllers/add_edit_task_controller.dart';

class TimePickerField extends StatelessWidget {
  final String label;
  final RxString timeObservable;
  final AddEditTaskController controller;
  final ValueChanged<DateTime> onTimeSelected;

  const TimePickerField({
    super.key,
    required this.label,
    required this.timeObservable,
    required this.controller,
    required this.onTimeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(

      onTap: () async {
        final initialTime = timeObservable.value.isNotEmpty
            ? TimeOfDay(
          hour: int.parse(timeObservable.value.split(':')[0]),
          minute: int.parse(timeObservable.value.split(':')[1]),
        )
            : TimeOfDay.now();

        final timeOfDay = await showTimePicker(
          context: context,
          initialTime: initialTime,
        );

        if (timeOfDay != null) {
          final now = DateTime.now();
          final time = DateTime(
            now.year,
            now.month,
            now.day,
            timeOfDay.hour,
            timeOfDay.minute,
          );

          // Assuming you have a method to set the start time
          // controller.setStartTime(time);

          // Format the selected time to display
          timeObservable.value = controller.formatTime(time);
          onTimeSelected(time);
        }
      },
      child: Obx(() {
        // final timeText = timeObservable.value.isNotEmpty
        //     ? formatTime(timeObservable.value)
        //     : 'Time';
        if (timeObservable.value.isEmpty) {
          final nowDateTime = DateTime.now();
          timeObservable.value = controller.formatTime(nowDateTime);
        }
        final formattedTime = formatTime(timeObservable.value);
        return Text(
          formattedTime,
          style: TextStyle(
            color: Colors.grey[900],
            fontSize: 17.0,
          ),
        );
      }),
    );
  }

  String formatTime(String time) {
    try {
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final DateFormat formatter = DateFormat('h:mm a');
      final dateTime = DateTime(0, 0, 0, hour, minute);
      String formattedTime = formatter.format(dateTime);

      // Convert AM/PM to lowercase
      formattedTime = formattedTime.replaceAll('AM', 'am').replaceAll('PM', 'pm');

      return formattedTime;
    } catch (e) {
      log('ERROR TimePickerField.formatTime: Invalid time : $e');
      return 'Invalid time';
    }
  }



}
