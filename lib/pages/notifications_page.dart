import 'package:flutter/material.dart';

import '../models/app_notification.dart';
import '../repositories/notification_repository.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

/// Palet DonGiv
const Color _kPrimaryColor = Color(0xFF2972FF);
const Color _kBackgroundColor = Color(0xFFF8FAFC);
const Color _kTextPrimary = Color(0xFF0F172A);
const Color _kTextSecondary = Color(0xFF64748B);

/// Halaman riwayat notifikasi DonGiv yang dioptimalkan untuk smartphone.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final List<AppNotification> _notifications = [];
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _hasMore = true;
  int _currentPage = 1;
  int _unreadCount = 0;

  // Filter Kategori: 'all', 'donasi', 'relawan'
  String _selectedFilter = 'all';

  final List<Map<String, String>> _filterOptions = [
    {'key': 'all', 'label': 'Semua'},
    {'key': 'donasi', 'label': 'Donasi'},
    {'key': 'relawan', 'label': 'Relawan'},
  ];

  String _filterLabel(String key) {
    for (final opt in _filterOptions) {
      if (opt['key'] == key) return opt['label'] ?? '';
    }
    return '';
  }

  @override
  void initState() {
    super.initState();
    _fetch(reset: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_hasMore && !_isLoadingMore && !_isLoading) {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _fetch(reset: false);
      }
    }
  }

  Future<void> _fetch({required bool reset}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
        _currentPage = 1;
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Sesi kamu sudah berakhir. Silakan login kembali.');
      }

      final results = await Future.wait([
        NotificationRepository.getNotifications(
          authToken: token,
          page: reset ? 1 : _currentPage + 1,
          categoryFilter: _selectedFilter == 'all' ? null : _selectedFilter,
        ),
        NotificationRepository.getUnreadCount(authToken: token),
      ]);

      final items = results[0] as List<AppNotification>;
      final unread = results[1] as int;

      if (!mounted) return;

      setState(() {
        if (reset) {
          _notifications
            ..clear()
            ..addAll(items);
        } else {
          _notifications.addAll(items);
        }
        _unreadCount = unread;
        _hasMore = items.length >= 15;
        if (!reset) _currentPage = _currentPage + 1;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        if (_notifications.isEmpty) {
          _hasError = true;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        }
      });
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return;

      final ok = await NotificationRepository.markAllAsRead(authToken: token);
      if (ok && mounted) {
        setState(() {
          for (var i = 0; i < _notifications.length; i++) {
            _notifications[i] = _notifications[i].isRead
                ? _notifications[i]
                : AppNotification(
                    id: _notifications[i].id,
                    type: _notifications[i].type,
                    category: _notifications[i].category,
                    title: _notifications[i].title,
                    message: _notifications[i].message,
                    data: _notifications[i].data,
                    isRead: true,
                    readAt: DateTime.now(),
                    createdAt: _notifications[i].createdAt,
                    status: _notifications[i].status,
                  );
          }
          _unreadCount = 0;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Semua notifikasi ditandai sudah dibaca'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menandai semua notifikasi dibaca'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openNotification(AppNotification notification) async {
    if (!notification.isRead) {
      final index = _notifications.indexWhere((n) => n.id == notification.id);
      try {
        final token = await AuthService.getToken();
        if (token != null) {
          await NotificationRepository.markAsRead(
            id: notification.id,
            authToken: token,
          );
        }
        if (mounted && index != -1) {
          setState(() {
            _notifications[index] = AppNotification(
              id: notification.id,
              type: notification.type,
              category: notification.category,
              title: notification.title,
              message: notification.message,
              data: notification.data,
              isRead: true,
              readAt: DateTime.now(),
              createdAt: notification.createdAt,
              status: notification.status,
            );
            if (_unreadCount > 0) _unreadCount--;
          });
        }
      } catch (_) {
        // Gagal menandai dibaca tidak menghalangi pembukaan detail
      }
    }

    if (!mounted) return;
    await NotificationService.openFromNotification(context, notification);
  }

  void _onFilterChanged(String filterKey) {
    if (_selectedFilter == filterKey) return;
    setState(() {
      _selectedFilter = filterKey;
    });
    _fetch(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kTextPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Notifikasi',
          style: TextStyle(
            color: _kTextPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        actions: [
          if (_unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: _markAllAsRead,
                icon: const Icon(Icons.done_all_rounded, size: 16, color: _kPrimaryColor),
                label: const Text(
                  'Baca semua',
                  style: TextStyle(
                    color: _kPrimaryColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips ("Semua", "Donasi", "Relawan")
          _buildFilterBar(),

          // Body Content (Grouped by date)
          Expanded(
            child: RefreshIndicator(
              color: _kPrimaryColor,
              onRefresh: () => _fetch(reset: true),
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: Row(
        children: _filterOptions.map((opt) {
          final isSelected = _selectedFilter == opt['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => _onFilterChanged(opt['key']!),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? _kPrimaryColor : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? _kPrimaryColor : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Text(
                  opt['label']!,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? Colors.white : _kTextSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _kPrimaryColor),
      );
    }

    if (_hasError) {
      return _buildErrorState();
    }

    if (_notifications.isEmpty) {
      return _buildEmptyState();
    }

    // Kelompokkan notifikasi berdasarkan waktu: "Hari ini", "Kemarin", "Sebelumnya"
    final Map<String, List<AppNotification>> grouped = _groupNotificationsByDate(_notifications);
    final groupKeys = grouped.keys.toList();

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: groupKeys.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= groupKeys.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimaryColor),
              ),
            ),
          );
        }

        final groupTitle = groupKeys[index];
        final notifsInGroup = grouped[groupTitle]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
              child: Text(
                groupTitle,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF475569),
                  letterSpacing: -0.2,
                ),
              ),
            ),
            ...notifsInGroup.map((n) => _buildCompactTile(n)),
          ],
        );
      },
    );
  }

  Map<String, List<AppNotification>> _groupNotificationsByDate(List<AppNotification> list) {
    final Map<String, List<AppNotification>> result = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (var n in list) {
      final notifDate = n.createdAt.isUtc ? n.createdAt.toLocal() : n.createdAt;
      final dateOnly = DateTime(notifDate.year, notifDate.month, notifDate.day);

      String group;
      if (dateOnly.isAtSameMomentAs(today)) {
        group = 'Hari ini';
      } else if (dateOnly.isAtSameMomentAs(yesterday)) {
        group = 'Kemarin';
      } else {
        group = 'Sebelumnya';
      }

      result.putIfAbsent(group, () => []).add(n);
    }

    return result;
  }

  Widget _buildCompactTile(AppNotification notification) {
    final isUnread = !notification.isRead;
    final style = _resolveNotificationStyle(notification);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isUnread ? const Color(0xFFF0F6FF) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUnread ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0),
          width: isUnread ? 1.2 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: isUnread ? 0.05 : 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openNotification(notification),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ikon sesuai kategori & status
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: style.background,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(style.icon, color: style.color, size: 20),
                  ),
                ),
                const SizedBox(width: 10),

                // Konten Ringkas
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: isUnread ? FontWeight.w800 : FontWeight.w700,
                                color: _kTextPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Waktu ringkas
                          Text(
                            _formatCompactTime(notification.createdAt),
                            style: TextStyle(
                              fontSize: 10.5,
                              color: isUnread ? _kPrimaryColor : const Color(0xFF94A3B8),
                              fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                          if (isUnread) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: _kPrimaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        notification.message,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: Color(0xFF475569),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _NotificationVisual _resolveNotificationStyle(AppNotification notification) {
    // 1. Lamaran relawan diterima (file-check / tanda centang)
    if (notification.isVolunteerApproved) {
      return const _NotificationVisual(
        icon: Icons.assignment_turned_in_rounded,
        color: Color(0xFF10B981), // Green
        background: Color(0xFFECFDF5),
      );
    }

    // 2. Lamaran relawan ditolak (file-x / tanda silang dokumen)
    if (notification.isVolunteerRejected) {
      return const _NotificationVisual(
        icon: Icons.assignment_late_rounded,
        color: Color(0xFFEF4444), // Red
        background: Color(0xFFFEF2F2),
      );
    }

    // 3. Donasi berhasil (heart-handshake / donasi)
    if (notification.isDonationSuccess || notification.category == 'donasi') {
      return const _NotificationVisual(
        icon: Icons.volunteer_activism_rounded,
        color: _kPrimaryColor, // Blue
        background: Color(0xFFEFF6FF),
      );
    }

    // 4. Relawan umum (users / kelompok relawan)
    if (notification.category == 'relawan') {
      return const _NotificationVisual(
        icon: Icons.people_alt_rounded,
        color: Color(0xFF0D9488), // Teal
        background: Color(0xFFF0FDFA),
      );
    }

    // 5. Kampanye
    if (notification.category == 'kampanye') {
      return const _NotificationVisual(
        icon: Icons.campaign_rounded,
        color: Color(0xFF6366F1), // Indigo
        background: Color(0xFFEEF2FF),
      );
    }

    // 6. Notifikasi Umum / Sistem (bell)
    return const _NotificationVisual(
      icon: Icons.notifications_rounded,
      color: Color(0xFF64748B), // Slate
      background: Color(0xFFF1F5F9),
    );
  }

  String _formatCompactTime(DateTime time) {
    final local = time.isUtc ? time.toLocal() : time;
    final diff = DateTime.now().difference(local);

    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}j';
    if (diff.inDays == 1) return 'Kemarin';
    if (diff.inDays < 7) return '${diff.inDays}h';

    return '${local.day}/${local.month}';
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off_rounded, size: 40, color: Color(0xFFEF4444)),
            ),
            const SizedBox(height: 14),
            const Text(
              'Gagal Memuat Notifikasi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _kTextPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              _errorMessage.isEmpty ? 'Terjadi kesalahan saat memuat data.' : _errorMessage,
              style: const TextStyle(color: _kTextSecondary, fontSize: 12.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () => _fetch(reset: true),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      size: 42,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _selectedFilter == 'all'
                        ? 'Belum Ada Notifikasi'
                        : 'Tidak Ada Notifikasi ${_filterLabel(_selectedFilter)}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _kTextPrimary),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Pembaruan status donasi dan kegiatan relawan Anda\nakan muncul di sini.',
                    style: TextStyle(color: _kTextSecondary, fontSize: 12.5),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationVisual {
  final IconData icon;
  final Color color;
  final Color background;

  const _NotificationVisual({
    required this.icon,
    required this.color,
    required this.background,
  });
}
