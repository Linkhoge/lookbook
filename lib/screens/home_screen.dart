/*
 * Home-screen demo with shared social interactions
 * and a delayed test message notification.
 * Author: Ariel Fajimiyo
 */

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/in_app_notification.dart';
import '../services/demo_social_state.dart';
import '../services/in_app_notification_service.dart';

import 'profile_screen.dart';
import 'radar_challenge.dart';
import 'welcome_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.showLoginNotification = false,
  });

  final bool showLoginNotification;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HeartBurst {
  const _HeartBurst(this.id, this.position);

  final int id;
  final Offset position;
}

class _HomeScreenState extends State<HomeScreen> {
  static const _background = Color(0xFFFAFAF8);
  static const _ink = Color(0xFF1B2432);
  static const _muted = Color(0xFF7D818B);
  static const _line = Color(0xFFE2E3E7);
  static const _gold = Color(0xFFCCA251);

  final _social = DemoSocialState.instance;
  final List<_HeartBurst> _hearts = [];

  Timer? _loginNotificationTimer;

  int _tab = 0;
  int _feedTab = 0;
  int _heartId = 0;

  bool _signingOut = false;

  Offset _doubleTapPosition = const Offset(120, 120);

  void _log(String text) {
    debugPrint('[TEST MESSAGE] $text');
  }

  @override
  void initState() {
    super.initState();

    _social.addListener(_refresh);

    _log(
      'Home opened. '
      'showLoginNotification=${widget.showLoginNotification}',
    );

    if (!widget.showLoginNotification) {
      _log('Not scheduled: login notification flag is false.');
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _log('Not scheduled: Home is no longer mounted.');
        return;
      }

      final uid = FirebaseAuth.instance.currentUser?.uid;

      if (uid == null) {
        _log('Not scheduled: no signed-in Firebase user.');
        return;
      }

      _log('Timer scheduled for 4 seconds.');

      _loginNotificationTimer = Timer(
        const Duration(seconds: 4),
        () {
          _loginNotificationTimer = null;
          _log('Timer fired.');

          if (!mounted) {
            _log('Skipped: Home is no longer mounted.');
            return;
          }

          if (_signingOut) {
            _log('Skipped: signing out.');
            return;
          }

          if (FirebaseAuth.instance.currentUser?.uid != uid) {
            _log('Skipped: signed-in user changed.');
            return;
          }

          final lifecycle =
              WidgetsBinding.instance.lifecycleState;

          _log('App lifecycle: $lifecycle');

          if (lifecycle != null &&
              lifecycle != AppLifecycleState.resumed) {
            _log(
              'Skipped: app is not active. '
              'Return to Home and tap the test message icon. '
              'The automatic timer does not retry.',
            );
            return;
          }

          _showTestMessage(source: 'automatic timer');
        },
      );
    });
  }

  void _showTestMessage({required String source}) {
    _log('Test requested by $source.');

    if (!mounted) {
      _log('Skipped: Home is no longer mounted.');
      return;
    }

    if (_signingOut) {
      _log('Skipped: signing out.');
      return;
    }

    if (FirebaseAuth.instance.currentUser == null) {
      _log('Skipped: no signed-in Firebase user.');
      _message('Sign in before testing the message.');
      return;
    }

    try {
      _log(
        'Calling notification service: '
        'Student — this is a test message',
      );

      InAppNotificationService.instance.show(
        const InAppNotification(
          title: 'Student',
          message: 'this is a test message',
          type: InAppNotificationType.message,
          duration: Duration(seconds: 10),
        ),
      );

      _log(
        'Service.show() returned. '
        'This confirms the call completed, '
        'not that the banner rendered.',
      );
    } catch (error, stackTrace) {
      _log('Notification call failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        _message(
          'Could not show the test message. Check the console.',
        );
      }
    }
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(text)),
      );
  }

  void _openStudent() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ProfileScreen(
          data: ProfileData.demoStudent,
        ),
      ),
    );
  }

  void _doubleLike() {
    if (_social.blocked) return;

    _social.like();

    if (MediaQuery.of(context).disableAnimations) return;

    final burst = _HeartBurst(
      _heartId++,
      _doubleTapPosition,
    );

    setState(() {
      // Limit simultaneous heart animations.
      if (_hearts.length >= 12) {
        _hearts.removeAt(0);
      }

      _hearts.add(burst);
    });

    Future<void>.delayed(
      const Duration(milliseconds: 800),
      () {
        if (!mounted) return;

        setState(() {
          _hearts.removeWhere(
            (heart) => heart.id == burst.id,
          );
        });
      },
    );
  }

  void _postAction(String action) {
    switch (action) {
      case 'hide':
        _social.hidePosts();
        _message('Student’s posts hidden for this session.');
        break;

      case 'block':
        _social.toggleBlock();
        _message('Student blocked for this session.');
        break;
    }
  }

  void _openUpload() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Upload',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(
                    Icons.checkroom_outlined,
                  ),
                  title: const Text('Clothing item'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();

                    setState(() {
                      _tab = 1;
                    });

                    _message('Upload is not connected yet.');
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_camera_outlined,
                  ),
                  title: const Text('Outfit post'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _message('Posting is not connected yet.');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _signOut() async {
    if (_signingOut) return;

    setState(() {
      _signingOut = true;
    });

    _log('Signing out. Cancelling any pending test timer.');

    _loginNotificationTimer?.cancel();
    _loginNotificationTimer = null;

    try {
      InAppNotificationService.instance.dismiss();
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      _social.reset();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const WelcomeScreen(),
        ),
        (_) => false,
      );
    } catch (error, stackTrace) {
      _log('Sign-out failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _signingOut = false;
      });

      _message('Could not sign out. Try again.');
    }
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'LOOKBOOK',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _ink,
                fontSize: 25,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.6,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Test Student message',
            onPressed: _signingOut
                ? null
                : () {
                    _showTestMessage(
                      source: 'manual message button',
                    );
                  },
            icon: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: _ink,
            ),
          ),
          const SizedBox(width: 4),
          FilledButton(
            onPressed: _openUpload,
            style: FilledButton.styleFrom(
              backgroundColor: _ink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Text('+ Upload'),
          ),
        ],
      ),
    );
  }

  Widget _tabs() {
    const labels = [
      'Campus',
      'Friends',
      'Challenges',
    ];

    return Row(
      children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: TextButton(
              onPressed: () {
                setState(() {
                  _feedTab = i;
                });
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    labels[i],
                    style: TextStyle(
                      color: _feedTab == i ? _ink : _muted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 7),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    height: 2,
                    width: _feedTab == i ? 32 : 0,
                    color: _gold,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _photo() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onDoubleTapDown: (details) {
        _doubleTapPosition = details.localPosition;
      },
      onDoubleTap: _doubleLike,
      child: Container(
        height: 260,
        width: double.infinity,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: const Color(0xFFEAEBED),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.image_outlined,
                    color: _muted,
                    size: 32,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Outfit photo',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            for (final heart in _hearts)
              Positioned(
                key: ValueKey(heart.id),
                left: heart.position.dx - 36,
                top: heart.position.dy - 36,
                child: IgnorePointer(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: 0.0,
                      end: 1.0,
                    ),
                    duration: const Duration(milliseconds: 750),
                    builder: (context, progress, child) {
                      final opacity = progress < 0.6
                          ? 1.0
                          : ((1 - progress) / 0.4)
                              .clamp(0.0, 1.0)
                              .toDouble();

                      final scale = progress < 0.2
                          ? 0.5 + progress * 3
                          : 1.1;

                      return Opacity(
                        opacity: opacity,
                        child: Transform.translate(
                          offset: Offset(0, -progress * 45),
                          child: Transform.rotate(
                            angle: heart.id.isEven ? -0.15 : 0.15,
                            child: Transform.scale(
                              scale: scale,
                              child: child,
                            ),
                          ),
                        ),
                      );
                    },
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: Colors.white,
                      size: 72,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _post() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: _line),
          bottom: BorderSide(color: _line),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _openStudent,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Color(0xFFEFF1F7),
                          child: Text(
                            'S',
                            style: TextStyle(
                              color: _ink,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Student',
                                style: TextStyle(
                                  color: _ink,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                '@student · Demo post',
                                style: TextStyle(
                                  color: _muted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Post options',
                onSelected: _postAction,
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'hide',
                    child: Text('Hide posts'),
                  ),
                  PopupMenuItem(
                    value: 'block',
                    child: Text('Block Student'),
                  ),
                ],
                icon: const Icon(
                  Icons.more_horiz,
                  color: _muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Lecture fit. Keeping it simple today.',
            style: TextStyle(
              color: _ink,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          _photo(),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Lectures · Campus casual',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 11,
                  ),
                ),
              ),
              IconButton(
                tooltip: _social.liked ? 'Unlike' : 'Like',
                onPressed: _social.toggleLike,
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(
                      scale: animation,
                      child: child,
                    );
                  },
                  child: Icon(
                    _social.liked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    key: ValueKey(_social.liked),
                    color: _social.liked
                        ? const Color(0xFFB95262)
                        : _muted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _challengeBanner() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 6,
      ),
      title: const Text(
        'Campus discovery',
        style: TextStyle(
          color: _ink,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: const Text(
        'Photo spots · work in progress',
        style: TextStyle(
          color: _muted,
          fontSize: 12,
        ),
      ),
      trailing: const Icon(
        Icons.north_east,
        size: 18,
        color: _muted,
      ),
      onTap: () {
        setState(() {
          _feedTab = 2;
        });
      },
    );
  }

  Widget _friends() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Friends',
          style: TextStyle(
            color: _ink,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Demo requests are not sent to real accounts.',
          style: TextStyle(
            color: _muted,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 20),
        ListTile(
          contentPadding: EdgeInsets.zero,
          onTap: _openStudent,
          leading: const CircleAvatar(
            child: Text('S'),
          ),
          title: const Text('Student'),
          subtitle: Text(
            _social.blocked
                ? 'Blocked'
                : _social.requestPending
                    ? '@student · Request pending'
                    : '@student · Demo account',
          ),
          trailing: _social.blocked
              ? TextButton(
                  onPressed: _social.toggleBlock,
                  child: const Text('Unblock'),
                )
              : TextButton(
                  onPressed: _social.toggleRequest,
                  child: Text(
                    _social.requestPending ? 'Cancel' : 'Add',
                  ),
                ),
        ),
      ],
    );
  }

  Widget _feed() {
    if (_feedTab == 1) {
      return _friends();
    }

    if (_feedTab == 2) {
      return const RadarChallenge();
    }

    return ListView(
      children: [
        _challengeBanner(),
        if (_social.blocked || _social.postsHidden)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  _social.blocked
                      ? 'Student is blocked.'
                      : 'Student’s posts are hidden.',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 13,
                  ),
                ),
                TextButton(
                  onPressed: _social.blocked
                      ? _social.toggleBlock
                      : _social.showPosts,
                  child: Text(
                    _social.blocked
                        ? 'Unblock Student'
                        : 'Show posts',
                  ),
                ),
              ],
            ),
          )
        else
          _post(),
      ],
    );
  }

  Widget _placeholder(String title) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _ink,
              fontSize: 21,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Work in progress',
            style: TextStyle(
              color: _muted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    switch (_tab) {
      case 0:
        return Column(
          children: [
            _header(),
            _tabs(),
            Expanded(child: _feed()),
          ],
        );

      case 1:
        return _placeholder('Your wardrobe');

      case 2:
        return _placeholder('Your lookbook');

      default:
        return MyProfileTab(
          onSignOut: _signOut,
          signingOut: _signingOut,
        );
    }
  }

  @override
  void dispose() {
    _log('Home disposed. Cancelling any pending test timer.');

    _loginNotificationTimer?.cancel();
    _social.removeListener(_refresh);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                Expanded(child: _body()),
                BottomNavigationBar(
                  currentIndex: _tab,
                  onTap: (index) {
                    setState(() {
                      _tab = index;
                    });
                  },
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: Colors.white,
                  selectedItemColor: _ink,
                  unselectedItemColor: _muted,
                  selectedFontSize: 10,
                  unselectedFontSize: 10,
                  elevation: 0,
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home_outlined),
                      label: 'Home',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.checkroom_outlined),
                      label: 'Wardrobe',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.menu_book_outlined),
                      label: 'Lookbook',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.person_outline),
                      label: 'Profile',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}