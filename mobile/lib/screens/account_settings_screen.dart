import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../app/app_router.dart';
import '../core/theme/app_theme.dart';
import '../services/auth_provider.dart';

class AccountSettingsScreen extends StatefulWidget {
 const AccountSettingsScreen({super.key});
 @override State<AccountSettingsScreen> createState()=>_AccountSettingsScreenState();
}
class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
 final _registration=TextEditingController(),_password=TextEditingController();bool _hide=true;
 @override void dispose(){_registration.dispose();_password.dispose();super.dispose();}
 Future<void> _changePassword() async {
  final value=_password.text;if(value.isEmpty)return;
  final auth=context.read<AuthProvider>();final ok=await auth.updateErpPassword(value);
  if(!mounted)return;_password.clear();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(ok?'ERP password updated and verified':auth.error??'Unable to update password')));
 }
 Future<void> _unlinkErp() async {
  final yes=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:const Text('Unlink ERP account?'),content:const Text('Academic data access will stop until you connect ERP credentials again.'),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Unlink'))]));
  if(yes!=true||!mounted)return;final auth=context.read<AuthProvider>();final ok=await auth.unbindErp();
  if(!mounted)return;if(ok)context.go(AppRoutes.erpSetup);else ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(auth.error??'Unable to unlink ERP')));
 }
 Future<void> _revokeGoogle() async {
  final yes=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:const Text('Revoke Google sign-in?'),content:const Text('This removes Google sign-in from this account. You will be signed out and can access this existing account with ERP credentials. Signing in with another Google account creates a separate app account.'),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Revoke'))]));
  if(yes!=true||!mounted)return;final auth=context.read<AuthProvider>();final ok=await auth.unbindGoogle();
  if(!mounted)return;if(!ok)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(auth.error??'Unable to revoke Google sign-in')));else context.go(AppRoutes.login);
 }
 Future<void> _changeGoogle() async {
  await context.read<AuthProvider>().logout();if(!mounted)return;context.go(AppRoutes.login);
 }
 @override Widget build(BuildContext context) {
  final auth=context.watch<AuthProvider>();final user=auth.user;
  return Scaffold(backgroundColor:AppTheme.background,appBar:AppBar(title:const Text('Account & security')),body:ListView(padding:const EdgeInsets.all(18),children:[
   _section('GOOGLE ACCOUNT',[
    ListTile(leading:const Icon(Icons.account_circle_outlined),title:Text(user?.email.isNotEmpty==true?user!.email:'Google account'),subtitle:Text(user?.googleId.isNotEmpty==true?'Connected':'Not connected'),trailing:const Icon(Icons.verified_user_outlined)),
    ListTile(leading:const Icon(Icons.swap_horiz),title:const Text('Change Google account'),subtitle:const Text('Sign out and sign in with a different Google account'),onTap:_changeGoogle),
    ListTile(leading:const Icon(Icons.link_off),title:const Text('Revoke Google sign-in'),subtitle:const Text('Available when ERP sign-in is configured'),enabled:user?.erpLinked==true,onTap:auth.isLoading?null:_revokeGoogle),
   ]),
   const SizedBox(height:16),
   _section('LOYOLA ERP ACCOUNT',[
    ListTile(leading:const Icon(Icons.school_outlined),title:const Text('ERP connection'),subtitle:Text(user?.erpLinked==true?'Connected':'Not connected'),trailing:Icon(user?.erpLinked==true?Icons.check_circle:Icons.error_outline,color:user?.erpLinked==true?AppTheme.gold:null)),
    if(user?.erpLinked==true) ...[
     const SizedBox(height:8),TextField(controller:_password,obscureText:_hide,decoration:InputDecoration(labelText:'New ERP password',prefixIcon:const Icon(Icons.lock_outline),suffixIcon:IconButton(onPressed:()=>setState(()=>_hide=!_hide),icon:Icon(_hide?Icons.visibility:Icons.visibility_off)))),
     const SizedBox(height:10),FilledButton.tonal(onPressed:auth.isLoading?_noop:_changePassword,child:const Text('Verify and update password')),
     ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.edit_outlined),title:const Text('Change ERP account'),subtitle:const Text('Replace the registration number and password'),onTap:()=>_showChangeErp(context)),
     ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.link_off),title:const Text('Unlink ERP account'),onTap:auth.isLoading?null:_unlinkErp),
    ] else const Padding(padding:EdgeInsets.all(12),child:Text('Connect ERP to enable student services and account recovery.')),
   ]),
   const SizedBox(height:16),
   _section('SESSION',[
    ListTile(leading:const Icon(Icons.logout),title:const Text('Sign out'),onTap:()=>auth.logout().then((_) {if(context.mounted)context.go(AppRoutes.login);})),
   ]),
   if(auth.error!=null)Padding(padding:const EdgeInsets.all(12),child:Text(auth.error!,style:const TextStyle(color:Colors.redAccent))),
  ]));
 }
 void _noop(){}
 Future<void> _showChangeErp(BuildContext context) async {
  final form=GlobalKey<FormState>();final reg=TextEditingController(),pass=TextEditingController();
  final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:const Text('Change ERP account'),content:Form(key:form,child:Column(mainAxisSize:MainAxisSize.min,children:[
   TextFormField(controller:reg,decoration:const InputDecoration(labelText:'Registration number'),validator:(v)=>v==null||v.trim().isEmpty?'Required':null),
   TextFormField(controller:pass,obscureText:true,decoration:const InputDecoration(labelText:'ERP password'),validator:(v)=>v==null||v.isEmpty?'Required':null),
  ])),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(c,form.currentState!.validate()),child:const Text('Verify'))]));
  if(ok==true&&mounted){final auth=context.read<AuthProvider>();final success=await auth.bindErp(registrationNumber:reg.text,password:pass.text);if(!mounted)return;ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(success?'ERP account updated':auth.error??'Unable to update ERP')));}
  reg.dispose();pass.dispose();
 }
 Widget _section(String title,List<Widget> children)=>Card(color:AppTheme.glass,child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Padding(padding:const EdgeInsets.all(8),child:Text(title,style:const TextStyle(color:AppTheme.gold,fontSize:11,fontWeight:FontWeight.w800,letterSpacing:1.2))),...children])));
}
