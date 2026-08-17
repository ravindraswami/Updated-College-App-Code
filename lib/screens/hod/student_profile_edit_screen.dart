import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/academic_data.dart';
import '../../widgets/location_picker.dart';

/// UG/PG Incharge: view and edit a student's full profile.
/// Only the Incharge (this screen is only reachable from the Incharge's
/// Students tab in hod_dashboard.dart) can edit a student's details here.
class StudentProfileEditScreen extends StatefulWidget {
  final UserModel student;
  const StudentProfileEditScreen({super.key, required this.student});

  @override
  State<StudentProfileEditScreen> createState() => _StudentProfileEditScreenState();
}

class _StudentProfileEditScreenState extends State<StudentProfileEditScreen> {
  final _authService = AuthService();
  bool _isEditing = false;
  bool _isSaving = false;

  late final Map<String, TextEditingController> _c;
  String? _state, _district, _taluka, _village;
  String _hostelFacility = 'No';

  UserModel get s => widget.student;

  @override
  void initState() {
    super.initState();
    _c = {
      'nameAsPerHsc': TextEditingController(text: s.nameAsPerHsc),
      'nameAsPerAadhar': TextEditingController(text: s.nameAsPerAadhar),
      'motherName': TextEditingController(text: s.motherName),
      'abcId': TextEditingController(text: s.abcId),
      'aadharNo': TextEditingController(text: s.aadharNo),
      'dob': TextEditingController(text: s.dob),
      'mobile': TextEditingController(text: s.mobile),
      'email': TextEditingController(text: s.email),
      'maritalStatus': TextEditingController(text: s.maritalStatus),
      'address': TextEditingController(text: s.address),
      'fatherOrHusbandName': TextEditingController(text: s.fatherOrHusbandName),
      'guardianOccupation': TextEditingController(text: s.guardianOccupation),
      'religion': TextEditingController(text: s.religion),
      'caste': TextEditingController(text: s.caste),
      'actualCasteCategory': TextEditingController(text: s.actualCasteCategory),
      'admittedCasteCategory': TextEditingController(text: s.admittedCasteCategory),
      'registerNo': TextEditingController(text: s.registerNo),
    };
    _state = s.state.isNotEmpty ? s.state : null;
    _district = s.district.isNotEmpty ? s.district : null;
    _taluka = s.taluka.isNotEmpty ? s.taluka : null;
    _village = s.village.isNotEmpty ? s.village : null;
    _hostelFacility = s.hostelFacility.isNotEmpty ? s.hostelFacility : 'No';
  }

  @override
  void dispose() {
    for (final ctrl in _c.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final data = <String, dynamic>{
        for (final e in _c.entries) e.key: e.value.text.trim(),
        'hostelFacility': _hostelFacility,
      };
      if (_state != null) data['state'] = _state;
      if (_district != null) data['district'] = _district;
      if (_taluka != null) data['taluka'] = _taluka;
      if (_village != null) data['village'] = _village;

      await _authService.updateProfile(s.id, data);
      if (!mounted) return;
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student profile updated.'), backgroundColor: AppTheme.success),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: $e'), backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 150,
              child: Text(label,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500)),
            ),
            Expanded(
              child: Text(value.isNotEmpty ? value : '—',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      );

  Widget _field(String key, String label, {int maxLines = 1}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextFormField(
          controller: _c[key],
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      );

  Widget _card(String title, List<Widget> children) => Card(
        margin: const EdgeInsets.only(bottom: 14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primary)),
              const Divider(height: 16),
              ...children,
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(s.displayName.isNotEmpty ? s.displayName : 'Student Profile'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        actions: [
          if (!_isEditing)
            IconButton(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit',
            )
          else
            IconButton(
              onPressed: _isSaving ? null : () => setState(() => _isEditing = false),
              icon: const Icon(Icons.close),
              tooltip: 'Cancel',
            ),
        ],
      ),
      floatingActionButton: _isEditing
          ? FloatingActionButton.extended(
              onPressed: _isSaving ? null : _save,
              backgroundColor: AppTheme.success,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save),
              label: const Text('Save'),
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _card('Academic Information', [
              _row('Branch', AcademicData.branchFullLabel(s.branch)),
              _row('Year', AcademicData.yearFullLabel(s.year)),
              _row('Semester', s.semester),
              _isEditing ? _field('registerNo', 'Registration No.') : _row('Registration No.', s.registerNo),
              _row('ERP ID', s.erpId),
              _row('Class', s.classId),
            ]),
            _card('Personal Information', [
              _isEditing ? _field('nameAsPerHsc', 'Name (as per HSC)') : _row('Name (HSC)', s.nameAsPerHsc),
              _isEditing ? _field('nameAsPerAadhar', 'Name (as per Aadhar)') : _row('Name (Aadhar)', s.nameAsPerAadhar),
              _isEditing ? _field('motherName', "Mother's Name") : _row("Mother's Name", s.motherName),
              _isEditing ? _field('aadharNo', 'Aadhar No.') : _row('Aadhar No.', s.aadharNo),
              _isEditing ? _field('dob', 'Date of Birth') : _row('Date of Birth', s.dob),
              _isEditing ? _field('maritalStatus', 'Marital Status') : _row('Marital Status', s.maritalStatus),
              _isEditing ? _field('mobile', 'Mobile Number') : _row('Mobile', s.mobile),
              _isEditing ? _field('email', 'Email') : _row('Email', s.email),
              _isEditing ? _field('abcId', 'ABC ID') : _row('ABC ID', s.abcId),
            ]),
            _card('Address', [
              _isEditing ? _field('address', 'Address', maxLines: 2) : _row('Address', s.address),
              if (_isEditing) ...[
                const SizedBox(height: 6),
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
              ] else ...[
                _row('State', s.state),
                _row('District', s.district),
                _row('Taluka', s.taluka),
                _row('Village', s.village),
              ],
            ]),
            _card('Family Information', [
              _isEditing
                  ? _field('fatherOrHusbandName', "Father's / Husband's Name")
                  : _row("Father's / Husband's Name", s.fatherOrHusbandName),
              _isEditing
                  ? _field('guardianOccupation', 'Guardian Occupation')
                  : _row('Guardian Occupation', s.guardianOccupation),
            ]),
            _card('Category & Religion', [
              _isEditing ? _field('religion', 'Religion') : _row('Religion', s.religion),
              _isEditing ? _field('caste', 'Caste') : _row('Caste', s.caste),
              _isEditing
                  ? _field('actualCasteCategory', 'Actual Category')
                  : _row('Actual Category', s.actualCasteCategory),
              _isEditing
                  ? _field('admittedCasteCategory', 'Admitted Category')
                  : _row('Admitted Category', s.admittedCasteCategory),
              if (_isEditing)
                Row(
                  children: [
                    const Text('Hostel Facility  '),
                    Radio<String>(
                      value: 'Yes',
                      groupValue: _hostelFacility,
                      onChanged: (v) => setState(() => _hostelFacility = v!),
                    ),
                    const Text('Yes'),
                    Radio<String>(
                      value: 'No',
                      groupValue: _hostelFacility,
                      onChanged: (v) => setState(() => _hostelFacility = v!),
                    ),
                    const Text('No'),
                  ],
                )
              else
                _row('Hostel Facility', s.hostelFacility),
            ]),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}
