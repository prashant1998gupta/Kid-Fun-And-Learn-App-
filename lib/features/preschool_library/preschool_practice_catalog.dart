import '../profiles/domain/grade_level.dart';
import 'preschool_picture_word_data.dart';

enum PreschoolPracticeKind { trace, vocabulary }

enum PreschoolPracticeCategory {
  uppercase(
    'uppercase',
    'Capital A–Z',
    '🔠',
    'Hear each letter, meet its picture, then trace it.',
    PreschoolPracticeKind.trace,
  ),
  lowercase(
    'lowercase',
    'Small a–z',
    '🔡',
    'Learn small letters separately and practise whenever you like.',
    PreschoolPracticeKind.trace,
  ),
  numbers(
    'numbers',
    'Numbers 0–9',
    '🔢',
    'See, hear, count and trace every number.',
    PreschoolPracticeKind.trace,
  ),
  hindiVowels(
    'hindi_vowels',
    'हिंदी स्वर',
    'अ',
    'सुनें, चित्र देखें और स्वर लिखें।',
    PreschoolPracticeKind.trace,
  ),
  hindiConsonants(
    'hindi_consonants',
    'हिंदी व्यंजन',
    'क',
    'सुनें, पहचानें और व्यंजन लिखें।',
    PreschoolPracticeKind.trace,
  ),
  bodyParts('body_parts', 'Body Parts', '👋',
      'Learn the names of your body parts.', PreschoolPracticeKind.vocabulary),
  fruits('fruits', 'Fruits', '🍎', 'Meet colorful fruits and hear their names.',
      PreschoolPracticeKind.vocabulary),
  vegetables(
      'vegetables',
      'Vegetables',
      '🥕',
      'Fill your learning basket with vegetables.',
      PreschoolPracticeKind.vocabulary),
  animals(
      'animals',
      'Animals',
      '🦁',
      'Meet friendly animals and hear their names.',
      PreschoolPracticeKind.vocabulary),
  birds('birds', 'Birds', '🦜', 'Discover birds, feathers and familiar names.',
      PreschoolPracticeKind.vocabulary),
  colors('colors', 'Colors', '🌈', 'Hear and recognise everyday colors.',
      PreschoolPracticeKind.vocabulary),
  shapes('shapes', 'Shapes', '🔷', 'Meet circles, squares and more shapes.',
      PreschoolPracticeKind.vocabulary),
  family('family', 'Family', '👨‍👩‍👧', 'Learn words for family members.',
      PreschoolPracticeKind.vocabulary),
  transport(
      'transport',
      'Transport',
      '🚌',
      'Explore vehicles on land, water and air.',
      PreschoolPracticeKind.vocabulary),
  everyday(
      'everyday',
      'Everyday Things',
      '🏠',
      'Name useful things children see every day.',
      PreschoolPracticeKind.vocabulary),
  farmAnimals('farm_animals', 'Farm Animals', '🐄',
      'Meet animals that live on farms.', PreschoolPracticeKind.vocabulary),
  wildAnimals(
      'wild_animals',
      'Wild Animals',
      '🐅',
      'Discover animals from forests and grasslands.',
      PreschoolPracticeKind.vocabulary),
  seaAnimals('sea_animals', 'Sea Animals', '🐬',
      'Dive in and name ocean animals.', PreschoolPracticeKind.vocabulary),
  insects(
      'insects',
      'Insects & Tiny Creatures',
      '🦋',
      'Meet small creatures in gardens and nature.',
      PreschoolPracticeKind.vocabulary),
  flowersPlants(
      'flowers_plants',
      'Flowers & Plants',
      '🌻',
      'Learn the names of flowers and useful plants.',
      PreschoolPracticeKind.vocabulary),
  nature('nature', 'Nature', '🌳', 'Explore things found in the natural world.',
      PreschoolPracticeKind.vocabulary),
  weatherSeasons(
      'weather_seasons',
      'Weather & Seasons',
      '🌦️',
      'Name weather, seasons and things in the sky.',
      PreschoolPracticeKind.vocabulary),
  clothes('clothes', 'Clothes', '👕', 'Learn the clothes children wear.',
      PreschoolPracticeKind.vocabulary),
  footwearAccessories(
      'footwear_accessories',
      'Shoes & Accessories',
      '👟',
      'Name shoes and things we wear or carry.',
      PreschoolPracticeKind.vocabulary),
  food('food', 'Food', '🍚', 'Meet familiar meals and tasty foods.',
      PreschoolPracticeKind.vocabulary),
  drinks('drinks', 'Drinks', '🥛', 'Name familiar drinks and beverages.',
      PreschoolPracticeKind.vocabulary),
  kitchen('kitchen', 'Kitchen Things', '🍽️',
      'Discover familiar kitchen objects.', PreschoolPracticeKind.vocabulary),
  homeRooms(
      'home_rooms',
      'Home & Rooms',
      '🏡',
      'Explore rooms and things around the home.',
      PreschoolPracticeKind.vocabulary),
  school('school', 'School Things', '🏫', 'Name things children see at school.',
      PreschoolPracticeKind.vocabulary),
  toys('toys', 'Toys & Play', '🧸', 'Meet toys and playful activities.',
      PreschoolPracticeKind.vocabulary),
  sports('sports', 'Sports', '⚽', 'Learn sports, games and their equipment.',
      PreschoolPracticeKind.vocabulary),
  instruments(
      'instruments',
      'Musical Instruments',
      '🎸',
      'Hear the names of instruments that make music.',
      PreschoolPracticeKind.vocabulary),
  helpers('helpers', 'Community Helpers', '👩‍⚕️',
      'Meet people who help our community.', PreschoolPracticeKind.vocabulary),
  places(
      'places',
      'Places Around Us',
      '🏥',
      'Name useful places children may visit.',
      PreschoolPracticeKind.vocabulary),
  actions('actions', 'Action Words', '🏃', 'See and say familiar doing words.',
      PreschoolPracticeKind.vocabulary);

  const PreschoolPracticeCategory(
    this.id,
    this.title,
    this.emoji,
    this.description,
    this.kind,
  );

  final String id;
  final String title;
  final String emoji;
  final String description;
  final PreschoolPracticeKind kind;
}

class PreschoolPracticeItem {
  const PreschoolPracticeItem({
    required this.id,
    required this.category,
    required this.name,
    required this.emoji,
    required this.spoken,
    this.glyph,
    this.example,
    this.voiceLanguage = 'en-US',
  });

  final String id;
  final PreschoolPracticeCategory category;
  final String name;
  final String emoji;
  final String spoken;
  final String? glyph;
  final String? example;
  final String voiceLanguage;

  bool get traceable => glyph != null;
}

class PreschoolPracticeCatalog {
  const PreschoolPracticeCatalog._();

  static bool availableFor(GradeLevel grade) => grade.isPreSchool;

  static List<PreschoolPracticeItem> itemsFor(
          PreschoolPracticeCategory category) =>
      switch (category) {
        PreschoolPracticeCategory.uppercase => _letterItems(category, false),
        PreschoolPracticeCategory.lowercase => _letterItems(category, true),
        PreschoolPracticeCategory.numbers => _numberItems,
        PreschoolPracticeCategory.hindiVowels => _hindiVowels,
        PreschoolPracticeCategory.hindiConsonants => _hindiConsonants,
        _ => _vocabularyItems[category] ?? const [],
      };

  static final Map<PreschoolPracticeCategory, List<PreschoolPracticeItem>>
      _vocabularyItems = {
    for (final category in PreschoolPracticeCategory.values)
      if (category.kind == PreschoolPracticeKind.vocabulary)
        category: List.unmodifiable(
          _vocabulary(
            category,
            preschoolPictureWords[category.id] ?? const [],
          ),
        ),
  };

  static PreschoolPracticeItem? byId(String id) {
    for (final category in PreschoolPracticeCategory.values) {
      for (final item in itemsFor(category)) {
        if (item.id == id) return item;
      }
    }
    return null;
  }

  static List<PreschoolPracticeItem> _letterItems(
      PreschoolPracticeCategory category, bool lowercase) {
    return [
      for (final entry in _alphabet)
        PreschoolPracticeItem(
          id: '${category.id}_${entry.$1.toLowerCase()}',
          category: category,
          name: lowercase ? entry.$1.toLowerCase() : entry.$1,
          glyph: lowercase ? entry.$1.toLowerCase() : entry.$1,
          emoji: entry.$3,
          example: entry.$2,
          spoken: lowercase
              ? 'Small ${entry.$1}. ${entry.$1} for ${entry.$2}.'
              : '${entry.$1}. ${entry.$1} for ${entry.$2}.',
        ),
    ];
  }

  static List<PreschoolPracticeItem> _vocabulary(
    PreschoolPracticeCategory category,
    List<(String, String)> entries,
  ) =>
      [
        for (var i = 0; i < entries.length; i++)
          PreschoolPracticeItem(
            id: '${category.id}_$i',
            category: category,
            name: entries[i].$1,
            emoji: entries[i].$2,
            spoken: entries[i].$1,
          ),
      ];

  static const _alphabet = <(String, String, String)>[
    ('A', 'Apple', '🍎'),
    ('B', 'Ball', '⚽'),
    ('C', 'Cat', '🐱'),
    ('D', 'Dog', '🐶'),
    ('E', 'Elephant', '🐘'),
    ('F', 'Fish', '🐟'),
    ('G', 'Goat', '🐐'),
    ('H', 'Hat', '🎩'),
    ('I', 'Ice cream', '🍨'),
    ('J', 'Juice', '🧃'),
    ('K', 'Kite', '🪁'),
    ('L', 'Lion', '🦁'),
    ('M', 'Moon', '🌙'),
    ('N', 'Nest', '🪺'),
    ('O', 'Orange', '🍊'),
    ('P', 'Parrot', '🦜'),
    ('Q', 'Queen', '👑'),
    ('R', 'Rainbow', '🌈'),
    ('S', 'Sun', '☀️'),
    ('T', 'Tiger', '🐯'),
    ('U', 'Umbrella', '☂️'),
    ('V', 'Van', '🚐'),
    ('W', 'Whale', '🐳'),
    ('X', 'Xylophone', '🎼'),
    ('Y', 'Yo-yo', '🪀'),
    ('Z', 'Zebra', '🦓'),
  ];

  static const _numberWords = [
    'Zero',
    'One',
    'Two',
    'Three',
    'Four',
    'Five',
    'Six',
    'Seven',
    'Eight',
    'Nine',
  ];
  static const _numberEmoji = [
    '0️⃣',
    '1️⃣',
    '2️⃣',
    '3️⃣',
    '4️⃣',
    '5️⃣',
    '6️⃣',
    '7️⃣',
    '8️⃣',
    '9️⃣'
  ];
  static final _numberItems = [
    for (var number = 0; number <= 9; number++)
      PreschoolPracticeItem(
        id: 'numbers_$number',
        category: PreschoolPracticeCategory.numbers,
        name: '$number',
        glyph: '$number',
        emoji: _numberEmoji[number],
        example: _numberWords[number],
        spoken: 'Number $number. ${_numberWords[number]}.',
      ),
  ];

  static PreschoolPracticeItem _hindi(
    String id,
    PreschoolPracticeCategory category,
    String glyph,
    String example,
    String emoji,
  ) =>
      PreschoolPracticeItem(
        id: id,
        category: category,
        name: glyph,
        glyph: glyph,
        emoji: emoji,
        example: example.isEmpty ? null : example,
        spoken: example.isEmpty ? glyph : '$glyph से $example',
        voiceLanguage: 'hi-IN',
      );

  static final _hindiVowels = <PreschoolPracticeItem>[
    _hindi('hv_a', PreschoolPracticeCategory.hindiVowels, 'अ', 'अनार', '🍎'),
    _hindi('hv_aa', PreschoolPracticeCategory.hindiVowels, 'आ', 'आम', '🥭'),
    _hindi('hv_i', PreschoolPracticeCategory.hindiVowels, 'इ', 'इमली', '🫘'),
    _hindi('hv_ii', PreschoolPracticeCategory.hindiVowels, 'ई', 'ईख', '🌾'),
    _hindi('hv_u', PreschoolPracticeCategory.hindiVowels, 'उ', 'उल्लू', '🦉'),
    _hindi('hv_uu', PreschoolPracticeCategory.hindiVowels, 'ऊ', 'ऊन', '🧶'),
    _hindi('hv_ri', PreschoolPracticeCategory.hindiVowels, 'ऋ', 'ऋषि', '🧘'),
    _hindi('hv_e', PreschoolPracticeCategory.hindiVowels, 'ए', 'एड़ी', '🦶'),
    _hindi('hv_ai', PreschoolPracticeCategory.hindiVowels, 'ऐ', 'ऐनक', '👓'),
    _hindi('hv_o', PreschoolPracticeCategory.hindiVowels, 'ओ', 'ओखली', '🥣'),
    _hindi('hv_au', PreschoolPracticeCategory.hindiVowels, 'औ', 'औरत', '👩'),
    _hindi('hv_an', PreschoolPracticeCategory.hindiVowels, 'अं', 'अंगूर', '🍇'),
    _hindi('hv_ah', PreschoolPracticeCategory.hindiVowels, 'अः', '', '✨'),
  ];

  static final _hindiConsonants = <PreschoolPracticeItem>[
    _hindi('hc_ka', PreschoolPracticeCategory.hindiConsonants, 'क', 'कबूतर',
        '🕊️'),
    _hindi('hc_kha', PreschoolPracticeCategory.hindiConsonants, 'ख', 'खरगोश',
        '🐰'),
    _hindi(
        'hc_ga', PreschoolPracticeCategory.hindiConsonants, 'ग', 'गमला', '🪴'),
    _hindi(
        'hc_gha', PreschoolPracticeCategory.hindiConsonants, 'घ', 'घर', '🏠'),
    _hindi('hc_nga', PreschoolPracticeCategory.hindiConsonants, 'ङ', '', '✨'),
    _hindi('hc_cha', PreschoolPracticeCategory.hindiConsonants, 'च', 'चम्मच',
        '🥄'),
    _hindi(
        'hc_chha', PreschoolPracticeCategory.hindiConsonants, 'छ', 'छत', '🏠'),
    _hindi(
        'hc_ja', PreschoolPracticeCategory.hindiConsonants, 'ज', 'जहाज', '🚢'),
    _hindi(
        'hc_jha', PreschoolPracticeCategory.hindiConsonants, 'झ', 'झंडा', '🚩'),
    _hindi('hc_nya', PreschoolPracticeCategory.hindiConsonants, 'ञ', '', '✨'),
    _hindi('hc_tta', PreschoolPracticeCategory.hindiConsonants, 'ट', 'टमाटर',
        '🍅'),
    _hindi('hc_ttha', PreschoolPracticeCategory.hindiConsonants, 'ठ', 'ठेला',
        '🛒'),
    _hindi(
        'hc_dda', PreschoolPracticeCategory.hindiConsonants, 'ड', 'डमरू', '🥁'),
    _hindi('hc_ddha', PreschoolPracticeCategory.hindiConsonants, 'ढ', 'ढक्कन',
        '🥣'),
    _hindi('hc_nna', PreschoolPracticeCategory.hindiConsonants, 'ण', '', '✨'),
    _hindi(
        'hc_ta', PreschoolPracticeCategory.hindiConsonants, 'त', 'तरबूज', '🍉'),
    _hindi('hc_tha', PreschoolPracticeCategory.hindiConsonants, 'थ', 'थाली',
        '🍽️'),
    _hindi(
        'hc_da', PreschoolPracticeCategory.hindiConsonants, 'द', 'दवाई', '💊'),
    _hindi(
        'hc_dha', PreschoolPracticeCategory.hindiConsonants, 'ध', 'धनुष', '🏹'),
    _hindi('hc_na', PreschoolPracticeCategory.hindiConsonants, 'न', 'नल', '🚰'),
    _hindi(
        'hc_pa', PreschoolPracticeCategory.hindiConsonants, 'प', 'पतंग', '🪁'),
    _hindi(
        'hc_pha', PreschoolPracticeCategory.hindiConsonants, 'फ', 'फल', '🍎'),
    _hindi(
        'hc_ba', PreschoolPracticeCategory.hindiConsonants, 'ब', 'बकरी', '🐐'),
    _hindi(
        'hc_bha', PreschoolPracticeCategory.hindiConsonants, 'भ', 'भालू', '🐻'),
    _hindi(
        'hc_ma', PreschoolPracticeCategory.hindiConsonants, 'म', 'मछली', '🐟'),
    _hindi(
        'hc_ya', PreschoolPracticeCategory.hindiConsonants, 'य', 'योग', '🧘'),
    _hindi('hc_ra', PreschoolPracticeCategory.hindiConsonants, 'र', 'रथ', '🛞'),
    _hindi(
        'hc_la', PreschoolPracticeCategory.hindiConsonants, 'ल', 'लड्डू', '🍬'),
    _hindi('hc_va', PreschoolPracticeCategory.hindiConsonants, 'व', 'वन', '🌳'),
    _hindi(
        'hc_sha', PreschoolPracticeCategory.hindiConsonants, 'श', 'शेर', '🦁'),
    _hindi('hc_ssa', PreschoolPracticeCategory.hindiConsonants, 'ष', 'षट्कोण',
        '⬡'),
    _hindi(
        'hc_sa', PreschoolPracticeCategory.hindiConsonants, 'स', 'सेब', '🍎'),
    _hindi(
        'hc_ha', PreschoolPracticeCategory.hindiConsonants, 'ह', 'हाथी', '🐘'),
    _hindi('hc_ksha', PreschoolPracticeCategory.hindiConsonants, 'क्ष', 'क्षमा',
        '🙏'),
    _hindi('hc_tra', PreschoolPracticeCategory.hindiConsonants, 'त्र',
        'त्रिशूल', '🔱'),
    _hindi('hc_gya', PreschoolPracticeCategory.hindiConsonants, 'ज्ञ', 'ज्ञान',
        '📚'),
  ];
}
