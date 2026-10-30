/*
 * Account profile and interactive Student demo profile.
 * Author: Ariel Fajimiyo
 */

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/demo_social_state.dart';

class ProfileData {
  const ProfileData({
    required this.name,
    required this.handle,
    required this.bio,
    required this.campus,
    required this.joined,
    this.email,
    this.emailVerified = false,
    this.isDemo = false,
    this.fits = 0,
  });

  final String name;
  final String handle;
  final String bio;
  final String campus;
  final String joined;
  final String? email;
  final bool emailVerified;
  final bool isDemo;
  final int fits;

  static const demoStudent = ProfileData(
    name: 'Student',
    handle: '@student',
    bio: 'Lecture fits and campus walks.',
    campus: 'Campus',
    joined: 'Demo account',
    isDemo: true,
    fits: 1,
  );
}

class ProfileBody extends StatelessWidget {
  const ProfileBody({
    super.key,
    required this.data,
    this.onSignOut,
    this.signingOut = false,
  });

  final ProfileData data;
  final VoidCallback? onSignOut;
  final bool signingOut;

  static const _ink = Color(0xFF1B2432);
  static const _muted = Color(0xFF7D818B);
  static const _line = Color(0xFFE2E3E7);

  void _message(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  void _menuAction(BuildContext context, String action) {
    final social = DemoSocialState.instance;

    switch (action) {
      case 'hide':
        social.hidePosts();
        _message(context, 'Student’s posts hidden for this session.');
        break;
      case 'show':
        social.showPosts();
        _message(context, 'Student’s posts shown.');
        break;
      case 'block':
        social.toggleBlock();
        _message(
          context,
          social.blocked
              ? 'Student blocked for this session.'
              : 'Student unblocked.',
        );
        break;
    }
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: _ink, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final social = DemoSocialState.instance;
    final name = data.name.trim();
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();

    return ListenableBuilder(
      listenable: social,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            Row(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF1F7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 27,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.name,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data.handle,
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (data.isDemo)
                  PopupMenuButton<String>(
                    tooltip: 'Profile options',
                    onSelected: (action) => _menuAction(context, action),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: social.postsHidden ? 'show' : 'hide',
                        child: Text(
                          social.postsHidden ? 'Show posts' : 'Hide posts',
                        ),
                      ),
                      PopupMenuItem(
                        value: 'block',
                        child: Text(
                          social.blocked ? 'Unblock Student' : 'Block Student',
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              data.bio,
              style: const TextStyle(
                color: _ink,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            if (data.isDemo) ...[
              const SizedBox(height: 18),
              SizedBox(
                height: 44,
                child: FilledButton.icon(
                  onPressed: social.blocked
                      ? null
                      : () {
                          social.toggleRequest();
                          _message(
                            context,
                            social.requestPending
                                ? 'Demo friend request sent.'
                                : 'Demo friend request cancelled.',
                          );
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: _ink,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  icon: Icon(
                    social.requestPending
                        ? Icons.schedule_outlined
                        : Icons.person_add_alt_1_outlined,
                    size: 18,
                  ),
                  label: Text(
                    social.blocked
                        ? 'Blocked'
                        : social.requestPending
                            ? 'Request sent · Cancel'
                            : 'Add friend',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Demo profile · requests are local to this session.',
                style: TextStyle(color: _muted, fontSize: 11),
              ),
            ],
            const SizedBox(height: 24),
            const Divider(color: _line, height: 1),
            _detail('Campus', data.campus),
            _detail('Joined', data.joined),
            _detail('Fits', '${data.fits}'),
            if (data.emailVerified)
              _detail('Account', 'Email verified'),
            if (data.email != null && data.email!.isNotEmpty)
              _detail('Email', data.email!),
            const Divider(color: _line, height: 1),
            if (data.isDemo) ...[
              const SizedBox(height: 22),
              const Text(
                'Posts',
                style: TextStyle(
                  color: _ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 140,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F2F4),
                  border: Border.all(color: _line),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  social.blocked
                      ? 'This account is blocked.'
                      : social.postsHidden
                          ? 'Posts hidden.'
                          : 'Demo outfit photo',
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
              ),
            ],
            if (onSignOut != null) ...[
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: signingOut ? null : onSignOut,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _ink,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: Text(signingOut ? 'Signing out…' : 'Sign out'),
              ),
            ],
          ],
        );
      },
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.data});

  final ProfileData data;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAF8),
        foregroundColor: const Color(0xFF1B2432),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          data.handle,
          style: const TextStyle(fontSize: 15),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ProfileBody(data: data),
          ),
        ),
      ),
    );
  }
}

class MyProfileTab extends StatefulWidget {
  const MyProfileTab({
    super.key,
    required this.onSignOut,
    this.signingOut = false,
  });

  final VoidCallback onSignOut;
  final bool signingOut;

  @override
  State<MyProfileTab> createState() => _MyProfileTabState();
}

class _MyProfileTabState extends State<MyProfileTab> {
  late final Future<ProfileData> _future = _load();

  Future<ProfileData> _load() async {
    final user = FirebaseAuth.instance.currentUser;
    var name = user?.displayName?.trim() ?? '';
    DateTime? joined = user?.metadata.creationTime;

    if (user != null) {
      final document = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = document.data();
      final storedName = data?['username'];
      final createdAt = data?['createdAt'];

      if (storedName is String && storedName.trim().isNotEmpty) {
        name = storedName.trim();
      }

      if (createdAt is Timestamp) joined = createdAt.toDate();
    }

    final email = user?.email ?? '';
    final domain = email.split('@').last.toLowerCase();

    return ProfileData(
      name: name.isEmpty ? 'Your profile' : name,
      handle: name.isEmpty ? '' : '@$name',
      bio: 'Welcome to LookBook.',
      campus: domain == 'setu.ie' || domain.endsWith('.setu.ie')
          ? 'SETU'
          : 'Campus',
      joined: joined == null
          ? 'New member'
          : '${joined.day}/${joined.month}/${joined.year}',
      email: email,
      emailVerified: user?.emailVerified ?? false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProfileData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Could not load your profile.'),
                TextButton(
                  onPressed: widget.signingOut ? null : widget.onSignOut,
                  child: const Text('Sign out'),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data;
        if (data == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return ProfileBody(
          data: data,
          onSignOut: widget.onSignOut,
          signingOut: widget.signingOut,
        );
      },
    );
  }
}