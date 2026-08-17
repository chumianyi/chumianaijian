import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/project.dart';

class ProjectStorage {
  static const String _draftsDir = 'drafts';

  Future<Directory> _getDraftsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/$_draftsDir');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<void> saveDraft(Project project) async {
    project.updatedAt = DateTime.now();
    project.recalculateDuration();
    final dir = await _getDraftsDirectory();
    final file = File('${dir.path}/${project.id}.json');
    await file.writeAsString(project.toJsonString());
  }

  Future<Project?> loadDraft(String id) async {
    final dir = await _getDraftsDirectory();
    final file = File('${dir.path}/$id.json');
    if (!await file.exists()) return null;
    final content = await file.readAsString();
    return Project.fromJsonString(content);
  }

  Future<List<Project>> listDrafts() async {
    final dir = await _getDraftsDirectory();
    if (!await dir.exists()) return [];
    final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.json'));
    final projects = <Project>[];
    for (final file in files) {
      try {
        final content = await file.readAsString();
        projects.add(Project.fromJsonString(content));
      } catch (_) {}
    }
    projects.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return projects;
  }

  Future<void> deleteDraft(String id) async {
    final dir = await _getDraftsDirectory();
    final file = File('${dir.path}/$id.json');
    if (await file.exists()) await file.delete();
  }

  Future<String> getExportDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/exports');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  Future<String> getTempDirectory() async {
    final appDir = await getTemporaryDirectory();
    final dir = Directory('${appDir.path}/chumian_aijian');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }
}
