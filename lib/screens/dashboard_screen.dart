import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

import '../models/client_model.dart';
import '../theme/app_theme.dart';
import '../providers/db_provider.dart';
import 'client_ledger_screen.dart';
import '../widgets/add_client_sheet.dart';
import '../utils/app_localizations.dart';
import '../providers/locale_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;
  String _searchQuery = '';
  String _filterType = 'all';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final clientsAsync = ref.watch(clientsProvider);
    final formatCurrency = NumberFormat.currency(locale: 'en_PK', symbol: 'Rs ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppTheme.surfaceWhite, // Clean white background
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_filled), label: AppLocalizations.of(context).translate('dashboard')),
          NavigationDestination(icon: const Icon(Icons.people_outline), label: AppLocalizations.of(context).translate('clients')),
          NavigationDestination(icon: const Icon(Icons.backup_outlined), label: AppLocalizations.of(context).translate('backup')),
          NavigationDestination(icon: const Icon(Icons.settings_outlined), label: AppLocalizations.of(context).translate('settings')),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildDashboardContent(context, statsAsync, clientsAsync, formatCurrency),
            _buildClientsOnlyContent(context, clientsAsync, formatCurrency),
            _buildBackupContent(context, ref),
            _buildSettingsContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, AsyncValue<Map<String, double>> statsAsync, AsyncValue<List<Client>> clientsAsync, NumberFormat formatCurrency) {
    final loc = AppLocalizations.of(context);
    return Column(
      children: [
        // Top Section (Red Gradient Header + Floating Card)
        _buildTopSection(context, statsAsync, formatCurrency),
        
        // Search & Icons Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: loc.translate('search'),
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => _showAddClientDialog(context, ref),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE53935), Color(0xFFFF7043)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_add_alt_1, color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text('ADD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1, color: Color(0xFFEEEEEE)),

        // Client List
        Expanded(
          child: clientsAsync.when(
            data: (clients) {
              List<Client> displayClients = List.from(clients); // Create a copy to sort

              // Sort newest first
              displayClients.sort((a, b) => b.id.compareTo(a.id));

              if (_searchQuery.isNotEmpty) {
                displayClients = displayClients.where((c) {
                  return c.name.toLowerCase().contains(_searchQuery) ||
                         c.phone.toLowerCase().contains(_searchQuery);
                }).toList();
              }

              if (displayClients.isEmpty) {
                return const Center(child: Text('No customers found.'));
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, top: 12.0, bottom: 8.0),
                    child: Text(loc.translate('recently_added'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.only(bottom: 20),
                      itemCount: displayClients.length,
                      separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFEEEEEE)),
                      itemBuilder: (context, index) {
                        final client = displayClients[index];
                        return _buildClientListItem(context, client, formatCurrency, ref);
                      },
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }

  Widget _buildClientsOnlyContent(BuildContext context, AsyncValue<List<Client>> clientsAsync, NumberFormat formatCurrency) {
    final loc = AppLocalizations.of(context);
    return Column(
      children: [
        // Simple Header
        Container(
          width: double.infinity,
          color: const Color(0xFFE53935),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Text(loc.translate('all_clients'), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        
        // Search, Filter & Add Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: loc.translate('search'),
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              PopupMenuButton<String>(
                icon: const Icon(Icons.filter_alt_outlined, color: Color(0xFFD84315), size: 28),
                padding: EdgeInsets.zero,
                initialValue: _filterType,
                onSelected: (value) {
                  setState(() {
                    _filterType = value;
                  });
                },
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'all', child: Text(loc.translate('all'))),
                  PopupMenuItem(value: 'gain', child: Text(loc.translate('you_will_get'))),
                  PopupMenuItem(value: 'give', child: Text(loc.translate('you_will_give'))),
                  PopupMenuItem(value: 'clear', child: Text(loc.translate('cleared'))),
                ],
              ),
              const SizedBox(width: 12),
              InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => _showAddClientDialog(context, ref),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE53935), Color(0xFFFF7043)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_add_alt_1, color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text('ADD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1, color: Color(0xFFEEEEEE)),
        
        // Client List Only
        Expanded(
          child: clientsAsync.when(
            data: (clients) {
              List<Client> displayClients = clients;

              if (_filterType == 'give') {
                displayClients = displayClients.where((c) => c.netBalance < 0).toList();
              } else if (_filterType == 'gain') {
                displayClients = displayClients.where((c) => c.netBalance > 0).toList();
              } else if (_filterType == 'clear') {
                displayClients = displayClients.where((c) => c.netBalance == 0).toList();
              }

              if (_searchQuery.isNotEmpty) {
                displayClients = displayClients.where((c) {
                  return c.name.toLowerCase().contains(_searchQuery) ||
                         c.phone.toLowerCase().contains(_searchQuery);
                }).toList();
              }

              if (displayClients.isEmpty) {
                return const Center(child: Text('No customers found.'));
              }
              return ListView.separated(
                padding: const EdgeInsets.only(bottom: 20),
                itemCount: displayClients.length,
                separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFEEEEEE)),
                itemBuilder: (context, index) {
                  final client = displayClients[index];
                  return _buildClientListItem(context, client, formatCurrency, ref);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }

  Widget _buildTopSection(BuildContext context, AsyncValue<Map<String, double>> statsAsync, NumberFormat formatCurrency) {
    final loc = AppLocalizations.of(context);
    return SizedBox(
      height: 180,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Gradient Background
          Container(
            height: 120,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE64A19), Color(0xFFF4511E)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(loc.translate('my_khata'), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          
          // Floating Stats Card
          Positioned(
            top: 60,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  statsAsync.when(
                    data: (stats) => Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                formatCurrency.format(stats['dayna']), 
                                style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 18, fontWeight: FontWeight.bold)
                              ),
                              const SizedBox(height: 2),
                              Text(loc.translate('you_will_give'), style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                            ],
                          ),
                        ),
                        Container(height: 40, width: 1, color: Colors.grey.shade300),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                formatCurrency.format(stats['lana']), 
                                style: const TextStyle(color: Color(0xFFD32F2F), fontSize: 18, fontWeight: FontWeight.bold)
                              ),
                              const SizedBox(height: 2),
                              Text(loc.translate('you_will_get'), style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    loading: () => const SizedBox(height: 40, child: Center(child: CircularProgressIndicator())),
                    error: (e, st) => SizedBox(height: 40, child: Center(child: Text('Error: $e'))),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientListItem(BuildContext context, Client client, NumberFormat formatCurrency, WidgetRef ref) {
    Color statusColor;
    String statusText;
    
    if (client.netBalance > 0) {
      statusColor = const Color(0xFFD32F2F);
      statusText = AppLocalizations.of(context).translate('you_will_get');
    } else if (client.netBalance < 0) {
      statusColor = const Color(0xFF4CAF50);
      statusText = AppLocalizations.of(context).translate('you_will_give');
    } else {
      statusColor = Colors.grey.shade600;
      statusText = AppLocalizations.of(context).translate('cleared');
    }
    final balanceText = formatCurrency.format(client.netBalance.abs());
    final initial = client.name.isNotEmpty ? client.name[0].toUpperCase() : '?';
    
    final dateStr = client.lastTransactionDate != null
        ? '${DateFormat('MMM dd, yyyy').format(client.lastTransactionDate!)} • ${DateFormat('hh:mm a').format(client.lastTransactionDate!)}'
        : 'New Customer';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClientLedgerScreen(client: client),
          ),
        ).then((_) {
          // ignore: unused_result
          ref.refresh(clientsProvider);
          // ignore: unused_result
          ref.refresh(dashboardStatsProvider);
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey.shade200,
              child: Text(initial, style: const TextStyle(color: Color(0xFFD84315), fontSize: 20, fontWeight: FontWeight.w400)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(client.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(dateStr, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(balanceText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 2),
                Text(statusText, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blue),
                  onPressed: () => _showAddClientDialog(context, ref, existingClient: client),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Customer', style: TextStyle(fontWeight: FontWeight.bold)),
                        content: Text('Are you sure you want to delete ${client.name}?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true), 
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red), 
                            child: const Text('Delete', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await ref.read(dbServiceProvider).deleteClient(client.id);
                      // ignore: unused_result
                      ref.refresh(clientsProvider);
                      // ignore: unused_result
                      ref.refresh(dashboardStatsProvider);
                    }
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsContent(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.translate('settings'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ListTile(
            title: Text(loc.translate('choose_language')),
            trailing: const Icon(Icons.language),
            onTap: () {
              _showLanguageBottomSheet(context);
            },
          ),
          const Divider(),
          ListTile(
            title: Text(loc.translate('logout')),
            trailing: const Icon(Icons.logout, color: Colors.red),
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              // Just mark as logged out (if we had a flag), but DO NOT delete the account credentials.
              await prefs.setBool('is_logged_in', false);
              
              if (!context.mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBackupContent(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.translate('backup_restore_title'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 4),
          Text(loc.translate('backup_restore_sub'), style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 24),
          
          // Backup Card
          _buildActionCard(
            context: context,
            icon: Icons.cloud_download_outlined,
            iconColor: const Color(0xFFB45309),
            iconBgColor: const Color(0xFFFEF3C7),
            title: loc.translate('backup_data'),
            description: loc.translate('backup_desc'),
            buttonText: loc.translate('backup_data'),
            buttonIcon: Icons.download_outlined,
            isFilledButton: true,
            buttonColor: const Color(0xFFB45309),
            onTap: () async {
              try {
                await ref.read(backupServiceProvider).exportData();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.translate('export_complete'))));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${loc.translate('error')}: $e')));
              }
            },
          ),
          const SizedBox(height: 16),
          
          // Restore Card
          _buildActionCard(
            context: context,
            icon: Icons.cloud_upload_outlined,
            iconColor: const Color(0xFFE11D48),
            iconBgColor: const Color(0xFFFFE4E6),
            title: loc.translate('restore_data'),
            description: loc.translate('restore_desc'),
            buttonText: loc.translate('choose_json'),
            buttonIcon: Icons.file_upload_outlined,
            isFilledButton: false,
            buttonColor: const Color(0xFFE11D48),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(loc.translate('import_backup')),
                  content: Text(loc.translate('import_warning')),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(loc.translate('cancel'))),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE11D48)),
                      child: Text(loc.translate('import'), style: const TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                final success = await ref.read(backupServiceProvider).importData();
                if (success) {
                  // ignore: unused_result
                  ref.refresh(clientsProvider);
                  // ignore: unused_result
                  ref.refresh(dashboardStatsProvider);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.translate('import_success'))));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.translate('import_failed'))));
                }
              }
            },
          ),
          const SizedBox(height: 16),
          
          // Info Notice
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 20, color: Color(0xFFB45309)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(loc.translate('backup_info'), style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          Text(loc.translate('danger_zone'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFE11D48))),
          const SizedBox(height: 12),
          
          // Delete Card
          _buildActionCard(
            context: context,
            icon: Icons.delete_outline,
            iconColor: const Color(0xFFE11D48),
            iconBgColor: const Color(0xFFFFE4E6),
            title: loc.translate('delete_reset'),
            titleColor: const Color(0xFFE11D48),
            description: loc.translate('delete_reset_desc'),
            buttonText: loc.translate('delete_reset'),
            buttonIcon: Icons.delete_outline,
            isFilledButton: true,
            buttonColor: const Color(0xFFEF4444),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(loc.translate('delete_all_data')),
                  content: Text(loc.translate('delete_all_warning')),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(loc.translate('cancel'))),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: Text(loc.translate('delete'), style: const TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(dbServiceProvider).clearAllData();
                // ignore: unused_result
                ref.refresh(clientsProvider);
                // ignore: unused_result
                ref.refresh(dashboardStatsProvider);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.translate('all_data_deleted'))));
              }
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    Color titleColor = Colors.black87,
    required String description,
    required String buttonText,
    required IconData buttonIcon,
    required bool isFilledButton,
    required Color buttonColor,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: titleColor)),
                    const SizedBox(height: 6),
                    Text(description, style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: isFilledButton
                ? ElevatedButton.icon(
                    onPressed: onTap,
                    icon: Icon(buttonIcon, color: Colors.white, size: 20),
                    label: Text(buttonText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  )
                : OutlinedButton.icon(
                    onPressed: onTap,
                    icon: Icon(buttonIcon, color: buttonColor, size: 20),
                    label: Text(buttonText, style: TextStyle(color: buttonColor, fontWeight: FontWeight.bold, fontSize: 15)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: buttonColor, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showLanguageBottomSheet(BuildContext context) {
    final loc = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(loc.translate('choose_language'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ListTile(
                title: Text(loc.translate('english')),
                onTap: () {
                  ref.read(localeProvider.notifier).setLocale(const Locale('en'));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text(loc.translate('urdu')),
                onTap: () {
                  ref.read(localeProvider.notifier).setLocale(const Locale('ur'));
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

void _showAddClientDialog(BuildContext context, WidgetRef ref, {Client? existingClient}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AddClientSheet(existingClient: existingClient),
  );
}
