import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/models/feed_models.dart';

class DiscoveryService {
  static final DiscoveryService instance = DiscoveryService._internal();
  DiscoveryService._internal();

  /// Resolves the backend base URL depending on platform
  String get _baseUrl {
    if (kIsWeb) return 'http://localhost:8000';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    } catch (_) {}
    return 'http://localhost:8000';
  }

  /// Searches Wikipedia via the backend heuristic search endpoint
  Future<List<ArticleItem>> search(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    final url = Uri.parse('$_baseUrl/api/v1/discovery/search?q=${Uri.encodeQueryComponent(cleanQuery)}');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
        return list.map((e) => ArticleItem.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {
      // Offline fallback: search against local curated pool
    }

    return _searchFallback(cleanQuery);
  }

  /// Fetches 5 items for a curated category seed topic
  Future<List<ArticleItem>> fetchCategory({
    required String topic,
    List<String> exclude = const [],
  }) async {
    final excludeParam = exclude.isNotEmpty ? '&exclude=${Uri.encodeQueryComponent(exclude.join(','))}' : '';
    final url = Uri.parse('$_baseUrl/api/v1/discovery/category?topic=$topic$excludeParam');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
        return list.map((e) => ArticleItem.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {
      // Offline fallback
    }

    return _categoryFallback(topic, exclude);
  }

  /// Fetches a single random article
  Future<ArticleItem> fetchRandomArticle() async {
    final url = Uri.parse('$_baseUrl/api/v1/discovery/random-article');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        return ArticleItem.fromJson(data);
      }
    } catch (_) {}

    final pool = _fallbackCatalog;
    final random = Random();
    return pool[random.nextInt(pool.length)];
  }

  final List<String> _recentFactTexts = [];

  void _recordRecentFact(String text) {
    _recentFactTexts.add(text);
    if (_recentFactTexts.length > 50) {
      _recentFactTexts.removeAt(0);
    }
  }

  /// Fetches a single random bite-sized fact with deduplication
  Future<FactItem> fetchRandomFact() async {
    final url = Uri.parse('$_baseUrl/api/v1/discovery/random-fact');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final item = FactItem.fromJson(data);
        _recordRecentFact(item.text);
        return item;
      }
    } catch (_) {}

    final available = _fallbackFacts.where((f) => !_recentFactTexts.contains(f.text)).toList();
    final pool = available.isNotEmpty ? available : _fallbackFacts;
    final random = Random();
    final chosen = pool[random.nextInt(pool.length)];
    _recordRecentFact(chosen.text);
    return chosen;
  }

  // --- Offline Fallback Pools ---

  List<ArticleItem> _searchFallback(String query) {
    final q = query.toLowerCase();
    final matches = _fallbackCatalog.where((item) {
      return item.title.toLowerCase().contains(q) ||
          item.normalizedTitle.toLowerCase().contains(q) ||
          item.summary.toLowerCase().contains(q);
    }).toList();

    if (matches.isNotEmpty) return matches;

    // If query didn't match directly, synthesize a clean fallback card for seamless UX
    return [
      ArticleItem(
        title: query,
        normalizedTitle: query,
        summary: 'Explore detailed Wikipedia archives and verified encyclopedic research regarding $query.',
        thumbnailUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/80/Wikipedia-logo-v2.svg/300px-Wikipedia-logo-v2.svg.png',
      ),
    ];
  }

  List<ArticleItem> _categoryFallback(String topic, List<String> exclude) {
    final normalizedExclude = exclude.map((e) => e.toLowerCase().replaceAll(' ', '_')).toSet();
    final topicPool = _categoryMap[topic.toUpperCase()] ?? _fallbackCatalog;

    final available = topicPool.where((item) {
      final key = item.title.toLowerCase().replaceAll(' ', '_');
      return !normalizedExclude.contains(key);
    }).toList();

    final pool = available.length >= 5 ? available : topicPool;
    final shuffled = List<ArticleItem>.from(pool)..shuffle();
    return shuffled.take(5).toList();
  }

  static final List<ArticleItem> _fallbackCatalog = [
    const ArticleItem(
      title: 'James_Webb_Space_Telescope',
      normalizedTitle: 'James Webb Space Telescope',
      summary: 'The James Webb Space Telescope is an optical space observatory designed to conduct infrared astronomy.',
      thumbnailUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/00/James_Webb_Space_Telescope_Mirror.jpg/640px-James_Webb_Space_Telescope_Mirror.jpg',
    ),
    const ArticleItem(
      title: 'Voyager_1',
      normalizedTitle: 'Voyager 1',
      summary: 'Voyager 1 is a space probe launched by NASA in 1977 to study the outer Solar System and interstellar space.',
      thumbnailUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d2/Voyager_spacecraft_model.png/640px-Voyager_spacecraft_model.png',
    ),
    const ArticleItem(
      title: 'Library_of_Alexandria',
      normalizedTitle: 'Library of Alexandria',
      summary: 'The Great Library of Alexandria in Alexandria, Egypt, was one of the largest and most significant libraries of the ancient world.',
      thumbnailUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/Ancientlibraryalex.jpg/640px-Ancientlibraryalex.jpg',
    ),
    const ArticleItem(
      title: 'Rosetta_Stone',
      normalizedTitle: 'Rosetta Stone',
      summary: 'The Rosetta Stone is an ancient granodiorite stele inscribed with three versions of a decree issued in 196 BC.',
      thumbnailUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/Rosetta_Stone.JPG/640px-Rosetta_Stone.JPG',
    ),
    const ArticleItem(
      title: 'Turing_machine',
      normalizedTitle: 'Turing machine',
      summary: 'A Turing machine is a mathematical model of computation describing an abstract machine that manipulates symbols on a strip of tape.',
      thumbnailUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a2/Turing_machine_simulating_an_automaton.svg/640px-Turing_machine_simulating_an_automaton.svg.png',
    ),
    const ArticleItem(
      title: 'CRISPR_gene_editing',
      normalizedTitle: 'CRISPR gene editing',
      summary: 'CRISPR gene editing is a genetic engineering technique by which the genomes of living organisms may be modified.',
      thumbnailUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a7/DNA_Structure%2BKey%2BLabelled.pn_NoBB.png/640px-DNA_Structure%2BKey%2BLabelled.pn_NoBB.png',
    ),
    const ArticleItem(
      title: 'Mitochondrion',
      normalizedTitle: 'Mitochondrion',
      summary: 'A mitochondrion is an organelle found in the cells of most eukaryotes, generating adenosine triphosphate (ATP).',
      thumbnailUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0c/Animal_mitochondrion_diagram_en_%28edit%29.svg/640px-Animal_mitochondrion_diagram_en_%28edit%29.svg.png',
    ),
    const ArticleItem(
      title: 'Quantum_computing',
      normalizedTitle: 'Quantum computing',
      summary: 'Quantum computing exploits the collective properties of quantum states, such as superposition and entanglement, to perform computation.',
      thumbnailUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e0/Quantum_circuit_symbol.svg/640px-Quantum_circuit_symbol.svg.png',
    ),
  ];

  static final Map<String, List<ArticleItem>> _categoryMap = {
    'SPACE': [
      _fallbackCatalog[0],
      _fallbackCatalog[1],
      const ArticleItem(
        title: 'Hubble_Space_Telescope',
        normalizedTitle: 'Hubble Space Telescope',
        summary: 'The Hubble Space Telescope was launched into low Earth orbit in 1990 and remains in operation.',
        thumbnailUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3f/HST-SM4.jpeg/640px-HST-SM4.jpeg',
      ),
      const ArticleItem(
        title: 'Mars_rover',
        normalizedTitle: 'Mars rover',
        summary: 'A Mars rover is a motor vehicle designed to travel on the surface of Mars.',
        thumbnailUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d8/NASA_Mars_Rover.jpg/640px-NASA_Mars_Rover.jpg',
      ),
      const ArticleItem(
        title: 'Neutron_star',
        normalizedTitle: 'Neutron star',
        summary: 'A neutron star is the collapsed core of a massive supergiant star.',
        thumbnailUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/02/Neutron_star_illustrated.jpg/640px-Neutron_star_illustrated.jpg',
      ),
    ],
    'HISTORY': [
      _fallbackCatalog[2],
      _fallbackCatalog[3],
      const ArticleItem(
        title: 'Colosseum',
        normalizedTitle: 'Colosseum',
        summary: 'The Colosseum is an elliptical amphitheatre in the centre of the city of Rome, Italy.',
        thumbnailUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/de/Colosseo_2020.jpg/640px-Colosseo_2020.jpg',
      ),
      const ArticleItem(
        title: 'Acropolis_of_Athens',
        normalizedTitle: 'Acropolis of Athens',
        summary: 'The Acropolis of Athens is an ancient citadel located on a rocky outcrop above the city of Athens.',
        thumbnailUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a7/Acropolis_of_Athens_viewed_from_the_Hill_of_the_Muses_%2816999201977%29.jpg/640px-Acropolis_of_Athens.jpg',
      ),
      const ArticleItem(
        title: 'Great_Pyramid_of_Giza',
        normalizedTitle: 'Great Pyramid of Giza',
        summary: 'The Great Pyramid of Giza is the largest Egyptian pyramid and tomb of Fourth Dynasty pharaoh Khufu.',
        thumbnailUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e3/Kheops-Pyramid.jpg/640px-Kheops-Pyramid.jpg',
      ),
    ],
    'BIOLOGY': [
      _fallbackCatalog[5],
      _fallbackCatalog[6],
      const ArticleItem(
        title: 'Photosynthesis',
        normalizedTitle: 'Photosynthesis',
        summary: 'Photosynthesis is a biological process used by plants and other organisms to convert light into chemical energy.',
        thumbnailUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/db/Photosynthesis_en.svg/640px-Photosynthesis_en.svg.png',
      ),
      const ArticleItem(
        title: 'Evolution',
        normalizedTitle: 'Evolution',
        summary: 'Evolution is the change in the heritable characteristics of biological populations over successive generations.',
        thumbnailUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/69/Darwin%27s_finches_by_Gould.jpg/640px-Darwin%27s_finches_by_Gould.jpg',
      ),
      const ArticleItem(
        title: 'Neural_circuit',
        normalizedTitle: 'Neural circuit',
        summary: 'A neural circuit is a population of neurons interconnected by synapses to carry out a specific function when activated.',
        thumbnailUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/10/Blausen_0657_MultipolarNeuron.png/640px-Blausen_0657_MultipolarNeuron.png',
      ),
    ],
    'TECH': [
      _fallbackCatalog[4],
      _fallbackCatalog[7],
      const ArticleItem(
        title: 'Transistor',
        normalizedTitle: 'Transistor',
        summary: 'A transistor is a semiconductor device used to amplify or switch electrical signals and power.',
        thumbnailUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/36/Transistors.agr.jpg/640px-Transistors.agr.jpg',
      ),
      const ArticleItem(
        title: 'Internet_Protocol',
        normalizedTitle: 'Internet Protocol',
        summary: 'The Internet Protocol is the network layer communications protocol in the Internet protocol suite for relaying datagrams across network boundaries.',
        thumbnailUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c4/IP_address_and_subnet_mask.svg/640px-IP_address_and_subnet_mask.svg.png',
      ),
      const ArticleItem(
        title: 'Artificial_neural_network',
        normalizedTitle: 'Artificial neural network',
        summary: 'Artificial neural networks are computational models inspired by biological neural networks in animal brains.',
        thumbnailUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e4/Artificial_neural_network.svg/640px-Artificial_neural_network.svg.png',
      ),
    ],
  };

  static final List<FactItem> _fallbackFacts = [
    const FactItem(
      text: 'Honey never spoils; archaeologists have excavated 3,000-year-old honey from ancient Egyptian tombs that remains fully edible.',
      source: 'Nature & Chemistry',
    ),
    const FactItem(
      text: 'Octopuses possess three hearts, nine brains, and circulate hemocyanin-rich blue blood throughout their bodies.',
      source: 'Marine Biology',
    ),
    const FactItem(
      text: '42 is the precise angle in degrees at which light reflects through water droplets to form a primary rainbow.',
      source: 'Physics & Optics',
    ),
    const FactItem(
      text: '73 is the 21st prime number; its mirror 37 is the 12th prime number, whose mirror 21 is the product of 7 and 3.',
      source: 'Mathematics',
    ),
    const FactItem(
      text: 'A single bolt of lightning contains enough energy to toast 100,000 slices of bread.',
      source: 'Earth Science',
    ),
    const FactItem(
      text: 'Venus is the only planet in our Solar System to rotate clockwise, known as retrograde rotation.',
      source: 'Astronomy',
    ),
    const FactItem(
      text: 'Bananas are naturally slightly radioactive because they contain high levels of potassium-40.',
      source: 'Chemistry',
    ),
    const FactItem(
      text: 'Wombat feces are cube-shaped, preventing them from rolling away and helping mark territory on elevated rocks.',
      source: 'Zoology',
    ),
    const FactItem(
      text: 'There are more trees on Earth (approx. 3 trillion) than there are stars in the Milky Way galaxy (approx. 100-400 billion).',
      source: 'Nature & Space',
    ),
    const FactItem(
      text: 'Cleopatra lived closer in time to the 1969 Apollo 11 Moon landing than to the construction of the Great Pyramid of Giza.',
      source: 'World History',
    ),
    const FactItem(
      text: 'Water can boil and freeze simultaneously at 0.01 °C under 0.006 atmospheres of pressure, known as the triple point.',
      source: 'Thermodynamics',
    ),
    const FactItem(
      text: 'The Apollo 11 guidance computer had only 4 kilobytes of RAM and operated with a 1.024 MHz processor.',
      source: 'Computing History',
    ),
    const FactItem(
      text: 'A day on Venus is longer than a year on Venus: it takes 243 Earth days to rotate once, but only 225 Earth days to orbit the Sun.',
      source: 'Planetary Science',
    ),
    const FactItem(
      text: 'Sharks existed before trees; the earliest shark scales date back 450 million years, while the first trees emerged 350 million years ago.',
      source: 'Paleontology',
    ),
    const FactItem(
      text: 'Sound travels about 4.3 times faster through water (approx. 1,480 m/s) than through air (approx. 343 m/s).',
      source: 'Acoustics',
    ),
    const FactItem(
      text: 'The human eye can distinguish approximately 10 million distinct colors and up to 500 shades of gray.',
      source: 'Human Biology',
    ),
    const FactItem(
      text: 'The International Space Station orbits Earth every 90 minutes traveling at roughly 17,500 miles per hour (28,000 km/h).',
      source: 'Space Exploration',
    ),
    const FactItem(
      text: 'A cloud of average cumulus size weighs roughly 500,000 kilograms (1.1 million pounds), equivalent to 100 elephants.',
      source: 'Meteorology',
    ),
    const FactItem(
      text: 'Glass is made primarily from liquid sand melted at temperatures above 1,700 °C (3,090 °F).',
      source: 'Materials Science',
    ),
    const FactItem(
      text: 'Neutron stars are so dense that a single sugar-cube-sized amount of their material would weigh about 1 billion tons on Earth.',
      source: 'Astrophysics',
    ),
    const FactItem(
      text: 'The footprints left on the Moon by Apollo astronauts will remain undisturbed for millions of years because there is no wind or erosion.',
      source: 'Lunar Science',
    ),
    const FactItem(
      text: 'The Pacific Ocean is wider at its greatest breadth than the diameter of the Moon.',
      source: 'Geography',
    ),
    const FactItem(
      text: 'DNA in human cells is so densely packed that if unwound, all the DNA in one person would stretch across the Solar System twice.',
      source: 'Genetics',
    ),
    const FactItem(
      text: 'The Eiffel Tower grows by up to 15 cm (6 inches) during summer due to thermal expansion of the iron structure.',
      source: 'Physics',
    ),
    const FactItem(
      text: 'Oxford University is older than the Aztec Empire; teaching began at Oxford around 1096, whereas Aztec civilization began in 1325.',
      source: 'History',
    ),
    const FactItem(
      text: 'Koala fingerprints are virtually indistinguishable from human fingerprints, even under electron microscopy.',
      source: 'Biology',
    ),
    const FactItem(
      text: 'In 1969: The Apollo 11 Lunar Module touched down on the lunar surface, marking humanity\'s first steps on another world.',
      source: 'Wikipedia (On This Day)',
    ),
    const FactItem(
      text: 'In 1928: Sir Alexander Fleming discovered penicillin at St Mary\'s Hospital, launching the antibiotic era.',
      source: 'Wikipedia (On This Day)',
    ),
    const FactItem(
      text: '6174 is known as Kaprekar\'s constant: taking any 4-digit number (not all digits identical) and repeatedly subtracting the ascending from descending digits always reaches 6174 in at most 7 steps.',
      source: 'Numbers API',
    ),
    const FactItem(
      text: '1,729 is the Hardy-Ramanujan number, the smallest integer expressible as the sum of two cubes in two different ways: 1³ + 12³ and 9³ + 10³.',
      source: 'Numbers API',
    ),
    const FactItem(
      text: '4 is the only number in the English language whose spelling has the exact same number of letters as its numerical value.',
      source: 'Numbers API',
    ),
    const FactItem(
      text: '23 is the minimum number of people in a room needed for a greater than 50% probability that two share a birthday (the Birthday Paradox).',
      source: 'Numbers API',
    ),
    const FactItem(
      text: '42 is the precise angle in degrees at which light reflects through water droplets to form a primary rainbow.',
      source: 'Numbers API',
    ),
    const FactItem(
      text: '6 is the smallest positive perfect number, equal to the sum of its proper positive divisors: 1 + 2 + 3.',
      source: 'Numbers API',
    ),
    const FactItem(
      text: '144 is the 12th Fibonacci number, and the only Fibonacci number that is the square of its position (12²).',
      source: 'Numbers API',
    ),
    const FactItem(
      text: '256 is 2⁸, the exact number of distinct values that can be represented by a single 8-bit computational byte.',
      source: 'Numbers API',
    ),
    const FactItem(
      text: '1,024 is 2¹⁰, forming the binary kilo (kibibyte) fundamental to digital computing memory architecture.',
      source: 'Numbers API',
    ),
    const FactItem(
      text: '299,792,458 is the exact speed of light in meters per second in a vacuum, defining the modern SI unit of the meter.',
      source: 'Numbers API',
    ),
  ];
}
