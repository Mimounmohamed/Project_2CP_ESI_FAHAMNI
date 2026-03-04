import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fahamni/widgets/widgets.dart';



class IpersonalInfo extends StatelessWidget {
  const IpersonalInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff9f9f9),
      appBar: AppBar(
        backgroundColor: const Color(0xfff9f9f9),
        leading: Container(
          child: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            iconSize: 24,
            icon: const Icon(Icons.arrow_back_ios_new_outlined),
          ),
        ),
        title: const Text(
          "User Registration",
          style: TextStyle(
            fontFamily: "Inter",
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xff0f172a),
            height: 23 / 18,
          ),
        ),
        centerTitle: true,
      ),


      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(8,0,0,8),
          child: Column(


            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Bare(1,0),
              Container(
                margin: const EdgeInsets.only(left: 20),
                child: const Text(
                "Personal Information",
                style: TextStyle(
                  letterSpacing: -0.25,
                  fontFamily: "Inter",
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff1f2937),
                  height: 30 / 18,
                ),
              ),),


              Container(
                margin: const EdgeInsets.only(left: 34),
                child:
              const Text(
                "First Name",
                style: TextStyle(
                  fontFamily: "Inter",
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff1f2937),
                  height: 14 / 18,
                ),
              ),),


              const SizedBox(height: 8),

              Container(
                margin: const EdgeInsets.only(left: 24, right: 24),
                child: 
              TextFormField(
                decoration: InputDecoration(
                  hintText: 'Mahieddine',
                  hintStyle: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 17,
                    fontFamily: 'Lexend',
                  ),
                  prefixIcon: const Icon(
                    Icons.person_outline,
                    size: 22,
                    color: Color(0xFF94A3B8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 2),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFFFFFFF),
                ),
              ),),


              const SizedBox(height: 8),

              Container(
                margin: const EdgeInsets.only(left: 29, right: 24),
                child:
              const Text(
                "Last Name",
                style: TextStyle(
                  fontFamily: "Inter",
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff1f2937),
                  height: 14 / 18,
                ),
              ),),

              const SizedBox(height: 8),

              Container(
                margin: const EdgeInsets.only(left: 24, right: 24),
                child:
              TextFormField(
                decoration: InputDecoration(
                  hintText: 'Mimoun',
                  hintStyle: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 17,
                    fontFamily: 'Lexend',
                  ),
                  prefixIcon: const Icon(
                    Icons.person_outline,
                    size: 22,
                    color: Color(0xFF94A3B8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 2),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFFFFFFF),
                ),
              ),),

              

              


              const SizedBox(height: 8),
             
              Container(
                margin: const EdgeInsets.only(left: 24, right: 24),
                child: const ROW1(), ),
                const SizedBox(height: 8),
              Container(
                margin: const EdgeInsets.only(left: 24, right: 24),
                child: const ROW2(), ),
                const SizedBox(height: 8),
                Container(
                margin: const EdgeInsets.only(left: 34),
                child:
              const Text(
                "Email Address",
                style: TextStyle(
                  fontFamily: "Inter",
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff1f2937),
                  height: 14 / 18,
                ),
              ),),
                const SizedBox(height: 8),
                Container(
                margin: const EdgeInsets.only(left: 24, right: 24),
                child: 
              TextFormField(
                decoration: InputDecoration(
                  hintText: 'name@example.com',
                  hintStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                    fontSize: 17,
                    fontFamily: 'Lexend',
                  ),
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    size: 22,
                    color: Color(0xFF94A3B8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 2),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFFFFFFF),
                ),
              ),),
                const SizedBox(height: 8),
                Container(
                margin: const EdgeInsets.only(left: 34),
                child:
              const Text(
                "Phone Number",
                style: TextStyle(
                  fontFamily: "Inter",
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff1f2937),
                  height: 14 / 18,
                ),
              ),),
                const SizedBox(height: 8),
                Container(
                margin: const EdgeInsets.only(left: 24, right: 24),
                child: 
              TextFormField(
                decoration: InputDecoration(
                  hintText: 'Ex:0555555555',
                  hintStyle: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 17,
                    fontFamily: 'Lexend',
                  ),
                  prefixIcon: const Icon(
                    Icons.phone_outlined,
                    size: 22,
                    color: Color(0xFF94A3B8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 2),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFFFFFFF),
                ),
              ),),
                const SizedBox(height: 8),
                Container(
                margin: const EdgeInsets.only(left: 34),
                child:
              const Text(
                "Password",
                style: TextStyle(
                  fontFamily: "Inter",
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff1f2937),
                  height: 14 / 18,
                ),
              ),),
                const SizedBox(height: 8),
                 Passwrd(),
                 const SizedBox(height: 24),
  
                 Container(
                  alignment: Alignment.center,
  margin: const EdgeInsets.only(left: 0),
  
  child: ElevatedButton(
    onPressed: () {
      // Handle button press
    },
    style: ElevatedButton.styleFrom(
      shadowColor: const Color(0xFF000080),
      elevation: 6,
      backgroundColor: const Color(0xFF000080),
      padding: const EdgeInsets.symmetric(horizontal: 150, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    child: const Text(
    
      'NEXT',
      style: TextStyle(
        color: Colors.white,
        fontSize: 17,
        fontWeight: FontWeight.w700,
        fontFamily: 'Inter',
      ),
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


class ROW1 extends StatefulWidget {
  const ROW1({super.key});

  @override
  State<ROW1> createState() => _ROW1State();
}

class _ROW1State extends State<ROW1> {
  String? selectedGender;
   DateTime _selectedDate = DateTime(2000, 1, 1);
final TextEditingController _dobController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Gender Dropdown (left side)
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(5,0,0,0),
                child:
              const Text(
                'Gender',
                style: TextStyle(
                  fontFamily: "Nunito",
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff1f2937),
                  height: 14 / 18,
                ),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedGender,
               
        borderRadius: BorderRadius.circular(16), 
        dropdownColor: Colors.white,           
        elevation: 8,                          
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8)), // Use 'value' instead of 'initialValue'
                hint: const Text(
                  'Select Gender',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontFamily: 'Lexend'),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Male',
                    child: Text('Male',
                    style: TextStyle(
                      color: Color(0xFF1f2937),
                    fontSize: 17,
                    fontFamily: 'Lexend',
                    ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Female',
                    child: Text('Female',
                    style: TextStyle(
                     color: Color(0xFF1f2937),
                    fontSize: 17,
                    fontFamily: 'Lexend',
                    ),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedGender = value;
                  });
                },
                decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16), // Space between columns
        Expanded(
  flex: 1,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
        child: const Text(
          'Date of Birth',
          style: TextStyle(
            fontFamily: "Nunito",
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xff1f2937),
            height: 14 / 18,
          ),
        ),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: _dobController,
        readOnly: true, // prevents keyboard from showing
        onTap: () => _showCupertinoDatePicker(context),
        decoration: InputDecoration(
          hintText: 'Select date',
          suffixIcon: const Icon(Icons.calendar_today, size: 18, color: Color(0xFF94A3B8)),
          hintStyle: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 14,
            fontFamily: 'Lexend',
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 2),
          ),
          filled: true,
          fillColor: const Color(0xFFFFFFFF),
        ),
      ),
    ],
  ),
),


      ],
    );
  }


void _showCupertinoDatePicker(BuildContext context) {
  DateTime tempDate = _selectedDate;

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) {
      return SizedBox(
        height: 320,
        child: Column(
          children: [
            // Header row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                  ),
                  const Text(
                    'Date of Birth',
                    style: TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Nunito'),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedDate = tempDate;
                        _dobController.text =
                            '${tempDate.day.toString().padLeft(2, '0')}/'
                            '${tempDate.month.toString().padLeft(2, '0')}/'
                            '${tempDate.year}';
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('Done', style: TextStyle(color: Color(0xFF000080))),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // The spinner
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _selectedDate,
                minimumDate: DateTime(1900),
                maximumDate: DateTime.now(),
                onDateTimeChanged: (date) {
                  tempDate = date;
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}}

class ROW2 extends StatefulWidget {
  const ROW2({super.key});

  @override
  State<ROW2> createState() => _ROW2State();
}

class _ROW2State extends State<ROW2> {
  String? selectedCity;
  final List<String> algerianCities = [
    'Adrar', 'Aïn Defla', 'Aïn Témouchent', 'Algiers', 'Annaba',
    'Batna', 'Béchar', 'Béjaïa', 'Béni Abbès', 'Biskra',
    'Blida', 'Bordj Badji Mokhtar', 'Bordj Bou Arréridj', 'Bouira', 'Boumerdès',
    'Chlef', 'Constantine',
    'Djelfa', 'Djanet',
    'El Bayadh', 'El Meniaa', 'El Oued', 'El Tarf',
    'Ghardaïa', 'Guelma',
    'Illizi', 'In Guezzam', 'In Salah',
    'Jijel',
    'Khenchela',
    'Laghouat',
    'Mascara', 'Médéa', 'M\'Ghair', 'Mila', 'Mostaganem', 'M\'Sila',
    'Naâma',
    'Oran', 'Ouargla', 'Ouled Djellal', 'Oum El Bouaghi',
    'Relizane',
    'Saïda', 'Sétif', 'Sidi Bel Abbès', 'Skikda', 'Souk Ahras',
    'Tamanrasset', 'Tébessa', 'Tiaret', 'Timimoun', 'Tindouf',
    'Tipaza', 'Tissemsilt', 'Tizi Ouzou', 'Tlemcen', 'Touggourt',
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // City Dropdown (left side)
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                child: const Text(
                  'City of residence',
                  style: TextStyle(
                    fontFamily: "Nunito",
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff1f2937),
                    height: 14 / 18,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedCity,
                isExpanded: true, 
                borderRadius: BorderRadius.circular(16),
                dropdownColor: Colors.white,
                elevation: 8,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8)),
                hint: const Text(
                  'Select City',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontFamily: 'Lexend'),
                ),
                items: algerianCities
                    .map((city) => DropdownMenuItem(
                          value: city,
                          child: Text(
                            city,
                            style: const TextStyle(
                              color: Color(0xFF1f2937),
                              fontSize: 14,
                              fontFamily: 'Lexend',
                            ),
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCity = value;
                  });
                },
                decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 16), // same as ROW1

        // Postal Code (right side)
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                child: const Text(
                  'Postal code',
                  style: TextStyle(
                    fontFamily: "Nunito",
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff1f2937),
                    height: 14 / 18,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Ex: 1600',
                  hintStyle: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 14,
                    fontFamily: 'Lexend',
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 2),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFFFFFFF),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

  class Passwrd extends StatefulWidget {
  const Passwrd({super.key});

  @override
  State<Passwrd> createState() => _PasswrdState();
}

class _PasswrdState extends State<Passwrd> {
      bool _obscurePassword = true; 
  Widget build(BuildContext context) {
    return Container(
  margin: const EdgeInsets.only(left: 24, right: 24),
  child: TextFormField(
    obscureText: _obscurePassword, 
    decoration: InputDecoration(
      hintText: 'Enter password',
      hintStyle: const TextStyle(
        color: Color(0xFF94A3B8),
        fontSize: 14,
        fontFamily: 'Lexend',
      ),
      prefixIcon: const Icon(
        Icons.lock_outline,
        size: 20,
        color: Color(0xFF94A3B8),
      ),
      suffixIcon: IconButton(  
        icon: Icon(
          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          size: 20,
          color: const Color(0xFF94A3B8),
        ),
        onPressed: () {
          setState(() {
            _obscurePassword = !_obscurePassword;
          });
        },
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 2),
      ),
      filled: true,
      fillColor: const Color(0xFFFFFFFF),
    ),
  ),
);
     
  }
}
