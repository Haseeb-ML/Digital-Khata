import 'package:isar/isar.dart';

part 'transaction_model.g.dart';

@collection
class TransactionModel {
  Id id = Isar.autoIncrement;

  @Index()
  int clientId;

  DateTime? date;
  double amount;
  String type; // 'Purchased Goods', 'Sold Goods', 'Cash Given', 'Cash Received'
  String? itemCategory; // 'Rice', 'Scrap', 'Other'
  double? weight;
  String? unit; // 'KG', 'Mann', 'Tons'
  
  String? note;
  String? businessCategory;

  TransactionModel({
    this.clientId = -1,
    this.date,
    this.amount = 0.0,
    this.type = 'Cash Given',
    this.itemCategory,
    this.weight,
    this.unit,
    this.note,
    this.businessCategory,
  });

  @ignore
  bool get isGave => type == 'Purchased Goods' || type == 'Cash Given';
  
  @ignore
  bool get isMaal => type == 'Purchased Goods' || type == 'Sold Goods';
}
