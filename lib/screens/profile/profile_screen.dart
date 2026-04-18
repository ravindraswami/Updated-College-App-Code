import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../legal/legal_screen.dart';
import '../../widgets/location_picker.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel user;
  final VoidCallback? onLogout;
  const ProfileScreen({super.key, required this.user, this.onLogout});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  bool _isSaving = false;
  final _authService = AuthService();

  // Editable controllers — only fields allowed to edit post-registration
  late TextEditingController _mobileCtrl;
  late TextEditingController _abcIdCtrl;
  late TextEditingController _addressCtrl;
  String? _state;
  String? _district;
  String? _taluka;
  String? _village;
  String _hostelFacility = 'No';
  // Staff editable
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;

  @override
  void initState() {
    super.initState();
    _mobileCtrl = TextEditingController(text: widget.user.mobile);
    _abcIdCtrl = TextEditingController(text: widget.user.abcId);
    _addressCtrl = TextEditingController(text: widget.user.address);
    _state = widget.user.state.isNotEmpty ? widget.user.state : null;
    _district = widget.user.district.isNotEmpty ? widget.user.district : null;
    _taluka = widget.user.taluka.isNotEmpty ? widget.user.taluka : null;
    _village = widget.user.village.isNotEmpty ? widget.user.village : null;
    _hostelFacility = widget.user.hostelFacility.isNotEmpty
        ? widget.user.hostelFacility
        : 'No';
    _nameCtrl = TextEditingController(text: widget.user.name);
    _phoneCtrl = TextEditingController(text: widget.user.phone);
  }

  @override
  void dispose() {
    _mobileCtrl.dispose();
    _abcIdCtrl.dispose();
    _addressCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final data = <String, dynamic>{};
      if (widget.user.role == 'student') {
        data['mobile'] = _mobileCtrl.text.trim();
        data['abcId'] = _abcIdCtrl.text.trim();
        data['address'] = _addressCtrl.text.trim();
        if (_state != null) data['state'] = _state;
        if (_district != null) data['district'] = _district;
        if (_taluka != null) data['taluka'] = _taluka;
        if (_village != null) data['village'] = _village;
        data['hostelFacility'] = _hostelFacility;
      } else {
        data['name'] = _nameCtrl.text.trim();
        data['phone'] = _phoneCtrl.text.trim();
        data['address'] = _addressCtrl.text.trim();
      }
      await _authService.updateProfile(widget.user.id, data);
      if (!mounted) return;
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully.'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save changes. Please try again.'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.roleColor(widget.user.role);
    final isStudent = widget.user.role == 'student';

    return SingleChildScrollView(
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.75)],
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white.withOpacity(0.25),
                  child: Text(
                    widget.user.displayName.isNotEmpty
                        ? widget.user.displayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.user.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  AppConstants.roleLabel(widget.user.role),
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 12),
                // ERP ID badge
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: widget.user.erpId));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('ERP ID copied.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.badge, color: color, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          widget.user.erpId.isNotEmpty
                              ? widget.user.erpId
                              : 'ID not assigned',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.copy,
                          color: color.withOpacity(0.5),
                          size: 12,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Edit / Save ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                if (!_isEditing)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _isEditing = true),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit Profile'),
                      style: OutlinedButton.styleFrom(foregroundColor: color),
                    ),
                  )
                else ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _isEditing = false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(backgroundColor: color),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.save, size: 16),
                      label: const Text('Save'),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Profile sections ─────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isStudent) ...[
                  // Academic
                  _Card(
                    title: 'Academic Information',
                    children: [
                      _row('Branch', widget.user.branch),
                      _row('Year', widget.user.year),
                      _row('Semester', widget.user.semester),
                      _row(
                        'Registration No.',
                        widget.user.registerNo.isNotEmpty
                            ? widget.user.registerNo
                            : '(Not assigned)',
                      ),
                      _row('ERP ID', widget.user.erpId),
                      _row('Class', widget.user.classId),
                      _row(
                        'Approval Status',
                        widget.user.isApproved
                            ? 'Approved ✓'
                            : 'Pending approval',
                        valueColor: widget.user.isApproved
                            ? AppTheme.success
                            : AppTheme.warning,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Personal
                  _Card(
                    title: 'Personal Information',
                    children: [
                      _row('Name (HSC)', widget.user.nameAsPerHsc),
                      _row('Name (Aadhar)', widget.user.nameAsPerAadhar),
                      _row("Mother's Name", widget.user.motherName),
                      _row('Aadhar No.', _maskAadhar(widget.user.aadharNo)),
                      _row('Date of Birth', widget.user.dob),
                      _row('Marital Status', widget.user.maritalStatus),
                      _isEditing
                          ? _editField(
                              _mobileCtrl,
                              'Mobile Number',
                              Icons.phone_outlined,
                            )
                          : _row('Mobile', widget.user.mobile),
                      _row('Email', widget.user.email),
                      _isEditing
                          ? _editField(
                              _abcIdCtrl,
                              'ABC ID',
                              Icons.credit_card_outlined,
                            )
                          : _row(
                              'ABC ID',
                              widget.user.abcId.isNotEmpty
                                  ? widget.user.abcId
                                  : '—',
                            ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Address
                  _Card(
                    title: 'Address',
                    children: [
                      _isEditing
                          ? _editField(
                              _addressCtrl,
                              'Address',
                              Icons.home_outlined,
                              maxLines: 2,
                            )
                          : _row('Address', widget.user.address),
                      if (_isEditing) ...[
                        const SizedBox(height: 10),
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
                        _row('State', widget.user.state),
                        _row('District', widget.user.district),
                        _row('Taluka', widget.user.taluka),
                        _row('Village', widget.user.village),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Family
                  _Card(
                    title: 'Family Information',
                    children: [
                      _row(
                        "Father's / Husband's Name",
                        widget.user.fatherOrHusbandName,
                      ),
                      _row(
                        'Guardian Occupation',
                        widget.user.guardianOccupation,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Category
                  _Card(
                    title: 'Category & Religion',
                    children: [
                      _row('Religion', widget.user.religion),
                      _row('Caste', widget.user.caste),
                      _row('Actual Category', widget.user.actualCasteCategory),
                      _row(
                        'Admitted Category',
                        widget.user.admittedCasteCategory,
                      ),
                      _row('Other Category', widget.user.otherCategory),
                      _isEditing
                          ? _hostelToggle()
                          : _row('Hostel Facility', widget.user.hostelFacility),
                    ],
                  ),
                ] else ...[
                  // Staff profile
                  _Card(
                    title: 'Account Information',
                    children: [
                      _isEditing
                          ? _editField(
                              _nameCtrl,
                              'Full Name',
                              Icons.person_outline,
                            )
                          : _row('Name', widget.user.name),
                      _row('Email', widget.user.email),
                      _isEditing
                          ? _editField(
                              _phoneCtrl,
                              'Phone',
                              Icons.phone_outlined,
                            )
                          : _row(
                              'Phone',
                              widget.user.phone.isNotEmpty
                                  ? widget.user.phone
                                  : '—',
                            ),
                      _row('Department', widget.user.department),
                      _row('ERP ID', widget.user.erpId),
                      _row(
                        'Status',
                        widget.user.isApproved ? 'Approved ✓' : 'Pending',
                        valueColor: widget.user.isApproved
                            ? AppTheme.success
                            : AppTheme.warning,
                      ),
                    ],
                  ),
                  if (_isEditing) ...[
                    const SizedBox(height: 14),
                    _Card(
                      title: 'Address',
                      children: [
                        _editField(
                          _addressCtrl,
                          'Address',
                          Icons.home_outlined,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ],
                ],

                const SizedBox(height: 20),

                // Legal links
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
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
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ),
                    const Text('•', style: TextStyle(color: Colors.grey)),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LegalScreen(
                            type: LegalType.termsAndConditions,
                          ),
                        ),
                      ),
                      child: const Text(
                        'Terms & Conditions',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Logout button
                if (widget.onLogout != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: widget.onLogout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.error,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.logout),
                      label: const Text(
                        'Logout',
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _hostelToggle() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFFE2E8F0)),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        const Icon(Icons.hotel_outlined, color: Colors.grey, size: 20),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Hostel Facility',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
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
            const SizedBox(width: 6),
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
  );

  Widget _editField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    int maxLines = 1,
  }) => TextFormField(
    controller: ctrl,
    maxLines: maxLines,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: maxLines > 1
          ? Padding(
              padding: EdgeInsets.only(bottom: (maxLines - 1) * 20.0),
              child: Icon(icon),
            )
          : Icon(icon),
      alignLabelWithHint: maxLines > 1,
    ),
  );

  Widget _row(String label, String value, {Color? valueColor}) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value.isNotEmpty ? value : '—',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ),
      ],
    ),
  );

  String _maskAadhar(String no) {
    if (no.length < 4) return no.isNotEmpty ? no : '—';
    return 'XXXX XXXX ${no.replaceAll(' ', '').substring(no.replaceAll(' ', '').length - 4)}';
  }
}

class _Card extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Card({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.primary,
              ),
            ),
            const Divider(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}
