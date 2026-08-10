import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/client_model.dart';
import '../models/transaction_model.dart';
import '../theme/app_theme.dart';
import '../providers/db_provider.dart';
import '../widgets/add_transaction_sheet.dart';
import '../services/pdf_service.dart';
import '../utils/app_localizations.dart';

class ClientLedgerScreen extends ConsumerStatefulWidget {
  final Client client;

  const ClientLedgerScreen({super.key, required this.client});

  @override
  ConsumerState<ClientLedgerScreen> createState() => _ClientLedgerScreenState();
}

class _ClientLedgerScreenState extends ConsumerState<ClientLedgerScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final transactionsAsync = ref.watch(clientTransactionsProvider(widget.client.id));
    final formatCurrency = NumberFormat.currency(locale: 'en_PK', symbol: 'Rs ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Section (Red Header + Overlapping Card)
            _buildTopSection(context, formatCurrency),
            
            const SizedBox(height: 16),
            
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: loc.translate('search'),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Table Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(loc.translate('entries'), style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                  Expanded(
                    flex: 1,
                    child: Center(child: Text(loc.translate('you_gave'), style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 13))),
                  ),
                  Expanded(
                    flex: 1,
                    child: Align(alignment: Alignment.centerRight, child: Text(loc.translate('you_got'), style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 13))),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // List
            Expanded(
              child: Container(
                color: Colors.white,
                child: transactionsAsync.when(
                  data: (transactions) {
                    var filtered = transactions;
                    if (_searchQuery.isNotEmpty) {
                      filtered = transactions.where((tx) => 
                        (tx.type.toLowerCase().contains(_searchQuery)) || 
                        (tx.itemCategory?.toLowerCase().contains(_searchQuery) ?? false) ||
                        (tx.note?.toLowerCase().contains(_searchQuery) ?? false)
                      ).toList();
                    }

                    if (filtered.isEmpty) {
                      return const Center(child: Text('No transactions found.'));
                    }

                    // Calculate running balances
                    // We assume transactions are sorted Date Descending from DB
                    // So we must calculate from bottom to top
                    List<double> runningBalances = List.filled(filtered.length, 0.0);
                    double currentBal = 0.0;
                    for (int i = filtered.length - 1; i >= 0; i--) {
                       final tx = filtered[i];
                       if (tx.isGave) {
                          currentBal += tx.amount;
                       } else {
                          currentBal -= tx.amount;
                       }
                       runningBalances[i] = currentBal;
                    }

                    return ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final tx = filtered[index];
                        return _buildTransactionTile(context, tx, runningBalances[index], formatCurrency);
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Center(child: Text('Error: $e')),
                ),
              ),
            ),
            
            // Bottom Actions
            _buildBottomActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSection(BuildContext context, NumberFormat formatCurrency) {
    return SizedBox(
      height: 190, // Space for Red container (140) + overlapping part of card
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Red background top
          Container(
            height: 140,
            color: const Color(0xFFE53935), // Red color from screenshot
            padding: const EdgeInsets.only(top: 16, left: 8, right: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  widget.client.name, 
                                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text('Customer', style: TextStyle(color: Color(0xFFE53935), fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.info_outline, color: Colors.white),
                      onPressed: () => _showClientDetailsSheet(context),
                    ),
                    IconButton(
                      icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                      onPressed: () {
                        final transactionsAsync = ref.read(clientTransactionsProvider(widget.client.id));
                        transactionsAsync.whenData((transactions) {
                          PdfService.generateAndPrintInvoice(widget.client, transactions);
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.share, color: Colors.white),
                      onPressed: () {
                        final transactionsAsync = ref.read(clientTransactionsProvider(widget.client.id));
                        transactionsAsync.whenData((transactions) {
                          PdfService.generateAndShareInvoice(widget.client, transactions);
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Floating Card
          Positioned(
            top: 90,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatCurrency.format(widget.client.netBalance.abs()),
                    style: TextStyle(
                      fontSize: 22, 
                      fontWeight: FontWeight.bold, 
                      color: widget.client.isReceivable ? const Color(0xFFE53935) : const Color(0xFF43A047)
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.client.isReceivable ? 'You will get' : 'You will give',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(BuildContext context, TransactionModel tx, double runningBal, NumberFormat formatCurrency) {
    final isGave = tx.isGave;
    
    // Formatting Date: "Sun, 09 Aug 26 • 01:42 AM"
    final dateStr = tx.date != null ? DateFormat('EEE, dd MMM yy • hh:mm a').format(tx.date!) : '-';
    
    final loc = AppLocalizations.of(context);
    String typeKey = tx.type.replaceAll(' ', '_').toLowerCase();
    String typeLoc = loc.translate(typeKey);
    
    String details = typeLoc;
    if (tx.isMaal) {
      String catKey = (tx.itemCategory ?? '').toLowerCase();
      String catLoc = loc.translate(catKey);
      String w = tx.weight?.toString() ?? '';
      String u = tx.unit ?? '';
      
      if (w.isNotEmpty && u.isNotEmpty) {
        details = '$typeLoc - $catLoc ($w $u)';
      } else {
        details = '$typeLoc - $catLoc';
      }
    }

    // Colors
    final gaveColor = const Color(0xFFC62828);
    final gotColor = const Color(0xFF2E7D32);
    final faintRed = const Color(0xFFFFF0F0);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Column 1: Details
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: () => _showTransactionOptions(context, tx),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(dateStr, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(details, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      color: faintRed,
                      child: Text('Bal. ${formatCurrency.format(runningBal.abs())}', style: TextStyle(color: Colors.grey.shade700, fontSize: 11)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Column 2: You Gave
          Expanded(
            flex: 1,
            child: InkWell(
              onTap: () => _showTransactionOptions(context, tx),
              child: Container(
                color: isGave ? faintRed : Colors.white,
                child: Center(
                  child: isGave 
                    ? Text(formatCurrency.format(tx.amount).replaceAll('Rs ', ''), style: TextStyle(color: gaveColor, fontWeight: FontWeight.bold, fontSize: 14))
                    : const SizedBox(),
                ),
              ),
            ),
          ),
          
          // Column 3: You Got
          Expanded(
            flex: 1,
            child: InkWell(
              onTap: () => _showTransactionOptions(context, tx),
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.only(right: 16),
                alignment: Alignment.centerRight,
                child: !isGave 
                  ? Text(formatCurrency.format(tx.amount).replaceAll('Rs ', ''), style: TextStyle(color: gotColor, fontWeight: FontWeight.bold, fontSize: 14))
                  : const SizedBox(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTransactionOptions(BuildContext context, TransactionModel tx) {
    final loc = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: Text(loc.translate('edit')),
                onTap: () {
                  Navigator.pop(context);
                  _editTransaction(context, tx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share, color: Colors.green),
                title: Text(loc.translate('share')),
                onTap: () {
                  Navigator.pop(context);
                  PdfService.generateAndShareInvoice(widget.client, [tx]);
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.orange),
                title: Text(loc.translate('pdf')),
                onTap: () {
                  Navigator.pop(context);
                  PdfService.generateAndPrintInvoice(widget.client, [tx]);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(loc.translate('delete'), style: const TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteTransaction(context, tx);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteTransaction(BuildContext context, TransactionModel tx) {
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.translate('delete')),
        content: Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.translate('cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final db = ref.read(dbServiceProvider);
              await db.deleteTransaction(widget.client, tx);
              // ignore: unused_result
              ref.refresh(clientTransactionsProvider(widget.client.id));
              // ignore: unused_result
              ref.refresh(clientsProvider);
              // ignore: unused_result
              ref.refresh(dashboardStatsProvider);
            },
            child: Text(loc.translate('delete'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _editTransaction(BuildContext context, TransactionModel tx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionSheet(
        client: widget.client,
        initialIsGave: tx.isGave,
        existingTx: tx,
      ),
    ).then((_) {
        // ignore: unused_result
        ref.refresh(clientTransactionsProvider(widget.client.id));
        // ignore: unused_result
        ref.refresh(clientsProvider);
        // ignore: unused_result
        ref.refresh(dashboardStatsProvider);
    });
  }

  Widget _buildBottomActions(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => AddTransactionSheet(client: widget.client, initialIsGave: true),
                  ).then((_) {
                      // ignore: unused_result
                      ref.refresh(clientTransactionsProvider(widget.client.id));
                      // ignore: unused_result
                      ref.refresh(clientsProvider);
                      // ignore: unused_result
                      ref.refresh(dashboardStatsProvider);
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC62828), // Darker Red for "YOU GAVE Rs"
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text('${loc.translate('you_gave')} Rs', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => AddTransactionSheet(client: widget.client, initialIsGave: false),
                  ).then((_) {
                      // ignore: unused_result
                      ref.refresh(clientTransactionsProvider(widget.client.id));
                      // ignore: unused_result
                      ref.refresh(clientsProvider);
                      // ignore: unused_result
                      ref.refresh(dashboardStatsProvider);
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32), // Darker Green for "YOU GOT Rs"
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text('${loc.translate('you_got')} Rs', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClientDetailsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFFBE9E7),
                    child: Text(widget.client.initials, style: const TextStyle(color: Color(0xFFD84315), fontSize: 24, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppLocalizations.of(context).translate('customer_details'), style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(widget.client.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (widget.client.phone.isNotEmpty) _buildModernDetailRow(Icons.phone_outlined, 'Phone', widget.client.phone),
              if (widget.client.cnic != null && widget.client.cnic!.isNotEmpty) _buildModernDetailRow(Icons.credit_card_outlined, 'CNIC', widget.client.cnic!),
              if (widget.client.address != null && widget.client.address!.isNotEmpty) _buildModernDetailRow(Icons.location_on_outlined, 'Address', widget.client.address!),
              if (widget.client.city != null && widget.client.city!.isNotEmpty) _buildModernDetailRow(Icons.location_city_outlined, 'City', widget.client.city!),
              if (widget.client.notes != null && widget.client.notes!.isNotEmpty) _buildModernDetailRow(Icons.note_alt_outlined, 'Notes', widget.client.notes!),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: Color(0xFFD84315)),
                  ),
                  child: Text(AppLocalizations.of(context).translate('close'), style: const TextStyle(color: Color(0xFFD84315), fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModernDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFFD84315), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
