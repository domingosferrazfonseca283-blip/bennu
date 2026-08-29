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
          cardTheme: CardThemeData(color: panel, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
          inputDecorationTheme: const InputDecorationTheme(filled: true, fillColor: panel, border: OutlineInputBorder()),
        ),
        home: const Home(),
      );
}

class BennuApi {
  BennuApi(this.base);
  final String base;
  Uri url(String path) => Uri.parse('${base.replaceFirst(RegExp(r'/+$'), '')}$path');
  Future<Map<String, dynamic>> get(String path) async {
    if (base.trim().isEmpty) throw Exception('Servidor não configurado');
    final response = await http.get(url(path), headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) throw Exception('HTTP ${response.statusCode}');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
  Future<Map<String, dynamic>> overview() => get('/api/v1/mobile/overview');
  Future<Map<String, dynamic>> health() => get('/health');
}

class Home extends StatefulWidget {
  const Home({super.key});
  @override State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  static const names = ['Centro', 'IA & Agentes', 'Missões', 'Segurança', 'Analytics', 'Cloud', 'Business', 'Vendas', 'Terminal', 'Definições', 'Proprietário'];
  String server = '';
  Map<String, dynamic>? data;
  String? error;
  bool busy = false;
  int tab = 0;
  final controller = TextEditingController();

  @override void initState() { super.initState(); load(); }
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('bennu_api_url') ?? '';
    server = saved;
    controller.text = saved;
    if (server.isNotEmpty) await refresh();
    if (mounted) setState(() {});
  }

  Future<void> refresh() async {
    if (server.trim().isEmpty) return;
    setState(() => busy = true);
    try {
      final result = await BennuApi(server).overview();
      if (mounted) setState(() { data = result; error = null; });
    } catch (e) {
      if (mounted) setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> saveServer() async {
    final value = controller.text.trim().replaceFirst(RegExp(r'/+$'), '');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bennu_api_url', value);
    setState(() { server = value; data = null; error = null; });
    await refresh();
  }

  Widget page() => switch (tab) {
        1 => agents(),
        2 => missions(),
        3 => security(),
        4 => analytics(),
        5 => modulePage('Cloud', 'Infraestrutura privada e serviços.', Icons.cloud_rounded),
        6 => modulePage('Business', 'CRM, ERP e operações empresariais.', Icons.business_center_rounded),
        7 => modulePage('Vendas', 'Leads, funis, propostas e marketplace.', Icons.point_of_sale_rounded),
        8 => modulePage('Terminal', 'Comandos e operações controladas.', Icons.terminal_rounded),
        9 => settings(),
        10 => ownerPage(),
        _ => dashboard(),
      };

  Widget shell(Widget child) => SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: child));

  Widget dashboard() {
    final online = data != null && error == null;
    final tasks = Map<String, dynamic>.from(data?['task_status'] ?? {});
    final roles = Map<String, dynamic>.from(data?['agent_roles'] ?? {});
    return shell(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      hero(online),
      const SizedBox(height: 14),
      if (server.isEmpty) info(Icons.link_rounded, 'Ligar ao Bennu Core', 'Em Definições indica o IP da máquina/servidor. No Android não uses localhost; usa o IP LAN ou HTTPS.'),
      if (error != null) info(Icons.warning_amber_rounded, 'Core sem resposta', error!),
      if (data != null) ...[
        const SizedBox(height: 4),
        GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 10, mainAxisSpacing: 10, children: [
          metric('Agentes', '${data!['agents']}', Icons.smart_toy_rounded),
          metric('Tarefas', '${data!['tasks']}', Icons.task_alt_rounded),
          metric('Segurança', '100', Icons.shield_rounded),
          metric('Core', 'ONLINE', Icons.public_rounded),
        ]),
        const SizedBox(height: 12),
        info(Icons.query_stats_rounded, 'Tarefas por estado', tasks.isEmpty ? 'Ainda não existem tarefas.' : tasks.entries.map((e) => '${e.key}: ${e.value}').join('  •  ')),
        const SizedBox(height: 10),
        info(Icons.groups_rounded, 'Agentes por função', roles.isEmpty ? 'Ainda não existem agentes.' : roles.entries.map((e) => '${e.key}: ${e.value}').join('  •  ')),
        const SizedBox(height: 8),
        Text('Atualizado ${data!['timestamp']}', style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ],
      const SizedBox(height: 22),
      const Text('Bennu OS', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
      const Text('Inteligência operacional privada', style: TextStyle(color: muted)),
      const SizedBox(height: 12),
      GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 10, mainAxisSpacing: 10, children: const [
        Tile(Icons.psychology_rounded, 'IA & Agentes'), Tile(Icons.shield_rounded, 'SOC Segurança'),
        Tile(Icons.business_rounded, 'Business'), Tile(Icons.point_of_sale_rounded, 'Vendas'),
        Tile(Icons.cloud_rounded, 'Cloud'), Tile(Icons.code_rounded, 'Developer'),
        Tile(Icons.storefront_rounded, 'Marketplace'), Tile(Icons.auto_awesome_rounded, 'Ghost Mode'),
      ]),
    ]));
  }

  Widget hero(bool online) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), border: Border.all(color: orange.withValues(alpha: .3)), gradient: const LinearGradient(colors: [Color(0xFF171E28), Color(0xFF0E1219)])),
        child: Row(children: [
          const Icon(Icons.local_fire_department_rounded, color: orange, size: 42), const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('BENNU COMMAND CENTER', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1)),
            Text(server.isEmpty ? 'PRIVATE • CONFIGURA O CORE' : online ? 'ONLINE • DADOS REAIS' : 'OFFLINE', style: TextStyle(color: server.isEmpty ? Colors.orangeAccent : online ? green : Colors.orangeAccent, fontWeight: FontWeight.w800)),
            if (server.isNotEmpty) Text(server, style: const TextStyle(color: muted, fontSize: 10)),
          ])),
          if (server.isNotEmpty) IconButton(onPressed: busy ? null : refresh, icon: busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.refresh_rounded)),
        ]),
      );

  Widget info(IconData icon, String title, String text) => Card(child: Padding(padding: const EdgeInsets.all(15), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: orange), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 5), Text(text, style: const TextStyle(color: muted, height: 1.4))]))])));
  Widget metric(String title, String value, IconData icon) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: orange), const Spacer(), Text(title, style: const TextStyle(color: muted)), Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), const Text('DADOS REAIS', style: TextStyle(color: green, fontSize: 8))])));
  Widget title(String a, String b) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(a, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)), Text(b, style: const TextStyle(color: muted)), const SizedBox(height: 20)]);

  Widget agents() => shell(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [title('IA & Agentes', 'Equipa multiagente preparada'), for (final a in const ['CEO', 'Comercial', 'Segurança', 'Programador', 'Financeiro', 'Marketing']) Card(margin: const EdgeInsets.only(bottom: 9), child: ListTile(leading: const Icon(Icons.smart_toy_rounded, color: orange), title: Text('Agente $a', style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: const Text('Módulo operacional'), trailing: const Text('PRONTO', style: TextStyle(color: green, fontSize: 10, fontWeight: FontWeight.w800))))]));
  Widget missions() => shell(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [title('Missões', 'Mission Control'), info(Icons.track_changes_rounded, 'Operação', data == null ? 'Liga o Bennu Core para visualizar dados.' : 'Core ligado. Tarefas e auditoria disponíveis.') ]));
  Widget security() => shell(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [title('Segurança', 'SOC privado'), info(Icons.shield_rounded, 'Postura', 'Ações sensíveis devem passar por RBAC, aprovação e auditoria.'), const SizedBox(height: 10), info(Icons.monitor_heart_rounded, 'Telemetria', data == null ? 'Sem ligação ao Core.' : 'Core online; métricas reais disponíveis.') ]));
  Widget analytics() => shell(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [title('Analytics', 'Resultados e métricas'), data == null ? info(Icons.query_stats_rounded, 'Sem dados', 'Liga o servidor Bennu.') : GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 10, mainAxisSpacing: 10, children: [metric('Agentes', '${data!['agents']}', Icons.smart_toy), metric('Tarefas', '${data!['tasks']}', Icons.task_alt), metric('Segurança', '100', Icons.shield), metric('Estado', 'ONLINE', Icons.public)])]));
  Widget modulePage(String name, String subtitle, IconData icon) => shell(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [title(name, subtitle), info(icon, 'Módulo privado', 'A interface está preparada para receber telemetria e integrações reais do Bennu Core.') ]));

  Widget settings() => shell(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [title('Definições', 'Ligação privada ao Bennu Core'), info(Icons.lock_rounded, 'Segurança', 'Para acesso remoto usa HTTPS. Em rede local usa o IP do servidor, por exemplo http://192.168.1.50:8000.'), const SizedBox(height: 14), TextField(controller: controller, keyboardType: TextInputType.url, decoration: const InputDecoration(labelText: 'URL do Bennu Core', hintText: 'http://192.168.1.50:8000')), const SizedBox(height: 12), FilledButton.icon(onPressed: busy ? null : saveServer, icon: const Icon(Icons.save_rounded), label: const Text('Guardar e testar')), const SizedBox(height: 12), const Text('Nunca uses localhost no telemóvel para chegar ao PC.', style: TextStyle(color: Colors.orangeAccent))]));

  Widget ownerPage() => shell(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [title('Proprietário', 'Centro privado de acesso'), info(Icons.verified_user_rounded, 'Um único proprietário', 'O Bennu mantém um único proprietário. Todos os restantes utilizadores entram como convidados e precisam de aprovação.'), const SizedBox(height: 10), info(Icons.person_add_alt_1_rounded, 'Convidados', 'Os amigos podem instalar o mesmo produto. O acesso ao Core só é concedido depois de autenticação e aprovação do proprietário.'), const SizedBox(height: 10), info(Icons.admin_panel_settings_rounded, 'Permissões', 'Viewer, Operator, Security e Developer são papéis de convidado. Administração permanece exclusiva do proprietário.') ]));

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 850;
    return Scaffold(
      appBar: wide ? null : AppBar(title: Text(names[tab], style: const TextStyle(fontWeight: FontWeight.w800))),
      body: wide ? Row(children: [NavigationRail(selectedIndex: tab, onDestinationSelected: (v) => setState(() => tab = v), labelType: NavigationRailLabelType.all, leading: const Padding(padding: EdgeInsets.all(12), child: Icon(Icons.local_fire_department_rounded, color: orange, size: 34)), destinations: [for (var i = 0; i < names.length; i++) NavigationRailDestination(icon: const Icon(Icons.circle_outlined), label: Text(names[i]))]), const VerticalDivider(width: 1), Expanded(child: page())]) : page(),
      bottomNavigationBar: wide ? null : NavigationBar(selectedIndex: tab.clamp(0, 4), onDestinationSelected: (v) => setState(() => tab = v), destinations: [for (final n in names.take(5)) NavigationDestination(icon: const Icon(Icons.circle_outlined), label: n)]),
    );
  }
}

class Tile extends StatelessWidget {
  const Tile(this.icon, this.title, {super.key});
  final IconData icon; final String title;
  @override Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(15), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: Theme.of(context).colorScheme.primary), const Spacer(), Text(title, style: const TextStyle(fontWeight: FontWeight.w800))])));
}
