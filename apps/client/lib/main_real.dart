import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const buildApiUrl = String.fromEnvironment('BENNU_API_URL', defaultValue: '');

void main() => runApp(const BennuApp());

class BennuApp extends StatelessWidget {
  const BennuApp({super.key});
  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFFFF6B35), brightness: Brightness.dark);
    return MaterialApp(
      title: 'Bennu', debugShowCheckedModeBanner: false, locale: const Locale('pt', 'PT'),
      supportedLocales: const [Locale('pt', 'PT'), Locale('en', 'US')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(useMaterial3: true, colorScheme: scheme, scaffoldBackgroundColor: const Color(0xFF090B0F),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF090B0F), foregroundColor: Colors.white, elevation: 0),
        cardTheme: CardThemeData(color: const Color(0xFF12161C), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
        inputDecorationTheme: const InputDecorationTheme(filled: true, fillColor: Color(0xFF12161C), border: OutlineInputBorder())),
      home: const BennuShell(),
    );
  }
}

class BennuApi {
  BennuApi(this.baseUrl);
  final String baseUrl;
  Uri u(String path) => Uri.parse('${baseUrl.replaceFirst(RegExp(r'/+$'), '')}$path');
  Future<Map<String,dynamic>> getJson(String path) async {
    final r = await http.get(u(path), headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 8));
    if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
    return jsonDecode(r.body) as Map<String,dynamic>;
  }
  Future<Map<String,dynamic>> health() => getJson('/health');
  Future<Map<String,dynamic>> overview() => getJson('/api/v1/mobile/overview');
}

class BennuShell extends StatefulWidget {
  const BennuShell({super.key});
  @override State<BennuShell> createState() => _BennuShellState();
}
class _BennuShellState extends State<BennuShell> {
  int index = 0; String apiUrl = buildApiUrl; bool loading = true;
  static const items = [(Icons.dashboard_rounded,'Painel'),(Icons.dns_rounded,'Serviços'),(Icons.terminal_rounded,'Terminal'),(Icons.settings_rounded,'Definições')];
  @override void initState(){super.initState(); _load();}
  Future<void> _load() async { final p=await SharedPreferences.getInstance(); final s=p.getString('bennu_api_url'); if(!mounted)return; setState((){apiUrl=(s?.trim().isNotEmpty??false)?s!.trim():buildApiUrl;loading=false;}); }
  Future<void> saveUrl(String value) async { final v=value.trim().replaceFirst(RegExp(r'/+$'),''); final p=await SharedPreferences.getInstance(); await p.setString('bennu_api_url',v); if(mounted)setState(()=>apiUrl=v); }
  @override Widget build(BuildContext context){
    if(loading)return const Scaffold(body:Center(child:CircularProgressIndicator()));
    final page=switch(index){1=>ServicesPage(api:BennuApi(apiUrl),configured:apiUrl.isNotEmpty),2=>TerminalPage(api:BennuApi(apiUrl),configured:apiUrl.isNotEmpty),3=>SettingsPage(url:apiUrl,onSaved:saveUrl),_=>DashboardPage(api:BennuApi(apiUrl),configured:apiUrl.isNotEmpty)};
    return LayoutBuilder(builder:(context,c){if(c.maxWidth>=720)return Scaffold(body:Row(children:[_Rail(selected:index,onSelected:(v)=>setState(()=>index=v)),const VerticalDivider(width:1),Expanded(child:page)]));return Scaffold(appBar:AppBar(title:Text(items[index].$2,style:const TextStyle(fontWeight:FontWeight.w800))),body:page,bottomNavigationBar:NavigationBar(selectedIndex:index,onDestinationSelected:(v)=>setState(()=>index=v),destinations:[for(final i in items)NavigationDestination(icon:Icon(i.$1),label:i.$2)]));});
  }
}

class _Rail extends StatelessWidget { const _Rail({required this.selected,required this.onSelected}); final int selected; final ValueChanged<int> onSelected;
  @override Widget build(BuildContext c)=>NavigationRail(selectedIndex:selected,onDestinationSelected:onSelected,labelType:NavigationRailLabelType.all,leading:Padding(padding:const EdgeInsets.only(bottom:25),child:Column(children:[Container(width:48,height:48,decoration:BoxDecoration(color:Theme.of(c).colorScheme.primary,borderRadius:BorderRadius.circular(16)),child:const Icon(Icons.local_fire_department_rounded)),const SizedBox(height:8),const Text('Bennu',style:TextStyle(fontWeight:FontWeight.w800))])),destinations:const[NavigationRailDestination(icon:Icon(Icons.dashboard_rounded),label:Text('Painel')),NavigationRailDestination(icon:Icon(Icons.dns_rounded),label:Text('Serviços')),NavigationRailDestination(icon:Icon(Icons.terminal_rounded),label:Text('Terminal')),NavigationRailDestination(icon:Icon(Icons.settings_rounded),label:Text('Definições'))]); }

class DashboardPage extends StatefulWidget { const DashboardPage({super.key,required this.api,required this.configured}); final BennuApi api; final bool configured; @override State<DashboardPage> createState()=>_DashboardState(); }
class _DashboardState extends State<DashboardPage>{ Map<String,dynamic>? data; String? error; bool busy=false; @override void initState(){super.initState();if(widget.configured)_refresh();}
  Future<void> _refresh() async {setState(()=>busy=true);try{final d=await widget.api.overview();if(mounted)setState(()=>data=d);}catch(e){if(mounted)setState(()=>error=e.toString().replaceFirst('Exception: ',''));}finally{if(mounted)setState(()=>busy=false);}}
  @override Widget build(BuildContext c)=>PageFrame(title:'Centro de Comando',subtitle:'Telemetria real do Bennu.',child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Connection(online:data!=null&&error==null,configured:widget.configured,busy:busy,error:error,onRefresh:widget.configured?_refresh:null),const SizedBox(height:15),if(!widget.configured)const Info(icon:Icons.link,title:'API por configurar',text:'Vai a Definições e indica o servidor Bennu. No telemóvel não uses localhost; usa o IP ou domínio do servidor.')else if(error!=null)Info(icon:Icons.warning_amber_rounded,title:'Sem dados reais',text:'Não foi possível contactar a API.\n\n$error')else if(data==null)const Center(child:CircularProgressIndicator())else RealMetrics(data:data!)])); }

class RealMetrics extends StatelessWidget { const RealMetrics({super.key,required this.data}); final Map<String,dynamic> data; @override Widget build(BuildContext c){final ts=Map<String,dynamic>.from(data['task_status']??{});final roles=Map<String,dynamic>.from(data['agent_roles']??{});return Column(children:[Row(children:[Expanded(child:Metric(icon:Icons.smart_toy_rounded,title:'Agentes',value:'${data['agents']}',detail:'na API')),const SizedBox(width:10),Expanded(child:Metric(icon:Icons.task_alt_rounded,title:'Tarefas',value:'${data['tasks']}',detail:'na API'))]),const SizedBox(height:10),Info(icon:Icons.analytics_rounded,title:'Tarefas por estado',text:ts.isEmpty?'Ainda não existem tarefas.':ts.entries.map((e)=>'${e.key}: ${e.value}').join('  •  ')),const SizedBox(height:10),Info(icon:Icons.groups_rounded,title:'Agentes por função',text:roles.isEmpty?'Ainda não existem agentes.':roles.entries.map((e)=>'${e.key}: ${e.value}').join('  •  ')),const SizedBox(height:8),Align(alignment:Alignment.centerLeft,child:Text('Atualizado: ${data['timestamp']}',style:const TextStyle(color:Colors.white54,fontSize:11))) ]);}}

class ServicesPage extends StatefulWidget { const ServicesPage({super.key,required this.api,required this.configured}); final BennuApi api; final bool configured; @override State<ServicesPage> createState()=>_ServicesState(); }
class _ServicesState extends State<ServicesPage>{bool? online;String? version;String? error;@override void initState(){super.initState();if(widget.configured)_check();} Future<void>_check()async{try{final d=await widget.api.health();if(mounted)setState((){online=d['status']=='online';version='${d['version']}';error=null;});}catch(e){if(mounted)setState((){online=false;error=e.toString().replaceFirst('Exception: ','');});}} @override Widget build(BuildContext c)=>PageFrame(title:'Serviços',subtitle:'Estado obtido da API Bennu.',child:Column(children:[Service('Bennu API',online==true?'Online':online==false?'Offline':'Não testado',Icons.cloud_done_rounded,online==true),if(version!=null)Service('Versão',version!,Icons.info_outline_rounded,true),if(error!=null)Info(icon:Icons.warning_amber_rounded,title:'Erro de ligação',text:error!),if(!widget.configured)const Info(icon:Icons.link,title:'API não configurada',text:'Define o endereço em Definições.'),const SizedBox(height:10),FilledButton.icon(onPressed:widget.configured?_check:null,icon:const Icon(Icons.refresh),label:const Text('Testar novamente'))]));}

class TerminalPage extends StatefulWidget { const TerminalPage({super.key,required this.api,required this.configured}); final BennuApi api; final bool configured; @override State<TerminalPage> createState()=>_TerminalState(); }
class _TerminalState extends State<TerminalPage>{final input=TextEditingController();final lines=<String>['Bennu Terminal','Comandos: help, status, health, clear'];@override void dispose(){input.dispose();super.dispose();}Future<void>run()async{final cmd=input.text.trim().toLowerCase();if(cmd.isEmpty)return;setState(()=>lines.add('> $cmd'));input.clear();if(cmd=='clear'){setState(()=>lines.clear());return;}if(cmd=='help'){setState(()=>lines.addAll(['status  dados reais','health  saúde da API','clear   limpar']));return;}if(!widget.configured){setState(()=>lines.add('API não configurada.'));return;}try{final d=cmd=='health'?await widget.api.health():await widget.api.overview();setState(()=>lines.add(cmd=='health'?'API ${d['status']} • ${d['version']}':'ONLINE • agentes ${d['agents']} • tarefas ${d['tasks']}'));}catch(e){setState(()=>lines.add('ERRO: ${e.toString().replaceFirst('Exception: ','')}'));}}@override Widget build(BuildContext c)=>PageFrame(title:'Terminal',subtitle:'Consultas reais à API Bennu.',child:Column(children:[Container(width:double.infinity,height:280,padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:const Color(0xFF050608),borderRadius:BorderRadius.circular(18)),child:SelectableText(lines.join('\n'),style:const TextStyle(fontFamily:'monospace',height:1.6)),),const SizedBox(height:10),Row(children:[Expanded(child:TextField(controller:input,onSubmitted:(_)=>run(),decoration:const InputDecoration(hintText:'Escreve um comando…'))),const SizedBox(width:8),FilledButton(onPressed:run,child:const Icon(Icons.play_arrow))]) ]));}

class SettingsPage extends StatefulWidget { const SettingsPage({super.key,required this.url,required this.onSaved}); final String url; final Future<void>Function(String)onSaved; @override State<SettingsPage>createState()=>_SettingsState(); }
class _SettingsState extends State<SettingsPage>{late final TextEditingController input;String? message;bool busy=false;@override void initState(){super.initState();input=TextEditingController(text:widget.url);}@override void dispose(){input.dispose();super.dispose();}Future<void>save()async{final url=input.text.trim().replaceFirst(RegExp(r'/+$'),'');if(url.isEmpty){setState(()=>message='Indica o endereço da API.');return;}setState(()=>busy=true);try{final h=await BennuApi(url).health();await widget.onSaved(url);if(mounted)setState(()=>message='Ligação OK • Bennu ${h['version']}');}catch(e){if(mounted)setState(()=>message='Falha: ${e.toString().replaceFirst('Exception: ','')}');}finally{if(mounted)setState(()=>busy=false);}}@override Widget build(BuildContext c)=>PageFrame(title:'Definições',subtitle:'Ligação do telemóvel ao servidor Bennu.',child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Info(icon:Icons.info_outline,title:'Endereço do servidor',text:'Não uses localhost no telemóvel. Exemplo: http://192.168.1.50:8080 ou, em produção, um domínio HTTPS.'),const SizedBox(height:12),TextField(controller:input,keyboardType:TextInputType.url,decoration:const InputDecoration(labelText:'URL do Bennu',hintText:'http://192.168.1.50:8080')),const SizedBox(height:10),SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:busy?null:save,icon:busy?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.wifi_tethering),label:Text(busy?'A testar…':'Guardar e testar'))),if(message!=null)Padding(padding:const EdgeInsets.only(top:12),child:Text(message!,style:TextStyle(color:message!.startsWith('Ligação OK')?Colors.greenAccent:Colors.orangeAccent))) ]));}

class Connection extends StatelessWidget{const Connection({super.key,required this.online,required this.configured,required this.busy,required this.error,required this.onRefresh});final bool online,configured,busy;final String?error;final VoidCallback?onRefresh;@override Widget build(BuildContext c)=>Card(child:ListTile(leading:Icon(Icons.circle,size:12,color:configured?(online?Colors.greenAccent:Colors.orangeAccent):Colors.white30),title:Text(!configured?'API por configurar':busy?'A contactar…':online?'Bennu está online':'Bennu sem ligação',style:const TextStyle(fontWeight:FontWeight.w800)),subtitle:Text(error??(configured?'Dados reais ligados à API.':'Define o servidor em Definições.')),trailing:onRefresh==null?null:IconButton(onPressed:onRefresh,icon:const Icon(Icons.refresh))));}
class Metric extends StatelessWidget{const Metric({super.key,required this.icon,required this.title,required this.value,required this.detail});final IconData icon;final String title,value,detail;@override Widget build(BuildContext c)=>Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon,color:Theme.of(c).colorScheme.primary),const SizedBox(height:20),Text(title,style:const TextStyle(color:Colors.white60)),Text(value,style:const TextStyle(fontSize:25,fontWeight:FontWeight.w900)),Text(detail,style:const TextStyle(fontSize:12,color:Colors.white54))])));}
class Info extends StatelessWidget{const Info({super.key,required this.icon,required this.title,required this.text});final IconData icon;final String title,text;@override Widget build(BuildContext c)=>Card(child:Padding(padding:const EdgeInsets.all(18),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon,color:Theme.of(c).colorScheme.primary),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontWeight:FontWeight.w800)),const SizedBox(height:5),Text(text,style:const TextStyle(color:Colors.white60,height:1.4))]))])));}
class Service extends StatelessWidget{const Service(this.name,this.state,this.icon,this.online,{super.key});final String name,state;final IconData icon;final bool online;@override Widget build(BuildContext c)=>Card(margin:const EdgeInsets.only(bottom:8),child:ListTile(leading:Icon(icon),title:Text(name,style:const TextStyle(fontWeight:FontWeight.w700)),subtitle:Text(state),trailing:Container(width:10,height:10,decoration:BoxDecoration(color:online?Colors.greenAccent:Colors.orangeAccent,shape:BoxShape.circle))));}
class PageFrame extends StatelessWidget{const PageFrame({super.key,required this.title,required this.subtitle,required this.child});final String title,subtitle;final Widget child;@override Widget build(BuildContext c)=>SafeArea(child:SingleChildScrollView(padding:const EdgeInsets.all(18),child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:980),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:Theme.of(c).textTheme.headlineMedium?.copyWith(fontWeight:FontWeight.w900)),const SizedBox(height:4),Text(subtitle,style:const TextStyle(color:Colors.white60)),const SizedBox(height:18),child])))));
