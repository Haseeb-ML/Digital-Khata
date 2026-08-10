import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/client_model.dart';
import '../models/transaction_model.dart';
import '../providers/db_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_localizations.dart';

class AddTransactionSheet extends ConsumerStatefulWidget {
  final Client client;
  final bool initialIsGave;
  final TransactionModel? existingTx;

  const AddTransactionSheet({
    super.key, 
    required this.client, 
    this.initialIsGave = true,
    this.existingTx,
  });

  @override
  ConsumerState<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  late String transactionType;
  late String itemCategory;
  late String unit;
  
  late DateTime selectedDate;
  final _amountController = TextEditingController();
  final _weightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existingTx != null) {
      final tx = widget.existingTx!;
      final validTypes = ['Purchased Goods', 'Sold Goods', 'Cash Given', 'Cash Received'];
      
      transactionType = validTypes.contains(tx.type) 
          ? tx.type 
          : (tx.isGave ? 'Cash Given' : 'Cash Received');
          
      itemCategory = tx.itemCategory ?? 'Rice';
      unit = tx.unit ?? 'KG';
      selectedDate = tx.date ?? DateTime.now();
      _amountController.text = tx.amount.toString();
      _weightController.text = tx.weight?.toString() ?? '';
    } else {
      transactionType = widget.initialIsGave ? 'Cash Given' : 'Cash Received';
      itemCategory = 'Rice';
      unit = 'KG';
      selectedDate = DateTime.now();
    }
  }

  bool get isMaal => transactionType == 'Purchased Goods' || transactionType == 'Sold Goods';
  bool get isGave => transactionType == 'Purchased Goods' || transactionType == 'Cash Given';

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final activeColor = isGave ? AppTheme.primaryRed : AppTheme.primaryGreen;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.existingTx != null ? loc.translate('update_transaction') : loc.translate('add_transaction'), style: Theme.of(context).textTheme.titleLarge),
                      Text(widget.client.name, style: const TextStyle(color: AppTheme.textMuted)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
              const SizedBox(height: 24),

              // Transaction Type Dropdown
              Text(loc.translate('transaction_type'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: activeColor.withOpacity(0.1),
                  border: Border.all(color: activeColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: transactionType,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: activeColor),
                    icon: Icon(Icons.arrow_drop_down, color: activeColor),
                    items: ['Purchased Goods', 'Sold Goods', 'Cash Given', 'Cash Received'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      if (newValue != null) {
                        setState(() {
                          transactionType = newValue;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Maal specific fields
              if (isMaal) ...[
                Text(loc.translate('which_goods'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Row(
                  children: ['Rice', 'Scrap', 'Other'].map((category) {
                    final isSelected = itemCategory == category;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => itemCategory = category),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? activeColor : AppTheme.borderLight.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              category,
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppTheme.textMuted,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: TextField(
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: loc.translate('weight'),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          filled: true,
                          fillColor: AppTheme.borderLight.withOpacity(0.3),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 4,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: unit,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          filled: true,
                          fillColor: AppTheme.borderLight.withOpacity(0.3),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        items: ['KG', 'Maund', 'Tons', 'Bags'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          if (newValue != null) setState(() => unit = newValue);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // Amount Input
              Text(loc.translate('amount'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: activeColor),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: TextStyle(color: AppTheme.textMuted.withOpacity(0.5)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  filled: true,
                  fillColor: activeColor.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Date Picker Field
              Text(loc.translate('date'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) setState(() => selectedDate = date);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.borderLight),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: AppTheme.textMuted, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        selectedDate.day == DateTime.now().day
                            ? '${loc.translate('today')} — ${DateFormat('dd MMM yyyy').format(selectedDate)}'
                            : DateFormat('dd MMM yyyy').format(selectedDate),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final amount = double.tryParse(_amountController.text) ?? 0;
                    if (amount <= 0) return;
                    
                    double? parsedWeight;
                    if (isMaal) {
                      parsedWeight = double.tryParse(_weightController.text);
                    }

                    final tx = TransactionModel(
                      clientId: widget.client.id,
                      amount: amount,
                      date: selectedDate,
                      type: transactionType,
                      itemCategory: isMaal ? itemCategory : null,
                      weight: isMaal ? parsedWeight : null,
                      unit: isMaal ? unit : null,
                    );

                    final db = ref.read(dbServiceProvider);
                    if (widget.existingTx != null) {
                      await db.updateTransaction(widget.client, widget.existingTx!, tx);
                    } else {
                      await db.addTransaction(widget.client, tx);
                    }

                    // Refresh providers
                    // ignore: unused_result
                    ref.refresh(clientTransactionsProvider(widget.client.id));
                    // ignore: unused_result
                    ref.refresh(clientsProvider);
                    // ignore: unused_result
                    ref.refresh(dashboardStatsProvider);

                    if (mounted) {
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: activeColor,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(loc.translate('save').toUpperCase(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
