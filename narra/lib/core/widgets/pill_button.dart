import 'package:material_ui/material_ui.dart';

import '../theme/tokens.dart';

/// Fully rounded 40px button. [filled] is the primary blue "Add" style; the
/// default is the light grey "Listen" style.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.filled = false,
    this.iconSize = 20,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool filled;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? NarraColors.onPrimary : NarraColors.textPrimary;
    final bg = filled ? NarraColors.primary : NarraColors.surfaceMuted;
    final hover = filled ? const Color(0xFF2236E0) : const Color(0xFFEDEDED);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: bg,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          hoverColor: hover,
          child: SizedBox(
            height: NarraSizes.controlHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: iconSize, color: fg),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: NarraText.button.copyWith(color: fg),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
