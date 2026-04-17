import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fahamni/widgets/widgets.dart';
import 'package:fahamni/User_status/User_info.dart';
import 'package:fahamni/models/user_model.dart';
import 'package:fahamni/Services/auth_.service.dart';
class IpersonalInfo extends StatefulWidget {
  const IpersonalInfo({super.key});

  @override
  State<IpersonalInfo> createState() => _IpersonalInfoState();
}

class _IpersonalInfoState extends State<IpersonalInfo> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController  = TextEditingController();
  
  bool    _isLoading    = false;
  String? _errorMessage;
  final _authService = AuthService();


  Gender?   _selectedGender;
  DateTime? _selectedBirthday;
  String?   _selectedCity;

  bool _genderError   = false;
  bool _birthdayError = false;
  bool _cityError     = false;
  
  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xfff9f9f9),
      bottomNavigationBar: Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    if (_errorMessage != null)
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Text(
            _errorMessage!,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, keyboardInset > 0 ? 12 : 32),
      child: ElevatedButton(
        onPressed: _isLoading ? null : () async {
          final formValid = _formKey.currentState!.validate();
          setState(() {
            _genderError   = _selectedGender   == null;
            _birthdayError = _selectedBirthday == null;
            _cityError     = _selectedCity     == null;
            _errorMessage  = null; // clear previous error
          });
          if (!formValid || _genderError || _birthdayError || _cityError) return;

          setState(() => _isLoading = true);

          try {
            await AuthService().checkIfUserExists(
              email: _emailController.text.trim(),
              phone: toE164(_phoneController.text.trim(), '213'),
            );
            if (!mounted) return;

            final Map<String, dynamic> data = {
              'firstName' : _firstNameController.text.trim(),
              'lastName'  : _lastNameController.text.trim(),
              'email'     : _emailController.text.trim(),
              'phone'     : toE164(_phoneController.text.trim(), '213'),
              'password'  : _passwordController.text.trim(),
              'gender'    : _selectedGender,
              'birthday'  : _selectedBirthday,
              'location'  : _selectedCity,
            };

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => studentinfo(data: data),
              ),
            );
          } catch (e) {
            setState(() => _errorMessage = e.toString());
          } finally {
            if (mounted) setState(() => _isLoading = false);
          }
        },
        style: ElevatedButton.styleFrom(
          shadowColor: const Color(0xFF000080),
          elevation: 6,
          backgroundColor: const Color(0xFF000080),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
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
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xfff9f9f9),
        surfaceTintColor: const Color(0xfff9f9f9),
        shadowColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          iconSize: 24,
          icon: const Icon(Icons.arrow_back_ios_new_outlined),
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
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(8, 0, 8, 8 + keyboardInset),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Bare(1, 0),
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
                  ),
                ),

                // First Name
                Container(
                  margin: const EdgeInsets.only(left: 34),
                  child: const Text(
                    "First Name",
                    style: TextStyle(
                      fontFamily: "Inter",
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff1f2937),
                      height: 14 / 18,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  margin: const EdgeInsets.only(left: 24, right: 24),
                  child: TextFormField(
                    controller: _firstNameController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'First name is required';
                      }
                      return null;
                    },
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
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red, width: 1.5),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red, width: 1.5),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFFFFFFF),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Last Name
                Container(
                  margin: const EdgeInsets.only(left: 29, right: 24),
                  child: const Text(
                    "Last Name",
                    style: TextStyle(
                      fontFamily: "Inter",
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff1f2937),
                      height: 14 / 18,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  margin: const EdgeInsets.only(left: 24, right: 24),
                  child: TextFormField(
                    controller: _lastNameController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Last name is required';
                      }
                      return null;
                    },
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
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red, width: 1.5),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red, width: 1.5),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFFFFFFF),
                    ),
                  ),
                ),

                const SizedBox(height: 8),
                Container(
                  margin: const EdgeInsets.only(left: 24, right: 24),
                  child: ROW1(formKey: _formKey,onGenderChanged: (gender) => setState(() {
                    _selectedGender = gender;
                    _genderError = false;
                  }),
                  onDateChanged: (date) => setState(() {
                    _selectedBirthday = date;
                    _birthdayError = false;
                  }),
                  showGenderError: _genderError,
                  showBirthdayError: _birthdayError,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  margin: const EdgeInsets.only(left: 24, right: 24),
                  child: ROW2(onCityChanged: (city) => setState(() {
                    _selectedCity = city;
                    _cityError = false;
                  }), showCityError: _cityError,),
                ),

                const SizedBox(height: 8),

                // Email
                Container(
                  margin: const EdgeInsets.only(left: 34),
                  child: const Text(
                    "Email Address",
                    style: TextStyle(
                      fontFamily: "Inter",
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff1f2937),
                      height: 14 / 18,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  margin: const EdgeInsets.only(left: 24, right: 24),
                  child: TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                     onChanged: (_) => setState(() => _errorMessage = null),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email is required';
                      }
                      if (!value.contains('@')) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
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
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red, width: 1.5),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red, width: 1.5),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFFFFFFF),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Phone
                Container(
                  margin: const EdgeInsets.only(left: 34),
                  child: const Text(
                    "Phone Number",
                    style: TextStyle(
                      fontFamily: "Inter",
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff1f2937),
                      height: 14 / 18,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  margin: const EdgeInsets.only(left: 24, right: 24),
                  child: TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                     onChanged: (_) => setState(() => _errorMessage = null),
                    validator: (value) {
  if (value == null || value.isEmpty) {
    return 'Phone number is required';
  }
  if (value.length != 10) {
    return 'Phone number must be 10 digits';
  }
  if (!value.startsWith('05') &&
      !value.startsWith('06') &&
      !value.startsWith('07')) {
    return 'Number must start with 05, 06, or 07';
  }
  return null;
},
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
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red, width: 1.5),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red, width: 1.5),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFFFFFFF),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Password
                Container(
                  margin: const EdgeInsets.only(left: 34),
                  child: const Text(
                    "Password",
                    style: TextStyle(
                      fontFamily: "Inter",
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff1f2937),
                      height: 14 / 18,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                 Passwrd(controller: _passwordController),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ROW1 extends StatefulWidget {
  final GlobalKey<FormState>? formKey;
  final Function(Gender)   onGenderChanged;
  final Function(DateTime) onDateChanged;
  final bool showGenderError;
  final bool showBirthdayError;
  const ROW1({super.key, this.formKey, required this.onGenderChanged, required this.onDateChanged, this.showGenderError = false, this.showBirthdayError = false});

  @override
  State<ROW1> createState() => _ROW1State();
}

class _ROW1State extends State<ROW1> {
  String? selectedGender;
  DateTime _selectedDate = DateTime(2000, 1, 1);
  final TextEditingController _dobController = TextEditingController();
@override
Widget build(BuildContext context) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final isNarrow = constraints.maxWidth < 320;
      
      final genderField = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
            child: const Text(
              'Gender',
              style: TextStyle(
                fontFamily: "Nunito", fontSize: 15,
                fontWeight: FontWeight.w700, color: Color(0xff1f2937),
                height: 14 / 18,
              ),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: selectedGender,
            borderRadius: BorderRadius.circular(16),
            dropdownColor: Colors.white,
            elevation: 8,
            isExpanded: true, 
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8)),
            hint: const Text(
              'Select',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontFamily: 'Lexend'),
            ),
            validator: (value) => value == null ? 'Required' : null,
            items: const [
              DropdownMenuItem(value: 'male',
                child: Text('Male', style: TextStyle(color: Color(0xFF1f2937), fontSize: 15, fontFamily: 'Lexend'))),
              DropdownMenuItem(value: 'female',
                child: Text('Female', style: TextStyle(color: Color(0xFF1f2937), fontSize: 15, fontFamily: 'Lexend'))),
            ],
            onChanged: (value) {
              setState(() => selectedGender = value);
              if (value != null) widget.onGenderChanged(Gender.values.byName(value));
            },
            decoration: InputDecoration(
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: widget.showGenderError ? Colors.red : const Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 2)),
              errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 1.5)),
              focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 1.5)),
              filled: true, fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
          ),
        ],
      );

      final dobField = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
            child: const Text(
              'Date of Birth',
              style: TextStyle(
                fontFamily: "Nunito", fontSize: 15,
                fontWeight: FontWeight.w700, color: Color(0xff1f2937),
                height: 14 / 18,
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _dobController,
            readOnly: true,
            onTap: () => _showCupertinoDatePicker(context),
            validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
            decoration: InputDecoration(
              hintText: 'Select date',
              suffixIcon: const Icon(Icons.calendar_today, size: 18, color: Color(0xFF94A3B8)),
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontFamily: 'Lexend'),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: widget.showBirthdayError ? Colors.red : const Color(0xFFE0E0E0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 2)),
              errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 1.5)),
              focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 1.5)),
              filled: true, fillColor: const Color(0xFFFFFFFF),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
          ),
        ],
      );

      if (isNarrow) {
        return Column(
          children: [
            genderField,
            const SizedBox(height: 12),
            dobField,
          ],
        );
      }

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: genderField),
          const SizedBox(width: 12),
          Expanded(child: dobField),
        ],
      );
    },
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
                        widget.onDateChanged(tempDate);
                        Navigator.pop(context);
                      },
                      child: const Text('Done', style: TextStyle(color: Color(0xFF000080))),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
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
  }
}


class ROW2 extends StatefulWidget {
  final Function(String) onCityChanged;
  final bool showCityError;
  const ROW2({super.key, required this.onCityChanged, this.showCityError = false});

  @override
  State<ROW2> createState() => _ROW2State();
}

class _ROW2State extends State<ROW2> {
  String? selectedCity;
  String? selectedCommune;

  final Map<String, List<String>> wilayaBaladiyat = {
  'Adrar': [
    'Adrar', 'Aougrout', 'Aoulef', 'Bouda', 'Fenoughil', 'In Zghmir', 
    'Ouled Ahmed Tammi', 'Reggane', 'Sali', 'Sebaa', 'Talmine', 'Tamest', 
    'Timiaouine', 'Tit', 'Tsabit', 'Zaouiet Kounta'
  ],
  'Aïn Defla': [
    'Aïn Defla', 'Aïn Benian', 'Aïn Bouyahia', 'Aïn Torki', 'Aïn Lechiakh',
    'Bathia', 'Belassaa Bouzegza', 'Boumedfaâ', 'Bourached', 'Djebala',
    'Djelida', 'El Amra', 'El Attaf', 'El Maine', 'Hassania', 'Khemis Miliana',
    'Mekhatria', 'Miliana', 'Oued Chorfa', 'Oued Djemaa', 'Rouina', 'Sidi Lakhdar',
    'Tachta Zegagha', 'Tarik Ibn Ziad', 'Tiberkanine', 'Zeddine'
  ],
  'Aïn Témouchent': [
    'Aïn Témouchent', 'Aïn Kihal', 'Aïn Tolba', 'Aoubellil', 'Beni Saf',
    'Bouzedjar', 'El Amria', 'El Emir Abdelkader', 'El Malah', 'Hammam Bou Hadjar',
    'Hassasna', 'Oued Berkeche', 'Oued Sabah', 'Sidi Ben Adda', 'Sidi Boumedienne',
    'Sidi Safi', 'Tamzoura', 'Terga', 'Tousmouline'
  ],
  'Algiers': [
    'Alger Centre', 'Sidi M’hamed', 'Bab El Oued', 'Bologhine', 'Casbah',
    'Oued Koriche', 'Bir Mourad Raïs', 'El Biar', 'Bouzareah', 'Ben Aknoun',
    'Dely Ibrahim', 'El Madania', 'Hussein Dey', 'Kouba', 'Mohammadia',
    'Bachdjerrah', 'Bourouba', 'El Harrach', 'Baraki', 'Oued Semar',
    'Dar El Beïda', 'Bab Ezzouar', 'Beni Messous', 'Aïn Bénian', 'Chéraga',
    'Draria', 'Douéra', 'Zéralda', 'Staoueli', 'Rouïba', 'Réghaïa',
    'Bordj El Bahri', 'Aïn Taya', 'Haraoua', 'Souidania', 'Mahelma',
    'Rahmania', 'Ouled Chebel', 'El Achour', 'Ouled Fayet'
  ],
  'Annaba': [
    'Annaba', 'Aïn Berda', 'Berrahal', 'Bounamoussa', 'Cheurfa', 'El Bouni',
    'El Hadjar', 'Seraïdi', 'Sidi Amar', 'Treat'
  ],
  'Batna': [
    'Batna', 'Aïn Djasser', 'Aïn Touta', 'Aïn Yagout', 'Arris', 'Barika',
    'Bitam', 'Boumia', 'Bouzina', 'Chemora', 'Chir', 'Djezzar', 'El Madher',
    'Fesdis', 'Foum Toub', 'Ghassira', 'Gueigoune', 'Ichmoul', 'Ichemoul',
    'Inoughissen', 'Kais', 'Larbâa', 'Lazrou', 'Maafa', 'Menaa', 'Merouana',
    'NGaous', 'Oued Chaaba', 'Ouled Fadel', 'Ouled Si Slimane', 'Ouled Ammar',
    'Ouled Aouf', 'Ouled Sellam', 'Ras El Aioun', 'Seggana', 'Seriana',
    'TKout', 'Tazoult', 'Taxlent', 'Teniet El Abed', 'Timgad', 'Toulmout',
    'Zanat El Beïda'
  ],
  'Béchar': [
    'Béchar', 'Abadla', 'Beni Ounif', 'Boukaïs', 'El Ouata', 'Igli',
    'Kenadsa', 'Lahmar', 'Meridja', 'Mogheul', 'Taghit', 'Timoudi'
  ],
  'Béjaïa': [
    'Béjaïa', 'Adekar', 'Aït R’zine', 'Aït Smaïl', 'Akbou', 'Allaghène',
    'Amalou', 'Aokas', 'Barbacha', 'Beni Djellil', 'Beni Ksila', 'Beni Maouche',
    'Bouhamza', 'Boukhelifa', 'Chellata', 'Darguina', 'Draâ El Caïd', 'Feraoun',
    'Ighram', 'Kendira', 'Kherrata', 'M’Cisna', 'Melbou', 'Oued Ghir', 'Ouzellaguen',
    'Seddouk', 'Semaoun', 'Sidi Aïch', 'Sidi Ayad', 'Souk El Thenine', 'Souk Oufella',
    'Taskriout', 'Tazmalt', 'Timezrit', 'Tichy', 'Tinabdher', 'Tizi N’Berber',
    'Toudja'
  ],
  'Béni Abbès': [
    'Béni Abbès', 'Béni Ikhlef', 'El Ouata', 'Igli', 'Kerzaz', 'Ouled Khoudir',
    'Tabelbala', 'Timoudi', 'Zaouia Kounta'
  ],
  'Biskra': [
    'Biskra', 'Aïn Naga', 'Aïn Zaatout', 'Bouchagroune', 'Branis', 'Chetma',
    'Djemorah', 'El Feidh', 'El Ghrous', 'El Hadjeb', 'El Kantara', 'El Mizaraa',
    'Foughala', 'Lichana', 'Lioua', 'M’Chouneche', 'Mekhadma', 'Ouled Djellal',
    'Oumache', 'Sidi Khaled', 'Sidi Okba', 'Tolga', 'Zeribet El Oued'
  ],
  'Blida': [
    'Blida', 'Aïn Romana', 'Beni Mered', 'Beni Tamou', 'Bouarfa', 'Boufarik',
    'Bougara', 'Bouinan', 'Chiffa', 'Chréa', 'Djebabra', 'El Affroun', 'Guérou',
    'Hammam Melouane', 'Meftah', 'Mouzaïa', 'Oued Alleug', 'Oued Djer', 'Sidi Moussa',
    'Sidi Naamane', 'Souhane'
  ],
  'Bordj Badji Mokhtar': [
    'Bordj Badji Mokhtar', 'Timiaouine'
  ],
  'Bordj Bou Arréridj': [
    'Bordj Bou Arréridj', 'Aïn Taghrout', 'Aïn Tesra', 'Belimour', 'Beni Ouar',
    'Bordj Ghedir', 'Bordj Zemmoura', 'Colla', 'Djaâfra', 'El Achir', 'El Eulma',
    'El Hamadia', 'El Main', 'El M’hir', 'Ghailassa', 'Haraza', 'Hasnaoua',
    'Khelil', 'Mansoura', 'Medjana', 'Ouled Brahem', 'Ouled Dahmane', 'Ouled Sidi Brahim',
    'Rabta', 'Ras El Oued', 'Sidi Embarek', 'Tafreg', 'Taglait', 'Teniet En Nasr',
    'Tixter', 'Yellas'
  ],
  'Bouira': [
    'Bouira', 'Aïn Bessam', 'Aïn El Hadjar', 'Aïn Laloui', 'Aïn Turk', 'Aït Laaziz',
    'Bechloul', 'Bir Ghbalou', 'Bordj Okhriss', 'Boukram', 'Chorfa', 'Dechmia',
    'Dirrah', 'Djebahia', 'El Asnam', 'El Hakimia', 'El Hachimia', 'El Kseur',
    'Haizer', 'Hanif', 'Kadiria', 'Lakhdaria', 'Maamora', 'M’Chedallah', 'Mezdour',
    'Oued El Berdi', 'Oued El Kébir', 'Raouraoua', 'Ridane', 'Saharij', 'Souk El Khemis',
    'Sour El Ghozlane', 'Taghzout', 'Zbarbar'
  ],
  'Boumerdès': [
    'Boumerdès', 'Afir', 'Ammal', 'Baghlia', 'Beni Amrane', 'Boudouaou', 'Boudouaou El Bahri',
    'Bouzegza Keddara', 'Chabet El Ameur', 'Corso', 'Dellys', 'Djinet', 'El Kharrouba',
    'Isser', 'Khemis El Khechna', 'Larbatache', 'Legata', 'Naciria', 'Ouled Aïssa',
    'Ouled Hedadj', 'Ouled Moussa', 'Si Mustapha', 'Sidi Daoud', 'Souk El Had', 'Taourga',
    'Thenia', 'Tidjelabine', 'Timezrit', 'Zemmouri'
  ],
  'Chlef': [
    'Chlef', 'Aïn Merane', 'Aïn Oussera', 'Beni Bouateb', 'Boukadir', 'Bouzeghaia',
    'Breira', 'Chettia', 'Dahra', 'El Hadjadj', 'El Karimia', 'El Marsa', 'Harchoun',
    'Labiod Medjadja', 'Moussadek', 'Oued Fodda', 'Oued Goussine', 'Oued Sly',
    'Ouled Abbes', 'Ouled Ben Abdelkader', 'Oum Drou', 'Sendjas', 'Sidi Abderrahmane',
    'Sidi Akkacha', 'Sobha', 'Tadjena', 'Talassa', 'Taougrite', 'Ténès', 'Zeboudja'
  ],
  'Constantine': [
    'Constantine', 'Aïn Abid', 'Aïn Smara', 'Beni Hamidane', 'Didouche Mourad',
    'El Khroub', 'Hamma Bouziane', 'Ibn Ziad', 'Oued Hamimime', 'Zighoud Youcef'
  ],
  'Djelfa': [
    'Djelfa', 'Aïn Chouhada', 'Aïn El Ibel', 'Aïn Fekka', 'Aïn Maabed', 'Aïn Oussera',
    'Amourah', 'Benhar', 'Beni Yagoub', 'Bouira Lahdab', 'Charef', 'Dar Chouikh',
    'Delduol', 'El Guedid', 'El Idrissia', 'El Khemis', 'Faïdh El Botma', 'Guernini',
    'Guettara', 'Had Sahary', 'Hassi Bahbah', 'M’Liliha', 'Messaâd', 'Moudjebara',
    'Oum Laadham', 'Sedd Rahal', 'Selmana', 'Sidi Baizid', 'Sidi Ladjel', 'Zaafrane',
    'Zaccar'
  ],
  'Djanet': [
    'Djanet', 'Bordj El Haouas'
  ],
  'El Bayadh': [
    'El Bayadh', 'Arbaouat', 'Boualem', 'Bougtoub', 'Boussemghoun', 'Brezina',
    'Cheguig', 'Chellala', 'El Abiodh Sidi Cheikh', 'El Bnoud', 'El Houita', 'Kef El Ahmar',
    'Krakda', 'Mékeri', 'Rogassa', 'Sidi Ameur', 'Sidi Slimane', 'Sidi Tifour', 'Stitten',
    'Tousmouline'
  ],
  'El Meniaa': [
    'El Meniaa', 'Hassi El Gara'
  ],
  'El Oued': [
    'El Oued', 'Bayadha', 'Debila', 'Djamaa', 'El M’Ghair', 'Guemar', 'Hassi Khalifa',
    'Kouinine', 'Magrane', 'Mih Ouensa', 'Nakhla', 'Oued El Alenda', 'Ourmas', 'Reguiba',
    'Robbah', 'Sidi Aoun', 'Taghzout', 'Tendla', 'Trifaoui'
  ],
  'El Tarf': [
    'El Tarf', 'Aïn El Assel', 'Aïn Kerma', 'Asfour', 'Ben M’Hidi', 'Berkhouche',
    'Bouhadjar', 'Bouteldja', 'Chebaita Mokhtar', 'Cheffia', 'Dréan', 'Echatt',
    'El Aioun', 'El Kala', 'Lac des Oiseaux', 'Oued Zitoun', 'Raml Souk', 'Souarekh',
    'Zerizer'
  ],
  'Ghardaïa': [
    'Ghardaïa', 'Bounoura', 'Dhayet Bendhahoua', 'El Atteuf', 'El Guerrara', 'Mansoura',
    'Metlili', 'Sebseb', 'Zelfana'
  ],
  'Guelma': [
    'Guelma', 'Aïn Ben Beida', 'Aïn Hessania', 'Aïn Larbi', 'Aïn Makhlouf', 'Aïn Reggada',
    'Aïn Sandel', 'Belkheir', 'Ben Djerrah', 'Beni Mezline', 'Bordj Sabat', 'Bouati Mahmoud',
    'Bouchegouf', 'Bouhamdane', 'Boumaâdja', 'Dahouara', 'Djeballah Khemissi', 'El Fedjoudj',
    'Guelaat Bou Sbaâ', 'Hammam Debagh', 'Hammam N’Bails', 'Héliopolis', 'Houari Boumediene',
    'Khezaras', 'Medjez Amar', 'Medjez Sfa', 'Nechemata', 'Oued Cheham', 'Oued Fragha',
    'Oued Zenati', 'Ras El Agba', 'Roknia', 'Salaoua Announa', 'Tamlouka'
  ],
  'Illizi': [
    'Illizi', 'Bordj Omar Driss', 'Debdeb', 'In Amenas', 'In Azzaoua', 'In Guezzam'
  ],
  'In Guezzam': [
    'In Guezzam', 'In Amguel'
  ],
  'In Salah': [
    'In Salah', 'Foggaret Ezzoua'
  ],
  'Jijel': [
    'Jijel', 'Boudriaa Ben Yadjis', 'Bouragba', 'Boussif Ouled Askeur', 'Chekfa',
    'Djemaa Beni Habibi', 'Djimla', 'El Ancer', 'El Aouana', 'El Kennar Nouchfi',
    'Emir Abdelkader', 'Erraguene', 'Ghebala', 'Kemir Oued Adjoul', 'Kheïri Oued Adjoul',
    'Ouled Amar', 'Ouled Rabah', 'Ouled Yahia Khedrouche', 'Selma Benziada', 'Sidi Abdelaziz',
    'Sidi Maarouf', 'Taher', 'Texenna', 'Ziama Mansouriah'
  ],
  'Khenchela': [
    'Khenchela', 'Aïn Touila', 'Babar', 'Baghai', 'Bouhmama', 'Chechar', 'Cheria',
    'Djellal', 'El Hamma', 'El Mahmal', 'Ensigha', 'Kais', 'Khirane', 'M’Sara',
    'MToussa', 'Ouled Rechache', 'Remila', 'Tamza', 'Yabous'
  ],
  'Laghouat': [
    'Laghouat', 'Aïn Madhi', 'Aïn Sidi Ali', 'Beidha', 'Bennasser Benchohra', 'Brida',
    'El Assafia', 'El Ghicha', 'Gueltat Sidi Saâd', 'Hadj Mechri', 'Hassi Delaa',
    'Hassi R’Mel', 'Kheneg', 'Ksar El Hirane', 'M’Kham', 'Oued Morra', 'Oued M’Zi',
    'Sebgag', 'Sidi Bouzid', 'Sidi Makhlouf', 'Taouiala', 'Tadjemout', 'Tadjrouna',
    'Tayebet', 'Tighremet', 'Touila'
  ],
  'Mascara': [
    'Mascara', 'Aïn Fares', 'Aïn Fekan', 'Aïn Ferah', 'Aïn Frass', 'Alaimia',
    'Benaïa', 'Bou Hanifia', 'Bou Henni', 'Chorfa', 'El Bordj', 'El Gaada',
    'El Guettana', 'El Hachem', 'El Keurt', 'El Mamounia', 'Ghriss', 'Hachem',
    'Khalouia', 'Macta', 'Mamounia', 'Matemore', 'Mocta Douz', 'Mohammadia',
    'Nesmoth', 'Oggaz', 'Oued El Abtal', 'Oued Taria', 'Ras El Aïn Amirouche',
    'Sedjerara', 'Sehailia', 'Sidi Abdeldjebar', 'Sidi Kada', 'Sidi Boussaid',
    'Sig', 'Teghennif', 'Tizi', 'Zahana', 'Zelmata'
  ],
  'Médéa': [
    'Médéa', 'Aïn Boucif', 'Aïn Ouksir', 'Aïn Benian', 'Aïn Bouziane', 'Aïn El Hadjar',
    'Aïn El Kerma', 'Aïn Torki', 'Aziz', 'Baata', 'Ben Chicao', 'Belaas', 'Beni Slimane',
    'Berrouaghia', 'Bir Ben Laabed', 'Boghar', 'Bou Aiche', 'Bouaichoune', 'Bouchrahil',
    'Boughezoul', 'Bouskene', 'Chellalet El Adhaoura', 'Cheniguel', 'Derrag', 'Djouab',
    'Draa Essamar', 'El Azizia', 'El Guelb El Kebir', 'El Hamdania', 'El Hassania',
    'El Omaria', 'Ferme', 'Hannacha', 'Ksar El Boukhari', 'Meghraoua', 'Mellab', 'Mihoub',
    'Ouled Antar', 'Ouled Brahim', 'Ouled Deide', 'Ouled Hellal', 'Ouled Maaref',
    'Ouled Ziane', 'Ouzera', 'Rebahia', 'Saneg', 'Sedraya', 'Seghouane', 'Si Mahdjoub',
    'Sidi Damed', 'Sidi Naamane', 'Sidi Rabiâ', 'Sidi Zahar', 'Sidi Ziane', 'Souagui',
    'Tablat', 'Tafraout', 'Tamesguida', 'Tizi Mahdi', 'Tletat Ed Douair', 'Zoubiria'
  ],
  'M’Ghair': [
    'M’Ghair', 'Djamaa', 'Oum Touyour', 'Sidi Amrane'
  ],
  'Mila': [
    'Mila', 'Aïn Beida', 'Aïn El Kebira', 'Aïn Mellouk', 'Aïn Tine', 'Aïn El Khercha',
    'Amira Arrès', 'Benyahia Abderrahmane', 'Bouhatem', 'Chelghoum Laïd', 'Chigara',
    'Derradji Bousselah', 'El Mechira', 'Elayadi Barbès', 'Ferdjioua', 'Grarem Gouga',
    'Hamala', 'M’chira', 'Oued Athmania', 'Oued Endja', 'Oued Seguen', 'Rouached',
    'Sidi Khelifa', 'Sidi Mérouane', 'Tadjenanet', 'Tassadane Haddada', 'Teleghma',
    'Terrai Bainen', 'Tiberguent', 'Yahia Beni Guecha', 'Zerzara'
  ],
  'Mostaganem': [
    'Mostaganem', 'Aïn Boudinar', 'Aïn Nouïssy', 'Aïn Sidi Cherif', 'Aïn Tedles',
    'Belaâssel', 'Bouguirat', 'El Achour', 'El Hassiane', 'Fornaka', 'Hadjadj',
    'Hassi Mameche', 'Khayr Eddine', 'Kheïr Eddine', 'Mansourah', 'Mazagran',
    'Mesra', 'Nekmaria', 'Oued El Kheir', 'Ouled Boughalem', 'Ouled Maallah',
    'Safsaf', 'Sayada', 'Sidi Ali', 'Sidi Belattar', 'Sidi Lakhdar', 'Sirat',
    'Souaflia', 'Stidia', 'Tazgait', 'Touahria'
  ],
  'M’Sila': [
    'M’Sila', 'Aïn El Hadjel', 'Aïn El Melh', 'Aïn Errich', 'Aïn Fares', 'Aïn Khadra',
    'Belaiba', 'Ben Srour', 'Beni Ilmane', 'Benzouh', 'Bir Foda', 'Bou Saâda',
    'Bouti Sayeh', 'Chellal', 'Dehahna', 'Djebel Messaâd', 'El Hamel', 'El Houamed',
    'El M’Chir', 'El Ouldja', 'Hammam Dhalaâ', 'Khettouti Sed El Djir', 'Maâdid',
    'Magra', 'M’Cif', 'Mohammed Boudiaf', 'Ouanougha', 'Oued Chair', 'Ouled Addi Guebala',
    'Ouled Atia', 'Ouled Derradj', 'Ouled Madhi', 'Ouled Mansour', 'Ouled Sidi Brahim',
    'Oultem', 'Ras El Ma', 'Sidi Aïssa', 'Sidi Hadjeres', 'Sidi M’Hamed', 'Slim',
    'Souamaa', 'Tamsa', 'Tarmount', 'Zarzour'
  ],
  'Naâma': [
    'Naâma', 'Aïn Ben Khelil', 'Aïn Sefra', 'Asla', 'Djeniane Bourzeg', 'El Biod',
    'Kasdir', 'Mécheria', 'Moghrar', 'Tiout'
  ],
  'Oran': [
    'Oran', 'Aïn El Bia', 'Aïn El Kerma', 'Aïn El Turk', 'Arzew', 'Ben Freha',
    'Benyamin', 'Birkhadem', 'Boufatis', 'Bouznika', 'El Ançor', 'El Kerma',
    'El Hassi', 'Es Senia', 'Gdyel', 'Hassi Ben Okba', 'Hassi Bounif', 'Hassi Mefsoukh',
    'Marsat El Hadjadj', 'Mers El Kébir', 'Misserghin', 'Oued Tlelat', 'Sidi Ben Yebka',
    'Sidi Chami', 'Tafraoui'
  ],
  'Ouargla': [
    'Ouargla', 'Aïn Beïda', 'Balidat Ameur', 'Benaceur', 'El Allia', 'El Borma',
    'El Hadjira', 'Hassi Ben Abdellah', 'Hassi Messaoud', 'Megarine', 'NGoussa',
    'Ouargla', 'Rouissat', 'Sidi Khouiled', 'Tebesbest', 'Touggourt'
  ],
  'Ouled Djellal': [
    'Ouled Djellal', 'Doucen', 'Sidi Khaled'
  ],
  'Oum El Bouaghi': [
    'Oum El Bouaghi', 'Aïn Babouche', 'Aïn Beïda', 'Aïn Diss', 'Aïn Fakroun',
    'Aïn Kercha', 'Aïn M’Lila', 'Aïn Zitoun', 'Behir Chergui', 'Berriche',
    'Bir Chouhada', 'Dharmia', 'El Amiria', 'El Belala', 'El Fedjoudj Boughrara',
    'El Harmilia', 'Fkirina', 'Hanchir Toumghani', 'Ksar Sbahi', 'Meskiana',
    'Oued Nini', 'Ouled Gacem', 'Ouled Hamla', 'Ouled Zouaï', 'Rahia', 'Sidi Khelifa',
    'Sidi Rached', 'Souk Naamane', 'Zorg'
  ],
  'Relizane': [
    'Relizane', 'Aïn Rahma', 'Aïn Tarek', 'Ammi Moussa', 'Belaassel Bouzegza',
    'Beni Dergoun', 'Beni Zentis', 'Dar Ben Abdellah', 'Djidioua', 'El Guettar',
    'El Hamadna', 'El Hassi', 'El Matmar', 'El Ouldja', 'Hadjout', 'Kalaa',
    'Lahlef', 'Mazouna', 'Mediouna', 'Mendes', 'Merdja Sidi Abed', 'Oued El Djemaa',
    'Oued Rhiou', 'Ouled Aïch', 'Ouled Sidi Mihoub', 'Ramka', 'Sidi Khettab',
    'Sidi Lazreg', 'Sidi M’Hamed Ben Ali', 'Sidi Saâda', 'Sougueur', 'Yellel',
    'Zemmoura'
  ],
  'Saïda': [
    'Saïda', 'Aïn El Hadjar', 'Aïn Soltane', 'Doui Thabet', 'El Hassasna', 'Hounet',
    'Moulay Larbi', 'Ouled Brahim', 'Ouled Khaled', 'Sidi Ahmed', 'Sidi Boubekeur',
    'Sidi Amar', 'Tircine', 'Youb'
  ],
  'Sétif': [
    'Sétif', 'Aïn Abessa', 'Aïn Arnat', 'Aïn Azel', 'Aïn El Kebira', 'Aïn Oulmène',
    'Aïn Legraj', 'Aïn Roua', 'Aïn Sebt', 'Aïn Taguine', 'Amoucha', 'Babor',
    'Beidha Bordj', 'Beni Aziz', 'Beni Chebana', 'Beni Fouda', 'Beni Hocine',
    'Beni Mouhli', 'Bir El Arch', 'Bouandas', 'Bougaâ', 'Bousselam', 'Boutaleb',
    'Dehamcha', 'Djemila', 'Draâ Kebila', 'El Eulma', 'El Ouldja', 'El Ouricia',
    'Guelal', 'Guidjel', 'Hamma', 'Harbil', 'Ksar El Abtal', 'Maaouia', 'Mezloug',
    'Oued El Barad', 'Ouled Addouane', 'Ouled Sabor', 'Ouled Teben', 'Ouled Si Ahmed',
    'Rasfa', 'Salah Bey', 'Serdj El Ghoul', 'Tachouda', 'Talaifacene', 'Taya',
    'Tella', 'Tizi N’Bechar'
  ],
  'Sidi Bel Abbès': [
    'Sidi Bel Abbès', 'Aïn Adden', 'Aïn El Berd', 'Aïn Kada', 'Aïn Thrid', 'Aïn Tindamine',
    'Amarnas', 'Badredine El Mokrani', 'Belaâba', 'Benachiba Chelia', 'Benali Benyoub',
    'Boubekeur', 'Bouhanche', 'Boukhanafis', 'Chebaita Mokhtar', 'Chettouane Belaila',
    'Dhaya', 'El Haçaiba', 'Hassi Dahou', 'Hassi Zehana', 'Lamtar', 'Makedra', 'Marhoum',
    'Mazzer', 'Mezaourou', 'Moulay Slissen', 'Oued Sebaa', 'Oued Sefioun', 'Ras El Ma',
    'Redjem Demouche', 'Sfissef', 'Sidi Ali Benyoub', 'Sidi Bel Abbès', 'Sidi Brahim',
    'Sidi Chaïb', 'Sidi Hamadouche', 'Sidi Khaled', 'Sidi Lahcene', 'Sidi Yacoub',
    'Tabia', 'Talassa', 'Taoudmout', 'Teghalimet', 'Telagh', 'Tenira', 'Tessala',
    'Tilmouni', 'Zerouala'
  ],
  'Skikda': [
    'Skikda', 'Aïn Bouziane', 'Aïn Charchar', 'Aïn Kechra', 'Aïn Zouit', 'Azzaba',
    'Bekkouche Lakhdar', 'Ben Azzouz', 'Beni Bechir', 'Beni Oulbane', 'Bin El Ouiden',
    'Bouchtata', 'Cheraia', 'El Ghedir', 'El Hadaiek', 'El Marsa', 'Emdjez Edchich',
    'Es Sebt', 'Filfila', 'Hamadi Krouma', 'Kanoua', 'Kerkera', 'Oued Djebbara',
    'Ouled Attia', 'Ouled Hbaba', 'Oum Toub', 'Ramdane Djamel', 'Salah Bouchaour',
    'Sidi Mezghiche', 'Tamalous', 'Zerdazas', 'Zitouna'
  ],
  'Souk Ahras': [
    'Souk Ahras', 'Aïn Soltane', 'Aïn Zana', 'Bir Bouhouche', 'Drea', 'Haddada',
    'Hanancha', 'Khedara', 'Khemissa', 'M’Daourouch', 'Machroha', 'Merahna',
    'Ouled Driss', 'Oum El Adhaïm', 'Ragouba', 'Saïda', 'Sedrata', 'Sidi Fredj',
    'Sidi Hamla', 'Taoura', 'Terraguelt', 'Tiffech', 'Zaarouria', 'Zouabi'
  ],
  'Tamanrasset': [
    'Tamanrasset', 'Abalessa', 'Idles', 'In Amguel', 'In Ghar', 'In Guezzam',
    'Tazrouk', 'Tin Zaouatine'
  ],
  'Tébessa': [
    'Tébessa', 'Aïn Zerga', 'Bekkaria', 'Bir El Ater', 'Bir Mokkadem', 'Boukhroufa',
    'Boulhaf Dir', 'Cheria', 'El Aouinet', 'El Hammamet', 'El Kouif', 'El Ma El Abiod',
    'El Meridj', 'El Ogla', 'El Ogla El Malha', 'Ferkane', 'Guorriguer', 'Hammamet',
    'Morsott', 'Negrine', 'Oued Kabrit', 'Oum Ali', 'Safsaf El Ouesra', 'Stah Guentis',
    'Tlidjene'
  ],
  'Tiaret': [
    'Tiaret', 'Aïn Bouchekif', 'Aïn Deheb', 'Aïn Dzarit', 'Aïn El Hadid', 'Aïn Kermes',
    'Aïn Zarit', 'Bougara', 'Chehaima', 'Dahmouni', 'Djebilet Rosfa', 'Djillali Ben Amar',
    'Faidja', 'Frenda', 'Guertoufa', 'Hamadia', 'Ksar Chellala', 'Mechraâ Safa',
    'Madna', 'Mahdia', 'Mechrouha', 'Medrissa', 'Mellakou', 'Nadorah', 'Oued Lilli',
    'Rahouia', 'Rechaïga', 'Sebaïne', 'Sidi Abdelghani', 'Sidi Ali Mellal', 'Sidi Bakhti',
    'Sidi Hosni', 'Sidi M’Hamed', 'Sidi Mokhtar', 'Sidi Slimane', 'Sougueur', 'Tagdemt',
    'Takhemaret', 'Tidda', 'Tousnina', 'Zmalet El Emir Abdelkader'
  ],
  'Timimoun': [
    'Timimoun', 'Ouled Aïssa', 'Ouled Said', 'Tinerkouk'
  ],
  'Tindouf': [
    'Tindouf', 'Oum El Achar'
  ],
  'Tipaza': [
    'Tipaza', 'Aïn Tagourait', 'Attatba', 'Beni Milleuk', 'Bou Ismail', 'Bouharoun',
    'Bourkika', 'Chaiba', 'Cherchell', 'Damous', 'Douaouda', 'Fouka', 'Gouraya',
    'Hadjout', 'Khemisti', 'Larhat', 'Menaceur', 'Merad', 'Messelmoun', 'Nador',
    'Sidi Amar', 'Sidi Ghiles', 'Sidi Rached', 'Sidi Semiane', 'Tazgait', 'Tefessour'
  ],
  'Tissemsilt': [
    'Tissemsilt', 'Aïn El Hadid', 'Aïn Larbi', 'Aïn Sefra', 'Beni Chaïb', 'Beni Lahcene',
    'Bordj Bounaama', 'Bordj El Emir Abdelkader', 'Boucaïd', 'Boumaâd', 'Bouzeri',
    'El Guerrouj', 'Khemisti', 'Lardjem', 'Layoune', 'Mâacem', 'Melaab', 'Ouled Bessem',
    'Sidi Abed', 'Sidi Boutouchent', 'Sidi Lantri', 'Sidi Slimane', 'Tamalaht', 'Theniet El Had'
  ],
  'Tizi Ouzou': [
    'Tizi Ouzou', 'Aïn El Hammam', 'Aghribs', 'Aït Aouggacha', 'Aït Bouaddou', 'Aït Boumahdi',
    'Aït Chafâa', 'Aït Khellili', 'Aït Mahmoud', 'Aït Oumalou', 'Aït Yahia', 'Aït Yahia Moussa',
    'Aït Ziki', 'Akbil', 'Assi Youcef', 'Azazga', 'Azeffoun', 'Béni Douala', 'Béni Yenni',
    'Beni Ziki', 'Beni Zmenzer', 'Boghni', 'Boudjima', 'Bouzeguène', 'Draâ Ben Khedda',
    'Draâ El Mizan', 'Fréha', 'Ibdouchene', 'Idjeur', 'Iferhounène', 'Ifigha', 'Iflissen',
    'Illoula Oumalou', 'Imsouhel', 'Irdjen', 'Larbaâ Nath Irathen', 'Mâatkas', 'Makouda',
    'Mekla', 'Mizrana', 'Ouacifs', 'Ouadhia', 'Oued Sebt', 'Oued Zeguir', 'Sidi Naâmane',
    'Souamaâ', 'Souk El Thenine', 'Tadmaït', 'Tifra', 'Tighzirt', 'Timizart', 'Tirmitine',
    'Tizi Gheniff', 'Tizi N’Tleta', 'Tizi Rached', 'Yakouren', 'Yatafen', 'Zekri'
  ],
  'Tlemcen': [
    'Tlemcen', 'Aïn Fetah', 'Aïn Fezza', 'Aïn Ghoraba', 'Aïn Kebira', 'Aïn Nehala',
    'Aïn Tallout', 'Aïn Youcef', 'Amieur', 'Azails', 'Bab El Assa', 'Beni Bahdel',
    'Beni Boussaid', 'Beni Khellad', 'Beni Mester', 'Beni Ouarsous', 'Beni Semiel',
    'Bensekrane', 'Bouhlou', 'Chetouane', 'Dar Yaghmouracene', 'Djebala', 'El Aricha',
    'El Bouihi', 'El Fehoul', 'El Gor', 'Fellaoucene', 'Ghazaouet', 'Hammam Boughrara',
    'Hennaya', 'Honaïne', 'Maghnia', 'Mansourah', 'Marsa Ben M’Hidi', 'Msirda Fouaga',
    'Nedroma', 'Oued Lakhdar', 'Ouled Mimoun', 'Ouled Riyah', 'Remchi', 'Sabra', 'Sebbaa Chioukh',
    'Sebdou', 'Sidi Abdelli', 'Sidi Djilali', 'Sidi Medjahed', 'Sidi Senoussi',
    'Sidi Soufi', 'Souk Tlata', 'Terny Beni Hediel', 'Tianet', 'Zenata'
  ],
  'Touggourt': [
    'Touggourt', 'El Allia', 'Megarine', 'Nezla', 'Tebesbest', 'Zaouia El Abidia'
  ],
};

  @override
  Widget build(BuildContext context) {
    final List<String> communes =
        selectedCity != null ? (wilayaBaladiyat[selectedCity] ?? []) : [];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 320;

        final cityField = Column(
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
              initialValue: selectedCity,
              isExpanded: true,
              borderRadius: BorderRadius.circular(16),
              dropdownColor: Colors.white,
              elevation: 8,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF94A3B8)),
              hint: const Text('Select City',
                  style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 13,
                      fontFamily: 'Lexend')),
              validator: (value) => value == null ? 'Required' : null,
              items: wilayaBaladiyat.keys
                  .map((city) => DropdownMenuItem(
                        value: city,
                        child: Text(city,
                            style: const TextStyle(
                                color: Color(0xFF1f2937),
                                fontSize: 13,
                                fontFamily: 'Lexend')),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedCity = value;
                  selectedCommune = null; // reset commune when city changes
                });
                if (value != null) widget.onCityChanged(value);
              },
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: widget.showCityError
                            ? Colors.red
                            : const Color(0xFFE0E0E0))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFFE0E0E0), width: 2)),
                errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Colors.red, width: 1.5)),
                focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Colors.red, width: 1.5)),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
            ),
          ],
        );

        final communeField = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
              child: const Text(
                'Commune',
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
              initialValue: selectedCommune,
              isExpanded: true,
              borderRadius: BorderRadius.circular(16),
              dropdownColor: Colors.white,
              elevation: 8,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: selectedCity == null
                    ? const Color(0xFFCBD5E1)
                    : const Color(0xFF94A3B8),
              ),
              hint: Text(
                selectedCity == null ? 'Select city first' : 'Select Commune',
                style: TextStyle(
                  color: selectedCity == null
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF94A3B8),
                  fontSize: 13,
                  fontFamily: 'Lexend',
                ),
              ),
              validator: (value) => value == null ? 'Required' : null,
              items: communes
                  .map((commune) => DropdownMenuItem(
                        value: commune,
                        child: Text(commune,
                            style: const TextStyle(
                                color: Color(0xFF1f2937),
                                fontSize: 13,
                                fontFamily: 'Lexend')),
                      ))
                  .toList(),
              onChanged: selectedCity == null
                  ? null
                  : (value) {
                      setState(() => selectedCommune = value);
                    },
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: selectedCity == null
                            ? const Color(0xFFF1F5F9)
                            : const Color(0xFFE0E0E0))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFFE0E0E0), width: 2)),
                errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Colors.red, width: 1.5)),
                focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Colors.red, width: 1.5)),
                filled: true,
                fillColor: selectedCity == null
                    ? const Color(0xFFF8FAFC)
                    : const Color(0xFFFFFFFF),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
            ),
          ],
        );

        if (isNarrow) {
          return Column(
            children: [
              cityField,
              const SizedBox(height: 12),
              communeField,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: cityField),
            const SizedBox(width: 12),
            Expanded(child: communeField),
          ],
        );
      },
    );
  }
}


String toE164(String phone, String countryCode) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  final local = digits.startsWith('0') ? digits.substring(1) : digits;
  return '+$countryCode$local';
}
