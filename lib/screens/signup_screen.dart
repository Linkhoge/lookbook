/*
 * Registration, email verification, and Firestore profile creation.
 * Author: Ariel Fajimiyo
 */

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/password_breach_service.dart';
import '../validators/signup_validators.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with WidgetsBindingObserver {
  static const _ink = Color(0xFF1B2432);
  static const _muted = Color(0xFF7D818B);
  static const _border = Color(0xFFE2E3E7);
  static const _fieldBackground = Color(0xFFF8F9FB);
  static const _green = Color(0xFF2F7D55);

  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _invitationController = TextEditingController();

  final _emailFocus = FocusNode();
  final _breachService = PasswordBreachService();

  StreamSubscription<User?>? _authSubscription;
  Timer? _verificationTimer;

  User? _user;

  bool _authReady = false;
  bool _hidePassword = true;
  bool _requiresInvitation = false;
  bool _busy = false;
  bool _profileSaved = false;
  bool _checkingVerification = false;
  bool _active = true;

  String? _passwordBreachError;
  String? _status;
  String? _pendingUsername;
  String? _pendingUsernameUid;
  String? _autoSaveBlockedUid;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    _emailFocus.addListener(_onEmailFocusChanged);

    _authSubscription =
        FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) return;

      final accountChanged = _user?.uid != user?.uid;

      setState(() {
        _user = user;
        _authReady = true;

        if (accountChanged) {
          _profileSaved = false;
          _autoSaveBlockedUid = null;
          _status = null;

          if (_pendingUsernameUid != user?.uid) {
            _pendingUsername = null;
            _pendingUsernameUid = null;
          }
        }
      });

      if (user != null) {
        _autoCheckVerification();
      }
    });

    _verificationTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _autoCheckVerification(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;

    if (_active) {
      _autoCheckVerification();
    }
  }

  bool _sameAccount(String uid) {
    return mounted &&
        FirebaseAuth.instance.currentUser?.uid == uid;
  }

  void _onEmailFocusChanged() {
    if (!_emailFocus.hasFocus && mounted) {
      _updateInvitationRequirement();
    }
  }

  bool _updateInvitationRequirement() {
    final email = _emailController.text.trim();

    final requiresInvitation =
        SignUpValidators.email(email) == null &&
        !SignUpValidators.isSchoolEmail(email);

    if (requiresInvitation == _requiresInvitation) return false;

    setState(() {
      _requiresInvitation = requiresInvitation;

      if (!requiresInvitation) {
        _invitationController.clear();
      }
    });

    return true;
  }

  void _onPasswordChanged(String _) {
    if (_passwordBreachError == null) return;

    setState(() {
      _passwordBreachError = null;
    });
  }

  void _setStatus(String message) {
    if (!mounted) return;

    setState(() {
      _status = message;
    });
  }

  String _errorMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'Account exists. Use Log in below.';
        case 'invalid-email':
          return 'Enter a valid email address.';
        case 'weak-password':
          return 'Choose a stronger password.';
        case 'operation-not-allowed':
          return 'Enable Email/Password in Firebase Authentication.';
        case 'network-request-failed':
          return 'Check your connection and try again.';
        case 'too-many-requests':
          return 'Too many attempts. Try again shortly.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'user-token-expired':
        case 'invalid-user-token':
          return 'Session expired. Please log in again.';
        default:
          return 'Authentication failed (${error.code}).';
      }
    }

    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'Profile request refused. Check the Firestore rules.';
        case 'unavailable':
          return 'Database unavailable. Try again.';
        default:
          return 'Database error (${error.code}).';
      }
    }

    return 'Something went wrong. Try again.';
  }

  String? _usernameFor(User user) {
    if (_pendingUsernameUid == user.uid) {
      final pending = _pendingUsername?.trim() ?? '';
      if (pending.isNotEmpty) return pending;
    }

    final name = user.displayName?.trim() ?? '';
    return name.isEmpty ? null : name;
  }

  void _openLogin() {
    if (_busy || _checkingVerification) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
    );
  }

  void _openHome() {
    if (!_profileSaved ||
        FirebaseAuth.instance.currentUser?.uid != _user?.uid) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const HomeScreen(),
      ),
      (_) => false,
    );
  }

  Future<void> _submit() async {
    if (_busy || _user != null) return;

    setState(() {
      _busy = true;
      _status = null;
      _passwordBreachError = null;
    });

    try {
      final layoutChanged = _updateInvitationRequirement();
      FocusScope.of(context).unfocus();

      if (layoutChanged) {
        await WidgetsBinding.instance.endOfFrame;
      }

      if (!mounted) return;
      if (!(_formKey.currentState?.validate() ?? false)) return;

      if (_requiresInvitation) {
        _setStatus(
          'Invitations are not available yet. Use a SETU email.',
        );
        return;
      }

      final username = _usernameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      final breached = await _breachService.isBreached(password);

      if (!mounted) return;

      if (breached) {
        setState(() {
          _passwordBreachError =
              'This password appeared in a data breach. Choose another.';
        });

        _formKey.currentState?.validate();
        return;
      }

      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (user == null) {
        throw StateError('No user returned after registration.');
      }

      if (!_sameAccount(user.uid)) return;

      setState(() {
        _user = user;
        _profileSaved = false;
        _pendingUsername = username;
        _pendingUsernameUid = user.uid;
      });

      _passwordController.clear();

      // Registration has succeeded. Subsequent failures must not
      // tell the user to create the account again.
      var nameRemembered = true;

      try {
        await user.updateDisplayName(username);
      } catch (_) {
        nameRemembered = false;
      }

      if (!_sameAccount(user.uid)) return;

      try {
        await user.sendEmailVerification();

        if (!_sameAccount(user.uid)) return;

        setState(() {
          _status = nameRemembered
              ? null
              : 'Email sent. Keep this page open to finish signup.';
        });
      } catch (error) {
        if (!_sameAccount(user.uid)) return;

        _setStatus(
          'Email not sent. Tap Resend. ${_errorMessage(error)}',
        );
      }
    } catch (error) {
      _setStatus(_errorMessage(error));
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _resendVerification() async {
    if (_busy || _checkingVerification) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _setStatus('Please log in again.');
      return;
    }

    setState(() {
      _busy = true;
      _status = null;
    });

    try {
      await user.reload();

      if (!_sameAccount(user.uid)) return;

      final refreshed = FirebaseAuth.instance.currentUser!;

      setState(() {
        _user = refreshed;
      });

      if (refreshed.emailVerified) {
        _setStatus('Already verified. Tap “I’ve verified my email”.');
        return;
      }

      await refreshed.sendEmailVerification();

      if (!_sameAccount(user.uid)) return;

      _setStatus('Email sent. Check your inbox.');
    } catch (error) {
      if (_sameAccount(user.uid)) {
        _setStatus(_errorMessage(error));
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _autoCheckVerification() async {
    if (!mounted ||
        !_active ||
        !_authReady ||
        _profileSaved ||
        _busy ||
        _checkingVerification ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _autoSaveBlockedUid == user.uid) return;

    _checkingVerification = true;

    try {
      await user.reload();

      if (!_sameAccount(user.uid)) return;

      final refreshed = FirebaseAuth.instance.currentUser!;

      if (!refreshed.emailVerified) return;

      await _continueAfterVerification(automatic: true);

      if (_sameAccount(user.uid) && !_profileSaved) {
        _autoSaveBlockedUid = user.uid;
      }
    } catch (_) {
      // A failed refresh retries quietly on a later tick.
    } finally {
      _checkingVerification = false;
    }
  }

  Future<void> _continueAfterVerification({
    bool automatic = false,
  }) async {
    if (_busy || _profileSaved) return;
    if (!automatic && _checkingVerification) return;

    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      _setStatus('Please log in again.');
      return;
    }

    final uid = currentUser.uid;

    setState(() {
      _busy = true;
      _status = null;
    });

    try {
      await currentUser.reload();

      if (!_sameAccount(uid)) return;

      final user = FirebaseAuth.instance.currentUser!;

      setState(() {
        _user = user;
      });

      if (!user.emailVerified) {
        _setStatus('Not verified yet. Open the link in your email.');
        return;
      }

      await user.getIdToken(true);

      if (!_sameAccount(uid)) return;

      final email = user.email;
      if (email == null) {
        throw StateError('No email address.');
      }

      final username = _usernameFor(user);
      final reference =
          FirebaseFirestore.instance.collection('users').doc(uid);

      await FirebaseFirestore.instance.runTransaction<void>(
        (transaction) async {
          if (FirebaseAuth.instance.currentUser?.uid != uid) {
            throw StateError('Session changed.');
          }

          final existing = await transaction.get(reference);

          if (existing.exists) {
            final name = existing.data()?['username'];

            if (name is String && name.trim().isNotEmpty) {
              return;
            }

            throw StateError('Existing profile is incomplete.');
          }

          if (username == null ||
              username.isEmpty ||
              username.length > 50) {
            throw const FormatException('missing-username');
          }

          transaction.set(reference, {
            'username': username,
            'email': email,
            'createdAt': FieldValue.serverTimestamp(),
          });
        },
      );

      if (!_sameAccount(uid)) return;

      setState(() {
        _profileSaved = true;
        _status = null;
      });
    } on FormatException {
      if (_sameAccount(uid)) {
        _setStatus(
          'Your signup username is missing. '
          'Your account is safe, but profile recovery is needed.',
        );
      }
    } catch (error) {
      if (_sameAccount(uid)) {
        _setStatus(_errorMessage(error));
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    if (_busy || _checkingVerification) return;

    setState(() {
      _busy = true;
    });

    try {
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      _usernameController.clear();
      _emailController.clear();
      _passwordController.clear();
      _invitationController.clear();

      setState(() {
        _user = null;
        _profileSaved = false;
        _pendingUsername = null;
        _pendingUsernameUid = null;
        _autoSaveBlockedUid = null;
        _requiresInvitation = false;
        _passwordBreachError = null;
        _status = null;
      });
    } catch (error) {
      _setStatus(_errorMessage(error));
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _muted, fontSize: 13),
      filled: true,
      fillColor: _fieldBackground,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: _ink),
      ),
      errorMaxLines: 3,
    );
  }

  Widget _fieldGroup(String label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _ink,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        field,
      ],
    );
  }

  Widget _primaryButton(String label, VoidCallback onPressed) {
    return SizedBox(
      height: 48,
      child: FilledButton(
        onPressed: _busy ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: _ink,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
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
            : Text(label),
      ),
    );
  }

  Widget _statusNotice() {
    if (_status == null) return const SizedBox.shrink();

    return Padding(
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
    );
  }

  Widget _registrationForm() {
    return AutofillGroup(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Sign up',
              style: TextStyle(
                color: _ink,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Use your SETU email.',
              style: TextStyle(color: _muted, fontSize: 12),
            ),
            const SizedBox(height: 26),
            _fieldGroup(
              'Username',
              TextFormField(
                controller: _usernameController,
                readOnly: _busy,
                decoration: _decoration('Choose a username'),
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newUsername],
                autocorrect: false,
                validator: (value) {
                  final name = value?.trim() ?? '';
                  final error = SignUpValidators.username(name);

                  if (error != null) return error;
                  if (name.isEmpty) return 'Enter a username.';
                  if (name.length > 50) {
                    return 'Use no more than 50 characters.';
                  }

                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            _fieldGroup(
              'Email',
              TextFormField(
                controller: _emailController,
                focusNode: _emailFocus,
                readOnly: _busy,
                decoration: _decoration('SETU email'),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                autocorrect: false,
                enableSuggestions: false,
                validator: (value) {
                  return SignUpValidators.email(value?.trim());
                },
              ),
            ),
            const SizedBox(height: 16),
            _fieldGroup(
              'Password',
              TextFormField(
                controller: _passwordController,
                readOnly: _busy,
                obscureText: _hidePassword,
                autocorrect: false,
                enableSuggestions: false,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: _requiresInvitation
                    ? TextInputAction.next
                    : TextInputAction.done,
                onChanged: _onPasswordChanged,
                onFieldSubmitted: (_) {
                  if (!_requiresInvitation) _submit();
                },
                decoration: _decoration('Password').copyWith(
                  helperText: 'At least 8 characters.',
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
                      size: 19,
                    ),
                  ),
                ),
                validator: (value) {
                  return SignUpValidators.password(value) ??
                      _passwordBreachError;
                },
              ),
            ),
            if (_requiresInvitation) ...[
              const SizedBox(height: 16),
              _fieldGroup(
                'Invitation code',
                TextFormField(
                  controller: _invitationController,
                  readOnly: _busy,
                  decoration: _decoration('Invitation code').copyWith(
                    helperText: 'Invitations are not available yet.',
                    helperMaxLines: 2,
                  ),
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  validator: (value) {
                    return SignUpValidators.invitationCode(
                      value,
                      required: _requiresInvitation,
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 24),
            _primaryButton('Create account', _submit),
            _statusNotice(),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'Have an account?',
                  style: TextStyle(color: _muted, fontSize: 12),
                ),
                TextButton(
                  onPressed: _busy ? null : _openLogin,
                  style: TextButton.styleFrom(foregroundColor: _ink),
                  child: const Text('Log in'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _verifyView() {
    final working = _busy || _checkingVerification;

    return Padding(
      padding: const EdgeInsets.only(top: 36, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFF1FCF6),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFDDF7E9),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFDDF7E9),
                  ),
                  child: const Icon(
                    Icons.mark_email_unread_rounded,
                    size: 23,
                    color: Color(0xFF388761),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Please verify your email',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _ink,
              fontSize: 25,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Open the verification link sent to',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _muted,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _user?.email ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _ink,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Can’t find it? Check your spam folder.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _muted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: working ? null : _resendVerification,
                  style: FilledButton.styleFrom(
                    backgroundColor: _ink,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shadowColor: const Color(0x331B2432),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Resend verification email'),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: working
                  ? null
                  : () {
                      _autoSaveBlockedUid = null;
                      _continueAfterVerification();
                    },
              style: TextButton.styleFrom(
                foregroundColor: _ink,
                textStyle: const TextStyle(fontSize: 12),
              ),
              child: const Text('I’ve verified my email'),
            ),
          ),
          if (_busy) ...[
            const SizedBox(height: 8),
            const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _ink,
                  semanticsLabel: 'Please wait',
                ),
              ),
            ),
          ],
          _statusNotice(),
          const SizedBox(height: 20),
          Center(
            child: TextButton(
              onPressed: working ? null : _signOut,
              style: TextButton.styleFrom(
                foregroundColor: _muted,
                textStyle: const TextStyle(fontSize: 12),
              ),
              child: const Text('Sign out'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _doneView() {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 72, bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                    begin: reduceMotion ? 1.0 : 0.8,
                    end: 1.0,
                  ),
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 450),
                  curve: Curves.easeOutBack,
                  builder: (context, scale, child) {
                    return Opacity(
                      opacity: scale.clamp(0.0, 1.0).toDouble(),
                      child: Transform.scale(
                        scale: scale,
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _green, width: 2.5),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 44,
                      color: _green,
                      semanticLabel: 'Verified',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Email Verified',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _ink,
                  fontSize: 26,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'You’re all set.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _muted,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: IconButton(
            tooltip: 'Continue to home',
            onPressed: _openHome,
            icon: const Icon(
              Icons.close_rounded,
              color: _muted,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  Widget _currentView() {
    if (_user == null) return _registrationForm();
    if (_profileSaved) return _doneView();
    return _verifyView();
  }

  @override
  void dispose() {
    _verificationTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();

    _emailFocus.removeListener(_onEmailFocusChanged);
    _emailFocus.dispose();

    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _invitationController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: !_authReady
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: DefaultTextStyle.merge(
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 13,
                      ),
                      child: _currentView(),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}