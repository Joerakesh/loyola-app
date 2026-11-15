import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/storage/secure_storage.dart';
import '../models/auth_user.dart';

class AuthService {
  AuthService(this._apiClient, this._storage);
  final ApiClient _apiClient;
  final SecureStorage _storage;

  Future<AuthUser> _sessionFrom(Response response) async {
    final data = response.data;
    if (data is! Map || data['status'] != 'success') {
      throw Exception(data is Map ? data['message'] ?? 'Request failed' : 'Invalid server response');
    }
    final token = (data['authentication'] as Map?)?['token'];
    if (token is! String || token.isEmpty) throw Exception('Authentication token missing');
    await _storage.saveToken(token);
    return AuthUser.fromJson(Map<String, dynamic>.from(data['user'] as Map));
  }

  Future<AuthUser> loginWithGoogle({required String idToken}) async {
    try { return await _sessionFrom(await _apiClient.dio.post(ApiConstants.googleLogin, data: {'idToken': idToken})); }
    on DioException catch (e) { throw Exception(_message(e, 'Unable to connect to Loyola servers')); }
  }

  Future<AuthUser> loginWithErp({required String username, required String password}) async {
    try { return await _sessionFrom(await _apiClient.dio.post(ApiConstants.erpLogin, data: {'username': username.trim(), 'password': password})); }
    on DioException catch (e) { throw Exception(_message(e, 'Unable to connect to Loyola servers')); }
  }

  String _message(DioException e, String fallback) {
    final data=e.response?.data;
    return data is Map && data['message'] is String ? data['message'] as String : fallback;
  }

  Future<AuthUser> getCurrentUser() async {
    final response=await _apiClient.dio.get(ApiConstants.me);
    final data=response.data;
    if(data is! Map || data['status']!='success' || data['user'] is! Map) throw Exception('Unable to restore account');
    return AuthUser.fromJson(Map<String,dynamic>.from(data['user'] as Map));
  }

  Future<AuthUser> bindErp({required String registrationNumber, required String password}) async {
    try { final r=await _apiClient.dio.post(ApiConstants.bindErp,data:{'registrationNumber':registrationNumber.trim(),'password':password}); return _userFrom(r); }
    on DioException catch(e){throw Exception(_message(e,'Unable to verify ERP credentials. Check your connection and try again.'));}
  }
  Future<AuthUser> updateErpPassword(String password) async {
    try { return _userFrom(await _apiClient.dio.put(ApiConstants.erpPassword,data:{'password':password})); }
    on DioException catch(e){throw Exception(_message(e,'Unable to update ERP password.'));}
  }
  Future<AuthUser> unbindErp() async {
    try { return _userFrom(await _apiClient.dio.post(ApiConstants.unbindErp)); }
    on DioException catch(e){throw Exception(_message(e,'Unable to unlink ERP credentials.'));}
  }
  Future<void> unbindGoogle() async {
    try { await _apiClient.dio.post(ApiConstants.unbindGoogle); }
    on DioException catch(e){throw Exception(_message(e,'Unable to revoke Google sign-in.'));}
  }
  AuthUser _userFrom(Response r) {
    final d=r.data;
    if(d is! Map || d['status']!='success' || d['user'] is! Map) throw Exception(d is Map ? d['message'] ?? 'Request failed' : 'Invalid server response');
    return AuthUser.fromJson(Map<String,dynamic>.from(d['user'] as Map));
  }

  Future<String?> fetchStudentPhoto() async {
    final response=await _apiClient.dio.get(ApiConstants.studentPhoto);
    final data=response.data;
    if(data is! Map || data['status']!='success') throw Exception(data is Map ? data['message'] ?? 'Unable to fetch student photo' : 'Invalid response');
    final photo=(data['data'] as Map?)?['photoDataUri'];
    if(photo is! String || !photo.startsWith('data:image/')) throw Exception('Student photo is missing from ERP response');
    return photo;
  }
  Future<bool> hasValidSession() async {
    final token=await _storage.getToken();
    if(token==null || token.isEmpty) return false;
    try {
      final parts=token.split('.');
      if(parts.length!=3) return false;
      final payload=jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      return payload is Map && payload['exp'] is num && (payload['exp'] as num)*1000>DateTime.now().millisecondsSinceEpoch;
    } catch (_) { return false; }
  }
  Future<void> logout() async {
    try { await _apiClient.dio.post(ApiConstants.logout); } on DioException {} finally { await _storage.clear(); }
  }
  Future<void> clearLocalSession()=>_storage.clear();
}
