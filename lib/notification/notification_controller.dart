import 'dart:developer';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../model/task_model.dart';
import 'local_notifications.dart';
import '../controllers/home_screen_controller.dart';

class NotificationController extends GetxController {
  final HomeScreenController homeScreenController =
      Get.put(HomeScreenController());

  final Map<int, List<DateTime>> _taskNotifications = {};

  // Schedule notifications for a task
  Future<void> scheduleNotificationsForTask(TaskModel task) async {
    log('START scheduleNotificationsForTask: ${task.id}, ${task.title}');

    try {
      if (task.id == null) {
        log("NOT SCHEDULED scheduleNotificationsForTask: ${task.id}, ${task.title} - ID is null.");
        return;
      }

      final List<DateTime> notificationTimes = _getNotificationTimes(task);

      if (notificationTimes.isEmpty) {
        log("NOT SCHEDULED scheduleNotificationsForTask: ${task.id}, ${task.title} - notificationTimes list is empty or No valid notification times");
        return;
      }
      log('LIST 1: scheduleNotificationsForTask: ${task.id}, ${task.title}, notificationTimes list: $notificationTimes');

      // Store notifications in the map
      _taskNotifications[task.id!] = notificationTimes;

      // final notificationController = Get.put(NotificationController());
      // notificationController.clearScheduledNotificationsForTask(task.id!);

      for (var notificationTime in notificationTimes) {
        // Check if the notification time is in the past
        if (notificationTime.isBefore(DateTime.now())) {
          log("In loop: Skipping past notification time for ${task.id}, ${task.title}, $notificationTime");
          continue; // Skip this iteration and move to the next notification time
        }

        log("In loop: Scheduling for ${task.id}, ${task.title}, $notificationTime");
        try {
          await LocalNotifications.scheduledNotification(
            id: _generateUniqueNotificationId(task.id!, notificationTime),
            task: task,
            scheduledDateTime: notificationTime,
            payload: _generatePayload(task.id!, notificationTime),
          );
          log("In loop: SUCCESS Scheduling for ${task.id}, ${task.title}, $notificationTime");
        } on Exception catch (e) {
          log("In loop: FAILED Scheduling for ${task.id}, ${task.title}, $notificationTime");
          log("ERROR: $e");
        }
      }

      log('SCHEDULED ${task.id}, ${task.title}');
      log('FINISHED scheduleNotificationsForTask: ${task.id}, ${task.title}');
    } catch (e) {
      log("FAILED scheduleNotificationsForTask: ${task.id}, ${task.title}");
      log("NOT SCHEDULED - $e");
      return;
    }
  }

  // Reschedule notifications for an updated task
  Future<void> rescheduleNotificationsForTask(TaskModel updatedTask) async {
    try {
      log("rescheduleNotificationsForTask: ${updatedTask.id}, ${updatedTask.title}");
      await clearScheduledNotificationsForTask(updatedTask.id!);
      await scheduleNotificationsForTask(updatedTask);
    } catch (e) {
      log("ERROR rescheduleNotificationsForTask: ${updatedTask.id}, ${updatedTask.title}, $e");
    }
  }

  List<DateTime> _getNotificationTimes(TaskModel task) {
    final List<DateTime> notificationTimes = [];
    final DateTime taskStartDateTime =
        homeScreenController.parseDateTime(task.startDate, task.startTime)!;
    // log('_getNotificationTimes: taskStartDateTime: $taskStartDateTime');

    if (task.notification != null && task.notification!.isNotEmpty) {
      final List<String> notificationStrings = task.notification!.split(', ');

      for (var notification in notificationStrings) {
        // log('_getNotificationTimes: ${task.id}, ${task.title}, $notification');

        DateTime? notificationTime;

        switch (notification) {
          case 'On start time':
            notificationTime = taskStartDateTime;
            log("_getNotificationTimes: 'On start time' ${task.id}, ${task.title}, notificationTime: $notificationTime");
            break;
          case '5 minutes before':
            notificationTime = taskStartDateTime.subtract(const Duration(minutes: 5));
            log("_getNotificationTimes: '5 minutes before' ${task.id}, ${task.title}, notificationTime: $notificationTime");
            break;
          case '10 minutes before':
            notificationTime =
                taskStartDateTime.subtract(const Duration(minutes: 10));
            log("_getNotificationTimes: '10 minutes before' ${task.id}, ${task.title}, notificationTime: $notificationTime");

            break;
          case '15 minutes before':
            notificationTime =
                taskStartDateTime.subtract(const Duration(minutes: 15));
            log("_getNotificationTimes: '15 minutes before' ${task.id}, ${task.title}, notificationTime: $notificationTime");

            break;
          case '1 hour before':
            notificationTime = taskStartDateTime.subtract(const Duration(hours: 1));
            log("_getNotificationTimes: '1 hour before' ${task.id}, ${task.title}, notificationTime: $notificationTime");

            break;
          case '1 day before':
            notificationTime = taskStartDateTime.subtract(const Duration(days: 1));
            log("_getNotificationTimes: '1 day before' ${task.id}, ${task.title}, notificationTime: $notificationTime");

            break;
          case 'On the day at 6 am':
            notificationTime = DateTime(taskStartDateTime.year,
                taskStartDateTime.month, taskStartDateTime.day, 6, 0, 0);
            log("_getNotificationTimes: 'On the day at 6 am' ${task.id}, ${task.title}, notificationTime: $notificationTime");

            break;
          case 'On the day at 9 am':
            notificationTime = DateTime(taskStartDateTime.year,
                taskStartDateTime.month, taskStartDateTime.day, 9, 0, 0);
            log("_getNotificationTimes: 'On the day at 9 am' ${task.id}, ${task.title}, notificationTime: $notificationTime");

            break;
          case 'The day before at 6 am':
            notificationTime = DateTime(taskStartDateTime.year,
                    taskStartDateTime.month, taskStartDateTime.day, 6, 0, 0)
                .subtract(const Duration(days: 1));
            log("_getNotificationTimes: 'The day before at 6 am' ${task.id}, ${task.title}, notificationTime: $notificationTime");

            break;
          case 'The day before at 9 am':
            notificationTime = DateTime(taskStartDateTime.year,
                    taskStartDateTime.month, taskStartDateTime.day, 9, 0, 0)
                .subtract(const Duration(days: 1));
            log("_getNotificationTimes: 'The day before at 9 am' ${task.id}, ${task.title}, notificationTime: $notificationTime");

            break;
          default:
            // Handle custom date-time strings like '31-08-2024 23:19:00'
            try {
              notificationTime =
                  DateFormat('dd-MM-yyyy HH:mm:ss').parse(notification);
              log("_getNotificationTimes: 'Custom' ${task.id}, ${task.title}, notificationTime: $notificationTime");
            } catch (e) {
              log('Invalid notification time format: $notification');
            }
            break;
        }

        if (notificationTime != null) {
          notificationTimes.add(notificationTime);
        }
      }
    }

    log('_getNotificationTimes: notificationTimes:  ${notificationTimes.toString()}');
    return notificationTimes;
  }

  // Clear scheduled notifications for a task
  Future<void> clearScheduledNotificationsForTask(int taskId) async {
    try {
      log("Clearing notifications for task $taskId...");
      if (_taskNotifications.containsKey(taskId)) {
        for (var notificationTime in _taskNotifications[taskId]!) {
          final notificationId =
              _generateUniqueNotificationId(taskId, notificationTime);
          await LocalNotifications.cancel(notificationId);
        }
        _taskNotifications.remove(taskId);
        log('clearScheduledNotificationsForTask: the _taskNotifications: ${_taskNotifications.toString()}');
        return;
      }
      log("_taskNotifications has no notifications for task $taskId...");
    } catch (e) {
      log("FAILED to clear notifications of task $taskId $e");
      log("ERROR: $e");
    }
  }

  // Clear all the scheduled notifications for all tasks
  Future<void> clearAllNotifications() async {
    try {
      log("Clearing notifications for all tasks");
      await LocalNotifications.cancelAll();

      // Clear all task notifications in the map
      _taskNotifications.clear();
    } catch (e) {
      log("ERROR NotificationController.clearAllNotifications: $e");
    }
  }

  // Generate a unique notification ID based on the task ID and notification time
  int _generateUniqueNotificationId(int taskId, DateTime notificationTime) {
    return taskId + notificationTime.hashCode;
  }

  // Generate a payload string with necessary information for the task
  String _generatePayload(int taskId, DateTime notificationTime) {
    return 'task_id:$taskId, notification_time:${notificationTime.toIso8601String()}';
  }

  Future<void> logPendingNotifications() async {
    List<PendingNotificationRequest> pendingList =
        await LocalNotifications.pendingNotifications();
    for (PendingNotificationRequest task in pendingList) {
      log('logPendingNotifications: ${task.id}, ${task.title}');
    }
  }

  Future<void> logActiveNotifications() async {
    List<ActiveNotification> activeList =
        await LocalNotifications.activeNotifications();
    for (ActiveNotification task in activeList) {
      log('logActiveNotifications: ${task.id}, ${task.title}');
    }
  }

  Future<bool> areNotificationsPending() async {
    List<PendingNotificationRequest> pendingNotifications =
        await LocalNotifications.pendingNotifications();
    return pendingNotifications.isNotEmpty;
  }
}
