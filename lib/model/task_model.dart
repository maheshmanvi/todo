import 'dart:developer';

import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:todo/model/task_element.dart';

class TaskModel extends TaskElement {
  static final DateFormat _dateFormat = DateFormat('dd-MM-yyyy');
  static final DateFormat _timeFormat = DateFormat('HH:mm:ss');

  // Existing fields
  final String? description;
  final String? startDate;
  final String? startTime;
  final String? endDate;
  final String? endTime;
  final String? priority;
  final String? repeat;
  final DateTime? createdOn;
  final int? id;
  final String? reminderDate;
  final String? reminderTime;

  // taskStatus as an RxInt (observable)
  RxInt taskStatus;

  // taskStatus as an RxInt (observable)
  RxString? notification;

  TaskModel({
    required super.title,
    this.description = '',
    this.startDate = '',
    this.startTime = '',
    this.endDate = '',
    this.endTime = '',
    this.priority = '',
    this.repeat = '',
    DateTime? createdOn,
    this.id,
    required this.taskStatus, // Initialize taskStatus as RxInt
    this.notification, // Initialize taskStatus as RxString
    this.reminderDate = '',
    this.reminderTime = '',
  }) : createdOn = createdOn ?? DateTime.now();

  // Modify the copyWith method to handle taskStatus as well
  TaskModel copyWith({
    String? title,
    String? description,
    String? startDate,
    String? startTime,
    String? endDate,
    String? endTime,
    String? priority,
    String? repeat,
    DateTime? createdOn,
    int? id,
    RxInt? taskStatus, // Make sure taskStatus is an RxInt
    RxString? notification, // Make sure taskStatus is an RxString
    String? reminderDate,
    String? reminderTime,

  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      startTime: startTime ?? this.startTime,
      endDate: endDate ?? this.endDate,
      endTime: endTime ?? this.endTime,
      priority: priority ?? this.priority,
      repeat: repeat ?? this.repeat,
      createdOn: createdOn ?? this.createdOn,
      taskStatus: taskStatus ?? this.taskStatus, // Use RxInt directly
      notification: notification ?? this.notification, // Use RxString directly
      reminderDate: reminderDate ?? this.reminderDate,
      reminderTime: reminderTime ?? this.reminderTime,
    );
  }

  // fromMap method to handle taskStatus as an RxInt
  factory TaskModel.fromMap(Map<String, dynamic> map) {
    DateTime? parseDateTime(String dateTimeString) {
      try {
        final dateTimeParts = dateTimeString.split(' ');
        final date = _dateFormat.parse(dateTimeParts[0]);
        final time = _timeFormat.parse(dateTimeParts[1]);
        DateTime newDate = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
          time.second,
        );
        return newDate;
      } catch (e) {
        log("ERROR TaskModel.fromMap: Exception: $e");
        return null;
      }
    }

    return TaskModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      startDate: map['start_date'] as String? ?? '',
      startTime: map['start_time'] as String? ?? '',
      endDate: map['end_date'] as String? ?? '',
      endTime: map['end_time'] as String? ?? '',
      priority: map['priority'] as String? ?? '',
      repeat: map['repeat'] as String? ?? '',
      createdOn: map['created_on'] != null
          ? parseDateTime(map['created_on'] as String)
          : null,
      taskStatus: RxInt(map['status'] as int? ?? 0), // Initialize as RxInt
      notification: RxString(map['notification'] as String? ?? ''), // Initialize as RxString
      // notification: RxString(map['status'] as String? ?? ''), // Initialize as RxString
      reminderDate: map['reminder_date'] as String? ?? '',
      reminderTime: map['reminder_time'] as String? ?? '',
    );
  }

  // toMap method to handle taskStatus as an RxInt
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description?.isEmpty ?? true ? null : description,
      'start_date': startDate?.isEmpty ?? true ? null : startDate,
      'start_time': startTime?.isEmpty ?? true ? null : startTime,
      'end_date': endDate?.isEmpty ?? true ? null : endDate,
      'end_time': endTime?.isEmpty ?? true ? null : endTime,
      'priority': priority?.isEmpty ?? true ? null : priority,
      'repeat': repeat?.isEmpty ?? true ? null : repeat,
      // 'created_on': createdOn?.toIso8601String(),
      'created_on': createdOn != null
          ? '${_dateFormat.format(createdOn!)} ${_timeFormat.format(createdOn!)}'
          : null,
      'status': taskStatus.value, // Extract the value of RxInt
      'notification':  notification?.value.isEmpty ?? true ? null : notification?.value,
      'reminder_date': reminderDate?.isEmpty ?? true ? null : reminderDate,
      'reminder_time': reminderTime?.isEmpty ?? true ? null : reminderTime,
    };
  }

  @override
  String toString() {
    return 'TaskModel{description: $description, startDate: $startDate, startTime: $startTime, endDate: $endDate, endTime: $endTime, priority: $priority, repeat: $repeat, createdOn: $createdOn, id: $id, reminderDate: $reminderDate, reminderTime: $reminderTime, taskStatus: $taskStatus, notification: $notification}';
  }
}
