import 'package:flutter/material.dart';

import '../../core/services/audio_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/animated_background.dart';
import '../../core/widgets/bouncy_button.dart';
import '../curriculum/domain/lesson.dart';
import '../curriculum/domain/subject.dart';

class AdventureMission {
  const AdventureMission(this.emoji, this.title, this.story);

  final String emoji;
  final String title;
  final String story;

  factory AdventureMission.forLesson(Lesson lesson, {String? heroName}) {
    final hero = heroName?.trim().isNotEmpty == true ? heroName! : 'your team';
    return switch (lesson.subject) {
      Subject.math => AdventureMission(
          '🌙',
          'Repair the Moon Bridge',
          'The number stones have floated away! Help $hero solve the puzzles '
              'and rebuild the bridge.'),
      Subject.english => AdventureMission(
          '📚',
          'Wake the Whispering Library',
          'The story words have fallen asleep. Help $hero wake them with '
              'every answer.'),
      Subject.evs => AdventureMission(
          '🌱',
          'Help the Tiny Garden',
          'The garden needs knowledge to grow. Each answer gives $hero one '
              'drop of magic water.'),
      Subject.science => AdventureMission(
          '🚀',
          'Power the Discovery Rocket',
          'The rocket needs bright ideas for fuel. Help $hero fill its '
              'thinking tank.'),
      Subject.art => AdventureMission(
          '🎨',
          'Restore the Missing Colors',
          'The rainbow has lost its sparkle. Help $hero bring every color '
              'home.'),
      Subject.logic => AdventureMission('🗝️', 'Open the Puzzle Castle',
          'Clever locks guard the castle. Help $hero discover each secret.'),
      Subject.rhymes => AdventureMission('🎵', 'Bring Back the Music',
          'The songbirds forgot their tune. Help $hero collect the notes.'),
    };
  }
}

class AdventureIntro extends StatefulWidget {
  const AdventureIntro({
    super.key,
    required this.mission,
    required this.lessonTitle,
    required this.skillName,
    required this.teachingTip,
    required this.isNewSkill,
    this.foundationNote,
    required this.onStart,
  });

  final AdventureMission mission;
  final String lessonTitle;
  final String skillName;
  final String teachingTip;
  final bool isNewSkill;
  final String? foundationNote;
  final VoidCallback onStart;

  @override
  State<AdventureIntro> createState() => _AdventureIntroState();
}

class _AdventureIntroState extends State<AdventureIntro> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => AudioService.instance.speak(
          '${widget.mission.story} ${widget.foundationNote ?? ''} ${widget.teachingTip}'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        theme: WorldTheme.night,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 520),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: const [
                    BoxShadow(color: Color(0x55000000), blurRadius: 24),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.mission.emoji,
                        style: const TextStyle(fontSize: 92)),
                    const Text('YOUR MISSION',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Text(widget.mission.title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(color: AppColors.lightText)),
                    const SizedBox(height: 12),
                    Text(widget.mission.story,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: AppColors.lightText,
                            fontSize: 18,
                            height: 1.35,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(widget.lessonTitle,
                        style: const TextStyle(
                            color: AppColors.lightTextSoft,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.star.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Text(
                              '${widget.isNewSkill ? 'NEW SKILL' : 'QUICK REMINDER'} • ${widget.skillName.toUpperCase()}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w900)),
                          const SizedBox(height: 6),
                          Text(widget.teachingTip,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: AppColors.lightText,
                                  fontSize: 16,
                                  height: 1.35,
                                  fontWeight: FontWeight.w700)),
                          if (widget.foundationNote != null) ...[
                            const SizedBox(height: 8),
                            Text(widget.foundationNote!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w800)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    BouncyButton(
                      onTap: widget.onStart,
                      child: Container(
                        width: 260,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text('Let’s help! 🚀',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
