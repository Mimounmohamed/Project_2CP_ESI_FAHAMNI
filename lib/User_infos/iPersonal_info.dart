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
    return Scaffold(
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
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
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
        backgroundColor: const Color(0xfff9f9f9),
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
          padding: const EdgeInsets.fromLTRB(8, 0, 0, 8),
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
  //bool _dobTouched = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Gender Dropdown
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                child: const Text(
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
                initialValue: selectedGender,
                borderRadius: BorderRadius.circular(16),
                dropdownColor: Colors.white,
                elevation: 8,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8)),
                hint: const Text(
                  'Select Gender',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontFamily: 'Lexend'),
                ),
                validator: (value) {
                  if (value == null) return 'Required';
                  return null;
                },
                items: const [
                  DropdownMenuItem(
                    value: 'male',
                    child: Text('Male', style: TextStyle(color: Color(0xFF1f2937), fontSize: 17, fontFamily: 'Lexend')),
                  ),
                  DropdownMenuItem(
                    value: 'female',
                    child: Text('Female', style: TextStyle(color: Color(0xFF1f2937), fontSize: 17, fontFamily: 'Lexend')),
                  ),
                ],
                onChanged: (value) {
                  setState(() => selectedGender = value);
                  if (value != null) 
                    widget.onGenderChanged(Gender.values.byName(value)  ); 
                },

                decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: widget.showGenderError ? Colors.red : const Color(0xFFE0E0E0)),
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
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 16),

        // Date of Birth
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
                readOnly: true,
                onTap: () => _showCupertinoDatePicker(context),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  return null;
                },
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
                   borderSide: BorderSide(color: widget.showBirthdayError ? Colors.red : const Color(0xFFE0E0E0)),
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
  final _postalController = TextEditingController();

  final List<String> algerianCities = [
    'Adrar', 'Aïn Defla', 'Aïn Témouchent', 'Algiers', 'Annaba',
    'Batna', 'Béchar', 'Béjaïa', 'Béni Abbès', 'Biskra',
    'Blida', 'Bordj Badji Mokhtar', 'Bordj Bou Arréridj', 'Bouira', 'Boumerdès',
    'Chlef', 'Constantine',
    'Djelfa', 'Djanet',
    'El Bayadh', 'El Meniaa', 'El Oued', 'El Tarf',
    'Ghardaïa', 'Guelma',
    'Illizi', 'In Guezzam', 'In Salah',
    'Jijel', 'Khenchela', 'Laghouat',
    'Mascara', 'Médéa', 'M\'Ghair', 'Mila', 'Mostaganem', 'M\'Sila',
    'Naâma', 'Oran', 'Ouargla', 'Ouled Djellal', 'Oum El Bouaghi',
    'Relizane', 'Saïda', 'Sétif', 'Sidi Bel Abbès', 'Skikda', 'Souk Ahras',
    'Tamanrasset', 'Tébessa', 'Tiaret', 'Timimoun', 'Tindouf',
    'Tipaza', 'Tissemsilt', 'Tizi Ouzou', 'Tlemcen', 'Touggourt',
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // City Dropdown
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
                initialValue: selectedCity,
                isExpanded: true,
                borderRadius: BorderRadius.circular(16),
                dropdownColor: Colors.white,
                elevation: 8,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8)),
                hint: const Text(
                  'Select City',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontFamily: 'Lexend'),
                ),
                validator: (value) {
                  if (value == null) return 'Required';
                  return null;
                },
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
                  setState(() => selectedCity = value);
                  if (value != null) widget.onCityChanged(value);
                },
                decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: widget.showCityError ? Colors.red : const Color(0xFFE0E0E0)),
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
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 16),

        // Postal Code
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
                controller: _postalController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (value.length < 4) return 'Invalid code';
                  return null;
                },
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
String toE164(String phone, String countryCode) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  final local = digits.startsWith('0') ? digits.substring(1) : digits;
  return '+$countryCode$local';
}