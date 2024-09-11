import 'package:get/get.dart';
import 'package:todo/notification/notification_controller.dart';

void inject() async {
  Get.put(NotificationController());
}