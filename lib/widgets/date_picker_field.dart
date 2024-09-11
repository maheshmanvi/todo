import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:todo/controllers/add_edit_task_controller.dart';

class DatePickerField extends StatelessWidget {
  final String label;
  final RxString dateObservable;
  final AddEditTaskController controller;
  final DateTime? firstDate;
  final ValueChanged<DateTime> onDateSelected;

  const DatePickerField({
    super.key,
    required this.label,
    required this.dateObservable,
    required this.controller,
    this.firstDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        // Parse dateObservable if it has a value, otherwise use DateTime.now()
        final initialDate = dateObservable.value.isNotEmpty
            ? DateFormat('dd-MM-yyyy').parse(dateObservable.value)
            : DateTime.now();

        // final date = await showDatePicker(
        //   context: context,
        //   initialDate: firstDate ?? DateTime.now(),
        //   firstDate: firstDate ?? DateTime(2000),
        //   lastDate: DateTime(2101),
        // );


        final date = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: firstDate ?? DateTime(2000),
          lastDate: DateTime(2101),
        );

        if (date != null) {
          final formattedDate = DateFormat('dd-MM-yyyy').format(date);
          dateObservable.value = formattedDate;
          onDateSelected(date);
        }
      },
      child: Obx(() {
        // final dateText = dateObservable.value.isNotEmpty
        //     ? dateObservable.value
        //     : 'Date';
        if (dateObservable.value.isEmpty) {
          final currentDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
          dateObservable.value = currentDate;
        }
        final formattedDate = formatDateToTextVariant1(dateObservable.value);
        return Text(
          formattedDate,
          style: TextStyle(
            color: Colors.grey[900],
            fontSize: 17.0,
          ),
        );
      }),
    );
  }

  // Method to get the formatted date text
  String formatDateToText(String date) {
    DateTime taskDate = DateFormat('dd-MM-yyyy').parse(date);
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime tomorrow = today.add(const Duration(days: 1));
    DateTime yesterday = today.subtract(const Duration(days: 1));

    if (taskDate == today) {
      return "Today";
    } else if (taskDate == tomorrow) {
      return "Tomorrow";
    } else if (taskDate == yesterday) {
      return "Yesterday";
    } else {
      return DateFormat('dd MMMM yyyy').format(
          taskDate); // e.g., "25 August 2024"
    }
  }

  // Method to get the formatted date text in "Wed, 28 Aug 2024" format
  String formatDateToTextVariant1(String date) {
    DateTime taskDate = DateFormat('dd-MM-yyyy').parse(date);
    return DateFormat('EEE, dd MMM yyyy').format(taskDate); // e.g., "Wed, 28 Aug 2024"
  }


  // Method to get the formatted date text with specific labels for today, tomorrow, and yesterday, and "Wed, 28 Aug 2024" format for other dates
  String formatDateToTextVariant2(String date) {
    DateTime taskDate = DateFormat('dd-MM-yyyy').parse(date);
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime tomorrow = today.add(const Duration(days: 1));
    DateTime yesterday = today.subtract(const Duration(days: 1));

    if (taskDate == today) {
      return "Today";
    } else if (taskDate == tomorrow) {
      return "Tomorrow";
    } else if (taskDate == yesterday) {
      return "Yesterday";
    } else {
      return DateFormat('EEE, dd MMM yyyy').format(taskDate); // e.g., "Wed, 28 Aug 2024"
    }
  }


  // Method to get the formatted time text
  String formatTimeTo12Hour(String time) {
    DateTime dateTime = DateFormat('HH:mm:ss').parse(time);
    return DateFormat('hh:mm a').format(dateTime); // 12-hour format with AM/PM
  }

  // Helper method to parse datetime from date and time strings
  DateTime? parseDateTime(String? date, String? time) {
    if (date == null || date.isEmpty || time == null || time.isEmpty) {
      return null;
    }

    try {
      final dateFormat = DateFormat('dd-MM-yyyy');
      final timeFormat = DateFormat('HH:mm:ss');
      final dateTime = dateFormat.parse(date);
      final parsedTime = timeFormat.parse(time);

      return DateTime(
          dateTime.year, dateTime.month, dateTime.day, parsedTime.hour,
          parsedTime.minute, parsedTime.second);
    } catch (e) {
      log('Failed to parse date/time: $e');
      return null;
    }
  }


}
