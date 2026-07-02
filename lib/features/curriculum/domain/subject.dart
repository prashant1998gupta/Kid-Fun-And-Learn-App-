import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// A learning subject. Each owns a signature color and icon so a
/// pre-reader navigates by look, not label.
enum Subject {
  math('Math', Icons.calculate_rounded, AppColors.subjectMath),
  english('English', Icons.menu_book_rounded, AppColors.subjectEnglish),
  evs('World Around Us', Icons.public_rounded, AppColors.subjectEvs),
  science('Science', Icons.science_rounded, AppColors.subjectScience),
  art('Art & Craft', Icons.palette_rounded, AppColors.subjectArt),
  logic('Logic & Puzzles', Icons.extension_rounded, AppColors.subjectLogic),
  rhymes('Rhymes & Music', Icons.music_note_rounded, AppColors.subjectRhymes);

  const Subject(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;

  static Subject fromId(String id) =>
      Subject.values.firstWhere((s) => s.name == id, orElse: () => math);
}
