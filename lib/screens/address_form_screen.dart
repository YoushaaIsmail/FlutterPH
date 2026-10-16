// lib/screens/address_form_screen.dart
import 'package:flutter/material.dart';
import '../models/address.dart';
import '../services/address_service.dart';
import 'map_picker_screen.dart';

class AddressFormScreen extends StatefulWidget {
  final Address? address;
  final AddressService addressService;

  const AddressFormScreen({
    super.key,
    this.address,
    required this.addressService,
  });

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _labelController;
  late TextEditingController _addressLineController;
  late TextEditingController _cityController;
  late TextEditingController _postalCodeController;
  late TextEditingController _phoneController;
  bool _isDefault = false;
  double _x = 0.0;
  double _y = 0.0;
  String _selectedAddressText = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.address?.label ?? '');
    _addressLineController = TextEditingController(
      text: widget.address?.addressLine ?? '',
    );
    _cityController = TextEditingController(text: widget.address?.city ?? '');
    _postalCodeController = TextEditingController(
      text: widget.address?.postalCode ?? '',
    );
    _phoneController = TextEditingController(text: widget.address?.phone ?? '');
    _isDefault = widget.address?.isDefault ?? false;
    _x = widget.address?.x ?? 0.0;
    _y = widget.address?.y ?? 0.0;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _addressLineController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapPickerScreen(
          onLocationSelected: (x, y, address) {
            setState(() {
              _x = x;
              _y = y;
              _selectedAddressText = address;
            });
          },
          initialX: _x != 0.0 ? _x : null,
          initialY: _y != 0.0 ? _y : null,
        ),
      ),
    );
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    if (_x == 0.0 && _y == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a location on the map'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final address = Address(
        id: widget.address?.id ?? '',
        user: widget.address?.user ?? 0,
        label: _labelController.text,
        addressLine: _addressLineController.text,
        city: _cityController.text,
        postalCode: _postalCodeController.text,
        phone: _phoneController.text,
        isDefault: _isDefault,
        x: _x,
        y: _y,
      );

      if (widget.address == null) {
        await widget.addressService.createAddress(address);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Address added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await widget.addressService.updateAddress(widget.address!.id, address);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Address updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.address == null ? 'Add Address' : 'Edit Address'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: Colors.white),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Location Picker
              Card(
                elevation: 2,
                child: InkWell(
                  onTap: _pickLocation,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: _x != 0.0 ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedAddressText.isNotEmpty
                                    ? _selectedAddressText
                                    : 'Tap to select location on map',
                                style: TextStyle(
                                  color: _x != 0.0 ? Colors.black : Colors.grey,
                                ),
                              ),
                              if (_x != 0.0)
                                Text(
                                  'Lat: ${_y.toStringAsFixed(6)}, Lng: ${_x.toStringAsFixed(6)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Address Label
              TextFormField(
                controller: _labelController,
                decoration: const InputDecoration(
                  labelText: 'Address Label',
                  hintText: 'e.g., Home, Work, etc.',
                  prefixIcon: Icon(Icons.label),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a label';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Address Line
              TextFormField(
                controller: _addressLineController,
                decoration: const InputDecoration(
                  labelText: 'Address Line',
                  hintText: 'Street name and number',
                  prefixIcon: Icon(Icons.home),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // City
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'City',
                  prefixIcon: Icon(Icons.location_city),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter city';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Postal Code and Phone in Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _postalCodeController,
                      decoration: const InputDecoration(
                        labelText: 'Postal Code',
                        prefixIcon: Icon(Icons.code),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Default Address Switch
              SwitchListTile(
                title: const Text('Set as Default Address'),
                subtitle: const Text('This address will be used as primary'),
                value: _isDefault,
                onChanged: (value) {
                  setState(() {
                    _isDefault = value;
                  });
                },
                activeColor: Colors.green,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    widget.address == null ? 'Add Address' : 'Update Address',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
