import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:todo/screens/add_edit_task.dart';

import '../model/task_model.dart';
import '../controllers/home_screen_controller.dart';

class TaskBottomSheetContent extends StatefulWidget {
  final TaskModel task;


  const TaskBottomSheetContent({super.key, required this.task});

  @override
  State<TaskBottomSheetContent> createState() => _TaskBottomSheetContentState();
}

class _TaskBottomSheetContentState extends State<TaskBottomSheetContent> {
  final controller = Get.put(HomeScreenController());

  // Observable list for the selected notifications (multiple selections)
  var taskNotifications = <String>[].obs;


  @override
  void initState() {
    // Convert the notification string to a list and assign it to taskNotifications
    taskNotifications.value = widget.task.notification!.value.split(', ').where((item) => item.isNotEmpty).toList();
    super.initState();
  }

  @override
  void dispose() {
    taskNotifications.clear();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      // constraints: ,
      // height: MediaQuery.of(context).size.height > 700 ? 700 : MediaQuery.of(context).size.height * 0.9,
      constraints: const BoxConstraints(
        maxHeight: 700.0,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // Top bar fixed height
          SizedBox(
            height: 68.0,
            child: _buildTopBar(context),
          ),

          // Scrollable content area
          Flexible(
            child: SingleChildScrollView(
              // padding:
              //     const EdgeInsets.fromLTRB(16.0, 16.0
              //         , 16.0, 0),
              child: _buildTaskDetails(),
            ),
          ),

          // Bottom bar fixed height
          SizedBox(
            height: 120.0,
            child: _buildBottomBar(context),
          ),
          // _buildBottomBar(context),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 15, 16.0, 2),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
          // bottomLeft: Radius.circular(0),
          // bottomRight: Radius.circular(0),
        ),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest, // Red color for the bottom border
            width: 1.5, // Thickness of the border
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Task Details',
                style: TextStyle(
                  fontSize: 18.0,
                  // fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 24.0),
                    onPressed: () {
                      // Open edit screen
                      Navigator.of(context).pop();
                      _showEditScreen(widget.task);
                      // Navigator.of(context).pop();
                    },
                  ),
                  IconButton(
                      icon: const Icon(Icons.delete_outline, size: 24.0),
                      onPressed: () async {
                        await controller.deleteTask(widget.task.id!);
                        log('008fetchTasks()');
                        controller.fetchTasks();
                        Navigator.of(context).pop();
                      }),
                  // IconButton(
                  //   icon: Icon(Icons.close_rounded, size: 26.0),
                  //   onPressed: () {
                  //     Navigator.pop(context); // Close bottom sheet
                  //   },
                  // ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      // color: Theme.of(context).colorScheme.errorContainer, // Dim background color (light gray in this example)
                      // color: Theme.of(context).colorScheme.surfaceContainerLow, // Dim background color (light gray in this example)
                      borderRadius:
                          BorderRadius.circular(30.0), // Rounded corners
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded,
                          size: 24, color: Color(0xFF0C1844)), // Icon color
                      onPressed: () {
                        Navigator.pop(context); // Close bottom sheet
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Divider(color: Colors.grey[200], thickness: 1.5),
        ],
      ),
    );
  }

  void _showEditScreen(TaskModel? task) async {
    // final result = await Get.to(() => AddEditTask(task: task));
    // if (result != null) {
    //   _refreshTasks();
    // }
    final result = await Get.to(() => AddEditTask(task: task));
    if (result != null) {
      _refreshTasks();
    }
  }

  Future<void> _refreshTasks() async {
    try {
      log('022fetchTasks()');
      await controller.fetchTasks();
    } catch (e) {
      log("ERROR TaskBottomSheetContent._refreshTasks: $e");
    }
  }

  Widget _buildTaskDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 18.0, 10.0, 10.0),
          child: Text(
            widget.task.title,
            style: const TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
            softWrap: true,
          ),
        ),
        if (widget.task.description?.isNotEmpty ?? false)
          Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 0.0, 10.0, 10.0),
            child: Column(
              children: [
                Text(
                  widget.task.description!,
                  style: TextStyle(fontSize: 16.0, color: Colors.grey[800]),
                ),
              ],
            ),
          ),
        const SizedBox(height: 10,),
        const Divider(height: 1, thickness: 0.5,),
        const SizedBox(height: 15,),
        _buildDateAndTime(),
        const SizedBox(height: 15,),
        const Divider(height: 1, thickness: 0.5,),
        const SizedBox(height: 15,),

        if (widget.task.priority != null && widget.task.priority!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 0.0, 10.0, 0.0),
            child: Row(
              children: [
                SizedBox(width: 45, child: Align( alignment: Alignment.centerLeft, child: Padding(
                  padding: const EdgeInsets.only(left: 3.8),
                  child: FaIcon(FontAwesomeIcons.flag, size: 20, color: Colors.grey[700]),
                  // child: FaIcon(widget.task.priority != 'No priority set' ? FontAwesomeIcons.flag : FontAwesomeIcons.flagCheckered, size: 20, color: Colors.grey[700]),
                ))),
                Text(
                  '${widget.task.priority}',
                  style: TextStyle(fontSize: 16.0, color: Colors.grey[800]),
                ),
              ],
            ),
          ),
        const SizedBox(height: 15,),
        const Divider(height: 1, thickness: 0.5,),
        const SizedBox(height: 15,),

        // Inside your widget
        if (widget.task.notification?.value != '' || true)
          Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 0.0, 10.0, 0.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (taskNotifications.isEmpty) // Checking if the list is empty
                  Row(
                    children: [
                      SizedBox(
                        width: 45,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Icon(Icons.notifications_off_rounded, color: Colors.grey[700]),
                        ),
                      ),
                      Text(
                        'No notifications set',
                        style: TextStyle(fontSize: 16.0, color: Colors.grey[800]),
                      ),
                    ],
                  )
                else

                // Iterate over the list and display each item
                ...List.generate(taskNotifications.length, (index) {
                  String notificationText = taskNotifications[index];

                  // Try to parse the notificationText as a DateTime
                  DateTime? notificationDateTime;
                  try {
                    notificationDateTime = DateFormat('dd-MM-yyyy HH:mm:ss').parse(notificationText);
                  } catch (e) {
                    notificationDateTime = null; // Not a valid DateTime
                  }

                  // Format the DateTime if valid, otherwise use the string as is
                  String displayText;
                  if (notificationDateTime != null) {
                    // Format the DateTime as "Fri, 13 Feb 2014 at 06:03 pm"
                    displayText = DateFormat('EEE, dd MMM yyyy \'at\' h:mm a').format(notificationDateTime).replaceAll('AM', 'am').replaceAll('PM', 'pm');
                  } else {
                    // Use the text as it is
                    displayText = notificationText;
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (index == 0) // Add icon only for the first row
                        SizedBox(
                          width: 45,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Icon(Icons.notifications, color: Colors.grey[700]),
                          ),
                        )
                      else
                        const SizedBox(width: 45), // Keep the space for other rows to align with the first one
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            displayText,
                            style: TextStyle(fontSize: 16.0, color: Colors.grey[800]),
                          ),
                        ),
                      ),
                    ],
                  );
                }),

              ],
            ),
          ),

        const SizedBox(height: 15,),
      ],
    );
  }

  Widget _buildDateAndTime() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // widget.task.startDate == widget.task.endDate && widget.task.startDate == widget.task.endDate ?
        //   Row(
        //     children: [
        //       SizedBox(width: 40, child: Align( alignment: Alignment.centerLeft, child: Icon(Icons.access_time_rounded, color: Colors.grey[700]))),
        //       const SizedBox(width: 8.0),
        //       Text(
        //         'All day',
        //         style: TextStyle(fontSize: 16.0, color: Colors.grey[800]),
        //       ),
        //     ],
        //   ) : Text('Text'),
        if (widget.task.startDate != null && widget.task.startTime != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 0.0, 10.0, 5.0),
            child: Row(
              children: [
                SizedBox(width: 45, child: Align( alignment: Alignment.centerLeft, child: Icon(Icons.access_time_rounded, color: Colors.grey[700]))),
                Text(
                  'Starts:  ${formatDateToText(widget.task.startDate!)} at ${formatTimeTo12Hour(widget.task.startTime!)}',
                  style: TextStyle(fontSize: 16.0, color: Colors.grey[800]),
                ),
              ],
            ),
          ),
        if (widget.task.endDate != null &&
            widget.task.endTime != null &&
            widget.task.endTime!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 0.0, 10.0, 5.0),
            child: Row(
              children: [
                const SizedBox(width: 45,),
                Text(
                  'Due:      ${formatDateToText(widget.task.endDate!)} at ${formatTimeTo12Hour(widget.task.endTime!)}',
                  style: TextStyle(fontSize: 16.0, color: Colors.grey[800]),
                ),
              ],
            ),
          ),
        const SizedBox(height: 5,),
        if (widget.task.repeat != null && widget.task.repeat!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 0.0, 10.0, 0.0),
            child: Row(
              children: [
                SizedBox(width: 45, child: Align( alignment: Alignment.centerLeft, child: Icon(Icons.replay_rounded, color: Colors.grey[700]))),
                Text(
                  '${widget.task.repeat}',
                  style: TextStyle(fontSize: 16.0, color: Colors.grey[800]),
                ),
              ],
            ),
          ),
        // const SizedBox(height: 10,),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      // height: 90,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
      ),
      child: Column(
        children: [
          Divider(height: 1, thickness: 1.2, color: Theme.of(context).colorScheme.surfaceContainerHighest,),
          const SizedBox(height: 0,),
          Container(
            height: 110,
            padding: const EdgeInsets.fromLTRB(18.0, 0, 18.0, 0.0),
            child: Column(
              // crossAxisAlignment: CrossAxisAlignment.center,
              // mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(1, 0, 0, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Status: Completed / Incomplete'
                      ),
                      Switch(
                        value: widget.task.taskStatus.value == 1 ? true : false,
                        onChanged: (bool value) {
                          setState(() {
                            widget.task.taskStatus.value = value ? 1 : 0;
                            handleTaskStatusToggle(widget.task, value);
                            controller.updateTaskStatus(widget.task); // Persist the change
                          });
                        },
                        inactiveTrackColor: Colors.white,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5,),
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: _getColorBasedOnTaskStatus(widget.task.taskStatus.value),
                    borderRadius: BorderRadius.circular(12.0), // Enhanced border radius
                    // border: Border.all(color: Colors.black, width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0),
                        child: Text(
                          widget.task.taskStatus.value == 1 ? 'Completed' : widget.task.taskStatus.value == 0 ? 'Overdue' : 'Pending',
                          style: TextStyle(
                            // color: _getColorBasedOnTaskStatus(widget.task.taskStatus.value),
                            color: widget.task.taskStatus.value == 2 ? Colors.white : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          // textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void handleTaskStatusToggle(TaskModel task, bool value) {
    if (value) {
      // If the switch is turned ON, set task status to 1 (active)
      task.taskStatus.value = 1;
    } else {
      // If the switch is turned OFF, determine task status based on the timing
      controller.updateTaskStatusPeriodically(task);
    }

    // Log the change
    log('handleTaskStatusToggle: Task ID: ${task.id}, Title: ${task.title}, Status: ${task.taskStatus.value}');
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


  String formatDateToTextVariant1(String date) {
    DateTime taskDate = DateFormat('dd-MM-yyyy').parse(date);
    return DateFormat('EEE, dd MMM yyyy').format(taskDate); // e.g., "Wed, 28 Aug 2024"
  }

}
