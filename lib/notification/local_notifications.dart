import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../model/task_model.dart';
import '../controllers/home_screen_controller.dart';
import '../services/database_helper.dart';
import '../utils/logger.dart';

class LocalNotifications extends GetxController {
  static final FlutterLocalNotificationsPlugin
  _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Background notification handler
  @pragma('vm:entry-point')
  static Future<void> _backgroundNotificationHandler(
    NotificationResponse notificationResponse) async {

    final String? payload = notificationResponse.payload;
    final String? actionId = notificationResponse.actionId;

    logger.i('_backgroundNotificationHandler: NotificationResponse: ${notificationResponse.toString()}');
    log('_backgroundNotificationHandler: payload: $payload, actionId: $actionId');

    if (payload != null) {
      await _onSelectNotification(payload: payload, actionId: actionId);
    }
  }

  static Future<void> _handleNotificationTap(NotificationResponse notificationResponse) async {
    final String? payload = notificationResponse.payload;
    final String? actionId = notificationResponse.actionId;

    logger.i('_handleNotificationTap: NotificationResponse: ${notificationResponse.toString()}');
    log('_handleNotificationTap: NotificationResponse: id: ${notificationResponse.id}, actionId: ${notificationResponse.actionId}, input: ${notificationResponse.input}, payload: ${notificationResponse.payload}');
    log('_handleNotificationTap: payload: $payload, actionId: $actionId');

    if (payload != null) {
      await _onSelectNotification(payload: payload, actionId: actionId);
    }
  }

  //------------------------------------------------------------------------------------------------

  // Initialize notification
  static Future<void> initializeNotification() async {
    log("Initializing notifications...");
    await _configureLocalTimeZone();

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) async {
        _handleNotificationTap(notificationResponse);
      },
      onDidReceiveBackgroundNotificationResponse:
      _backgroundNotificationHandler,
    );
    log("Notifications initialized.");
  }

  // Configure local timezone
  static Future<void> _configureLocalTimeZone() async {
    try {
      tz.initializeTimeZones();
      final String timeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZone));
      log("Timezone configured to: $timeZone");
    } catch (e) {
      log("ERROR in configuring timezone: $e");
    }
  }


  // Convert the time to a timezone-aware DateTime object
  static tz.TZDateTime _convertTime(DateTime scheduledDateTime) {
    log("_convertTime: scheduledDateTime converted to timezone-aware DateTime: $scheduledDateTime");

    try {
      _configureLocalTimeZone();
    } catch (e) {
      log("ERROR LocalNotifications._convertTime: _configureLocalTimeZone error: $e");
    }

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduleDate = tz.TZDateTime.from(scheduledDateTime, tz.local);

    if (scheduleDate.isBefore(now)) {
      // scheduleDate = scheduleDate.add(const Duration(days: 1));
    }
    log("_convertTime: Scheduled time converted to timezone-aware DateTime: $scheduleDate");
    return scheduleDate;
  }

  static const NotificationDetails notificationDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your_channel_description',
      importance: Importance.max,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(
        '',
        htmlFormatContent: true,
        htmlFormatTitle: true,
      ),
      actions: [
        AndroidNotificationAction('mark_done', 'Mark as Done',
            showsUserInterface: true, titleColor: Color(0xFF800000)),
        AndroidNotificationAction('remind_later', 'Remind Me Later',
            showsUserInterface: true, titleColor: Color(0xFF800000)),
      ],
    ),
  );

  //---------------------------------------------------------------------------------------------------

  // Schedule a notification
  static Future<void> scheduledNotification({
    required int id,
    required TaskModel task,
    required DateTime scheduledDateTime,
    required String payload,
  }) async {
    String title = truncateText('Reminder: ${task.title}', 20);
    String notificationBody = buildNotificationBody(task);

    // Schedule periodic notifications
    if(task.repeat != 'Does not repeat'){
      log('scheduledNotification: Scheduling periodicallyShowWithDuration notification for notification $id, ${task.id}, ${task.title}');
      await periodicNotification(
        id: id,
        task: task,
        scheduledDateTime: scheduledDateTime,
        payload: payload,
      );
      return;
    }

    log('scheduledNotification: Scheduling zonedSchedule notification for notification $id, ${task.id}, ${task.title}');

    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        notificationBody,
        _convertTime(scheduledDateTime),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      log('SUCCESS scheduledNotification: $id, ${task.id}, ${task.title}');
      return;
    } on Exception catch (e) {
      log('FAILED scheduledNotification: $id, ${task.id}, ${task.title}');
      log('FAILED zonedSchedule: $e');
    }

  }

  // Schedule a periodic notification
  static Future<void> periodicNotification({
    required int id,
    required TaskModel task,
    required DateTime scheduledDateTime,
    required String payload,
  }) async {
    String title = truncateText('Reminder: ${task.title}', 20);
    String notificationBody = buildNotificationBody(task);

    // Fetch the NotificationController instance
    // final notificationController = Get.put(NotificationController());
    // notificationController.clearScheduledNotificationsForTask(task.id!);

    String? repeatValue = task.repeat;
    log('periodicNotification: repeatValue: $repeatValue');

    Duration? intervalDuration;
    log('periodicNotification: intervalDuration: $intervalDuration');


    // Define the repeat interval based on the task's "repeat" value
    switch (repeatValue) {
      case 'Every day':
        intervalDuration = Duration(minutes: 1);
        break;
      case 'Every week':
        intervalDuration = Duration(days: 7);
        break;
      case 'Every month':
        intervalDuration = Duration(days: 30); // Approximate monthly interval
        break;
      case 'Every year':
        intervalDuration = Duration(days: 365); // Approximate yearly interval
        break;
      default:
        intervalDuration = null;
        break;
    }

    // If repeat is set, schedule the periodic notifications
    if (intervalDuration != null) {
      log('periodicNotification: Scheduling periodicallyShowWithDuration for $id, ${task.id}, ${task.title}, repeatValue: $repeatValue, intervalDuration: $intervalDuration');
      try {
        await _flutterLocalNotificationsPlugin.periodicallyShowWithDuration(
          id,
          title,
          notificationBody,
          intervalDuration,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: payload,
        );
        log('SUCCESS periodicNotification: Scheduling periodicallyShowWithDuration for $id, ${task.id}, ${task.title}, repeatValue: $repeatValue, intervalDuration: $intervalDuration');
        return;
      } on Exception catch (e) {
        log('FAILED periodicNotification: Scheduling periodicallyShowWithDuration for $id, ${task.id}, ${task.title}, repeatValue: $repeatValue, intervalDuration: $intervalDuration');
        log('FAILED periodicNotification: $e');
        return;
      }
    }

    log('FAILED periodicNotification: Scheduling periodicallyShowWithDuration for $id, ${task.id}, ${task.title}, repeatValue: $repeatValue, intervalDuration: $intervalDuration');
    return;

    // else {
      // If repeat is not set, just schedule a one-time notification
      // log('periodicNotification: Scheduling zonedSchedule for $id, ${task.id}, ${task.title}, repeatValue: $repeatValue, intervalDuration: $intervalDuration');

      // await _flutterLocalNotificationsPlugin.zonedSchedule(
      //   id,
      //   title,
      //   notificationBody,
      //   tz.TZDateTime.from(scheduledDateTime, tz.local),
      //   const NotificationDetails(
      //     android: AndroidNotificationDetails(
      //       'your_channel_id', 'your_channel_name',
      //       channelDescription: 'your_channel_description',
      //       importance: Importance.max,
      //       priority: Priority.high,
      //     ),
      //   ),
      //   androidAllowWhileIdle: true,
      //   uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      //   payload: payload,
      // );
    // }
  }

  static Future<void> instantNotification({
    required int id,
    required TaskModel task,
    required DateTime scheduledDateTime,
  }) async {
    String title = truncateText('Reminder: ${task.title}', 20);
    // title = '<font color="#800000" size="7">$title</font>';
    String notificationBody = buildNotificationBody(task);

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      notificationBody,
      notificationDetails,
      payload: 'instant_notification:$id',
    );
    log("instantNotification scheduled for task ID: $id at ${scheduledDateTime.toString()}");
  }

  //-----------------------------------------------------------------------------------------------

  // Build the notification body
  static String buildNotificationBody(TaskModel task) {
    final description = truncateText(task.description, 20);
    String startDate = formatDateToText(task.startDate.toString());
    String startTime = formatTimeTo12Hour(task.startTime.toString());

    String priorityText = '';
    if (task.priority != null) {
      switch (task.priority) {
        case 'High':
          priorityText = '<font color="#FF0000">High</font>'; // Red color
          break;
        case 'Medium':
          priorityText = '<font color="#FFA500">Medium</font>'; // Orange color
          break;
        case 'Low':
          priorityText = '<font color="#008000">Low</font>'; // Green color
          break;
        default:
          priorityText = '';
      }
    }

    return '''
    ${description.isNotEmpty ? "$description<br>" : ''} 
  
    <font size="-1">Starts at: $startDate, $startTime</font>
    ${priorityText.isNotEmpty ? '<font size="-1">, Priority: $priorityText</font>' : ''}
  ''';
  }

  static String truncateText(String? text, int textLength) {
    if (text == null) return '';
    List<String> words = text.split(' ');
    if (words.length > textLength) {
      return '${words.sublist(0, textLength).join(' ')}...';
    }
    return text;
  }

  static String formatTimeTo12Hour(String time) {
    DateTime dateTime = DateFormat('HH:mm:ss').parse(time);
    return DateFormat('hh:mm a').format(dateTime); // 12-hour format with AM/PM
  }

  static String formatDateToText(String date) {
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
      return DateFormat('dd MMMM yyyy').format(taskDate); // e.g., "25 August 2024"
    }
  }


  //-----------------------------------------------------------------------------------------------------------

  // Handle notification taps
  static Future<void> _onSelectNotification({required String payload, required String? actionId}) async {
    log("Notification tapped with payload: $payload");
    logger.d("_onSelectNotification: Action: $actionId");

    // Payload should be in the format 'action:id'
    final parts = payload.split(',');
    log('parts: ${parts.toString()}');
    final finalParts = parts[0].split(':');
    log('finalParts: ${finalParts.toString()}');


    final id = int.tryParse(finalParts[1]);
    if (id == null) {
      log("Invalid task ID in payload: ${parts[1]}");
      return;
    }

    // Fetch the HomeScreenController instance
    final homeScreenController = Get.put(HomeScreenController());

    switch (actionId) {
      case 'mark_done':
        await _markTaskAsDone(id, homeScreenController);
        break;
      case 'remind_later':
        await _remindTaskLater(id);
        log("Remind later clicked");
        break;
      default:
        log("_onSelectNotification: Unknown action: $actionId");
        // homeScreenController.showTaskDetails(id);
        await _showTaskDetails(id, homeScreenController);
        break;
    }
  }

  static Future<void> _markTaskAsDone(
      int id, HomeScreenController homeScreenController) async {
    try {
      log("Marking task $id as done");
      await DatabaseHelper.instance.updateTaskStatus(id, 1);
      log("Task $id marked as completed.");
      // Update the UI or notify users
      homeScreenController.fetchTasks();
    } catch (e) {
      log("Failed to mark task $id as done: $e");
    }
  }



  static Future<void> _remindTaskLater(int id) async {
    final task = await DatabaseHelper.instance.getTaskById(id);
    if (task != null) {
      final reminderTime = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5));
      await scheduledNotification(
        id: id,
        task: task,
        scheduledDateTime: reminderTime,
        payload: 'remind_later:$id',
      );
    }
  }

  static Future<void> _showTaskDetails(
      int id, HomeScreenController homeScreenController) async {
    try {
      log("Navigating to task details for task $id");
      await homeScreenController.fetchTasks();
      Get.toNamed('/task-details', arguments: id);
    } catch (e) {
      log("Failed to navigate to task details for task $id: $e");
    }
  }

  // Cancel all notifications
  static Future<void> cancelAll() async {
    log("Cancelling all notifications...");
    await _flutterLocalNotificationsPlugin.cancelAll();
    log("Cancelled all notifications...");
  }

  // Cancel a specific notification by ID
  static Future<void> cancel(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
    log("Cleared notification for task ID: $id...");
  }

  // Retrieve pending notifications
  static Future<List<PendingNotificationRequest>> pendingNotifications() async {
    final List<PendingNotificationRequest> pendingNotificationRequests =
    await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
    return pendingNotificationRequests;
  }

  // Retrieve pending notifications
  static Future<List<ActiveNotification>> activeNotifications() async {
    final List<ActiveNotification> activeNotificationRequests =
    await _flutterLocalNotificationsPlugin.getActiveNotifications();
    return activeNotificationRequests;
  }

  static Future<List<PendingNotificationRequest>> getActiveNotifications() async {
    return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }


}
