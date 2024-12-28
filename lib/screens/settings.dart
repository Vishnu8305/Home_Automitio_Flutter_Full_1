import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' show pi, cos, sin, sqrt;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';
import 'dart:io';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with SingleTickerProviderStateMixin {
  bool darkMode = false;
  bool notifications = true;
  String username = 'Smart Home User';
  int selectedAvatarIndex = 0;

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    loadSettings();
    _controller = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      darkMode = prefs.getBool('darkMode') ?? false;
      notifications = prefs.getBool('notifications') ?? true;
      username = prefs.getString('username') ?? 'Smart Home User';
      selectedAvatarIndex = prefs.getInt('avatarIndex') ?? 0;
    });
  }

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', darkMode);
    await prefs.setBool('notifications', notifications);
    await prefs.setString('username', username);
    await prefs.setInt('avatarIndex', selectedAvatarIndex);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Settings saved successfully!'),
        backgroundColor: Color(0xFF0D7377),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showUsernameDialog() {
    final TextEditingController usernameController =
        TextEditingController(text: username);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Username'),
        content: TextField(
          controller: usernameController,
          decoration: InputDecoration(
            hintText: 'Enter your username',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                username = usernameController.text.trim().isNotEmpty
                    ? usernameController.text.trim()
                    : 'Smart Home User';
              });
              saveSettings();
              Navigator.pop(context);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAvatarSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Avatar'),
        content: SingleChildScrollView(
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildAvatarOption(Icons.person_rounded),
              _buildAvatarOption(Icons.person_outline_rounded),
              _buildAvatarOption(Icons.face_rounded),
              _buildAvatarOption(Icons.sentiment_satisfied_rounded),
              _buildAvatarOption(Icons.tag_faces_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarOption(IconData iconData) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedAvatarIndex = [
                Icons.person_rounded,
                Icons.person_outline_rounded,
                Icons.face_rounded,
                Icons.sentiment_satisfied_rounded,
                Icons.tag_faces_rounded
              ].indexOf(iconData) +
              1;
        });
        saveSettings();
        Navigator.pop(context);
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: selectedAvatarIndex ==
                    [
                          Icons.person_rounded,
                          Icons.person_outline_rounded,
                          Icons.face_rounded,
                          Icons.sentiment_satisfied_rounded,
                          Icons.tag_faces_rounded
                        ].indexOf(iconData) +
                        1
                ? Color(0xFF0D7377)
                : Colors.transparent,
            width: 3,
          ),
          borderRadius: BorderRadius.circular(50),
        ),
        child: CircleAvatar(
          radius: 40,
          backgroundColor: Color(0xFF0D7377).withOpacity(0.1),
          child: Icon(
            iconData,
            size: 40,
            color: Color(0xFF0D7377),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: isDark ? Color(0xFF1E1E1E) : Color(0xFF0D7377),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [Color(0xFF1E1E1E), Color(0xFF2D2D2D)]
                : [
                    Color(0xFF0D7377).withOpacity(0.9),
                    Color(0xFF14BDAC).withOpacity(0.9)
                  ],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // Profile Section
            _buildProfileSection(isDark),
            SizedBox(height: 20),

            // Appearance Section
            _buildSection(
              title: 'Appearance',
              icon: Icons.palette,
              isDark: isDark,
              children: [
                _buildAnimatedSwitchTile(
                  title: 'Dark Mode',
                  subtitle:
                      isDark ? 'Dark theme enabled' : 'Light theme enabled',
                  icon: isDark ? Icons.dark_mode : Icons.light_mode,
                  value: isDark,
                  onChanged: (value) {
                    context.read<ThemeProvider>().toggleTheme();
                    setState(() {
                      darkMode = value;
                    });
                  },
                  isDark: isDark,
                ),
              ],
            ),
            SizedBox(height: 16),

            // Notifications Section
            _buildSection(
              title: 'Notifications',
              icon: Icons.notifications,
              isDark: isDark,
              children: [
                _buildAnimatedSwitchTile(
                  title: 'Push Notifications',
                  subtitle: 'Receive device status updates',
                  icon: Icons.notification_important,
                  value: notifications,
                  onChanged: (value) {
                    setState(() {
                      notifications = value;
                    });
                    // Auto-save
                    saveSettings();
                  },
                  isDark: isDark,
                ),
              ],
            ),
            SizedBox(height: 16),

            // Device Info Section
            _buildSection(
              title: 'Device Information',
              icon: Icons.info,
              isDark: isDark,
              children: [
                _buildInfoTile(
                  title: 'App Version',
                  subtitle: '1.0.0',
                  icon: Icons.new_releases,
                  isDark: isDark,
                ),
                _buildInfoTile(
                  title: 'Device ID',
                  subtitle:
                      'SMARTHOME-${DateTime.now().millisecondsSinceEpoch}',
                  icon: Icons.devices,
                  isDark: isDark,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(bool isDark) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF2D2D2D) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _showAvatarSelectionDialog,
            child: Container(
              padding: EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF0D7377), Color(0xFF14BDAC)],
                ),
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: isDark ? Color(0xFF1E1E1E) : Colors.white,
                child: Icon(
                  Icons.person_rounded,
                  size: 60,
                  color: Color(0xFF0D7377).withOpacity(0.7),
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                username,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Color(0xFF0D7377),
                ),
              ),
              SizedBox(width: 10),
              IconButton(
                icon: Icon(
                  Icons.edit,
                  color: Color(0xFF0D7377),
                ),
                onPressed: _showUsernameDialog,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF2D2D2D) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF0D7377).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: Color(0xFF0D7377),
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Color(0xFF0D7377),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: isDark ? Colors.white24 : Colors.grey[300]),
          ...children,
        ],
      ),
    );
  }

  Widget _buildAnimatedSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Color(0xFF0D7377).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Color(0xFF0D7377)),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDark ? Colors.white70 : Colors.black54,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Color(0xFF0D7377),
      ),
    );
  }

  Widget _buildInfoTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isDark,
  }) {
    return ListTile(
      leading: Icon(icon, color: Color(0xFF0D7377)),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}

class PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw hexagonal pattern
    double hexSize = 40;
    double horizontalSpacing = hexSize * 1.5;
    double verticalSpacing = hexSize * sqrt(3);
    bool oddRow = false;

    for (double y = 0; y <= size.height + hexSize; y += verticalSpacing / 2) {
      oddRow = !oddRow;
      for (double x = 0; x <= size.width + hexSize; x += horizontalSpacing) {
        double offsetX = oddRow ? horizontalSpacing / 2 : 0;
        drawHexagon(
          canvas,
          Offset(x + offsetX, y),
          hexSize,
          paint,
        );
      }
    }

    // Add decorative circles
    paint.style = PaintingStyle.fill;
    double circleSpacing = 100;
    for (double x = 0; x <= size.width; x += circleSpacing) {
      for (double y = 0; y <= size.height; y += circleSpacing) {
        // Main circle
        paint.color = Colors.white.withOpacity(0.05);
        canvas.drawCircle(Offset(x, y), 8, paint);

        // Inner circle
        paint.color = Colors.white.withOpacity(0.1);
        canvas.drawCircle(Offset(x, y), 4, paint);
      }
    }
  }

  void drawHexagon(Canvas canvas, Offset center, double size, Paint paint) {
    Path path = Path();
    for (int i = 0; i < 6; i++) {
      double angle = (60 * i - 30) * pi / 180;
      double x = center.dx + size * cos(angle);
      double y = center.dy + size * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
