import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const bg = Color(0xFF070A0F);
const panel = Color(0xFF10151D);
const muted = Color(0xFF8B98A8);
const green = Color(0xFF48E08A);
const orange = Color(0xFFFF7043);

void main() => runApp(const BennuApp());

class BennuApp extends StatelessWidget {
  const BennuApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Bennu OS',
        debugShowCheckedModeBanner: false,
        locale: const Locale('pt', 'PT'),
        supportedLocales: const [Locale('pt', 'PT'), Locale('en', 'US')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: bg,
          colorScheme: ColorScheme.fromSeed(seedColor: orange, brightness: Brightness.dark),
          cardTheme: CardThemeData(color: panel, elevation: 0, margin: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
          inputDecorationTheme: const InputDecorationTheme(filled: true, fillColor: panel, border: OutlineInputBorder()),
        ),
        home: const CommandCenter(),
      );
}

class BennuApi {
  BennuApi(this.base);
  final String base;
  Uri url(String path) => Uri.parse('${base.replaceFirst(RegExp(r'/+$'), '')}$path');
  Future<Map<String, dynamic>> get(String path) async {
    if (base.trim().isEmpty) throw Exception('Servidor não configurado');
    final r = await http.get(url(path), headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 8));
    if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
    return jsonDecode(r.body) as Map<String, dynamic>;
  }
  Future<Map<String, dynamic>> dashboard() => get('/api/v1/mobile/dashboard');
  Future<Map<String, dynamic>> health() => get('/health');
}

class CommandCenter extends StatefulWidget {
  const CommandCenter({super.key});
  @override State<CommandCenter> createState() => _CommandCenterState();
}

class _CommandCenterState extends State<CommandCenter> {
  final serverController = TextEditingController();
  final commandController = TextEditingController();
  String server = '';
  Map<String, dynamic>? data;
  String? error;
  bool busy = false;
  int tab = 0;
  DateTime? lastSync;

  static const sections = ['Centro', 'IA', 'Segurança', 'Business', 'Vendas', 'Cloud', 'Marketplace', 'Terminal', 'Proprietário', 'Definições'];

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { serverController.dispose(); commandController.dispose(); super.dispose(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final saved = p.getString('bennu_api_url') ?? '';
    if (!mounted) return;
    setState(() { server = saved; serverController.text = saved; });
    if (server.isNotEmpty) await refresh();
  }

  Future<void> refresh() async {
    if (server.trim().isEmpty) return;
    setState(() => busy = true);
    try {
      final d = await BennuApi(server).dashboard();
      if (mounted) setState(() { data = d; error = null; lastSync = DateTime.now(); });
    } catch (e) {
      if (mounted) setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> saveServer() async {
    final value = serverController.text.trim().replaceFirst(RegExp(r'/+$'), '');
    final p = await SharedPreferences.getInstance();
    await p.setString('bennu_api_url', value);
    if (mounted) setState(() { server = value; data = null; error = null; });
    await refresh();
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final content = _page();
    return Scaffold(
      appBar: wide ? null : AppBar(title: Text(sections[tab], style: const TextStyle(fontWeight: FontWeight.w900)), actions: [if (server.isNotEmpty) IconButton(onPressed: busy ? null : refresh, icon: const Icon(Icons.sync_rounded))]),
      body: wide ? Row(children: [NavigationRail(selectedIndex: tab, onDestinationSelected: (v) => setState(() => tab = v), labelType: NavigationRailLabelType.all, leading: const Padding(padding: EdgeInsets.fromLTRB(8, 18, 8, 22), child: Icon(Icons.local_fire_department_rounded, color: orange, size: 34)), destinations: [for (var i = 0; i < sections.length; i++) NavigationRailDestination(icon: const Icon(Icons.circle_outlined, size: 18), label: Text(sections[i]))]), const VerticalDivider(width: 1), Expanded(child: content)]) : content,
      bottomNavigationBar: wide ? null : NavigationBar(selectedIndex: tab.clamp(0, 4), onDestinationSelected: (v) => setState(() => tab = v), destinations: [for (final n in sections.take(5)) NavigationDestination(icon: const Icon(Icons.circle_outlined), label: n)]),
    );
  }

  Widget _page() => switch (tab) {
        1 => _agents(),
        2 => _security(),
        3 => _business(),
        4 => _sales(),
        5 => _cloud(),
        6 => _marketplace(),
        7 => _terminal(),
        8 => _owner(),
        9 => _settings(),
        _ => _dashboard(),
      };

  Widget _frame(String title, String subtitle, Widget child) => SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1150), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(color: muted)), const SizedBox(height: 20), child]))));

  Widget _dashboard() {
    final d = data;
    final s = Map<String, dynamic>.from(d?['summary'] ?? {});
    return _frame('Centro de Comando', 'Bennu OS • inteligência operacional privada', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _hero(),
      const SizedBox(height: 14),
      if (server.isEmpty) _info(Icons.link_rounded, 'Liga a infraestrutura', 'Em Definições indica o endereço do Bennu Core. No Android usa o IP LAN ou HTTPS, nunca localhost.'),
      if (error != null) _info(Icons.cloud_off_rounded, 'Core sem resposta', error!),
      if (d != null) ...[
        _metricGrid([_metric('Agentes', s['agents'], Icons.smart_toy_rounded), _metric('Tarefas', s['tasks'], Icons.task_alt_rounded), _metric('Leads', s['leads'], Icons.person_search_rounded), _metric('Oportunidades', s['opportunities'], Icons.trending_up_rounded), _metric('Pipeline', _money(s['pipeline_value']), Icons.euro_rounded), _metric('Campanhas', s['campaigns'], Icons.campaign_rounded), _metric('Produtos', s['products'], Icons.storefront_rounded), _metric('Deployments', s['deployments'], Icons.cloud_rounded)]),
        const SizedBox(height: 14),
        _bars('Tarefas por estado', d['task_status']),
        const SizedBox(height: 12),
        _bars('Agentes por função', d['agent_roles']),
        const SizedBox(height: 12),
        _bars('Oportunidades por etapa', d['opportunity_stages']),
        const SizedBox(height: 14),
        _learning(d),
      ],
      const SizedBox(height: 22),
      const Text('Ecossistema', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
      const SizedBox(height: 10),
      _moduleGrid(),
    ]));
  }

  Widget _hero() => Card(child: Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: orange.withValues(alpha: .3)), gradient: const LinearGradient(colors: [Color(0xFF171E28), Color(0xFF0D1118)])), child: Row(children: [Container(width: 54, height: 54, decoration: BoxDecoration(color: orange.withValues(alpha: .14), borderRadius: BorderRadius.circular(17)), child: const Icon(Icons.local_fire_department_rounded, color: orange, size: 32)), const SizedBox(width: 15), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('BENNU COMMAND CENTER', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, letterSpacing: 1)), Text(server.isEmpty ? 'PRIVATE • CONFIGURA O CORE' : data != null && error == null ? 'ONLINE • TELEMETRIA REAL' : 'SERVIDOR CONFIGURADO • SEM RESPOSTA', style: TextStyle(color: data != null && error == null ? green : Colors.orangeAccent, fontWeight: FontWeight.w800)), if (data != null) Text('Core ${data!['version']} • sincronizado ${lastSync?.toLocal().toString().substring(11, 19) ?? '—'}', style: const TextStyle(color: muted, fontSize: 10))])), if (server.isNotEmpty) IconButton(onPressed: busy ? null : refresh, icon: busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.refresh_rounded))]));

  Widget _metricGrid(List<Widget> cards) => LayoutBuilder(builder: (_, c) => GridView.count(crossAxisCount: c.maxWidth >= 900 ? 4 : 2, crossAxisSpacing: 10, mainAxisSpacing: 10, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), childAspectRatio: 1.5, children: cards));
  Widget _metric(String title, dynamic value, IconData icon) => Card(child: Padding(padding: const EdgeInsets.all(15), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: orange), const Spacer(), Text(title, style: const TextStyle(color: muted, fontSize: 12)), Text('${value ?? 0}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), const Text('DADOS DO CORE', style: TextStyle(color: green, fontSize: 8, fontWeight: FontWeight.w800))])));

  Widget _bars(String title, dynamic raw) {
    final values = Map<String, dynamic>.from(raw ?? {});
    if (values.isEmpty) return _info(Icons.query_stats_rounded, title, 'Sem dados observados ainda.');
    final max = values.values.map((v) => (v as num).toDouble()).fold<double>(1, (a, b) => a > b ? a : b);
    return Card(child: Padding(padding: const EdgeInsets.all(17), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 12), for (final e in values.entries) Padding(padding: const EdgeInsets.only(bottom: 9), child: Row(children: [SizedBox(width: 110, child: Text(e.key, style: const TextStyle(color: muted, fontSize: 11))), Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(5), child: LinearProgressIndicator(value: (e.value as num).toDouble() / max, minHeight: 9, backgroundColor: Colors.white10, color: orange))), const SizedBox(width: 9), Text('${e.value}', style: const TextStyle(fontWeight: FontWeight.w800))]))])));
  }

  Widget _learning(Map<String, dynamic> d) { final l = Map<String, dynamic>.from(d['learning'] ?? {}); return _info(Icons.auto_awesome_rounded, 'Aprendizagem operacional', '${l['mode'] ?? 'telemetry-driven'} • ${l['source'] ?? 'Core'}\n${l['meaning'] ?? 'Indicadores baseados no estado observado da plataforma.'}'); }

  Widget _moduleGrid() => LayoutBuilder(builder: (_, c) { final items = const [('IA & Agentes', Icons.psychology_rounded), ('SOC Segurança', Icons.shield_rounded), ('Business', Icons.business_center_rounded), ('Vendas', Icons.point_of_sale_rounded), ('Cloud', Icons.cloud_rounded), ('Developer', Icons.code_rounded), ('Marketplace', Icons.storefront_rounded), ('Ghost Mode', Icons.auto_awesome_rounded)]; final cols = c.maxWidth >= 850 ? 4 : 2; return GridView.count(crossAxisCount: cols, crossAxisSpacing: 10, mainAxisSpacing: 10, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), childAspectRatio: 1.3, children: [for (final x in items) Card(child: Padding(padding: const EdgeInsets.all(15), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(x.$2, color: orange), const Spacer(), Text(x.$1, style: const TextStyle(fontWeight: FontWeight.w800))])))]); });

  Widget _agents() { final d = data; final roles = Map<String, dynamic>.from(d?['agent_roles'] ?? {}); final status = Map<String, dynamic>.from(d?['agent_status'] ?? {}); return _frame('IA & Agentes', 'Agentes especializados com estado observado pelo Core', Column(children: [_bars('Agentes por função', roles), const SizedBox(height: 12), _bars('Estado dos agentes', status), const SizedBox(height: 12), _info(Icons.psychology_rounded, 'Agentes previstos', 'CEO • Comercial • Segurança • Programador • Financeiro • Marketing. O estado real só é mostrado quando existir no Core.') ])); }
  Widget _security() { final m = Map<String, dynamic>.from(data?['modules']?['seguranca'] ?? {}); return _frame('Centro de Segurança', 'SOC privado • postura baseada em eventos reais', Column(children: [_metricGrid([_metric('Eventos de auditoria', m['audit_events'], Icons.receipt_long_rounded), _metric('Acessos pendentes', m['access_pending'], Icons.person_search_rounded)]), const SizedBox(height: 12), _info(Icons.shield_rounded, 'Postura', 'Proteção controlada por RBAC, aprovação e auditoria. Sensores de rede como Wazuh, Suricata e CrowdSec só serão apresentados como ativos quando estiverem ligados ao Core.') ])); }
  Widget _business() { final m = Map<String, dynamic>.from(data?['modules']?['business'] ?? {}); return _frame('Business OS', 'CRM, ERP, operações e inteligência empresarial', Column(children: [_metricGrid([_metric('Leads', m['leads'], Icons.people_alt_rounded), _metric('Oportunidades', m['opportunities'], Icons.trending_up_rounded), _metric('Pipeline', _money(m['pipeline_value']), Icons.euro_rounded)]), const SizedBox(height: 12), _bars('Oportunidades por etapa', data?['opportunity_stages']), ])); }
  Widget _sales() { final m = Map<String, dynamic>.from(data?['modules']?['vendas'] ?? {}); return _frame('Motor de Vendas', 'Leads, funis e campanhas com dados do Core', Column(children: [_metricGrid([_metric('Leads', m['opportunities'], Icons.person_search_rounded), _metric('Campanhas', m['campaigns'], Icons.campaign_rounded)]), const SizedBox(height: 12), _info(Icons.point_of_sale_rounded, 'Automação comercial', 'Ações de venda permanecem sujeitas às permissões e aos mecanismos de aprovação da plataforma.') ])); }
  Widget _cloud() { final m = Map<String, dynamic>.from(data?['modules']?['cloud'] ?? {}); return _frame('Cloud & Infra', 'Infraestrutura privada e execução controlada', Column(children: [_metricGrid([_metric('Deployments', m['deployments'], Icons.dns_rounded)]), const SizedBox(height: 12), _bars('Estado dos deployments', m['deployment_status']), const SizedBox(height: 12), _info(Icons.lock_rounded, 'Execução', 'Deployments passam por aprovação. O cliente nunca apresenta infraestrutura como online sem telemetria do Core.') ])); }
  Widget _marketplace() { final m = Map<String, dynamic>.from(data?['modules']?['marketplace'] ?? {}); return _frame('Marketplace', 'Produtos e extensões do ecossistema Bennu', Column(children: [_metricGrid([_metric('Produtos', m['products'], Icons.storefront_rounded)]), const SizedBox(height: 12), _bars('Produtos por estado', m['product_status'])])); }

  Widget _terminal() => _frame('Terminal Inteligente', 'Interface de comandos autorizados', Column(children: [Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white12)), child: const Text('BENNU TERMINAL\n\nComandos seguros: status • health • sync\nAs operações sensíveis continuam sujeitas a RBAC e aprovação.', style: TextStyle(fontFamily: 'monospace', height: 1.6))), const SizedBox(height: 10), Row(children: [Expanded(child: TextField(controller: commandController, onSubmitted: (_) => _runCommand(), decoration: const InputDecoration(hintText: 'bennu status'))), const SizedBox(width: 8), FilledButton(onPressed: _runCommand, child: const Icon(Icons.play_arrow_rounded))]) ]));
  Future<void> _runCommand() async { final cmd = commandController.text.trim().toLowerCase(); if (cmd.isEmpty) return; commandController.clear(); if (cmd == 'clear') return; if (server.isEmpty) { _snack('Configura primeiro o Bennu Core.'); return; } try { final d = cmd == 'health' ? await BennuApi(server).health() : await BennuApi(server).dashboard(); if (!mounted) return; _snack(cmd == 'health' ? 'Core ${d['status']} • versão ${d['version']}' : 'Online • ${d['summary']['agents']} agentes • ${d['summary']['tasks']} tarefas'); } catch (e) { if (mounted) _snack('Falha: ${e.toString().replaceFirst('Exception: ', '')}'); } }
  void _snack(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Widget _owner() => _frame('Proprietário', 'Controlo de identidade e convidados', Column(children: [_info(Icons.verified_user_rounded, 'Proprietário único', 'Existe apenas um proprietário da plataforma. A administração não é distribuída pelos convidados.'), const SizedBox(height: 10), _info(Icons.person_add_alt_1_rounded, 'Convidados', 'Amigos e restaurantes podem instalar o produto, mas precisam de autenticação e aprovação antes de receber acesso ao Core.'), const SizedBox(height: 10), _info(Icons.admin_panel_settings_rounded, 'RBAC', 'Viewer, Operator, Security, Developer, Sales, Marketing e Finance são papéis controlados. O proprietário mantém a decisão final sobre acesso e permissões.'), const SizedBox(height: 10), _bars('Pedidos de acesso', data?['access_status'])]));

  Widget _settings() => _frame('Definições', 'Ligação privada entre a aplicação e o Bennu Core', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_info(Icons.lock_rounded, 'Privacidade', 'A aplicação guarda apenas o endereço do Core. Os dados operacionais permanecem na infraestrutura Bennu.'), const SizedBox(height: 14), TextField(controller: serverController, keyboardType: TextInputType.url, decoration: const InputDecoration(labelText: 'URL do Bennu Core', hintText: 'http://192.168.1.50:8000')), const SizedBox(height: 10), SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: busy ? null : saveServer, icon: const Icon(Icons.save_rounded), label: Text(busy ? 'A testar…' : 'Guardar e testar'))), const SizedBox(height: 12), const Text('Android: usa IP LAN ou HTTPS. Linux/Windows: pode usar localhost se o Core estiver na mesma máquina.', style: TextStyle(color: muted)), const SizedBox(height: 14), if (data != null) _info(Icons.check_circle_rounded, 'Ligação ativa', 'Bennu Core ${data!['version']} • telemetria disponível') ]));

  Widget _info(IconData icon, String title, String text) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: orange), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 5), Text(text, style: const TextStyle(color: muted, height: 1.45))]))])));
  String _money(dynamic v) => '€${((v as num?)?.toDouble() ?? 0).toStringAsFixed(2)}';
}
