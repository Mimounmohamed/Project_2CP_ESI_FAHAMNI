import 'package:flutter/material.dart';
//import 'iPersonal_info.dart';
import 'Student_info.dart'; // Import your widgets file

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: studentinfo(), // This calls your widget from the other file
  ));
}