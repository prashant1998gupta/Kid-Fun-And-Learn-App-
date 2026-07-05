import 'package:equatable/equatable.dart';

import '../../gamification/domain/wallet.dart';
import 'grade_level.dart';

/// A single child under a parent account. KidVerse supports multiple children
/// per parent, each with independent progress, wallet, and avatar.
class ChildProfile extends Equatable {
  const ChildProfile({
    required this.id,
    required this.name,
    required this.grade,
    required this.avatar,
    this.wallet = const Wallet(),
    this.mascotId = 'panda',
    this.unlockedThemes = const ['sunrise'],
    this.activeTheme = 'sunrise',
    this.ownedCollectibles = const [],
    this.activePetId,
    this.ownedRoomItems = const [],
    this.placedRoomItems = const [],
    this.companionXp = 0,
    this.companionName = 'Spark',
    this.companionMemory = 'I am ready for our first adventure!',
    this.heroDrawingId,
    this.heroName,
    this.completedAdventures = 0,
    this.createdAt,
    this.lastActiveAt,
  });

  final String id;
  final String name;
  final GradeLevel grade;
  final AvatarConfig avatar;
  final Wallet wallet;
  final String mascotId;
  final List<String> unlockedThemes;
  final String activeTheme;

  /// Collected sticker + pet ids (see `CollectionCatalog`). Rides the profile
  /// blob, so it persists locally and syncs to the cloud for free.
  final List<String> ownedCollectibles;

  /// The pet companion currently shown beside the child on Home (or null).
  final String? activePetId;

  /// Persistent pieces of the child's living world. These fields deliberately
  /// ride the profile blob so rewards, mini-games, and creative play all feed
  /// one offline-first emotional loop.
  final List<String> ownedRoomItems;
  final List<String> placedRoomItems;
  final int companionXp;
  final String companionName;
  final String companionMemory;
  final String? heroDrawingId;
  final String? heroName;
  final int completedAdventures;
  final DateTime? createdAt;
  final DateTime? lastActiveAt;

  ChildProfile copyWith({
    String? name,
    GradeLevel? grade,
    AvatarConfig? avatar,
    Wallet? wallet,
    String? mascotId,
    List<String>? unlockedThemes,
    String? activeTheme,
    List<String>? ownedCollectibles,
    String? activePetId,
    List<String>? ownedRoomItems,
    List<String>? placedRoomItems,
    int? companionXp,
    String? companionName,
    String? companionMemory,
    String? heroDrawingId,
    String? heroName,
    int? completedAdventures,
    DateTime? lastActiveAt,
  }) {
    return ChildProfile(
      id: id,
      name: name ?? this.name,
      grade: grade ?? this.grade,
      avatar: avatar ?? this.avatar,
      wallet: wallet ?? this.wallet,
      mascotId: mascotId ?? this.mascotId,
      unlockedThemes: unlockedThemes ?? this.unlockedThemes,
      activeTheme: activeTheme ?? this.activeTheme,
      ownedCollectibles: ownedCollectibles ?? this.ownedCollectibles,
      activePetId: activePetId ?? this.activePetId,
      ownedRoomItems: ownedRoomItems ?? this.ownedRoomItems,
      placedRoomItems: placedRoomItems ?? this.placedRoomItems,
      companionXp: companionXp ?? this.companionXp,
      companionName: companionName ?? this.companionName,
      companionMemory: companionMemory ?? this.companionMemory,
      heroDrawingId: heroDrawingId ?? this.heroDrawingId,
      heroName: heroName ?? this.heroName,
      completedAdventures: completedAdventures ?? this.completedAdventures,
      createdAt: createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'grade': grade.name,
        'avatar': avatar.toMap(),
        'wallet': wallet.toMap(),
        'mascotId': mascotId,
        'unlockedThemes': unlockedThemes,
        'activeTheme': activeTheme,
        'ownedCollectibles': ownedCollectibles,
        'activePetId': activePetId,
        'ownedRoomItems': ownedRoomItems,
        'placedRoomItems': placedRoomItems,
        'companionXp': companionXp,
        'companionName': companionName,
        'companionMemory': companionMemory,
        'heroDrawingId': heroDrawingId,
        'heroName': heroName,
        'completedAdventures': completedAdventures,
        'createdAt': createdAt?.toIso8601String(),
        'lastActiveAt': lastActiveAt?.toIso8601String(),
      };

  factory ChildProfile.fromMap(Map<String, dynamic> map) => ChildProfile(
        id: map['id'] as String,
        name: map['name'] as String,
        grade: GradeLevel.fromId(map['grade'] as String? ?? 'lkg'),
        avatar: AvatarConfig.fromMap(
          (map['avatar'] as Map?)?.cast<String, dynamic>() ?? const {},
        ),
        wallet: Wallet.fromMap(
          (map['wallet'] as Map?)?.cast<String, dynamic>() ?? const {},
        ),
        mascotId: map['mascotId'] as String? ?? 'panda',
        unlockedThemes: (map['unlockedThemes'] as List?)?.cast<String>() ??
            const ['sunrise'],
        activeTheme: map['activeTheme'] as String? ?? 'sunrise',
        ownedCollectibles:
            (map['ownedCollectibles'] as List?)?.cast<String>() ?? const [],
        activePetId: map['activePetId'] as String?,
        ownedRoomItems:
            (map['ownedRoomItems'] as List?)?.cast<String>() ?? const [],
        placedRoomItems:
            (map['placedRoomItems'] as List?)?.cast<String>() ?? const [],
        companionXp: (map['companionXp'] as num?)?.toInt() ?? 0,
        companionName: map['companionName'] as String? ?? 'Spark',
        companionMemory: map['companionMemory'] as String? ??
            'I am ready for our first adventure!',
        heroDrawingId: map['heroDrawingId'] as String?,
        heroName: map['heroName'] as String?,
        completedAdventures: (map['completedAdventures'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.tryParse(map['createdAt'] as String? ?? ''),
        lastActiveAt: DateTime.tryParse(map['lastActiveAt'] as String? ?? ''),
      );

  @override
  List<Object?> get props => [
        id,
        name,
        grade,
        avatar,
        wallet,
        mascotId,
        activeTheme,
        ownedCollectibles,
        activePetId,
        ownedRoomItems,
        placedRoomItems,
        companionXp,
        companionName,
        companionMemory,
        heroDrawingId,
        heroName,
        completedAdventures,
      ];
}

/// A composable, non-photographic avatar — safe for kids (no real photos).
/// Each field indexes into a set of illustrated parts.
class AvatarConfig extends Equatable {
  const AvatarConfig({
    this.skin = 2,
    this.hair = 0,
    this.hairColor = 0,
    this.outfit = 0,
    this.accessory = 0,
    this.background = 0,
  });

  final int skin;
  final int hair;
  final int hairColor;
  final int outfit;
  final int accessory;
  final int background;

  AvatarConfig copyWith({
    int? skin,
    int? hair,
    int? hairColor,
    int? outfit,
    int? accessory,
    int? background,
  }) {
    return AvatarConfig(
      skin: skin ?? this.skin,
      hair: hair ?? this.hair,
      hairColor: hairColor ?? this.hairColor,
      outfit: outfit ?? this.outfit,
      accessory: accessory ?? this.accessory,
      background: background ?? this.background,
    );
  }

  Map<String, dynamic> toMap() => {
        'skin': skin,
        'hair': hair,
        'hairColor': hairColor,
        'outfit': outfit,
        'accessory': accessory,
        'background': background,
      };

  factory AvatarConfig.fromMap(Map<String, dynamic> map) => AvatarConfig(
        skin: (map['skin'] ?? 2) as int,
        hair: (map['hair'] ?? 0) as int,
        hairColor: (map['hairColor'] ?? 0) as int,
        outfit: (map['outfit'] ?? 0) as int,
        accessory: (map['accessory'] ?? 0) as int,
        background: (map['background'] ?? 0) as int,
      );

  @override
  List<Object?> get props =>
      [skin, hair, hairColor, outfit, accessory, background];
}
