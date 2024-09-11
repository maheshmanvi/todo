import 'dart:developer';

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../model/task_model.dart';
import '../services/database_helper.dart';
import '../utils/my_utils.dart';
import '../notification/notification_controller.dart';

class AddEditTaskController extends GetxController {
  var title = ''.obs;
  var description = ''.obs;
  var startDate = ''.obs;
  var startTime = ''.obs;
  var endDate = ''.obs;
  var endTime = ''.obs;
  var priority = ''.obs;
  var repeat = ''.obs;
  var id = Rxn<int>();
  var createdOn = Rxn<DateTime>();
  var taskStatus = 0.obs; // Initialize as RxInt
  var notification = ''.obs; // Initialize as RxInt
  var reminderDate = ''.obs;
  var reminderTime = ''.obs;

  NotificationController notificationController =
      Get.put(NotificationController());
  bool isAllDay = false;
  bool isEndDateBeforeStartDate = false;

  String previousStartTime = '';
  String previousEndTime = '';

  // Observable for the selected notification (single selection)
  var selectedNotification = Rx<String?>(null);

  // Observable list for the selected notifications (multiple selections)
  var taskNotifications = <String>[].obs;

  void init(TaskModel? task) {
    clearData();
    final now = DateTime.now();
    final initStartDate = formatDate(now);
    final initStartTime = formatTime(now);
    final initEndDate = formatDate(now);
    final initEndTime = formatTime(now.add(const Duration(hours: 1)));

    if (task != null) {
      // Initialize with task details
      title.value = task.title;
      description.value = task.description ?? '';
      startDate.value = task.startDate ?? initStartDate;
      startTime.value = task.startTime ?? initStartTime;
      endDate.value = task.endDate ?? initEndDate;
      endTime.value = task.endTime ?? initEndTime;
      priority.value = task.priority ?? '';
      repeat.value = task.repeat ?? '';
      id.value = task.id;
      createdOn.value = task.createdOn;
      taskStatus.value = task.taskStatus.value;
      notification.value = task.notification!.value ?? '';
      reminderDate.value = task.reminderDate ?? '';
      reminderTime.value = task.reminderTime ?? '';

      // Convert the notification string to a list and assign it to taskNotifications
      taskNotifications.value = task.notification!.value
          .split(', ')
          .where((item) => item.isNotEmpty)
          .toList();

      initIsAllDay();
    } else {
      // Default values for new task
      title.value = '';
      description.value = '';
      startDate.value = initStartDate;
      startTime.value = initStartTime;
      endDate.value = initEndDate;
      endTime.value = initEndTime;
      priority.value = 'No priority set';
      repeat.value = 'Does not repeat';
      notification.value = '';
      reminderDate.value = '';
      reminderTime.value = '';
      taskNotifications.clear(); // Clear the list for a new task
    }
  }

  void initStartDateTime() {
    final now = DateTime.now();
    final initStartDate = formatDate(now);
    final initStartTime = formatTime(now);
    final initEndDate = formatDate(now);
    final initEndTime = formatTime(now.add(const Duration(hours: 1)));

    if (id.value == null) {
      // Only set default values if no task is being edited
      startDate.value = initStartDate;
      startTime.value = initStartTime;
      endDate.value = initEndDate;
      endTime.value = initEndTime;
    }
  }

  void initRepeatOption() {
    repeat.value = 'Does not repeat';
  }

  void initPriorityOption() {
    priority.value = 'No priority set';
  }

  void initNotificationStatus() {
    notification.value = '';
  }

  Future<TaskModel> save() async {
    final db = DatabaseHelper.instance;

    // Convert taskNotifications list to a single string with commas as separator
    final notificationString = taskNotifications.join(', ');

    TaskModel task = TaskModel(
      id: id.value,
      title: title.value,
      description: description.value,
      startDate: startDate.value,
      startTime: startTime.value,
      endDate: endDate.value,
      endTime: endTime.value,
      priority: priority.value,
      repeat: repeat.value,
      createdOn: createdOn.value,
      taskStatus: taskStatus.value.obs,
      notification: notificationString.obs,
      // Assign the string to notification
      reminderDate: reminderDate.value,
      reminderTime: reminderTime.value,
    );

    int finalId = 0;
    if (id.value == null) {
      // Adding a new task
      final result = await db.insert(task.toMap());
      finalId = result;
      if (result > 0) {
        MyUtils.showToast('Task created');
        // Update the task object with the new id
        task = task.copyWith(id: finalId);
        await notificationController.scheduleNotificationsForTask(task);
      } else {
        MyUtils.showToast('Task not created');
      }
    } else {
      // Editing an existing task
      final result = await db.update(task.toMap());
      if (result == 1) {
        MyUtils.showToast('Updated');
        finalId = task.id!;
        if (notificationString.isEmpty && notificationString == '') {
          // Handle clearing notifications if needed
          await notificationController
              .clearScheduledNotificationsForTask(finalId);
        } else {
          await notificationController.rescheduleNotificationsForTask(task);
        }
      } else {
        MyUtils.showToast('Not updated');
      }
    }

    // Fetch the updated task from the database to ensure it has the correct id
    TaskModel upsertedModel = await db.getTaskById(finalId);
    // Clear data after saving
    return upsertedModel;
  }

  void clearInitializedDate() {
    clearData();
  }

  void initIsAllDay() {
    if (startDate.value.isNotEmpty) {
      isAllDay = startTime.value == '00:00:00' && endTime.value == '23:59:59';
      // isAllDay = startTime.value == '00:00:00' && endTime.value == '23:59:59' && startDate.value == endDate.value;
      log('initIsAllDay(): isAllDay = $isAllDay');
    } else {
      isAllDay = false;
      log('initIsAllDay(): isAllDay = $isAllDay');
    }
  }

  void setStartDate(DateTime date) {
    if (startTime.value.isEmpty) {
      startTime.value = formatTime(date);
    }
    log("setStartDate: startDate = $date");
    startDate.value = formatDate(date);
  }

  void setStartTime(DateTime time) {
    if (startDate.value.isEmpty) {
      startDate.value = formatDate(DateTime.now());
    }
    log("setStartTime: startTime = $time");
    startTime.value = formatTime(time);
  }

  void setEndDate(DateTime date) {
    DateTime startDateTime =
        parseDateTime('${startDate.value} ${startTime.value}');
    DateTime endDateTime;

    if (endTime.value.isEmpty) {
      endDateTime = parseDateTime('${formatDate(date)} ${startTime.value}');
      endTime.value = formatTime(
          startDateTime); // Adjusted to the current end time, not the start time
    } else {
      endDate.value = formatDate(date);
      endDateTime = parseDateTime('${endDate.value} ${endTime.value}');
    }

    log("setEndDate: startDateTime = $startDateTime");
    log("setEndDate: endDateTime = $endDateTime");

    if (endDateTime.isBefore(startDateTime)) {
      MyUtils.showToast('End date cannot be before start date!');
      // Clear the endDate and endTime values if endDateTime is before startDateTime
      endDate.value = '';
      endTime.value = '';
      return;
    }

    endDate.value = formatDate(date);
  }

  void setEndTime(DateTime time) {
    if (endDate.value.isEmpty) {
      endDate.value = startDate.value;
    }
    try {
      DateTime startDateTime =
          parseDateTime('${startDate.value} ${startTime.value}');
      DateTime endDateTime =
          parseDateTime('${endDate.value} ${formatTime(time)}');

      log("startDateTime: $startDateTime");
      log("endDateTime: $endDateTime");

      if (startDate.value == endDate.value) {
        if (startTime.value.isNotEmpty) {
          final startTimeParts = startTime.value.split(':');
          final startDateTimeOnly = DateTime(
            startDateTime.year,
            startDateTime.month,
            startDateTime.day,
            int.parse(startTimeParts[0]),
            int.parse(startTimeParts[1]),
          );

          if (endDateTime.isBefore(startDateTimeOnly)) {
            MyUtils.showToast('Cannot end the task before start');
            return;
          }
        }
      }
      endTime.value = formatTime(time);
    } catch (e) {
      log("ERROR AddEditTaskController.setEndTime: ${e.toString()}");
    }
  }

  void setReminderDate(DateTime date) {
    if (reminderTime.value.isEmpty) {
      reminderTime.value = formatTime(date);
    }
    log("setReminderDate: reminderDate = $date");
    reminderDate.value = formatDate(date);
  }

  void setReminderTime(DateTime time) {
    if (reminderDate.value.isEmpty) {
      reminderDate.value = formatDate(DateTime.now());
    }
    log("setReminderTime: reminderTime = $time");
    reminderTime.value = formatTime(time);
  }

  String formatDate(DateTime dateTime) {
    return DateFormat('dd-MM-yyyy').format(dateTime);
  }

  String formatDateToTextVariant1(String date) {
    DateTime taskDate = DateFormat('dd-MM-yyyy').parse(date);
    return DateFormat('EEE, dd MMM yyyy')
        .format(taskDate); // e.g., "Wed, 28 Aug 2024"
  }

  String formatTime(DateTime dateTime) {
    return DateFormat('HH:mm:ss').format(dateTime);
  }

  DateTime parseDateTime(String dateTimeStr) {
    try {
      final format = DateFormat('dd-MM-yyyy HH:mm:ss');
      return format.parse(dateTimeStr);
    } catch (e) {
      log("ERROR AddEditTaskController.parseDateTime: $e");
      return DateTime.now();
    }
  }

  // Method to get the formatted time text
  String formatTimeTo12Hour(String time) {
    DateTime dateTime = DateFormat('HH:mm:ss').parse(time);
    return DateFormat('h:mm a').format(dateTime);
  }

  // Method to get the formatted date text
  String formatDateToText(String date) {
    DateTime taskDate = DateFormat('dd-MM-yyyy').parse(date);
    return DateFormat('EEE, dd MMM yyyy')
        .format(taskDate); // e.g., "Wed, 28 Aug 2024"
  }

  DateTime? parseDateTimeFromDateAndTimeString(String? date, String? time) {
    if (date == null || date.isEmpty) return null;

    final dateString = date;
    final timeString = time ?? '00:00:00';
    try {
      return DateFormat('dd-MM-yyyy HH:mm:ss').parse('$dateString $timeString');
    } catch (e) {
      log('ERROR AddEditController.parseDateTimeFromDateAndTimeString: $e');
      return null;
    }
  }

  void updateRepeatOption(String value) {
    repeat.value = value;
  }

  void updatePriorityOption(String value) {
    priority.value = value;
  }

  // Method to add a notification to the list
  void addNotification(String notification) {
    if (!taskNotifications.contains(notification)) {
      taskNotifications.add(notification);
    }
    log('addNotification: taskNotifications: ${taskNotifications.join(', ').toString()}');
  }

  // Method to remove a notification from the list
  void removeNotification(String notification) {
    taskNotifications.remove(notification);
    log('removeNotification: taskNotifications: ${taskNotifications.join(', ').toString()}');
  }

  // Method to clear all data
  void clearData() {
    title.value = '';
    description.value = '';
    startDate.value = '';
    startTime.value = '';
    endDate.value = '';
    endTime.value = '';
    priority.value = '';
    repeat.value = '';
    id.value = null;
    createdOn.value = null;
    taskStatus.value = 0;
    notification.value = '';
    reminderDate.value = '';
    reminderTime.value = '';

    isAllDay = false;
    isEndDateBeforeStartDate = false;

    previousStartTime = '';
    previousEndTime = '';

    selectedNotification.value = null;
    taskNotifications.clear();
  }
}
