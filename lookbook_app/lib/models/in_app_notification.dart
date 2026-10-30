/*
 * Data displayed by the in-app notification banner.
 */

enum InAppNotificationType {
  info,
  success,
  message,
  friendRequest,
  challenge,
}

class InAppNotification {
  const InAppNotification({
    required this.title,
    required this.message,
    this.type = InAppNotificationType.info,
    this.duration = const Duration(seconds: 5),
  });

  final String title;
  final String message;
  final InAppNotificationType type;
  final Duration duration;
}