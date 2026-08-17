import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/editor_controller.dart';
import '../models/project.dart';
import '../services/project_storage.dart';
import '../theme/colors.dart';
import '../widgets/common/neu_widgets.dart';
import 'editor_screen.dart';

class DraftsScreen extends StatefulWidget {
  const DraftsScreen({super.key});

  @override
  State<DraftsScreen> createState() => _DraftsScreenState();
}

class _DraftsScreenState extends State<DraftsScreen> {
  final ProjectStorage _storage = ProjectStorage();
  List<Project> _drafts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDrafts();
  }

  Future<void> _loadDrafts() async {
    setState(() => _loading = true);
    final drafts = await _storage.listDrafts();
    setState(() {
      _drafts = drafts;
      _loading = false;
    });
  }

  Future<void> _openDraft(Project project) async {
    final controller = context.read<EditorController>();
    await controller.loadProject(project);
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const EditorScreen()));
    }
  }

  Future<void> _deleteDraft(String id) async {
    await _storage.deleteDraft(id);
    _loadDrafts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text('草稿箱', style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadDrafts),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _drafts.isEmpty
              ? _buildEmpty()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _drafts.length,
                  itemBuilder: (context, index) => _buildDraftCard(_drafts[index]),
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 64, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text('暂无草稿', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text('开始剪辑后项目会自动保存到这里', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildDraftCard(Project project) {
    return NeuContainer(
      margin: const EdgeInsets.only(bottom: 12),
      borderRadius: 12,
      padding: const EdgeInsets.all(16),
      onTap: () => _openDraft(project),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.primary, AppColors.accent]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.movie, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(project.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text('${project.width}x${project.height} · ${project.fps}fps · ${project.totalDuration.inSeconds}s', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text('更新于 ${_formatDate(project.updatedAt)}', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: () => _deleteDraft(project.id),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
  }
}
