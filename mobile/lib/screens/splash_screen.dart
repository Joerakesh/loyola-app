import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app/app_router.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/responsive.dart';
import '../services/auth_provider.dart';
import '../services/cache_warmup.dart';

class SplashScreen extends StatefulWidget {
 const SplashScreen({super.key,required this.authProvider,required this.warmup});
 final AuthProvider authProvider; final CacheWarmup warmup;
 @override State<SplashScreen> createState()=>_SplashScreenState();
}
class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
 static const Duration _minimumShowTime=Duration(milliseconds:650);
 late final AnimationController _entranceController;
 late final Animation<double> _logoScale,_textFade;
 late final Animation<Offset> _textSlide;
 @override void initState(){super.initState();
  _entranceController=AnimationController(vsync:this,duration:const Duration(milliseconds:750));
  _logoScale=CurvedAnimation(parent:_entranceController,curve:const Interval(0,.6,curve:Curves.easeOutCubic));
  _textFade=CurvedAnimation(parent:_entranceController,curve:const Interval(.45,1,curve:Curves.easeOut));
  _textSlide=Tween<Offset>(begin:const Offset(0,.15),end:Offset.zero).animate(CurvedAnimation(parent:_entranceController,curve:const Interval(.45,1,curve:Curves.easeOutCubic)));
  _entranceController.forward();_bootstrap();
 }
 @override void dispose(){_entranceController.dispose();super.dispose();}
 Future<void> _bootstrap() async {
  final start=DateTime.now();final logged=await widget.authProvider.autoLogin();
  if(logged && !widget.authProvider.requiresErpSetup) unawaited(widget.warmup.prefetchAll().catchError((e){debugPrint('Cache warmup error: $e');}));
  final elapsed=DateTime.now().difference(start);if(elapsed<_minimumShowTime)await Future.delayed(_minimumShowTime-elapsed);
  if(!mounted)return;
  context.go(!logged?AppRoutes.login:(widget.authProvider.requiresErpSetup?AppRoutes.erpSetup:AppRoutes.home));
 }
 @override Widget build(BuildContext context)=>Scaffold(body:Container(decoration:const BoxDecoration(gradient:LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[Color(0xFF111920),AppTheme.background,Color(0xFF0B1014)])),child:LayoutBuilder(builder:(context,c){
  final w=c.maxWidth,h=c.maxHeight,compact=w<360||h<560,orb=(w*.55).clamp(220.0,420.0),logo=compact?(w*.30).clamp(84.0,130.0):130.0;
  return Stack(children:[
   Positioned(top:-orb*.35,right:-orb*.25,child:Container(width:orb,height:orb,decoration:const BoxDecoration(shape:BoxShape.circle,color:Color(0x1FB9F36B)))),
   Positioned(bottom:-orb*.38,left:-orb*.30,child:Container(width:orb*1.2,height:orb*1.2,decoration:const BoxDecoration(shape:BoxShape.circle,color:Color(0x1472E4D2)))),
   Center(child:SingleChildScrollView(padding:const EdgeInsets.symmetric(vertical:32),child:Column(mainAxisSize:MainAxisSize.min,children:[
    ScaleTransition(scale:_logoScale,child:Container(width:logo,height:logo,decoration:BoxDecoration(shape:BoxShape.circle,color:AppTheme.glass,border:Border.all(color:AppTheme.crimson,width:2),boxShadow:[BoxShadow(color:AppTheme.crimson.withValues(alpha:.16),blurRadius:22,spreadRadius:1)]),child:ClipOval(child:Image.asset('assets/images/loyola_logo.png',fit:BoxFit.cover,errorBuilder:(c,e,s)=>Icon(Icons.school_rounded,size:logo*.43,color:AppTheme.white))))),
    SizedBox(height:compact?h*.04:48),
    FadeTransition(opacity:_textFade,child:SlideTransition(position:_textSlide,child:Column(children:[
     Text('LOYOLA COLLEGE',textAlign:TextAlign.center,style:TextStyle(color:AppTheme.white,fontSize:Responsive.sp(context,26),fontWeight:FontWeight.w900,letterSpacing:4.5)),
     const SizedBox(height:8),Text('C H E N N A I',textAlign:TextAlign.center,style:TextStyle(color:AppTheme.gold,fontSize:Responsive.sp(context,13),fontWeight:FontWeight.w700,letterSpacing:8)),
     SizedBox(height:Responsive.dp(context,14)),Text('Autonomous · Affiliated to University of Madras',textAlign:TextAlign.center,style:TextStyle(color:AppTheme.white38,fontSize:Responsive.sp(context,11),letterSpacing:.5,fontWeight:FontWeight.w500)),
    ]))),
    SizedBox(height:compact?h*.03:50),FadeTransition(opacity:_textFade,child:SizedBox(width:76,child:ClipRRect(borderRadius:BorderRadius.circular(4),child:const LinearProgressIndicator(minHeight:4,backgroundColor:AppTheme.outline,color:AppTheme.gold)))),
   ]))),
  ]);
 }));
}
