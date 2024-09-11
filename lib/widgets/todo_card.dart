import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:todo/model/task_model.dart';

import '../controllers/home_screen_controller.dart';

class TodoCard extends StatefulWidget {
  final TaskModel task;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onSelectionChange;
  final bool isDeleteMode; // New parameter for delete mode

  const TodoCard({
    super.key,
    required this.task,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    required this.onSelectionChange,
    required this.isDeleteMode, // Initialize isDeleteMode
  });


  @override
  _TodoCardState createState() => _TodoCardState();
}

class _TodoCardState extends State<TodoCard> {
  final controller = Get.put(HomeScreenController());

  @override
  Widget build(BuildContext context) {


    // // Clear and assign color values based on task status
    // final checkboxColor = _getColorBasedOnTaskStatus(
    //     widget.task.taskStatus.value ?? 0);
    final statusColor = _getColorBasedOnTaskStatus(
        widget.task.taskStatus.value ?? 0);

    // Log the color values to ensure correct assignment
    // log('_buildCheckbox: color: $checkboxColor, task status: ${widget.task
    //     .taskStatus.value}');
    // log('_buildStatusIndicator: backgroundColor: $statusColor, id: ${widget.task
    //     .id}, task status: ${widget.task.taskStatus.value}');

    // // Set the card color based on the selection and delete mode status
    // Color? cardColor = widget.isSelected && widget.isDeleteMode
    //     ? Colors.grey[400] // Light dark color when selected in delete mode
    //     : widget.isSelected
    //     ? Colors.grey[300] // Selected color when not in delete mode
    //     : Colors.grey[50];  // Default card color

    return GestureDetector(
      onTap: (){
        if (widget.isDeleteMode) {
          // Toggle selection when in delete mode
          widget.onSelectionChange();
        } else {
          widget.onTap(); // Regular tap behavior
        }
      },
      onLongPress: () {
        widget.onLongPress();
        widget.onSelectionChange();
      },
      child: Card(
        // color: widget.isSelected ? Theme.of(context).colorScheme.onTertiary : Colors.grey[50],
        // color: widget.isSelected ? Color.fromARGB(250, 200, 200, 200) : Colors.grey[50],
        color: widget.isSelected && widget.isDeleteMode
            ? Colors.grey[300]
            : Colors.grey[50],

        margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        elevation: 5.0,
        shadowColor: Colors.grey.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // First Row: Checkbox, Title, and Priority
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Interactive Checkbox based on taskStatus
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (widget.task.taskStatus.value == 1) {
                          // Uncheck - Reset task status based on the current date and time
                          widget.task.taskStatus.value = 2; // Set back to pending
                          updateTaskStatusPeriodically(widget.task); // Re-evaluate status
                          controller.updateTaskStatus(widget.task);
                        } else {
                          // Check - Mark task as complete
                          widget.task.taskStatus.value = 1;
                          controller.updateTaskStatus(widget.task);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(1.0, 1.0, 7.0, 1.0),
                      margin: const EdgeInsets.only(right: 1.0),
                      child: Icon(
                        widget.task.taskStatus.value == 1
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        // color: checkboxColor,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Text(
                        widget.task.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.0,
                          color: Colors.black87,
                          decoration: widget.task.taskStatus.value == 1
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  if (widget.task.priority != "No priority set" && widget.task.priority!.isNotEmpty ?? false) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: _getColorBasedOnPriority(widget.task.priority!),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Center(
                        child: Text(
                          '${widget.task.priority}',
                          style: const TextStyle(
                            fontSize: 14.0,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8.0),
              // Second Row: Status, Start Date, Start Time, and Repeat
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        // Status based on taskStatus
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 4.0),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Text(
                            widget.task.taskStatus.value == 1
                                ? "Completed"
                                : widget.task.taskStatus.value == 0
                                ? "Overdue"
                                : "Pending",
                            style: const TextStyle(
                              fontSize: 14.0,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (widget.task.startDate?.isNotEmpty ?? false) ...[
                          Container(
                            margin: const EdgeInsets.only(left: 16.0),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_month_rounded, size: 16,
                                    color: Colors.grey[600]),
                                const SizedBox(width: 4.0),
                                Text(
                                  formatDateToText(widget.task.startDate!),
                                  style: const TextStyle(
                                    fontSize: 14.0,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(width: 10,),
                        if (widget.task.startTime?.isNotEmpty ?? false) ...[
                          Row(
                            children: [
                              Icon(Icons.access_time_rounded, size: 16,
                                  color: Colors.grey[600]),
                              const SizedBox(width: 4.0),
                              Text(
                                formatTimeTo12Hour(widget.task.startTime!),
                                style: const TextStyle(
                                  fontSize: 14.0,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getColorBasedOnPriority(String priority) {
    switch (priority) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getColorBasedOnTaskStatus(int taskStatus) {
    switch (taskStatus) {
      case 1:
        return Colors.green;
      case 0:
        return Colors.red;
      case 2:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // Method to get the formatted date text
  String formatDateToText(String? date) {
    if (date == null || date.isEmpty) {
      return "Invalid Date";
    }

    try {
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
        // return DateFormat('dd MMMM yyyy').format(taskDate);
        return DateFormat('EEE, dd MMM yyyy').format(taskDate);
      }
    } catch (e) {
      log('Date parsing error: $e');
      return "Invalid Date";
    }
  }

  // Method to get the formatted time text
  String formatTimeTo12Hour(String? time) {
    if (time == null || time.isEmpty) {
      return "Invalid Time";
    }

    try {
      DateTime dateTime = DateFormat('HH:mm:ss').parse(time);
      return DateFormat('hh:mm a').format(dateTime).replaceAll('AM', 'am').replaceAll('PM', 'pm');
    } catch (e) {
      log('Time parsing error: $e');
      return "Invalid Time";
    }
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


  // Method to update task status periodically
  void updateTaskStatusPeriodically(TaskModel task) {
    DateTime? startDateTime = parseDateTime(task.startDate, task.startTime);
    DateTime? endDateTime;

    // Parse endDate and endTime if they're not null and not empty
    if (task.endDate != null && task.endDate!.isNotEmpty &&
        task.endTime != null && task.endTime!.isNotEmpty) {
      endDateTime = parseDateTime(task.endDate, task.endTime);
    }

    // Return early if startDateTime is null (no valid start date/time)
    if (startDateTime == null) return;

    DateTime currentDateTime = DateTime.now();

    // If the task has started
    if (startDateTime.isBefore(currentDateTime)) {
      // If endDateTime is present and has passed, mark task as complete (status 0)
      if (endDateTime != null && endDateTime.isBefore(currentDateTime)) {
        if (task.taskStatus.value != 1) {
          task.taskStatus.value = 0; // Set to 0 if task status is not 1 (complete)
        }
      } else {
        // If the task is ongoing, mark it as ongoing (status 2)
        if (endDateTime != null && endDateTime.isAfter(currentDateTime)) {
          if (task.taskStatus.value != 1) {
            task.taskStatus.value = 2; // Set to 2 (ongoing) if status is not 1
          }
        } else {
          // If endDateTime is not defined, keep the task ongoing until further notice
          if (task.taskStatus.value != 1) {
            task.taskStatus.value = 0; // Set to 2 (ongoing) if status is not 1
          }
        }
      }
    } else {
      // If the task has not started yet, set status to 2 (upcoming)
      if (task.taskStatus.value != 1) {
        task.taskStatus.value = 2; // Set to 2 (upcoming) if status is not 1
      }
    }

    log('updateTaskStatusPeriodically: ${task.id}, ${task.title} status: ${task.taskStatus.value}, start: ${task.startDate} ${task.startTime}, end: ${task.endDate} ${task.endTime}');
  }

}