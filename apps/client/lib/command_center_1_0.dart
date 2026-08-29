import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const bg = Color(0xFF070A0F), panel = Color(0xFF10151D), muted = Color(0xFF8B98A8), green = Color(0xFF48E08A), orange = Color(0xFFFF7043);

void main() => runApp(const BennuApp());

class BennuApp extends StatelessWidget {
  const BennuApp({super.key});
  @override Widget build(BuildContext context) => MaterialApp(
    title: 'Bennu OS', debugShowCheckedModeBanner: false, locale: const Locale('pt','PT'),
    supportedLocales: const [Locale('pt','PT'), Locale('en','US')], localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: ThemeData(useMaterial3:true, brightness:Brightness.dark, colorScheme:ColorScheme.fromSeed(seedColor:orange,brightness:Brightness.dark),scaffoldBackgroundColor:bg,cardTheme:CardThemeData(color:panel,elevation:0)),
    home: const Shell(),
  );
}

class Api {
  Api(this.url,this.token); final String url, token;
  Future<Map<String,dynamic>> dashboard() async {
    if (url.trim().isEmpty) throw Exception('Servidor Bennu não configurado');
    final h=<String,String>{'Accept':'application/json'};
    if(token.trim().isNotEmpty) h['Authorization']='Bearer ${token.trim()}';
    final r=await http.get(Uri.parse('${url.replaceFirst(RegExp(r'/+$'),'')}/api/v1/mobile/dashboard'),headers:h).timeout(const Duration(seconds:10));
    if(r.statusCode!=200) throw Exception('Servidor respondeu HTTP ${r.statusCode}');
    return jsonDecode(r.body) as Map<String,dynamic>;
  }
}

class Shell extends StatefulWidget { const Shell({super.key}); @override State<Shell> createState()=>_ShellState(); }
class _ShellState extends State<Shell> {
  int index=0; String url='',token=''; bool loading=true;
  static const titles=['Visão geral','IA & Agentes','Segurança','Negócios','Vendas','Cloud','Operações','Marketplace','Definições'];
  static const icons=[Icons.grid_view_rounded,Icons.psychology_rounded,Icons.shield_rounded,Icons.business_center_rounded,Icons.point_of_sale_rounded,Icons.cloud_rounded,Icons.hub_rounded,Icons.storefront_rounded,Icons.settings_rounded];
  @override void initState(){super.initState(); load();}
  Future<void> load() async { final p=await SharedPreferences.getInstance(); if(!mounted)return; setState((){url=p.getString('bennu_api_url')??'';token=p.getString('bennu_api_token')??'';loading=false;}); }
  Future<void> save(String u,String t) async { final p=await SharedPreferences.getInstance(); await p.setString('bennu_api_url',u.trim().replaceFirst(RegExp(r'/+$'),'')); await p.setString('bennu_api_token',t.trim()); if(mounted)setState((){url=u.trim().replaceFirst(RegExp(r'/+$'),'');token=t.trim();}); }
  Widget page()=>index==8?SettingsPage(url:url,token:token,onSave:save):LivePage(title:titles[index],icon:icons[index],api:Api(url,token));
  @override Widget build(BuildContext c){ if(loading)return const Scaffold(body:Center(child:CircularProgressIndicator())); final wide=MediaQuery.sizeOf(c).width>=900; if(wide)return Scaffold(body:Row(children:[Rail(selected:index,onSelect:(v)=>setState(()=>index=v)),const VerticalDivider(width:1),Expanded(child:page())])); return Scaffold(appBar:AppBar(title:Text(titles[index],style:const TextStyle(fontWeight:FontWeight.w900)),actions:[Icon(url.isEmpty?Icons.cloud_off:Icons.lock,color:url.isEmpty?Colors.orangeAccent:green),const SizedBox(width:14)]),body:page(),bottomNavigationBar:NavigationBar(selectedIndex:index.clamp(0,4),onDestinationSelected:(v)=>setState(()=>index=v),destinations:[for(int i=0;i<5;i++)NavigationDestination(icon:Icon(icons[i]),label:titles[i].split(' ').first)])); }
}

class Rail extends StatelessWidget { const Rail({super.key,required this.selected,required this.onSelect}); final int selected; final ValueChanged<int> onSelect;
  @override Widget build(BuildContext c)=>Container(width:238,color:const Color(0xFF0B0F15),child:SafeArea(child:Column(children:[const Padding(padding:EdgeInsets.all(20),child:Row(children:[Icon(Icons.local_fire_department_rounded,color:orange,size:36),SizedBox(width:10),Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('BENNU',style:TextStyle(fontWeight:FontWeight.w900,letterSpacing:2)),Text('PRIVATE OS',style:TextStyle(color:muted,fontSize:10,letterSpacing:1.5))])])),Expanded(child:ListView.builder(itemCount:_ShellState.titles.length,itemBuilder:(_,i)=>ListTile(leading:Icon(_ShellState.icons[i],color:i==selected?orange:muted),title:Text(_ShellState.titles[i],style:TextStyle(color:i==selected?Colors.white:muted,fontSize:13,fontWeight:i==selected?FontWeight.w800:FontWeight.w500)),selected:i==selected,selectedTileColor:const Color(0xFF1D232C),onTap:()=>onSelect(i))),const Padding(padding:EdgeInsets.all(16),child:Row(children:[Icon(Icons.lock,size:15,color:green),SizedBox(width:7),Text('PRIVATE • OWNER CONTROLLED',style:TextStyle(color:green,fontSize:9,letterSpacing:.8))]))]))); }
}

class LivePage extends StatefulWidget { const LivePage({super.key,required this.title,required this.icon,required this.api}); final String title; final IconData icon; final Api api; @override State<LivePage> createState()=>_LivePageState(); }
class _LivePageState extends State<LivePage>{ Map<String,dynamic>? d; String? error; bool busy=false;
  @override void initState(){super.initState();refresh();}
  Future<void> refresh()async{if(widget.api.url.isEmpty){setState(()=>error=null);return;}setState(()=>busy=true);try{final x=await widget.api.dashboard();if(mounted)setState((){d=x;error=null;});}catch(e){if(mounted)setState(()=>error=e.toString().replaceFirst('Exception: ',''));}finally{if(mounted)setState(()=>busy=false);}}
  int s(String k)=>((d?['summary'] as Map?)?[k]??0) as int;
  Map<String,dynamic> m(String k)=>Map<String,dynamic>.from(d?[k]??{});
  @override Widget build(BuildContext c)=>Frame(title:widget.title,subtitle:'Bennu OS • telemetria real da plataforma',action:IconButton(onPressed:busy?null:refresh,icon:const Icon(Icons.refresh)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Header(icon:widget.icon,online:d!=null,error:error,busy:busy,version:d?['version']?.toString()??'—'),
    const SizedBox(height:14),
    if(widget.api.url.isEmpty)const Info(title:'Ligar ao Core',text:'Em Definições indique o endereço do Bennu Core. No Android use o IP ou domínio do servidor; não use localhost.',icon:Icons.link),
    if(error!=null)Info(title:'Dados indisponíveis',text:error!,icon:Icons.warning_amber_rounded),
    if(d!=null)...[
      Grid(cells:[('Agentes',s('agents'),Icons.smart_toy),('Tarefas',s('tasks'),Icons.task_alt),('Leads',s('leads'),Icons.people_alt),('Oportunidades',s('opportunities'),Icons.trending_up),('Campanhas',s('campaigns'),Icons.campaign),('Produtos',s('products'),Icons.storefront),('Deployments',s('deployments'),Icons.cloud),('Eventos',s('operation_events'),Icons.bolt)]),
      const SizedBox(height:12),
      Row(children:[Expanded(child:Bars(title:'Tarefas por estado',values:m('task_status'))),const SizedBox(width:10),Expanded(child:Bars(title:'Agentes por estado',values:m('agent_status')))]),
      const SizedBox(height:10),
      Row(children:[Expanded(child:Bars(title:'Agentes por função',values:m('agent_roles'))),const SizedBox(width:10),Expanded(child:Bars(title:'Acessos',values:m('access_status')))]),
      const SizedBox(height:10),
      Bars(title:'Oportunidades por etapa',values:m('opportunity_stages')),
      const SizedBox(height:12),
      Info(title:'Origem dos indicadores',text:'Dados provenientes do Bennu Core, base de dados e operações. A interface não cria métricas fictícias. Atualizado ${d?['timestamp']??'—'}.',icon:Icons.verified_user),
    ] else if(widget.api.url.isNotEmpty&&error==null)const Padding(padding:EdgeInsets.all(40),child:Center(child:CircularProgressIndicator())),
  ]));
}

class Header extends StatelessWidget{const Header({super.key,required this.icon,required this.online,required this.error,required this.busy,required this.version});final IconData icon;final bool online,busy;final String? error,version;@override Widget build(BuildContext c)=>Card(child:Padding(padding:const EdgeInsets.all(20),child:Row(children:[Container(width:54,height:54,decoration:BoxDecoration(color:orange.withValues(alpha:.14),borderRadius:BorderRadius.circular(17)),child:Icon(icon,color:orange,size:30)),const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('BENNU COMMAND CENTER',style:TextStyle(fontSize:18,fontWeight:FontWeight.w900,letterSpacing:1)),const SizedBox(height:4),Text(busy?'A sincronizar…':online?'Online • dados reais':'Privado • servidor não ligado',style:const TextStyle(color:muted)),const SizedBox(height:7),Row(children:[Icon(Icons.circle,size:8,color:online?green:Colors.orangeAccent),const SizedBox(width:6),Text(online?'CORE $version':'LOCAL / PRIVATE',style:const TextStyle(color:muted,fontSize:10,letterSpacing:1))])]))]));}

class Grid extends StatelessWidget{const Grid({super.key,required this.cells});final List<(String,int,IconData)> cells;@override Widget build(BuildContext c)=>LayoutBuilder(builder:(_,x){final cols=x.maxWidth>=900?4:x.maxWidth>=560?3:2;return GridView.count(crossAxisCount:cols,shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisSpacing:10,mainAxisSpacing:10,childAspectRatio:1.45,children:[for(final e in cells)Metric(label:e.$1,value:'${e.$2}',icon:e.$3)]});}}
class Metric extends StatelessWidget{const Metric({super.key,required this.label,required this.value,required this.icon});final String label,value;final IconData icon;@override Widget build(BuildContext c)=>Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon,color:orange),const Spacer(),Text(label,style:const TextStyle(color:muted,fontSize:11)),Text(value,style:const TextStyle(fontSize:25,fontWeight:FontWeight.w900))])));}

class Bars extends StatelessWidget{const Bars({super.key,required this.title,required this.values});final String title;final Map<String,dynamic> values;@override Widget build(BuildContext c){final es=values.entries.toList()..sort((a,b)=>(b.value as num).compareTo(a.value as num));final max=es.isEmpty?1.0:es.map((e)=>(e.value as num).toDouble()).reduce((a,b)=>a>b?a:b);return Card(child:Padding(padding:const EdgeInsets.all(15),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontWeight:FontWeight.w800)),const SizedBox(height:12),if(es.isEmpty)const Text('Sem dados registados.',style:TextStyle(color:muted,fontSize:11))else for(final e in es.take(7))Padding(padding:const EdgeInsets.only(bottom:9),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Expanded(child:Text(e.key,style:const TextStyle(color:muted,fontSize:10))),Text('${e.value}',style:const TextStyle(fontSize:10,fontWeight:FontWeight.w800))]),const SizedBox(height:4),ClipRRect(borderRadius:BorderRadius.circular(5),child:LinearProgressIndicator(value:((e.value as num).toDouble()/max).clamp(0.0,1.0).toDouble(),minHeight:7))]))])));}}

class Info extends StatelessWidget{const Info({super.key,required this.title,required this.text,required this.icon});final String title,text;final IconData icon;@override Widget build(BuildContext c)=>Card(child:Padding(padding:const EdgeInsets.all(15),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon,color:orange),const SizedBox(width:11),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontWeight:FontWeight.w800)),const SizedBox(height:5),Text(text,style:const TextStyle(color:muted,height:1.35))]))])));}

class Frame extends StatelessWidget{const Frame({super.key,required this.title,required this.subtitle,required this.child,this.action});final String title,subtitle;final Widget child,action;@override Widget build(BuildContext c)=>SafeArea(child:SingleChildScrollView(padding:const EdgeInsets.fromLTRB(22,20,22,30),child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:1200),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:26,fontWeight:FontWeight.w900)),Text(subtitle,style:const TextStyle(color:muted))])),if(action!=null)action!]),const SizedBox(height:18),child]))));}

class SettingsPage extends StatefulWidget{const SettingsPage({super.key,required this.url,required this.token,required this.onSave});final String url,token;final Future<void> Function(String,String) onSave;@override State<SettingsPage> createState()=>_SettingsState();}
class _SettingsState extends State<SettingsPage>{late TextEditingController u,t;@override void initState(){super.initState();u=TextEditingController(text:widget.url);t=TextEditingController(text:widget.token);}@override void dispose(){u.dispose();t.dispose();super.dispose();}@override Widget build(BuildContext c)=>Frame(title:'Definições',subtitle:'Ligação e controlo da plataforma privada',child:Column(children:[Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(children:[TextField(controller:u,decoration:const InputDecoration(labelText:'URL do Bennu Core',hintText:'http://192.168.x.x:8000')),const SizedBox(height:12),TextField(controller:t,obscureText:true,decoration:const InputDecoration(labelText:'Token privado')),const SizedBox(height:14),Align(alignment:Alignment.centerRight,child:FilledButton.icon(onPressed:()async{await widget.onSave(u.text,t.text);if(mounted)ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content:Text('Definições guardadas.')));},icon:const Icon(Icons.save),label:const Text('Guardar')))]))),const SizedBox(height:12),const Info(title:'Modelo de acesso',text:'Existe um único proprietário. Convidados permanecem sem acesso até serem validados pelo proprietário. O token privado impede instalações não autorizadas de lerem a telemetria móvel.',icon:Icons.admin_panel_settings)]));}
