import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/cache/data_cache.dart';
import '../models/auth_user.dart';
import 'auth_service.dart';
import 'google_auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._authService,this._googleAuthService);
  final AuthService _authService;
  final GoogleAuthService _googleAuthService;
  bool _isLoading=false,_isAuthenticated=false;
  String? _error,_studentPhotoDataUri;
  AuthUser? _user;
  bool get isLoading=>_isLoading;
  bool get isAuthenticated=>_isAuthenticated;
  String? get error=>_error;
  AuthUser? get user=>_user;
  String? get studentPhotoDataUri=>_studentPhotoDataUri;
  bool get requiresErpSetup=>_isAuthenticated && _user?.erpLinked!=true;
  String? get profileAvatarUrl {
    final p=_studentPhotoDataUri;
    if(p!=null && p.startsWith('data:image/')) return p;
    final g=_user?.avatarUrl?.trim();
    return g==null || g.isEmpty ? null : g;
  }
  Future<void> refreshStudentPhoto() async { if(_user?.erpLinked==true) await _refreshStudentPhoto(); }
  Future<bool> autoLogin() async {
    try {
      if(!await _authService.hasValidSession()){await _clearFailedSession();return false;}
      _user=await _authService.getCurrentUser(); _isAuthenticated=true;
      await _loadCachedStudentPhoto();
      if(_user?.erpLinked==true) unawaited(_refreshStudentPhoto());
      _error=null; notifyListeners(); return true;
    } catch(e){debugPrint('AUTO-LOGIN FAILED: $e');await _clearFailedSession();return false;}
  }
  Future<void> _clearFailedSession() async {
    await _authService.clearLocalSession(); await DataCache.instance.clearAll();
    _user=null;_studentPhotoDataUri=null;_isAuthenticated=false;notifyListeners();
  }
  Future<void> loginWithGoogle() async {
    _setLoading(true);_error=null;
    try {
      final idToken=await _googleAuthService.signInWithGoogle();
      _user=await _authService.loginWithGoogle(idToken:idToken);
      _isAuthenticated=true; await DataCache.instance.clearAll();
      if(_user!.erpLinked) unawaited(_refreshStudentPhoto());
    } catch(e){debugPrint('GOOGLE LOGIN ERROR: $e');_error=_friendly(e);_isAuthenticated=false;}
    finally{_setLoading(false);}
  }
  Future<void> loginWithErp({required String username,required String password}) async {
    _setLoading(true);_error=null;
    try {
      _user=await _authService.loginWithErp(username:username,password:password);
      _isAuthenticated=true; await DataCache.instance.clearAll();
      if(_user!.erpLinked) unawaited(_refreshStudentPhoto());
    } catch(e){_error=_friendly(e);_isAuthenticated=false;}
    finally{_setLoading(false);}
  }
  Future<bool> bindErp({required String registrationNumber,required String password}) async {
    _setLoading(true);_error=null;
    try {
      _user=await _authService.bindErp(registrationNumber:registrationNumber,password:password);
      await DataCache.instance.clearAll();_studentPhotoDataUri=null;
      unawaited(_refreshStudentPhoto());return true;
    } catch(e){_error=_friendly(e);return false;}
    finally{_setLoading(false);notifyListeners();}
  }
  Future<bool> updateErpPassword(String password) async {
    _setLoading(true);_error=null;
    try{_user=await _authService.updateErpPassword(password);return true;}
    catch(e){_error=_friendly(e);return false;}
    finally{_setLoading(false);notifyListeners();}
  }
  Future<bool> unbindErp() async {
    _setLoading(true);_error=null;
    try{_user=await _authService.unbindErp();await DataCache.instance.clearAll();_studentPhotoDataUri=null;return true;}
    catch(e){_error=_friendly(e);return false;}
    finally{_setLoading(false);notifyListeners();}
  }
  Future<bool> unbindGoogle() async {
    _setLoading(true);_error=null;
    try{await _authService.unbindGoogle();await logout();return true;}
    catch(e){_error=_friendly(e);_setLoading(false);return false;}
  }
  String _friendly(Object e)=>e.toString().replaceFirst('Exception: ','');
  Future<void> logout() async {
    await _authService.logout();await _googleAuthService.signOut();await DataCache.instance.clearAll();
    _user=null;_studentPhotoDataUri=null;_isAuthenticated=false;notifyListeners();
  }
  Future<void> _loadCachedStudentPhoto() async {
    final c=await DataCache.instance.load(CacheKeys.studentPhoto);
    if(c is String && c.startsWith('data:image/')) _studentPhotoDataUri=c;
  }
  Future<void> _refreshStudentPhoto() async {
    try{final p=await _authService.fetchStudentPhoto();if(p==null)return;await DataCache.instance.save(CacheKeys.studentPhoto,p);_studentPhotoDataUri=p;notifyListeners();}
    catch(e){debugPrint('STUDENT PHOTO FETCH FAILED: $e');}
  }
  void _setLoading(bool v){_isLoading=v;notifyListeners();}
}
