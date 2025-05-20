import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/emergency_numbers.service.dart';
import 'package:uuid/uuid.dart';

class ManageEmergencyNumbers extends StatefulWidget {
  const ManageEmergencyNumbers({super.key});

  @override
  State<ManageEmergencyNumbers> createState() => _ManageEmergencyNumbersState();
}

class _ManageEmergencyNumbersState extends State<ManageEmergencyNumbers> {
  final EmergencyNumbersService _service = EmergencyNumbersService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _addEmergencyNumber() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final number = EmergencyNumber(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        number: _numberController.text.trim(),
        description: _descriptionController.text.trim(),
        icon: Icons.emergency, // Will be set based on name
        color: Colors.red, // Will be set based on name
      );

      await _service.addEmergencyNumber(number);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Emergency number added successfully')),
        );
        _nameController.clear();
        _numberController.clear();
        _descriptionController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _deleteEmergencyNumber(String id) async {
    try {
      await _service.deleteEmergencyNumber(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Emergency number deleted successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Emergency Numbers'),
        backgroundColor: Colors.red,
      ),
      body: Column(
        children: [
          // Add new emergency number form
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Service Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a service name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _numberController,
                    decoration: const InputDecoration(
                      labelText: 'Emergency Number',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an emergency number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _addEmergencyNumber,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Add Emergency Number'),
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          // List of emergency numbers
          Expanded(
            child: StreamBuilder<List<EmergencyNumber>>(
              stream: _service.getEmergencyNumbers(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final numbers = snapshot.data!;

                if (numbers.isEmpty) {
                  return const Center(
                    child: Text('No emergency numbers added yet'),
                  );
                }

                return ListView.builder(
                  itemCount: numbers.length,
                  itemBuilder: (context, index) {
                    final number = numbers[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: number.color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(number.icon, color: number.color),
                        ),
                        title: Text(number.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(number.number),
                            Text(
                              number.description,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteEmergencyNumber(number.id),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
