import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
          const NavigationDestination(icon: Icon(Icons.backup_outlined), label: 'Backup'),
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
            const Center(child: Text('Backup - Coming Soon!')),
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
      statusText = "You'll Get";
    } else if (client.netBalance < 0) {
      statusColor = const Color(0xFF4CAF50);
      statusText = "You'll Give";
    } else {
      statusColor = Colors.grey.shade600;
      statusText = "Settled";
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
