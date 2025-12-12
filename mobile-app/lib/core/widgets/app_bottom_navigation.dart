import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'create_menu_overlay.dart';

class AppBottomNavigation extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  State<AppBottomNavigation> createState() => _AppBottomNavigationState();
}

class _AppBottomNavigationState extends State<AppBottomNavigation> {
  final GlobalKey _createButtonKey = GlobalKey();
  OverlayEntry? _overlayEntry;

  void _showCreateMenu() {
    final RenderBox? renderBox =
        _createButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final buttonCenter = Offset(position.dx + (size.width / 2), position.dy);

    _overlayEntry = OverlayEntry(
      builder: (context) => CreateMenuOverlay(
        buttonPosition: buttonCenter,
        onClose: _closeCreateMenu,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _closeCreateMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _closeCreateMenu();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundPrimary.withOpacity(0.3),
            border: Border(
              top: BorderSide(
                color: AppColors.glassBorder.withOpacity(0.1),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            child: Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: _BottomNavItem(
                      icon: Icons.home_outlined,
                      selectedIcon: Icons.home_rounded,
                      isSelected: widget.selectedIndex == 0,
                      onTap: () => widget.onTap(0),
                    ),
                  ),
                  Expanded(
                    child: _BottomNavItem(
                      icon: Icons.people_outline,
                      selectedIcon: Icons.people_rounded,
                      isSelected: widget.selectedIndex == 1,
                      onTap: () => widget.onTap(1),
                    ),
                  ),
                  Expanded(
                    child: _BottomNavItem(
                      key: _createButtonKey,
                      icon: Icons.add_box_outlined,
                      selectedIcon: Icons.add_box_rounded,
                      isSelected: widget.selectedIndex == 2,
                      isCreate: true,
                      onTap: _showCreateMenu,
                    ),
                  ),
                  Expanded(
                    child: _BottomNavItem(
                      icon: Icons.work_outline,
                      selectedIcon: Icons.work_rounded,
                      isSelected: widget.selectedIndex == 3,
                      onTap: () => widget.onTap(3),
                    ),
                  ),
                  Expanded(
                    child: _BottomNavItem(
                      icon: Icons.person_outline,
                      selectedIcon: Icons.person_rounded,
                      isSelected: widget.selectedIndex == 4,
                      onTap: () => widget.onTap(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final bool isSelected;
  final bool isCreate;
  final VoidCallback onTap;
  final Key? key;

  const _BottomNavItem({
    this.key,
    required this.icon,
    required this.selectedIcon,
    required this.isSelected,
    required this.onTap,
    this.isCreate = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isCreate) {
      return GestureDetector(
        onTap: onTap,
        child: Center(
          child: Icon(
            isSelected ? selectedIcon : icon,
            color: isSelected ? AppColors.accentPrimary : AppColors.textPrimary,
            size: 28,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        child: Icon(
          isSelected ? selectedIcon : icon,
          color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
          size: 28,
        ),
      ),
    );
  }
}
