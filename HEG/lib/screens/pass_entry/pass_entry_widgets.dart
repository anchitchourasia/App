import 'package:flutter/material.dart';

class PassEntryStyles {
  static const bg1 = Color(0xFF0B1E3A);
  static const bg2 = Color(0xFF0EA5A4);
  static const panelBg = Colors.white;
  static const panelBorder = Color(0xFFD9E2EC);
  static const textPrimary = Color(0xFF102A43);
  static const textSecondary = Color(0xFF627D98);
}

Widget sectionCard(String title, Widget child) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: PassEntryStyles.panelBorder),
    ),
    child: Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [PassEntryStyles.bg1, Color(0xFF163B6B)],
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.circle, size: 10, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: child,
        ),
      ],
    ),
  );
}

Widget fieldLabel(String label) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1E3A6E),
        ),
      ),
    );

Widget readOnlyField(String label, String value) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        fieldLabel(label),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: PassEntryStyles.panelBorder),
          ),
          child: Text(
            value.isEmpty ? '-' : value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );

Widget messageBox(String text, {required bool success}) => Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: success ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: success ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
        ),
      ),
      child: Row(
        children: [
          Icon(
            success ? Icons.check_circle : Icons.error_outline,
            color: success ? const Color(0xFF15803D) : const Color(0xFFDC2626),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );