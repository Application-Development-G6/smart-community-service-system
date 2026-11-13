import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _primaryGreen = Color(0xFF1E5631);
const _backgroundColor = Color(0xFFF5F7F5);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.fullName});

  final String? fullName;

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This feature is coming soon.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroSection(context),
                  const SizedBox(height: 30),
                  _buildStatsRow(context),
                  const SizedBox(height: 12),
                  Text(
                    'Report statistics will appear here when report data is connected.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Community services, made simpler',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    'Tools to help residents share concerns and stay informed.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildFeaturesRow(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.home_work, color: _primaryGreen, size: 30),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Smart Community',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontSize: 16,
                ),
              ),
              Text(
                'SERVICE & COMPLAINT SYSTEM',
                style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
      actions: isWide
          ? [
              _navButton('Home', onPressed: () {}),
              _navButton(
                'Report a Problem',
                onPressed: () => _showComingSoon(context),
              ),
              _navButton(
                'Track Reports',
                onPressed: () => _showComingSoon(context),
              ),
              _navButton(
                'Announcements',
                onPressed: () => _showComingSoon(context),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _showComingSoon(context),
                  child: const Text('Admin Preview'),
                ),
              ),
              const SizedBox(width: 20),
            ]
          : [
              PopupMenuButton<String>(
                tooltip: 'Open menu',
                onSelected: (value) {
                  if (value != 'Home') _showComingSoon(context);
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'Home', child: Text('Home')),
                  PopupMenuItem(
                    value: 'Report a Problem',
                    child: Text('Report a Problem'),
                  ),
                  PopupMenuItem(
                    value: 'Track Reports',
                    child: Text('Track Reports'),
                  ),
                  PopupMenuItem(
                    value: 'Announcements',
                    child: Text('Announcements'),
                  ),
                  PopupMenuItem(
                    value: 'Admin Preview',
                    child: Text('Admin Preview'),
                  ),
                ],
              ),
            ],
    );
  }

  Widget _navButton(String text, {required VoidCallback onPressed}) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: text == 'Home' ? _primaryGreen : Colors.grey[700],
          fontWeight: text == 'Home' ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    final firstName = fullName?.trim().split(' ').first;
    final greeting = firstName == null || firstName.isEmpty
        ? 'Your community.'
        : 'Welcome, $firstName.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: _primaryGreen,
        borderRadius: BorderRadius.circular(24),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 800;
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A BETTER WAY TO SERVE OUR COMMUNITY',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                '$greeting\nOur shared responsibility.',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                'A simple digital space to report local concerns, follow their progress, and stay informed about important community announcements.',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 30),
              Wrap(
                spacing: 15,
                runSpacing: 12,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _primaryGreen,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                    onPressed: () => _showComingSoon(context),
                    icon: const Icon(Icons.add),
                    label: const Text(
                      'Report a Problem',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                    onPressed: () => _showComingSoon(context),
                    child: const Text(
                      'Track My Report →',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          );
          final illustration = Container(
            width: 250,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.house_siding,
                  size: 80,
                  color: Colors.orangeAccent,
                ),
                const SizedBox(height: 10),
                Text(
                  'Community First',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          );

          if (!isWide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [content, const SizedBox(height: 24), illustration],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: content),
              const SizedBox(width: 24),
              illustration,
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth >= 900
            ? (constraints.maxWidth - 45) / 4
            : constraints.maxWidth >= 560
            ? (constraints.maxWidth - 15) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 15,
          runSpacing: 15,
          children: [
            _statCard(
              '—',
              'Total reports',
              Icons.assignment,
              Colors.orange,
              cardWidth,
            ),
            _statCard(
              '—',
              'Pending review',
              Icons.access_time,
              Colors.purple,
              cardWidth,
            ),
            _statCard('—', 'In progress', Icons.build, Colors.blue, cardWidth),
            _statCard(
              '—',
              'Resolved',
              Icons.check_circle,
              Colors.green,
              cardWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _statCard(
    String number,
    String title,
    IconData icon,
    Color iconColor,
    double width,
  ) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                number,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesRow(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth >= 980
            ? (constraints.maxWidth - 40) / 3
            : constraints.maxWidth >= 620
            ? (constraints.maxWidth - 20) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 20,
          runSpacing: 20,
          children: [
            _featureCard(
              'Submit a Report',
              'Describe a community issue, choose its category, and provide a location.',
              Icons.post_add,
              _primaryGreen,
              cardWidth,
            ),
            _featureCard(
              'Track Progress',
              'Check a report’s status and see whether it is pending, being addressed, or resolved.',
              Icons.search,
              Colors.blue,
              cardWidth,
            ),
            _featureCard(
              'Stay Informed',
              'Read community announcements and important notices published for residents.',
              Icons.campaign,
              Colors.redAccent,
              cardWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _featureCard(
    String title,
    String description,
    IconData icon,
    Color color,
    double width,
  ) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 15),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
