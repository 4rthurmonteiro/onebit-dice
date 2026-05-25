import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:onebit_dice/core/storage/hive_init.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HiveInit.registerAndOpen', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_init_test');
      Hive.init(tempDir.path);
    });

    tearDown(() async {
      await Hive.close();
      await tempDir.delete(recursive: true);
    });

    test('opens both boxes and registers adapters', () async {
      final boxes = await HiveInit.registerAndOpen();

      expect(boxes.rollHistory.isOpen, isTrue);
      expect(boxes.customPresets.isOpen, isTrue);
      expect(Hive.isAdapterRegistered(0), isTrue);
      expect(Hive.isAdapterRegistered(1), isTrue);
    });

    test('is idempotent: calling twice does not throw', () async {
      await HiveInit.registerAndOpen();
      await expectLater(HiveInit.registerAndOpen(), completes);
    });
  });

  group('HiveInit.init', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_init_full_test');
      const channel = MethodChannel('plugins.flutter.io/path_provider');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async => tempDir.path);
    });

    tearDown(() async {
      await Hive.close();
      const channel = MethodChannel('plugins.flutter.io/path_provider');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      await tempDir.delete(recursive: true);
    });

    test(
      'initFlutter resolves the documents dir and opens both boxes',
      () async {
        final boxes = await HiveInit.init();
        expect(boxes.rollHistory.isOpen, isTrue);
        expect(boxes.customPresets.isOpen, isTrue);
      },
    );
  });
}
