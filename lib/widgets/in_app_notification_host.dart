/*
 * App-level presentation for in-app notifications.
 */

import 'dart:async';

import 'package:flutter/material.dart';

import '../models/in_app_notification.dart';
import '../services/in_app_notification_service.dart';

class InAppNotificationHost extends StatefulWidget {
  const InAppNotificationHost({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<InAppNotificationHost> createState() =>
      _InAppNotificationHostState();
}

class _InAppNotificationHostState
    extends State<InAppNotificationHost>
    with WidgetsBindingObserver {
  StreamSubscription<InAppNotification?>? _subscription;
  Timer? _dismissTimer;

  InAppNotification? _notification;
  bool _foreground = true;
  int _version = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    final state = WidgetsBinding.instance.lifecycleState;
    _foreground = state == null || state == AppLifecycleState.resumed;

    _subscription =
        InAppNotificationService.instance.events.listen(_receive);
  }

  void _receive(InAppNotification? notification) {
    if (!mounted) return;

    _dismissTimer?.cancel();

    if (!_foreground && notification != null) return;

    setState(() {
      _notification = notification;
      _version++;
    });

    if (notification != null) {
      _dismissTimer = Timer(notification.duration, _dismiss);
    }
  }

  void _dismiss() {
    _dismissTimer?.cancel();

    if (!mounted || _notification == null) return;

    setState(() {
      _notification = null;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;

    if (!_foreground) {
      _dismiss();
    }
  }

IconData _icon(InAppNotificationType type) {
  switch (type) {
    case InAppNotificationType.success:
      return Icons.check_circle_outline;

    case InAppNotificationType.message:
      return Icons.chat_bubble_outline_rounded;

    case InAppNotificationType.friendRequest:
      return Icons.person_add_alt_1_outlined;

    case InAppNotificationType.challenge:
      return Icons.outlined_flag;

    case InAppNotificationType.info:
      return Icons.notifications_none_rounded;
  }
}

  Widget _banner(InAppNotification notification) {
    return Semantics(
      liveRegion: true,
      container: true,
      child: Material(
        color: Colors.white,
        elevation: 3,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(
            color: Color(0xFFE2E3E7),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  _icon(notification.type),
                  size: 21,
                  color: const Color(0xFF1B2432),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      notification.title,
                      style: const TextStyle(
                        color: Color(0xFF1B2432),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: const TextStyle(
                        color: Color(0xFF7D818B),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Dismiss notification',
                onPressed: _dismiss,
                icon: const Icon(
                  Icons.close_rounded,
                  color: Color(0xFF7D818B),
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    _dismissTimer?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notification = _notification;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

return Stack(
  fit: StackFit.expand,
  children: [
    Positioned.fill(
      child: widget.child,
    ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: AnimatedSwitcher(
                    duration: reduceMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, -0.15),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: notification == null
                        ? const SizedBox.shrink(
                            key: ValueKey('no-notification'),
                          )
                        : KeyedSubtree(
                            key: ValueKey(_version),
                            child: _banner(notification),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}