import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:gowayanad/services/auth_services.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  bool _isLoading = false;
  String _statusMessage = "Please select a CSV file to upload users.";

  Future<void> _pickAndProcessCSV() async {
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

        // We assume Row 0 is the header: Name, Phone, Password, Role
        int successCount = 0;
        int failCount = 0;

        for (int i = 1; i < fields.length; i++) {
          final row = fields[i];

          if (row.length >= 4) {
            String name = row[0].toString().trim();
            String phone = row[1].toString().trim();
            String password = row[2].toString().trim();
            String role = row[3]
                .toString()
                .trim()
                .toLowerCase(); // 'rider' or 'driver'

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
        // User canceled the picker
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Panel"),
        backgroundColor: const Color(0xFF2D62ED),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.admin_panel_settings,
                size: 100,
                color: Color(0xFF2D62ED),
              ),
              const SizedBox(height: 24),
              const Text(
                "Bulk User Upload",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                "Upload a CSV file with the following columns:\nName, Phone, Password, Role (rider/driver)",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),

              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton.icon(
                  onPressed: _pickAndProcessCSV,
                  icon: const Icon(Icons.upload_file),
                  label: const Text("Select CSV File"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D62ED),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

              const SizedBox(height: 32),
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: _statusMessage.contains("Error")
                      ? Colors.red
                      : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
