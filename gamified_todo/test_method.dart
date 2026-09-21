import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() {
  final plugin = AndroidFlutterLocalNotificationsPlugin();
  // If this compiles, the method exists.
  plugin.requestFullScreenIntentPermission();
}
