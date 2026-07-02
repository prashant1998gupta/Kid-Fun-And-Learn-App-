import 'package:equatable/equatable.dart';

import '../../profiles/domain/child_profile.dart';

/// One row on a friends leaderboard. Deliberately non-PII beyond a chosen
/// display name + a cosmetic avatar seed and a score — no email, no age, no
/// precise location. Entries are written server-side (Cloud Functions); clients
/// only read them.
class LeaderboardEntry extends Equatable {
  const LeaderboardEntry({
    required this.id,
    required this.displayName,
    required this.avatarSeed,
    required this.score,
    this.rank = 0,
    this.isMe = false,
  });

  final String id;
  final String displayName;
  final String avatarSeed;
  final int score;
  final int rank;

  /// True for the current family's own entry (highlighted in the list).
  final bool isMe;

  LeaderboardEntry copyWith({int? rank, bool? isMe}) => LeaderboardEntry(
        id: id,
        displayName: displayName,
        avatarSeed: avatarSeed,
        score: score,
        rank: rank ?? this.rank,
        isMe: isMe ?? this.isMe,
      );

  factory LeaderboardEntry.fromMap(String id, Map<String, dynamic> m) =>
      LeaderboardEntry(
        id: id,
        displayName: m['displayName'] as String? ?? 'Player',
        avatarSeed: m['avatarSeed'] as String? ?? '',
        score: (m['score'] as num?)?.toInt() ?? 0,
      );

  @override
  List<Object?> get props => [id, displayName, avatarSeed, score, rank, isMe];
}

/// Encodes/decodes an [AvatarConfig] to a compact, shareable seed string so a
/// friend's illustrated (non-photographic) avatar can be rendered from a
/// leaderboard entry without exposing anything identifying.
class AvatarSeed {
  const AvatarSeed._();

  static String encode(AvatarConfig a) =>
      '${a.skin}-${a.hair}-${a.hairColor}-${a.outfit}-${a.accessory}-${a.background}';

  static AvatarConfig decode(String seed) {
    final p = seed.split('-');
    int at(int i) => i < p.length ? (int.tryParse(p[i]) ?? 0) : 0;
    if (p.length < 6) return const AvatarConfig();
    return AvatarConfig(
      skin: at(0),
      hair: at(1),
      hairColor: at(2),
      outfit: at(3),
      accessory: at(4),
      background: at(5),
    );
  }
}
