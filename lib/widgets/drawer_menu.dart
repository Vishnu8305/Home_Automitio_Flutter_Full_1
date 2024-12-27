import 'package:flutter/material.dart';
import '../screens/settings.dart';
import '../screens/about_us.dart';
import '../screens/contact_us.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class DrawerMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [Color(0xFF1E1E1E), Color(0xFF2D2D2D)]
                : [Color(0xFF0D7377), Color(0xFF14BDAC)],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.home,
                      size: 35,
                      color: Color(0xFF0D7377),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Smart Home',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Control your home devices',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              icon: Icons.dashboard,
              title: 'Dashboard',
              onTap: () => Navigator.pop(context),
              context: context,
            ),
            _buildDrawerItem(
              icon: Icons.settings,
              title: 'Settings',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsPage()),
                );
              },
              context: context,
            ),
            _buildDrawerItem(
              icon: Icons.info,
              title: 'About Us',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AboutUsPage()),
                );
              },
              context: context,
            ),
            _buildDrawerItem(
              icon: Icons.contact_support,
              title: 'Contact Us',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ContactUsPage()),
                );
              },
              context: context,
            ),
            Divider(color: Colors.white24, thickness: 1),
            _buildDrawerItem(
              icon: Icons.help,
              title: 'Help & Support',
              onTap: () {
                // Show help dialog
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Help & Support'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Email: support@smarthome.com'),
                        SizedBox(height: 8),
                        Text('Phone: +1-234-567-8900'),
                        SizedBox(height: 8),
                        Text('Version: 1.0.0'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Close'),
                      ),
                    ],
                  ),
                );
              },
              context: context,
            ),
            _buildDrawerItem(
              icon: Icons.privacy_tip,
              title: 'Privacy Policy',
              onTap: () {
                // Show privacy policy
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Privacy Policy'),
                    content: SingleChildScrollView(
                      child: Text(
                        'Your privacy is important to us. This app collects minimal data necessary for device operation.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Close'),
                      ),
                    ],
                  ),
                );
              },
              context: context,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required BuildContext context,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white, size: 24),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      hoverColor: Colors.white.withOpacity(0.1),
      selectedTileColor: Colors.white.withOpacity(0.1),
    );
  }
}
