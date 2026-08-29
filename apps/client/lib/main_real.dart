import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const buildApiUrl = String.fromEnvironment('BENNU_API_URL', defaultValue: '');
const bg = Color(0xFF070A0F);
const panel = Color(0xFF10151D);
const panel2 = Color(0xFF151C26);
const muted = Color(0xFF8B98A8);
const green = Color(0xFF48E08A);
const orange = Color(0xFFFF7043);

void main() => runApp(const BennuApp());

class BennuApp extends StatelessWidget {
  const BennuApp({super.key});
  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(seedColor: orange, brightness: Brightness.dark);
    return MaterialApp(
      title: 'Bennu OS',
      debugShowCheckedModeBanner: false,
      locale: const Locale('pt', 'PT'),
      supportedLocales: const [Locale('pt', 'PT'), Locale('en', 'US')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: bg,
        cardTheme: CardThemeData(color: panel, elevation: 0, margin: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
        inputDecorationTheme: const InputDecorationTheme(filled: true, fillColor: panel, border: OutlineInputBorder()),
      ),
      home: const BennuShell(),
    );
  }
}

class BennuApi {
  BennuApi(this.baseUrl);
  final String baseUrl;
  Uri u(String path) => Uri.parse('${baseUrl.replaceFirst(RegExp(r'/+$'), '')}$path');
  Future<Map<String, dynamic>> getJson(String path) async {
    final r = await http.get(u(path), headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 8));
    if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
    return jsonDecode(r.body) as Map<String, dynamic>;
  }
  Future<Map<String, dynamic>> health() => getJson('/health');
  Future<Map<String, dynamic>> overview() => getJson('/api/v1/mobile/overview');
}

class BennuShell extends StatefulWidget {
  const BennuShell({super.key});
  @override State<BennuShell> createState() => _BennuShellState();
}

class _BennuShellState extends State<BennuShell> {
  int index = 0;
  String apiUrl = buildApiUrl;
  bool loading = true;
  static const nav = [
    (Icons.grid_view_rounded, 'Visão geral'),
    (Icons.psychology_rounded, 'IA & Agentes'),
    (Icons.shield_rounded, 'Segurança'),
    (Icons.business_center_rounded, 'Negócios'),
    (Icons.point_of_sale_rounded, 'Vendas'),
    (Icons.cloud_rounded, 'Cloud'),
    (Icons.terminal_rounded, 'Terminal'),
    (Icons.extension_rounded, 'Marketplace'),
    (Icons.settings_rounded, 'Definições'),
  ];

  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final saved = p.getString('bennu_api_url');
    if (!mounted) return;
    setState(() { apiUrl = saved?.trim().isNotEmpty == true ? saved!.trim() : buildApiUrl; loading = false; });
  }
  Future<void> saveUrl(String value) async {
    final v = value.trim().replaceFirst(RegExp(r'/+$'), '');
    final p = await SharedPreferences.getInstance();
    await p.setString('bennu_api_url', v);
    if (mounted) setState(() => apiUrl = v);
  }

  @override Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= 900;
      final page = _page(index);
      if (wide) {
        return Scaffold(body: Row(children: [BennuRail(selected: index, onSelected: (v) => setState(() => index = v)), const VerticalDivider(width: 1), Expanded(child: page)]));
      }
      return Scaffold(
        appBar: AppBar(title: Text(nav[index].$2, style: const TextStyle(fontWeight: FontWeight.w800)), actions: [if (apiUrl.isNotEmpty) const Padding(padding: EdgeInsets.only(right: 16), child: Icon(Icons.lock_rounded, color: green))]),
        body: page,
        bottomNavigationBar: NavigationBar(selectedIndex: index.clamp(0, 4), onDestinationSelected: (v) => setState(() => index = v), destinations: [for (final n in nav.take(5)) NavigationDestination(icon: Icon(n.$1), label: n.$2.split(' ').first)]),
      );
    });
  }

  Widget _page(int i) => switch (i) {
    1 => AgentsPage(api: BennuApi(apiUrl), configured: apiUrl.isNotEmpty),
    2 => SecurityPage(),
    3 => BusinessPage(),
    4 => SalesPage(),
    5 => CloudPage(),
    6 => TerminalPage(api: BennuApi(apiUrl), configured: apiUrl.isNotEmpty),
    7 => MarketplacePage(),
    8 => SettingsPage(url: apiUrl, onSaved: saveUrl),
    _ => DashboardPage(api: BennuApi(apiUrl), configured: apiUrl.isNotEmpty),
  };
}

class BennuRail extends StatelessWidget {
  const BennuRail({super.key, required this.selected, required this.onSelected});
  final int selected; final ValueChanged<int> onSelected;
  @override Widget build(BuildContext context) => Container(
    width: 230,
    color: const Color(0xFF0B0F15),
    child: SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(20, 20, 16, 24), child: Row(children: [Container(width: 42, height: 42, decoration: BoxDecoration(color: orange, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.local_fire_department_rounded)), const SizedBox(width: 12), const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('BENNU', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)), Text('PRIVATE OS', style: TextStyle(fontSize: 10, color: muted, letterSpacing: 1.5))])])),
      Expanded(child: ListView.builder(itemCount: nav.length, itemBuilder: (_, i) { final n = _BennuShellState.nav[i]; final selectedNow = selected == i; return Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2), child: ListTile(leading: Icon(n.$1, size: 21, color: selectedNow ? orange : muted), title: Text(n.$2, style: TextStyle(fontSize: 13, fontWeight: selectedNow ? FontWeight.w800 : FontWeight.w500, color: selectedNow ? Colors.white : muted)), selected: selectedNow, selectedTileColor: const Color(0xFF1D232C), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), onTap: () => onSelected(i))); }) ),
      const Padding(padding: EdgeInsets.all(16), child: Row(children: [Icon(Icons.lock_rounded, size: 15, color: green), SizedBox(width: 7), Text('PRIVATE • SECURE', style: TextStyle(fontSize: 10, color: green, letterSpacing: 1))])),
    ])),
  );
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.api, required this.configured});
  final BennuApi api; final bool configured;
  @override State<DashboardPage> createState() => _DashboardState();
}
class _DashboardState extends State<DashboardPage> {
  Map<String,dynamic>? data; String? error; bool busy = false;
  @override void initState() { super.initState(); if (widget.configured) refresh(); }
  Future<void> refresh() async { setState(() => busy = true); try { final d = await widget.api.overview(); if (mounted) setState(() { data = d; error = null; }); } catch(e) { if (mounted) setState(() => error = e.toString().replaceFirst('Exception: ', '')); } finally { if (mounted) setState(() => busy = false); } }
  @override Widget build(BuildContext context) => PageFrame(title: 'Centro de Comando', subtitle: 'Bennu OS • inteligência operacional privada', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    CommandHero(online: data != null && error == null, version: '${data?['version'] ?? '—'}', configured: widget.configured, busy: busy, onRefresh: widget.configured ? refresh : null),
    const SizedBox(height: 16),
    if (!widget.configured) const InfoCard(icon: Icons.link_rounded, title: 'Ligue o Bennu à tua infraestrutura', text: 'Abra Definições e indique o endereço da API. No Android, nunca use localhost: use o IP LAN ou um domínio HTTPS.'),
    if (error != null) InfoCard(icon: Icons.warning_amber_rounded, title: 'API sem resposta', text: error!),
    if (data != null) RealOverview(data: data!),
    if (data == null && error == null && widget.configured) const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
    const SizedBox(height: 22),
    const SectionTitle('Módulos Bennu OS'),
    const SizedBox(height: 10),
    const ModuleGrid(),
  ]));
}

class CommandHero extends StatelessWidget {
  const CommandHero({super.key, required this.online, required this.version, required this.configured, required this.busy, required this.onRefresh});
  final bool online, configured, busy; final String version; final VoidCallback? onRefresh;
  @override Widget build(BuildContext context) { final c = Theme.of(context).colorScheme; return Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: LinearGradient(colors: [const Color(0xFF171E28), const Color(0xFF0E1219)], begin: Alignment.topLeft, end: Alignment.bottomRight), border: Border.all(color: orange.withValues(alpha: .25))), child: Row(children: [Container(width: 56,height:56,decoration:BoxDecoration(color: orange.withValues(alpha:.15),borderRadius:BorderRadius.circular(18)),child:Icon(Icons.local_fire_department_rounded,color:orange,size:32)),const SizedBox(width:16),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('BENNU COMMAND CENTER',style:TextStyle(fontSize:20,fontWeight:FontWeight.w900,letterSpacing:1)),const SizedBox(height:5),Text(configured ? (busy ? 'A contactar com a infraestrutura…' : online ? 'Sistema online • dados reais' : 'Servidor configurado, mas sem resposta') : 'Modo privado • servidor ainda não configurado',style:const TextStyle(color:muted)),const SizedBox(height:8),Row(children:[Icon(Icons.circle,size:9,color:configured&&online?green:Colors.orangeAccent),const SizedBox(width:7),Text(configured?'API $version':'LOCAL / PRIVATE',style:TextStyle(color:c.onSurfaceVariant,fontSize:11))])])),if(onRefresh!=null)IconButton(onPressed:onRefresh,icon:const Icon(Icons.refresh_rounded))])); }
}

class RealOverview extends StatelessWidget {
  const RealOverview({super.key, required this.data}); final Map<String,dynamic> data;
  @override Widget build(BuildContext context) { final tasks=Map<String,dynamic>.from(data['task_status']??{}); final roles=Map<String,dynamic>.from(data['agent_roles']??{}); return Column(children:[const SizedBox(height:16), LayoutBuilder(builder:(_,c){final cols=c.maxWidth>=760?4:2; return GridView.count(crossAxisCount:cols,crossAxisSpacing:10,mainAxisSpacing:10,shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),childAspectRatio:1.5,children:[MetricCard(icon:Icons.smart_toy_rounded,title:'Agentes',value:'${data['agents']}',detail:'dados reais'),MetricCard(icon:Icons.task_alt_rounded,title:'Tarefas',value:'${data['tasks']}',detail:'dados reais'),MetricCard(icon:Icons.shield_rounded,title:'Segurança',value:'100',detail:'score base'),MetricCard(icon:Icons.public_rounded,title:'Estado',value:'ONLINE',detail:'Bennu Core')];}),const SizedBox(height:12), InfoCard(icon:Icons.query_stats_rounded,title:'Tarefas por estado',text:tasks.isEmpty?'Ainda não existem tarefas.':tasks.entries.map((e)=>'${e.key}: ${e.value}').join('  •  ')),const SizedBox(height:10),InfoCard(icon:Icons.groups_rounded,title:'Agentes por função',text:roles.isEmpty?'Ainda não existem agentes.':roles.entries.map((e)=>'${e.key}: ${e.value}').join('  •  ')),const SizedBox(height:8),Align(alignment:Alignment.centerLeft,child:Text('Atualizado ${data['timestamp']}',style:const TextStyle(color:Colors.white38,fontSize:10))) ]); }
}

class ModuleGrid extends StatelessWidget { const ModuleGrid({super.key}); @override Widget build(BuildContext context)=>LayoutBuilder(builder:(_,c){final cols=c.maxWidth>=800?4:c.maxWidth>=520?3:2; return GridView.count(crossAxisCount:cols,crossAxisSpacing:10,mainAxisSpacing:10,shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),childAspectRatio:1.2,children:const[_Module(Icons.psychology_rounded,'IA & Agentes','Multiagente'),_Module(Icons.security_rounded,'SOC','Defesa'),_Module(Icons.business_rounded,'Business','CRM / ERP'),_Module(Icons.point_of_sale_rounded,'Sales','Leads / Funil'),_Module(Icons.cloud_rounded,'Cloud','Infraestrutura'),_Module(Icons.code_rounded,'Developer','Código'),_Module(Icons.storefront_rounded,'Marketplace','Plugins'),_Module(Icons.auto_awesome_rounded,'Ghost Mode','Automação')]);}); }
class _Module extends StatelessWidget { const _Module(this.icon,this.title,this.subtitle); final IconData icon; final String title,subtitle; @override Widget build(BuildContext c)=>Card(child:Padding(padding:const EdgeInsets.all(15),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon,color:Theme.of(c).colorScheme.primary),const Spacer(),Text(title,style:const TextStyle(fontWeight:FontWeight.w800)),Text(subtitle,style:const TextStyle(color:muted,fontSize:11))]))); }

class AgentsPage extends StatelessWidget { const AgentsPage({super.key,required this.api,required this.configured}); final BennuApi api; final bool configured; @override Widget build(BuildContext c)=>PageFrame(title:'IA & Agentes',subtitle:'A camada cognitiva do Bennu OS.',child:Column(children:const[_Agent('CEO','Coordenação e estratégia',Icons.psychology_rounded),_Agent('Comercial','Leads, propostas e negociação',Icons.point_of_sale_rounded),_Agent('Segurança','Deteção e resposta a incidentes',Icons.shield_rounded),_Agent('Programador','Código, testes e automação',Icons.code_rounded),_Agent('Financeiro','Receitas, despesas e análise',Icons.account_balance_rounded),_Agent('Marketing','Conteúdo, campanhas e tendências',Icons.campaign_rounded)]));}}
class _Agent extends StatelessWidget { const _Agent(this.name,this.desc,this.icon); final String name,desc; final IconData icon; @override Widget build(BuildContext c)=>Card(margin:const EdgeInsets.only(bottom:9),child:ListTile(leading:Icon(icon),title:Text('Agente $name',style:const TextStyle(fontWeight:FontWeight.w800)),subtitle:Text(desc),trailing:Container(padding:const EdgeInsets.symmetric(horizontal:9,vertical:5),decoration:BoxDecoration(color:green.withValues(alpha:.1),borderRadius:BorderRadius.circular(20)),child:const Text('PRONTO',style:TextStyle(color:green,fontSize:10,fontWeight:FontWeight.w800))));}

class SecurityPage extends StatelessWidget { const SecurityPage({super.key}); @override Widget build(BuildContext c)=>PageFrame(title:'Centro de Segurança',subtitle:'SOC privado • arquitetura preparada para telemetria real.',child:Column(children:[const _RiskCard(),const SizedBox(height:12),const _SecurityGrid(),const SizedBox(height:12),const InfoCard(icon:Icons.lock_rounded,title:'Defesa controlada',text:'Integrações como Suricata, Wazuh, CrowdSec e ferramentas de auditoria serão ligadas por plugins com sandbox, RBAC, aprovação e auditoria.')])); }
class _RiskCard extends StatelessWidget { const _RiskCard(); @override Widget build(BuildContext c)=>Card(child:Padding(padding:const EdgeInsets.all(20),child:Row(children:[SizedBox(width:92,height:92,child:CustomPaint(painter:GaugePainter(0.94),child:const Center(child:Text('94',style:TextStyle(fontSize:27,fontWeight:FontWeight.w900))))),const SizedBox(width:20),const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('RISK SCORE',style:TextStyle(color:muted,fontSize:11,letterSpacing:1.5)),SizedBox(height:5),Text('Baixo risco',style:TextStyle(fontSize:21,fontWeight:FontWeight.w900)),SizedBox(height:6),Text('Indicador visual base. Os sensores reais serão conectados ao pipeline de segurança.',style:TextStyle(color:muted))]))]));}}
class _SecurityGrid extends StatelessWidget { const _SecurityGrid(); @override Widget build(BuildContext c)=>GridView.count(crossAxisCount:2,crossAxisSpacing:10,mainAxisSpacing:10,shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),childAspectRatio:1.7,children:const[MetricCard(icon:Icons.radar_rounded,title:'Ameaças',value:'—',detail:'aguarda sensores'),MetricCard(icon:Icons.block_rounded,title:'Bloqueios',value:'—',detail:'aguarda firewall'),MetricCard(icon:Icons.network_check_rounded,title:'Rede',value:'—',detail:'aguarda IDS/IPS'),MetricCard(icon:Icons.receipt_long_rounded,title:'Auditoria',value:'ATIVA',detail:'eventos locais')]);}}

class BusinessPage extends StatelessWidget { const BusinessPage({super.key}); @override Widget build(BuildContext c)=>PageFrame(title:'Business OS',subtitle:'CRM, ERP, suporte e operações empresariais.',child:const ModuleStatusList(items:[('CRM inteligente',Icons.people_alt_rounded),('Financeiro',Icons.account_balance_wallet_rounded),('Suporte',Icons.support_agent_rounded),('Marketing',Icons.campaign_rounded),('Leads',Icons.person_search_rounded)])); }
class SalesPage extends StatelessWidget { const SalesPage({super.key}); @override Widget build(BuildContext c)=>PageFrame(title:'Sales Engine',subtitle:'Motor comercial autónomo e marketplace.',child:const ModuleStatusList(items:[('Leads',Icons.person_search_rounded),('Funil de vendas',Icons.filter_alt_rounded),('Campanhas',Icons.ads_click_rounded),('Pagamentos',Icons.payments_rounded),('Marketplace',Icons.storefront_rounded)])); }
class CloudPage extends StatelessWidget { const CloudPage({super.key}); @override Widget build(BuildContext c)=>PageFrame(title:'Cloud & Infra',subtitle:'Infraestrutura privada e serviços Bennu.',child:const ModuleStatusList(items:[('Servidores',Icons.dns_rounded),('Containers',Icons.inventory_2_rounded),('PostgreSQL',Icons.storage_rounded),('Redis',Icons.memory_rounded),('Cloudflare / Nginx',Icons.language_rounded)])); }
class MarketplacePage extends StatelessWidget { const MarketplacePage({super.key}); @override Widget build(BuildContext c)=>PageFrame(title:'Marketplace',subtitle:'Extensões para transformar o Bennu numa plataforma.',child:const ModuleStatusList(items:[('Plugins de IA',Icons.psychology_rounded),('Segurança',Icons.shield_rounded),('Automação',Icons.auto_awesome_rounded),('E-commerce',Icons.shopping_cart_rounded),('Analytics',Icons.analytics_rounded)])); }
class ModuleStatusList extends StatelessWidget { const ModuleStatusList({super.key,required this.items}); final List<(String,IconData)> items; @override Widget build(BuildContext c)=>Column(children:[for(final x in items)Card(margin:const EdgeInsets.only(bottom:9),child:ListTile(leading:Icon(x.$2),title:Text(x.$1,style:const TextStyle(fontWeight:FontWeight.w700)),subtitle:const Text('Módulo preparado para integração'),trailing:const Icon(Icons.construction_rounded,color:Colors.orangeAccent,size:18))) ]); }

class TerminalPage extends StatefulWidget { const TerminalPage({super.key,required this.api,required this.configured}); final BennuApi api; final bool configured; @override State<TerminalPage> createState()=>_TerminalState(); }
class _TerminalState extends State<TerminalPage>{final input=TextEditingController();final lines=<String>['BENNU TERMINAL','help  comandos','status  dados reais','health  saúde da API'];@override void dispose(){input.dispose();super.dispose();}Future<void>run()async{final cmd=input.text.trim().toLowerCase();if(cmd.isEmpty)return;setState(()=>lines.add('> $cmd'));input.clear();if(cmd=='clear'){setState(()=>lines.clear());return;}if(cmd=='help'){setState(()=>lines.addAll(['status  estado real do Bennu','health  saúde da API','clear   limpar terminal']));return;}if(!widget.configured){setState(()=>lines.add('ERRO: API não configurada.'));return;}try{final d=cmd=='health'?await widget.api.health():await widget.api.overview();setState(()=>lines.add(cmd=='health'?'API ${d['status']} • ${d['version']}':'ONLINE • agentes ${d['agents']} • tarefas ${d['tasks']}'));}catch(e){setState(()=>lines.add('ERRO: ${e.toString().replaceFirst('Exception: ','')}'));}}@override Widget build(BuildContext c)=>PageFrame(title:'Terminal',subtitle:'Interface de comando do Bennu.',child:Column(children:[Container(width:double.infinity,height:310,padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:const Color(0xFF030508),borderRadius:BorderRadius.circular(18),border:Border.all(color:Colors.white12)),child:SelectableText(lines.join('\n'),style:const TextStyle(fontFamily:'monospace',height:1.6)),),const SizedBox(height:10),Row(children:[Expanded(child:TextField(controller:input,onSubmitted:(_)=>run(),decoration:const InputDecoration(hintText:'bennu status'))),const SizedBox(width:8),FilledButton(onPressed:run,child:const Icon(Icons.play_arrow_rounded))]) ]));}

class SettingsPage extends StatefulWidget { const SettingsPage({super.key,required this.url,required this.onSaved}); final String url; final Future<void> Function(String) onSaved; @override State<SettingsPage> createState()=>_SettingsState(); }
class _SettingsState extends State<SettingsPage>{late final TextEditingController input;String? message;bool busy=false;@override void initState(){super.initState();input=TextEditingController(text:widget.url);}@override void dispose(){input.dispose();super.dispose();}Future<void>save()async{final url=input.text.trim().replaceFirst(RegExp(r'/+$'),'');if(url.isEmpty){setState(()=>message='Indica o endereço da API.');return;}setState(()=>busy=true);try{final h=await BennuApi(url).health();await widget.onSaved(url);if(mounted)setState(()=>message='Ligação OK • Bennu ${h['version']}');}catch(e){if(mounted)setState(()=>message='Falha: ${e.toString().replaceFirst('Exception: ','')}');}finally{if(mounted)setState(()=>busy=false);}}@override Widget build(BuildContext c)=>PageFrame(title:'Definições',subtitle:'Infraestrutura privada e ligação segura.',child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const InfoCard(icon:Icons.lock_rounded,title:'Plataforma privada',text:'O cliente guarda apenas o endereço da tua API. Os dados operacionais ficam no teu servidor Bennu.'),const SizedBox(height:12),TextField(controller:input,keyboardType:TextInputType.url,decoration:const InputDecoration(labelText:'URL da API Bennu',hintText:'http://192.168.1.50:8000')),const SizedBox(height:10),SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:busy?null:save,icon:busy?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.wifi_tethering_rounded),label:Text(busy?'A testar…':'Guardar e testar'))),if(message!=null)Padding(padding:const EdgeInsets.only(top:12),child:Text(message!,style:TextStyle(color:message!.startsWith('Ligação OK')?green:Colors.orangeAccent))) ]));}

class PageFrame extends StatelessWidget { const PageFrame({super.key,required this.title,required this.subtitle,required this.child}); final String title,subtitle; final Widget child; @override Widget build(BuildContext c)=>SafeArea(child:SingleChildScrollView(padding:const EdgeInsets.all(20),child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:1100),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:Theme.of(c).textTheme.headlineMedium?.copyWith(fontWeight:FontWeight.w900)),const SizedBox(height:4),Text(subtitle,style:const TextStyle(color:muted)),const SizedBox(height:20),child])))); }
class SectionTitle extends StatelessWidget { const SectionTitle(this.text,{super.key}); final String text; @override Widget build(BuildContext c)=>Text(text,style:Theme.of(c).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w900)); }
class InfoCard extends StatelessWidget { const InfoCard({super.key,required this.icon,required this.title,required this.text}); final IconData icon; final String title,text; @override Widget build(BuildContext c)=>Card(child:Padding(padding:const EdgeInsets.all(17),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon,color:Theme.of(c).colorScheme.primary),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontWeight:FontWeight.w800)),const SizedBox(height:5),Text(text,style:const TextStyle(color:muted,height:1.4))]))]))); }
class MetricCard extends StatelessWidget { const MetricCard({super.key,required this.icon,required this.title,required this.value,required this.detail}); final IconData icon; final String title,value,detail; @override Widget build(BuildContext c)=>Card(child:Padding(padding:const EdgeInsets.all(17),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon,color:Theme.of(c).colorScheme.primary),const Spacer(),Text(title,style:const TextStyle(color:muted,fontSize:12)),Text(value,style:const TextStyle(fontSize:23,fontWeight:FontWeight.w900)),Text(detail,style:const TextStyle(color:Colors.white38,fontSize:10))]))); }
class GaugePainter extends CustomPainter { GaugePainter(this.value); final double value; @override void paint(Canvas canvas,Size s){final p=Paint()..style=PaintingStyle.stroke..strokeWidth=9..strokeCap=StrokeCap.round..color=Colors.white12;canvas.drawArc(Offset.zero& s,-2.35,3.7,false,p);p.color=green;canvas.drawArc(Offset.zero&s,-2.35,3.7*value,false,p);} @override bool shouldRepaint(covariant GaugePainter old)=>old.value!=value; }
