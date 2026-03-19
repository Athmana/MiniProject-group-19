import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:gowayanad/services/auth_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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
        final String csvString = await file.readAsString();

        List<List<dynamic>> fields = [];
        final lines = csvString.split(RegExp(r'\r?\n'));
        for (var line in lines) {
          if (line.trim().isNotEmpty) {
            fields.add(line.split(',').map((e) => e.trim()).toList());
          }
        }

        if (fields.isEmpty || fields.length < 2) {
          setState(() {
            _isLoading = false;
            _statusMessage = "CSV is empty or missing data rows.";
          });
          return;
        }

        int successCount = 0;
        int failCount = 0;

        for (int i = 1; i < fields.length; i++) {
          final row = fields[i];
          if (row.length >= 3) {
            String name = row[0].toString().trim();
            String phone = row[1].toString().trim();
            String password = row[2].toString().trim();

            if (phone.isNotEmpty && password.isNotEmpty && name.isNotEmpty) {
              try {
                // Ensure number has prefix if it doesn't already
                String formattedPhone = phone;
                if (!phone.startsWith('+')) {
                  formattedPhone = '+91$phone';
                }

                await AuthService().signUpWithPhoneAsAdmin(
                  name,
                  formattedPhone,
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
          _statusMessage = "Upload complete.\nAdded: $successCount\nFailed: $failCount";
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

  Future<void> _downloadTemplate() async {
    try {
      List<List<dynamic>> rows = [
        ["Name", "Phone", "Password"],
        ["John Doe", "9876543210", "pass123"],
      ];
      String csvData = rows.map((row) => row.join(',')).join('\n');
      final directory = await getTemporaryDirectory();
      final path = "${directory.path}/user_template.csv";
      final file = File(path);
      await file.writeAsString(csvData);
      await Share.shareXFiles([XFile(path)], text: 'User Template');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  Future<void> _deleteUser(String docId, String role) async {
    try {
      String collectionName = (role == 'driver') ? 'drivers' : 'riders';
      await FirebaseFirestore.instance.collection(collectionName).doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _showAddUserDialog(String role) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        bool isAdding = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Add New ${role == 'rider' ? 'Rider' : 'Driver'}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: 'Phone', prefixText: '+91 '),
                    keyboardType: TextInputType.phone,
                  ),
                  TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
                ],
              ),
              actions: [
                TextButton(onPressed: isAdding ? null : () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: isAdding ? null : () async {
                    final name = nameController.text.trim();
                    final phone = phoneController.text.trim();
                    final password = passwordController.text.trim();

                    if (name.isEmpty || phone.isEmpty || password.isEmpty) return;
                    
                    setDialogState(() => isAdding = true);
                    try {
                      String formattedPhone = '+91$phone';
                      await AuthService().signUpWithPhoneAsAdmin(name, formattedPhone, password, role);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User added')));
                      }
                    } catch (e) {
                      setDialogState(() => isAdding = false);
                      String code = "unknown";
                      String message = e.toString();
                      if (e is FirebaseAuthException) {
                        code = e.code;
                        message = e.message ?? e.toString();
                      } else if (e is FirebaseException) {
                        code = e.code;
                        message = e.message ?? e.toString();
                      }
                      if (context.mounted) {
                        showDialog(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: const Text("Creation Failed"),
                            content: Text("Error Code: $code\n\n$message"),
                            actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("OK"))],
                          ),
                        );
                      }
                    }
                  },
                  child: isAdding ? const CircularProgressIndicator(strokeWidth: 2) : const Text('Add'),
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
              IconButton(onPressed: _downloadTemplate, icon: const Icon(Icons.download), tooltip: "Template"),
              ElevatedButton.icon(
                onPressed: () => _pickAndProcessCSV(role),
                icon: const Icon(Icons.upload_file),
                label: const Text("CSV"),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddUserDialog(role),
                icon: const Icon(Icons.person_add),
                label: const Text("Add"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection(role == 'driver' ? 'drivers' : 'riders').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final users = snapshot.data!.docs;
              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index].data() as Map<String, dynamic>;
                  return ListTile(
                    title: Text(user['name'] ?? 'No Name'),
                    subtitle: Text(user['phone'] ?? 'No Phone'),
                    trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteUser(users[index].id, role)),
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
          bottom: const TabBar(tabs: [Tab(text: "Riders"), Tab(text: "Drivers")]),
        ),
        body: _isLoading 
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const CircularProgressIndicator(), Text(_statusMessage)]))
          : TabBarView(children: [_buildUserList('rider'), _buildUserList('driver')]),
      ),
    );
  }
}
