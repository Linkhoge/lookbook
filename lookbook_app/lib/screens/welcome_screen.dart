/*
 * Welcome screen with Firebase startup and animated actions.
 * Author: Ariel Fajimiyo
 */

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../firebase_options.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  static const _background = Color(0xFFFAFAF8);
  static const _ink = Color(0xFF1B2432);
  static const _gold = Color(0xFFCCA251);

  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _position;

  bool _ready = false;
  bool _failed = false;
  bool _starting = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _opacity = _controller.drive(
      CurveTween(curve: Curves.easeOut),
    );

    _position = _controller.drive(
      Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).chain(
        CurveTween(curve: Curves.easeOutCubic),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _start();
    });
  }

  Future<void> _initialiseApp() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  }

  Future<void> _start() async {
    if (_starting || _ready) return;

    _starting = true;

    if (_failed) {
      setState(() {
        _failed = false;
      });
    }

    try {
      await _initialiseApp();

      if (!mounted) return;

      setState(() {
        _ready = true;
      });

      if (MediaQuery.of(context).disableAnimations) {
        _controller.value = 1;
      } else {
        _controller.forward();
      }
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Firebase startup failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }

      if (!mounted) return;

      setState(() {
        _failed = true;
      });
    } finally {
      _starting = false;
    }
  }

  void _openSignUp() {
    if (!_ready) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SignUpScreen(),
      ),
    );
  }

  void _openLogin() {
    if (!_ready) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
    );
  }

  Widget _branding() {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'LOOKBOOK',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _ink,
            fontSize: 30,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.7,
          ),
        ),
        SizedBox(height: 12),
        SizedBox(
          width: 36,
          height: 1,
          child: ColoredBox(color: _gold),
        ),
      ],
    );
  }

  Widget _actions() {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(5),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: _openSignUp,
            style: FilledButton.styleFrom(
              backgroundColor: _ink,
              foregroundColor: Colors.white,
              shape: shape,
            ),
            child: const Text('Sign up'),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 48,
          child: OutlinedButton(
            onPressed: _openLogin,
            style: OutlinedButton.styleFrom(
              foregroundColor: _ink,
              side: const BorderSide(color: _ink, width: 0.7),
              shape: shape,
            ),
            child: const Text('Log in'),
          ),
        ),
      ],
    );
  }

  Widget _startupError() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Could not start LookBook.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _ink),
        ),
        TextButton(
          onPressed: _start,
          style: TextButton.styleFrom(foregroundColor: _ink),
          child: const Text('Try again'),
        ),
      ],
    );
  }

  Widget _bottomContent() {
    if (_failed) return _startupError();

    return IgnorePointer(
      ignoring: !_ready,
      child: ExcludeFocus(
        excluding: !_ready,
        child: ExcludeSemantics(
          excluding: !_ready,
          child: FadeTransition(
            opacity: _opacity,
            child: SlideTransition(
              position: _position,
              child: _actions(),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Positioned(
                  top: constraints.maxHeight * 0.40,
                  left: 24,
                  right: 24,
                  child: _branding(),
                ),
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 28,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: _bottomContent(),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}