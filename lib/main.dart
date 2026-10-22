import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';

void main() => runApp(const PosterApp());
const mint=Color(0xFF79F0D6), gold=Color(0xFFFFD84D), dark=Color(0xFF080E19);

class PosterApp extends StatelessWidget {
 const PosterApp({super.key});
 @override Widget build(BuildContext context)=>MaterialApp(
  debugShowCheckedModeBanner:false,title:'Voting Pro',
  theme:ThemeData.dark().copyWith(scaffoldBackgroundColor:dark,
   colorScheme:ColorScheme.fromSeed(seedColor:mint,brightness:Brightness.dark)),
  home:const Editor());
}
class Editor extends StatefulWidget {const Editor({super.key}); @override State<Editor> createState()=>_EditorState();}
class _EditorState extends State<Editor>{
 final picker=ImagePicker(); final shot=ScreenshotController();
 File? a,b; Color background=const Color(0xFF064B27); bool busy=false;
 Color frameColor=gold; double frameWidth=3; double canvasRatio=.79;
 final List<String> emojis=[];
 void msg(String s)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));
 Future<void> pick(bool sideA) async {
  try { final x=await picker.pickImage(source:ImageSource.gallery,imageQuality:95);
   if(x!=null)setState(()=>sideA?a=File(x.path):b=File(x.path));
  } catch(e){msg('تصویر منتخب نہیں ہو سکی: $e');}
 }
 Future<void> save() async {
  if(busy)return; setState(()=>busy=true);
  try {final bytes=await shot.capture(pixelRatio:2.5); if(bytes==null)return;
   await Gal.putImageBytes(bytes,name:'tagda_muquabla_${DateTime.now().millisecondsSinceEpoch}');
   msg('پوسٹر گیلری میں محفوظ ہو گیا۔');
  } catch(e){msg('محفوظ نہیں ہو سکا۔ Gallery permission چیک کریں۔');}
  finally{if(mounted)setState(()=>busy=false);}
 }
 Future<void> share() async {
  try {final bytes=await shot.capture(pixelRatio:2.5); if(bytes==null)return;
   final d=await getTemporaryDirectory(); final f=File('${d.path}/tagda_muquabla.png');
   await f.writeAsBytes(bytes,flush:true);
   await Share.shareXFiles([XFile(f.path,mimeType:'image/png')],text:'Voting Pro Poster');
  } catch(e){msg('شیئر نہیں ہو سکا: $e');}
 }

 void frameTool()=>showModalBottomSheet(context:context,backgroundColor:const Color(0xFF172235),
  builder:(c)=>StatefulBuilder(builder:(c,modalSet)=>SafeArea(child:Padding(padding:const EdgeInsets.all(18),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
   const Text('Frame Settings',style:TextStyle(fontSize:19,fontWeight:FontWeight.bold)),const SizedBox(height:14),
   const Text('Frame Color'),const SizedBox(height:8),
   Wrap(spacing:12,children:[Colors.amber,Colors.white,Colors.pinkAccent,Colors.cyanAccent,Colors.redAccent,Colors.greenAccent].map((col)=>InkWell(onTap:(){setState(()=>frameColor=col);modalSet((){});},child:Container(width:35,height:35,decoration:BoxDecoration(color:col,shape:BoxShape.circle,border:Border.all(color:frameColor==col?Colors.white:Colors.transparent,width:3)))).toList()),
   const SizedBox(height:14),const Text('Frame Thickness'),
   Slider(value:frameWidth,min:1,max:10,divisions:9,label:frameWidth.toInt().toString(),onChanged:(v){setState(()=>frameWidth=v);modalSet((){});}),
   Align(alignment:Alignment.centerRight,child:FilledButton(onPressed:()=>Navigator.pop(c),child:const Text('Done')))
  ])))));
 void canvasTool()=>showModalBottomSheet(context:context,backgroundColor:const Color(0xFF172235),
  builder:(c)=>SafeArea(child:Padding(padding:const EdgeInsets.all(18),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
   const Text('Canvas Size',style:TextStyle(fontSize:19,fontWeight:FontWeight.bold)),const SizedBox(height:12),
   for(final opt in [('Poster 4:5',.8),('Square 1:1',1.0),('Story 9:16',.5625),('Landscape 16:9',1.7778)])
    ListTile(title:Text(opt.$1),trailing:canvasRatio==opt.$2?const Icon(Icons.check,color:mint):null,onTap:(){setState(()=>canvasRatio=opt.$2);Navigator.pop(c);}),
  ]))));
 void emojiTool()=>showModalBottomSheet(context:context,backgroundColor:const Color(0xFF172235),
  builder:(c)=>SafeArea(child:Padding(padding:const EdgeInsets.all(18),child:Wrap(spacing:12,runSpacing:12,children:['⭐','🔥','👑','❤️','🏆','⚡','🎉','💥','👍','🌟','😊','💯'].map((e)=>InkWell(onTap:(){setState(()=>emojis.add(e));Navigator.pop(c);},child(Container(width:52,height:52,alignment:Alignment.center,decoration:BoxDecoration(color:const Color(0xFF26354A),borderRadius:BorderRadius.circular(12)),child:Text(e,style:const TextStyle(fontSize:28))))).toList()))));


 Future<void> addText() async {
  final c=TextEditingController();
  final value=await showDialog<String>(context:context,builder:(d)=>AlertDialog(title:const Text('متن شامل کریں'),content:TextField(controller:c,maxLines:3),actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(d,c.text.trim()),child:const Text('Add'))]));
  if(value!=null&&value.isNotEmpty){setState(()=>emojis.add(value));}
 }
 Future<void> addSticker() async => emojiTool();
 void show3DBackgrounds()=>backgrounds();

 void backgrounds()=>showModalBottomSheet(context:context,backgroundColor:const Color(0xFF172235),
  builder:(c)=>Padding(padding:const EdgeInsets.all(22),child:Wrap(spacing:14,runSpacing:14,children:[
   for(final color in [const Color(0xFF064B27),const Color(0xFF102C67),const Color(0xFF7F101B),const Color(0xFF241044),const Color(0xFF111827),const Color(0xFF744210)])
    InkWell(onTap:(){setState(()=>background=color);Navigator.pop(c);},child:Container(width:50,height:50,decoration:BoxDecoration(color:color,shape:BoxShape.circle,border:Border.all(color:Colors.white,width:2))))
  ])));
 @override Widget build(BuildContext context)=>Scaffold(body:SafeArea(child:Column(children:[
  Padding(padding:const EdgeInsets.fromLTRB(14,12,14,10),child:Column(children:[
   Row(children:[const Icon(Icons.workspace_premium,color:gold,size:36),const SizedBox(width:8),
    const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
     Text('Voting Pro',style:TextStyle(fontSize:22,fontWeight:FontWeight.w900,color:gold)),
     Text('P O S T E R   M A K E R',style:TextStyle(fontSize:10,letterSpacing:2.2))
    ])),IconButton(onPressed:()=>msg('مزید سیٹنگز اگلے مرحلے میں شامل ہوں گی'),icon:const Icon(Icons.settings_outlined,color:gold,size:28))]),
   const SizedBox(height:10),Row(children:[
    Expanded(child:Container decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFF075BFF),Color(0xFF7715E8),Color(0xFFF20A9C)]),borderRadius:BorderRadius.circular(22),border:Border.all(color:gold,width:2),boxShadow:[BoxShadow(color:Colors.purple.withOpacity(.3),blurRadius:18)]),
     child:ElevatedButton.icon(onPressed:busy?null:save,icon:const Icon(Icons.download_rounded),label:Text(busy?'ذرا انتظار کریں…':'Save Poster ↓',style:const TextStyle(fontWeight:FontWeight.w900,fontSize:19)),style:ElevatedButton.styleFrom(backgroundColor:Colors.transparent,shadowColor:Colors.transparent,foregroundColor:Colors.white,padding:const EdgeInsets.symmetric(vertical:17),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(20))))),
    const SizedBox(width:9),SizedBox(width:62,height:62,child:OutlinedButton(onPressed:share,style:OutlinedButton.styleFrom(backgroundColor:const Color(0xFF1B2638),side:const BorderSide(color:Color(0xFF65758F)),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(18)),padding:EdgeInsets.zero),child:const Icon(Icons.share,size:26)))
   ])
  ])),
  Expanded(child:SingleChildScrollView(padding:const EdgeInsets.all(12),child:Column(children:[
   Screenshot(controller:shot,child:AspectRatio(aspectRatio:canvasRatio,child:Container(decoration:BoxDecoration(color:background,border:Border.all(color:frameColor,width:frameWidth),boxShadow:[BoxShadow(color:Colors.greenAccent.withOpacity(.2),blurRadius:15)]),padding:const EdgeInsets.all(7),child:Stack(children:[
   Column(children:[
    Expanded(flex:7,child:Row(children:[Expanded(child:photoSlot(true)),const SizedBox(width:6),Expanded(child:photoSlot(false))])),
    const SizedBox(height:6),Expanded(flex:3,child:Container(width:double.infinity,decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFF6B0B08),Color(0xFF120B08),Color(0xFF6B0B08)]),border:Border.all(color:gold,width:2),borderRadius:BorderRadius.circular(10)),child:Stack(alignment:Alignment.center,children:[
     const Positioned(top:0,child:Icon(Icons.workspace_premium,color:gold,size:42)),
     const Padding(padding:EdgeInsets.only(top:17),child:Text('TAGDA',style:TextStyle(fontSize:30,fontWeight:FontWeight.w900,fontStyle:FontStyle.italic,color:Color(0xFFFFE35C),shadows:[Shadow(color:Colors.black,blurRadius:4,offset:Offset(2,3))]))),
     const Positioned(bottom:7,child:Text('MUQABLA',style:TextStyle(fontSize:21,fontWeight:FontWeight.w900,fontStyle:FontStyle.italic,color:Colors.white))),
     Positioned(left:8,bottom:10,child:badge('A',const Color(0xFFB80E1A))),Positioned(right:8,bottom:10,child:badge('B',const Color(0xFF16863A)))
    ])))
   ]),
   ...emojis.asMap().entries.map((entry)=>Positioned(left:10+(entry.key%4)*35,top:12+(entry.key%3)*38,child:GestureDetector(onLongPress:()=>setState(()=>emojis.remove(entry.value)),child:Text(entry.value,style:const TextStyle(fontSize:30,shadows:[Shadow(color:Colors.black,blurRadius:4)]))))),
  ]))),
   const SizedBox(height:10),const Text('A یا B منتخب کریں، پھر گیلری سے تصویر لگائیں',style:TextStyle(color:Colors.white70,fontSize:12))
  ]))),
  Container(padding:const EdgeInsets.fromLTRB(8,10,8,14),decoration:const BoxDecoration(color:Color(0xFF101827),border:Border(top:BorderSide(color:Color(0xFF293345)))),child:SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:[
   tool('A','Add A Photo',()=>pick(true)),tool('B','Add B Photo',()=>pick(false)),tool('T','Text',addText),tool('✦','3D Backgrounds',show3DBackgrounds),tool('☻','Stickers',addSticker),tool('▣','Frame',frameTool),tool('😊','Emoji',emojiTool),tool('▱','Canvas',canvasTool),tool('▦','Background',backgrounds),tool('↗','Share Poster',share)
  ])))
 ])));
 Widget photoSlot(bool sideA){final f=sideA?a:b;return GestureDetector(onTap:()=>pick(sideA),child:Container(clipBehavior:Clip.antiAlias,decoration:BoxDecoration(color:const Color(0xFF18202B),border:Border.all(color:gold,width:3),borderRadius:BorderRadius.circular(8)),child:Stack(fit:StackFit.expand,children:[
  if(f!=null)Image.file(f,fit:BoxFit.cover) else const Column(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(Icons.add_photo_alternate_outlined,color:mint,size:34),SizedBox(height:8),Text('تصویر شامل کریں',textAlign:TextAlign.center,style:TextStyle(fontSize:12,color:Colors.white70))]),
  Positioned(left:0,right:0,bottom:0,child:Container(color:sideA?const Color(0xCCB40E1B):const Color(0xCC087B37),padding:const EdgeInsets.all(5),child:Text(sideA?'A SIDE':'B SIDE',textAlign:TextAlign.center,style:const TextStyle(fontWeight:FontWeight.w900,letterSpacing:1.5))))
 ])));}
 Widget badge(String t,Color c)=>Container(width:48,height:42,decoration:BoxDecoration(color:c,shape:BoxShape.circle,border:Border.all(color:gold,width:3)),alignment:Alignment.center,child:Text(t,style:const TextStyle(fontSize:26,fontWeight:FontWeight.w900)));
 Widget tool(String icon,String title,VoidCallback tap)=>Container(width:142,height:112,margin:const EdgeInsets.symmetric(horizontal:5),child:Material(color:const Color(0xFF1B2638),borderRadius:BorderRadius.circular(20),child:InkWell(onTap:tap,borderRadius:BorderRadius.circular(20),child:Container(decoration:BoxDecoration(borderRadius:BorderRadius.circular(20),border:Border.all(color:const Color(0xFF4A5870),width:1.5),gradient:const LinearGradient(colors:[Color(0xFF26354A),Color(0xFF111A29)],begin:Alignment.topLeft,end:Alignment.bottomRight)),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Text(icon,style:const TextStyle(color:mint,fontSize:33,fontWeight:FontWeight.w900)),const SizedBox(height:7),Text(title,textAlign:TextAlign.center,style:const TextStyle(fontSize:13,fontWeight:FontWeight.w800))]))));
}
