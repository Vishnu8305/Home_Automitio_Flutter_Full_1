import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Contact Us',
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
                // Header Section
                Center(
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
                      Icons.contact_support_rounded,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 24),
                Center(
                  child: Text(
                    'Get in Touch',
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
                    'We\'re here to help and answer any questions',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white70 : Colors.grey[600],
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 40),

                // Contact Methods
                _buildContactCard(
                  context,
                  'Customer Support',
                  'Available 24/7 for your questions',
                  Icons.headset_mic_rounded,
                  isDark,
                  onTap: () => _launchPhone('+1234567890'),
                ),
                SizedBox(height: 20),

                _buildContactCard(
                  context,
                  'Email Us',
                  'support@smarthome.com',
                  Icons.email_rounded,
                  isDark,
                  onTap: () => _launchEmail('support@smarthome.com'),
                ),
                SizedBox(height: 20),

                _buildContactCard(
                  context,
                  'Visit Us',
                  '123 Smart Street, Tech City, 12345',
                  Icons.location_on_rounded,
                  isDark,
                  onTap: () => _launchMaps('123 Smart Street, Tech City'),
                ),
                SizedBox(height: 40),

                // Social Media Section
                Center(
                  child: Text(
                    'Follow Us',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Color(0xFF0D7377),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSocialButton(
                      context,
                      'Facebook',
                      Icons.facebook_rounded,
                      isDark,
                      onTap: () => _launchURL('https://facebook.com'),
                    ),
                    SizedBox(width: 20),
                    _buildSocialButton(
                      context,
                      'Twitter',
                      Icons.flutter_dash_rounded,
                      isDark,
                      onTap: () => _launchURL('https://twitter.com'),
                    ),
                    SizedBox(width: 20),
                    _buildSocialButton(
                      context,
                      'LinkedIn',
                      Icons.link_rounded,
                      isDark,
                      onTap: () => _launchURL('https://linkedin.com'),
                    ),
                  ],
                ),
                SizedBox(height: 40),

                // Business Hours
                _buildInfoCard(
                  context,
                  'Business Hours',
                  'Monday - Friday: 9:00 AM - 6:00 PM\nSaturday: 10:00 AM - 4:00 PM\nSunday: Closed',
                  Icons.access_time_rounded,
                  isDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard(BuildContext context, String title, String content,
      IconData icon, bool isDark,
      {VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
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
                color: isDark
                    ? Colors.black12
                    : Color(0xFF0D7377).withOpacity(0.08),
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
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Color(0xFF0D7377),
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        content,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.grey[700],
                          height: 1.5,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: isDark ? Colors.white30 : Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton(
      BuildContext context, String label, IconData icon, bool isDark,
      {VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Color(0xFF0D7377).withOpacity(0.08),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Color(0xFF0D7377).withOpacity(0.1),
            ),
          ),
          child: Icon(
            icon,
            size: 24,
            color: isDark ? Colors.white70 : Color(0xFF0D7377),
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
    );
  }

  void _launchPhone(String phoneNumber) async {
    final url = 'tel:$phoneNumber';
    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  void _launchEmail(String email) async {
    final url = 'mailto:$email';
    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  void _launchMaps(String address) async {
    final url =
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeFull(address)}';
    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    }
  }
}
