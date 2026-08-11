import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/client_model.dart';
import '../providers/db_provider.dart';
import '../utils/app_localizations.dart';

class AddClientSheet extends ConsumerStatefulWidget {
  final Client? existingClient;
  
  const AddClientSheet({Key? key, this.existingClient}) : super(key: key);

  @override
  ConsumerState<AddClientSheet> createState() => _AddClientSheetState();
}

class _AddClientSheetState extends ConsumerState<AddClientSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _cnicController;
  
  String _selectedType = 'Customer';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingClient?.name ?? '');
    _phoneController = TextEditingController(text: widget.existingClient?.phone ?? '');
    _addressController = TextEditingController(text: widget.existingClient?.address ?? '');
    _cityController = TextEditingController(text: widget.existingClient?.city ?? '');
    _cnicController = TextEditingController(text: widget.existingClient?.cnic ?? '');
    _selectedType = widget.existingClient?.type ?? 'Customer';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _cnicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              Text(widget.existingClient != null ? loc.translate('update_customer') : loc.translate('add_new_customer_vendor'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFD84315))),
              const SizedBox(height: 24),
              
              // Client Type Selection Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedType,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFFD84315)),
                    items: [
                      DropdownMenuItem(value: 'Customer', child: Text(loc.translate('customer'), style: const TextStyle(fontSize: 15))),
                      DropdownMenuItem(value: 'Vendor', child: Text(loc.translate('vendor'), style: const TextStyle(fontSize: 15))),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedType = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              _buildModernTextField(_nameController, _selectedType == 'Customer' ? loc.translate('customer_name') : loc.translate('vendor_name'), Icons.person_outline),
              const SizedBox(height: 16),
              _buildModernTextField(_phoneController, loc.translate('phone_number'), Icons.phone_outlined, keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              _buildModernTextField(_addressController, loc.translate('address'), Icons.location_on_outlined),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildModernTextField(_cityController, loc.translate('city'), Icons.location_city_outlined)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildModernTextField(_cnicController, loc.translate('cnic'), Icons.credit_card_outlined, keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_nameController.text.trim().isNotEmpty) {
                      final db = ref.read(dbServiceProvider);
                      if (widget.existingClient != null) {
                        widget.existingClient!.name = _nameController.text.trim();
                        widget.existingClient!.phone = _phoneController.text.trim();
                        widget.existingClient!.address = _addressController.text.trim();
                        widget.existingClient!.city = _cityController.text.trim();
                        widget.existingClient!.cnic = _cnicController.text.trim();
                        widget.existingClient!.type = _selectedType;
                        await db.updateClient(widget.existingClient!);
                      } else {
                        final newClient = Client(
                          name: _nameController.text.trim(),
                          phone: _phoneController.text.trim(),
                          address: _addressController.text.trim(),
                          city: _cityController.text.trim(),
                          cnic: _cnicController.text.trim(),
                          type: _selectedType,
                        );
                        await db.addClient(newClient);
                      }
                      // ignore: unused_result
                      ref.refresh(clientsProvider);
                      // ignore: unused_result
                      ref.refresh(dashboardStatsProvider);
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD84315),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  child: Text(loc.translate('save_customer'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField(TextEditingController controller, String label, IconData icon, {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFFD84315), size: 22),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD84315), width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }
}
