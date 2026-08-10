import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/client_model.dart';
import '../models/transaction_model.dart';
import '../services/db_service.dart';

final dbServiceProvider = Provider((ref) => DbService());

final dbInitProvider = FutureProvider((ref) async {
  final db = ref.watch(dbServiceProvider);
  await db.init();
  return true;
});

final clientsProvider = FutureProvider<List<Client>>((ref) async {
  final db = ref.watch(dbServiceProvider);
  // Ensure DB is initialized
  await ref.watch(dbInitProvider.future);
  return db.getAllClients();
});

final dashboardStatsProvider = FutureProvider<Map<String, double>>((ref) async {
  final clients = await ref.watch(clientsProvider.future);
  double lana = 0;
  double dayna = 0;
  for (final client in clients) {
    if (client.netBalance > 0) {
      lana += client.netBalance;
    } else {
      dayna += client.netBalance.abs();
    }
  }
  return {'lana': lana, 'dayna': dayna};
});

final clientTransactionsProvider = FutureProvider.family<List<TransactionModel>, int>((ref, clientId) async {
  final db = ref.watch(dbServiceProvider);
  await ref.watch(dbInitProvider.future);
  return db.getClientTransactions(clientId);
});
