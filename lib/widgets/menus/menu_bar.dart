import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/editor_controller.dart';
import '../../models/keyframe.dart';
import '../../models/track.dart';
import '../../theme/colors.dart';
import '../../theme/neumorphism_theme.dart';
import '../common/neu_widgets.dart';

class AppMenuBar extends StatelessWidget {
  final VoidCallback? onNewProject;
  final VoidCallback? onOpenDraft;
  final VoidCallback? onSave;
  final VoidCallback? onExport;
  final VoidCallback? onSettings;
  final VoidCallback? onCredits;

  const AppMenuBar({
    super.key,
    this.onNewProject,
    this.onOpenDraft,
    this.onSave,
    this.onExport,
    this.onSettings,
    this.onCredits,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.menuBar,
        boxShadow: [
          BoxShadow(color: AppColors.shadowDark.withOpacity(0.2), offset: const Offset(0, 1), blurRadius: 2),
        ],
      ),
      child: Row(
        children: [
          // App icon + title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.primary, AppColors.accent]),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.cut, size: 12, color: Colors.white),
                ),
                const SizedBox(width: 8),
                const Text('初眠爱剪', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              ],
            ),
          ),
          _MenuButton(label: '文件', items: [
            _MenuItem(label: '新建项目', icon: Icons.note_add, onTap: onNewProject),
            _MenuItem(label: '打开草稿', icon: Icons.folder_open, onTap: onOpenDraft),
            _MenuItem(label: '保存', icon: Icons.save, onTap: onSave),
            _MenuDivider(),
            _MenuItem(label: '导出视频', icon: Icons.video_file, onTap: onExport),
          ]),
          _MenuButton(label: '编辑', items: [
            _MenuItem(label: '撤销', icon: Icons.undo, onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('撤销'), duration: Duration(seconds: 1)));
            }),
            _MenuItem(label: '重做', icon: Icons.redo, onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('重做'), duration: Duration(seconds: 1)));
            }),
            _MenuDivider(),
            _MenuItem(label: '分割片段', icon: Icons.content_cut, onTap: () => context.read<EditorController>().splitClipAtPlayhead()),
            _MenuItem(label: '删除选中', icon: Icons.delete, onTap: () => context.read<EditorController>().deleteSelectedClip()),
            _MenuItem(label: '复制片段', icon: Icons.copy, onTap: () {
              final c = context.read<EditorController>();
              final clip = c.selectedClip;
              if (clip != null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已复制: ${clip.name}'), duration: Duration(seconds: 1)));
              }
            }),
          ]),
          _MenuButton(label: '视图', items: [
            _MenuItem(label: '放大时间轴', icon: Icons.zoom_in, onTap: () => context.read<EditorController>().setZoom(context.read<EditorController>().zoom * 1.25)),
            _MenuItem(label: '缩小时间轴', icon: Icons.zoom_out, onTap: () => context.read<EditorController>().setZoom(context.read<EditorController>().zoom / 1.25)),
            _MenuItem(label: '逐帧后退', icon: Icons.fast_rewind, onTap: () => context.read<EditorController>().stepFrame(-1)),
            _MenuItem(label: '逐帧前进', icon: Icons.fast_forward, onTap: () => context.read<EditorController>().stepFrame(1)),
          ]),
          _MenuButton(label: '工具', items: [
            _MenuItem(label: 'AI超能剪', icon: Icons.auto_awesome, onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('点击左侧工具栏AI按钮打开AI超能剪面板'), duration: Duration(seconds: 2)));
            }),
            _MenuItem(label: '色度抠像(绿幕)', icon: Icons.colorize, onTap: () {
              final c = context.read<EditorController>();
              final clip = c.selectedClip;
              if (clip != null) {
                c.setChromaKey(clip.id, 0xFF00FF00, 0.3, 0.1);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已启用绿幕抠像，可在属性面板调整参数'), duration: Duration(seconds: 2)));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先在时间轴选中一个片段'), duration: Duration(seconds: 1)));
              }
            }),
            _MenuItem(label: '添加缩放关键帧', icon: Icons.diamond, onTap: () {
              final c = context.read<EditorController>();
              final clip = c.selectedClip;
              if (clip != null) {
                c.addKeyframe(clip.id, KeyframeProperty.scale, clip.scale);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已在当前时间添加缩放关键帧'), duration: Duration(seconds: 1)));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先在时间轴选中一个片段'), duration: Duration(seconds: 1)));
              }
            }),
            _MenuItem(label: '添加视频轨道', icon: Icons.layers, onTap: () {
              context.read<EditorController>().addTrack(TrackType.video);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已添加新视频轨道(画中画)'), duration: Duration(seconds: 1)));
            }),
          ]),
          _MenuButton(label: '帮助', items: [
            _MenuItem(label: '设置', icon: Icons.settings, onTap: onSettings),
            _MenuItem(label: '致谢', icon: Icons.favorite, onTap: onCredits),
          ]),
          const Spacer(),
          // Window controls (decorative)
          _WindowButton(color: AppColors.warning, icon: Icons.remove),
          const SizedBox(width: 6),
          _WindowButton(color: AppColors.success, icon: Icons.crop_square),
          const SizedBox(width: 6),
          _WindowButton(color: AppColors.error, icon: Icons.close),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _MenuButton extends StatefulWidget {
  final String label;
  final List<_MenuItem> items;
  const _MenuButton({required this.label, required this.items});

  @override
  State<_MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<_MenuButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: PopupMenuButton<_MenuItem>(
        tooltip: widget.label,
        offset: const Offset(0, 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        color: AppColors.surface,
        elevation: 8,
        onSelected: (item) => item.onTap?.call(),
        itemBuilder: (context) => widget.items.map((item) {
          if (item is _MenuDivider) {
            return PopupMenuItem<_MenuItem>(enabled: false, child: const Divider(height: 1));
          }
          return PopupMenuItem<_MenuItem>(
            value: item,
            child: Row(
              children: [
                Icon(item.icon, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 10),
                Text(item.label, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
              ],
            ),
          );
        }).toList(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          height: 32,
          alignment: Alignment.center,
          color: _hovered ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
          child: Text(widget.label, style: TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: _hovered ? FontWeight.w600 : FontWeight.normal)),
        ),
      ),
    );
  }
}

class _MenuItem {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  _MenuItem({required this.label, required this.icon, this.onTap});
}

class _MenuDivider extends _MenuItem {
  _MenuDivider() : super(label: '', icon: Icons.horizontal_rule);
}

class _WindowButton extends StatelessWidget {
  final Color color;
  final IconData icon;
  const _WindowButton({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, size: 10, color: Colors.white.withOpacity(0.7)),
    );
  }
}

class ToolBar extends StatelessWidget {
  final VoidCallback? onNew;
  final VoidCallback? onOpen;
  final VoidCallback? onAI;
  final VoidCallback? onExport;

  const ToolBar({super.key, this.onNew, this.onOpen, this.onAI, this.onExport});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<EditorController>();
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.windowBorder.withOpacity(0.3))),
      ),
      child: Row(
        children: [
          _ToolButton(icon: Icons.note_add, label: '新建', onTap: onNew ?? () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('新建项目'), duration: Duration(seconds: 1)));
          }),
          _ToolButton(icon: Icons.folder_open, label: '打开', onTap: onOpen ?? () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('打开草稿箱'), duration: Duration(seconds: 1)));
          }),
          _ToolButton(icon: Icons.save, label: '保存', onTap: () {
            controller.autoSave();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('项目已保存'), duration: Duration(seconds: 1)));
          }),
          const VerticalDivider(width: 16),
          _ToolButton(icon: Icons.undo, label: '撤销', onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('撤销'), duration: Duration(seconds: 1)));
          }),
          _ToolButton(icon: Icons.redo, label: '重做', onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('重做'), duration: Duration(seconds: 1)));
          }),
          const VerticalDivider(width: 16),
          _ToolButton(icon: Icons.content_cut, label: '分割', onTap: () => controller.splitClipAtPlayhead()),
          _ToolButton(icon: Icons.delete, label: '删除', onTap: () => controller.deleteSelectedClip()),
          const VerticalDivider(width: 16),
          _ToolButton(icon: Icons.zoom_in, label: '放大', onTap: () => controller.setZoom(controller.zoom * 1.25)),
          _ToolButton(icon: Icons.zoom_out, label: '缩小', onTap: () => controller.setZoom(controller.zoom / 1.25)),
          _ToolButton(icon: Icons.fast_rewind, label: '退帧', onTap: () => controller.stepFrame(-1)),
          _ToolButton(icon: Icons.fast_forward, label: '进帧', onTap: () => controller.stepFrame(1)),
          const Spacer(),
          _ToolButton(icon: Icons.auto_awesome, label: 'AI超能剪', onTap: onAI ?? () {}, isPrimary: true),
          const SizedBox(width: 8),
          _ToolButton(icon: Icons.video_file, label: '导出', onTap: onExport ?? () {}, isPrimary: true),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isPrimary;

  const _ToolButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: NeuContainer(
        onTap: onTap,
        borderRadius: 8,
        blur: 4,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        color: isPrimary ? AppColors.primary.withOpacity(0.1) : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isPrimary ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, color: isPrimary ? AppColors.primary : AppColors.textPrimary, fontWeight: isPrimary ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}
