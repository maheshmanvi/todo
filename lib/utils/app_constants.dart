class AppConstants {
  static const String appName = 'ToDo';
  static const String appTitle = 'Remainders';
  static const String welcomeMessage = 'Welcome To ToDo App!';

  static const List<String> priorityOptions = ['None', 'High', 'Medium', 'Low'];
  static const List<String> repeatOptions = ['None', 'Daily', 'Weekly', 'Monthly', 'Yearly'];

  static const addTitle = 'Add Task';
  static const editTitle = 'Edit Task';
  static const titleHintText = 'Add title';
  static const longTitleHintText = 'Write title here...';
  static const descriptionHintText = 'Add description';
  static const longDescriptionHintText = 'Write description here...';

  static const String databaseName = 'todo.db';
  static const String tableName = 'tasks';
  static const int databaseVersion = 1;

  static const String columnId = 'id';
  static const String columnCreatedOn = 'created_on';
  static const String columnTitle = 'title';
  static const String columnDescription = 'description';
  static const String columnStartDate = 'start_date';
  static const String columnStartTime = 'start_time';
  static const String columnEndDate = 'end_date';
  static const String columnEndTime = 'end_time';
  static const String columnPriority = 'priority';
  static const String columnRepeat = 'repeat';
  static const String columnTaskStatus = 'status';
  static const String columnReminderDate = 'reminder_date';
  static const String columnReminderTime = 'reminder_time';
  static const String columnNotification = 'notification';

}
