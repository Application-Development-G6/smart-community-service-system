import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_config.dart';
import '../services/auth_api.dart';
import '../services/complaints_api.dart';
import 'admin_dashboard_screen.dart';
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
  int _selectedIndex = 0;
  Timer? _trackRefreshTimer;
  final ScrollController _scrollController = ScrollController();
  final _reportsSectionKey = GlobalKey();
  final _tipsSectionKey = GlobalKey();

  bool get _isAdmin => widget.user['role'] == 'admin';

  @override
  void initState() {
    super.initState();
    _refreshComplaints();
    _trackRefreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (_selectedIndex == 2 && !_isLoading) {
        unawaited(_refreshComplaints());
      }
    });
  }

  @override
  void dispose() {
    _trackRefreshTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
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
    final result = await Navigator.push<Object?>(
      context,
      MaterialPageRoute(builder: (context) => const ComplaintFormScreen()),
    );
    if (result == true) {
      await _refreshComplaints();
    }
    if (result == ComplaintFormNavigation.trackReports && mounted) {
      setState(() => _selectedIndex = 2);
      await _scrollTo(_reportsSectionKey);
    }
  }

  Future<void> _openAdminDashboard() async {
    if (!_isAdmin) return;
    setState(() => _selectedIndex = 3);
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AdminDashboardScreen(user: widget.user),
      ),
    );
    if (!mounted) return;
    setState(() => _selectedIndex = 0);
    await _refreshComplaints();
  }

  Future<void> _selectNavigation(int index) async {
    if (index == 3) {
      await _openAdminDashboard();
      return;
    }

    if (index == 1) {
      setState(() => _selectedIndex = index);
      await _openComplaintForm();
      if (mounted && _selectedIndex == 1) {
        setState(() => _selectedIndex = 0);
      }
      return;
    }

    setState(() => _selectedIndex = index);
    if (index == 2) {
      await _refreshComplaints();
      await _scrollTo(_reportsSectionKey);
    } else {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _scrollTo(GlobalKey key) async {
    final sectionContext = key.currentContext;
    if (sectionContext == null) return;
    await Scrollable.ensureVisible(
      sectionContext,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
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
    final pendingCount = _complaints
        .where((complaint) => complaint['status'] == 'Pending')
        .length;
    final ongoingCount = _complaints
        .where((complaint) => complaint['status'] == 'Ongoing')
        .length;
    final resolvedCount = _complaints
        .where((complaint) => complaint['status'] == 'Resolved')
        .length;
    final showWideNavigation =
        MediaQuery.sizeOf(context).width >= (_isAdmin ? 1200 : 900);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE5F2E9),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.home_work_rounded,
                color: Color(0xFF176B4D),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Smart Community',
              style: GoogleFonts.poppins(
                color: const Color(0xFF173B2E),
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          if (showWideNavigation) ...[
            _HeaderNavButton(
              label: 'Home',
              selected: _selectedIndex == 0,
              onPressed: () => _selectNavigation(0),
            ),
            _HeaderNavButton(
              label: 'Report a Problem',
              selected: _selectedIndex == 1,
              onPressed: () => _selectNavigation(1),
            ),
            _HeaderNavButton(
              label: 'Track Reports',
              selected: _selectedIndex == 2,
              onPressed: () => _selectNavigation(2),
            ),
            if (_isAdmin)
              _HeaderNavButton(
                label: 'Admin Dashboard',
                selected: _selectedIndex == 3,
                onPressed: _openAdminDashboard,
              ),
          ] else
            PopupMenuButton<int>(
              tooltip: 'Navigation',
              icon: const Icon(Icons.menu_rounded),
              onSelected: _selectNavigation,
              itemBuilder: (context) => [
                PopupMenuItem(value: 0, child: Text('Home')),
                PopupMenuItem(value: 1, child: Text('Report a Problem')),
                PopupMenuItem(value: 2, child: Text('Track Reports')),
                if (_isAdmin)
                  const PopupMenuItem(value: 3, child: Text('Admin Dashboard')),
              ],
            ),
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
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final pagePadding = constraints.maxWidth > 700 ? 28.0 : 18.0;
                return ListView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    pagePadding,
                    16,
                    pagePadding,
                    28,
                  ),
                  children: [
                    _HomeHero(
                      firstName: firstName,
                      onReport: _openComplaintForm,
                    ),
                    const SizedBox(height: 18),
                    LayoutBuilder(
                      builder: (context, statConstraints) {
                        final columns = statConstraints.maxWidth >= 700 ? 4 : 2;
                        final gap = 10.0;
                        final cardWidth =
                            (statConstraints.maxWidth - gap * (columns - 1)) /
                            columns;
                        return Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: [
                            _StatCard(
                              width: cardWidth,
                              count: _complaints.length,
                              label: 'Total reports',
                              icon: Icons.description_outlined,
                              color: const Color(0xFF24795A),
                            ),
                            _StatCard(
                              width: cardWidth,
                              count: pendingCount,
                              label: 'Pending',
                              icon: Icons.schedule_rounded,
                              color: const Color(0xFFB87916),
                            ),
                            _StatCard(
                              width: cardWidth,
                              count: ongoingCount,
                              label: 'In progress',
                              icon: Icons.handyman_outlined,
                              color: const Color(0xFF3B73B9),
                            ),
                            _StatCard(
                              width: cardWidth,
                              count: resolvedCount,
                              label: 'Resolved',
                              icon: Icons.check_circle_outline,
                              color: const Color(0xFF32805A),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 28),
                    const _SectionHeading(
                      eyebrow: 'WHAT YOU CAN DO',
                      title: 'Community services, made simpler',
                      subtitle:
                          'A few taps can help make your neighborhood better.',
                    ),
                    const SizedBox(height: 14),
                    LayoutBuilder(
                      builder: (context, actionConstraints) {
                        final columns = actionConstraints.maxWidth >= 760
                            ? 3
                            : 1;
                        final gap = 12.0;
                        final cardWidth =
                            (actionConstraints.maxWidth - gap * (columns - 1)) /
                            columns;
                        return Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: [
                            _ActionCard(
                              width: cardWidth,
                              icon: Icons.edit_note_rounded,
                              color: const Color(0xFF27845F),
                              title: 'Report a problem',
                              description:
                                  'Tell us what needs attention in your area.',
                              actionLabel: 'Create a report',
                              onTap: _openComplaintForm,
                            ),
                            _ActionCard(
                              width: cardWidth,
                              icon: Icons.track_changes_rounded,
                              color: const Color(0xFF3977B8),
                              title: 'Track your reports',
                              description: 'Check the latest status of reports you submitted.',
                              actionLabel: 'View report status',
                              onTap: () => _scrollTo(_reportsSectionKey),
                            ),
                            _ActionCard(
                              width: cardWidth,
                              icon: Icons.lightbulb_outline_rounded,
                              color: const Color(0xFFC17A18),
                              title: 'Make a helpful report',
                              description: 'Include a clear location and useful details.',
                              actionLabel: 'Reporting tips',
                              onTap: () => _scrollTo(_tipsSectionKey),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 28),
                    Row(
                      key: _reportsSectionKey,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Expanded(
                          child: _SectionHeading(
                            eyebrow: 'COMMUNITY UPDATES',
                            title: 'Recent reports',
                            subtitle: 'Reports submitted by the community.',
                          ),
                        ),
                        if (_complaints.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Text(
                              '${_complaints.length} total',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF557267),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_isLoading && _complaints.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_loadError != null && _complaints.isEmpty)
                      _LoadError(
                        message: _loadError!,
                        onRetry: _refreshComplaints,
                      )
                    else if (_complaints.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(22),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.forum_outlined,
                                size: 34,
                                color: Color(0xFF6D8B7B),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'No reports yet',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF173B2E),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Be the first to let your community know about an issue.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFF718078),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      for (final complaint in _complaints)
                        _ComplaintCard(
                          complaint: complaint,
                          isAdmin: _isAdmin,
                          onStatusChanged: _updateStatus,
                        ),
                    const SizedBox(height: 24),
                    _TipsCard(key: _tipsSectionKey),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderNavButton extends StatelessWidget {
  const _HeaderNavButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: selected
            ? const Color(0xFF176B4D)
            : const Color(0xFF607168),
        backgroundColor: selected
            ? const Color(0xFFE5F2E9)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }
}

class _HomeHero extends StatelessWidget {
  const _HomeHero({required this.firstName, required this.onReport});

  final String firstName;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF12583F), Color(0xFF23845F)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'A BETTER WAY TO SERVE OUR COMMUNITY',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Icon(
                  Icons.holiday_village_rounded,
                  size: 32,
                  color: Color(0xFFFFD978),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Your community.\nYour shared responsibility.',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 25,
              height: 1.2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Welcome, $firstName. Report local concerns and follow their progress in one place.',
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.86),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onReport,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Report a problem'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF176B4D),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: GoogleFonts.poppins(
            color: const Color(0xFF23845F),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          title,
          style: GoogleFonts.poppins(
            color: const Color(0xFF173B2E),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          subtitle,
          style: GoogleFonts.poppins(
            color: const Color(0xFF718078),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.width,
    required this.count,
    required this.label,
    required this.icon,
    required this.color,
  });

  final double width;
  final int count;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 19, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$count',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF173B2E),
                        fontSize: 18,
                        height: 1.2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF718078),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.width,
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onTap,
  });

  final double width;
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 21),
                ),
                const SizedBox(height: 13),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF173B2E),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF718078),
                    fontSize: 11,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '$actionLabel  →',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF176B4D),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
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

class _TipsCard extends StatelessWidget {
  const _TipsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF2D8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.tips_and_updates_outlined,
                color: Color(0xFFB87916),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Help us understand the issue',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF173B2E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add a specific location and clear details when you report a concern. A photo is optional.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      height: 1.5,
                      color: const Color(0xFF718078),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
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
    final adminRemark = complaint['admin_remark'] is String
        ? (complaint['admin_remark'] as String).trim()
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
            if (adminRemark.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Admin update: $adminRemark',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF176B4D),
                  fontWeight: FontWeight.w500,
                ),
              ),
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
                  errorBuilder: (_, _, _) =>
                      const Text('The complaint image could not be loaded.'),
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
