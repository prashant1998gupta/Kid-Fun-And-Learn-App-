part of 'learning_adventure_game.dart';

enum LearningAdventureType {
  soundSafari,
  numberGarden,
  storyTrain,
  letterBakery,
  cleanRoom,
  mathMarket,
  wordWizard,
  sentenceTrain,
  clockAdventure,
  natureDetective,
  shapeBuilder,
  fractionCafe,
  multiplicationKingdom,
  grammarDetective,
  codeRobot,
  scienceLab,
  mapQuest,
  ecoCity,
  spaceMission,
  businessBazaar,
  mysteryScience,
  newsDetective,
  algorithmQuest,
}

extension LearningAdventureTypeData on LearningAdventureType {
  String get id => switch (this) {
        LearningAdventureType.soundSafari => 'sound-safari',
        LearningAdventureType.numberGarden => 'number-garden',
        LearningAdventureType.storyTrain => 'story-train',
        LearningAdventureType.letterBakery => 'letter-bakery',
        LearningAdventureType.cleanRoom => 'clean-room-helper',
        LearningAdventureType.mathMarket => 'math-market',
        LearningAdventureType.wordWizard => 'word-wizard-workshop',
        LearningAdventureType.sentenceTrain => 'sentence-train',
        LearningAdventureType.clockAdventure => 'clock-adventure',
        LearningAdventureType.natureDetective => 'nature-detective',
        LearningAdventureType.shapeBuilder => 'shape-builder',
        LearningAdventureType.fractionCafe => 'fraction-cafe',
        LearningAdventureType.multiplicationKingdom => 'multiplication-kingdom',
        LearningAdventureType.grammarDetective => 'grammar-detective',
        LearningAdventureType.codeRobot => 'code-the-robot',
        LearningAdventureType.scienceLab => 'science-machine-lab',
        LearningAdventureType.mapQuest => 'map-quest',
        LearningAdventureType.ecoCity => 'eco-city-builder',
        LearningAdventureType.spaceMission => 'space-mission-control',
        LearningAdventureType.businessBazaar => 'business-bazaar',
        LearningAdventureType.mysteryScience => 'mystery-science-lab',
        LearningAdventureType.newsDetective => 'news-detective',
        LearningAdventureType.algorithmQuest => 'algorithm-quest',
      };

  String get title => switch (this) {
        LearningAdventureType.soundSafari => 'Sound Safari',
        LearningAdventureType.numberGarden => 'Number Garden',
        LearningAdventureType.storyTrain => 'Story Train',
        LearningAdventureType.letterBakery => 'Letter Bakery',
        LearningAdventureType.cleanRoom => 'Clean Room Helper',
        LearningAdventureType.mathMarket => 'Math Market',
        LearningAdventureType.wordWizard => 'Word Wizard Workshop',
        LearningAdventureType.sentenceTrain => 'Sentence Train',
        LearningAdventureType.clockAdventure => 'Clock Adventure',
        LearningAdventureType.natureDetective => 'Nature Detective',
        LearningAdventureType.shapeBuilder => 'Shape Builder',
        LearningAdventureType.fractionCafe => 'Pizza Fraction Café',
        LearningAdventureType.multiplicationKingdom => 'Multiplication Kingdom',
        LearningAdventureType.grammarDetective => 'Grammar Detective',
        LearningAdventureType.codeRobot => 'Code the Robot',
        LearningAdventureType.scienceLab => 'Science Machine Lab',
        LearningAdventureType.mapQuest => 'Map Quest',
        LearningAdventureType.ecoCity => 'Eco City Builder',
        LearningAdventureType.spaceMission => 'Space Mission Control',
        LearningAdventureType.businessBazaar => 'Business Bazaar',
        LearningAdventureType.mysteryScience => 'Mystery Science Lab',
        LearningAdventureType.newsDetective => 'News Detective',
        LearningAdventureType.algorithmQuest => 'Algorithm Quest',
      };

  String get icon => switch (this) {
        LearningAdventureType.soundSafari => '🦁',
        LearningAdventureType.numberGarden => '🌻',
        LearningAdventureType.storyTrain => '🚂',
        LearningAdventureType.letterBakery => '🥐',
        LearningAdventureType.cleanRoom => '🧹',
        LearningAdventureType.mathMarket => '🛒',
        LearningAdventureType.wordWizard => '🧙',
        LearningAdventureType.sentenceTrain => '🚂',
        LearningAdventureType.clockAdventure => '⏰',
        LearningAdventureType.natureDetective => '🔎',
        LearningAdventureType.shapeBuilder => '🏗️',
        LearningAdventureType.fractionCafe => '🍕',
        LearningAdventureType.multiplicationKingdom => '🏰',
        LearningAdventureType.grammarDetective => '🕵️',
        LearningAdventureType.codeRobot => '🤖',
        LearningAdventureType.scienceLab => '🧪',
        LearningAdventureType.mapQuest => '🗺️',
        LearningAdventureType.ecoCity => '🏙️',
        LearningAdventureType.spaceMission => '🚀',
        LearningAdventureType.businessBazaar => '💼',
        LearningAdventureType.mysteryScience => '🔬',
        LearningAdventureType.newsDetective => '📰',
        LearningAdventureType.algorithmQuest => '🧠',
      };

  String get mascot => switch (this) {
        LearningAdventureType.soundSafari => '🦉',
        LearningAdventureType.numberGarden => '🐝',
        LearningAdventureType.storyTrain => '🐼',
        LearningAdventureType.letterBakery => '🧑‍🍳',
        LearningAdventureType.cleanRoom => '🐧',
        LearningAdventureType.mathMarket => '🦊',
        LearningAdventureType.wordWizard => '🦉',
        LearningAdventureType.sentenceTrain => '🐼',
        LearningAdventureType.clockAdventure => '🐰',
        LearningAdventureType.natureDetective => '🐻',
        LearningAdventureType.shapeBuilder => '🦖',
        LearningAdventureType.fractionCafe => '🧑‍🍳',
        LearningAdventureType.multiplicationKingdom => '🐉',
        LearningAdventureType.grammarDetective => '🦉',
        LearningAdventureType.codeRobot => '🤖',
        LearningAdventureType.scienceLab => '🧑‍🔬',
        LearningAdventureType.mapQuest => '🦜',
        LearningAdventureType.ecoCity => '🦊',
        LearningAdventureType.spaceMission => '🐱‍🚀',
        LearningAdventureType.businessBazaar => '🦁',
        LearningAdventureType.mysteryScience => '🧑‍🔬',
        LearningAdventureType.newsDetective => '🦉',
        LearningAdventureType.algorithmQuest => '🤖',
      };

  String get achievementId => switch (this) {
        LearningAdventureType.soundSafari => 'sound_scout',
        LearningAdventureType.numberGarden => 'number_gardener',
        LearningAdventureType.storyTrain => 'story_conductor',
        LearningAdventureType.letterBakery => 'letter_baker',
        LearningAdventureType.cleanRoom => 'tidy_helper',
        LearningAdventureType.mathMarket => 'market_master',
        LearningAdventureType.wordWizard => 'word_wizard',
        LearningAdventureType.sentenceTrain => 'sentence_conductor',
        LearningAdventureType.clockAdventure => 'time_keeper',
        LearningAdventureType.natureDetective => 'nature_detective',
        LearningAdventureType.shapeBuilder => 'shape_architect',
        LearningAdventureType.fractionCafe => 'fraction_chef',
        LearningAdventureType.multiplicationKingdom => 'times_table_knight',
        LearningAdventureType.grammarDetective => 'grammar_sleuth',
        LearningAdventureType.codeRobot => 'robot_coder',
        LearningAdventureType.scienceLab => 'junior_scientist',
        LearningAdventureType.mapQuest => 'map_explorer',
        LearningAdventureType.ecoCity => 'eco_mayor',
        LearningAdventureType.spaceMission => 'mission_commander',
        LearningAdventureType.businessBazaar => 'business_brain',
        LearningAdventureType.mysteryScience => 'evidence_expert',
        LearningAdventureType.newsDetective => 'truth_tracker',
        LearningAdventureType.algorithmQuest => 'algorithm_ace',
      };

  WorldTheme get worldTheme => switch (this) {
        LearningAdventureType.soundSafari => WorldTheme.jungle,
        LearningAdventureType.numberGarden => WorldTheme.sunrise,
        LearningAdventureType.storyTrain => WorldTheme.ocean,
        LearningAdventureType.letterBakery => WorldTheme.candy,
        LearningAdventureType.cleanRoom => WorldTheme.aurora,
        LearningAdventureType.mathMarket => WorldTheme.sunrise,
        LearningAdventureType.wordWizard => WorldTheme.aurora,
        LearningAdventureType.sentenceTrain => WorldTheme.ocean,
        LearningAdventureType.clockAdventure => WorldTheme.candy,
        LearningAdventureType.natureDetective => WorldTheme.jungle,
        LearningAdventureType.shapeBuilder => WorldTheme.space,
        LearningAdventureType.fractionCafe => WorldTheme.candy,
        LearningAdventureType.multiplicationKingdom => WorldTheme.aurora,
        LearningAdventureType.grammarDetective => WorldTheme.night,
        LearningAdventureType.codeRobot => WorldTheme.space,
        LearningAdventureType.scienceLab => WorldTheme.ocean,
        LearningAdventureType.mapQuest => WorldTheme.jungle,
        LearningAdventureType.ecoCity => WorldTheme.jungle,
        LearningAdventureType.spaceMission => WorldTheme.space,
        LearningAdventureType.businessBazaar => WorldTheme.sunrise,
        LearningAdventureType.mysteryScience => WorldTheme.ocean,
        LearningAdventureType.newsDetective => WorldTheme.night,
        LearningAdventureType.algorithmQuest => WorldTheme.aurora,
      };

  Color get accent => switch (this) {
        LearningAdventureType.soundSafari => const Color(0xFF00A878),
        LearningAdventureType.numberGarden => const Color(0xFFFFB000),
        LearningAdventureType.storyTrain => const Color(0xFF3D7EFF),
        LearningAdventureType.letterBakery => const Color(0xFFE84393),
        LearningAdventureType.cleanRoom => const Color(0xFF7C5CE7),
        LearningAdventureType.mathMarket => const Color(0xFFFF8F00),
        LearningAdventureType.wordWizard => const Color(0xFF6C5CE7),
        LearningAdventureType.sentenceTrain => const Color(0xFF1976D2),
        LearningAdventureType.clockAdventure => const Color(0xFFE91E63),
        LearningAdventureType.natureDetective => const Color(0xFF00897B),
        LearningAdventureType.shapeBuilder => const Color(0xFF5E35B1),
        LearningAdventureType.fractionCafe => const Color(0xFFFF7043),
        LearningAdventureType.multiplicationKingdom => const Color(0xFF7B1FA2),
        LearningAdventureType.grammarDetective => const Color(0xFF455A64),
        LearningAdventureType.codeRobot => const Color(0xFF1565C0),
        LearningAdventureType.scienceLab => const Color(0xFF00838F),
        LearningAdventureType.mapQuest => const Color(0xFF2E7D32),
        LearningAdventureType.ecoCity => const Color(0xFF00A86B),
        LearningAdventureType.spaceMission => const Color(0xFF3949AB),
        LearningAdventureType.businessBazaar => const Color(0xFFF57C00),
        LearningAdventureType.mysteryScience => const Color(0xFF00838F),
        LearningAdventureType.newsDetective => const Color(0xFF37474F),
        LearningAdventureType.algorithmQuest => const Color(0xFF6A1B9A),
      };

  String get tutorial => switch (this) {
        LearningAdventureType.soundSafari =>
          'Listen to the sound clue, then tap the matching picture.',
        LearningAdventureType.numberGarden =>
          'Count the garden objects, then tap the right number.',
        LearningAdventureType.storyTrain =>
          'Look at the story carriages, then choose what happens next.',
        LearningAdventureType.letterBakery =>
          'Look at the picture, then tap the letter its word starts with.',
        LearningAdventureType.cleanRoom =>
          'Look at the object, then tap the place where it belongs.',
        LearningAdventureType.mathMarket =>
          'Count the coins and prices, then tap the correct answer.',
        LearningAdventureType.wordWizard =>
          'Look at the picture and use the right letter or word.',
        LearningAdventureType.sentenceTrain =>
          'Read the sentence carriages and choose the word that completes them.',
        LearningAdventureType.clockAdventure =>
          'Look at the clock and choose the matching time or daily activity.',
        LearningAdventureType.natureDetective =>
          'Read or listen to the nature clue and choose the best answer.',
        LearningAdventureType.shapeBuilder =>
          'Study the shapes, sides, and patterns, then choose the right piece.',
        LearningAdventureType.fractionCafe =>
          'Look at the pizza parts, then choose the matching fraction.',
        LearningAdventureType.multiplicationKingdom =>
          'Count equal groups and solve the multiplication or division mission.',
        LearningAdventureType.grammarDetective =>
          'Inspect the sentence clue and choose the correct grammar evidence.',
        LearningAdventureType.codeRobot =>
          'Read the robot commands, predict the result, and fix silly bugs.',
        LearningAdventureType.scienceLab =>
          'Study the experiment clue and choose the scientific explanation.',
        LearningAdventureType.mapQuest =>
          'Use directions, coordinates, distance, and map symbols to find the answer.',
        LearningAdventureType.ecoCity =>
          'Choose sustainable systems and balance the needs of a growing city.',
        LearningAdventureType.spaceMission =>
          'Use decimals, fractions, angles, and measurement to repair the spacecraft.',
        LearningAdventureType.businessBazaar =>
          'Manage budgets, discounts, revenue, cost, and simple profit missions.',
        LearningAdventureType.mysteryScience =>
          'Choose fair tests, variables, evidence, and conclusions for each mystery.',
        LearningAdventureType.newsDetective =>
          'Separate facts, opinions, strong evidence, and unreliable claims.',
        LearningAdventureType.algorithmQuest =>
          'Predict loops and conditions, trace algorithms, and debug efficient solutions.',
      };
}
