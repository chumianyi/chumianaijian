import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/editor_controller.dart';
import '../../models/clip.dart';
import '../../models/keyframe.dart';
import '../../theme/colors.dart';
import '../common/neu_widgets.dart';

class PropertiesPanel extends StatefulWidget {
  const PropertiesPanel({super.key});

  @override
  State<PropertiesPanel> createState() => _PropertiesPanelState();
}

class _PropertiesPanelState extends State<PropertiesPanel> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EditorController>(
      builder: (context, controller, _) {
        final clip = controller.selectedClip;
        return Container(
          width: 280,
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [BoxShadow(color: AppColors.shadowDark.withOpacity(0.2), offset: const Offset(-2, 0), blurRadius: 6)],
          ),
          child: clip == null
              ? _buildEmptyState()
              : Column(
                  children: [
                    _buildClipHeader(clip),
                    TabBar(
                      controller: _tabController,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textSecondary,
                      indicatorColor: AppColors.primary,
                      labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      tabs: const [
                        Tab(text: '变换'),
                        Tab(text: '关键帧'),
                        Tab(text: '抠像'),
                        Tab(text: '音频'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildTransformTab(controller, clip),
                          _buildKeyframeTab(controller, clip),
                          _buildChromaKeyTab(controller, clip),
                          _buildAudioTab(controller, clip),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.tune, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text('选择一个片段以编辑属性', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildClipHeader(Clip clip) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.windowBorder.withOpacity(0.3))),
      ),
      child: Row(
        children: [
          Icon(Icons.video_library, size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(clip.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('${clip.type.name} · ${clip.duration.inSeconds}s', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransformTab(EditorController controller, Clip clip) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        NeuSlider(
          label: '缩放',
          value: clip.scale,
          min: 0.1,
          max: 3.0,
          onChanged: (v) => controller.updateClipProperty(clip.id, scale: v),
        ),
        const SizedBox(height: 12),
        NeuSlider(
          label: '位置 X',
          value: clip.positionX,
          min: -1,
          max: 1,
          onChanged: (v) => controller.updateClipProperty(clip.id, positionX: v),
        ),
        const SizedBox(height: 12),
        NeuSlider(
          label: '位置 Y',
          value: clip.positionY,
          min: -1,
          max: 1,
          onChanged: (v) => controller.updateClipProperty(clip.id, positionY: v),
        ),
        const SizedBox(height: 12),
        NeuSlider(
          label: '透明度',
          value: clip.opacity,
          min: 0,
          max: 1,
          onChanged: (v) => controller.updateClipProperty(clip.id, opacity: v),
        ),
        const SizedBox(height: 12),
        NeuSlider(
          label: '旋转 (°)',
          value: clip.rotation,
          min: -180,
          max: 180,
          onChanged: (v) => controller.updateClipProperty(clip.id, rotation: v),
        ),
        const SizedBox(height: 16),
        NeuButton(
          icon: Icons.refresh,
          onPressed: () => controller.updateClipProperty(clip.id, scale: 1, positionX: 0, positionY: 0, opacity: 1, rotation: 0),
          child: const Text('重置变换'),
        ),
      ],
    );
  }

  Widget _buildKeyframeTab(EditorController controller, Clip clip) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text('在当前播放头位置添加关键帧', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: KeyframeProperty.values.map((prop) {
            return NeuButton(
              icon: Icons.add,
              padding: 8,
              onPressed: () {
                double value = 0;
                switch (prop) {
                  case KeyframeProperty.scale: value = clip.scale; break;
                  case KeyframeProperty.positionX: value = clip.positionX; break;
                  case KeyframeProperty.positionY: value = clip.positionY; break;
                  case KeyframeProperty.opacity: value = clip.opacity; break;
                  case KeyframeProperty.rotation: value = clip.rotation; break;
                }
                controller.addKeyframe(clip.id, prop, value);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已添加 ${prop.name} 关键帧'), duration: const Duration(seconds: 1)));
              },
              child: Text(prop.name),
            );
          }).toList(),
        ),
        const Divider(),
        Expanded(
          child: clip.keyframes.isEmpty
              ? Center(child: Text('暂无关键帧', style: TextStyle(color: AppColors.textMuted, fontSize: 12)))
              : ListView.builder(
                  itemCount: clip.keyframes.length,
                  itemBuilder: (context, index) {
                    final kf = clip.keyframes[index];
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.diamond, size: 14, color: AppColors.accent),
                      title: Text('${kf.property.name} = ${kf.value.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11)),
                      subtitle: Text('${kf.time.inMilliseconds}ms', style: TextStyle(fontSize: 9, color: AppColors.textSecondary)),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () => controller.removeKeyframe(clip.id, kf.id),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildChromaKeyTab(EditorController controller, Clip clip) {
    final chroma = clip.chromaKey;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text('色度抠像 (绿幕/蓝幕)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        if (chroma != null) ...[
          Row(
            children: [
              Text('启用', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Switch(value: chroma.enabled, onChanged: (_) => controller.toggleChromaKey(clip.id)),
            ],
          ),
          const SizedBox(height: 8),
          Text('抠像颜色', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Row(
            children: [
              _ColorPresetButton(color: 0xFF00FF00, label: '绿幕', onTap: () => controller.setChromaKey(clip.id, 0xFF00FF00, chroma.threshold, chroma.softness)),
              const SizedBox(width: 8),
              _ColorPresetButton(color: 0xFF0000FF, label: '蓝幕', onTap: () => controller.setChromaKey(clip.id, 0xFF0000FF, chroma.threshold, chroma.softness)),
              const SizedBox(width: 8),
              _ColorPresetButton(color: 0xFFFF0000, label: '红幕', onTap: () => controller.setChromaKey(clip.id, 0xFFFF0000, chroma.threshold, chroma.softness)),
            ],
          ),
          const SizedBox(height: 12),
          NeuSlider(
            label: '容差',
            value: chroma.threshold,
            min: 0,
            max: 1,
            onChanged: (v) => controller.setChromaKey(clip.id, chroma.color, v, chroma.softness),
          ),
          const SizedBox(height: 12),
          NeuSlider(
            label: '边缘羽化',
            value: chroma.softness,
            min: 0,
            max: 0.5,
            onChanged: (v) => controller.setChromaKey(clip.id, chroma.color, chroma.threshold, v),
          ),
        ] else ...[
          NeuButton(
            icon: Icons.colorize,
            isPrimary: true,
            onPressed: () => controller.setChromaKey(clip.id, 0xFF00FF00, 0.3, 0.1),
            child: const Text('启色度抠像'),
          ),
        ],
        const SizedBox(height: 20),
        Text('手动抠像 (遮罩)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Text('在预览窗口绘制遮罩区域', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        NeuButton(
          icon: Icons.brush,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('手动遮罩模式：在预览区拖动绘制')));
          },
          child: const Text('画笔遮罩'),
        ),
      ],
    );
  }

  Widget _buildAudioTab(EditorController controller, Clip clip) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        NeuSlider(
          label: '音量',
          value: clip.volume,
          min: 0,
          max: 2,
          onChanged: (v) => controller.updateClipProperty(clip.id, volume: v),
        ),
        const SizedBox(height: 12),
        NeuSlider(
          label: '播放速度',
          value: clip.speed,
          min: 0.25,
          max: 4,
          divisions: 15,
          onChanged: (v) {},
        ),
        const SizedBox(height: 16),
        Text('音频轨道将在导出时混合', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
      ],
    );
  }
}

class _ColorPresetButton extends StatelessWidget {
  final int color;
  final String label;
  final VoidCallback onTap;
  const _ColorPresetButton({required this.color, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(width: 32, height: 32, decoration: BoxDecoration(color: Color(color), borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.windowBorder))),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
