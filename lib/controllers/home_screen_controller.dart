import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:todo/model/task_model.dart';
import 'package:todo/services/database_helper.dart';
import 'package:todo/utils/my_utils.dart';
import 'package:todo/widgets/welcome.dart';

import '../notification/local_notifications.dart';
import '../notification/notification_controller.dart';

class HomeScreenController extends GetxController with WidgetsBindingObserver {
  var allTasks = <TaskModel>[].obs;
  var pendingTasks = <TaskModel>[].obs;
  var completedTasks = <TaskModel>[].obs;
  var overdueTasks = <TaskModel>[].obs;

  final _sortOption = 'Created on'.obs;
  final _filterOption = 'None'.obs;
  var searchQuery = ''.obs;
  final _selectedTab = 0.obs;
  var isLoading = false.obs; // Add this line

  // var allowNotification = false.obs;
  final RxBool allowNotification = false.obs;

  // final NotificationController notificationController = Get.put(NotificationController());

  String get sortOption => _sortOption.value;

  String get filterOption => _filterOption.value;

  int get selectedTab => _selectedTab.value;

  set sortOption(String sortOption) {
    _sortOption.value = sortOption;
    updateTaskLists();
  }

  set filterOption(String filterOption) {
    _filterOption.value = filterOption;
    updateTaskLists();
  }

  set selectedTab(int value) {
    _selectedTab.value = value;
    updateTaskLists();
  }

  final selectedFilters = RxSet<String>();

  @override
  void onInit() {
    super.onInit();
    // log('001fetchTasks()');
    // fetchTasks(); // Fetch tasks when the controller is initialized
    // checkNotifications();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      log('didChangeAppLifecycleState: 002fetchTasks()');
      fetchTasks(); // Refresh tasks when the app comes back to the foreground
    }
  }

  // Method to check for pending notifications
  Future<void> checkForPendingNotifications() async {
    List<PendingNotificationRequest> pendingNotifications =
        await LocalNotifications.pendingNotifications();
    if (pendingNotifications.isNotEmpty) {
      allowNotification.value =
          true; // Toggle switch ON if there are notifications
    } else {
      allowNotification.value = false; // Toggle switch OFF if no notifications
    }
  }

  Future<void> checkNotifications() async {
    final notificationController = Get.put(NotificationController());
    allowNotification.value =
        await notificationController.areNotificationsPending();
  }

  Future<void> fetchTasks() async {
    isLoading.value = true; // Start loading
    log('fetchTasks: STARTING');
    try {
      final db = DatabaseHelper.instance;
      final tasksData = await db.getAllTasks();

      final modelList =
          tasksData.map((data) => TaskModel.fromMap(data)).toList();

      // Apply task status updates
      List<TaskModel> updatedTasks = applyStatusUpdates(modelList);

      // Update the task lists
      updateTaskLists(updatedTasks);

      // Update UI
      update();
      log("fetchTasks: selectedTab: $selectedTab; sortOption: $sortOption; filterOption: $filterOption");
      log('fetchTasks: COMPLETED');
      // isLoading.value = false; // Stop loading
    } catch (e) {
      // isLoading.value = false; // Stop loading
      log("ERROR HomeScreenController.fetchTasks: $e");
    }
  }

  void updateTaskLists([List<TaskModel>? tasks]) {
    log('updateTaskLists: STARTING');
    try {
      final taskList = tasks ?? allTasks.toList();

      // Sort and filter tasks
      List<TaskModel> sortedTasks = _sortTasks(taskList);
      List<TaskModel> filteredTasks = _filterTasks(sortedTasks);

      // Assign tasks based on selected tab
      allTasks.assignAll(filteredTasks);

      overdueTasks.assignAll(
          filteredTasks.where((task) => task.taskStatus.value == 0).toList());
      completedTasks.assignAll(
          filteredTasks.where((task) => task.taskStatus.value == 1).toList());
      pendingTasks.assignAll(
          filteredTasks.where((task) => task.taskStatus.value == 2).toList());

      // Update UI
      update();
      log("updateTaskLists: sortOption: $sortOption; filterOption: $filterOption");
      log('updateTaskLists: COMPLETED');
    } catch (e) {
      log("ERROR HomeScreenController.updateTaskLists: $e");
    }
  }

  List<TaskModel> applyStatusUpdates(List<TaskModel> tasks) {
    for (var task in tasks) {
      updateTaskStatusPeriodically(task);
    }
    return tasks;
  }

  void updateTaskStatusPeriodically(TaskModel task) {
    DateTime? startDateTime = parseDateTime(task.startDate, task.startTime);
    DateTime? endDateTime;

    // Parse endDate and endTime if they're not null and not empty
    if (task.endDate != null &&
        task.endDate!.isNotEmpty &&
        task.endTime != null &&
        task.endTime!.isNotEmpty) {
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
          task.taskStatus.value =
              0; // Set to 0 if task status is not 1 (complete)
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

    // log('updateTaskStatusPeriodically: ${task.id}, ${task.title} status: ${task.taskStatus.value}, start: ${task.startDate} ${task.startTime}, end: ${task.endDate} ${task.endTime}');
  }

  RxList<TaskModel> get filteredTasks {
    final query = searchQuery.value.toLowerCase();
    final filtered = query.isEmpty
        ? allTasks
        : allTasks
            .where((task) =>
                task.title.toLowerCase().contains(query) ||
                (task.description?.toLowerCase().contains(query) ?? false))
            .toList();

    switch (selectedTab) {
      case 0:
        return filtered.obs;
      case 1:
        return filtered
            .where((task) => task.taskStatus.value == 1)
            .toList()
            .obs;
      case 2:
        return filtered
            .where((task) => task.taskStatus.value == 2)
            .toList()
            .obs;
      case 3:
        return filtered
            .where((task) => task.taskStatus.value == 0)
            .toList()
            .obs;
      default:
        return filtered.obs;
    }
  }

  List<TaskModel> _sortTasks(List<TaskModel> tasks) {
    switch (sortOption) {
      case 'Priority':
        return _sortByPriority(tasks);
      case 'Upcoming':
        return _sortByUpcoming(tasks);
      case 'Created on':
      default:
        return _sortByCreatedOn(tasks);
    }
  }

  List<TaskModel> _sortByPriority(List<TaskModel> tasks) {
    return tasks
      ..sort((a, b) {
        final priorityOrder = {'High': 1, 'Medium': 2, 'Low': 3};
        final priorityA = a.priority ?? '';
        final priorityB = b.priority ?? '';

        final orderA = priorityOrder[priorityA] ?? 4;
        final orderB = priorityOrder[priorityB] ?? 4;

        if (orderA != orderB) {
          return orderA.compareTo(orderB);
        }

        return _sortByCreatedOn([a, b]).indexOf(a) -
            _sortByCreatedOn([a, b]).indexOf(b);
      });
  }

  List<TaskModel> _sortByUpcoming(List<TaskModel> tasks) {
    return tasks
      ..sort((a, b) {
        final dateA = parseDateTime(a.startDate, a.startTime);
        final dateB = parseDateTime(b.startDate, b.startTime);

        if (dateA != null && dateB != null) {
          final dateComparison = dateA.compareTo(dateB);

          if (dateComparison != 0) return dateComparison;
          final timeComparison =
              _compareTime(a.startDate, a.startTime, b.startDate, b.startTime);
          if (timeComparison != 0) return timeComparison;
        } else if (dateA != null) {
          return -1;
        } else if (dateB != null) {
          return 1;
        }
        return _sortByCreatedOn([a, b]).indexOf(a) -
            _sortByCreatedOn([a, b]).indexOf(b);
      });
  }

  List<TaskModel> _sortByCreatedOn(List<TaskModel> tasks) {
    return tasks
      ..sort((a, b) {
        final dateA = a.createdOn;
        final dateB = b.createdOn;

        return dateB!.compareTo(dateA!);
      });
  }

  List<TaskModel> _filterTasks(List<TaskModel> tasks) {
    List<TaskModel> filteredTasks = tasks;

    bool hasDateFilter = selectedFilters
        .any((filter) => ['Today', 'Tomorrow', 'Yesterday'].contains(filter));
    bool hasPriorityFilter = selectedFilters
        .any((filter) => ['High', 'Medium', 'Low'].contains(filter));

    if (hasDateFilter) {
      filteredTasks = _filterByDate(filteredTasks);
    }
    if (hasPriorityFilter) {
      filteredTasks = _filterByPriority(filteredTasks);
    }
    return filteredTasks;
  }

  List<TaskModel> _filterByDate(List<TaskModel> tasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));

    // Check if any of the selected date filters are present
    bool filterToday = selectedFilters.contains('Today');
    bool filterTomorrow = selectedFilters.contains('Tomorrow');
    bool filterYesterday = selectedFilters.contains('Yesterday');

    return tasks.where((task) {
      final startDateTime = parseDateTime(task.startDate, task.startTime);
      if (startDateTime != null) {
        if (filterToday && startDateTime.day == today.day) return true;
        if (filterTomorrow && startDateTime.day == tomorrow.day) return true;
        if (filterYesterday && startDateTime.day == yesterday.day) return true;
      }
      return false;
    }).toList();
  }

  List<TaskModel> _filterByPriority(List<TaskModel> tasks) {
    final priorityFilters = {'High', 'Medium', 'Low'};
    final selectedPriorities = priorityFilters.intersection(selectedFilters);
    log("_filterByPriority: $selectedPriorities");
    log("_filterByPriority: ${selectedPriorities.contains('High')}");
    log("_filterByPriority: ${selectedPriorities.contains('Medium')}");
    log("_filterByPriority: ${selectedPriorities.contains('Low')}");

    if (selectedPriorities.isEmpty) return tasks;

    return tasks.where((task) {
      return selectedPriorities.contains(task.priority);
    }).toList();
  }

  Future<void> deleteTask(int id) async {
    final db = DatabaseHelper.instance;
    await db.delete(id);
    allTasks.removeWhere((task) => task.id == id);
    MyUtils.showToast('Deleted');
    // Notify the NotificationController to cancel scheduled notification
    final notificationController = Get.put(NotificationController());
    await notificationController.clearScheduledNotificationsForTask(id);
  }

  Future<void> deleteAllTasks() async {
    log("updateTaskStatus: STARTING");
    final db = DatabaseHelper.instance;
    await db.deleteAll();
    allTasks.clear();
    MyUtils.showToast('All deleted');

    // Notify the NotificationController to cancel all the scheduled notification
    NotificationController notificationController =
        Get.put(NotificationController());
    await notificationController.clearAllNotifications();
  }

  Future<void> updateTaskStatus(TaskModel task) async {
    log('updateTaskStatus: updating task ${task.id} with task status ${task.taskStatus}');
    final db = DatabaseHelper.instance;
    await db.updateTask(task);

    log('updateTaskStatus: looking for the task ${task.id} in task list(allTasks)');
    try {
      int index = allTasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        allTasks[index] = task;
      }
      log('updateTaskStatus: found the task ${task.id} in the index $index in task list(allTasks)');
    } catch (e) {
      log('ERROR HomeScreenController.updateTaskStatus: $e');
    }

    try {
      NotificationController notificationController =
          Get.put(NotificationController());
      if (task.taskStatus.value == 1) {
        await notificationController
            .clearScheduledNotificationsForTask(task.id as int);
      } else {
        await notificationController.rescheduleNotificationsForTask(task);
      }
    } catch (e) {
      log('ERROR HomeScreenController.updateTaskStatus: After task status inundation failed to update notification, error is logged below.');
      log('ERROR HomeScreenController.updateTaskStatus: $e');
    }

    update();
    log("updateTaskStatus: COMPLETED");
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  TaskModel getTaskById(int? id) {
    log("getTaskById: STARTING");

    if (id == null) {
      throw Exception('getTaskById: Task ID cannot be null');
    }

    try {
      TaskModel taskFound =
          allTasks.firstWhere((task) => task.id == id, orElse: () {
        throw Exception('ERROR getTaskById: Task not found for id $id');
      });
      log("getTaskById: COMPLETED");
      return taskFound;
    } catch (e) {
      log("getTaskById: Exception - ${e.toString()}");
      rethrow;
    }
  }

  DateTime? parseDateTime(String? date, String? time) {
    if (date == null || date.isEmpty) return null;

    final dateString = date;
    final timeString = time ?? '00:00:00';
    try {
      return DateFormat('dd-MM-yyyy HH:mm:ss').parse('$dateString $timeString');
    } catch (e) {
      log('ERROR HomeScreenController.parseDateTime: $e');
      return null;
    }
  }

  String formatTime(String timeStr) {
    try {
      final timeParts = timeStr.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final period = hour >= 12 ? 'pm' : 'am';

      final formattedHour = hour > 12
          ? hour - 12
          : hour == 0
              ? 12
              : hour;
      return '${formattedHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      log('ERROR HomeScreenController.formatTime: $e');
      return '---';
    }
  }

  int _compareTime(String? dateA, String? timeA, String? dateB, String? timeB) {
    final timeStringA = timeA ?? '00:00:00';
    final timeStringB = timeB ?? '00:00:00';

    final timeAParsed = DateFormat('HH:mm:ss').parse(timeStringA);
    final timeBParsed = DateFormat('HH:mm:ss').parse(timeStringB);

    return timeAParsed.compareTo(timeBParsed);
  }

  Widget showWelcomeMsg() {
    return const EmptyTasksWidget();
  }

  String wishingText() {
    return 'test';
  }

  String getGreeting() {
    final now = DateTime.now();
    final hour = now.hour;

    if (hour >= 5 && hour < 12) {
      return 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon';
    } else if (hour >= 17 && hour < 20) {
      return 'Good Evening';
    } else {
      return 'Good Night';
    }
  }
}
