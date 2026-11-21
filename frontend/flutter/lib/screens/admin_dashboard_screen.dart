import 'package:flutter/material.dart';

import '../services/api_config.dart';
import '../services/complaints_api.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key, required this.user});

  final Map<String, dynamic> user;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  static const _allStatuses = 'All statuses';
  static const _allCategories = 'All categories';
  static const _statuses = ['Pending', 'Ongoing', 'Resolved'];

  List<Map<String, dynamic>> _complaints = [];
  bool _isLoading = true;
  String? _loadError;
  String _selectedStatus = _allStatuses;
  String _selectedCategory = _allCategories;

  bool get _isAdmin => widget.user['role'] == 'admin';

  @override
  void initState() {
    super.initState();
    if (_isAdmin) _refreshComplaints();
  }

  Future<void> _refreshComplaints() async {
    if (!_isAdmin) return;
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final complaints = await ComplaintsApi.getAdminComplaints();
      if (!mounted) return;
      final categories = complaints
          .map((complaint) => _complaintText(complaint, 'category'))
          .where((category) => category.isNotEmpty)
          .toSet();
      setState(() {
        _complaints = complaints;
        if (!categories.contains(_selectedCategory)) {
          _selectedCategory = _allCategories;
        }
      });
    } catch (error) {
      if (mounted) setState(() => _loadError = error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<String> get _categories => [
    _allCategories,
    ..._complaints
        .map((complaint) => _complaintText(complaint, 'category'))
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList()
      ..sort(),
  ];

  List<Map<String, dynamic>> get _filteredComplaints =>
      _complaints.where((complaint) {
        final matchesStatus =
            _selectedStatus == _allStatuses ||
            _complaintText(complaint, 'status') == _selectedStatus;
        final matchesCategory =
            _selectedCategory == _allCategories ||
            _complaintText(complaint, 'category') == _selectedCategory;
        return matchesStatus && matchesCategory;
      }).toList();

  Future<void> _openComplaint(Map<String, dynamic> complaint) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AdminComplaintDetailsScreen(complaint: complaint),
      ),
    );
    if (updated == true) {
      await _refreshComplaints();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Complaint update saved.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin Dashboard')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Access denied. Admin privileges are required to view this page.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final pendingCount = _complaints
        .where((complaint) => _complaintText(complaint, 'status') == 'Pending')
        .length;
    final ongoingCount = _complaints
        .where((complaint) => _complaintText(complaint, 'status') == 'Ongoing')
        .length;
    final resolvedCount = _complaints
        .where((complaint) => _complaintText(complaint, 'status') == 'Resolved')
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Refresh complaints',
            onPressed: _isLoading ? null : _refreshComplaints,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshComplaints,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'COMPLAINT MANAGEMENT',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF21835F),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Resident reports',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: const Color(0xFF173B2E),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Review submitted concerns, update their status, and leave an admin note.',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: const Color(0xFF718078)),
                ),
                const SizedBox(height: 18),
                _DashboardSummary(
                  total: _complaints.length,
                  pending: pendingCount,
                  ongoing: ongoingCount,
                  resolved: resolvedCount,
                ),
                const SizedBox(height: 16),
                _buildFilters(context),
                const SizedBox(height: 12),
                if (_isLoading && _complaints.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_loadError != null)
                  _DashboardError(
                    message: _loadError!,
                    onRetry: _refreshComplaints,
                  )
                else if (_filteredComplaints.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No complaints match these filters.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  for (final complaint in _filteredComplaints)
                    _AdminComplaintCard(
                      complaint: complaint,
                      onTap: () => _openComplaint(complaint),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final statusFilter = DropdownButtonFormField<String>(
              initialValue: _selectedStatus,
              decoration: const InputDecoration(labelText: 'Filter by status'),
              items: [_allStatuses, ..._statuses].map((status) {
                return DropdownMenuItem(value: status, child: Text(status));
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedStatus = value);
              },
            );
            final categoryFilter = DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Filter by category',
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedCategory = value);
              },
            );

            if (constraints.maxWidth < 620) {
              return Column(
                children: [
                  statusFilter,
                  const SizedBox(height: 12),
                  categoryFilter,
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: statusFilter),
                const SizedBox(width: 14),
                Expanded(child: categoryFilter),
              ],
            );
          },
        ),
      ),
    );
  }
}

class AdminComplaintDetailsScreen extends StatefulWidget {
  const AdminComplaintDetailsScreen({super.key, required this.complaint});

  final Map<String, dynamic> complaint;

  @override
  State<AdminComplaintDetailsScreen> createState() =>
      _AdminComplaintDetailsScreenState();
}

class _AdminComplaintDetailsScreenState
    extends State<AdminComplaintDetailsScreen> {
  late String _selectedStatus;
  late final TextEditingController _remarkController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = _complaintText(widget.complaint, 'status', 'Pending');
    _remarkController = TextEditingController(
      text: _complaintText(widget.complaint, 'admin_remark'),
    );
  }

  @override
  void dispose() {
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _saveUpdate() async {
    final rawId = widget.complaint['id'];
    final complaintId = rawId is num ? rawId.toInt() : int.tryParse('$rawId');
    if (complaintId == null || complaintId <= 0) {
      _showMessage('This complaint has an invalid ID and cannot be updated.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ComplaintsApi.updateStatus(
        complaintId: complaintId,
        status: _selectedStatus,
        remark: _remarkController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      _showMessage('Unable to update this complaint: $error');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final complaint = widget.complaint;
    final photoUrl = _complaintText(complaint, 'photo_url');
    final remark = _complaintText(complaint, 'admin_remark');

    return Scaffold(
      appBar: AppBar(title: const Text('Complaint details')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _complaintText(complaint, 'title', 'Complaint'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: const Color(0xFF173B2E),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _DetailLine(
                        label: 'Reference',
                        value: '#${_complaintText(complaint, 'id', '—')}',
                      ),
                      _DetailLine(
                        label: 'Category',
                        value: _complaintText(complaint, 'category', '—'),
                      ),
                      _DetailLine(
                        label: 'Location / Purok',
                        value: _complaintText(complaint, 'location', '—'),
                      ),
                      _DetailLine(
                        label: 'Reported',
                        value: _complaintText(complaint, 'created_at', '—'),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Description',
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _complaintText(
                          complaint,
                          'description',
                          'No description provided.',
                        ),
                      ),
                      if (photoUrl.startsWith('/uploads/')) ...[
                        const SizedBox(height: 18),
                        Text(
                          'Photo evidence',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            ApiConfig.upload(photoUrl).toString(),
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'The complaint image could not be loaded.',
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (remark.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        Text(
                          'Previous admin remark',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 5),
                        Text(remark),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Manage report',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: const Color(0xFF173B2E),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedStatus,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: _DashboardSummary.statuses.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          );
                        }).toList(),
                        onChanged: _isSaving
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(() => _selectedStatus = value);
                                }
                              },
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _remarkController,
                        maxLength: 500,
                        maxLines: 3,
                        enabled: !_isSaving,
                        decoration: const InputDecoration(
                          labelText: 'Admin remark (optional)',
                          hintText: 'Add a short update for the resident',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton.icon(
                          onPressed: _isSaving ? null : _saveUpdate,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(_isSaving ? 'Saving...' : 'Save update'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF176B4D),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardSummary extends StatelessWidget {
  const _DashboardSummary({
    required this.total,
    required this.pending,
    required this.ongoing,
    required this.resolved,
  });

  static const statuses = ['Pending', 'Ongoing', 'Resolved'];

  final int total;
  final int pending;
  final int ongoing;
  final int resolved;

  @override
  Widget build(BuildContext context) {
    final cards = [
      ('Total reports', total, const Color(0xFF24795A)),
      ('Pending', pending, const Color(0xFFB87916)),
      ('Ongoing', ongoing, const Color(0xFF3B73B9)),
      ('Resolved', resolved, const Color(0xFF32805A)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 700 ? 4 : 2;
        final gap = 10.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final (label, count, color) in cards)
              SizedBox(
                width: width,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$count',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: color,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        Text(
                          label,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: const Color(0xFF718078)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AdminComplaintCard extends StatelessWidget {
  const _AdminComplaintCard({required this.complaint, required this.onTap});

  final Map<String, dynamic> complaint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = _complaintText(complaint, 'status', 'Pending');
    final statusColor = switch (status) {
      'Resolved' => const Color(0xFF32805A),
      'Ongoing' => const Color(0xFF3B73B9),
      _ => const Color(0xFFB87916),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        title: Text(
          _complaintText(complaint, 'title', 'Complaint'),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            '#${_complaintText(complaint, 'id', '—')}  ·  '
            '${_complaintText(complaint, 'category', 'Uncategorized')}  ·  '
            '${_complaintText(complaint, 'location', 'Location not provided')}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Chip(
              label: Text(status),
              labelStyle: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              backgroundColor: statusColor.withValues(alpha: 0.1),
              side: BorderSide.none,
              visualDensity: VisualDensity.compact,
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 135,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: const Color(0xFF718078)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF173B2E),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.message, required this.onRetry});

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

String _complaintText(
  Map<String, dynamic> complaint,
  String key, [
  String fallback = '',
]) {
  final value = complaint[key];
  return value == null || value.toString().trim().isEmpty
      ? fallback
      : value.toString().trim();
}
