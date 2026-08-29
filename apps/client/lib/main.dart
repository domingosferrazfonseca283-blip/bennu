import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() => runApp(const BennuApp());

class BennuApp extends StatelessWidget {
  const BennuApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFFF6B35),
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: 'Bennu',
      debugShowCheckedModeBanner: false,
      locale: const Locale('pt', 'PT'),
      supportedLocales: const [Locale('pt', 'PT'), Locale('en', 'US')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFF090B0F),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF090B0F),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF12161C),
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
      home: const BennuShell(),
    );
  }
}

class BennuShell extends StatefulWidget {
  const BennuShell({super.key});

  @override
  State<BennuShell> createState() => _BennuShellState();
}

class _BennuShellState extends State<BennuShell> {
  int index = 0;

  static const destinations = [
    (Icons.dashboard_rounded, 'Painel'),
    (Icons.dns_rounded, 'Serviços'),
    (Icons.terminal_rounded, 'Terminal'),
    (Icons.apps_rounded, 'Aplicações'),
    (Icons.settings_rounded, 'Definições'),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;
        final page = _page(index);

        if (wide) {
          return Scaffold(
            body: Row(
              children: [
                _Rail(selected: index, onSelected: _select),
                const VerticalDivider(width: 1),
                Expanded(child: page),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              destinations[index].$2,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          body: page,
          bottomNavigationBar: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: _select,
            destinations: [
              for (final item in destinations.take(4))
                NavigationDestination(icon: Icon(item.$1), label: item.$2),
            ],
          ),
        );
      },
    );
  }

  void _select(int value) => setState(() => index = value);

  Widget _page(int value) {
    switch (value) {
      case 1:
        return const ServicesPage();
      case 2:
        return const TerminalPage();
      case 3:
        return const AppsPage();
      case 4:
        return const SettingsPage();
      default:
        return const DashboardPage();
    }
  }
}

class _Rail extends StatelessWidget {
  const _Rail({required this.selected, required this.onSelected});
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: selected,
      onDestinationSelected: onSelected,
      labelType: NavigationRailLabelType.all,
      leading: Padding(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 28),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.local_fire_department_rounded),
            ),
            const SizedBox(height: 8),
            const Text('Bennu', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
      destinations: const [
        NavigationRailDestination(icon: Icon(Icons.dashboard_rounded), label: Text('Painel')),
        NavigationRailDestination(icon: Icon(Icons.dns_rounded), label: Text('Serviços')),
        NavigationRailDestination(icon: Icon(Icons.terminal_rounded), label: Text('Terminal')),
        NavigationRailDestination(icon: Icon(Icons.apps_rounded), label: Text('Aplicações')),
        NavigationRailDestination(icon: Icon(Icons.settings_rounded), label: Text('Definições')),
      ],
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _PageScroll(
      title: 'Centro de Comando',
      subtitle: 'O teu ambiente Bennu num só lugar.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _HeroCard(),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 760 ? 4 : 2;
              return GridView.count(
                crossAxisCount: columns,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.45,
                children: const [
                  _MetricCard(icon: Icons.dns_rounded, title: 'Serviços', value: '3/4', detail: 'online'),
                  _MetricCard(icon: Icons.security_rounded, title: 'Segurança', value: 'Ativa', detail: 'protegido'),
                  _MetricCard(icon: Icons.memory_rounded, title: 'Sistema', value: 'OK', detail: 'recursos normais'),
                  _MetricCard(icon: Icons.cloud_done_rounded, title: 'API', value: 'Online', detail: 'ligação disponível'),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Acesso rápido',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          const _QuickAction(icon: Icons.terminal_rounded, title: 'Abrir Terminal', subtitle: 'Executar comandos autorizados'),
          const _QuickAction(icon: Icons.dns_rounded, title: 'Ver Serviços', subtitle: 'Monitorizar os componentes Bennu'),
          const _QuickAction(icon: Icons.system_update_rounded, title: 'Atualizações', subtitle: 'Verificar novas versões'),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.primary, const Color(0xFF8E2F1B)],
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.local_fire_department_rounded, size: 44),
          SizedBox(height: 18),
          Text('Bennu está operacional', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
          SizedBox(height: 7),
          Text('Centro de comando pronto para utilização.', style: TextStyle(fontSize: 16, color: Colors.white70)),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.icon, required this.title, required this.value, required this.detail});
  final IconData icon;
  final String title;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const Spacer(),
            Text(title, style: const TextStyle(color: Colors.white60)),
            Text(value, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
            Text(detail, style: const TextStyle(fontSize: 12, color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class ServicesPage extends StatelessWidget {
  const ServicesPage({super.key});

  @override
  Widget build(BuildContext context) => _PageScroll(
        title: 'Serviços',
        subtitle: 'Estado dos componentes do Bennu.',
        child: Column(
          children: const [
            _ServiceTile('Bennu API', 'Online', Icons.cloud_done_rounded, true),
            _ServiceTile('Dashboard', 'Online', Icons.dashboard_rounded, true),
            _ServiceTile('Terminal', 'Online', Icons.terminal_rounded, true),
            _ServiceTile('Worker', 'Parado', Icons.memory_rounded, false),
          ],
        ),
      );
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile(this.name, this.state, this.icon, this.online);
  final String name;
  final String state;
  final IconData icon;
  final bool online;

  @override
  Widget build(BuildContext context) {
    final color = online ? Colors.greenAccent : Colors.orangeAccent;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(state),
        trailing: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

class TerminalPage extends StatefulWidget {
  const TerminalPage({super.key});

  @override
  State<TerminalPage> createState() => _TerminalPageState();
}

class _TerminalPageState extends State<TerminalPage> {
  final controller = TextEditingController();
  final lines = <String>[
    'Bennu Terminal',
    'Ligação local preparada.',
    'Escreve "help" para ver os comandos disponíveis.',
  ];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void execute() {
    final command = controller.text.trim();
    if (command.isEmpty) return;
    setState(() {
      lines.add('> $command');
      switch (command.toLowerCase()) {
        case 'help':
          lines.add('status   Mostra o estado do Bennu');
          lines.add('version  Mostra a versão do cliente');
          lines.add('clear    Limpa o terminal');
          break;
        case 'status':
          lines.add('Bennu       ONLINE');
          lines.add('API         ONLINE');
          lines.add('Dashboard   ONLINE');
          lines.add('Worker      STOPPED');
          break;
        case 'version':
          lines.add('Bennu Client 0.6.7');
          break;
        case 'clear':
          lines.clear();
          break;
        default:
          lines.add('Comando desconhecido. Usa "help".');
      }
      controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) => _PageScroll(
        title: 'Terminal',
        subtitle: 'Comandos locais autorizados.',
        child: Column(
          children: [
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 300),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF050608),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white12),
              ),
              child: SelectableText(
                lines.join('\n'),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 14, height: 1.6),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    onSubmitted: (_) => execute(),
                    decoration: const InputDecoration(
                      hintText: 'Escreve um comando…',
                      prefixIcon: Icon(Icons.chevron_right_rounded),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: execute,
                  style: FilledButton.styleFrom(minimumSize: const Size(56, 56)),
                  child: const Icon(Icons.play_arrow_rounded),
                ),
              ],
            ),
          ],
        ),
      );
}

class AppsPage extends StatelessWidget {
  const AppsPage({super.key});

  @override
  Widget build(BuildContext context) => _PageScroll(
        title: 'Aplicações',
        subtitle: 'Ferramentas do ecossistema Bennu.',
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 760 ? 4 : 2;
            return GridView.count(
              crossAxisCount: columns,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.25,
              children: const [
                _AppCard(Icons.terminal_rounded, 'Terminal', 'Administração'),
                _AppCard(Icons.dashboard_rounded, 'Dashboard', 'Monitorização'),
                _AppCard(Icons.storage_rounded, 'Storage', 'Dados'),
                _AppCard(Icons.security_rounded, 'Segurança', 'Proteção'),
              ],
            );
          },
        ),
      );
}

class _AppCard extends StatelessWidget {
  const _AppCard(this.icon, this.name, this.description);
  final IconData icon;
  final String name;
  final String description;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 30, color: Theme.of(context).colorScheme.primary),
              const Spacer(),
              Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
              Text(description, style: const TextStyle(color: Colors.white60)),
            ],
          ),
        ),
      );
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) => _PageScroll(
        title: 'Definições',
        subtitle: 'Personaliza o cliente Bennu.',
        child: Column(
          children: const [
            Card(child: SwitchListTile(value: true, onChanged: null, title: Text('Modo escuro'), subtitle: Text('Interface otimizada para uso contínuo'))),
            SizedBox(height: 10),
            Card(child: ListTile(leading: Icon(Icons.language_rounded), title: Text('Idioma'), subtitle: Text('Português (Portugal)'))),
            SizedBox(height: 10),
            Card(child: ListTile(leading: Icon(Icons.info_outline_rounded), title: Text('Sobre o Bennu'), subtitle: Text('Versão 0.6.7'))),
          ],
        ),
      );
}

class _PageScroll extends StatelessWidget {
  const _PageScroll({required this.title, required this.subtitle, required this.child});
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(color: Colors.white60)),
            const SizedBox(height: 24),
            child,
          ],
        ),
      );
}
