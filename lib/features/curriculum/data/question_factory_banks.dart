part of 'question_factory.dart';

typedef _WorldFact = (String, String, String, String, String, String, String);

/// Curated class-specific knowledge. Keeping these pools separate prevents a
/// preschool learner from seeing abstract science and prevents an older child
/// from spending a whole session on animal sounds.
class _GradeWorldBanks {
  const _GradeWorldBanks._();

  static List<_WorldFact> forGrade(GradeLevel grade, Subject subject) {
    if (grade.isPreSchool) return _preschool[grade]!;
    return (subject == Subject.science ? _science : _evs)[grade]!;
  }

  static const _preschool = <GradeLevel, List<_WorldFact>>{
    GradeLevel.lkg: [
      ('Who says moo?', 'Cow', '🐄', 'Dog', '🐶', 'Duck', '🦆'),
      ('Who says woof?', 'Dog', '🐶', 'Cat', '🐱', 'Cow', '🐄'),
      ('Who says meow?', 'Cat', '🐱', 'Lion', '🦁', 'Bird', '🐦'),
      ('Which one can fly?', 'Bird', '🐦', 'Dog', '🐶', 'Fish', '🐟'),
      ('Where does a fish live?', 'Water', '🌊', 'Tree', '🌳', 'Nest', '🪺'),
      ('What do we see with?', 'Eyes', '👀', 'Ears', '👂', 'Nose', '👃'),
      ('What do we hear with?', 'Ears', '👂', 'Hands', '🤚', 'Eyes', '👀'),
      ('What do we smell with?', 'Nose', '👃', 'Feet', '🦶', 'Ears', '👂'),
      ('What shines in the day?', 'Sun', '☀️', 'Moon', '🌙', 'Lamp', '💡'),
      (
        'What do we drink when thirsty?',
        'Water',
        '💧',
        'Paint',
        '🎨',
        'Soap',
        '🧼'
      ),
      ('Which one is a fruit?', 'Apple', '🍎', 'Chair', '🪑', 'Bus', '🚌'),
      ('What keeps hands clean?', 'Soap', '🧼', 'Crayon', '🖍️', 'Ball', '⚽'),
      ('Where do we sleep?', 'Bed', '🛏️', 'Table', '🪑', 'Bus', '🚌'),
      (
        'Who teaches us?',
        'Teacher',
        '👩‍🏫',
        'Pilot',
        '👨‍✈️',
        'Chef',
        '👨‍🍳'
      ),
      (
        'What keeps us dry in rain?',
        'Umbrella',
        '☂️',
        'Spoon',
        '🥄',
        'Pencil',
        '✏️'
      ),
    ],
    GradeLevel.ukg: [
      ('A baby dog is a?', 'Puppy', '🐶', 'Kitten', '🐱', 'Calf', '🐮'),
      ('A baby cat is a?', 'Kitten', '🐱', 'Chick', '🐣', 'Cub', '🦁'),
      ('Which animal gives us milk?', 'Cow', '🐄', 'Lion', '🦁', 'Crow', '🐦'),
      ('Where does a bird rest?', 'Nest', '🪺', 'Pond', '🌊', 'Cave', '🪨'),
      (
        'Which body part helps us walk?',
        'Legs',
        '🦵',
        'Ears',
        '👂',
        'Hair',
        '💇'
      ),
      ('What do we taste with?', 'Tongue', '👅', 'Nose', '👃', 'Eyes', '👀'),
      ('What comes after day?', 'Night', '🌙', 'Summer', '☀️', 'Rain', '🌧️'),
      (
        'Which season feels cold?',
        'Winter',
        '❄️',
        'Summer',
        '☀️',
        'Spring',
        '🌸'
      ),
      ('What grows from a seed?', 'Plant', '🌱', 'Stone', '🪨', 'Toy', '🧸'),
      (
        'Which food helps us stay healthy?',
        'Fruit',
        '🍎',
        'Candy',
        '🍬',
        'Chips',
        '🍟'
      ),
      (
        'What do we brush teeth with?',
        'Toothbrush',
        '🪥',
        'Comb',
        '🪮',
        'Spoon',
        '🥄'
      ),
      (
        'Which vehicle runs on tracks?',
        'Train',
        '🚂',
        'Car',
        '🚗',
        'Boat',
        '⛵'
      ),
      (
        'Who helps sick people?',
        'Doctor',
        '👨‍⚕️',
        'Driver',
        '🚌',
        'Farmer',
        '👨‍🌾'
      ),
      (
        'What does a red traffic light mean?',
        'Stop',
        '🛑',
        'Go',
        '🟢',
        'Run',
        '🏃'
      ),
      (
        'Where do children learn?',
        'School',
        '🏫',
        'Market',
        '🏪',
        'Station',
        '🚉'
      ),
    ],
    GradeLevel.kg: [
      ('Which one is living?', 'Tree', '🌳', 'Rock', '🪨', 'Chair', '🪑'),
      (
        'What do plants need to grow?',
        'Sunlight',
        '☀️',
        'Candy',
        '🍬',
        'Plastic',
        '🧴'
      ),
      (
        'Which plant part is under soil?',
        'Root',
        '🪴',
        'Flower',
        '🌸',
        'Leaf',
        '🍃'
      ),
      (
        'Which animal lives in water?',
        'Whale',
        '🐳',
        'Horse',
        '🐴',
        'Lion',
        '🦁'
      ),
      ('Which animal eats plants?', 'Cow', '🐄', 'Tiger', '🐯', 'Eagle', '🦅'),
      ('What covers a bird?', 'Feathers', '🪶', 'Fur', '🐾', 'Scales', '🐟'),
      ('Rain comes from?', 'Clouds', '☁️', 'Roads', '🛣️', 'Trees', '🌳'),
      (
        'What melts an ice cube?',
        'Warmth',
        '🔥',
        'Cold',
        '❄️',
        'Darkness',
        '🌙'
      ),
      (
        'Which object floats on water?',
        'Leaf',
        '🍃',
        'Stone',
        '🪨',
        'Coin',
        '🪙'
      ),
      ('What do we breathe?', 'Air', '💨', 'Milk', '🥛', 'Sand', '🏖️'),
      ('Who grows crops?', 'Farmer', '👨‍🌾', 'Pilot', '👨‍✈️', 'Tailor', '🧵'),
      (
        'Which vehicle travels on water?',
        'Boat',
        '⛵',
        'Bus',
        '🚌',
        'Train',
        '🚂'
      ),
      (
        'Where should we cross a road?',
        'Zebra crossing',
        '🚸',
        'Anywhere',
        '🛣️',
        'Road middle',
        '🚗'
      ),
      (
        'What should we do before eating?',
        'Wash hands',
        '🧼',
        'Watch TV',
        '📺',
        'Run outside',
        '🏃'
      ),
      (
        'Which home belongs to a bee?',
        'Hive',
        '🐝',
        'Kennel',
        '🐶',
        'Stable',
        '🐴'
      ),
    ],
  };

  static const _science = <GradeLevel, List<_WorldFact>>{
    GradeLevel.grade1: [
      ('Which one is living?', 'Butterfly', '🦋', 'Rock', '🪨', 'Pencil', '✏️'),
      (
        'What do living things need?',
        'Water',
        '💧',
        'Plastic',
        '🧴',
        'Paint',
        '🎨'
      ),
      (
        'Which sense uses the nose?',
        'Smell',
        '👃',
        'Sight',
        '👀',
        'Hearing',
        '👂'
      ),
      (
        'Which sense uses the skin?',
        'Touch',
        '🤚',
        'Taste',
        '👅',
        'Sight',
        '👀'
      ),
      (
        'Which part helps a plant drink water?',
        'Roots',
        '🪴',
        'Flowers',
        '🌸',
        'Fruit',
        '🍎'
      ),
      ('Which animal has feathers?', 'Parrot', '🦜', 'Cat', '🐱', 'Fish', '🐟'),
      ('Which animal has scales?', 'Fish', '🐟', 'Rabbit', '🐰', 'Hen', '🐔'),
      (
        'What gives Earth daytime light?',
        'Sun',
        '☀️',
        'Moon',
        '🌙',
        'Cloud',
        '☁️'
      ),
      (
        'Which material is transparent?',
        'Clear glass',
        '🪟',
        'Wood',
        '🪵',
        'Stone',
        '🪨'
      ),
      (
        'Which object is attracted by a magnet?',
        'Iron nail',
        '📌',
        'Rubber band',
        '➰',
        'Paper',
        '📄'
      ),
      (
        'What happens to ice in warmth?',
        'It melts',
        '💧',
        'It grows',
        '🧊',
        'It burns',
        '🔥'
      ),
      (
        'Which body part pumps blood?',
        'Heart',
        '❤️',
        'Lungs',
        '🫁',
        'Stomach',
        '🫃'
      ),
      ('What helps us breathe?', 'Lungs', '🫁', 'Bones', '🦴', 'Teeth', '🦷'),
      (
        'Which is a source of water?',
        'River',
        '🌊',
        'Road',
        '🛣️',
        'Hill',
        '⛰️'
      ),
      (
        'A shadow forms when light is?',
        'Blocked',
        '🌑',
        'Painted',
        '🎨',
        'Washed',
        '💧'
      ),
    ],
    GradeLevel.grade2: [
      ('Which is a solid?', 'Stone', '🪨', 'Water', '💧', 'Air', '💨'),
      ('Which is a liquid?', 'Milk', '🥛', 'Book', '📖', 'Steam', '💨'),
      ('Which is a gas?', 'Air', '💨', 'Ice', '🧊', 'Juice', '🧃'),
      (
        'Water becomes ice when it?',
        'Freezes',
        '🧊',
        'Melts',
        '💧',
        'Boils',
        '♨️'
      ),
      (
        'Water vapour becomes drops by?',
        'Cooling',
        '❄️',
        'Heating',
        '🔥',
        'Mixing',
        '🥄'
      ),
      (
        'Which plant part makes food?',
        'Leaf',
        '🍃',
        'Root',
        '🪴',
        'Flower',
        '🌸'
      ),
      (
        'Which habitat is very dry?',
        'Desert',
        '🏜️',
        'Pond',
        '🌊',
        'Forest',
        '🌳'
      ),
      (
        'Which animal is adapted to a desert?',
        'Camel',
        '🐪',
        'Penguin',
        '🐧',
        'Frog',
        '🐸'
      ),
      (
        'Which force pulls things down?',
        'Gravity',
        '🌍',
        'Light',
        '💡',
        'Sound',
        '🔊'
      ),
      (
        'A push or pull is called?',
        'Force',
        '💪',
        'Heat',
        '🔥',
        'Colour',
        '🎨'
      ),
      (
        'Which organ helps digest food?',
        'Stomach',
        '🫃',
        'Lungs',
        '🫁',
        'Eyes',
        '👀'
      ),
      ('Which teeth cut food?', 'Incisors', '🦷', 'Molars', '🦷', 'Gums', '👄'),
      (
        'Which object makes its own light?',
        'Candle flame',
        '🕯️',
        'Mirror',
        '🪞',
        'Moon',
        '🌙'
      ),
      (
        'Sound is made by?',
        'Vibrations',
        '🎵',
        'Shadows',
        '🌑',
        'Colours',
        '🌈'
      ),
      (
        'Which is renewable energy?',
        'Sunlight',
        '☀️',
        'Coal',
        '🪨',
        'Petrol',
        '⛽'
      ),
    ],
    GradeLevel.grade3: [
      (
        'Plants make food mainly in?',
        'Leaves',
        '🍃',
        'Roots',
        '🪴',
        'Flowers',
        '🌸'
      ),
      (
        'The green pigment in leaves is?',
        'Chlorophyll',
        '🍃',
        'Haemoglobin',
        '🩸',
        'Calcium',
        '🦴'
      ),
      (
        'Which animal is a vertebrate?',
        'Fish',
        '🐟',
        'Earthworm',
        '🪱',
        'Jellyfish',
        '🪼'
      ),
      (
        'Which animal changes from tadpole to adult?',
        'Frog',
        '🐸',
        'Hen',
        '🐔',
        'Cat',
        '🐱'
      ),
      (
        'Melting changes a solid into a?',
        'Liquid',
        '💧',
        'Gas',
        '💨',
        'New solid',
        '🧊'
      ),
      (
        'Evaporation changes liquid into?',
        'Vapour',
        '💨',
        'Ice',
        '🧊',
        'Soil',
        '🟤'
      ),
      (
        'Which soil holds the most water?',
        'Clayey soil',
        '🟤',
        'Sandy soil',
        '🏖️',
        'Gravel',
        '🪨'
      ),
      (
        'A complete path for electricity is a?',
        'Circuit',
        '🔌',
        'Magnet',
        '🧲',
        'Shadow',
        '🌑'
      ),
      (
        'Which material conducts electricity?',
        'Copper',
        '🪙',
        'Rubber',
        '➰',
        'Plastic',
        '🧴'
      ),
      (
        'Friction usually makes motion?',
        'Slower',
        '🐢',
        'Brighter',
        '💡',
        'Louder',
        '🔊'
      ),
      ('Earth spins on its?', 'Axis', '🌍', 'Orbit only', '🪐', 'Moon', '🌙'),
      (
        'One Earth rotation takes about?',
        '24 hours',
        '🕛',
        '7 days',
        '📅',
        '30 days',
        '🗓️'
      ),
      (
        'The Moon shines because it?',
        'Reflects sunlight',
        '🌙',
        'Makes fire',
        '🔥',
        'Uses electricity',
        '🔌'
      ),
      (
        'Which planet is closest to the Sun?',
        'Mercury',
        '🪐',
        'Earth',
        '🌍',
        'Jupiter',
        '🪐'
      ),
      (
        'A food chain begins with?',
        'Green plants',
        '🌱',
        'Carnivores',
        '🦁',
        'Decomposers',
        '🍄'
      ),
    ],
    GradeLevel.grade4: [
      (
        'Tiny pores on leaves are?',
        'Stomata',
        '🍃',
        'Roots',
        '🪴',
        'Petals',
        '🌸'
      ),
      (
        'Animals with a backbone are?',
        'Vertebrates',
        '🐟',
        'Invertebrates',
        '🪱',
        'Producers',
        '🌱'
      ),
      ('Which is a producer?', 'Grass', '🌿', 'Rabbit', '🐰', 'Eagle', '🦅'),
      (
        'Which organism breaks down dead matter?',
        'Fungus',
        '🍄',
        'Tiger',
        '🐯',
        'Grass',
        '🌿'
      ),
      (
        'Heat travels through solids mainly by?',
        'Conduction',
        '🔥',
        'Reflection',
        '🪞',
        'Evaporation',
        '💨'
      ),
      (
        'Which is a good heat insulator?',
        'Wood',
        '🪵',
        'Copper',
        '🪙',
        'Iron',
        '🔩'
      ),
      (
        'A change that can be reversed is?',
        'Melting ice',
        '🧊',
        'Burning paper',
        '🔥',
        'Cooking rice',
        '🍚'
      ),
      (
        'Which mixture can be separated by filtering?',
        'Sand and water',
        '🏖️',
        'Salt water',
        '🧂',
        'Sugar water',
        '🍬'
      ),
      (
        'The strongest magnetic pull is at the?',
        'Poles',
        '🧲',
        'Centre only',
        '⭕',
        'Handle',
        '🪝'
      ),
      (
        'Like magnetic poles?',
        'Repel',
        '↔️',
        'Attract',
        '🫂',
        'Disappear',
        '✨'
      ),
      (
        'Pitch tells how ___ a sound is.',
        'High or low',
        '🎵',
        'Fast or slow',
        '🏃',
        'Hot or cold',
        '🌡️'
      ),
      (
        'A prism can split white light into?',
        'Colours',
        '🌈',
        'Sound',
        '🔊',
        'Heat only',
        '🔥'
      ),
      (
        'Earth takes about one year to?',
        'Orbit the Sun',
        '🌍',
        'Rotate once',
        '🔄',
        'Orbit the Moon',
        '🌙'
      ),
      (
        'Which planet is known for large rings?',
        'Saturn',
        '🪐',
        'Mars',
        '🔴',
        'Mercury',
        '⚪'
      ),
      (
        'An adaptation helps an organism?',
        'Survive',
        '🌱',
        'Change planets',
        '🚀',
        'Stop growing',
        '🛑'
      ),
    ],
    GradeLevel.grade5: [
      (
        'Photosynthesis releases which gas?',
        'Oxygen',
        '💨',
        'Nitrogen',
        '🌫️',
        'Hydrogen',
        '🎈'
      ),
      (
        'Pollen reaching a flower stigma is?',
        'Pollination',
        '🌸',
        'Germination',
        '🌱',
        'Respiration',
        '💨'
      ),
      (
        'Which system carries blood?',
        'Circulatory system',
        '❤️',
        'Digestive system',
        '🫃',
        'Nervous system',
        '🧠'
      ),
      (
        'Which organ filters waste from blood?',
        'Kidneys',
        '🫘',
        'Lungs',
        '🫁',
        'Stomach',
        '🫃'
      ),
      (
        'A group of connected food chains is a?',
        'Food web',
        '🕸️',
        'Habitat only',
        '🏞️',
        'Life cycle',
        '🔄'
      ),
      (
        'Removing one species can affect?',
        'The whole food web',
        '🕸️',
        'Nothing else',
        '⭕',
        'Only rocks',
        '🪨'
      ),
      (
        'A solution has a solute and a?',
        'Solvent',
        '💧',
        'Magnet',
        '🧲',
        'Shadow',
        '🌑'
      ),
      (
        'Which method gets salt from salt water?',
        'Evaporation',
        '💨',
        'Filtering',
        '🧻',
        'Magnetism',
        '🧲'
      ),
      (
        'A chemical change usually forms?',
        'A new substance',
        '🧪',
        'Only a new shape',
        '🔷',
        'Only a new size',
        '📏'
      ),
      (
        'Two or more cells make a?',
        'Battery',
        '🔋',
        'Bulb',
        '💡',
        'Switch',
        '🔘'
      ),
      (
        'A parallel circuit has?',
        'More than one path',
        '🔌',
        'No path',
        '⭕',
        'Only one path',
        '➡️'
      ),
      (
        'The bending of light is?',
        'Refraction',
        '🌈',
        'Reflection',
        '🪞',
        'Vibration',
        '🎵'
      ),
      (
        'Earth’s gravity keeps the Moon in?',
        'Orbit',
        '🌙',
        'A cloud',
        '☁️',
        'The ocean',
        '🌊'
      ),
      (
        'Which planet has the shortest year?',
        'Mercury',
        '🪐',
        'Earth',
        '🌍',
        'Neptune',
        '🔵'
      ),
      (
        'A fair test changes how many variables?',
        'One',
        '1️⃣',
        'All',
        '🔢',
        'None',
        '0️⃣'
      ),
    ],
  };

  static const _evs = <GradeLevel, List<_WorldFact>>{
    GradeLevel.grade1: [
      (
        'Who delivers letters?',
        'Postal worker',
        '📬',
        'Doctor',
        '👨‍⚕️',
        'Farmer',
        '👨‍🌾'
      ),
      (
        'Who puts out fires?',
        'Firefighter',
        '🧑‍🚒',
        'Teacher',
        '👩‍🏫',
        'Tailor',
        '🧵'
      ),
      (
        'Who grows our food?',
        'Farmer',
        '👨‍🌾',
        'Pilot',
        '👨‍✈️',
        'Mechanic',
        '🔧'
      ),
      (
        'Which room is used for cooking?',
        'Kitchen',
        '🍳',
        'Bedroom',
        '🛏️',
        'Study',
        '📚'
      ),
      (
        'Where can we borrow books?',
        'Library',
        '📚',
        'Hospital',
        '🏥',
        'Bakery',
        '🥐'
      ),
      (
        'Which transport travels on water?',
        'Ferry',
        '⛴️',
        'Bus',
        '🚌',
        'Train',
        '🚂'
      ),
      (
        'Which transport carries many people?',
        'Bus',
        '🚌',
        'Bicycle',
        '🚲',
        'Scooter',
        '🛵'
      ),
      (
        'What should we do at a red light?',
        'Stop',
        '🛑',
        'Run',
        '🏃',
        'Turn anywhere',
        '↩️'
      ),
      (
        'Safe road crossing uses a?',
        'Zebra crossing',
        '🚸',
        'Divider',
        '🚧',
        'Flyover',
        '🌉'
      ),
      (
        'Which habit saves water?',
        'Close the tap',
        '🚰',
        'Let it run',
        '💦',
        'Play with water',
        '🔫'
      ),
      (
        'Which bin should hold paper for recycling?',
        'Dry waste bin',
        '♻️',
        'Food plate',
        '🍽️',
        'Sink',
        '🚰'
      ),
      (
        'A family member’s parent is a?',
        'Grandparent',
        '👵',
        'Classmate',
        '🧒',
        'Neighbour',
        '🏠'
      ),
      (
        'Which meal is usually eaten in the morning?',
        'Breakfast',
        '🍞',
        'Dinner',
        '🍲',
        'Supper',
        '🌙'
      ),
      (
        'What helps keep teeth healthy?',
        'Brushing',
        '🪥',
        'Candy',
        '🍬',
        'Skipping water',
        '🚱'
      ),
      (
        'Which place treats ill people?',
        'Hospital',
        '🏥',
        'Station',
        '🚉',
        'Museum',
        '🏛️'
      ),
    ],
    GradeLevel.grade2: [
      (
        'A neighbourhood is made of?',
        'Nearby homes and places',
        '🏘️',
        'Only one room',
        '🛏️',
        'Only farms',
        '🚜'
      ),
      (
        'Who repairs leaking taps?',
        'Plumber',
        '🔧',
        'Pilot',
        '👨‍✈️',
        'Chef',
        '👨‍🍳'
      ),
      (
        'Who stitches clothes?',
        'Tailor',
        '🧵',
        'Dentist',
        '🦷',
        'Driver',
        '🚌'
      ),
      (
        'Which is public transport?',
        'Metro',
        '🚇',
        'Private bicycle',
        '🚲',
        'Family car',
        '🚗'
      ),
      (
        'A map symbol helps us?',
        'Find places',
        '🗺️',
        'Cook food',
        '🍳',
        'Grow taller',
        '📏'
      ),
      (
        'The direction opposite east is?',
        'West',
        '⬅️',
        'North',
        '⬆️',
        'South',
        '⬇️'
      ),
      (
        'Which house suits a snowy region?',
        'Sloping-roof house',
        '🏠',
        'Tent only',
        '⛺',
        'Houseboat',
        '🛶'
      ),
      (
        'A houseboat is found on?',
        'Water',
        '🌊',
        'Desert sand',
        '🏜️',
        'A highway',
        '🛣️'
      ),
      (
        'Which festival is known as the festival of lights?',
        'Diwali',
        '🪔',
        'Holi',
        '🎨',
        'Onam',
        '🌼'
      ),
      (
        'Which action reduces waste?',
        'Reuse a bottle',
        '♻️',
        'Throw it anywhere',
        '🗑️',
        'Burn plastic',
        '🔥'
      ),
      (
        'Clean drinking water should be?',
        'Safe and filtered',
        '💧',
        'Muddy',
        '🟤',
        'Soapy',
        '🫧'
      ),
      (
        'Who makes rules for a classroom together?',
        'Teacher and class',
        '🏫',
        'Traffic only',
        '🚦',
        'Shopkeeper only',
        '🏪'
      ),
      (
        'Emergency services should be called when?',
        'There is danger',
        '🆘',
        'We are bored',
        '🥱',
        'We want a game',
        '🎮'
      ),
      (
        'Which food comes from plants?',
        'Rice',
        '🍚',
        'Egg',
        '🥚',
        'Milk',
        '🥛'
      ),
      (
        'Which food comes from an animal?',
        'Milk',
        '🥛',
        'Wheat',
        '🌾',
        'Lentil',
        '🫘'
      ),
    ],
    GradeLevel.grade3: [
      (
        'A compass needle points mainly?',
        'North–south',
        '🧭',
        'Up–down',
        '↕️',
        'Any fixed colour',
        '🎨'
      ),
      (
        'Blue on a physical map often shows?',
        'Water',
        '🌊',
        'Mountains',
        '⛰️',
        'Roads',
        '🛣️'
      ),
      (
        'A plateau is?',
        'Raised flat land',
        '🏞️',
        'Deep water',
        '🌊',
        'Low narrow valley',
        '🏕️'
      ),
      (
        'A valley lies?',
        'Between hills',
        '🏞️',
        'Above clouds',
        '☁️',
        'Inside an ocean',
        '🌊'
      ),
      (
        'Which occupation turns grain into flour?',
        'Miller',
        '🌾',
        'Carpenter',
        '🪚',
        'Potter',
        '🏺'
      ),
      (
        'A local governing body in a village is?',
        'Gram Panchayat',
        '🏘️',
        'Parliament only',
        '🏛️',
        'Railway board',
        '🚆'
      ),
      (
        'Which resource is renewable?',
        'Wind',
        '💨',
        'Coal',
        '🪨',
        'Petroleum',
        '⛽'
      ),
      (
        'Rainwater harvesting stores?',
        'Rainwater',
        '🌧️',
        'Smoke',
        '💨',
        'Plastic',
        '🧴'
      ),
      (
        'Composting turns food scraps into?',
        'Manure',
        '🌱',
        'Plastic',
        '🧴',
        'Metal',
        '🔩'
      ),
      (
        'Which action protects soil?',
        'Planting trees',
        '🌳',
        'Removing all plants',
        '🪓',
        'Dumping waste',
        '🗑️'
      ),
      (
        'Why do people migrate?',
        'For needs or opportunities',
        '🧳',
        'To stop seasons',
        '🌦️',
        'To change gravity',
        '🌍'
      ),
      (
        'A balanced meal contains?',
        'Different food groups',
        '🍱',
        'Only sweets',
        '🍬',
        'Only oil',
        '🛢️'
      ),
      (
        'Which disease can spread through dirty water?',
        'Cholera',
        '💧',
        'A sprain',
        '🦵',
        'A cut',
        '🩹'
      ),
      (
        'First aid for a small cut begins by?',
        'Cleaning it',
        '🩹',
        'Adding dirt',
        '🟤',
        'Ignoring bleeding',
        '🩸'
      ),
      (
        'A community works best when people?',
        'Cooperate',
        '🤝',
        'Waste resources',
        '🗑️',
        'Ignore rules',
        '🚫'
      ),
    ],
    GradeLevel.grade4: [
      (
        'Lines of latitude run mainly?',
        'East–west',
        '↔️',
        'North–south',
        '↕️',
        'Underground',
        '⬇️'
      ),
      (
        'Lines of longitude meet at the?',
        'Poles',
        '🌍',
        'Equator only',
        '⭕',
        'Oceans only',
        '🌊'
      ),
      (
        'The Equator divides Earth into?',
        'Northern and southern halves',
        '🌍',
        'Land and water',
        '🏞️',
        'Day and night',
        '🌗'
      ),
      (
        'A scale on a map shows?',
        'Distance',
        '📏',
        'Weather only',
        '🌦️',
        'Population only',
        '👥'
      ),
      (
        'Weather means conditions over?',
        'A short time',
        '🌦️',
        'Many centuries',
        '📜',
        'No time',
        '⏱️'
      ),
      (
        'Climate is the usual weather over?',
        'A long period',
        '🗓️',
        'One hour',
        '🕐',
        'One meal',
        '🍽️'
      ),
      (
        'Which farming method saves water?',
        'Drip irrigation',
        '💧',
        'Flooding fields daily',
        '🌊',
        'Leaving taps open',
        '🚰'
      ),
      (
        'Terrace farming helps reduce?',
        'Soil erosion',
        '⛰️',
        'Sunlight',
        '☀️',
        'Seed growth',
        '🌱'
      ),
      ('A dam can store?', 'River water', '💧', 'Sunlight', '☀️', 'Wind', '💨'),
      (
        'Which fuel causes less air pollution?',
        'Biogas',
        '♻️',
        'Coal',
        '🪨',
        'Burning plastic',
        '🔥'
      ),
      (
        'Deforestation means?',
        'Large-scale tree removal',
        '🪓',
        'Planting forests',
        '🌳',
        'Saving seeds',
        '🌰'
      ),
      (
        'A wildlife sanctuary protects?',
        'Wild animals and habitats',
        '🐅',
        'Only buildings',
        '🏢',
        'Only roads',
        '🛣️'
      ),
      (
        'A consumer’s basic right includes?',
        'Safe products',
        '🛡️',
        'False labels',
        '🏷️',
        'Hidden prices',
        '💰'
      ),
      (
        'Local government manages services like?',
        'Waste collection',
        '🗑️',
        'Planet orbits',
        '🪐',
        'Ocean tides only',
        '🌊'
      ),
      (
        'Diversity means people can have?',
        'Different cultures and traditions',
        '🤝',
        'Only one language',
        '1️⃣',
        'Identical lives',
        '👥'
      ),
    ],
    GradeLevel.grade5: [
      (
        'The Tropic of Cancer passes through?',
        'India',
        '🇮🇳',
        'Only Antarctica',
        '🧊',
        'The North Pole',
        '🌍'
      ),
      (
        'A time zone is based mainly on?',
        'Longitude',
        '🌐',
        'Rainfall',
        '🌧️',
        'Soil colour',
        '🟤'
      ),
      (
        'Population density compares people with?',
        'Land area',
        '👥',
        'Cloud cover',
        '☁️',
        'River length',
        '🌊'
      ),
      (
        'A census collects information about?',
        'Population',
        '👥',
        'Only weather',
        '🌦️',
        'Only crops',
        '🌾'
      ),
      (
        'Which sector turns raw material into goods?',
        'Manufacturing',
        '🏭',
        'Agriculture only',
        '🚜',
        'Transport only',
        '🚚'
      ),
      (
        'Imports are goods that a country?',
        'Buys from abroad',
        '📦',
        'Sends abroad',
        '🚢',
        'Throws away',
        '🗑️'
      ),
      (
        'Exports are goods that a country?',
        'Sells abroad',
        '🚢',
        'Buys locally only',
        '🛒',
        'Hides',
        '📦'
      ),
      (
        'A budget helps a family plan?',
        'Income and spending',
        '💰',
        'Weather',
        '🌦️',
        'Gravity',
        '🌍'
      ),
      (
        'Sustainable development meets needs while?',
        'Protecting the future',
        '🌱',
        'Using everything now',
        '🔥',
        'Ignoring waste',
        '🗑️'
      ),
      (
        'The three Rs are reduce, reuse and?',
        'Recycle',
        '♻️',
        'Replace',
        '🔁',
        'Remove',
        '➖'
      ),
      (
        'A carbon footprint measures?',
        'Greenhouse gas impact',
        '🌍',
        'Shoe size',
        '👟',
        'Walking distance only',
        '🚶'
      ),
      (
        'Democracy lets citizens choose?',
        'Representatives',
        '🗳️',
        'Weather',
        '🌦️',
        'Seasons',
        '🗓️'
      ),
      (
        'The Constitution sets out?',
        'Basic rules and rights',
        '📜',
        'Train times',
        '🚆',
        'Recipes',
        '🍲'
      ),
      (
        'A fundamental duty includes?',
        'Respecting public property',
        '🏛️',
        'Wasting water',
        '💦',
        'Breaking rules',
        '🚫'
      ),
      (
        'Disaster preparedness means?',
        'Planning before emergencies',
        '🆘',
        'Waiting without a plan',
        '⏳',
        'Ignoring warnings',
        '⚠️'
      ),
    ],
  };
}
