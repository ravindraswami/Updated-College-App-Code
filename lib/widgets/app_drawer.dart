import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class DrawerItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  const DrawerItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}

class AppDrawer extends StatelessWidget {
  final UserModel? user;
  final int selectedIndex;
  final List<DrawerItem> items;
  final void Function(int) onItemTap;
  final VoidCallback onLogout;
  final Color accentColor;

  const AppDrawer({
    super.key,
    required this.user,
    required this.selectedIndex,
    required this.items,
    required this.onItemTap,
    required this.onLogout,
    this.accentColor = AppTheme.primary,
  });

  @override
  Widget build(BuildContext context) {
    final u = user;
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accentColor, accentColor.withOpacity(0.75)],
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withOpacity(0.25),
                    child: Text(
                      u?.displayName.isNotEmpty == true
                          ? u!.displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    u?.displayName ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppConstants.roleLabel(u?.role ?? ''),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  if (u?.erpId.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        u!.erpId,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── Menu items ───────────────────────────────────
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final item = items[i];
                  final selected = i == selectedIndex;
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 2,
                    ),
                    child: ListTile(
                      selected: selected,
                      selectedTileColor: accentColor.withOpacity(0.1),
                      selectedColor: accentColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      leading: Icon(
                        selected ? item.selectedIcon : item.icon,
                        color: selected ? accentColor : Colors.grey[600],
                        size: 22,
                      ),
                      title: Text(
                        item.label,
                        style: TextStyle(
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          fontSize: 14,
                          color: selected ? accentColor : Colors.black87,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        onItemTap(i);
                      },
                    ),
                  );
                },
              ),
            ),

            // ── Logout ───────────────────────────────────────
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: ListTile(
                leading: const Icon(
                  Icons.logout,
                  color: AppTheme.error,
                  size: 22,
                ),
                title: const Text(
                  'Logout',
                  style: TextStyle(
                    color: AppTheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onLogout();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
