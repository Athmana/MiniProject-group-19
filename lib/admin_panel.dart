import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:gowayanad/services/auth_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  bool _isLoading = false;
  String _statusMessage = "Please select a CSV file to upload users.";

  Future<void> _pickAndProcessCSV(String role) async {
    try {
      // 1. Pick the file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _isLoading = true;
          _statusMessage = "Processing CSV file...";
        });

        File file = File(result.files.single.path!);

        // Read the entire file as a string
        final String csvString = await file.readAsString();

        // Convert the CSV string to a list of lists manully
        List<String> lines = csvString.split('\n');
        List<List<dynamic>> fields = [];
        for (String line in lines) {
          if (line.trim().isNotEmpty) {
            fields.add(line.split(','));
          }
        }

        if (fields.isEmpty || fields.length < 2) {
          setState(() {
            _isLoading = false;
            _statusMessage = "CSV is empty or missing data rows.";
          });
          return;
        }

        // We assume Row 0 is the header: Name, Phone, Password
        int successCount = 0;
        int failCount = 0;

        for (int i = 1; i < fields.length; i++) {
          final row = fields[i];
- [x] Post-Merge Error Resolution
    - [x] Clean up malformed conflict markers in all affected files
    - [x] Restore consistent API naming (`destLat`/`destLng`)
    - [x] Fix undefined references in `TrackingService` and `homepage.dart`
    - [x] Verify build stability with `flutter analyze` (0 errors)
- [x] Merge & Final Push
    - [x] Resolve non-fast-forward push issues
    - [x] Push clean, verified code to `admin-panel` branch

          if (row.length >= 3) {
            String name = row[0].toString().trim();
            String phone = row[1].toString().trim();
            String password = row[2].toString().trim();

            if (phone.isNotEmpty && password.isNotEmpty && name.isNotEmpty) {
              try {
                await AuthService().signUpWithPhone(
                  name,
                  phone,
                  password,
                  role,
                );
                successCount++;
              } catch (e) {
                debugPrint("Error adding $phone: $e");
                failCount++;
              }
            } else {
              failCount++;
            }
          }
        }

        setState(() {
          _isLoading = false;
          _statusMessage =
              "Upload complete.\nSuccessfully added: $successCount\nFailed/Skipped: $failCount";
        });
      } else {
        setState(() {
          _statusMessage = "No file selected.";
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = "Error processing file: $e";
      });
    }
  }

  Future<void> _deleteUser(String docId, String role) async {
    try {
      String collectionName = (role == 'driver') ? 'drivers' : 'riders';
      await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(docId)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddUserDialog(String role) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isAdding = false;
        return StatefulBuilder(
          builder: (builderContext, setDialogState) {
            return AlertDialog(
              title: Text('Add New ${role == 'rider' ? 'Rider' : 'Driver'}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Full Name'),
                    ),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixText: '+91 ',
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    TextField(
                      controller: passwordController,
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isAdding ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isAdding
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          final phone =
                              '+91${phoneController.text.trim()}'; // Enforcing standard format, adjust if needed
                          final password = passwordController.text.trim();

                          if (name.isEmpty ||
                              phone.length < 10 ||
                              password.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please fill all fields correctly',
                                ),
                              ),
                            );
                            return;
                          }

                          setDialogState(() => isAdding = true);

                          try {
                            // Using the existing AuthService method
                            await AuthService().signUpWithPhone(
                              name,
                              phone,
                              password,
                              role,
                            );
                            if (builderContext.mounted) {
                              Navigator.pop(builderContext);
                              ScaffoldMessenger.of(builderContext).showSnackBar(
                                const SnackBar(
                                  content: Text('User added successfully!'),
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isAdding = false);
                            if (builderContext.mounted) {
                              ScaffoldMessenger.of(builderContext).showSnackBar(
                                SnackBar(
                                  content: Text('Error adding user: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  child: isAdding
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Add User'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildUserList(String role) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => _pickAndProcessCSV(role),
                icon: const Icon(Icons.upload_file),
                label: const Text("Upload CSV"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D62ED),
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddUserDialog(role),
                icon: const Icon(Icons.person_add),
                label: Text("Add ${role == 'rider' ? 'Rider' : 'Driver'}"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        if (_statusMessage != "Please select a CSV file to upload users." &&
            _statusMessage != "No file selected.")
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: _statusMessage.contains("Error")
                    ? Colors.red
                    : Colors.black87,
              ),
            ),
          ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(role == 'driver' ? 'drivers' : 'riders')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text("Error fetching data: ${snapshot.error}"),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text("No ${role}s found."));
              }

              final users = snapshot.data!.docs;

              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index].data() as Map<String, dynamic>;
                  final docId = users[index].id;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: role == 'rider'
                            ? Colors.blue.shade100
                            : Colors.orange.shade100,
                        child: Icon(
                          role == 'rider'
                              ? Icons.person
                              : Icons.electric_rickshaw,
                          color: Colors.black87,
                        ),
                      ),
                      title: Text(
                        user['name'] ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text("Phone: ${user['phone'] ?? 'N/A'}"),
                      isThreeLine: false,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Confirm Delete"),
                              content: Text(
                                "Are you sure you want to delete ${user['name']}?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _deleteUser(docId, role);
                                  },
                                  child: const Text(
                                    "Delete",
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Admin Panel"),
          backgroundColor: const Color(0xFF2D62ED),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.person), text: "Riders"),
              Tab(icon: Icon(Icons.drive_eta), text: "Drivers"),
            ],
          ),
        ),
        body: _isLoading
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(_statusMessage),
                  ],
                ),
              )
            : TabBarView(
                children: [_buildUserList('rider'), _buildUserList('driver')],
              ),
      ),
    );
  }
}
