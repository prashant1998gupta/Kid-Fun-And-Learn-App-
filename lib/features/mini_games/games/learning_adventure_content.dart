part of 'learning_adventure_game.dart';

class _AdventureRound {
  const _AdventureRound({
    required this.skill,
    required this.prompt,
    required this.spokenPrompt,
    required this.scene,
    required this.sceneLabel,
    required this.choices,
    required this.correctIndex,
    required this.hint,
    required this.explanation,
  });

  final String skill;
  final String prompt;
  final String spokenPrompt;
  final List<String> scene;
  final String sceneLabel;
  final List<_AdventureChoice> choices;
  final int correctIndex;
  final String hint;
  final String explanation;

  String get identity => '$skill|$prompt|$sceneLabel|'
      '${choices[correctIndex].label}|${scene.join()}';

  String get wrongGuess =>
      choices[correctIndex == 0 ? 1 : 0].label.toLowerCase();
}

class _AdventureChoice {
  const _AdventureChoice(this.label, [this.emoji]);

  final String label;
  final String? emoji;
}

class _AdventureContent {
  _AdventureContent._();

  static _AdventureRound question(
    LearningAdventureType type,
    int level,
    int round,
  ) =>
      switch (type) {
        LearningAdventureType.soundSafari => _sound(level, round),
        LearningAdventureType.numberGarden => _number(level, round),
        LearningAdventureType.storyTrain => _story(level, round),
        LearningAdventureType.letterBakery => _letter(level, round),
        LearningAdventureType.cleanRoom => _clean(level, round),
        LearningAdventureType.mathMarket => _market(level, round),
        LearningAdventureType.wordWizard => _wordWizard(level, round),
        LearningAdventureType.sentenceTrain => _sentence(level, round),
        LearningAdventureType.clockAdventure => _clock(level, round),
        LearningAdventureType.natureDetective => _nature(level, round),
        LearningAdventureType.shapeBuilder => _shape(level, round),
        LearningAdventureType.fractionCafe => _fraction(level, round),
        LearningAdventureType.multiplicationKingdom =>
          _multiplication(level, round),
        LearningAdventureType.grammarDetective => _grammar(level, round),
        LearningAdventureType.codeRobot => _code(level, round),
        LearningAdventureType.scienceLab => _science(level, round),
        LearningAdventureType.mapQuest => _map(level, round),
        LearningAdventureType.ecoCity => _eco(level, round),
        LearningAdventureType.spaceMission => _space(level, round),
        LearningAdventureType.businessBazaar => _business(level, round),
        LearningAdventureType.mysteryScience => _mystery(level, round),
        LearningAdventureType.newsDetective => _news(level, round),
        LearningAdventureType.algorithmQuest => _algorithm(level, round),
      };

  static _AdventureRound _sound(int level, int round) {
    final targetIndex = (level * 7 + round * 4) % _sounds.length;
    final target = _sounds[targetIndex];
    final reverse = level > 15 && (level + round).isEven;
    final candidates = _candidateIndexes(
      targetIndex,
      _sounds.length,
      level,
      round,
    );
    final choices = [
      for (final index in candidates)
        reverse
            ? _AdventureChoice(_sounds[index].sound.toUpperCase(), '🔊')
            : _AdventureChoice(_sounds[index].animal, _sounds[index].emoji),
    ];
    final correct = candidates.indexOf(targetIndex);
    return _AdventureRound(
      skill: reverse ? 'Match animal sounds' : 'Listen and identify',
      prompt: reverse
          ? 'What sound does the ${target.animal} make?'
          : 'Who says "${target.sound.toUpperCase()}"?',
      spokenPrompt: reverse
          ? 'What sound does the ${target.animal} make?'
          : 'Listen. ${target.sound}. Who makes that sound?',
      scene: reverse ? [target.emoji, '🔊'] : ['🎧', '🌿'],
      sceneLabel: reverse ? target.animal.toUpperCase() : 'LISTEN CAREFULLY',
      choices: choices,
      correctIndex: correct,
      hint: reverse
          ? 'Listen to the ${target.animal}: ${target.sound}.'
          : 'The ${target.animal} says ${target.sound}.',
      explanation: 'The ${target.animal} says ${target.sound}!',
    );
  }

  static _AdventureRound _number(int level, int round) {
    final max = level <= 8
        ? 3
        : level <= 18
            ? 5
            : 10;
    final addition = level > 30 && (level + round).isEven;
    final first = 1 + ((level * 2 + round) % (addition ? 5 : max));
    final second = addition ? 1 + ((level + round * 2) % 4) : 0;
    final answer = first + second;
    final values = <int>{answer};
    var step = 1;
    while (values.length < 3) {
      final candidate = (answer + (step.isOdd ? step : -step)).clamp(1, 10);
      values.add(candidate);
      step++;
    }
    final numbers = values.toList()..shuffle(math.Random(level * 101 + round));
    return _AdventureRound(
      skill: addition ? 'Early addition' : 'Count quantities',
      prompt: addition ? 'How many flowers altogether?' : 'How many flowers?',
      spokenPrompt: addition
          ? 'Count $first flowers and $second more. How many altogether?'
          : 'Count the flowers. How many can you see?',
      scene: [
        for (var i = 0; i < first; i++) '🌼',
        if (addition) '➕',
        for (var i = 0; i < second; i++) '🌻',
      ],
      sceneLabel: addition ? '$first AND $second MORE' : 'TOUCH AND COUNT',
      choices: [for (final value in numbers) _AdventureChoice('$value')],
      correctIndex: numbers.indexOf(answer),
      hint: addition
          ? 'Start at $first, then count $second more.'
          : 'Touch each flower once.',
      explanation: 'There ${answer == 1 ? 'is' : 'are'} $answer!',
    );
  }

  static _AdventureRound _story(int level, int round) {
    final index = (level * 3 + round * 3) % _stories.length;
    final story = _stories[index];
    final candidates = _candidateIndexes(index, _stories.length, level, round);
    final choices = [
      for (final candidate in candidates)
        _AdventureChoice(_stories[candidate].answer, _stories[candidate].third),
    ];
    return _AdventureRound(
      skill: 'Story order and prediction',
      prompt: 'What happens next?',
      spokenPrompt:
          '${story.firstLabel}. Then ${story.secondLabel}. What happens next?',
      scene: [story.first, '➡️', story.second, '➡️', '❓'],
      sceneLabel:
          '${story.firstLabel.toUpperCase()} • THEN ${story.secondLabel.toUpperCase()}',
      choices: choices,
      correctIndex: candidates.indexOf(index),
      hint: 'Think about what usually comes after ${story.secondLabel}.',
      explanation: 'Next, ${story.answer.toLowerCase()}!',
    );
  }

  static _AdventureRound _letter(int level, int round) {
    final index = (level * 5 + round * 3) % _words.length;
    final word = _words[index];
    final lowercase = level > 20 && (level + round).isEven;
    final correctLetter = lowercase ? word.letter.toLowerCase() : word.letter;
    final letters = <String>{correctLetter};
    var offset = 1;
    final code = word.letter.codeUnitAt(0) - 65;
    while (letters.length < 3) {
      final candidate = String.fromCharCode(65 + ((code + offset * 5) % 26));
      letters.add(lowercase ? candidate.toLowerCase() : candidate);
      offset++;
    }
    final choices = letters.toList()..shuffle(math.Random(level * 211 + round));
    return _AdventureRound(
      skill: lowercase ? 'Lowercase first sounds' : 'Letter sounds',
      prompt: 'Which letter starts ${word.word.toUpperCase()}?',
      spokenPrompt:
          '${word.word}. ${word.word}. Which letter makes the first sound?',
      scene: [word.emoji, '🥐'],
      sceneLabel: word.word.toUpperCase(),
      choices: [for (final letter in choices) _AdventureChoice(letter)],
      correctIndex: choices.indexOf(correctLetter),
      hint: '${word.word} starts with ${word.letter}.',
      explanation: '${word.letter} is for ${word.word}!',
    );
  }

  static _AdventureRound _clean(int level, int round) {
    final index = (level * 7 + round * 4) % _tidyItems.length;
    final target = _tidyItems[index];
    final availablePlaces = _places
        .where((place) =>
            place.id == target.place || level > 8 || place.id != 'books')
        .toList();
    final targetPlaceIndex =
        availablePlaces.indexWhere((p) => p.id == target.place);
    final candidates = _candidateIndexes(
      targetPlaceIndex,
      availablePlaces.length,
      level,
      round,
      count: level <= 8 ? 2 : 3,
    );
    final choices = [
      for (final candidate in candidates)
        _AdventureChoice(
          availablePlaces[candidate].label,
          availablePlaces[candidate].emoji,
        ),
    ];
    return _AdventureRound(
      skill: 'Everyday sorting',
      prompt: 'Where does the ${target.name} belong?',
      spokenPrompt: 'Help clean up. Where does the ${target.name} belong?',
      scene: [target.emoji, '✨'],
      sceneLabel: target.name.toUpperCase(),
      choices: choices,
      correctIndex: candidates.indexOf(targetPlaceIndex),
      hint:
          'We keep the ${target.name} in the ${_place(target.place).label.toLowerCase()}.',
      explanation:
          'The ${target.name} goes in the ${_place(target.place).label.toLowerCase()}!',
    );
  }

  static _AdventureRound _market(int level, int round) {
    final first = _marketItems[(level * 3 + round * 2) % _marketItems.length];
    final second =
        _marketItems[(level * 5 + round * 3 + 1) % _marketItems.length];
    final firstPrice = 1 + ((level + round * 2) % (level <= 15 ? 9 : 15));
    final secondPrice = 1 + ((level * 2 + round) % (level <= 15 ? 6 : 12));
    final changeQuestion = level > 15 && (level + round).isEven;
    final threeItems = level > 35 && !changeQuestion;
    final thirdPrice = threeItems ? 1 + ((level + round * 4) % 8) : 0;
    final answer = changeQuestion
        ? firstPrice + secondPrice
        : firstPrice + secondPrice + thirdPrice;
    final paid = changeQuestion ? answer + 2 + ((level + round) % 8) : 0;
    final finalAnswer = changeQuestion ? paid - answer : answer;
    final numbers = _nearbyNumbers(finalAnswer, level * 307 + round, max: 40);
    return _AdventureRound(
      skill: changeQuestion ? 'Subtraction and change' : 'Addition and money',
      prompt: changeQuestion
          ? 'You pay $paid coins. How much change?'
          : 'How many coins altogether?',
      spokenPrompt: changeQuestion
          ? 'The ${first.name} and ${second.name} cost $answer coins. You pay $paid coins. How many coins come back?'
          : 'The ${first.name} costs $firstPrice coins and the ${second.name} costs $secondPrice coins${threeItems ? ', with $thirdPrice more coins for another item' : ''}. How many coins altogether?',
      scene: [
        first.emoji,
        '$firstPrice',
        '🪙',
        second.emoji,
        '$secondPrice',
        '🪙',
        if (threeItems) ...['🎁', '$thirdPrice', '🪙'],
      ],
      sceneLabel:
          changeQuestion ? 'COST $answer • PAY $paid' : 'ADD THE PRICES',
      choices: [
        for (final number in numbers) _AdventureChoice('$number', '🪙'),
      ],
      correctIndex: numbers.indexOf(finalAnswer),
      hint: changeQuestion
          ? 'Count forward from $answer to $paid.'
          : 'Start with $firstPrice, then count on $secondPrice${threeItems ? ' and $thirdPrice' : ''}.',
      explanation: changeQuestion
          ? '$finalAnswer coins come back!'
          : 'The total is $finalAnswer coins!',
    );
  }

  static _AdventureRound _wordWizard(int level, int round) {
    final word = _words[(level * 7 + round * 5) % _words.length];
    final firstLetter = word.letter;
    final lastLetter = word.word[word.word.length - 1].toUpperCase();
    if (level <= 18) {
      final letters = _letterChoices(firstLetter, level * 401 + round);
      return _AdventureRound(
        skill: 'Beginning sounds and spelling',
        prompt: 'Which letter completes the word?',
        spokenPrompt:
            '${word.word}. Which letter starts the word ${word.word}?',
        scene: [word.emoji, '✨'],
        sceneLabel: '_${word.word.substring(1).toUpperCase()}',
        choices: [for (final letter in letters) _AdventureChoice(letter)],
        correctIndex: letters.indexOf(firstLetter),
        hint: '${word.word} begins with the sound $firstLetter.',
        explanation: '$firstLetter completes ${word.word}!',
      );
    }
    if (level <= 34) {
      final letters = _letterChoices(lastLetter, level * 409 + round);
      return _AdventureRound(
        skill: 'Ending sounds and spelling',
        prompt: 'Which letter finishes the word?',
        spokenPrompt:
            '${word.word}. Listen to the final sound. Which letter finishes ${word.word}?',
        scene: [word.emoji, '🪄'],
        sceneLabel:
            '${word.word.substring(0, word.word.length - 1).toUpperCase()}_',
        choices: [for (final letter in letters) _AdventureChoice(letter)],
        correctIndex: letters.indexOf(lastLetter),
        hint: '${word.word} ends with $lastLetter.',
        explanation: '$lastLetter finishes ${word.word}!',
      );
    }
    final correct = word.word.toUpperCase();
    final wrongFirst =
        '${String.fromCharCode(65 + ((firstLetter.codeUnitAt(0) - 64) % 26))}${correct.substring(1)}';
    final missing = correct.substring(0, correct.length - 1);
    final spellings = <String>{correct, wrongFirst, missing}.toList()
      ..shuffle(math.Random(level * 419 + round));
    return _AdventureRound(
      skill: 'Whole-word spelling',
      prompt: 'Which spelling is correct?',
      spokenPrompt: 'Choose the correct spelling of ${word.word}.',
      scene: [word.emoji, '🧙'],
      sceneLabel: 'SPELL ${word.word.toUpperCase()}',
      choices: [for (final spelling in spellings) _AdventureChoice(spelling)],
      correctIndex: spellings.indexOf(correct),
      hint: 'Say each sound slowly: ${word.word}.',
      explanation: '$correct is the correct spelling!',
    );
  }

  static _AdventureRound _sentence(int level, int round) {
    final item = _sentences[(level * 5 + round * 3) % _sentences.length];
    final punctuation = level > 30 && (level + round).isEven;
    if (punctuation) {
      final marks = <String>[item.mark, '.', '?']
        ..shuffle(math.Random(level * 433 + round));
      final uniqueMarks = marks.toSet().toList();
      while (uniqueMarks.length < 3) {
        uniqueMarks.add('!');
      }
      return _AdventureRound(
        skill: 'Sentence punctuation',
        prompt: 'Which mark completes the sentence?',
        spokenPrompt:
            '${item.completeSentence} Which punctuation mark belongs at the end?',
        scene: [item.emoji, '🚂'],
        sceneLabel: '${item.completeSentence.toUpperCase()} _',
        choices: [for (final mark in uniqueMarks) _AdventureChoice(mark)],
        correctIndex: uniqueMarks.indexOf(item.mark),
        hint: item.mark == '?'
            ? 'A question ends with a question mark.'
            : item.mark == '!'
                ? 'An excited sentence can end with an exclamation mark.'
                : 'A telling sentence ends with a full stop.',
        explanation: '${item.mark} completes the sentence!',
      );
    }
    final words = <String>[item.answer, item.distractorOne, item.distractorTwo]
      ..shuffle(math.Random(level * 431 + round));
    return _AdventureRound(
      skill: level <= 18 ? 'Build simple sentences' : 'Grammar and verb choice',
      prompt: 'Which word completes the sentence?',
      spokenPrompt:
          '${item.before}, blank, ${item.after}. Choose the best word.',
      scene: [item.emoji, '🚂', '❓'],
      sceneLabel:
          '${item.before.toUpperCase()} ___ ${item.after.toUpperCase()}',
      choices: [for (final word in words) _AdventureChoice(word.toUpperCase())],
      correctIndex: words.indexOf(item.answer),
      hint:
          'Read the whole sentence and listen for the word that sounds right.',
      explanation: '${item.answer} makes the sentence correct!',
    );
  }

  static _AdventureRound _clock(int level, int round) {
    final halfHour = level > 25 && (level + round).isEven;
    final hour = 1 + ((level * 3 + round * 2) % 12);
    final correctTime = halfHour ? '$hour:30' : '$hour:00';
    final times = <String>{correctTime};
    var offset = 1;
    while (times.length < 3) {
      final otherHour = 1 + ((hour - 1 + offset * 3) % 12);
      times.add(halfHour ? '$otherHour:30' : '$otherHour:00');
      offset++;
    }
    final choices = times.toList()..shuffle(math.Random(level * 443 + round));
    final activityMode = level > 38 && round.isOdd;
    final activity = _dailyTimes[(level + round) % _dailyTimes.length];
    if (activityMode) {
      final activityChoices = <_DailyTime>[activity];
      var cursor = (_dailyTimes.indexOf(activity) + 2) % _dailyTimes.length;
      while (activityChoices.length < 3) {
        final candidate = _dailyTimes[cursor % _dailyTimes.length];
        if (!activityChoices.contains(candidate)) {
          activityChoices.add(candidate);
        }
        cursor++;
      }
      activityChoices.shuffle(math.Random(level * 449 + round));
      return _AdventureRound(
        skill: 'Time and daily routines',
        prompt: 'What usually happens at ${activity.time}?',
        spokenPrompt:
            'It is ${activity.spokenTime}. What activity usually happens now?',
        scene: [activity.clock, '⏰'],
        sceneLabel: activity.time,
        choices: [
          for (final choice in activityChoices)
            _AdventureChoice(choice.activity, choice.emoji),
        ],
        correctIndex: activityChoices.indexOf(activity),
        hint: '${activity.activity} often happens at ${activity.time}.',
        explanation: '${activity.activity} matches ${activity.time}!',
      );
    }
    return _AdventureRound(
      skill: halfHour ? 'Read half-hour clocks' : 'Read hour clocks',
      prompt: 'What time does the clock show?',
      spokenPrompt: 'Look at the clock hands. What time is it?',
      scene: [_clockEmoji(hour, halfHour)],
      sceneLabel: halfHour ? 'HALF PAST $hour' : '$hour O\'CLOCK',
      choices: [for (final time in choices) _AdventureChoice(time)],
      correctIndex: choices.indexOf(correctTime),
      hint: halfHour
          ? 'The minute hand points to six, so it is half past.'
          : 'The minute hand points to twelve, so it is exactly on the hour.',
      explanation: 'The time is $correctTime!',
    );
  }

  static _AdventureRound _nature(int level, int round) {
    final index = (level * 7 + round * 5) % _natureItems.length;
    final target = _natureItems[index];
    final habitatMode = level > 22 && (level + round).isEven;
    if (habitatMode) {
      final habitats = <String>{target.habitat};
      var cursor = (index + 1) % _natureItems.length;
      while (habitats.length < 3) {
        habitats.add(_natureItems[cursor].habitat);
        cursor = (cursor + 1) % _natureItems.length;
      }
      final choices = habitats.toList()
        ..shuffle(math.Random(level * 457 + round));
      return _AdventureRound(
        skill: 'Habitats and adaptation',
        prompt: 'Where does the ${target.name} live?',
        spokenPrompt: 'Where would you find a ${target.name} in nature?',
        scene: [target.emoji, '🔎'],
        sceneLabel: target.clue.toUpperCase(),
        choices: [
          for (final habitat in choices)
            _AdventureChoice(habitat.toUpperCase(), _habitatEmoji(habitat)),
        ],
        correctIndex: choices.indexOf(target.habitat),
        hint: 'Think about the body and needs of the ${target.name}.',
        explanation: 'The ${target.name} lives in the ${target.habitat}!',
      );
    }
    final candidates =
        _candidateIndexes(index, _natureItems.length, level, round);
    return _AdventureRound(
      skill: 'Observe and infer from clues',
      prompt: 'Which living thing matches the clue?',
      spokenPrompt: '${target.clue}. Which living thing am I describing?',
      scene: ['🔎', '🌿', '❓'],
      sceneLabel: target.clue.toUpperCase(),
      choices: [
        for (final candidate in candidates)
          _AdventureChoice(
              _natureItems[candidate].name, _natureItems[candidate].emoji),
      ],
      correctIndex: candidates.indexOf(index),
      hint: 'Look for the important words in the clue.',
      explanation: 'It is the ${target.name}!',
    );
  }

  static _AdventureRound _shape(int level, int round) {
    final index = (level * 5 + round * 2) % _shapes.length;
    final target = _shapes[index];
    final patternMode = level > 30 && (level + round).isEven;
    final sidesMode = !patternMode && level > 15 && round.isOdd;
    if (patternMode) {
      final second = _shapes[(index + 2) % _shapes.length];
      final candidates = _candidateIndexes(index, _shapes.length, level, round);
      return _AdventureRound(
        skill: 'Shape patterns',
        prompt: 'Which shape comes next?',
        spokenPrompt:
            '${target.name}, ${second.name}, ${target.name}, ${second.name}. Which shape comes next?',
        scene: [target.emoji, second.emoji, target.emoji, second.emoji, '❓'],
        sceneLabel: 'FIND THE REPEATING PATTERN',
        choices: [
          for (final candidate in candidates)
            _AdventureChoice(_shapes[candidate].name, _shapes[candidate].emoji),
        ],
        correctIndex: candidates.indexOf(index),
        hint: 'The two shapes take turns.',
        explanation: 'The ${target.name} continues the pattern!',
      );
    }
    if (sidesMode) {
      final numbers =
          _nearbyNumbers(target.sides, level * 463 + round, max: 12);
      return _AdventureRound(
        skill: 'Shape properties and sides',
        prompt: 'How many straight sides?',
        spokenPrompt: 'How many straight sides does a ${target.name} have?',
        scene: [target.emoji, '📏'],
        sceneLabel: target.name.toUpperCase(),
        choices: [for (final number in numbers) _AdventureChoice('$number')],
        correctIndex: numbers.indexOf(target.sides),
        hint: 'Trace around the shape and count each straight edge.',
        explanation: 'A ${target.name} has ${target.sides} straight sides!',
      );
    }
    final candidates = _candidateIndexes(index, _shapes.length, level, round);
    return _AdventureRound(
      skill: 'Recognise 2D shapes',
      prompt: 'Find the ${target.name}.',
      spokenPrompt: 'Which picture is a ${target.name}?',
      scene: ['🏗️', '🧱'],
      sceneLabel: 'CHOOSE THE ${target.name.toUpperCase()}',
      choices: [
        for (final candidate in candidates)
          _AdventureChoice(_shapes[candidate].name, _shapes[candidate].emoji),
      ],
      correctIndex: candidates.indexOf(index),
      hint: target.description,
      explanation: 'That is the ${target.name}!',
    );
  }

  static _AdventureRound _fraction(int level, int round) {
    final denominators =
        level <= 12 ? const [2, 3, 4] : const [2, 3, 4, 5, 6, 8];
    final denominator = denominators[(level + round * 2) % denominators.length];
    final numerator = 1 + ((level * 3 + round) % (denominator - 1));
    final addition = level > 34 && (level + round).isEven;
    final equivalent = !addition && level > 18 && round.isOdd;
    if (addition) {
      final first = 1 + ((level + round) % math.max(1, denominator - 2));
      final second = 1 + ((level * 2 + round) % (denominator - first));
      final answerTop = first + second;
      final answer = '$answerTop/$denominator';
      final choices = <String>{
        answer,
        '${math.max(1, answerTop - 1)}/$denominator',
        '$answerTop/${denominator + 1}',
      }.toList()
        ..shuffle(math.Random(level * 503 + round));
      return _AdventureRound(
        skill: 'Add like fractions',
        prompt: 'How much pizza altogether?',
        spokenPrompt:
            'Add $first $denominator-ths and $second $denominator-ths. The pieces are the same size.',
        scene: [
          for (var i = 0; i < first; i++) '🍕',
          '➕',
          for (var i = 0; i < second; i++) '🍕',
        ],
        sceneLabel: '$first/$denominator + $second/$denominator',
        choices: [for (final value in choices) _AdventureChoice(value)],
        correctIndex: choices.indexOf(answer),
        hint: 'Keep the denominator $denominator and add the top numbers.',
        explanation: '$first/$denominator + $second/$denominator = $answer!',
      );
    }
    if (equivalent) {
      final doubled = '${numerator * 2}/${denominator * 2}';
      final choiceSet = <String>{
        doubled,
        '${numerator + 1}/${denominator * 2}',
        '${numerator * 2}/${denominator + 1}',
      };
      if (choiceSet.length < 3) {
        choiceSet.add('$numerator/${denominator * 2}');
      }
      final choices = choiceSet.toList()
        ..shuffle(math.Random(level * 509 + round));
      return _AdventureRound(
        skill: 'Equivalent fractions',
        prompt: 'Which fraction is equal?',
        spokenPrompt:
            'Which fraction has the same value as $numerator over $denominator?',
        scene: ['🍕', '⚖️', '🍕'],
        sceneLabel: '$numerator/$denominator = ?',
        choices: [for (final value in choices) _AdventureChoice(value)],
        correctIndex: choices.indexOf(doubled),
        hint: 'Multiply the top and bottom by the same number.',
        explanation: '$numerator/$denominator equals $doubled!',
      );
    }
    final answer = '$numerator/$denominator';
    final choices = <String>{
      answer,
      '${math.max(1, numerator - 1)}/$denominator',
      '$numerator/${denominator + 1}',
    }.toList();
    while (choices.length < 3) {
      choices.add('${numerator + 1}/$denominator');
    }
    choices.shuffle(math.Random(level * 499 + round));
    return _AdventureRound(
      skill: 'Read fractions of a whole',
      prompt: 'What fraction is served?',
      spokenPrompt:
          '$numerator of $denominator equal pizza pieces are served. What fraction is that?',
      scene: [
        for (var i = 0; i < numerator; i++) '🍕',
        for (var i = numerator; i < denominator; i++) '▫️',
      ],
      sceneLabel: '$numerator OF $denominator EQUAL PIECES',
      choices: [for (final value in choices) _AdventureChoice(value)],
      correctIndex: choices.indexOf(answer),
      hint:
          'The top number counts served pieces. The bottom counts all pieces.',
      explanation: '$numerator out of $denominator is $answer!',
    );
  }

  static _AdventureRound _multiplication(int level, int round) {
    final maxFactor = level <= 12
        ? 5
        : level <= 28
            ? 10
            : 12;
    final first = 2 + ((level + round * 3) % (maxFactor - 1));
    final second = 2 + ((level * 2 + round) % (maxFactor - 1));
    final product = first * second;
    final division = level > 18 && (level + round).isEven;
    final missingFactor = level > 35 && !division && round.isOdd;
    final answer = division
        ? second
        : missingFactor
            ? first
            : product;
    final numbers = _nearbyNumbers(answer, level * 521 + round, max: 144);
    return _AdventureRound(
      skill: division
          ? 'Division as equal sharing'
          : missingFactor
              ? 'Find a missing factor'
              : 'Multiplication facts',
      prompt: division
          ? '$product ÷ $first = ?'
          : missingFactor
              ? '? × $second = $product'
              : '$first × $second = ?',
      spokenPrompt: division
          ? 'Share $product objects into $first equal groups. How many are in each group?'
          : missingFactor
              ? 'What number times $second makes $product?'
              : 'There are $first equal groups of $second. How many altogether?',
      scene: [
        for (var i = 0; i < math.min(first, 8); i++) '🛡️',
        '×',
        '$second',
      ],
      sceneLabel: division
          ? '$product SHARED INTO $first GROUPS'
          : '$first GROUPS OF $second',
      choices: [for (final value in numbers) _AdventureChoice('$value')],
      correctIndex: numbers.indexOf(answer),
      hint: division
          ? 'Use the multiplication fact $first × $second = $product.'
          : 'Skip-count by $second, $first times.',
      explanation: division
          ? '$product ÷ $first = $answer!'
          : '$first × $second = $product!',
    );
  }

  static _AdventureRound _grammar(int level, int round) {
    final question =
        _grammarQuestions[(level * 7 + round * 3) % _grammarQuestions.length];
    final choices = <String>[
      question.answer,
      question.distractorOne,
      question.distractorTwo,
    ]..shuffle(math.Random(level * 523 + round));
    return _AdventureRound(
      skill: question.skill,
      prompt: question.prompt,
      spokenPrompt: question.spokenPrompt,
      scene: [question.emoji, '🔎', '📖'],
      sceneLabel: question.sentence.toUpperCase(),
      choices: [for (final choice in choices) _AdventureChoice(choice)],
      correctIndex: choices.indexOf(question.answer),
      hint: question.hint,
      explanation: question.explanation,
    );
  }

  static _AdventureRound _code(int level, int round) {
    final loopMode = level > 18 && (level + round).isEven;
    final debugMode = level > 35 && !loopMode && round.isOdd;
    if (loopMode) {
      final repeats = 2 + ((level + round) % 4);
      final moves = 1 + ((level * 2 + round) % 3);
      final answer = repeats * moves;
      final numbers = _nearbyNumbers(answer, level * 541 + round, max: 20);
      return _AdventureRound(
        skill: 'Loops and repeated commands',
        prompt: 'Where does the robot finish?',
        spokenPrompt:
            'Repeat move $moves steps, $repeats times. How many steps altogether?',
        scene: ['🤖', '🔁', '$repeats', '➡️', '$moves', '⭐'],
        sceneLabel: 'REPEAT $repeats [ MOVE $moves ]',
        choices: [for (final number in numbers) _AdventureChoice('$number')],
        correctIndex: numbers.indexOf(answer),
        hint: 'Add $moves once for every repeat.',
        explanation: 'The robot moves $answer steps!',
      );
    }
    final target = 3 + ((level * 3 + round) % 7);
    if (debugMode) {
      final actual = target + ((level + round).isEven ? 1 : -1);
      final answer = actual > target ? 'REMOVE 1' : 'ADD 1';
      final choices = <String>{answer, 'TURN LEFT', 'REPEAT AGAIN'}.toList()
        ..shuffle(math.Random(level * 547 + round));
      return _AdventureRound(
        skill: 'Debug an algorithm',
        prompt: 'Which fix reaches the star?',
        spokenPrompt:
            'The star is $target steps away, but the code moves $actual steps. Which fix works?',
        scene: ['🤖', '➡️', '$actual', '🐛', '⭐'],
        sceneLabel: 'TARGET $target • CODE MOVES $actual',
        choices: [for (final choice in choices) _AdventureChoice(choice)],
        correctIndex: choices.indexOf(answer),
        hint: 'Compare the target distance with the coded distance.',
        explanation: '$answer fixes the code!',
      );
    }
    final commands = <String>{
      'MOVE $target',
      'MOVE ${target + 1}',
      'MOVE ${target - 1}'
    }.toList()
      ..shuffle(math.Random(level * 539 + round));
    return _AdventureRound(
      skill: 'Sequence movement commands',
      prompt: 'Which command reaches the star?',
      spokenPrompt:
          'The star is $target spaces ahead. Choose the exact move command.',
      scene: ['🤖', for (var i = 0; i < math.min(target, 7); i++) '▫️', '⭐'],
      sceneLabel: '$target SPACES FORWARD',
      choices: [for (final command in commands) _AdventureChoice(command)],
      correctIndex: commands.indexOf('MOVE $target'),
      hint: 'Count every space between the robot and star.',
      explanation: 'MOVE $target reaches the star exactly!',
    );
  }

  static _AdventureRound _science(int level, int round) {
    final question =
        _scienceQuestions[(level * 5 + round * 7) % _scienceQuestions.length];
    final choices = <String>[
      question.answer,
      question.distractorOne,
      question.distractorTwo,
    ]..shuffle(math.Random(level * 557 + round));
    return _AdventureRound(
      skill: question.skill,
      prompt: question.prompt,
      spokenPrompt: question.spokenPrompt,
      scene: [question.emoji, '🧪', '💡'],
      sceneLabel: question.sceneLabel.toUpperCase(),
      choices: [for (final choice in choices) _AdventureChoice(choice)],
      correctIndex: choices.indexOf(question.answer),
      hint: question.hint,
      explanation: question.explanation,
    );
  }

  static _AdventureRound _map(int level, int round) {
    final coordinateMode = level > 18 && (level + round).isEven;
    final distanceMode = level > 35 && !coordinateMode && round.isOdd;
    if (distanceMode) {
      final first = 2 + ((level + round) % 7);
      final second = 2 + ((level * 2 + round) % 7);
      final answer = first + second;
      final numbers = _nearbyNumbers(answer, level * 577 + round, max: 20);
      return _AdventureRound(
        skill: 'Map distance and scale',
        prompt: 'How far is the full journey?',
        spokenPrompt:
            'Walk $first kilometres to the bridge, then $second kilometres to the camp. How far altogether?',
        scene: ['🏕️', '━', '$first km', '🌉', '━', '$second km', '🏕️'],
        sceneLabel: '$first km + $second km',
        choices: [for (final value in numbers) _AdventureChoice('$value km')],
        correctIndex: numbers.indexOf(answer),
        hint: 'Add both parts of the route.',
        explanation: 'The journey is $answer kilometres!',
      );
    }
    if (coordinateMode) {
      final row = 1 + ((level * 2 + round) % 3);
      final east = (level + round).isEven;
      final column = east ? (level + round) % 2 : 1 + ((level + round) % 2);
      final nextColumn = column + (east ? 1 : -1);
      final answer = '${String.fromCharCode(65 + nextColumn)}$row';
      final choices = <String>{
        answer,
        '${String.fromCharCode(65 + column)}${row == 3 ? 2 : row + 1}',
        '${String.fromCharCode(65 + ((nextColumn + 1) % 3))}$row',
      }.toList();
      while (choices.length < 3) {
        choices.add('${String.fromCharCode(65 + column)}${row == 1 ? 3 : 1}');
      }
      choices.shuffle(math.Random(level * 571 + round));
      return _AdventureRound(
        skill: 'Grid coordinates',
        prompt: 'Which square do you reach?',
        spokenPrompt:
            'Start at ${String.fromCharCode(65 + column)}$row and move one square ${east ? 'east' : 'west'}. Where do you land?',
        scene: ['🗺️', east ? '➡️' : '⬅️', '🎯'],
        sceneLabel:
            'START ${String.fromCharCode(65 + column)}$row • MOVE ${east ? 'EAST' : 'WEST'}',
        choices: [for (final value in choices) _AdventureChoice(value)],
        correctIndex: choices.indexOf(answer),
        hint: 'Letters move left and right; numbers stay on the same row.',
        explanation: 'You arrive at $answer!',
      );
    }
    final directionIndex = (level * 3 + round) % _directions.length;
    final direction = _directions[directionIndex];
    final candidates = _candidateIndexes(
      directionIndex,
      _directions.length,
      level,
      round,
    );
    return _AdventureRound(
      skill: 'Compass directions',
      prompt: 'Which direction does the arrow point?',
      spokenPrompt: 'Use the compass. Which direction does this arrow show?',
      scene: ['🧭', direction.arrow, '🗺️'],
      sceneLabel: 'NORTH IS AT THE TOP',
      choices: [
        for (final candidate in candidates)
          _AdventureChoice(
              _directions[candidate].name, _directions[candidate].arrow),
      ],
      correctIndex: candidates.indexOf(directionIndex),
      hint: 'North is up, south is down, east is right, and west is left.',
      explanation: 'The arrow points ${direction.name.toLowerCase()}!',
    );
  }

  static _AdventureRound _eco(int level, int round) {
    final question =
        _ecoQuestions[(level * 7 + round * 5) % _ecoQuestions.length];
    return _authoredReasoningRound(
      question,
      level,
      round,
      sceneIcon: '🏙️',
    );
  }

  static _AdventureRound _space(int level, int round) {
    final mode = (level + round) % 4;
    if (mode == 0) {
      final firstTenths = 5 + ((level * 3 + round) % 40);
      final secondTenths = 2 + ((level + round * 2) % 20);
      final answerTenths = firstTenths + secondTenths;
      final answer = (answerTenths / 10).toStringAsFixed(1);
      final choices = <String>{
        answer,
        ((answerTenths + 1) / 10).toStringAsFixed(1),
        ((answerTenths - 2) / 10).toStringAsFixed(1),
      }.toList()
        ..shuffle(math.Random(level * 601 + round));
      return _AdventureRound(
        skill: 'Decimal calculation',
        prompt: 'How much fuel altogether?',
        spokenPrompt:
            'Tank one has ${(firstTenths / 10).toStringAsFixed(1)} litres and tank two has ${(secondTenths / 10).toStringAsFixed(1)} litres. How much altogether?',
        scene: ['🚀', '⛽', '➕', '⛽'],
        sceneLabel:
            '${(firstTenths / 10).toStringAsFixed(1)} L + ${(secondTenths / 10).toStringAsFixed(1)} L',
        choices: [for (final value in choices) _AdventureChoice('$value L')],
        correctIndex: choices.indexOf(answer),
        hint: 'Line up the decimal points before adding.',
        explanation: 'The tanks hold $answer litres altogether!',
      );
    }
    if (mode == 1) {
      final known = 20 + (((level * 7 + round * 10) % 14) * 10);
      final answer = 180 - known;
      final choices = _nearbyNumbers(answer, level * 607 + round, max: 180);
      return _AdventureRound(
        skill: 'Angles on a straight line',
        prompt: 'Find the missing angle.',
        spokenPrompt:
            'Angles on a straight line total one hundred eighty degrees. One angle is $known degrees. Find the other.',
        scene: ['📐', '━', '$known°', '❓'],
        sceneLabel: '$known° + ? = 180°',
        choices: [for (final value in choices) _AdventureChoice('$value°')],
        correctIndex: choices.indexOf(answer),
        hint: 'Subtract $known from 180.',
        explanation: 'The missing angle is $answer degrees!',
      );
    }
    if (mode == 2) {
      final metres = 1 + ((level + round) % 9);
      final answer = metres * 100;
      final choices = _nearbyNumbers(answer, level * 613 + round, max: 1000);
      return _AdventureRound(
        skill: 'Metric measurement',
        prompt: '$metres metres equals how many centimetres?',
        spokenPrompt:
            'Convert $metres metres into centimetres for the spacecraft cable.',
        scene: ['🛰️', '📏', '🔌'],
        sceneLabel: '$metres m = ? cm',
        choices: [for (final value in choices) _AdventureChoice('$value cm')],
        correctIndex: choices.indexOf(answer),
        hint: 'One metre equals one hundred centimetres.',
        explanation: '$metres metres equals $answer centimetres!',
      );
    }
    final denominator = [2, 4, 5, 10][(level + round) % 4];
    final whole = denominator * (2 + ((level + round) % 5));
    final numerator = 1 + ((level * 2 + round) % (denominator - 1));
    final answer = whole ~/ denominator * numerator;
    final choices = _nearbyNumbers(answer, level * 617 + round, max: 100);
    return _AdventureRound(
      skill: 'Fractions of quantities',
      prompt: 'What is $numerator/$denominator of $whole?',
      spokenPrompt:
          'The mission uses $numerator over $denominator of $whole energy cells. How many cells is that?',
      scene: ['🔋', '$whole', '×', '$numerator/$denominator'],
      sceneLabel: '$numerator/$denominator OF $whole CELLS',
      choices: [for (final value in choices) _AdventureChoice('$value')],
      correctIndex: choices.indexOf(answer),
      hint: 'Divide $whole by $denominator, then multiply by $numerator.',
      explanation: '$numerator/$denominator of $whole is $answer!',
    );
  }

  static _AdventureRound _business(int level, int round) {
    final mode = (level + round) % 4;
    if (mode == 0) {
      final budget = 100 + (((level + round) % 5) * 50);
      final cost = 30 + (((level * 3 + round) % 7) * 10);
      final answer = budget - cost;
      final choices = _nearbyNumbers(answer, level * 631 + round, max: 500);
      return _moneyRound(
        skill: 'Budgeting',
        prompt: 'How much budget remains?',
        spoken:
            'The shop budget is $budget rupees and supplies cost $cost rupees. How much remains?',
        sceneLabel: '₹$budget BUDGET − ₹$cost COST',
        answer: answer,
        choices: choices,
        hint: 'Subtract the cost from the budget.',
        explanation: '₹$answer remains in the budget!',
      );
    }
    if (mode == 1) {
      final percent = [10, 20, 25, 50][(level + round) % 4];
      final price = percent == 25
          ? 40 * (1 + ((level + round) % 5))
          : 100 + (((level + round) % 5) * 100);
      final answer = price * percent ~/ 100;
      final choices = _nearbyNumbers(answer, level * 641 + round, max: 500);
      return _moneyRound(
        skill: 'Percentages and discounts',
        prompt: 'How much is the discount?',
        spoken:
            'An item costs $price rupees and has a $percent percent discount. How many rupees are taken off?',
        sceneLabel: '$percent% OF ₹$price',
        answer: answer,
        choices: choices,
        hint: percent == 50
            ? 'Fifty percent means half.'
            : percent == 25
                ? 'Twenty-five percent means one quarter.'
                : 'Find one tenth first, then scale it.',
        explanation: 'The discount is ₹$answer!',
      );
    }
    if (mode == 2) {
      final cost = 50 + (((level + round) % 6) * 20);
      final profit = 10 + (((level * 2 + round) % 5) * 10);
      final selling = cost + profit;
      final choices = _nearbyNumbers(profit, level * 643 + round, max: 300);
      return _moneyRound(
        skill: 'Cost, revenue, and profit',
        prompt: 'What is the profit?',
        spoken:
            'A product costs $cost rupees and sells for $selling rupees. What is the profit?',
        sceneLabel: 'SELL ₹$selling − COST ₹$cost',
        answer: profit,
        choices: choices,
        hint: 'Profit equals selling price minus cost price.',
        explanation: 'The profit is ₹$profit!',
      );
    }
    final quantity = 2 + ((level + round) % 8);
    final unitPrice = 5 * (1 + ((level * 2 + round) % 6));
    final answer = quantity * unitPrice;
    final choices = _nearbyNumbers(answer, level * 647 + round, max: 500);
    return _moneyRound(
      skill: 'Unit price and total cost',
      prompt: 'What is the total price?',
      spoken:
          '$quantity notebooks cost $unitPrice rupees each. What is the total price?',
      sceneLabel: '$quantity × ₹$unitPrice EACH',
      answer: answer,
      choices: choices,
      hint: 'Multiply quantity by price per item.',
      explanation: 'The total price is ₹$answer!',
    );
  }

  static _AdventureRound _mystery(int level, int round) {
    final question =
        _mysteryQuestions[(level * 5 + round * 7) % _mysteryQuestions.length];
    return _authoredReasoningRound(
      question,
      level,
      round,
      sceneIcon: '🔬',
    );
  }

  static _AdventureRound _news(int level, int round) {
    final question =
        _newsQuestions[(level * 3 + round * 5) % _newsQuestions.length];
    return _authoredReasoningRound(
      question,
      level,
      round,
      sceneIcon: '📰',
    );
  }

  static _AdventureRound _algorithm(int level, int round) {
    final mode = (level + round) % 4;
    if (mode == 0) {
      final outer = 2 + ((level + round) % 4);
      final inner = 2 + ((level * 2 + round) % 3);
      final moves = 1 + ((level + round * 2) % 3);
      final answer = outer * inner * moves;
      final choices = _nearbyNumbers(answer, level * 661 + round, max: 60);
      return _AdventureRound(
        skill: 'Nested loops',
        prompt: 'How many moves run?',
        spokenPrompt:
            'An outer loop repeats $outer times. Inside it, a loop repeats $inner times and moves $moves steps. How many moves altogether?',
        scene: ['🤖', '🔁', '$outer', '🔁', '$inner', '➡️', '$moves'],
        sceneLabel: 'REPEAT $outer [ REPEAT $inner [ MOVE $moves ] ]',
        choices: [for (final value in choices) _AdventureChoice('$value')],
        correctIndex: choices.indexOf(answer),
        hint: 'Multiply outer repeats, inner repeats, and moves.',
        explanation: 'The algorithm runs $answer moves!',
      );
    }
    if (mode == 1) {
      final energy = 20 + ((level * 7 + round * 5) % 80);
      const threshold = 50;
      final answer = energy >= threshold ? 'OPEN GATE' : 'CHARGE BATTERY';
      final choices = <String>{answer, 'TURN AROUND', 'DELETE PROGRAM'}.toList()
        ..shuffle(math.Random(level * 673 + round));
      return _AdventureRound(
        skill: 'Conditions and branching',
        prompt: 'Which branch runs?',
        spokenPrompt:
            'If energy is at least $threshold, open the gate. Otherwise charge the battery. Energy is $energy. What happens?',
        scene: ['🔋', '$energy', '⚖️', '$threshold', '🚪'],
        sceneLabel: 'IF ENERGY ≥ $threshold',
        choices: [for (final value in choices) _AdventureChoice(value)],
        correctIndex: choices.indexOf(answer),
        hint: 'Compare $energy with $threshold before choosing the branch.',
        explanation: 'The program will ${answer.toLowerCase()}!',
      );
    }
    if (mode == 2) {
      const answer = 'REPEAT 5 [MOVE 1]';
      final choices = <String>{
        answer,
        'MOVE 1, MOVE 1, MOVE 1, MOVE 1, MOVE 1',
        'REPEAT 5 [TURN RIGHT]',
      }.toList()
        ..shuffle(math.Random(level * 677 + round));
      return _AdventureRound(
        skill: 'Algorithm efficiency',
        prompt: 'Which correct code is shortest?',
        spokenPrompt:
            'The robot must move forward five times. Choose the correct code with the fewest instructions.',
        scene: ['🤖', '➡️', '➡️', '➡️', '➡️', '➡️'],
        sceneLabel: 'REACH THE STAR IN 5 MOVES',
        choices: [for (final value in choices) _AdventureChoice(value)],
        correctIndex: choices.indexOf(answer),
        hint: 'A loop can replace repeated identical instructions.',
        explanation: 'The repeat loop is correct and compact!',
      );
    }
    final target = 8 + ((level + round) % 8);
    final actual = target - 1;
    const answer = 'CHANGE < TO <=';
    final choices = <String>{answer, 'REMOVE THE LOOP', 'CHANGE + TO −'}
        .toList()
      ..shuffle(math.Random(level * 683 + round));
    return _AdventureRound(
      skill: 'Boundary-condition debugging',
      prompt: 'How do you fix the missing last step?',
      spokenPrompt:
          'The loop stops at $actual but must reach $target. The condition uses less than target. Which fix includes the final value?',
      scene: ['🐛', '$actual', '➡️', '$target', '🎯'],
      sceneLabel: 'WHILE POSITION < $target',
      choices: [for (final value in choices) _AdventureChoice(value)],
      correctIndex: choices.indexOf(answer),
      hint: 'Less than or equal includes the boundary value.',
      explanation: 'Using less than or equal includes the final step!',
    );
  }

  static _AdventureRound _moneyRound({
    required String skill,
    required String prompt,
    required String spoken,
    required String sceneLabel,
    required int answer,
    required List<int> choices,
    required String hint,
    required String explanation,
  }) {
    return _AdventureRound(
      skill: skill,
      prompt: prompt,
      spokenPrompt: spoken,
      scene: ['🛒', '🪙', '🧮'],
      sceneLabel: sceneLabel,
      choices: [for (final value in choices) _AdventureChoice('₹$value')],
      correctIndex: choices.indexOf(answer),
      hint: hint,
      explanation: explanation,
    );
  }

  static _AdventureRound _authoredReasoningRound(
    _ScienceQuestion question,
    int level,
    int round, {
    required String sceneIcon,
  }) {
    final choices = <String>[
      question.answer,
      question.distractorOne,
      question.distractorTwo,
    ]..shuffle(math.Random(level * 691 + round));
    return _AdventureRound(
      skill: question.skill,
      prompt: question.prompt,
      spokenPrompt: question.spokenPrompt,
      scene: [question.emoji, sceneIcon, '💡'],
      sceneLabel: question.sceneLabel.toUpperCase(),
      choices: [for (final value in choices) _AdventureChoice(value)],
      correctIndex: choices.indexOf(question.answer),
      hint: question.hint,
      explanation: question.explanation,
    );
  }

  static List<int> _nearbyNumbers(int answer, int seed, {required int max}) {
    final values = <int>{answer};
    var offset = 1;
    while (values.length < 3) {
      values.add((answer + (offset.isOdd ? offset : -offset)).clamp(0, max));
      offset++;
    }
    return values.toList()..shuffle(math.Random(seed));
  }

  static List<String> _letterChoices(String answer, int seed) {
    final values = <String>{answer};
    final base = answer.codeUnitAt(0) - 65;
    var offset = 1;
    while (values.length < 3) {
      values.add(String.fromCharCode(65 + ((base + offset * 7) % 26)));
      offset++;
    }
    return values.toList()..shuffle(math.Random(seed));
  }

  static String _clockEmoji(int hour, bool halfHour) {
    final index = (hour - 1) % 12;
    return halfHour ? _halfHourClocks[index] : _hourClocks[index];
  }

  static String _habitatEmoji(String habitat) => switch (habitat) {
        'ocean' => '🌊',
        'pond' => '🌿',
        'forest' => '🌲',
        'desert' => '🏜️',
        'farm' => '🐄',
        'garden' => '🌻',
        'polar ice' => '🧳',
        _ => '🌍',
      };

  static List<int> _candidateIndexes(
    int target,
    int length,
    int level,
    int round, {
    int count = 3,
  }) {
    final values = <int>{target};
    var cursor = (target + level + round + 1) % length;
    while (values.length < math.min(count, length)) {
      values.add(cursor);
      cursor = (cursor + 1) % length;
    }
    final result = values.toList()
      ..shuffle(math.Random(level * 997 + round * 37 + target));
    return result;
  }

  static _Place _place(String id) =>
      _places.firstWhere((place) => place.id == id);
}

class _SoundItem {
  const _SoundItem(this.emoji, this.animal, this.sound);
  final String emoji;
  final String animal;
  final String sound;
}

const _sounds = <_SoundItem>[
  _SoundItem('🐄', 'cow', 'moo'),
  _SoundItem('🐶', 'dog', 'woof'),
  _SoundItem('🐱', 'cat', 'meow'),
  _SoundItem('🦁', 'lion', 'roar'),
  _SoundItem('🐑', 'sheep', 'baa'),
  _SoundItem('🐷', 'pig', 'oink'),
  _SoundItem('🐸', 'frog', 'ribbit'),
  _SoundItem('🐔', 'chicken', 'cluck'),
  _SoundItem('🦆', 'duck', 'quack'),
  _SoundItem('🐍', 'snake', 'hiss'),
  _SoundItem('🐝', 'bee', 'buzz'),
  _SoundItem('🦉', 'owl', 'hoot'),
  _SoundItem('🐴', 'horse', 'neigh'),
  _SoundItem('🐒', 'monkey', 'chatter'),
  _SoundItem('🐦', 'bird', 'tweet'),
];

class _StoryItem {
  const _StoryItem(
    this.first,
    this.firstLabel,
    this.second,
    this.secondLabel,
    this.third,
    this.answer,
  );
  final String first;
  final String firstLabel;
  final String second;
  final String secondLabel;
  final String third;
  final String answer;
}

const _stories = <_StoryItem>[
  _StoryItem('🌱', 'plant a seed', '💧', 'water it', '🌻', 'A flower grows'),
  _StoryItem(
      '🥚', 'an egg rests', '🐣', 'a chick hatches', '🐔', 'The chicken grows'),
  _StoryItem('🌧️', 'rain falls', '☂️', 'we use an umbrella', '🌈',
      'A rainbow appears'),
  _StoryItem('🛌', 'wake up', '🪥', 'brush teeth', '🏫', 'Go to school'),
  _StoryItem(
      '🥣', 'mix ingredients', '🔥', 'bake them', '🎂', 'The cake is ready'),
  _StoryItem('🧼', 'wash hands', '🧻', 'dry hands', '🍽️', 'Eat the meal'),
  _StoryItem(
      '📖', 'open a book', '👀', 'read the story', '💡', 'Learn an idea'),
  _StoryItem(
      '🌙', 'night arrives', '👕', 'put on pajamas', '😴', 'Go to sleep'),
  _StoryItem('🎨', 'dip the brush', '🖼️', 'paint a picture', '😊',
      'Share the artwork'),
  _StoryItem(
      '🧸', 'play with toys', '🧺', 'put toys away', '✨', 'The room is tidy'),
];

class _WordItem {
  const _WordItem(this.emoji, this.word, this.letter);
  final String emoji;
  final String word;
  final String letter;
}

const _words = <_WordItem>[
  _WordItem('🍎', 'apple', 'A'),
  _WordItem('🍌', 'banana', 'B'),
  _WordItem('🐱', 'cat', 'C'),
  _WordItem('🐶', 'dog', 'D'),
  _WordItem('🐘', 'elephant', 'E'),
  _WordItem('🐟', 'fish', 'F'),
  _WordItem('🍇', 'grape', 'G'),
  _WordItem('🏠', 'house', 'H'),
  _WordItem('🍨', 'ice cream', 'I'),
  _WordItem('🥤', 'juice', 'J'),
  _WordItem('🪁', 'kite', 'K'),
  _WordItem('🦁', 'lion', 'L'),
  _WordItem('🌕', 'moon', 'M'),
  _WordItem('🪆', 'nest', 'N'),
  _WordItem('🍊', 'orange', 'O'),
  _WordItem('🐧', 'penguin', 'P'),
  _WordItem('👸', 'queen', 'Q'),
  _WordItem('🌈', 'rainbow', 'R'),
  _WordItem('⭐', 'star', 'S'),
  _WordItem('🌳', 'tree', 'T'),
  _WordItem('☔', 'umbrella', 'U'),
  _WordItem('🎻', 'violin', 'V'),
  _WordItem('🐋', 'whale', 'W'),
  _WordItem('🪇', 'xylophone', 'X'),
  _WordItem('🪀', 'yo-yo', 'Y'),
  _WordItem('🦓', 'zebra', 'Z'),
];

class _Place {
  const _Place(this.id, this.label, this.emoji);
  final String id;
  final String label;
  final String emoji;
}

const _places = <_Place>[
  _Place('toybox', 'TOY BOX', '🧺'),
  _Place('wardrobe', 'WARDROBE', '👕'),
  _Place('kitchen', 'KITCHEN', '🍳'),
  _Place('bathroom', 'BATHROOM', '🚿'),
  _Place('books', 'BOOKSHELF', '📚'),
];

class _TidyItem {
  const _TidyItem(this.emoji, this.name, this.place);
  final String emoji;
  final String name;
  final String place;
}

const _tidyItems = <_TidyItem>[
  _TidyItem('⚽', 'ball', 'toybox'),
  _TidyItem('🧸', 'teddy', 'toybox'),
  _TidyItem('🧩', 'puzzle', 'toybox'),
  _TidyItem('🧱', 'blocks', 'toybox'),
  _TidyItem('👕', 'shirt', 'wardrobe'),
  _TidyItem('🧦', 'socks', 'wardrobe'),
  _TidyItem('👗', 'dress', 'wardrobe'),
  _TidyItem('🧢', 'cap', 'wardrobe'),
  _TidyItem('🥄', 'spoon', 'kitchen'),
  _TidyItem('🍽️', 'plate', 'kitchen'),
  _TidyItem('🥛', 'cup', 'kitchen'),
  _TidyItem('🥣', 'bowl', 'kitchen'),
  _TidyItem('🪥', 'toothbrush', 'bathroom'),
  _TidyItem('🧼', 'soap', 'bathroom'),
  _TidyItem('🧻', 'towel', 'bathroom'),
  _TidyItem('🧴', 'shampoo', 'bathroom'),
  _TidyItem('📕', 'story book', 'books'),
  _TidyItem('📘', 'blue book', 'books'),
  _TidyItem('📗', 'green book', 'books'),
  _TidyItem('📙', 'orange book', 'books'),
];

class _MarketItem {
  const _MarketItem(this.emoji, this.name);
  final String emoji;
  final String name;
}

const _marketItems = <_MarketItem>[
  _MarketItem('🍎', 'apple'),
  _MarketItem('🍌', 'banana'),
  _MarketItem('🥕', 'carrot'),
  _MarketItem('🧸', 'teddy'),
  _MarketItem('⚽', 'ball'),
  _MarketItem('✏️', 'pencil'),
  _MarketItem('📕', 'book'),
  _MarketItem('🪁', 'kite'),
  _MarketItem('🥪', 'sandwich'),
  _MarketItem('🍹', 'juice'),
  _MarketItem('🍪', 'cookie'),
  _MarketItem('🧩', 'puzzle'),
];

class _SentenceItem {
  const _SentenceItem(
    this.emoji,
    this.before,
    this.answer,
    this.after,
    this.distractorOne,
    this.distractorTwo,
    this.mark,
  );
  final String emoji;
  final String before;
  final String answer;
  final String after;
  final String distractorOne;
  final String distractorTwo;
  final String mark;

  String get completeSentence => '$before $answer $after';
}

const _sentences = <_SentenceItem>[
  _SentenceItem('🐱', 'The cat', 'sits', 'on the mat', 'sit', 'sleep', '.'),
  _SentenceItem('🐶', 'The dog', 'runs', 'in the park', 'run', 'reads', '.'),
  _SentenceItem('🐦', 'A bird', 'flies', 'in the sky', 'fly', 'swims', '.'),
  _SentenceItem('🐟', 'The fish', 'swims', 'in water', 'swim', 'walks', '.'),
  _SentenceItem('🌙', 'The moon', 'shines', 'at night', 'shine', 'eats', '.'),
  _SentenceItem('👧', 'Mia', 'reads', 'a story', 'read', 'jumps', '.'),
  _SentenceItem('👦', 'Sam', 'kicks', 'the ball', 'kick', 'drinks', '.'),
  _SentenceItem(
      '🐝', 'The bees', 'buzz', 'near flowers', 'buzzes', 'roar', '.'),
  _SentenceItem('🌧️', 'Why is it', 'raining', 'today', 'rain', 'yellow', '?'),
  _SentenceItem('🎂', 'What a', 'wonderful', 'cake', 'wonder', 'slowly', '!'),
  _SentenceItem('🚲', 'Can you', 'ride', 'a bicycle', 'rides', 'blue', '?'),
  _SentenceItem(
      '🌈', 'Look at the', 'bright', 'rainbow', 'brightness', 'swim', '!'),
  _SentenceItem('👫', 'The children', 'play', 'together', 'plays', 'red', '.'),
  _SentenceItem('🌱', 'A seed', 'grows', 'into a plant', 'grow', 'sings', '.'),
  _SentenceItem(
      '🐘', 'The elephant', 'has', 'a long trunk', 'have', 'are', '.'),
];

class _DailyTime {
  const _DailyTime(
    this.clock,
    this.time,
    this.spokenTime,
    this.emoji,
    this.activity,
  );
  final String clock;
  final String time;
  final String spokenTime;
  final String emoji;
  final String activity;
}

const _dailyTimes = <_DailyTime>[
  _DailyTime('🕡', '6:30', 'half past six', '🌅', 'WAKE UP'),
  _DailyTime('🕢', '7:30', 'half past seven', '🥣', 'BREAKFAST'),
  _DailyTime('🕘', '9:00', 'nine o clock', '🏫', 'SCHOOL'),
  _DailyTime('🕛', '12:00', 'twelve o clock', '🍛', 'LUNCH'),
  _DailyTime('🕞', '3:00', 'three o clock', '⚽', 'PLAY TIME'),
  _DailyTime('🕡', '6:00', 'six o clock', '🍽️', 'DINNER'),
  _DailyTime('🕣', '8:30', 'half past eight', '🛌', 'BEDTIME'),
];

const _hourClocks = <String>[
  '🕐',
  '🕑',
  '🕒',
  '🕓',
  '🕔',
  '🕕',
  '🕖',
  '🕗',
  '🕘',
  '🕙',
  '🕚',
  '🕛',
];

const _halfHourClocks = <String>[
  '🕜',
  '🕝',
  '🕞',
  '🕟',
  '🕠',
  '🕡',
  '🕢',
  '🕣',
  '🕤',
  '🕥',
  '🕦',
  '🕧',
];

class _NatureItem {
  const _NatureItem(
    this.emoji,
    this.name,
    this.clue,
    this.habitat,
  );
  final String emoji;
  final String name;
  final String clue;
  final String habitat;
}

const _natureItems = <_NatureItem>[
  _NatureItem(
      '🐫', 'camel', 'I store fat in my hump and need little water', 'desert'),
  _NatureItem('🐋', 'whale', 'I am a huge mammal that breathes air', 'ocean'),
  _NatureItem('🐸', 'frog', 'I have moist skin and can hop and swim', 'pond'),
  _NatureItem('🦉', 'owl', 'I hunt at night and have large eyes', 'forest'),
  _NatureItem('🐄', 'cow', 'I eat grass and give milk', 'farm'),
  _NatureItem(
      '🐝', 'bee', 'I collect nectar and help flowers make seeds', 'garden'),
  _NatureItem(
      '🐧', 'penguin', 'I am a bird that swims but cannot fly', 'polar ice'),
  _NatureItem('🐠', 'fish', 'I breathe with gills and have fins', 'ocean'),
  _NatureItem('🦋', 'butterfly', 'I begin life as a caterpillar', 'garden'),
  _NatureItem('🐒', 'monkey', 'I climb trees and use my hands', 'forest'),
  _NatureItem(
      '🦆', 'duck', 'I have webbed feet and waterproof feathers', 'pond'),
  _NatureItem('🐔', 'chicken', 'I have feathers and lay eggs', 'farm'),
  _NatureItem('🌵', 'cactus', 'My thick stem stores water', 'desert'),
  _NatureItem(
      '🌻', 'sunflower', 'I turn toward sunlight and make seeds', 'garden'),
];

class _ShapeItem {
  const _ShapeItem(this.emoji, this.name, this.sides, this.description);
  final String emoji;
  final String name;
  final int sides;
  final String description;
}

const _shapes = <_ShapeItem>[
  _ShapeItem('🔴', 'circle', 0, 'A circle is round and has no straight sides.'),
  _ShapeItem('🟦', 'square', 4, 'A square has four equal straight sides.'),
  _ShapeItem('🔺', 'triangle', 3, 'A triangle has three straight sides.'),
  _ShapeItem('🟩', 'rectangle', 4,
      'A rectangle has four sides and opposite sides match.'),
  _ShapeItem('⭐', 'star', 10, 'A five-point star has ten outside edges.'),
  _ShapeItem('🔷', 'diamond', 4, 'A diamond looks like a tilted square.'),
  _ShapeItem('⬡', 'hexagon', 6, 'A hexagon has six straight sides.'),
  _ShapeItem('🫥', 'oval', 0, 'An oval is round but stretched longer.'),
];

class _GrammarQuestion {
  const _GrammarQuestion({
    required this.emoji,
    required this.skill,
    required this.sentence,
    required this.prompt,
    required this.spokenPrompt,
    required this.answer,
    required this.distractorOne,
    required this.distractorTwo,
    required this.hint,
    required this.explanation,
  });
  final String emoji;
  final String skill;
  final String sentence;
  final String prompt;
  final String spokenPrompt;
  final String answer;
  final String distractorOne;
  final String distractorTwo;
  final String hint;
  final String explanation;
}

const _grammarQuestions = <_GrammarQuestion>[
  _GrammarQuestion(
      emoji: '🐶',
      skill: 'Parts of speech',
      sentence: 'The playful dog barked',
      prompt: 'Which word is the noun?',
      spokenPrompt:
          'In the sentence, the playful dog barked, which word names an animal?',
      answer: 'DOG',
      distractorOne: 'PLAYFUL',
      distractorTwo: 'BARKED',
      hint: 'A noun names a person, place, animal, or thing.',
      explanation: 'Dog is the noun.'),
  _GrammarQuestion(
      emoji: '🏃',
      skill: 'Parts of speech',
      sentence: 'Mia runs quickly',
      prompt: 'Which word is the verb?',
      spokenPrompt: 'In Mia runs quickly, which word shows the action?',
      answer: 'RUNS',
      distractorOne: 'MIA',
      distractorTwo: 'QUICKLY',
      hint: 'A verb shows an action or state.',
      explanation: 'Runs is the action verb.'),
  _GrammarQuestion(
      emoji: '🌺',
      skill: 'Adjectives',
      sentence: 'The red flower bloomed',
      prompt: 'Which word describes the flower?',
      spokenPrompt: 'Which word tells us more about the flower?',
      answer: 'RED',
      distractorOne: 'FLOWER',
      distractorTwo: 'BLOOMED',
      hint: 'An adjective describes a noun.',
      explanation: 'Red is the describing adjective.'),
  _GrammarQuestion(
      emoji: '🐢',
      skill: 'Adverbs',
      sentence: 'The turtle walked slowly',
      prompt: 'Which word tells how it walked?',
      spokenPrompt: 'Which word tells how the turtle walked?',
      answer: 'SLOWLY',
      distractorOne: 'TURTLE',
      distractorTwo: 'WALKED',
      hint: 'Many adverbs tell how an action happens.',
      explanation: 'Slowly tells how it walked.'),
  _GrammarQuestion(
      emoji: '👧',
      skill: 'Pronouns',
      sentence: 'Mia has a book. She reads it.',
      prompt: 'Which word replaces Mia?',
      spokenPrompt: 'Which pronoun replaces the name Mia?',
      answer: 'SHE',
      distractorOne: 'BOOK',
      distractorTwo: 'IT',
      hint: 'Use a pronoun instead of repeating a name.',
      explanation: 'She replaces Mia.'),
  _GrammarQuestion(
      emoji: '👦',
      skill: 'Subject-verb agreement',
      sentence: 'Sam ___ to school',
      prompt: 'Choose the correct verb.',
      spokenPrompt: 'Sam, blank, to school. Which verb agrees with Sam?',
      answer: 'WALKS',
      distractorOne: 'WALK',
      distractorTwo: 'WALKING',
      hint: 'A single person often takes a verb ending in s.',
      explanation: 'Sam walks to school.'),
  _GrammarQuestion(
      emoji: '👫',
      skill: 'Subject-verb agreement',
      sentence: 'The children ___ outside',
      prompt: 'Choose the correct verb.',
      spokenPrompt:
          'The children, blank, outside. Which verb agrees with children?',
      answer: 'PLAY',
      distractorOne: 'PLAYS',
      distractorTwo: 'PLAYING',
      hint: 'A plural subject uses play, without s.',
      explanation: 'The children play outside.'),
  _GrammarQuestion(
      emoji: '⏪',
      skill: 'Past tense',
      sentence: 'Yesterday we ___ football',
      prompt: 'Choose the past-tense verb.',
      spokenPrompt: 'Yesterday we blank football. Which word shows the past?',
      answer: 'PLAYED',
      distractorOne: 'PLAY',
      distractorTwo: 'WILL PLAY',
      hint: 'Yesterday tells us the action already happened.',
      explanation: 'Played is past tense.'),
  _GrammarQuestion(
      emoji: '⏩',
      skill: 'Future tense',
      sentence: 'Tomorrow I ___ my aunt',
      prompt: 'Choose the future-tense verb.',
      spokenPrompt: 'Tomorrow I blank my aunt. Which phrase shows the future?',
      answer: 'WILL VISIT',
      distractorOne: 'VISITED',
      distractorTwo: 'VISIT',
      hint: 'Will can show an action that has not happened yet.',
      explanation: 'Will visit is future tense.'),
  _GrammarQuestion(
      emoji: '❓',
      skill: 'Sentence types',
      sentence: 'Where is my pencil',
      prompt: 'Which punctuation mark belongs?',
      spokenPrompt: 'Where is my pencil? Which ending mark belongs?',
      answer: '?',
      distractorOne: '.',
      distractorTwo: '!',
      hint: 'A direct question ends with a question mark.',
      explanation: 'The sentence needs a question mark.'),
  _GrammarQuestion(
      emoji: '🎉',
      skill: 'Sentence types',
      sentence: 'What an amazing surprise',
      prompt: 'Which punctuation mark belongs?',
      spokenPrompt:
          'What an amazing surprise! Which ending mark shows excitement?',
      answer: '!',
      distractorOne: '.',
      distractorTwo: '?',
      hint: 'Strong excitement can end with an exclamation mark.',
      explanation: 'The sentence needs an exclamation mark.'),
  _GrammarQuestion(
      emoji: '📍',
      skill: 'Prepositions',
      sentence: 'The ball is under the table',
      prompt: 'Which word shows position?',
      spokenPrompt: 'Which word tells where the ball is?',
      answer: 'UNDER',
      distractorOne: 'BALL',
      distractorTwo: 'TABLE',
      hint: 'A preposition can show position.',
      explanation: 'Under shows the position.'),
  _GrammarQuestion(
      emoji: '🔗',
      skill: 'Conjunctions',
      sentence: 'I like apples ___ bananas',
      prompt: 'Which joining word fits?',
      spokenPrompt: 'I like apples, blank, bananas. Choose the joining word.',
      answer: 'AND',
      distractorOne: 'BUT',
      distractorTwo: 'BECAUSE',
      hint: 'Use and to join two things you like.',
      explanation: 'And joins apples and bananas.'),
  _GrammarQuestion(
      emoji: '🌧️',
      skill: 'Conjunctions',
      sentence: 'I took an umbrella ___ it was raining',
      prompt: 'Which joining word explains why?',
      spokenPrompt:
          'I took an umbrella, blank, it was raining. Which word gives the reason?',
      answer: 'BECAUSE',
      distractorOne: 'AND',
      distractorTwo: 'OR',
      hint: 'Because introduces a reason.',
      explanation: 'Because explains the reason.'),
  _GrammarQuestion(
      emoji: '📚',
      skill: 'Plural nouns',
      sentence: 'One story, two ___',
      prompt: 'Choose the correct plural.',
      spokenPrompt: 'One story, two what? Choose the plural form.',
      answer: 'STORIES',
      distractorOne: 'STORYS',
      distractorTwo: 'STORY',
      hint: 'Change consonant y to ies.',
      explanation: 'The plural of story is stories.'),
];

class _ScienceQuestion {
  const _ScienceQuestion({
    required this.emoji,
    required this.skill,
    required this.sceneLabel,
    required this.prompt,
    required this.spokenPrompt,
    required this.answer,
    required this.distractorOne,
    required this.distractorTwo,
    required this.hint,
    required this.explanation,
  });
  final String emoji;
  final String skill;
  final String sceneLabel;
  final String prompt;
  final String spokenPrompt;
  final String answer;
  final String distractorOne;
  final String distractorTwo;
  final String hint;
  final String explanation;
}

const _scienceQuestions = <_ScienceQuestion>[
  _ScienceQuestion(
      emoji: '🧊',
      skill: 'States of matter',
      sceneLabel: 'Ice warms in the sun',
      prompt: 'What change happens?',
      spokenPrompt: 'Ice warms in the sun. What happens to it?',
      answer: 'IT MELTS',
      distractorOne: 'IT FREEZES',
      distractorTwo: 'IT GROWS',
      hint: 'Heating changes solid ice into liquid water.',
      explanation: 'The ice melts into water.'),
  _ScienceQuestion(
      emoji: '💧',
      skill: 'States of matter',
      sceneLabel: 'Water goes into a freezer',
      prompt: 'What change happens?',
      spokenPrompt: 'Liquid water is placed in a freezer. What happens?',
      answer: 'IT FREEZES',
      distractorOne: 'IT MELTS',
      distractorTwo: 'IT BURNS',
      hint: 'Cooling water enough makes it solid.',
      explanation: 'The water freezes into ice.'),
  _ScienceQuestion(
      emoji: '💨',
      skill: 'States of matter',
      sceneLabel: 'Steam spreads through the air',
      prompt: 'Which state is steam?',
      spokenPrompt:
          'Steam spreads and fills space. Which state of matter is it?',
      answer: 'GAS',
      distractorOne: 'SOLID',
      distractorTwo: 'LIQUID',
      hint: 'A gas spreads to fill its container.',
      explanation: 'Steam is water vapour, a gas.'),
  _ScienceQuestion(
      emoji: '🧲',
      skill: 'Forces and magnets',
      sceneLabel: 'A magnet nears an iron nail',
      prompt: 'What will happen?',
      spokenPrompt: 'A magnet moves close to an iron nail. What will happen?',
      answer: 'THE NAIL IS ATTRACTED',
      distractorOne: 'THE NAIL MELTS',
      distractorTwo: 'NOTHING CAN MOVE',
      hint: 'Iron is attracted to a magnet.',
      explanation: 'The magnet attracts the iron nail.'),
  _ScienceQuestion(
      emoji: '🛤️',
      skill: 'Forces and motion',
      sceneLabel: 'A ball rolls down a slope',
      prompt: 'Which force pulls it downward?',
      spokenPrompt: 'Which force pulls the rolling ball toward Earth?',
      answer: 'GRAVITY',
      distractorOne: 'MAGNETISM',
      distractorTwo: 'ELECTRICITY',
      hint: 'This force pulls objects toward Earth.',
      explanation: 'Gravity pulls the ball downward.'),
  _ScienceQuestion(
      emoji: '💡',
      skill: 'Electric circuits',
      sceneLabel: 'Battery, wires and bulb form a closed loop',
      prompt: 'Why does the bulb light?',
      spokenPrompt: 'Why does a bulb light in a complete circuit?',
      answer: 'THE CIRCUIT IS CLOSED',
      distractorOne: 'THE WIRE IS CUT',
      distractorTwo: 'THERE IS NO BATTERY',
      hint: 'Electric current needs an unbroken path.',
      explanation: 'A closed circuit lets current flow.'),
  _ScienceQuestion(
      emoji: '🪝',
      skill: 'Simple machines',
      sceneLabel: 'A ramp helps load a heavy box',
      prompt: 'What simple machine is the ramp?',
      spokenPrompt: 'A ramp makes lifting easier. What simple machine is it?',
      answer: 'INCLINED PLANE',
      distractorOne: 'PULLEY',
      distractorTwo: 'LEVER',
      hint: 'It is a flat surface set at an angle.',
      explanation: 'A ramp is an inclined plane.'),
  _ScienceQuestion(
      emoji: '⚖️',
      skill: 'Simple machines',
      sceneLabel: 'A seesaw turns around a middle point',
      prompt: 'What simple machine is it?',
      spokenPrompt: 'A seesaw moves around a fixed middle point. What is it?',
      answer: 'LEVER',
      distractorOne: 'WHEEL',
      distractorTwo: 'SCREW',
      hint: 'A lever pivots around a fulcrum.',
      explanation: 'A seesaw is a lever.'),
  _ScienceQuestion(
      emoji: '🌱',
      skill: 'Plant science',
      sceneLabel: 'A plant stands near a sunny window',
      prompt: 'Why does it need light?',
      spokenPrompt: 'Why does a green plant need sunlight?',
      answer: 'TO MAKE FOOD',
      distractorOne: 'TO MAKE NOISE',
      distractorTwo: 'TO GROW METAL',
      hint: 'Plants use light during photosynthesis.',
      explanation: 'Plants use sunlight to make food.'),
  _ScienceQuestion(
      emoji: '🫗',
      skill: 'Human body',
      sceneLabel: 'We breathe in and out',
      prompt: 'Which organs help us breathe?',
      spokenPrompt: 'Which organs take oxygen from the air?',
      answer: 'LUNGS',
      distractorOne: 'BONES',
      distractorTwo: 'TEETH',
      hint: 'These organs are inside the chest.',
      explanation: 'Our lungs help us breathe.'),
  _ScienceQuestion(
      emoji: '🦴',
      skill: 'Human body',
      sceneLabel: 'The skeleton supports the body',
      prompt: 'What protects the brain?',
      spokenPrompt: 'Which bone structure protects the brain?',
      answer: 'SKULL',
      distractorOne: 'RIBS',
      distractorTwo: 'SPINE',
      hint: 'It is the hard case around the head.',
      explanation: 'The skull protects the brain.'),
  _ScienceQuestion(
      emoji: '🌑',
      skill: 'Earth and space',
      sceneLabel: 'The Moon seems bright at night',
      prompt: 'Where does moonlight come from?',
      spokenPrompt: 'The Moon does not make its own light. Why can we see it?',
      answer: 'IT REFLECTS SUNLIGHT',
      distractorOne: 'IT IS ON FIRE',
      distractorTwo: 'STARS LIGHT IT',
      hint: 'Light from the Sun bounces off the Moon.',
      explanation: 'The Moon reflects sunlight.'),
  _ScienceQuestion(
      emoji: '🌍',
      skill: 'Earth and space',
      sceneLabel: 'Day changes into night',
      prompt: 'What causes day and night?',
      spokenPrompt: 'What movement of Earth causes day and night?',
      answer: 'EARTH ROTATES',
      distractorOne: 'EARTH STOPS',
      distractorTwo: 'THE MOON MELTS',
      hint: 'Earth spins once about every twenty-four hours.',
      explanation: 'Earth rotating causes day and night.'),
  _ScienceQuestion(
      emoji: '🧽',
      skill: 'Materials',
      sceneLabel: 'A raincoat must keep water out',
      prompt: 'Which material property helps?',
      spokenPrompt: 'Which property should raincoat material have?',
      answer: 'WATERPROOF',
      distractorOne: 'ABSORBENT',
      distractorTwo: 'MAGNETIC',
      hint: 'Water should not pass through it.',
      explanation: 'A raincoat needs waterproof material.'),
  _ScienceQuestion(
      emoji: '🌊',
      skill: 'Environment',
      sceneLabel: 'Plastic floats in the ocean',
      prompt: 'What is the safest action?',
      spokenPrompt: 'What should we do to reduce plastic pollution?',
      answer: 'REUSE AND RECYCLE',
      distractorOne: 'THROW MORE AWAY',
      distractorTwo: 'BURN IT OUTSIDE',
      hint: 'Reduce waste and keep it out of nature.',
      explanation: 'Reusing and recycling reduces plastic waste.'),
];

const _ecoQuestions = <_ScienceQuestion>[
  _ScienceQuestion(
      emoji: '☀️',
      skill: 'Clean energy',
      sceneLabel: 'The city needs electricity with less smoke',
      prompt: 'Which energy source should the mayor choose?',
      spokenPrompt:
          'The city needs electricity with less air pollution. Which energy source should the mayor choose?',
      answer: 'SOLAR PANELS',
      distractorOne: 'MORE COAL',
      distractorTwo: 'BURN RUBBISH',
      hint: 'Choose a source that uses sunlight and makes no smoke.',
      explanation: 'Solar panels make electricity without producing smoke.'),
  _ScienceQuestion(
      emoji: '🌧️',
      skill: 'Water conservation',
      sceneLabel: 'Rain falls on the school roof',
      prompt: 'How can the city save this water?',
      spokenPrompt: 'Rain falls on the school roof. How can the city save it?',
      answer: 'USE A RAINWATER TANK',
      distractorOne: 'LET IT ALL DRAIN AWAY',
      distractorTwo: 'COVER THE ROOF IN PLASTIC',
      hint: 'Collect the rain now so it can be used later.',
      explanation: 'A rainwater tank stores water for gardens and cleaning.'),
  _ScienceQuestion(
      emoji: '🚌',
      skill: 'Clean transport',
      sceneLabel: 'Many cars crowd one road',
      prompt: 'What can reduce traffic and pollution?',
      spokenPrompt:
          'Many cars crowd one road. What can reduce traffic and pollution?',
      answer: 'RELIABLE PUBLIC BUSES',
      distractorOne: 'WIDER CAR PARKS',
      distractorTwo: 'MORE EMPTY CARS',
      hint: 'One vehicle can carry many people together.',
      explanation:
          'Good public transport reduces the number of cars on roads.'),
  _ScienceQuestion(
      emoji: '🍂',
      skill: 'Waste management',
      sceneLabel: 'The market has fruit peels and dry leaves',
      prompt: 'What is the best use for this waste?',
      spokenPrompt:
          'The market has fruit peels and dry leaves. What is the best use for them?',
      answer: 'MAKE COMPOST',
      distractorOne: 'THROW THEM IN A RIVER',
      distractorTwo: 'MIX THEM WITH GLASS',
      hint: 'Organic waste can become food for soil.',
      explanation: 'Composting turns organic waste into useful plant food.'),
  _ScienceQuestion(
      emoji: '🌳',
      skill: 'Biodiversity',
      sceneLabel: 'A new park needs plants for local birds',
      prompt: 'Which plants are the best choice?',
      spokenPrompt:
          'A new park needs plants for local birds. Which plants are the best choice?',
      answer: 'NATIVE TREES AND FLOWERS',
      distractorOne: 'ONLY PLASTIC PLANTS',
      distractorTwo: 'NO PLANTS AT ALL',
      hint: 'Local animals are adapted to plants from their area.',
      explanation:
          'Native plants provide suitable food and shelter for local wildlife.'),
  _ScienceQuestion(
      emoji: '🚰',
      skill: 'Resource planning',
      sceneLabel: 'A pipe leaks clean water every day',
      prompt: 'What should the city repair first?',
      spokenPrompt:
          'A pipe leaks clean water every day. What should the city repair first?',
      answer: 'THE LEAKING PIPE',
      distractorOne: 'THE PARK BENCH',
      distractorTwo: 'THE CLOCK TOWER',
      hint: 'Stop the problem that wastes an important resource.',
      explanation:
          'Repairing the leak prevents clean water from being wasted.'),
  _ScienceQuestion(
      emoji: '♻️',
      skill: 'Sorting waste',
      sceneLabel: 'Homes put food, paper and batteries in one bin',
      prompt: 'What system will make recycling safer?',
      spokenPrompt:
          'Homes mix food, paper and batteries. What system will make recycling safer?',
      answer: 'SEPARATE LABELLED BINS',
      distractorOne: 'ONE UNMARKED PILE',
      distractorTwo: 'DROP WASTE ON ROADS',
      hint: 'Different materials need different treatment.',
      explanation:
          'Labelled bins keep recyclable, organic and hazardous waste separate.'),
  _ScienceQuestion(
      emoji: '💡',
      skill: 'Energy efficiency',
      sceneLabel: 'The library replaces old light bulbs',
      prompt: 'Which bulbs usually use less electricity?',
      spokenPrompt:
          'The library replaces old light bulbs. Which bulbs usually use less electricity?',
      answer: 'LED BULBS',
      distractorOne: 'BROKEN BULBS',
      distractorTwo: 'HOT COAL LAMPS',
      hint: 'Look for the efficient modern lighting choice.',
      explanation: 'LED bulbs provide light while using less electricity.'),
  _ScienceQuestion(
      emoji: '🪷',
      skill: 'Flood protection',
      sceneLabel: 'A wetland beside the town stores storm water',
      prompt: 'How should the city treat the wetland?',
      spokenPrompt:
          'A wetland stores storm water and shelters animals. What should the city do?',
      answer: 'PROTECT AND RESTORE IT',
      distractorOne: 'FILL IT WITH CONCRETE',
      distractorTwo: 'DUMP WASTE THERE',
      hint: 'Keep the natural place that absorbs water.',
      explanation: 'Healthy wetlands absorb flood water and support wildlife.'),
  _ScienceQuestion(
      emoji: '🚲',
      skill: 'Healthy streets',
      sceneLabel: 'Children want to cycle safely to school',
      prompt: 'What should the city add?',
      spokenPrompt:
          'Children want to cycle safely to school. What should the city add?',
      answer: 'A PROTECTED CYCLE LANE',
      distractorOne: 'A FASTER CAR LANE',
      distractorTwo: 'A WALL ACROSS THE ROAD',
      hint: 'Separate bicycles from fast traffic.',
      explanation: 'A protected cycle lane makes active travel safer.'),
  _ScienceQuestion(
      emoji: '🏠',
      skill: 'Green buildings',
      sceneLabel: 'A home gets very hot and uses much cooling',
      prompt: 'Which change can reduce energy use?',
      spokenPrompt:
          'A home gets very hot and uses much cooling. Which change can reduce energy use?',
      answer: 'ADD SHADE AND INSULATION',
      distractorOne: 'LEAVE EVERY DOOR OPEN',
      distractorTwo: 'RUN MORE EMPTY FRIDGES',
      hint: 'Keep unwanted heat outside the building.',
      explanation:
          'Shade and insulation help rooms stay comfortable with less energy.'),
  _ScienceQuestion(
      emoji: '📱',
      skill: 'E-waste safety',
      sceneLabel: 'Old phones and batteries need disposal',
      prompt: 'Where should they go?',
      spokenPrompt:
          'Old phones and batteries need disposal. Where should they go?',
      answer: 'AN E-WASTE COLLECTION CENTRE',
      distractorOne: 'THE PLAYGROUND',
      distractorTwo: 'THE FOOD COMPOST BIN',
      hint: 'Electronics need specialist recycling.',
      explanation:
          'E-waste centres recover materials and handle batteries safely.'),
];

const _mysteryQuestions = <_ScienceQuestion>[
  _ScienceQuestion(
      emoji: '🌱',
      skill: 'Variables',
      sceneLabel: 'Mira changes the light given to bean plants',
      prompt: 'What is the independent variable?',
      spokenPrompt:
          'Mira changes the amount of light given to bean plants. What is the independent variable?',
      answer: 'AMOUNT OF LIGHT',
      distractorOne: 'PLANT HEIGHT',
      distractorTwo: 'TYPE OF RULER',
      hint: 'It is the factor the scientist deliberately changes.',
      explanation: 'The amount of light is changed by the scientist.'),
  _ScienceQuestion(
      emoji: '📏',
      skill: 'Variables',
      sceneLabel: 'Mira measures each plant after two weeks',
      prompt: 'What is the dependent variable?',
      spokenPrompt:
          'Mira measures each plant after two weeks. What is the dependent variable?',
      answer: 'PLANT HEIGHT',
      distractorOne: 'AMOUNT OF LIGHT',
      distractorTwo: 'COLOUR OF THE POT',
      hint: 'It is the result that is measured.',
      explanation: 'Plant height is the measured outcome.'),
  _ScienceQuestion(
      emoji: '🧪',
      skill: 'Fair testing',
      sceneLabel: 'Two liquids are tested for evaporation',
      prompt: 'How can this be a fair test?',
      spokenPrompt:
          'Two liquids are tested for evaporation. How can this be a fair test?',
      answer: 'CHANGE ONLY THE LIQUID',
      distractorOne: 'USE DIFFERENT TEMPERATURES',
      distractorTwo: 'USE DIFFERENT CUP SIZES',
      hint: 'Keep every other condition the same.',
      explanation: 'Changing one factor lets us compare its effect fairly.'),
  _ScienceQuestion(
      emoji: '🔁',
      skill: 'Reliable evidence',
      sceneLabel: 'One trial gives a surprising result',
      prompt: 'What should the scientist do next?',
      spokenPrompt:
          'One trial gives a surprising result. What should the scientist do next?',
      answer: 'REPEAT THE TRIAL',
      distractorOne: 'HIDE THE RESULT',
      distractorTwo: 'GUESS A NEW NUMBER',
      hint: 'Check whether the result happens again.',
      explanation: 'Repeated trials help reveal whether a result is reliable.'),
  _ScienceQuestion(
      emoji: '👥',
      skill: 'Sample size',
      sceneLabel: 'A food test uses only one child',
      prompt: 'How can the investigation improve?',
      spokenPrompt:
          'A food preference test uses only one child. How can the investigation improve?',
      answer: 'TEST A LARGER GROUP',
      distractorOne: 'ASK THE SAME CHILD AGAIN',
      distractorTwo: 'REMOVE ALL RESULTS',
      hint: 'More participants make the evidence more representative.',
      explanation:
          'A larger sample reduces the effect of one unusual response.'),
  _ScienceQuestion(
      emoji: '💭',
      skill: 'Hypotheses',
      sceneLabel: 'A team writes a prediction before testing',
      prompt: 'Which hypothesis can be tested?',
      spokenPrompt: 'Which hypothesis can be tested with measurements?',
      answer: 'MORE LIGHT INCREASES GROWTH',
      distractorOne: 'PLANTS ARE ALWAYS HAPPY',
      distractorTwo: 'GREEN IS THE NICEST COLOUR',
      hint: 'Choose a claim with measurable factors.',
      explanation: 'Light and growth can both be changed or measured.'),
  _ScienceQuestion(
      emoji: '📊',
      skill: 'Graph reading',
      sceneLabel: 'A graph shows temperature changing over time',
      prompt: 'Where should time usually go?',
      spokenPrompt:
          'A graph shows temperature changing over time. On which axis should time usually go?',
      answer: 'THE HORIZONTAL X-AXIS',
      distractorOne: 'ONLY IN THE TITLE',
      distractorTwo: 'OUTSIDE THE GRAPH',
      hint: 'The independent variable normally goes across the bottom.',
      explanation:
          'Time is the independent variable and is plotted on the x-axis.'),
  _ScienceQuestion(
      emoji: '⚖️',
      skill: 'Measurement tools',
      sceneLabel: 'A powder must be measured by mass',
      prompt: 'Which tool should be used?',
      spokenPrompt:
          'A powder must be measured by mass. Which tool should be used?',
      answer: 'A BALANCE',
      distractorOne: 'A THERMOMETER',
      distractorTwo: 'A STOPWATCH',
      hint: 'Choose the tool that measures grams.',
      explanation: 'A balance measures mass.'),
  _ScienceQuestion(
      emoji: '🧊',
      skill: 'Control groups',
      sceneLabel: 'Salt is tested to see if it melts ice faster',
      prompt: 'What should the control ice receive?',
      spokenPrompt:
          'Salt is tested to see if it melts ice faster. What should the control ice receive?',
      answer: 'NO SALT',
      distractorOne: 'TWICE AS MUCH SALT',
      distractorTwo: 'HOT JUICE',
      hint: 'The control does not receive the factor being tested.',
      explanation: 'Ice without salt provides a comparison for the treatment.'),
  _ScienceQuestion(
      emoji: '🔎',
      skill: 'Evidence',
      sceneLabel: 'A footprint is found beside spilled soil',
      prompt: 'Which statement is an observation?',
      spokenPrompt:
          'A footprint is found beside spilled soil. Which statement is an observation?',
      answer: 'THE PRINT IS 18 CM LONG',
      distractorOne: 'A GIANT MADE IT',
      distractorTwo: 'THE PERSON WAS ANGRY',
      hint: 'Choose what can be directly seen or measured.',
      explanation:
          'The print length is measurable evidence; the others are guesses.'),
  _ScienceQuestion(
      emoji: '🧤',
      skill: 'Lab safety',
      sceneLabel: 'A bottle has an unknown liquid',
      prompt: 'What is the safest action?',
      spokenPrompt:
          'A bottle has an unknown liquid. What is the safest action?',
      answer: 'ASK AN ADULT AND READ THE LABEL',
      distractorOne: 'TASTE IT',
      distractorTwo: 'SPLASH IT ON A FRIEND',
      hint: 'Never touch or taste an unknown chemical.',
      explanation:
          'Labels and adult supervision help us handle substances safely.'),
  _ScienceQuestion(
      emoji: '📈',
      skill: 'Conclusions',
      sceneLabel: 'Warm water dissolved sugar fastest in every trial',
      prompt: 'Which conclusion fits the evidence?',
      spokenPrompt:
          'Warm water dissolved sugar fastest in every trial. Which conclusion fits the evidence?',
      answer: 'WARM WATER DISSOLVED IT FASTER',
      distractorOne: 'SUGAR NEVER DISSOLVES',
      distractorTwo: 'COLD WATER WAS ALWAYS FASTEST',
      hint: 'The conclusion must match the recorded results.',
      explanation:
          'The evidence supports only the result observed in the trials.'),
];

const _newsQuestions = <_ScienceQuestion>[
  _ScienceQuestion(
      emoji: '🗣️',
      skill: 'Fact or opinion',
      sceneLabel: 'A post says, “Our playground is the best ever!”',
      prompt: 'What kind of statement is this?',
      spokenPrompt:
          'A post says our playground is the best ever. What kind of statement is this?',
      answer: 'AN OPINION',
      distractorOne: 'A MEASURED FACT',
      distractorTwo: 'A WEATHER RECORD',
      hint: 'The word best depends on personal preference.',
      explanation: '“Best” is a judgement, so the statement is an opinion.'),
  _ScienceQuestion(
      emoji: '📒',
      skill: 'Primary sources',
      sceneLabel: 'A report says the garden grew 12 kg of tomatoes',
      prompt: 'Which source can best confirm it?',
      spokenPrompt:
          'A report says the garden grew twelve kilograms of tomatoes. Which source can best confirm it?',
      answer: 'THE GARDEN WEIGHING RECORD',
      distractorOne: 'A RANDOM COMMENT',
      distractorTwo: 'A CARTOON ABOUT TOMATOES',
      hint: 'Look for a direct record made during the harvest.',
      explanation: 'The weighing record is direct evidence from the event.'),
  _ScienceQuestion(
      emoji: '📅',
      skill: 'Freshness',
      sceneLabel: 'A storm warning is shared in a group chat',
      prompt: 'What should you check first?',
      spokenPrompt:
          'A storm warning is shared in a group chat. What should you check first?',
      answer: 'THE DATE AND OFFICIAL SOURCE',
      distractorOne: 'THE FONT COLOUR',
      distractorTwo: 'HOW MANY EMOJIS IT HAS',
      hint: 'An old warning may no longer be true.',
      explanation:
          'The date and official weather source show whether a warning is current.'),
  _ScienceQuestion(
      emoji: '📰',
      skill: 'Headlines',
      sceneLabel: 'A dramatic headline makes a huge claim',
      prompt: 'What should a careful reader do?',
      spokenPrompt:
          'A dramatic headline makes a huge claim. What should a careful reader do?',
      answer: 'READ THE EVIDENCE IN THE ARTICLE',
      distractorOne: 'BELIEVE ONLY THE HEADLINE',
      distractorTwo: 'SHARE IT WITHOUT READING',
      hint: 'A headline is a summary, not proof.',
      explanation:
          'The full article should provide sources and evidence for its headline.'),
  _ScienceQuestion(
      emoji: '🕵️',
      skill: 'Source checking',
      sceneLabel: 'A claim is credited only to “someone online”',
      prompt: 'Why should we be cautious?',
      spokenPrompt:
          'A claim is credited only to someone online. Why should we be cautious?',
      answer: 'THE SOURCE CANNOT BE VERIFIED',
      distractorOne: 'ALL ONLINE CLAIMS ARE TRUE',
      distractorTwo: 'SHORT SENTENCES ARE FALSE',
      hint: 'We cannot check who provided the information.',
      explanation: 'Unnamed, untraceable sources are difficult to evaluate.'),
  _ScienceQuestion(
      emoji: '🖼️',
      skill: 'Image context',
      sceneLabel: 'A flood photo is attached to today’s message',
      prompt: 'How can you check the photo?',
      spokenPrompt:
          'A flood photo is attached to today’s message. How can you check whether it belongs to the event?',
      answer: 'FIND ITS ORIGINAL DATE AND SOURCE',
      distractorOne: 'TRUST IT BECAUSE IT IS BRIGHT',
      distractorTwo: 'ADD A FUNNY STICKER',
      hint: 'Images can be old or taken somewhere else.',
      explanation:
          'The original source reveals when and where an image was made.'),
  _ScienceQuestion(
      emoji: '✅',
      skill: 'Corroboration',
      sceneLabel: 'One website reports a surprising school closure',
      prompt: 'What is the strongest next check?',
      spokenPrompt:
          'One website reports a surprising school closure. What is the strongest next check?',
      answer: 'CHECK THE SCHOOL AND ANOTHER SOURCE',
      distractorOne: 'FORWARD IT IMMEDIATELY',
      distractorTwo: 'COUNT THE EXCLAMATION MARKS',
      hint: 'Confirm important claims independently.',
      explanation:
          'The official school notice and another reliable source can confirm the claim.'),
  _ScienceQuestion(
      emoji: '📣',
      skill: 'Advertising',
      sceneLabel: 'A video praises a toy and says “paid promotion”',
      prompt: 'What does the label tell us?',
      spokenPrompt:
          'A video praises a toy and says paid promotion. What does the label tell us?',
      answer: 'THE CREATOR WAS PAID',
      distractorOne: 'THE TOY WON EVERY TEST',
      distractorTwo: 'THE VIDEO IS A SCIENCE REPORT',
      hint: 'The recommendation may be part of an advertisement.',
      explanation:
          'A paid promotion is advertising and may not be an independent review.'),
  _ScienceQuestion(
      emoji: '😱',
      skill: 'Emotional language',
      sceneLabel: 'A message says “SHOCKING! Share before it disappears!”',
      prompt: 'What is this language trying to do?',
      spokenPrompt:
          'A message says shocking, share before it disappears. What is this language trying to do?',
      answer: 'MAKE YOU REACT QUICKLY',
      distractorOne: 'SHOW CAREFUL EVIDENCE',
      distractorTwo: 'MEASURE A RESULT',
      hint: 'Strong emotion can stop us checking first.',
      explanation:
          'Urgent emotional wording pressures readers to react without verifying.'),
  _ScienceQuestion(
      emoji: '📊',
      skill: 'Survey evidence',
      sceneLabel: 'Three friends vote for one snack',
      prompt: 'Can this prove every child prefers it?',
      spokenPrompt:
          'Three friends vote for one snack. Can this prove every child prefers it?',
      answer: 'NO, THE SAMPLE IS TOO SMALL',
      distractorOne: 'YES, THREE IS EVERYONE',
      distractorTwo: 'YES, SNACKS NEED NO DATA',
      hint: 'A tiny group may not represent all children.',
      explanation: 'A larger, varied sample is needed for a broad claim.'),
  _ScienceQuestion(
      emoji: '🔮',
      skill: 'Predictions',
      sceneLabel: 'An article says a team will win tomorrow',
      prompt: 'Is the result already a fact?',
      spokenPrompt:
          'An article says a team will win tomorrow. Is the result already a fact?',
      answer: 'NO, IT IS A PREDICTION',
      distractorOne: 'YES, THE GAME IS FINISHED',
      distractorTwo: 'YES, ALL GUESSES ARE FACTS',
      hint: 'Future events have not happened yet.',
      explanation:
          'A statement about an uncertain future event is a prediction.'),
  _ScienceQuestion(
      emoji: '✏️',
      skill: 'Corrections',
      sceneLabel: 'A news page clearly corrects an earlier mistake',
      prompt: 'Why is the correction useful?',
      spokenPrompt:
          'A news page clearly corrects an earlier mistake. Why is the correction useful?',
      answer: 'IT MAKES THE UPDATE TRANSPARENT',
      distractorOne: 'IT HIDES ALL EVIDENCE',
      distractorTwo: 'IT MAKES THE OLD ERROR TRUE',
      hint: 'Readers can see what changed and why.',
      explanation:
          'Visible corrections help readers track accurate updated information.'),
];

class _DirectionItem {
  const _DirectionItem(this.name, this.arrow);
  final String name;
  final String arrow;
}

const _directions = <_DirectionItem>[
  _DirectionItem('NORTH', '⬆️'),
  _DirectionItem('EAST', '➡️'),
  _DirectionItem('SOUTH', '⬇️'),
  _DirectionItem('WEST', '⬅️'),
];
