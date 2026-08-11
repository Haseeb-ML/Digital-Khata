import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';

import '../models/client_model.dart';
import '../models/transaction_model.dart';
import 'db_service.dart';

class BackupService {
  final DbService _dbService;

  BackupService(this._dbService);

  Future<void> exportData() async {
    final clients = await _dbService.getAllClients();
    
    // Get all transactions
    final allTransactions = <TransactionModel>[];
    for (var client in clients) {
      final txs = await _dbService.getClientTransactions(client.id);
      allTransactions.addAll(txs);
    }

    final data = {
      'clients': clients.map(_clientToJson).toList(),
      'transactions': allTransactions.map(_txToJson).toList(),
    };

    final jsonString = jsonEncode(data);

    // Save to temp file
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/my_khata_backup_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(jsonString);

    // Share / Save via SharePlus
    await Share.shareXFiles([XFile(file.path)], subject: 'My Khata Backup');
  }

  Future<bool> importData() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();

      try {
        final data = jsonDecode(jsonString) as Map<String, dynamic>;

        final clientsList = data['clients'] as List<dynamic>;
        final txsList = data['transactions'] as List<dynamic>;

        final clients = clientsList.map((e) => _clientFromJson(e)).toList();
        final txs = txsList.map((e) => _txFromJson(e)).toList();

        await _dbService.clearAndImportData(clients, txs);
        return true;
      } catch (e) {
        print("Import Error: $e");
        return false;
      }
    }
    return false;
  }

  Map<String, dynamic> _clientToJson(Client c) => {
        'id': c.id,
        'name': c.name,
        'phone': c.phone,
        'address': c.address,
        'city': c.city,
        'cnic': c.cnic,
        'notes': c.notes,
        'netBalance': c.netBalance,
        'lastTransactionDate': c.lastTransactionDate?.toIso8601String(),
        'businessCategories': c.businessCategories,
        'totalGave': c.totalGave,
        'totalGot': c.totalGot,
        'type': c.type,
      };

  Client _clientFromJson(Map<String, dynamic> json) {
    return Client(
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'],
      city: json['city'],
      cnic: json['cnic'],
      notes: json['notes'],
      netBalance: (json['netBalance'] ?? 0.0).toDouble(),
      lastTransactionDate: json['lastTransactionDate'] != null
          ? DateTime.tryParse(json['lastTransactionDate'])
          : null,
      businessCategories: List<String>.from(json['businessCategories'] ?? []),
      totalGave: (json['totalGave'] ?? 0.0).toDouble(),
      totalGot: (json['totalGot'] ?? 0.0).toDouble(),
      type: json['type'] ?? 'Customer',
    )..id = json['id'];
  }

  Map<String, dynamic> _txToJson(TransactionModel tx) => {
        'id': tx.id,
        'clientId': tx.clientId,
        'date': tx.date?.toIso8601String(),
        'amount': tx.amount,
        'type': tx.type,
        'itemCategory': tx.itemCategory,
        'weight': tx.weight,
        'unit': tx.unit,
        'note': tx.note,
        'businessCategory': tx.businessCategory,
      };

  TransactionModel _txFromJson(Map<String, dynamic> json) {
    return TransactionModel(
      clientId: json['clientId'] ?? -1,
      date: json['date'] != null ? DateTime.tryParse(json['date']) : null,
      amount: (json['amount'] ?? 0.0).toDouble(),
      type: json['type'] ?? 'Cash Given',
      itemCategory: json['itemCategory'],
      weight: json['weight'] != null ? (json['weight']).toDouble() : null,
      unit: json['unit'],
      note: json['note'],
      businessCategory: json['businessCategory'],
    )..id = json['id'];
  }
}
