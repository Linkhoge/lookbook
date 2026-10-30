/*
 * Sends foreground notification events to the app-level host.
 */

import 'dart:async';

import '../models/in_app_notification.dart';

class InAppNotificationService {
  InAppNotificationService._();

  static final instance = InAppNotificationService._();

  final _controller =
      StreamController<InAppNotification?>.broadcast();

  Stream<InAppNotification?> get events => _controller.stream;

  void show(InAppNotification notification) {
    _controller.add(notification);
  }

  void dismiss() {
    _controller.add(null);
  }
}