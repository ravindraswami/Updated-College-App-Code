import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/academic_data.dart';
import '../legal/register_agreement_dialog.dart';
import '../../widgets/location_picker.dart';
import '../legal/legal_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey1 = GlobalKey<FormState>(); // Step 1
  final _formKey2 = GlobalKey<FormState>(); // Step 2

  // ── Step 1: Academic (shown first) ───────────────────────
  String? _branch;
  String? _year;
  String? _semester;
  final _regNoCtrl = TextEditingController();

  // ── Step 2: Personal (shown after sem selected) ──────────
  final _hscNameCtrl = TextEditingController();
  final _aadharNameCtrl = TextEditingController();
  bool _sameAsHsc = false;
  final _motherNameCtrl = TextEditingController();
  final _abcIdCtrl = TextEditingController();
  final _aadharNoCtrl = TextEditingController();
  String? _dob;
  String? _admissionDate;
  final _mobileCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePass = true;
  String? _maritalStatus;
  String? _gender;

  // Address
  final _addressCtrl = TextEditingController();
  String? _state;
  String? _district;
  String? _taluka;
  String? _village;

  // Family
  final _fatherNameCtrl = TextEditingController();
  String? _guardianOccupation;

  // Category / Religion
  String? _religion;
  String? _caste;
  String? _actualCategory;
  String? _admittedCategory;
  String? _otherCategory = 'None';
  String _hostelFacility = 'No';

  // Staff fields (non-student)
  String _selectedRole = 'student';
  final _staffNameCtrl = TextEditingController();
  final _deptCtrl = TextEditingController();
  final _staffYearCtrl = TextEditingController(
    text: DateTime.now().year.toString(),
  );

  bool _isLoading = false;
  final _authService = AuthService();

  // ── Derived lists ─────────────────────────────────────────
  List<Map<String, dynamic>> get _years =>
      _branch != null ? AcademicData.yearsForBranch(_branch!) : [];

  List<Map<String, dynamic>> get _sems => (_branch != null && _year != null)
      ? AcademicData.semsForYear(_branch!, _year!)
      : [];

  bool get _showPersonalSection => _semester != null;

  bool get _regNoRequired =>
      _branch != null &&
      _year != null &&
      _semester != null &&
      AcademicData.isRegNoRequired(_branch!, _year!, _semester!);

  bool get _isStudent => _selectedRole == 'student';

  // ── Date picker ───────────────────────────────────────────
  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _dob = DateFormat('dd/MM/yyyy').format(picked));
    }
  }

  Future<void> _pickAdmissionDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(
        () => _admissionDate = DateFormat('dd/MM/yyyy').format(picked),
      );
    }
  }

  // ── Register ──────────────────────────────────────────────
  Future<void> _register() async {
    if (_isStudent) {
      if (!_formKey1.currentState!.validate()) return;
      if (!_formKey2.currentState!.validate()) return;
      if (_branch == null || _year == null || _semester == null) {
        _showSnack('Please select Branch, Year and Semester.', isError: true);
        return;
      }
    } else {
      if (!_formKey1.currentState!.validate()) return;
    }

    final agreed = await showRegisterAgreementDialog(context);
    if (agreed != true || !mounted) return;

    setState(() => _isLoading = true);
    try {
      final user = await _authService.registerUser(
        email: _isStudent ? _emailCtrl.text.trim() : _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        name: _isStudent
            ? _hscNameCtrl.text.trim()
            : _staffNameCtrl.text.trim(),
        role: _selectedRole,
        department: _isStudent ? '' : _deptCtrl.text.trim().toUpperCase(),
        year: _isStudent ? _year ?? '' : _staffYearCtrl.text.trim(),
        // Student-specific
        branch: _branch ?? '',
        semester: _semester ?? '',
        registerNo: _regNoCtrl.text.trim(),
        nameAsPerHsc: _hscNameCtrl.text.trim(),
        nameAsPerAadhar: _aadharNameCtrl.text.trim(),
        motherName: _motherNameCtrl.text.trim(),
        abcId: _abcIdCtrl.text.trim(),
        aadharNo: _aadharNoCtrl.text.trim(),
        dob: _dob ?? '',
        admissionDate: _admissionDate ?? '',
        mobile: _mobileCtrl.text.trim(),
        maritalStatus: _maritalStatus ?? '',
        gender: _gender ?? '',
        address: _addressCtrl.text.trim(),
        state: _state ?? '',
        district: _district ?? '',
        taluka: _taluka ?? '',
        village: _village ?? '',
        fatherOrHusbandName: _fatherNameCtrl.text.trim(),
        guardianOccupation: _guardianOccupation ?? '',
        religion: _religion ?? '',
        caste: _caste ?? '',
        actualCasteCategory: _actualCategory ?? '',
        admittedCasteCategory: _admittedCategory ?? '',
        otherCategory: _otherCategory ?? 'None',
        hostelFacility: _hostelFacility,
      );

      if (!mounted) return;
      _showSnack(
        _isStudent
            ? 'Registration submitted! Your class coordinator will review and approve your account.\nERP ID: ${user?.erpId ?? ""}'
            : 'Registration submitted. Awaiting Incharge/Principal approval.',
        isError: false,
        duration: 6,
      );
      Navigator.pop(context);
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {required bool isError, int duration = 4}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppTheme.error : AppTheme.success,
        duration: Duration(seconds: duration),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Role selector ─────────────────────────────
            const _SectionHeader(title: 'Select Role'),
            _buildRoleDropdown(),
            const SizedBox(height: 20),

            // ── STUDENT FORM ──────────────────────────────
            if (_isStudent) ...[
              // STEP 1: Academic info
              _StepBanner(
                step: 1,
                label: 'Academic Information',
                subtitle: 'Select your branch, year and semester',
              ),
              const SizedBox(height: 12),
              Form(
                key: _formKey1,
                child: Column(
                  children: [
                    _buildBranchDropdown(),
                    if (_years.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _buildYearDropdown(),
                    ],
                    if (_sems.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _buildSemDropdown(),
                    ],
                    // Registration No
                    if (_showPersonalSection) ...[
                      const SizedBox(height: 14),
                      _buildRegNo(),
                    ],
                  ],
                ),
              ),

              // STEP 2: Personal info (shown only after sem selected)
              if (_showPersonalSection) ...[
                const SizedBox(height: 24),
                _StepBanner(
                  step: 2,
                  label: 'Personal Information',
                  subtitle: 'Fill in all details carefully',
                ),
                const SizedBox(height: 12),
                Form(
                  key: _formKey2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [_buildStudentPersonalFields()],
                  ),
                ),
              ],
            ]
            // ── STAFF FORM ────────────────────────────────
            else ...[
              Form(key: _formKey1, child: _buildStaffForm()),
            ],

            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const LegalScreen(type: LegalType.termsAndConditions),
                    ),
                  ),
                  child: const Text(
                    'Terms & Conditions',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                const Text('•', style: TextStyle(color: Colors.grey)),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const LegalScreen(type: LegalType.privacyPolicy),
                    ),
                  ),
                  child: const Text(
                    'Privacy Policy',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_isLoading || (_isStudent && !_showPersonalSection))
                    ? null
                    : _register,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _isStudent && !_showPersonalSection
                            ? 'Select Branch → Year → Semester first'
                            : 'Submit Registration',
                        style: const TextStyle(fontSize: 15),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  Widget _buildRoleDropdown() {
    return _DropdownField(
      label: 'Role',
      icon: Icons.badge_outlined,
      value: _selectedRole,
      items: AppConstants.registerRoles
          .map(
            (r) => DropdownMenuItem(
              value: r,
              child: Text(AppConstants.roleLabel(r)),
            ),
          )
          .toList(),
      onChanged: (v) => setState(() {
        _selectedRole = v!;
        _branch = null;
        _year = null;
        _semester = null;
      }),
    );
  }

  Widget _buildBranchDropdown() {
    return _DropdownField(
      label: 'Branch',
      icon: Icons.school_outlined,
      value: _branch,
      hint: 'Select your branch',
      items: AcademicData.branches
          .map(
            (b) => DropdownMenuItem(
              value: b['id'] as String,
              child: Text(b['label'] as String),
            ),
          )
          .toList(),
      onChanged: (v) => setState(() {
        _branch = v;
        _year = null;
        _semester = null;
      }),
      validator: (v) => v == null ? 'Please select your branch.' : null,
    );
  }

  Widget _buildYearDropdown() {
    return _DropdownField(
      label: 'Year',
      icon: Icons.calendar_today,
      value: _year,
      hint: 'Select year',
      items: _years
          .map(
            (y) => DropdownMenuItem(
              value: y['id'] as String,
              child: Text(y['label'] as String),
            ),
          )
          .toList(),
      onChanged: (v) => setState(() {
        _year = v;
        _semester = null;
      }),
      validator: (v) => v == null ? 'Please select your year.' : null,
    );
  }

  Widget _buildSemDropdown() {
    return _DropdownField(
      label: 'Semester',
      icon: Icons.format_list_numbered,
      value: _semester,
      hint: 'Select semester',
      items: _sems
          .map(
            (s) => DropdownMenuItem(
              value: s['id'] as String,
              child: Text(s['label'] as String),
            ),
          )
          .toList(),
      onChanged: (v) => setState(() => _semester = v),
      validator: (v) => v == null ? 'Please select your semester.' : null,
    );
  }

  Widget _buildRegNo() {
    return TextFormField(
      controller: _regNoCtrl,
      keyboardType: TextInputType.text,
      textCapitalization: TextCapitalization.characters,
      decoration: InputDecoration(
        labelText: _regNoRequired
            ? 'Registration Number (College)'
            : 'Registration Number (Optional — FY Sem I)',
        prefixIcon: const Icon(Icons.numbers),
        hintText: 'e.g. 2024BT001',
        helperText: _regNoRequired
            ? 'Required — as per college records'
            : 'Optional for FY Sem I (comparative admission)',
        helperStyle: TextStyle(
          color: _regNoRequired ? AppTheme.error : Colors.grey,
          fontSize: 11,
        ),
      ),
      validator: (v) {
        if (_regNoRequired && (v == null || v.trim().isEmpty)) {
          return 'Registration number is required for this year/semester.';
        }
        return null;
      },
    );
  }

  Widget _buildStudentPersonalFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 4. Student Name as per HSC
        _Field(
          ctrl: _hscNameCtrl,
          label: 'Full Name (As per HSC Marklist)',
          icon: Icons.person_outline,
          caps: TextCapitalization.characters,
          validator: (v) => v!.trim().isEmpty
              ? 'Please enter your name as per HSC marklist.'
              : null,
        ),
        const SizedBox(height: 14),

        // 5. Name as per Aadhar — with same-as-above checkbox
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: _sameAsHsc,
                    onChanged: (v) => setState(() {
                      _sameAsHsc = v!;
                      if (_sameAsHsc) _aadharNameCtrl.text = _hscNameCtrl.text;
                    }),
                    activeColor: AppTheme.primary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Same as HSC name',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _aadharNameCtrl,
                enabled: !_sameAsHsc,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Full Name (As per Aadhar Card)',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (v) => v!.trim().isEmpty
                    ? 'Please enter name as per Aadhar card.'
                    : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 6. Mother Name
        _Field(
          ctrl: _motherNameCtrl,
          label: "Mother's Name (Before Marriage)",
          icon: Icons.person_2_outlined,
          caps: TextCapitalization.characters,
          validator: (v) =>
              v!.trim().isEmpty ? "Please enter mother's name." : null,
        ),
        const SizedBox(height: 14),

        // 7. ABC ID
        _Field(
          ctrl: _abcIdCtrl,
          label: 'ABC ID',
          icon: Icons.credit_card_outlined,
          hint: 'Academic Bank of Credits ID',
        ),
        const SizedBox(height: 14),

        // 8. Aadhar No
        TextFormField(
          controller: _aadharNoCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(12),
            _AadharFormatter(),
          ],
          decoration: const InputDecoration(
            labelText: 'Aadhar Card Number',
            prefixIcon: Icon(Icons.fingerprint),
            hintText: 'XXXX XXXX XXXX',
          ),
          validator: (v) {
            final digits = v?.replaceAll(' ', '') ?? '';
            if (digits.isEmpty) return 'Please enter your Aadhar number.';
            if (digits.length != 12) return 'Aadhar number must be 12 digits.';
            return null;
          },
        ),
        const SizedBox(height: 14),

        // 9. Date of Birth
        GestureDetector(
          onTap: _pickDob,
          child: AbsorbPointer(
            child: TextFormField(
              decoration: InputDecoration(
                labelText: 'Date of Birth',
                prefixIcon: const Icon(Icons.cake_outlined),
                hintText: 'dd/MM/yyyy',
                suffixIcon: const Icon(Icons.calendar_today, size: 18),
              ),
              controller: TextEditingController(text: _dob ?? ''),
              validator: (_) => (_dob == null || _dob!.isEmpty)
                  ? 'Please select your date of birth.'
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 14),

        // 9b. Year of Admission
        GestureDetector(
          onTap: _pickAdmissionDate,
          child: AbsorbPointer(
            child: TextFormField(
              decoration: InputDecoration(
                labelText: 'Year of Admission',
                prefixIcon: const Icon(Icons.school_outlined),
                hintText: 'dd/MM/yyyy',
                suffixIcon: const Icon(Icons.calendar_today, size: 18),
              ),
              controller: TextEditingController(text: _admissionDate ?? ''),
              validator: (_) => (_admissionDate == null || _admissionDate!.isEmpty)
                  ? 'Please select year of admission.'
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 14),

        // 10. Mobile
        TextFormField(
          controller: _mobileCtrl,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          decoration: const InputDecoration(
            labelText: 'Mobile Number',
            prefixIcon: Icon(Icons.phone_outlined),
            prefixText: '+91 ',
          ),
          validator: (v) {
            if (v!.isEmpty) return 'Please enter your mobile number.';
            if (v.length != 10) return 'Mobile number must be 10 digits.';
            return null;
          },
        ),
        const SizedBox(height: 14),

        // 11. Email + Password
        _Field(
          ctrl: _emailCtrl,
          label: 'Email Address',
          icon: Icons.email_outlined,
          type: TextInputType.emailAddress,
          validator: (v) {
            if (v!.trim().isEmpty) return 'Please enter your email address.';
            if (!v.contains('@')) return 'Please enter a valid email.';
            return null;
          },
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _passwordCtrl,
          obscureText: _obscurePass,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePass ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () => setState(() => _obscurePass = !_obscurePass),
            ),
          ),
          validator: (v) {
            if (v!.isEmpty) return 'Please create a password.';
            if (v.length < 6) return 'Password must be at least 6 characters.';
            return null;
          },
        ),
        const SizedBox(height: 14),

        // 12. Marital Status
        _DropdownField(
          label: 'Marital Status',
          icon: Icons.favorite_border,
          value: _maritalStatus,
          hint: 'Select status',
          items: AcademicData.maritalStatuses
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (v) => setState(() => _maritalStatus = v),
          validator: (v) => v == null ? 'Please select marital status.' : null,
        ),
        const SizedBox(height: 14),

        // 12b. Gender
        _DropdownField(
          label: 'Gender',
          icon: Icons.wc_outlined,
          value: _gender,
          hint: 'Select gender',
          items: const ['Male', 'Female', 'Other']
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (v) => setState(() => _gender = v),
          validator: (v) => v == null ? 'Please select gender.' : null,
        ),
        const SizedBox(height: 20),

        // ── Address section ──────────────────────────────
        const _SectionHeader(title: 'Address Details'),
        const SizedBox(height: 10),

        // 13. Address line
        _Field(
          ctrl: _addressCtrl,
          label: 'Address (S/O or Permanent)',
          icon: Icons.home_outlined,
          maxLines: 2,
          hint: 'House No., Street, Area',
          validator: (v) =>
              v!.trim().isEmpty ? 'Please enter your address.' : null,
        ),
        const SizedBox(height: 14),

        // 14-17. State → District → Taluka → Village (cascading)
        LocationPicker(
          initialState: _state,
          initialDistrict: _district,
          initialSubDistrict: _taluka,
          initialVillage: _village,
          onChanged: (state, district, sub, village) {
            setState(() {
              _state = state.isNotEmpty ? state : null;
              _district = district.isNotEmpty ? district : null;
              _taluka = sub.isNotEmpty ? sub : null;
              _village = village.isNotEmpty ? village : null;
            });
          },
        ),
        const SizedBox(height: 20),

        // ── Family section ───────────────────────────────
        const _SectionHeader(title: 'Family Information'),
        const SizedBox(height: 10),

        // 18. Father / Husband name
        _Field(
          ctrl: _fatherNameCtrl,
          label: "Father's Full Name / Husband's Name",
          icon: Icons.person_4_outlined,
          caps: TextCapitalization.characters,
          validator: (v) =>
              v!.trim().isEmpty ? 'Please enter father/husband name.' : null,
        ),
        const SizedBox(height: 14),

        // 19. Occupation
        _DropdownField(
          label: "Father's / Guardian's Occupation",
          icon: Icons.work_outline,
          value: _guardianOccupation,
          hint: 'Select occupation',
          items: AcademicData.occupations
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: (v) => setState(() => _guardianOccupation = v),
          validator: (v) => v == null ? 'Please select occupation.' : null,
        ),
        const SizedBox(height: 20),

        // ── Category / Religion section ──────────────────
        const _SectionHeader(title: 'Category & Religion'),
        const SizedBox(height: 10),

        // 20. Religion
        _DropdownField(
          label: 'Religion',
          icon: Icons.temple_buddhist_outlined,
          value: _religion,
          hint: 'Select religion',
          items: AcademicData.religionCastes.keys
              .map((r) => DropdownMenuItem(value: r, child: Text(r)))
              .toList(),
          onChanged: (v) => setState(() {
            _religion = v;
            _caste = null;
          }),
          validator: (v) => v == null ? 'Please select religion.' : null,
        ),
        if (_religion != null) ...[
          const SizedBox(height: 14),
          // 21. Caste
          _DropdownField(
            label: 'Caste',
            icon: Icons.groups_outlined,
            value: _caste,
            hint: 'Select caste',
            items: AcademicData.castesForReligion(
              _religion!,
            ).map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _caste = v),
            validator: (v) => v == null ? 'Please select caste.' : null,
          ),
        ],
        const SizedBox(height: 14),

        // 22. Actual Caste Category
        _DropdownField(
          label: 'Actual Caste Category',
          icon: Icons.category_outlined,
          value: _actualCategory,
          hint: 'Select category',
          items: AcademicData.actualCasteCategories
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (v) => setState(() => _actualCategory = v),
          validator: (v) =>
              v == null ? 'Please select actual caste category.' : null,
        ),
        const SizedBox(height: 14),

        // 23. Admitted Caste Category
        _DropdownField(
          label: 'Admitted Caste Category',
          icon: Icons.assignment_ind_outlined,
          value: _admittedCategory,
          hint: 'Select category',
          items: AcademicData.admittedCasteCategories
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (v) => setState(() => _admittedCategory = v),
          validator: (v) =>
              v == null ? 'Please select admitted caste category.' : null,
        ),
        const SizedBox(height: 14),

        // 24. Other Category
        _DropdownField(
          label: 'Other Category',
          icon: Icons.label_outline,
          value: _otherCategory,
          items: AcademicData.otherCategories
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (v) => setState(() => _otherCategory = v),
        ),
        const SizedBox(height: 14),

        // 25. Hostel Facility
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: Row(
            children: [
              const Icon(Icons.hotel_outlined, color: Colors.grey, size: 22),
              const SizedBox(width: 12),
              const Text(
                'Hostel Facility Required?',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Radio<String>(
                    value: 'Yes',
                    groupValue: _hostelFacility,
                    onChanged: (v) => setState(() => _hostelFacility = v!),
                    activeColor: AppTheme.success,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const Text('Yes'),
                  const SizedBox(width: 8),
                  Radio<String>(
                    value: 'No',
                    groupValue: _hostelFacility,
                    onChanged: (v) => setState(() => _hostelFacility = v!),
                    activeColor: AppTheme.error,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const Text('No'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildStaffForm() {
    return Column(
      children: [
        _Field(
          ctrl: _staffNameCtrl,
          label: 'Full Name',
          icon: Icons.person_outline,
          caps: TextCapitalization.words,
          validator: (v) =>
              v!.trim().isEmpty ? 'Please enter your name.' : null,
        ),
        const SizedBox(height: 14),
        _Field(
          ctrl: _emailCtrl,
          label: 'Email Address',
          icon: Icons.email_outlined,
          type: TextInputType.emailAddress,
          validator: (v) {
            if (v!.trim().isEmpty) return 'Please enter your email.';
            if (!v.contains('@')) return 'Please enter a valid email.';
            return null;
          },
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _passwordCtrl,
          obscureText: _obscurePass,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePass ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () => setState(() => _obscurePass = !_obscurePass),
            ),
          ),
          validator: (v) {
            if (v!.isEmpty) return 'Please create a password.';
            if (v.length < 6) return 'Password must be at least 6 characters.';
            return null;
          },
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _deptCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Department',
                  hintText: 'e.g. BIO-TECH',
                  prefixIcon: Icon(Icons.business_outlined),
                ),
                validator: (v) =>
                    v!.trim().isEmpty ? 'Please enter department.' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _staffYearCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Year',
                  hintText: 'e.g. 2026',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                validator: (v) => v!.length != 4 ? 'Enter valid year.' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.warning, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your account requires approval from Incharge or Principal before you can login.',
                  style: TextStyle(color: AppTheme.warning, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Helper Widgets
// ─────────────────────────────────────────────────────────────

class _StepBanner extends StatelessWidget {
  final int step;
  final String label;
  final String subtitle;
  const _StepBanner({
    required this.step,
    required this.label,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.secondary],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.white.withOpacity(0.25),
            child: Text(
              '$step',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: AppTheme.primary,
      ),
    ),
  );
}

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final IconData icon;
  final T? value;
  final String? hint;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;
  final String? Function(T?)? validator;

  const _DropdownField({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        hintText: hint,
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<T>(
              value: item.value,
              child: DefaultTextStyle(
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  overflow: TextOverflow.ellipsis,
                ),
                child: item.child,
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final String? hint;
  final int maxLines;
  final TextInputType type;
  final TextCapitalization caps;
  final String? Function(String?)? validator;

  const _Field({
    required this.ctrl,
    required this.label,
    required this.icon,
    this.hint,
    this.maxLines = 1,
    this.type = TextInputType.text,
    this.caps = TextCapitalization.sentences,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      textCapitalization: caps,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: maxLines > 1
            ? Padding(
                padding: EdgeInsets.only(bottom: (maxLines - 1) * 20.0),
                child: Icon(icon),
              )
            : Icon(icon),
        alignLabelWithHint: maxLines > 1,
      ),
      validator: validator,
    );
  }
}

// Aadhar number formatter: XXXX XXXX XXXX
class _AadharFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 12; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
