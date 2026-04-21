import 'package:flutter/material.dart';
import 'child_card.dart';

class Parent_widget extends StatefulWidget {
  const Parent_widget({super.key});

  @override
  State<Parent_widget> createState() => Parent_widgetState();
}

class Parent_widgetState extends State<Parent_widget> {
  final _formKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> get childrenData => children;
  List<Map<String, dynamic>> children = [
    {
      "id":         UniqueKey().toString(),
      "name":       "",
      "gender":     null,
      "level":      null,
      "grade":      null,
      "speciality": null,
      "subjects":   <String>[],
    }
  ];

  bool validate() {
    bool chipErrors = false;

    final updated = children.map((child) {
      Map<String, dynamic> c = {...child};
      if (c['gender'] == null) {
        c['genderError'] = true;
        chipErrors = true;
      }
      if (c['level'] != null && c['grade'] == null) {
        c['gradeError'] = true;
        chipErrors = true;
      }
      if (c['level'] == 'High' && c['grade'] != null && c['speciality'] == null) {
        c['specialityError'] = true;
        chipErrors = true;
      }
      return c;
    }).toList();

    setState(() => children = updated);

    final formValid = _formKey.currentState!.validate();
    return formValid && !chipErrors;
  }

  void addChild() {
    setState(() {
      children.add({
        "id":         UniqueKey().toString(),
        "name":       "",
        "gender":     null,
        "level":      null,
        "grade":      null,
        "speciality": null,
        "subjects":   <String>[],
      });
    });
  }

  void removeChild(int index) {
    setState(() => children.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(left: 20),
            child: const Text(
              "Children Information",
              style: TextStyle(
                letterSpacing: -0.25,
                fontFamily: "Inter",
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: Color(0xff1f2937),
                height: 30 / 18,
              ),
            ),
          ),
          ...List.generate(
            children.length,
            (index) => ChildCard(
              key: ValueKey(children[index]['id']),
              index: index,
              data: children[index],
              onRemove: children.length > 1 ? () => removeChild(index) : null,
              onChanged: (updatedData) {
                setState(() => children[index] = updatedData);
              },
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: addChild,
              icon: const Icon(
                Icons.add_circle_outline,
                size: 20,
                color: Color(0xFF000080),
              ),
              label: const Text(
                "Add Another Child",
                style: TextStyle(
                  fontFamily: "Inter",
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF000080),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}