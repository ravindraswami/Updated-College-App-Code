import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;
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
    String admissionDate = '',
    String mobile = '',
    String maritalStatus = '',
    String gender = '',
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

      // Fix 6: Auto-assign CC based on student ID serial number range
      // Student ID format: 2025BTLT001, 2025BTLT025, etc.
      // Range 001-025 → CC1 (lowest classNumber among CCs for same classId)
      // Range 026-050 → CC2, 051-075 → CC3, etc.
      String coordinatorId = '';
      if (role == 'student' && builtClassId.isNotEmpty) {
        // Extract the trailing serial number from registerNo
        int? studentSerial;
        if (registerNo.isNotEmpty) {
          final match = RegExp(r'(\d+)$').firstMatch(registerNo);
          if (match != null) {
            studentSerial = int.tryParse(match.group(1)!);
          }
        }

        // Use Incharge-assigned slotStart/slotEnd per coordinator for matching
        // (whereIn matches both the new 'advisor' role key and the legacy
        // 'coordinator' key, so this keeps working during/after migration).
        final coordSnap = await _firestore
            .collection('users')
            .where('role', whereIn: ['advisor', 'coordinator'])
            .where('classId', isEqualTo: builtClassId)
            .get();

        if (coordSnap.docs.isNotEmpty) {
          if (studentSerial != null) {
            // Match by Incharge-assigned slotStart/slotEnd range
            String? matchedId;
            String? fallbackId;
            for (final doc in coordSnap.docs) {
              final data = doc.data();
              final slotStart = data['slotStart'] as int?;
              final slotEnd = data['slotEnd'] as int?;
              fallbackId ??= doc.id;
              if (slotStart != null &&
                  slotEnd != null &&
                  studentSerial >= slotStart &&
                  studentSerial <= slotEnd) {
                matchedId = doc.id;
                break;
              }
            }
            coordinatorId = matchedId ?? fallbackId ?? '';
          } else {
            // No serial → assign first coordinator for the class
            coordinatorId = coordSnap.docs.first.id;
          }
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
        admissionDate: admissionDate,
        mobile: mobile,
        maritalStatus: maritalStatus,
        gender: gender,
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

  // ── Seed hardcoded Dean accounts ──────────────────────────
  // Safe to call every app launch — it's idempotent (checks first).
  //
  // IMPORTANT FIX #2: this used to check Firestore FIRST (query
  // `users` by email) before touching Firebase Auth at all. That read
  // ran at app startup, before anyone is signed in — which the
  // Firestore rules correctly reject (`allow read: if isSignedIn()`),
  // since letting a signed-out client browse the `users` collection
  // would be a real security hole. That's exactly why the Dean
  // account stopped auto-appearing after the rules were published:
  // this function's very first line was being silently denied.
  //
  // Fixed by flipping the order: always go through Firebase Auth
  // FIRST (sign up, or sign in if it already exists — Auth itself
  // doesn't need Firestore permissions), and only read/write Firestore
  // AFTER that succeeds, once actually authenticated as that account.
  //
  // (Earlier fix, still true: if the Auth account survives but its
  // Firestore doc was wiped, this recreates the missing doc instead of
  // silently giving up.)
  Future<void> seedPrincipalAccounts() async {
    for (final p in PrincipalConfig.principals) {
      try {
        String uid;
        try {
          // Try creating a fresh Auth account first — this never needs
          // any Firestore permission, only Firebase Auth itself.
          final credential = await _auth.createUserWithEmailAndPassword(
            email: p['email']!,
            password: p['password']!,
          );
          uid = credential.user!.uid;
        } on FirebaseAuthException catch (authErr) {
          if (authErr.code == 'email-already-in-use') {
            // Already exists — sign in to get the uid. Also doesn't
            // need any Firestore permission.
            final credential = await _auth.signInWithEmailAndPassword(
              email: p['email']!,
              password: p['password']!,
            );
            uid = credential.user!.uid;
          } else {
            rethrow;
          }
        }

        // From here on we ARE signed in as this account, so Firestore
        // rules (isSignedIn() / isOwner(uid)) allow reading and
        // creating this exact doc.
        final doc = await _firestore.collection('users').doc(uid).get();
        if (!doc.exists) {
          await _firestore.collection('users').doc(uid).set({
            'erpId': p['erpId'],
            'name': p['name'],
            'email': p['email'],
            'role': 'dean',
            'department': p['department'] ?? 'Administration',
            'year': DateTime.now().year.toString(),
            'phone': p['phone'] ?? '',
            'address': '',
            'photoUrl': '',
            'fcmToken': '',
            'isApproved': true, // Dean is always pre-approved
            'classId': '',
            'classLabel': '',
            'coordinatorId': '',
            'createdAt': DateTime.now(),
          });
        } else if (doc.data()?['isApproved'] != true || doc.data()?['role'] != 'dean') {
          // Doc already exists — just make sure it's still marked
          // approved and on the current role key.
          await _firestore.collection('users').doc(uid).update({
            'isApproved': true,
            'role': 'dean',
          });
        }

        // Sign back out after creating (we don't want to stay logged in as Dean)
        await _auth.signOut();
      } catch (e) {
        debugPrint('[seedPrincipalAccounts] Could not seed ${p['email']}: $e');
      }
    }
  }

  // ── Dean: delete own account ──────────────────────────────
  // Removes both the Firestore profile and the Firebase Auth account
  // itself, then signs out. Firebase Auth requires a "recent" login
  // for self account-deletion — if it's been a while since the Dean
  // signed in, this throws requires-recent-login, which the caller
  // shows as "please log out and log back in, then try again".
  Future<void> deleteOwnAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not signed in.');
    final uid = user.uid;

    // Delete the Firestore profile first (allowed: isOwner(uid) is
    // still true here since we haven't deleted the Auth account yet).
    await _firestore.collection('users').doc(uid).delete();

    // Now delete the Auth account itself. If this throws
    // requires-recent-login, the Firestore doc above is already gone,
    // which is fine — the outer seeding logic will simply recreate it
    // next launch if the Auth account still exists.
    await user.delete();
  }
}
