import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../app/app_router.dart';
import '../core/theme/app_theme.dart';
import '../services/auth_provider.dart';

class ErpSetupScreen extends StatefulWidget {
 const ErpSetupScreen({super.key});
 @override State<ErpSetupScreen> createState()=>_ErpSetupScreenState();
}
class _ErpSetupScreenState extends State<ErpSetupScreen> {
 final _form=GlobalKey<FormState>();final _reg=TextEditingController(),_pass=TextEditingController();bool _hide=true;
 @override void dispose(){_reg.dispose();_pass.dispose();super.dispose();}
 Future<void> _submit() async {
  if(!_form.currentState!.validate())return;
  final auth=context.read<AuthProvider>();
  final ok=await auth.bindErp(registrationNumber:_reg.text,password:_pass.text);
  if(!mounted)return;
  if(ok){context.go(AppRoutes.home);}else{ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(auth.error??'Unable to verify ERP credentials'),backgroundColor:AppTheme.crimson));}
 }
 @override Widget build(BuildContext context) {
  final auth=context.watch<AuthProvider>();
  return Scaffold(backgroundColor:AppTheme.background,appBar:AppBar(title:const Text('Connect Loyola ERP'),automaticallyImplyLeading:false),body:SafeArea(child:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:440),child:Form(key:_form,child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
   const Icon(Icons.school_rounded,size:54,color:AppTheme.gold),const SizedBox(height:20),
   const Text('One more step',textAlign:TextAlign.center,style:TextStyle(fontSize:26,fontWeight:FontWeight.w800,color:AppTheme.white)),
   const SizedBox(height:8),Text('Your Google account is signed in, but it is not connected to a Loyola ERP account. Verify your ERP credentials to access attendance, marks and other student services.',textAlign:TextAlign.center,style:TextStyle(color:AppTheme.white.withValues(alpha:.68),height:1.5)),
   const SizedBox(height:28),TextFormField(controller:_reg,autofillHints:const [AutofillHints.username],decoration:const InputDecoration(labelText:'Registration number',prefixIcon:Icon(Icons.badge_outlined)),validator:(v)=>v==null||v.trim().isEmpty?'Enter your registration number':null),
   const SizedBox(height:14),TextFormField(controller:_pass,obscureText:_hide,autofillHints:const [AutofillHints.password],decoration:InputDecoration(labelText:'ERP password',prefixIcon:const Icon(Icons.lock_outline),suffixIcon:IconButton(onPressed:()=>setState(()=>_hide=!_hide),icon:Icon(_hide?Icons.visibility_outlined:Icons.visibility_off_outlined))),validator:(v)=>v==null||v.isEmpty?'Enter your ERP password':null),
   const SizedBox(height:20),FilledButton(onPressed:auth.isLoading?null:_submit,child:auth.isLoading?const SizedBox(height:20,width:20,child:CircularProgressIndicator(strokeWidth:2)):const Text('Verify and continue')),
   const SizedBox(height:12),TextButton(onPressed:auth.isLoading?null,child:const Text('Sign out and use another Google account')),
  ]))))));
 }
}
