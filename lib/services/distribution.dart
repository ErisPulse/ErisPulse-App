// 发行版清单：custom/ CI 定制构建注入 assets/custom/manifest.json，官方构建为空默认值。

import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:flutter/services.dart' show rootBundle;

const String kDistributionManifestAsset = 'assets/custom/manifest.json';

const String kDistributionNoticeSeenKey = 'erispulse.distribution_notice_seen';

class PreinstalledItem {
  const PreinstalledItem({
    required this.name,
    this.type,
    this.version,
    this.description,
  });

  final String name;
  final String? type;
  final String? version;
  final String? description;

  factory PreinstalledItem.fromJson(Map<String, dynamic> json) =>
      PreinstalledItem(
        name: json['name'] as String? ?? '',
        type: json['type'] as String?,
        version: json['version'] as String?,
        description: json['description'] as String?,
      );
}

class Distribution {
  Distribution._({
    required this.name,
    required this.vendor,
    this.homepage,
    this.contact,
    this.preinstalled = const [],
    this.firstLaunchNotice,
    this.createInstanceNotice,
    this.defaultDownloadSource,
    this.defaultPypiSource,
    this.customPypiIndexUrl,
    this.customPypiLabel,
    this.releaseBase,
  });

  static Distribution instance = Distribution._official();

  static Distribution _official() => Distribution._(
        name: 'ErisPulse',
        vendor: 'ErisPulse Official',
        homepage: 'https://github.com/ErisPulse/ErisPulse-App',
      );

  final String name;
  final String vendor;
  final String? homepage;
  final String? contact;
  final List<PreinstalledItem> preinstalled;
  final String? firstLaunchNotice;
  final String? createInstanceNotice;
  final String? defaultDownloadSource;
  final String? defaultPypiSource;
  final String? customPypiIndexUrl;
  final String? customPypiLabel;
  final String? releaseBase;

  bool get isOfficial => identical(instance, _officialInstance) || _isDefault;

  bool get _isDefault =>
      name == 'ErisPulse' &&
      preinstalled.isEmpty &&
      firstLaunchNotice == null &&
      createInstanceNotice == null &&
      defaultDownloadSource == null &&
      defaultPypiSource == null &&
      customPypiIndexUrl == null &&
      releaseBase == null;

  bool get hasFirstLaunchContent =>
      !isOfficial && (preinstalled.isNotEmpty || firstLaunchNotice != null);

  String get displayTitle => isOfficial ? 'ErisPulse-App' : name;

  static Future<void> load() async {
    try {
      final raw = await rootBundle.loadString(kDistributionManifestAsset);
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        instance = Distribution._fromJson(decoded);
      }
    } catch (_) {}
  }

  @visibleForTesting
  static Distribution fromJsonForTest(Map<String, dynamic> json) =>
      Distribution._fromJson(json);

  static final Distribution _officialInstance = Distribution._official();

  factory Distribution._fromJson(Map<String, dynamic> json) {
    final dist = _map(json['distribution']);
    final notices = _map(json['notices']);
    final defaults = _map(json['defaults']);
    final download = _map(json['download']);

    final preinstalledRaw = json['preinstalled'];
    final preinstalled = [
      if (preinstalledRaw is List)
        for (final item in preinstalledRaw)
          if (item is Map<String, dynamic>) PreinstalledItem.fromJson(item),
    ];

    return Distribution._(
      name: dist['name'] as String? ?? 'ErisPulse',
      vendor: dist['vendor'] as String? ?? 'ErisPulse Official',
      homepage: _str(dist['homepage']),
      contact: _str(dist['contact']),
      preinstalled: preinstalled,
      firstLaunchNotice: _str(notices['firstLaunch']),
      createInstanceNotice: _str(notices['createInstance']),
      defaultDownloadSource: _str(defaults['downloadSource']),
      defaultPypiSource: _str(defaults['pypiSource']),
      customPypiIndexUrl: _str(defaults['pypiIndexUrl']),
      customPypiLabel: _str(defaults['pypiLabel']),
      releaseBase: _str(download['releaseBase']),
    );
  }

  static Map<String, dynamic> _map(Object? v) =>
      v is Map<String, dynamic> ? v : const {};

  static String? _str(Object? v) =>
      v is String && v.trim().isNotEmpty ? v : null;
}
