import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/neumorphism_theme.dart';

class NeuContainer extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final bool pressed;
  final VoidCallback? onTap;
  final double width;
  final double height;

  const NeuContainer({
    super.key,
    required this.child,
    this.borderRadius = 12,
    this.blur = 12,
    this.padding,
    this.margin,
    this.color,
    this.pressed = false,
    this.onTap,
    this.width = 0,
    this.height = 0,
  });

  @override
  State<NeuContainer> createState() => _NeuContainerState();
}

class _NeuContainerState extends State<NeuContainer> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isPressed = widget.pressed || _isPressed;
    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.onTap != null ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: widget.onTap != null ? () => setState(() => _isPressed = false) : null,
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: widget.width > 0 ? widget.width : null,
        height: widget.height > 0 ? widget.height : null,
        padding: widget.padding,
        margin: widget.margin,
        decoration: BoxDecoration(
          color: widget.color ?? AppColors.surface,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: isPressed
              ? NeuShadow.concave(blur: widget.blur)
              : NeuShadow.convex(blur: widget.blur),
        ),
        child: widget.child,
      ),
    );
  }
}

class NeuButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double borderRadius;
  final double padding;
  final Color? color;
  final bool isPrimary;
  final IconData? icon;

  const NeuButton({
    super.key,
    required this.child,
    this.onPressed,
    this.borderRadius = 10,
    this.padding = 12,
    this.color,
    this.isPrimary = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return NeuContainer(
      onTap: onPressed,
      borderRadius: borderRadius,
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding * 0.6),
      color: isPrimary ? AppColors.primary : color,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: isPrimary ? Colors.white : AppColors.textPrimary),
            const SizedBox(width: 6),
          ],
          DefaultTextStyle(
            style: TextStyle(
              color: isPrimary ? Colors.white : AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class NeuIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final Color? color;
  final String? tooltip;
  final bool active;

  const NeuIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 36,
    this.iconSize = 18,
    this.color,
    this.tooltip,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: NeuContainer(
        onTap: onPressed,
        borderRadius: size / 2,
        width: size,
        height: size,
        pressed: active,
        padding: EdgeInsets.zero,
        child: Center(
          child: Icon(icon, size: iconSize, color: active ? AppColors.primary : (color ?? AppColors.textSecondary)),
        ),
      ),
    );
  }
}

class NeuSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final String? label;
  final int? divisions;

  const NeuSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.label,
    this.divisions,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(label!, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ),
        NeuContainer(
          borderRadius: 8,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: RoundSliderOverlayShape(overlayRadius: 16),
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.shadowDark.withOpacity(0.3),
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withOpacity(0.2),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
