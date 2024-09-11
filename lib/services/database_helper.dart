import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:todo/model/task_model.dart';
import 'package:todo/utils/app_constants.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();

  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), AppConstants.databaseName);
    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.tableName} (
        ${AppConstants.columnId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${AppConstants.columnCreatedOn} TEXT,
        ${AppConstants.columnTitle} TEXT NOT NULL,
        ${AppConstants.columnDescription} TEXT,
        ${AppConstants.columnStartDate} TEXT,
        ${AppConstants.columnStartTime} TEXT,
        ${AppConstants.columnEndDate} TEXT,
        ${AppConstants.columnEndTime} TEXT,
        ${AppConstants.columnPriority} TEXT,
        ${AppConstants.columnRepeat} TEXT,
        ${AppConstants.columnReminderDate} TEXT,
        ${AppConstants.columnReminderTime} TEXT,
        ${AppConstants.columnTaskStatus} INTEGER,
        ${AppConstants.columnNotification} TEXT
      )
    ''');
  }

  Future<int> insert(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert(AppConstants.tableName, row);
  }

  Future<int> update(Map<String, dynamic> row) async {
    Database db = await database;
    int id = row[AppConstants.columnId];
    return await db.update(AppConstants.tableName, row,
        where: '${AppConstants.columnId} = ?', whereArgs: [id]);
  }

  Future<int> updateTask(TaskModel task) async {
    final db = await database;
    if (task.id == null) {
      throw ArgumentError('Task ID cannot be null.');
    }

    log('db.updateStatus: task: ${task.toString()}');
    return await db.update(
      'tasks',
      {
        'status': task.taskStatus.value,
      },
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }


  Future<int> delete(int id) async {
    Database db = await database;
    return await db.delete(AppConstants.tableName,
        where: '${AppConstants.columnId} = ?', whereArgs: [id]);
  }

  Future<int> deleteAll() async {
    Database db = await database;
    return await db.delete(AppConstants.tableName);
  }

  Future<List<Map<String, dynamic>>> getAllTasks() async {
    Database db = await database;
    return await db.query(AppConstants.tableName);
  }

  Future<TaskModel> getTaskById(int id) async {
    Database db = await database;
    final queryResult = await db.query(AppConstants.tableName,
        where: '${AppConstants.columnId} = ?', whereArgs: [id]);
    return TaskModel.fromMap(queryResult.first);
  }

  Future<int> updateTaskStatus(int taskId, int newStatus) async {
    debugPrint(
        "Starting updateTaskStatus for taskId: $taskId with newStatus: $newStatus");

    Database db = await database;
    debugPrint("Database instance obtained");

    // Fetch the existing task (for logging purposes, but not using the old status)
    final existingTask = await getTaskById(taskId);
    debugPrint("Fetched task: ${existingTask.toString()}");

    // Update the task status with the new status
    final result = await db.update(
      'tasks',
      {
        'status': 1, // Update with newStatus, not existingTask.taskStatus
      },
      where: 'id = ?',
      whereArgs: [taskId], // Ensure the correct task is being updated
    );

    final updatedTask = await getTaskById(taskId);
    debugPrint("Updated task: ${updatedTask.toString()}");

    if (result > 0) {
      debugPrint("Task updated successfully. Rows affected: $result");
    } else {
      debugPrint("Failed to update task. Rows affected: $result");
    }

    return result;
  }

  Future<int> updateNotification(int taskId, int notificationStatus) async {
    debugPrint(
        "Starting updateNotification for taskId: $taskId with notificationStatus: $notificationStatus");

    Database db = await database;
    debugPrint("Database instance obtained");

    // Fetch the existing task (for logging purposes, but not using the old status)
    final existingTask = await getTaskById(taskId);
    debugPrint("Fetched task: ${existingTask.toString()}");

    // Update the task status with the new status
    final result = await db.update(
      'tasks',
      {
        'notification': 1, // Update with newStatus, not existingTask.taskStatus
      },
      where: 'id = ?',
      whereArgs: [taskId], // Ensure the correct task is being updated
    );

    final updatedTask = await getTaskById(taskId);
    debugPrint("Updated task: ${updatedTask.toString()}");

    if (result > 0) {
      debugPrint("Task updated successfully. Rows affected: $result");
    } else {
      debugPrint("Failed to update task. Rows affected: $result");
    }

    return result;
  }
}
