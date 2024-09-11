import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:todo/controllers/add_edit_task_controller.dart';

import '../model/task_model.dart';
import '../utils/my_utils.dart';
import '../widgets/date_picker_field.dart';
import '../widgets/description_field.dart';
import '../widgets/time_picker_field.dart';
import '../widgets/title_field.dart';

class AddEditTask extends StatefulWidget {
  final TaskModel? task;

  const AddEditTask({super.key, this.task});

  @override
  State<AddEditTask> createState() => _AddEditTaskState();
}

class _AddEditTaskState extends State<AddEditTask> {
  // final taskNotificationController = Get.put(TaskNotificationManager());
  late TaskModel? task;
  final controller = Get.put(AddEditTaskController());

  @override
  void initState() {
    super.initState();
    task = widget.task;
    controller.init(task);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Dismiss keyboard and lose focus when tapping outside
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          toolbarHeight: 60,
          // backgroundColor: const Color(0xFFC80036),
          backgroundColor: Colors.grey[800],
          foregroundColor: Colors.white,
          automaticallyImplyLeading: true,
          title: widget.task == null || widget.task!.title.isEmpty
              ? const Text("Add Task")
              : const Text("Edit Task"),
          titleTextStyle: const TextStyle(
            fontSize: 18,
          ),
          centerTitle: false,
          leadingWidth: 44,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: _saveIconButtonTemp(context, controller),
            ),
          ],
          leading: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: IconButton(
              onPressed: () {
                controller.clearData();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.close_rounded),
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(
                height: 20,
              ),
              Row(
                children: [
                  Container(
                    width: 60,
                  ),
                  Flexible(child: MyTitle(controller: controller)),
                ],
              ),
              const Divider(
                thickness: 0.5,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    width: 60,
                    child: Padding(
                      padding: EdgeInsets.only(top: 15.0),
                      child: Center(
                          child: FaIcon(FontAwesomeIcons.alignLeft, size: 18)),
                    ),
                  ),
                  Flexible(child: MyDescription(controller: controller)),
                ],
              ),
              const Divider(
                thickness: 0.5,
              ),
              allDayToggleWithIcon(controller: controller),
              const SizedBox(
                height: 10,
              ),
              Container(
                color: controller.isEndDateBeforeStartDate
                    ? const Color.fromARGB(30, 255, 0, 0)
                    : null,
                // Conditional background color
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 60,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 15.0),
                        child: controller.isEndDateBeforeStartDate
                            ? const Center(
                                child: FaIcon(
                                    FontAwesomeIcons.circleExclamation,
                                    size: 18,
                                    color: Color.fromARGB(180, 255, 100, 100)))
                            : const SizedBox.shrink(),
                      ),
                    ),
                    Flexible(
                        child: selectStartDateTime(
                            controller: controller,
                            dateLabel: 'Start Date',
                            timeLabel: 'Start Time')),
                  ],
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    width: 60,
                  ),
                  Flexible(
                      child: selectEndDateTime(
                          controller: controller,
                          dateLabel: 'End Date',
                          timeLabel: 'End Time')),
                ],
              ),
              const SizedBox(
                height: 15,
              ),
              InkWell(
                onTap: () {
                  showRepeatOptions(context, controller);
                  log('Repeat option pressed!');
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 60,
                        child:
                            Center(child: Icon(Icons.replay_rounded, size: 24)),
                      ),
                      Flexible(
                        child: Obx(() {
                          return Text(
                            controller.repeat.value,
                            style: TextStyle(
                              color: Colors.grey[900],
                              fontSize: 17.0,
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(
                thickness: 0.5,
              ),
              InkWell(
                onTap: () {
                  showPriorityOptions(context, controller);
                  log('Priority option pressed!');
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 60,
                        child: Center(
                            child: FaIcon(FontAwesomeIcons.flag, size: 20)),
                      ),
                      Flexible(
                        child: Obx(() {
                          return Text(
                            controller.priority.value,
                            style: TextStyle(
                              color: Colors.grey[900],
                              fontSize: 17.0,
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(
                thickness: 0.5,
              ),
              Obx(() {
                return Column(
                  children: [
                    // Dynamically generate rows for selected notifications
                    ...controller.taskNotifications.map((notification) {
                      // Check if the notification is a valid DateTime string
                      DateTime? parsedDate;
                      try {
                        parsedDate = DateFormat('dd-MM-yyyy HH:mm:ss')
                            .parse(notification);

                        // final format = DateFormat('yyyy-MM-dd HH:mm:ss');
                        // parsedDate = format.parse(notification);
                        log('Notification: parsedDate $parsedDate');
                      } catch (e) {
                        parsedDate = null;
                      }

                      // Format the date-time string or use the original text
                      String displayText;
                      if (parsedDate != null) {
                        // Format the parsedDate to "Wed, 27 Aug 2024 at 12:00 am"
                        // displayText = DateFormat('EEE, dd MMM yyyy').format(parsedDate) +
                        //     ' at ' +
                        //     DateFormat('hh:mm a').format(parsedDate).replaceAll('AM', 'am').replaceAll('PM', 'pm');
                        displayText =
                            DateFormat('EEE, dd MMM yyyy \'at\' h:mm a')
                                .format(parsedDate)
                                .replaceAll('AM', 'am')
                                .replaceAll('PM', 'pm');
                      } else {
                        displayText = notification;
                      }

                      return Row(
                        children: [
                          const SizedBox(
                            width: 60,
                          ),
                          Flexible(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  displayText,
                                  // Updated to display formatted date-time with "at" and lowercase am/pm
                                  style: const TextStyle(
                                    fontSize: 17,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(right: 16.0),
                                  child: IconButton(
                                    onPressed: () {
                                      controller.removeNotification(
                                          notification); // Remove notification
                                      if (controller
                                          .taskNotifications.isEmpty) {
                                        // controller.notification.value = 0;
                                        controller.notification.value = '';
                                      }
                                      log('Removed Notification: $notification');
                                    },
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),

                    InkWell(
                      onTap: () {
                        showNotificationOptions(context, controller);
                        log('Notification option pressed!');
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10.0),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 60,
                              child: Center(
                                  child:
                                      FaIcon(FontAwesomeIcons.bell, size: 20)),
                            ),
                            Flexible(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Add notification',
                                    style: TextStyle(
                                      fontSize: 17,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }),
              const SizedBox(
                height: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------------------------------------------------------------------

  Widget _saveIconButtonTemp(
      BuildContext context, AddEditTaskController controller) {
    return ElevatedButton(
      onPressed: () => save(controller),
      child: Text(
        'Save',
        style: TextStyle(color: Colors.grey[800]),
      ),
    );
  }

  Future<void> save(AddEditTaskController controller) async {
    final title = controller.title.value;

    if (MyUtils.isTitleEmpty(title)) {
      MyUtils.showToast('Title cannot be empty!');
      return;
    }

    if (MyUtils.isTitleInvalid(title)) {
      MyUtils.showToast('Title must start with a letter!');
      return;
    }

    final result = await controller.save();
    Get.back(result: result);
  }

  Widget allDayToggleWithIcon({required AddEditTaskController controller}) {
    return InkWell(
      onTap: () {
        setState(() {
          // Toggle the value of isAllDay and update the controller
          controller.isAllDay = !controller.isAllDay;
          _setAllDay(controller.isAllDay);
        });
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: 60,
            child: Padding(
              padding: EdgeInsets.only(top: 14.0),
              child: Center(
                // Use either Icon or FaIcon as per your preference
                child: FaIcon(FontAwesomeIcons.clock, size: 20),
              ),
            ),
          ),
          Flexible(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'All-day',
                  style: TextStyle(
                    fontSize: 17,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Switch(
                    // value: _setInitialSwitchState(), // Set initial state
                    value: controller.isAllDay, // Set initial state
                    onChanged: (bool value) {
                      setState(() {
                        controller.isAllDay = value;
                        _setAllDay(value);
                      });
                    },
                    inactiveTrackColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _setAllDay(bool value) {
    log('isAllDay = ${controller.isAllDay}');

    try {
      if (controller.isAllDay) {
        // If setting to all-day, calculate start and end times of the day
        DateTime now = DateTime.now();
        DateTime startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
        DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

        // Store previous values before setting
        controller.previousStartTime = controller.startTime.value;
        controller.previousEndTime = controller.endTime.value;

        // Set startTime and endTime as strings in the desired format
        controller.startTime.value = controller.formatTime(startOfDay);
        controller.endTime.value = controller.formatTime(endOfDay);
        // controller.startTime.value = startOfDay.toIso8601String();
        // controller.endTime.value = endOfDay.toIso8601String();
      } else {
        // If reverting from all-day, restore previous startTime and endTime
        controller.startTime.value = controller.previousStartTime;
        controller.endTime.value = controller.previousEndTime;
      }

      log('_setAllDay: endTime: ${widget.task?.endTime}, startTime: ${widget.task?.startTime}');
    } catch (e) {
      log('_setAllDay: $e');
    }
  }

  Widget selectStartDateTime(
      {required AddEditTaskController controller, dateLabel, timeLabel}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          DatePickerField(
            label: dateLabel,
            dateObservable: controller.startDate,
            controller: controller,
            onDateSelected: (date) {
              controller.setStartDate(date);
            },
          ),
          // const SizedBox(width: 15),
          !controller.isAllDay
              ? Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: TimePickerField(
                    label: timeLabel,
                    timeObservable: controller.startTime,
                    controller: controller,
                    onTimeSelected: (time) {
                      controller.setStartTime(time);
                    },
                  ),
                )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget selectEndDateTime(
      {required AddEditTaskController controller, dateLabel, timeLabel}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        DatePickerField(
          label: dateLabel,
          dateObservable: controller.endDate,
          controller: controller,
          onDateSelected: (date) {
            controller.setEndDate(date);
          },
          firstDate: controller.startDate.value.isNotEmpty
              ? parseDate(controller.startDate.value)
              : DateTime(2000),
        ),
        // const SizedBox(width: 15),
        !controller.isAllDay
            ? Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: TimePickerField(
                  label: timeLabel,
                  timeObservable: controller.endTime,
                  controller: controller,
                  onTimeSelected: (time) {
                    controller.setEndTime(time);
                  },
                ),
              )
            : const SizedBox.shrink(),
      ],
    );
  }

  Widget repeat({required AddEditTaskController controller}) {
    // String value = 'Does not repeat';
    return Text(
      controller.repeat.value,
      style: TextStyle(
        color: Colors.grey[900],
        fontSize: 17.0,
      ),
    );
  }

  Widget priority({required AddEditTaskController controller}) {
    String value = 'Add priority';
    return Text(
      value,
      style: TextStyle(
        color: Colors.grey[900],
        fontSize: 17.0,
      ),
    );
  }

  // ------------------------------------------------------------------------------------------------------------------------------------

  DateTime parseDate(String dateStr) {
    try {
      return DateTime.parse(
          '${dateStr.split('-').reversed.join('-')} 00:00:00');
    } catch (e) {
      log("ERROR EditTaskScreen.parseDate: $e");
      return DateTime.now();
    }
  }

  void showRepeatOptions(
      BuildContext context, AddEditTaskController controller) {
    // Define repeat options
    List<String> repeatOptions = [
      'Does not repeat',
      'Every day',
      'Every week',
      'Every month',
      'Every year',
    ];

    // Set initial selected value to task's repeat value or default to 'Does not repeat'
    String selectedValue = controller.repeat.value.isNotEmpty
        ? controller.repeat.value
        : 'Does not repeat';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0), // Add some border radius
          ),
          child: Container(
            width: 120,
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 10.0,
            ),
            // Add padding around the content
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: repeatOptions.map((option) {
                return RadioListTile<String>(
                  title: Text(
                    option,
                    style: const TextStyle(
                      fontSize: 17.0,
                    ),
                  ),
                  value: option,
                  groupValue: selectedValue,
                  onChanged: (String? value) {
                    if (value != null) {
                      // Update the selected value
                      selectedValue = value;

                      // Update the task's repeat value and the text display
                      controller.repeat.value = value;
                      controller.updateRepeatOption(
                          value); // Notify listeners if necessary

                      // Close the dialog
                      Navigator.of(context).pop();
                    }
                  },
                  dense: true,
                  // Reduce the height of the ListTile
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 0, horizontal: 0), // Reduce vertical padding
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  void showPriorityOptions(
      BuildContext context, AddEditTaskController controller) {
    List<String> priorityOptions = ['No priority set', 'High', 'Medium', 'Low'];

    // Set initial selected value to task's repeat value or default to 'Does not repeat'
    String? selectedValue =
        controller.priority.value.isNotEmpty ? controller.priority.value : null;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0), // Add some border radius
          ),
          child: Container(
            width: 120,
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 10.0,
            ),
            // Add padding around the content
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: priorityOptions.map((option) {
                return RadioListTile<String>(
                  title: Text(
                    option,
                    style: const TextStyle(
                      fontSize: 17.0,
                    ),
                  ),
                  value: option,
                  groupValue: selectedValue,
                  onChanged: (String? value) {
                    if (value != null) {
                      // Update the selected value
                      selectedValue = value;

                      // Update the task's repeat value and the text display
                      controller.priority.value = value;
                      controller.updatePriorityOption(
                          value); // Notify listeners if necessary

                      // Close the dialog
                      Navigator.of(context).pop();
                    }
                  },
                  dense: true,
                  // Reduce the height of the ListTile
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 0, horizontal: 0), // Reduce vertical padding
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  void showNotificationOptions(
      BuildContext context, AddEditTaskController controller) {
    List<String> allOptions = [
      'On start time',
      '5 minutes before',
      '10 minutes before',
      '15 minutes before',
      '1 hour before',
      '1 day before',
      'On the day at 6 am',
      'On the day at 9 am',
      'The day before at 6 am',
      'The day before at 9 am',
      'Custom...',
    ];

    List<String> availableOptions = allOptions
        .where((option) => !controller.taskNotifications.contains(option))
        .toList();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
          child: Container(
            // width: 400,
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Obx(() {
                    return Column(
                      children: availableOptions.map((option) {
                        return RadioListTile<String>(
                          title: Text(
                            option,
                            style: const TextStyle(fontSize: 17.0),
                          ),
                          value: option,
                          groupValue: controller.selectedNotification.value,
                          // Access the value
                          onChanged: (String? value) {
                            if (value != null) {
                              if (value == 'Custom...') {
                                Navigator.of(context)
                                    .pop(); // Close current dialog
                                showCustomNotificationDialog(
                                    context, controller); // Open custom dialog
                              } else {
                                controller.selectedNotification.value =
                                    value; // Update value
                                if (controller.taskNotifications.isEmpty) {
                                  controller.notification.value = '';
                                  // controller.notification.value = 1;
                                }
                                controller.addNotification(value);
                                // controller.selectedNotification(value); // Add selected option to the list
                                Navigator.of(context).pop();
                              }
                            }
                          },
                          dense: true,
                          // Reduce the height of the ListTile
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 0,
                              horizontal: 0), // Reduce vertical padding
                        );
                      }).toList(),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void showCustomNotificationDialog(
      BuildContext context, AddEditTaskController controller) {
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Custom notification',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16.0), // Smaller font size for the title
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                          );
                          if (pickedDate != null &&
                              pickedDate != selectedDate) {
                            setState(() {
                              selectedDate = pickedDate;
                            });
                          }
                        },
                        child: Text(
                          // DateFormat('dd MMM yyyy').format(selectedDate),
                          controller.formatDateToTextVariant1(
                              controller.formatDate(selectedDate)),
                          style: TextStyle(
                              fontSize: 17.0,
                              color: Colors.grey[800],
                              fontWeight:
                                  FontWeight.normal), // Font size for date
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                          );
                          if (pickedTime != null &&
                              pickedTime != selectedTime) {
                            setState(() {
                              selectedTime = pickedTime;
                            });
                          }
                        },
                        child: Text(
                          selectedTime.format(context),
                          style: TextStyle(
                              fontSize: 17.0,
                              color: Colors.grey[800],
                              fontWeight:
                                  FontWeight.normal), // Font size for time
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Format the date and time as "dd-MM-yyyy HH:mm:ss"
                final DateFormat formatter = DateFormat('dd-MM-yyyy HH:mm:ss');
                final notificationTime = formatter.format(DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                ));

                if (controller.taskNotifications.isEmpty) {
                  controller.notification.value = '';
                  // controller.notification.value = 1;
                }
                controller.addNotification(
                    notificationTime); // Add custom notification
                // controller.selectedNotifications.add(notificationTime);
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }
}
