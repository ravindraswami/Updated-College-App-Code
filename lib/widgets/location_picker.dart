import 'package:flutter/material.dart';
import '../services/location_service.dart';
import '../utils/app_theme.dart';

/// Cascading State → District → Sub-District → Village picker
/// Usage:
///   LocationPicker(
///     onChanged: (state, dist, sub, village) { ... },
///     initialState: 'Maharashtra',
///   )
class LocationPicker extends StatefulWidget {
  final void Function(
    String state,
    String district,
    String subDistrict,
    String village,
  )
  onChanged;
  final String? initialState;
  final String? initialDistrict;
  final String? initialSubDistrict;
  final String? initialVillage;

  const LocationPicker({
    super.key,
    required this.onChanged,
    this.initialState,
    this.initialDistrict,
    this.initialSubDistrict,
    this.initialVillage,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  final _svc = LocationService();

  // Selected values
  String? _state;
  String? _district;
  String? _subDistrict;
  String? _village;

  // Lists
  List<String> _states = [];
  List<String> _districts = [];
  List<String> _subDistricts = [];
  List<String> _villages = [];

  // Loading flags
  bool _loadingStates = true;
  bool _loadingDistricts = false;
  bool _loadingSubDistricts = false;
  bool _loadingVillages = false;

  @override
  void initState() {
    super.initState();
    _loadStates();
  }

  Future<void> _loadStates() async {
    final states = await _svc.getStates();
    if (mounted) {
      setState(() {
        _states = states;
        _loadingStates = false;
        // Restore initial values
        if (widget.initialState != null &&
            states.contains(widget.initialState)) {
          _state = widget.initialState;
          _loadDistricts(widget.initialState!);
        }
      });
    }
  }

  Future<void> _loadDistricts(String state) async {
    setState(() {
      _loadingDistricts = true;
      _districts = [];
      _subDistricts = [];
      _villages = [];
    });
    final districts = await _svc.getDistricts(state);
    if (mounted) {
      setState(() {
        _districts = districts;
        _loadingDistricts = false;
        if (widget.initialDistrict != null &&
            districts.contains(widget.initialDistrict)) {
          _district = widget.initialDistrict;
          _loadSubDistricts(state, widget.initialDistrict!);
        }
      });
    }
  }

  Future<void> _loadSubDistricts(String state, String district) async {
    setState(() {
      _loadingSubDistricts = true;
      _subDistricts = [];
      _villages = [];
    });
    final subs = await _svc.getSubDistricts(state, district);
    if (mounted) {
      setState(() {
        _subDistricts = subs;
        _loadingSubDistricts = false;
        if (widget.initialSubDistrict != null &&
            subs.contains(widget.initialSubDistrict)) {
          _subDistrict = widget.initialSubDistrict;
          _loadVillages(state, district, widget.initialSubDistrict!);
        }
      });
    }
  }

  Future<void> _loadVillages(String state, String district, String sub) async {
    setState(() {
      _loadingVillages = true;
      _villages = [];
    });
    final villages = await _svc.getVillages(state, district, sub);
    if (mounted) {
      setState(() {
        _villages = villages;
        _loadingVillages = false;
        if (widget.initialVillage != null &&
            villages.contains(widget.initialVillage)) {
          _village = widget.initialVillage;
        }
      });
    }
  }

  void _notify() {
    widget.onChanged(
      _state ?? '',
      _district ?? '',
      _subDistrict ?? '',
      _village ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── State ──────────────────────────────────────────
        _buildDropdown(
          label: 'State',
          icon: Icons.map_outlined,
          value: _state,
          items: _states,
          isLoading: _loadingStates,
          hint: 'Select State',
          onChanged: (v) {
            setState(() {
              _state = v;
              _district = null;
              _subDistrict = null;
              _village = null;
              _districts = [];
              _subDistricts = [];
              _villages = [];
            });
            if (v != null) _loadDistricts(v);
            _notify();
          },
        ),

        // ── District ───────────────────────────────────────
        if (_state != null) ...[
          const SizedBox(height: 14),
          _buildDropdown(
            label: 'District',
            icon: Icons.location_city_outlined,
            value: _district,
            items: _districts,
            isLoading: _loadingDistricts,
            hint: 'Select District',
            onChanged: (v) {
              setState(() {
                _district = v;
                _subDistrict = null;
                _village = null;
                _subDistricts = [];
                _villages = [];
              });
              if (v != null && _state != null) _loadSubDistricts(_state!, v);
              _notify();
            },
          ),
        ],

        // ── Sub-District (Taluka) ──────────────────────────
        if (_district != null) ...[
          const SizedBox(height: 14),
          _buildDropdown(
            label: 'Taluka / Sub-District',
            icon: Icons.account_balance_outlined,
            value: _subDistrict,
            items: _subDistricts,
            isLoading: _loadingSubDistricts,
            hint: 'Select Taluka',
            onChanged: (v) {
              setState(() {
                _subDistrict = v;
                _village = null;
                _villages = [];
              });
              if (v != null && _state != null && _district != null) {
                _loadVillages(_state!, _district!, v);
              }
              _notify();
            },
          ),
        ],

        // ── Village ────────────────────────────────────────
        if (_subDistrict != null) ...[
          const SizedBox(height: 14),
          _buildDropdown(
            label: 'Village / Area',
            icon: Icons.location_on_outlined,
            value: _village,
            items: _villages,
            isLoading: _loadingVillages,
            hint: 'Select Village',
            onChanged: (v) {
              setState(() => _village = v);
              _notify();
            },
          ),
        ],
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required bool isLoading,
    required String hint,
    required void Function(String?) onChanged,
  }) {
    if (isLoading) {
      return Container(
        height: 56,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            Icon(icon, color: Colors.grey, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Loading $label...',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 14),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        hintText: hint,
      ),
      hint: Text(hint, style: const TextStyle(color: Colors.grey)),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(item, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: items.isEmpty ? null : onChanged,
    );
  }
}
