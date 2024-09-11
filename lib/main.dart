import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:todo/infrastructure/di.dart';
import 'package:todo/notification/local_notifications.dart';
import 'package:todo/screens/add_edit_task.dart';
import 'package:todo/controllers/add_edit_task_controller.dart';
import 'package:todo/screens/home_screen.dart';
import 'package:todo/controllers/home_screen_controller.dart';
import 'package:todo/utils/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    inject();

    // Initialize time zones
    tz.initializeTimeZones();

    // Initialize local notifications
    await LocalNotifications.initializeNotification();

    // Register controllers
    Get.put(HomeScreenController());
    Get.put(AddEditTaskController());

    log('Initialization complete.');

    runApp(const MyApp());
  } catch (e) {
    log('ERROR main: Initialization failed: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConstants.appName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.white, // Seed color as white or Colors.black for black.
          primary: const Color(0xFFB43F3F), // Custom primary color
          secondary: const Color(0xFFFF8225), // Custom secondary color
          surface: const Color(0xFFF8EDED), // Custom surface color
          // surface: Colors.grey[300], // Custom surface color
          background: const Color(0xFF173B45), // Custom background color
          surfaceContainerLowest: Colors.grey[100],
          surfaceContainerLow: Colors.grey[100],
          surfaceContainer: Colors.grey[50],

        ),
        useMaterial3: true,
      ),
      initialRoute: '/home',
      getPages: [
        GetPage(name: '/home', page: () => const HomeScreen()),
        GetPage(name: '/addEditTask', page: () => const AddEditTask()),
        // Add other routes here
      ],
      home: const HomeScreen(),
    );
  }
}
