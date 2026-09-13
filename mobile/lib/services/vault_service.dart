import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/models/feed_models.dart';

class VaultService {
  static final VaultService instance = VaultService._internal();
  VaultService._internal();

  /// Resolves backend base URL
  String get _baseUrl {
    if (kIsWeb) return 'http://localhost:8000';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    } catch (_) {}
    return 'http://localhost:8000';
  }

  /// Fetches the past 30 days of archived packs
  Future<List<VaultHistoryItem>> fetchVaultHistory() async {
    final url = Uri.parse('$_baseUrl/api/v1/vault/history');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
        return list.map((e) => VaultHistoryItem.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {
      // Graceful offline fallback
    }

    return _generateFallbackHistory();
  }

  /// Generates the past 14 days of realistic mock history for offline testing
  List<VaultHistoryItem> _generateFallbackHistory() {
    final now = DateTime.now();
    final List<VaultHistoryItem> items = [];

    final mockArticlesPool = [
      ['James Webb Space Telescope', 'Hubble Space Telescope', 'Voyager 1'],
      ['Library of Alexandria', 'Rosetta Stone', 'Great Pyramid of Giza'],
      ['CRISPR Gene Editing', 'Mitochondrion', 'DNA Replication'],
      ['Turing Machine', 'Quantum Computing', 'Transistor History'],
      ['Mars Rover Curiosity', 'Saturn V Rocket', 'Apollo 11 Mission'],
      ['The Colosseum', 'Acropolis of Athens', 'Parthenon Sculptures'],
      ['Theory of Relativity', 'Black Hole Event Horizon', 'Neutron Stars'],
    ];

    final mockThumbs = [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/0/00/James_Webb_Space_Telescope_Mirror.jpg/640px-James_Webb_Space_Telescope_Mirror.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/Ancientlibraryalex.jpg/640px-Ancientlibraryalex.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a7/DNA_Structure%2BKey%2BLabelled.pn_NoBB.png/640px-DNA_Structure%2BKey%2BLabelled.pn_NoBB.png',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a2/Turing_machine_simulating_an_automaton.svg/640px-Turing_machine_simulating_an_automaton.svg.png',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d8/NASA_Mars_Rover.jpg/640px-NASA_Mars_Rover.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/d/de/Colosseo_2020.jpg/640px-Colosseo_2020.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/0/02/Neutron_star_illustrated.jpg/640px-Neutron_star_illustrated.jpg',
    ];

    final mockFacts = [
      'Honey never spoils; excavated 3,000-year-old honey from tombs is edible.',
      'Octopuses possess three hearts and circulate blue blood.',
      '42 is the precise angle at which light reflects to form a rainbow.',
      '73 is the 21st prime number; its mirror 37 is the 12th prime number.',
      'In 1969: Apollo 11 Lunar Module touched down on the Moon.',
      'In 1928: Sir Alexander Fleming discovered penicillin.',
      'Neutron stars can spin at a rate of 600 rotations per second.',
    ];

    for (int i = 1; i <= 14; i++) {
      final pastDate = now.subtract(Duration(days: i));
      final dateStr = '${pastDate.year}-${pastDate.month.toString().padLeft(2, '0')}-${pastDate.day.toString().padLeft(2, '0')}';
      final poolIndex = (i - 1) % mockArticlesPool.length;

      items.add(
        VaultHistoryItem(
          packDate: dateStr,
          heroThumbnailUrl: mockThumbs[poolIndex],
          articleTitles: mockArticlesPool[poolIndex],
          factPreview: mockFacts[poolIndex],
          createdAt: pastDate.toIso8601String(),
        ),
      );
    }

    return items;
  }
}
