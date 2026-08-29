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
            title: Text(destinations[index].$2, style: const TextStyle(fontWeight: FontWeight.w800)),
            actions: [
              IconButton(
                tooltip: 'Perfil',
                onPressed: () {},
                icon: const Icon(Icons.account_circle_outlined),
              ),
            ],
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
      subtitle: 'Visão geral do teu ambiente Bennu.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _HeroCard(),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.45,
            children: const [
              _MetricCard(icon: Icons.dns_rounded, title: 'Serviços', value: '4', detail: '3 online · 1 parado'),
              _MetricCard(icon: Icons.security_rounded, title: 'Segurança', value: 'Ativa', detail: 'Ambiente protegido'),
              _MetricCard(icon: Icons.memory_rounded, title: 'Sistema', value: 'OK', detail: 'Recursos disponíveis'),
              _MetricCard(icon: Icons.cloud_done_rounded, title: 'API', value: 'Online', detail: 'Ligação operacional'),
            ],
          ),
          const SizedBox(height: 24),
          Text('Acesso rápido', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          const _QuickAction(icon: Icons.terminal_rounded, title: 'Abrir Terminal', subtitle: 'Executar comandos autorizados'),
          const _QuickAction(icon: Icons.dns_rounded, title: 'Ver Serviços', subtitle: 'Estado dos componentes Bennu'),
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
          Text('O teu centro de comando está pronto.', style: TextStyle(fontSize: 16, color: Colors.white70)),
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const Spacer(),
          Text(title, style: const TextStyle(color: Colors.white60)),
          Text(value, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
          Text(detail, style: const TextStyle(fontSize: 12, color: Colors.white54)),
        ]),
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
        onTap: () {},
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
        child: Column(children: const [
          _ServiceTile('Bennu API', 'Online', Icons.cloud_done_rounded, true),
          _ServiceTile('Dashboard', 'Online', Icons.dashboard_rounded, true),
          _ServiceTile('Terminal', 'Online', Icons.terminal_rounded, true),
          _ServiceTile('Worker', 'Parado', Icons.memory_rounded, false),
        ]),
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
        trailing: Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      ),
    );
  }
}

class TerminalPage extends StatelessWidget {
  const TerminalPage({super.key});

  @override
  Widget build(BuildContext context) => _PageScroll(
        title: 'Terminal',
        subtitle: 'Operações administrativas autorizadas.',
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: const Color(0xFF050608), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white12)),
          child: const SelectableText(
            r'$ bennu status\n\nBennu OS       ONLINE\nAPI             ONLINE\nDashboard       ONLINE\nTerminal        ONLINE\n\n$ _',
            style: TextStyle(fontFamily: 'monospace', fontSize: 14, height: 1.6),
          ),
        ),
      );
}

class AppsPage extends StatelessWidget {
  const AppsPage({super.key});

  @override
  Widget build(BuildContext context) => _PageScroll(
        title: 'Aplicações',
        subtitle: 'Ferramentas disponíveis no ecossistema Bennu.',
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.25,
          children: const [
            _AppCard(Icons.terminal_rounded, 'Terminal', 'Administração'),
            _AppCard(Icons.dashboard_rounded, 'Dashboard', 'Monitorização'),
            _AppCard(Icons.storage_rounded, 'Storage', 'Dados'),
            _AppCard(Icons.security_rounded, 'Security', 'Proteção'),
          ],
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
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, size: 30, color: Theme.of(context).colorScheme.primary),
            const Spacer(),
            Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            Text(description, style: const TextStyle(color: Colors.white60)),
          ]),
        ),
      );
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) => _PageScroll(
        title: 'Definições',
        subtitle: 'Personaliza o cliente Bennu.',
        child: Column(children: [
          Card(child: SwitchListTile(value: true, onChanged: (_) {}, title: const Text('Modo escuro'), subtitle: const Text('Interface otimizada para uso contínuo'))),
          const SizedBox(height: 10),
          const Card(child: ListTile(leading: Icon(Icons.language_rounded), title: Text('Idioma'), subtitle: Text('Português (Portugal)'))),
          const SizedBox(height: 10),
          const Card(child: ListTile(leading: Icon(Icons.info_outline_rounded), title: Text('Sobre o Bennu'), subtitle: Text('Versão 0.6.6'))),
        ]),
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
