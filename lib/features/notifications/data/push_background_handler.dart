import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Runs in its own isolate when a push arrives while the app is in the
/// background or closed. The system already shows a push that carries a
/// `notification` block, so there is nothing to display here — the handler
/// only has to exist and bring Firebase up for the plugin.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}
