import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_config.dart';
import '../services/auth_api.dart';
import '../services/complaints_api.dart';
import 'complaint_form_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.user});

  final Map<String, dynamic> user;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _complaints = [];
  bool _isLoading = true;
  String? _loadError;

  bool get _isAdmin => widget.user['role'] == 'admin';

  @override
  void initState() {
    super.initState();
    _refreshComplaints();
  }

  Future<void> _refreshComplaints() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final complaints = await ComplaintsApi.getComplaints();
      if (mounted) setState(() => _complaints = complaints);
    } catch (error) {
      if (mounted) setState(() => _loadError = error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openComplaintForm() async {
    final submitted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const ComplaintFormScreen()),
    );
    if (submitted == true) {
      await _refreshComplaints();
    }
  }

  Future<void> _updateStatus(int complaintId, String status) async {
    try {
      await ComplaintsApi.updateStatus(
        complaintId: complaintId,
        status: status,
      );
      await _refreshComplaints();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString()), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _logout() async {
    try {
      await AuthApi.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (_) => false,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to clear the saved session: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fullName = widget.user['full_name'];
    final firstName = fullName is String && fullName.trim().isNotEmpty
        ? fullName.trim().split(' ').first
        : 'Resident';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.home_work, color: Color(0xFF1E5631)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Smart Community',
                style: GoogleFonts.poppins(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh reports',
            onPressed: _isLoading ? null : _refreshComplaints,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Log out',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshComplaints,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E5631),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, $firstName',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Report a community issue and follow its status here.',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: _openComplaintForm,
                    icon: const Icon(Icons.add),
                    label: const Text('Submit a complaint'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1E5631),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Community complaints',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (_isLoading && _complaints.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_loadError != null && _complaints.isEmpty)
              _LoadError(message: _loadError!, onRetry: _refreshComplaints)
            else if (_complaints.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No complaints have been submitted yet.'),
                ),
              )
            else
              for (final complaint in _complaints)
                _ComplaintCard(
                  complaint: complaint,
                  isAdmin: _isAdmin,
                  onStatusChanged: _updateStatus,
                ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openComplaintForm,
        icon: const Icon(Icons.add),
        label: const Text('New complaint'),
        backgroundColor: const Color(0xFF1E5631),
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  const _ComplaintCard({
    required this.complaint,
    required this.isAdmin,
    required this.onStatusChanged,
  });

  final Map<String, dynamic> complaint;
  final bool isAdmin;
  final Future<void> Function(int complaintId, String status) onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final title = complaint['title'] is String
        ? complaint['title'] as String
        : 'Complaint';
    final category = complaint['category'] is String
        ? complaint['category'] as String
        : 'Uncategorized';
    final location = complaint['location'] is String
        ? complaint['location'] as String
        : 'Location not provided';
    final description = complaint['description'] is String
        ? complaint['description'] as String
        : '';
    final status = complaint['status'] is String
        ? complaint['status'] as String
        : 'Pending';
    final idValue = complaint['id'];
    final id = idValue is num ? idValue.toInt() : int.tryParse('$idValue');
    final photoUrl = complaint['photo_url'];
    final createdAt = complaint['created_at'];
    final createdText = createdAt is String
        ? createdAt
        : createdAt?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _StatusBadge(status: status),
              ],
            ),
            const SizedBox(height: 6),
            Text('$category  ·  $location'),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(description),
            ],
            if (createdText.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Reported: $createdText',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (photoUrl is String && photoUrl.startsWith('/uploads/')) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  ApiConfig.upload(photoUrl).toString(),
                  height: 190,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Text(
                    'The complaint image could not be loaded.',
                  ),
                ),
              ),
            ],
            if (isAdmin && id != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: PopupMenuButton<String>(
                  tooltip: 'Update status',
                  onSelected: (value) => onStatusChanged(id, value),
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'Pending', child: Text('Pending')),
                    PopupMenuItem(value: 'Ongoing', child: Text('Ongoing')),
                    PopupMenuItem(value: 'Resolved', child: Text('Resolved')),
                  ],
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Update status'),
                      Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'Resolved' => Colors.green,
      'Ongoing' => Colors.blue,
      _ => Colors.orange,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          status,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
