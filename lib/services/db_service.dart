import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/client_model.dart';
import '../models/transaction_model.dart';

class DbService {
  late Isar isar;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [ClientSchema, TransactionModelSchema],
      directory: dir.path,
    );
  }

  // --- Clients ---

  Future<List<Client>> getAllClients() async {
    return await isar.clients.where().findAll();
  }

  Future<void> addClient(Client client) async {
    await isar.writeTxn(() async {
      await isar.clients.put(client);
    });
  }

  Future<void> updateClient(Client client) async {
    await isar.writeTxn(() async {
      await isar.clients.put(client);
    });
  }

  Future<void> deleteClient(int clientId) async {
    await isar.writeTxn(() async {
      // 1. Delete all transactions associated with this client
      await isar.transactionModels.filter().clientIdEqualTo(clientId).deleteAll();
      // 2. Delete the client itself
      await isar.clients.delete(clientId);
    });
  }

  // --- Transactions ---

  Future<List<TransactionModel>> getClientTransactions(int clientId) async {
    return await isar.transactionModels
        .where()
        .clientIdEqualTo(clientId)
        .sortByDateDesc()
        .findAll();
  }

  Future<void> addTransaction(Client client, TransactionModel tx) async {
    await isar.writeTxn(() async {
      // 1. Save Transaction
      await isar.transactionModels.put(tx);

      // 2. Update Client Balances
      if (tx.type == 'Sold Goods' || tx.type == 'Cash Given') {
        client.totalGave += tx.amount;
        client.netBalance += tx.amount; // Lana (Receivable) badhega
      } else if (tx.type == 'Purchased Goods' || tx.type == 'Cash Received') {
        client.totalGot += tx.amount;
        client.netBalance -= tx.amount; // Dayna (Payable) badhega
      }
      
      client.lastTransactionDate = tx.date;

      await isar.clients.put(client);
    });
  }

  Future<void> deleteTransaction(Client client, TransactionModel tx) async {
    await isar.writeTxn(() async {
      // 1. Delete Transaction
      await isar.transactionModels.delete(tx.id);

      // 2. Reverse Client Balances
      if (tx.type == 'Sold Goods' || tx.type == 'Cash Given') {
        client.totalGave -= tx.amount;
        client.netBalance -= tx.amount;
      } else if (tx.type == 'Purchased Goods' || tx.type == 'Cash Received') {
        client.totalGot -= tx.amount;
        client.netBalance += tx.amount;
      }
      
      // Note: We are not perfectly restoring lastTransactionDate here if this was the latest.
      // But for simplicity, we leave it as is or it'll just stay the same.
      
      await isar.clients.put(client);
    });
  }

  Future<void> updateTransaction(Client client, TransactionModel oldTx, TransactionModel newTx) async {
    await isar.writeTxn(() async {
      // 1. Reverse old transaction effects
      if (oldTx.type == 'Sold Goods' || oldTx.type == 'Cash Given') {
        client.totalGave -= oldTx.amount;
        client.netBalance -= oldTx.amount;
      } else if (oldTx.type == 'Purchased Goods' || oldTx.type == 'Cash Received') {
        client.totalGot -= oldTx.amount;
        client.netBalance += oldTx.amount;
      }

      // 2. Delete old transaction from DB
      await isar.transactionModels.delete(oldTx.id);

      // 3. Save new transaction to DB
      await isar.transactionModels.put(newTx);

      // 4. Apply new transaction effects
      if (newTx.type == 'Sold Goods' || newTx.type == 'Cash Given') {
        client.totalGave += newTx.amount;
        client.netBalance += newTx.amount;
      } else if (newTx.type == 'Purchased Goods' || newTx.type == 'Cash Received') {
        client.totalGot += newTx.amount;
        client.netBalance -= newTx.amount;
      }

      client.lastTransactionDate = newTx.date;
      
      await isar.clients.put(client);
    });
  }
}
