import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../config/update_config.dart';

class AppUpdate {
  AppUpdate({
    required this.latestVersion,
    required this.latestBuild,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.mandatory,
  });

  final String latestVersion;
  final int latestBuild;
  final String downloadUrl;
  final String releaseNotes;
  final bool mandatory;

  factory AppUpdate.fromJson(Map<String, dynamic> json) {
    return AppUpdate(
      latestVersion: json['latestVersion'] as String,
      latestBuild: json['latestBuild'] as int,
      downloadUrl: json['downloadUrl'] as String,
      releaseNotes: json['releaseNotes'] as String? ?? '',
      mandatory: json['mandatory'] as bool? ?? false,
    );
  }
}

class UpdateService {
  Future<AppUpdate?> checkForUpdate() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;
    final response = await http.get(Uri.parse(UpdateConfig.manifestUrl));
    if (response.statusCode >= 400) {
      throw Exception('Unable to check for updates');
    }
    final update = AppUpdate.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    return update.latestBuild > currentBuild ? update : null;
  }

  Future<void> openDownload(AppUpdate update) async {
    final response = await http.get(Uri.parse(update.downloadUrl));
    if (response.statusCode >= 400 || response.bodyBytes.isEmpty) {
      throw Exception('Unable to download APK update');
    }
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/polyht_student_${update.latestVersion}_${update.latestBuild}.apk');
    await file.writeAsBytes(response.bodyBytes, flush: true);
    final result = await OpenFilex.open(file.path, type: 'application/vnd.android.package-archive');
    if (result.type != ResultType.done) {
      throw Exception(result.message);
    }
  }
}
