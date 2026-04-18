import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class SideBar extends StatefulWidget {
  final ValueChanged<String> onItemSelected;
  final String selectedPage;

  const SideBar({
    super.key,
    required this.onItemSelected,
    required this.selectedPage,
  });

  @override
  State<SideBar> createState() => _SideBarState();
}

class _SideBarState extends State<SideBar> {
  bool isCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = settings.isDarkMode;
    
    // Palette Modern Dark & Light Premium
    final Color sideBarBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF064E3B);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isCollapsed ? 85 : 260,
      decoration: BoxDecoration(
        color: sideBarBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.05),
            blurRadius: 20,
            offset: const Offset(5, 0),
          )
        ],
        border: Border(
          right: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // ---- LOGO + Bouton collapse ----
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: isCollapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.spaceBetween,
              children: [
                if (!isCollapsed)
                  Text(
                    "EcoVision",
                    style: TextStyle(
                      fontSize: 22,
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                IconButton(
                  icon: Icon(
                    isCollapsed ? Icons.menu : Icons.menu_open,
                    color: textColor.withOpacity(0.8),
                  ),
                  onPressed: () => setState(() => isCollapsed = !isCollapsed),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // ---- MENU ITEMS ----
          _buildItem(context, Icons.dashboard_outlined, "dashboard"),
          _buildItem(context, Icons.precision_manufacturing_outlined, "machines"),
          _buildItem(context, Icons.people_outline, "clients"),
          _buildItem(context, Icons.analytics_outlined, "analytics"),
          _buildItem(context, Icons.settings_outlined, "settings"),

          const Spacer(),

          _buildItem(context, Icons.logout_rounded, "logout", isLogout: true),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, IconData icon, String page, {bool isLogout = false}) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final isDark = settings.isDarkMode;
    final isSelected = widget.selectedPage == page;
    const activeColor = Color(0xFF10B981);
    final Color textColor = isDark ? Colors.white : const Color(0xFF064E3B);

    return InkWell(
      onTap: () => widget.onItemSelected(page),
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected ? activeColor.withOpacity(0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  color: isLogout 
                      ? Colors.redAccent 
                      : (isSelected ? activeColor : textColor.withOpacity(0.6)),
                  size: 24,
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      settings.translate(page),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isLogout 
                            ? Colors.redAccent 
                            : (isSelected ? (isDark ? Colors.white : textColor) : textColor.withOpacity(0.6)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Indicateur de sélection (barre verticale lumineuse)
          if (isSelected && !isLogout)
            Positioned(
              left: 4,
              top: 12,
              bottom: 12,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: activeColor,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(color: activeColor.withOpacity(0.6), blurRadius: 8)
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
