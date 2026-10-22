import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';

/// A compact, floating navigation treatment shared by the three app roles.
/// It keeps the primary destinations visible without competing with map content.
class RoleNavigationBar extends StatelessWidget {
  const RoleNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onSelected,
    required this.destinations,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;
  final List<RoleNavigationDestination> destinations;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.darkBg,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x330D1B2A),
              blurRadius: 22,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: SizedBox(
          height: 68,
          child: Row(
            children: List.generate(destinations.length, (index) {
              final destination = destinations[index];
              final selected = index == currentIndex;
              return Expanded(
                child: Semantics(
                  selected: selected,
                  button: true,
                  label: destination.label,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onSelected(index);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.white.withValues(alpha: 0.16)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            selected
                                ? destination.selectedIcon
                                : destination.icon,
                            color: selected
                                ? Colors.white
                                : const Color(0xFFB8C7D6),
                            size: 21,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            destination.label,
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFFB8C7D6),
                              fontSize: 10,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class RoleNavigationDestination {
  const RoleNavigationDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
