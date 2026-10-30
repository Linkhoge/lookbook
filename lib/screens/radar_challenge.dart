/*
 * Campus discovery WIP placeholder.
 * Author: Ariel Fajimiyo
 */

import 'package:flutter/material.dart';

class RadarChallenge extends StatelessWidget {
  const RadarChallenge({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
      children: [
        const Text(
          'Campus discovery',
          style: TextStyle(
            color: Color(0xFF1B2432),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Work in progress',
          style: TextStyle(
            color: Color(0xFF7D818B),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          height: 220,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E3E7)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'Discovery area',
            style: TextStyle(
              color: Color(0xFF7D818B),
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Find photo spots around campus.',
          style: TextStyle(
            color: Color(0xFF1B2432),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Location and photo capture are not connected yet.',
          style: TextStyle(
            color: Color(0xFF7D818B),
            fontSize: 12,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}