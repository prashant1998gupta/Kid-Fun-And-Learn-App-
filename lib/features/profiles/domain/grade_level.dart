/// The eight learner bands KidVerse supports, from pre-school to Grade 5.
/// [difficultyTier] drives adaptive content selection and question generation.
enum GradeLevel {
  lkg('LKG', 3, 0),
  ukg('UKG', 4, 1),
  kg('KG', 5, 2),
  grade1('Grade 1', 6, 3),
  grade2('Grade 2', 7, 4),
  grade3('Grade 3', 8, 5),
  grade4('Grade 4', 9, 6),
  grade5('Grade 5', 10, 7);

  const GradeLevel(this.label, this.typicalAge, this.difficultyTier);

  final String label;
  final int typicalAge;
  final int difficultyTier;

  static GradeLevel fromId(String id) =>
      GradeLevel.values.firstWhere((g) => g.name == id, orElse: () => lkg);

  /// Suggest a starting grade from a child's age (used in onboarding).
  static GradeLevel suggestForAge(int age) {
    return GradeLevel.values.firstWhere(
      (g) => g.typicalAge >= age,
      orElse: () => grade5,
    );
  }

  bool get isPreSchool => difficultyTier <= 2;
}
