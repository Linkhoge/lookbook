/*
 * Email/password login and password recovery.
 * Author: Ariel Fajimiyo
 */

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _ink = Color(0xFF1B2432);
  static const _muted = Color(0xFF7D818B);

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _busy = false;
  bool _hidePassword = true;
  String? _status;

  void _setStatus(String text) {
    if (mounted) setState(() => _status = text);
  }

  String _errorMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          return 'Could not sign in. Check your email and password.';
        case 'invalid-email':
          return 'Enter a valid email address.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        case 'network-request-failed':
          return 'Check your connection and try again.';
        case 'user-disabled':
          return 'This account has been disabled.';
        default:
          return 'Authentication failed (${error.code}).';
      }
    }

    if (error is FirebaseException) {
      return 'Could not load your profile (${error.code}). Try again.';
    }

    return 'Something went wrong. Please try again.';
  }

  Future<void> _login() async {
    if (_busy || !(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _busy = true;
      _status = null;
    });

    try {
      final credential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final signedInUser = credential.user;

      if (signedInUser == null) {
        throw StateError('No user returned.');
      }

      await signedInUser.reload();

      final user = FirebaseAuth.instance.currentUser;

      if (user == null || user.uid != signedInUser.uid) {
        throw StateError('Session changed.');
      }

      Widget destination = const SignUpScreen();

      if (user.emailVerified) {
        await user.getIdToken(true);

        final profile = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (profile.exists) {
          destination = const HomeScreen(
          showLoginNotification: true,
          );
        }
      }

      if (!mounted) return;

      _passwordController.clear();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => destination),
        (_) => false,
      );
    } catch (error) {
      _setStatus(_errorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_busy) return;

    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _setStatus('Enter your email above first.');
      return;
    }

    setState(() {
      _busy = true;
      _status = null;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      _setStatus(
        'If an account exists for this email, '
        'check your inbox for a reset link.',
      );
    } on FirebaseAuthException catch (error) {
      if (error.code == 'user-not-found') {
        _setStatus(
          'If an account exists for this email, '
          'check your inbox for a reset link.',
        );
      } else {
        _setStatus(_errorMessage(error));
      }
    } catch (error) {
      _setStatus(_errorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF8F9FB),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 15,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFFE2E3E7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: _ink),
      ),
    );
  }

  Widget _label(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          color: _ink,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _ink,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Welcome back',
                        style: TextStyle(
                          color: _ink,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Log in to LookBook.',
                        style: TextStyle(color: _muted, fontSize: 13),
                      ),
                      const SizedBox(height: 28),
                      _label('Email'),
                      TextFormField(
                        controller: _emailController,
                        readOnly: _busy,
                        decoration: _decoration('Email address'),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.username],
                        autocorrect: false,
                        enableSuggestions: false,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter your email.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      _label('Password'),
                      TextFormField(
                        controller: _passwordController,
                        readOnly: _busy,
                        obscureText: _hidePassword,
                        autocorrect: false,
                        enableSuggestions: false,
                        autofillHints: const [AutofillHints.password],
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _login(),
                        decoration: _decoration('Password').copyWith(
                          suffixIcon: IconButton(
                            tooltip:
                                _hidePassword ? 'Show password' : 'Hide password',
                            onPressed: _busy
                                ? null
                                : () {
                                    setState(() {
                                      _hidePassword = !_hidePassword;
                                    });
                                  },
                            icon: Icon(
                              _hidePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: _muted,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter your password.';
                          }
                          return null;
                        },
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _busy ? null : _resetPassword,
                          child: const Text(
                            'Forgot password?',
                            style: TextStyle(color: _muted, fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 48,
                        child: FilledButton(
                          onPressed: _busy ? null : _login,
                          style: FilledButton.styleFrom(
                            backgroundColor: _ink,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          child: _busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    semanticsLabel: 'Please wait',
                                  ),
                                )
                              : const Text('Log in'),
                        ),
                      ),
                      if (_status != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Semantics(
                            liveRegion: true,
                            child: Text(
                              _status!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: _ink,
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (_) => const SignUpScreen(),
                                  ),
                                );
                              },
                        child: const Text(
                          'Create an account',
                          style: TextStyle(color: _ink),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}