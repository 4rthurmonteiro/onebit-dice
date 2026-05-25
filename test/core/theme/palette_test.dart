import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/core/theme/palette.dart';

void main() {
  group('Palette', () {
    test('registers exactly 7 palettes', () {
      expect(Palette.all.length, 7);
    });

    test('every PaletteId has a matching entry', () {
      for (final id in PaletteId.values) {
        expect(Palette.all.containsKey(id), isTrue, reason: 'missing $id');
        expect(Palette.of(id).id, id);
      }
    });

    test('hex codes match the roadmap spec (regression guard)', () {
      const expected = <PaletteId, ({int ink, int paper, String name})>{
        PaletteId.macClassic: (
          ink: 0xFF000000,
          paper: 0xFFFFFFFF,
          name: 'Mac Classic',
        ),
        PaletteId.macBeige: (
          ink: 0xFF000000,
          paper: 0xFFC7C7C7,
          name: 'Mac Beige',
        ),
        PaletteId.gameBoy: (
          ink: 0xFF0F380F,
          paper: 0xFF9BBC0F,
          name: 'Game Boy DMG',
        ),
        PaletteId.c64: (
          ink: 0xFF352879,
          paper: 0xFF7869C4,
          name: 'Commodore 64',
        ),
        PaletteId.zxSpectrum: (
          ink: 0xFF000000,
          paper: 0xFF00FF00,
          name: 'ZX Spectrum',
        ),
        PaletteId.appleIIGreen: (
          ink: 0xFF000000,
          paper: 0xFF33FF33,
          name: 'Apple II Green',
        ),
        PaletteId.appleIIeAmber: (
          ink: 0xFF000000,
          paper: 0xFFFF9933,
          name: 'Apple //e Amber',
        ),
      };

      for (final entry in expected.entries) {
        final p = Palette.of(entry.key);
        expect(p.ink, Color(entry.value.ink), reason: '${entry.key} ink');
        expect(p.paper, Color(entry.value.paper), reason: '${entry.key} paper');
        expect(p.name, entry.value.name, reason: '${entry.key} name');
      }
    });
  });
}
