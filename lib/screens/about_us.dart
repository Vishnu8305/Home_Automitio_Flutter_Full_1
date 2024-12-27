import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class AboutUsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'About Us',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 24,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
        backgroundColor: isDark ? Color(0xFF1A1A1A) : Color(0xFF0D7377),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [Color(0xFF1A1A1A), Color(0xFF2D2D2D)]
                : [Color(0xFFF8FDFF), Color(0xFFF0F8FA)],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Company Logo and Name
                Center(
                  child: Hero(
                    tag: 'company_logo',
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF0D7377), Color(0xFF14BDAC)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF0D7377).withOpacity(0.3),
                            blurRadius: 15,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.home_work_rounded,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24),
                Center(
                  child: Text(
                    'Smart Home Solutions',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Color(0xFF0D7377),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Center(
                  child: Text(
                    'Making homes smarter, life better',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white70 : Colors.grey[600],
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                SizedBox(height: 40),

                // Mission Section
                _buildInfoCard(
                  context,
                  'Our Mission',
                  'To revolutionize home automation with innovative, user-friendly solutions that enhance comfort, security, and energy efficiency.',
                  Icons.rocket_launch_rounded,
                  isDark,
                ),
                SizedBox(height: 20),

                // Vision Section
                _buildInfoCard(
                  context,
                  'Our Vision',
                  'Creating a future where every home is a smart home, seamlessly connecting people with their living spaces.',
                  Icons.visibility_rounded,
                  isDark,
                ),
                SizedBox(height: 20),

                // Values Section
                _buildInfoCard(
                  context,
                  'Our Values',
                  '• Innovation in every solution\n• Customer satisfaction first\n• Quality and reliability\n• Environmental responsibility\n• Continuous improvement',
                  Icons.stars_rounded,
                  isDark,
                ),
                SizedBox(height: 20),

                // Team Section
                _buildInfoCard(
                  context,
                  'Our Team',
                  'We are a dedicated team of engineers, designers, and innovators passionate about creating the best smart home experience for our users.',
                  Icons.groups_rounded,
                  isDark,
                ),
                SizedBox(height: 40),

                // Version Info
                Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Color(0xFF0D7377).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Color(0xFF0D7377).withOpacity(0.1),
                      ),
                    ),
                    child: Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Color(0xFF0D7377),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String title, String content,
      IconData icon, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.white.withOpacity(0.05),
                  Colors.white.withOpacity(0.02),
                ]
              : [Colors.white, Color(0xFFF8FDFF)],
        ),
        boxShadow: [
          BoxShadow(
            color:
                isDark ? Colors.black12 : Color(0xFF0D7377).withOpacity(0.08),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Color(0xFF0D7377).withOpacity(0.1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // Add animation or interaction here if needed
          },
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Color(0xFF0D7377).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        size: 24,
                        color: isDark ? Colors.white70 : Color(0xFF0D7377),
                      ),
                    ),
                    SizedBox(width: 16),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Color(0xFF0D7377),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white70 : Colors.grey[700],
                    height: 1.5,
                    letterSpacing: 0.2,
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
