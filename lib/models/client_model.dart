import 'package:isar/isar.dart';

part 'client_model.g.dart';

@collection
class Client {
  Id id = Isar.autoIncrement; // you can also use id = null to auto increment

  String name;
  String phone;
  String? address;
  String? city;
  String? cnic;
  String? notes;
  
  @Index()
  double netBalance; // positive = Receivable, negative = Payable
  
  DateTime? lastTransactionDate;
  List<String> businessCategories;
  
  double totalGave;
  double totalGot;

  Client({
    this.name = '',
    this.phone = '',
    this.address,
    this.city,
    this.cnic,
    this.notes,
    this.netBalance = 0.0,
    this.lastTransactionDate,
    this.businessCategories = const [],
    this.totalGave = 0.0,
    this.totalGot = 0.0,
  });

  @ignore
  String get initials {
    final names = name.split(' ');
    if (names.length > 1) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    if (name.isNotEmpty) {
      return name.substring(0, name.length > 1 ? 2 : 1).toUpperCase();
    }
    return '?';
  }

  @ignore
  bool get isReceivable => netBalance > 0;
}
