import 'package:flutter/material.dart';
import '../models/medicine.dart';

class MedicineDetailScreen extends StatefulWidget {
  final Medicine medicine;
  const MedicineDetailScreen({super.key, required this.medicine});

  @override
  State<MedicineDetailScreen> createState() => _MedicineDetailScreenState();
}

class _MedicineDetailScreenState extends State<MedicineDetailScreen> {
  int _quantity = 1;

  void _increment() {
    setState(() {
      if (_quantity < 99) _quantity++;
    });
  }

  void _decrement() {
    setState(() {
      if (_quantity > 1) _quantity--;
    });
  }

  @override
  Widget build(BuildContext context) {
    final med = widget.medicine;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine Details'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF198754), Color(0xFF28a745)],
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                med.image ?? 'https://via.placeholder.com/400',
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 250,
                  color: Colors.grey[200],
                  child: Center(
                    child: Icon(
                      Icons.image_not_supported,
                      size: 60,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Name and prescription badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    med.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (med.prescriptionRequired)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber[200]!),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.medical_services,
                          size: 16,
                          color: Colors.amber,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Prescription Required',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Brand
            if (med.brand != null)
              _buildInfoRow(Icons.folder, 'Brand', med.brand!),
            // Category
            if (med.category != null)
              _buildInfoRow(
                Icons.folder,
                'Category',
                med.category!.name,
                color: Colors.green[700]!,
              ),
            // Form & Strength
            if (med.form != null)
              _buildInfoRow(Icons.science, 'Form', med.form!),
            if (med.strength != null)
              _buildInfoRow(Icons.monitor_weight, 'Strength', med.strength!),
            const Divider(height: 24),
            // Active Ingredients
            if (med.activeIngredients.isNotEmpty) ...[
              Text(
                'Active Ingredients',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: med.activeIngredients
                    .map(
                      (ing) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Text(
                          ing.name,
                          style: TextStyle(color: Colors.blue[800]),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const Divider(height: 24),
            ],
            // Price and availability
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Price', style: TextStyle(fontSize: 14)),
                    Text(
                      '\$${med.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: med.isAvailable ? Colors.green[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: med.isAvailable
                          ? Colors.green[200]!
                          : Colors.red[200]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        med.isAvailable ? Icons.check_circle : Icons.cancel,
                        color: med.isAvailable ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        med.isAvailable ? 'In Stock' : 'Out of Stock',
                        style: TextStyle(
                          color: med.isAvailable ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            // Dosage
            if (med.dosage != null && med.dosage!.isNotEmpty) ...[
              _buildSection('Dosage', med.dosage!),
              const SizedBox(height: 16),
            ],
            // Instructions
            if (med.instructions != null && med.instructions!.isNotEmpty) ...[
              _buildSection('Instructions', med.instructions!),
              const SizedBox(height: 16),
            ],
            // Warnings
            if (med.warnings != null && med.warnings!.isNotEmpty) ...[
              _buildSection(
                'Warnings',
                med.warnings!,
                color: Colors.orange[700]!,
              ),
              const SizedBox(height: 16),
            ],
            // Side Effects
            if (med.sideEffects != null && med.sideEffects!.isNotEmpty) ...[
              _buildSection(
                'Side Effects',
                med.sideEffects!,
                color: Colors.red[700]!,
              ),
              const SizedBox(height: 16),
            ],
            // Quantity selector and order button
            if (med.isAvailable) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Quantity',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: _decrement,
                              icon: const Icon(Icons.remove_circle_outline),
                              color: Colors.green[700],
                              iconSize: 32,
                            ),
                            Container(
                              width: 50,
                              alignment: Alignment.center,
                              child: Text(
                                '$_quantity',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _increment,
                              icon: const Icon(Icons.add_circle_outline),
                              color: Colors.green[700],
                              iconSize: 32,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: Add to cart logic
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Added $_quantity ${med.name} to cart',
                              ),
                              backgroundColor: Colors.green[700],
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Add to Cart',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color color = Colors.grey,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[700]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    String title,
    String content, {
    Color color = Colors.green,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(content, style: const TextStyle(height: 1.5)),
        ),
      ],
    );
  }
}
