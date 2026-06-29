import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:shared_preferences/shared_preferences.dart';

import '../../apis/api_endpoints.dart';
import '../../models/user_profile.dart';
import '../../constants/constants.dart';
import '../modules/auth/controllers/auth_controller.dart';
import '../modules/bottomnav/views/bottomnav_view.dart';
import '../modules/messanger/views/messages/components/firestore_service.dart';
import '../modules/registersteps/controllers/registersteps_controller.dart';

class GoogleAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  
  static final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  static final Dio _dio = Dio();

  /// Google Sign-In করার জন্য main method
  static Future<void> signInWithGoogle() async {
    try {
      // Loading state show করা
      Get.find<RegisterstepsController>().isLoading.value = true;

      // Sign out first to ensure fresh login
      await _googleSignIn.signOut();
      await _auth.signOut();
      
      // Google Sign-In process
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User cancelled the sign-in
        Get.find<RegisterstepsController>().isLoading.value = false;
        return;
      }

      // Google authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Create a new credential
       final credential = firebase_auth.GoogleAuthProvider.credential(
         accessToken: googleAuth.accessToken,
         idToken: googleAuth.idToken,
       );

      // Sign in to Firebase with the Google credential
       final firebase_auth.UserCredential userCredential = await _auth.signInWithCredential(credential);
       final firebase_auth.User? firebaseUser = userCredential.user;
      
      print('Google Sign-In successful:');
      print('Name: ${googleUser.displayName}');
      print('Email: ${googleUser.email}');
      print('Photo: ${googleUser.photoUrl}');
      
      if (firebaseUser != null && googleUser.email.isNotEmpty) {
        print('Firebase User: ${firebaseUser.uid}');
        print('Firebase Email: ${firebaseUser.email}');
        
        // Validate required data
        if (firebaseUser.uid.isEmpty) {
          throw Exception('Google ID is missing');
        }
        
        if (googleUser.email.isEmpty) {
          throw Exception('Email is missing');
        }
        
        // Backend API call করা
        await _sendGoogleDataToBackend(
          name: googleUser.displayName ?? '',
          email: googleUser.email,
          photoUrl: googleUser.photoUrl,
          googleId: firebaseUser.uid,
          googleToken: googleAuth.accessToken ?? '',
        );
      } else {
        throw Exception('Google authentication failed - missing user data');
      }

    } catch (error) {
      print('Google Sign-In Error: $error');
      Get.find<RegisterstepsController>().isLoading.value = false;
      
      String errorMessage = "Google Sign-In failed. Please try again.";
      
      // Specific error handling
      if (error.toString().contains('network_error')) {
        errorMessage = "Network error. Please check your internet connection.";
      } else if (error.toString().contains('sign_in_canceled')) {
        errorMessage = "Sign-in was cancelled.";
      } else if (error.toString().contains('sign_in_failed')) {
        errorMessage = "Google Sign-In failed. Please try again.";
      } else if (error.toString().contains('account_exists_with_different_credential')) {
        errorMessage = "An account already exists with a different sign-in method.";
      }
      
      Fluttertoast.showToast(
        msg: errorMessage,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  /// Backend API তে Google user data পাঠানো
  static Future<void> _sendGoogleDataToBackend({
    required String name,
    required String email,
    String? photoUrl,
    required String googleId,
    required String googleToken,
  }) async {
    try {
      // Validate input data
      if (email.isEmpty) {
        throw Exception('Email is required');
      }
      
      if (googleId.isEmpty) {
        throw Exception('Google ID is required');
      }
      
      if (googleToken.isEmpty) {
        throw Exception('Google token is required');
      }
      
      // API data prepare করা
      // Clean photoUrl to remove any extra parameters and unwanted characters
      String? cleanPhotoUrl;
      if (photoUrl?.isNotEmpty == true) {
        print('Step 1 - Original: $photoUrl');
        print('Original photoUrl length: ${photoUrl!.length}');
        print('Original photoUrl characters: ${photoUrl.split('').join(', ')}');
        
        // Step 1: Remove backticks and quotes first - handle all variations
        cleanPhotoUrl = photoUrl
            .trim()
            .replaceAll('`', '')
            .replaceAll('"', '')
            .replaceAll("'", '')
            .replaceAll(' ', ''); // Remove any spaces too
        print('Step 2 - After removing quotes and spaces: $cleanPhotoUrl');
        
        // Step 2: Remove size parameters (everything after =)
        cleanPhotoUrl = cleanPhotoUrl.replaceAll(RegExp(r'=.*$'), '');
        print('Step 3 - After removing size params: $cleanPhotoUrl');
        
        // Step 3: Remove any trailing commas, spaces, or special characters
        cleanPhotoUrl = cleanPhotoUrl.replaceAll(RegExp(r'[,\s]+$'), '');
        print('Step 4 - After removing trailing chars: $cleanPhotoUrl');
        
        // Step 4: Trim any remaining whitespace
        cleanPhotoUrl = cleanPhotoUrl.trim();
        print('Step 5 - After final trim: $cleanPhotoUrl');
        
        // Ensure it's a valid URL
        if (cleanPhotoUrl.isEmpty || !cleanPhotoUrl.startsWith('http')) {
          cleanPhotoUrl = null;
        }
        
        print('Final cleaned photoUrl: $cleanPhotoUrl');
      }
      
      final data = {
        'name': name.isNotEmpty ? name : null,
        'email': email,
        'profile_image_url': cleanPhotoUrl,
        'google_id': googleId,
        'google_token': googleToken,
      };

      print('Original photoUrl: $photoUrl');
      print('Cleaned photoUrl: $cleanPhotoUrl');
      print('Data object profile_image_url: ${data['profile_image_url']}');
      print('Data object profile_image_url length: ${data['profile_image_url']?.length}');
      print('Data object profile_image_url characters: ${data['profile_image_url']?.split('').join(', ')}');
      print('Sending Google data to backend: ${jsonEncode(data)}');

      // Backend API call
      final response = await _dio.post(kLoginGoogle, data: data);
      
      print('Google Login API Response: ${response.data}');

      if (response.statusCode == 200) {
        // Response data parse করা
        final responseData = response.data;
        
        if (responseData['success'] == true) {
          print('Backend response success: true');
          
          // User profile data save করা
          final authController = Get.find<AuthController>();
          
          // Create UserProfile object from response
          final userProfileData = {
            'success': true,
            'message': responseData['message'],
            'token': responseData['token'],
            'user': responseData['user'],
          };
          
          print('Creating UserProfile from response data...');
          authController.userProfile.value = UserProfile.fromJson(userProfileData);
          
          // SharedPreferences এ save করা
          print('Saving to SharedPreferences...');
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('profile', jsonEncode(userProfileData));
          
          print('Google login successful: ${authController.userProfile.value.user?.name}');
          
          // Device token create করা (existing phone login এর মতো)
          print('Creating device token...');
          await _createDeviceToken();
          
          // Initialize FirestoreService (phone login এর মতো)
          print('Initializing FirestoreService...');
          Get.put(FirestoreService());
          
          // Show active frame (phone login এর মতো)
          print('Showing active frame...');
          homeController.showActiveFrame();
          
          // Success message
          print('Showing success toast...');
          Fluttertoast.showToast(
            msg: "Google Sign-In successful!",
            backgroundColor: Colors.green,
            textColor: Colors.white,
          );
          
          // Navigate to home screen
          print('Setting loading to false and navigating to BottomnavView...');
          Get.find<RegisterstepsController>().isLoading.value = false;
          Get.to(BottomnavView(), transition: Transition.rightToLeft);
          print('Navigation completed!');
          
        } else {
          throw Exception(responseData['message'] ?? 'Login failed');
        }
      } else {
        throw Exception('API call failed with status: ${response.statusCode}');
      }
      
    } catch (error) {
      print('Backend API Error: $error');
      Get.find<RegisterstepsController>().isLoading.value = false;
      
      String errorMessage = "Login failed. Please try again.";
      
      // Specific error handling for different types of errors
      if (error is DioException) {
        switch (error.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.sendTimeout:
          case DioExceptionType.receiveTimeout:
            errorMessage = "Connection timeout. Please check your internet connection.";
            break;
          case DioExceptionType.badResponse:
            if (error.response?.statusCode == 400) {
              errorMessage = error.response?.data['message'] ?? "Invalid request data.";
            } else if (error.response?.statusCode == 401) {
              errorMessage = "Authentication failed. Please try again.";
            } else if (error.response?.statusCode == 422) {
              errorMessage = "Validation error. Please check your data.";
            } else if (error.response?.statusCode == 500) {
              errorMessage = "Server error. Please try again later.";
            } else {
              errorMessage = "Login failed. Please try again.";
            }
            break;
          case DioExceptionType.connectionError:
            errorMessage = "Network error. Please check your internet connection.";
            break;
          default:
            errorMessage = "Login failed. Please try again.";
        }
      } else if (error.toString().contains('FormatException')) {
        errorMessage = "Invalid response format from server.";
      } else if (error.toString().contains('SocketException')) {
        errorMessage = "Network error. Please check your internet connection.";
      }
      
      Fluttertoast.showToast(
        msg: errorMessage,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  /// Device token create করা (existing phone login থেকে copy)
  static Future<void> _createDeviceToken() async {
    try {
      final authController = Get.find<AuthController>();
      final registerController = Get.find<RegisterstepsController>();
      
      // Device token create করার জন্য existing method call করা
      registerController.createDeviceToken();
      
    } catch (error) {
      print('Device token creation error: $error');
    }
  }

  /// Google Sign-Out করার জন্য method
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      print('Google Sign-Out successful');
    } catch (error) {
      print('Google Sign-Out Error: $error');
    }
  }

  /// Current Google user check করা
  static Future<GoogleSignInAccount?> getCurrentUser() async {
    // Check both Google Sign-In and Firebase Auth
    final firebase_auth.User? firebaseUser = _auth.currentUser;
    final GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently();
    
    if (firebaseUser != null && googleUser != null) {
      return googleUser;
    }
    
    return null;
  }

  /// Google Sign-In configured কিনা check করা
  static Future<bool> isSignedIn() async {
     final bool googleSignedIn = await _googleSignIn.isSignedIn();
     final firebase_auth.User? firebaseUser = _auth.currentUser;
    
    return googleSignedIn && firebaseUser != null;
  }
}