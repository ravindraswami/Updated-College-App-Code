import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'id_service.dart';
import 'user_service.dart';
import '../utils/principal_config.dart';
import 'notification_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _idService = IdService();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> getCurrentUserModel() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!, doc.id);
  }

  Future<UserModel?> registerUser({
    required String email,
    required String password,
    required String name, // for staff; for students use nameAsPerHsc
    required String role,
    String department = '',
    String year = '',
    // Student-specific
    String branch = '',
    String semester = '',
    String registerNo = '',
    String nameAsPerHsc = '',
    String nameAsPerAadhar = '',
    String motherName = '',
    String abcId = '',
    String aadharNo = '',
    String dob = '',
    String mobile = '',
    String maritalStatus = '',
    String address = '',
    String state = '',
    String district = '',
    String taluka = '',
    String village = '',
    String fatherOrHusbandName = '',
    String guardianOccupation = '',
    String religion = '',
    String caste = '',
    String actualCasteCategory = '',
    String admittedCasteCategory = '',
    String otherCategory = 'None',
    String hostelFacility = 'No',
    // Staff
    String phone = '',
    String classId = '',
    String classLabel = '',
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;

      // Students: erpId = their college registerNo (or empty if FY Sem I)
      // Staff: auto-generated role-based ID
      String erpId;
      if (role == 'student') {
        erpId = registerNo.isNotEmpty ? registerNo : '';
      } else {
        erpId = await _idService.generateStaffId(
          role: role,
          department: department.isNotEmpty ? department : 'GEN',
          year: year.isNotEmpty ? year : DateTime.now().year.toString(),
        );
      }

      // Build classId from branch+semester for students
      // Format: "BIO-TECH-UG|SEM-I"
      String builtClassId = classId;
      if (role == 'student' && branch.isNotEmpty && semester.isNotEmpty) {
        builtClassId = '$branch|$semester';
      }

      // Find coordinator assigned to this class
      String coordinatorId = '';
      if (role == 'student' && builtClassId.isNotEmpty) {
        final coordSnap = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'coordinator')
            .where('classId', isEqualTo: builtClassId)
            .limit(1)
            .get();
        if (coordSnap.docs.isNotEmpty) {
          coordinatorId = coordSnap.docs.first.id;
        }
      }

      final userModel = UserModel(
        id: uid,
        erpId: erpId,
        role: role,
        isApproved: false,
        createdAt: DateTime.now(),
        // Staff
        name: name,
        department: department,
        year: year,
        phone: phone,
        classId: builtClassId,
        classLabel: classLabel,
        coordinatorId: coordinatorId,
        // Student personal
        email: email,
        branch: branch,
        semester: semester,
        registerNo: registerNo,
        nameAsPerHsc: nameAsPerHsc.isNotEmpty ? nameAsPerHsc : name,
        nameAsPerAadhar: nameAsPerAadhar,
        motherName: motherName,
        abcId: abcId,
        aadharNo: aadharNo,
        dob: dob,
        mobile: mobile,
        maritalStatus: maritalStatus,
        address: address,
        state: state,
        district: district,
        taluka: taluka,
        village: village,
        fatherOrHusbandName: fatherOrHusbandName,
        guardianOccupation: guardianOccupation,
        religion: religion,
        caste: caste,
        actualCasteCategory: actualCasteCategory,
        admittedCasteCategory: admittedCasteCategory,
        otherCategory: otherCategory,
        hostelFacility: hostelFacility,
      );

      await _firestore.collection('users').doc(uid).set(userModel.toMap());
      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _friendlyAuthError(e.code);
    }
  }

  Future<UserModel?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return getCurrentUserModel();
    } on FirebaseAuthException catch (e) {
      throw _friendlyAuthError(e.code);
    }
  }

  Future<void> logout() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await NotificationService().clearTokenOnLogout(uid);
    }
    await _auth.signOut();
  }

  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(userId).update(data);
  }

  // ── Convert Firebase error codes to user-friendly English messages ──
  String _friendlyAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email address. Please check and try again.';
      case 'wrong-password':
        return 'Incorrect password. Please try again or reset your password.';
      case 'invalid-email':
        return 'The email address entered is not valid. Please check the format.';
      case 'email-already-in-use':
        return 'An account with this email already exists. Please login instead.';
      case 'weak-password':
        return 'Your password is too weak. Please use at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact your administrator.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please wait a few minutes and try again.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network and try again.';
      case 'invalid-credential':
        return 'Incorrect email or password. Please check your details and try again.';
      case 'operation-not-allowed':
        return 'Sign-in is currently unavailable. Please contact support.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  // ── Seed hardcoded principal accounts ────────────────────
  // Call this ONCE from main.dart on first launch only.
  // After seeding, comment out the call to avoid re-seeding.
  Future<void> seedPrincipalAccounts() async {
    for (final p in PrincipalConfig.principals) {
      try {
        // Check if already exists
        final existing = await _firestore
            .collection('users')
            .where('email', isEqualTo: p['email'])
            .limit(1)
            .get();
        if (existing.docs.isNotEmpty) {
          // Already seeded — update isApproved just in case
          await _firestore
              .collection('users')
              .doc(existing.docs.first.id)
              .update({'isApproved': true});
          continue;
        }

        // Create Firebase Auth account
        final credential = await _auth.createUserWithEmailAndPassword(
          email: p['email']!,
          password: p['password']!,
        );
        final uid = credential.user!.uid;

        // Save to Firestore
        await _firestore.collection('users').doc(uid).set({
          'erpId': p['erpId'],
          'name': p['name'],
          'email': p['email'],
          'role': 'principal',
          'department': p['department'] ?? 'Administration',
          'year': DateTime.now().year.toString(),
          'phone': p['phone'] ?? '',
          'address': '',
          'photoUrl': '',
          'fcmToken': '',
          'isApproved': true, // Principal is always pre-approved
          'classId': '',
          'classLabel': '',
          'coordinatorId': '',
          'createdAt': DateTime.now(),
        });

        // Sign back out after creating (we don't want to stay logged in as principal)
        await _auth.signOut();
      } catch (e) {
        // If email-already-in-use, that's fine — just skip
        if (!e.toString().contains('email-already-in-use')) {
          rethrow;
        }
      }
    }
  }
}
