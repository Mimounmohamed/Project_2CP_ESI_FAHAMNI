import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dotted_border/dotted_border.dart';

class FileUploadWidget extends StatefulWidget {
  const FileUploadWidget({super.key});

  @override
  State<FileUploadWidget> createState() => FileUploadWidgetState();
}

class FileUploadWidgetState extends State<FileUploadWidget> {
  List<String> uploadedFiles = [];
  bool _showError = false;

  // Called from TeacherDetailsWidget
  bool validate() {
    if (uploadedFiles.isEmpty) {
      setState(() => _showError = true);
      return false;
    }
    return true;
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null) {
      setState(() {
        uploadedFiles.addAll(result.files.map((f) => f.name));
        _showError = false; // clear error once file is added
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(left: 24, right: 24),
          child: GestureDetector(
            onTap: _pickFile,
            child: DottedBorder(
              color: _showError ? Colors.red : const Color(0xFFE0E0E0),
              strokeWidth: 1.5,
              dashPattern: const [6, 4],
              borderType: BorderType.RRect,
              radius: const Radius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                color: Colors.white,
                child: const Column(
                  children: [
                    Icon(Icons.upload_outlined, color: Color(0xFF1A1F5E), size: 28),
                    SizedBox(height: 6),
                    Text(
                      "Tap to upload",
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontFamily: "Inter",
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Red error message
        if (_showError)
          Padding(
            padding: const EdgeInsets.only(left: 28, top: 6),
            child: Row(
              children: const [
                Icon(Icons.error_outline, color: Colors.red, size: 14),
                SizedBox(width: 4),
                Text(
                  'Please upload at least one certification',
                  style: TextStyle(color: Colors.red, fontSize: 12, fontFamily: 'Inter'),
                ),
              ],
            ),
          ),

        if (uploadedFiles.isNotEmpty) ...[
          const SizedBox(height: 10),
          ...uploadedFiles.map(
            (name) => Container(
              margin: const EdgeInsets.only(left: 24, right: 24),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.insert_drive_file_outlined, size: 16, color: Color(0xFF000080)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(fontSize: 13, color: Color(0xff1f2937)),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          uploadedFiles.remove(name);
                          if (uploadedFiles.isEmpty) _showError = true;
                        });
                      },
                      child: const Icon(Icons.close, size: 16, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}