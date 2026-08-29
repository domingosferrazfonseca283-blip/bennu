import 'dart:async';

import 'package:flutter/material.dart';

import 'analytics_models.dart';
import 'analytics_service.dart';

class LiveAnalytics extends StatefulWidget {
  final String apiUrl;
  const LiveAnalytics({super.key, required this.apiUrl});

  @override
  State<LiveAnalytics> createState() => _LiveAnalyticsState();
}

class _LiveAnalyticsState extends State<LiveAnalytics> {
  Timer? _timer;
  AnalyticsOverview? _data;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final data = await AnalyticsService(widget.apiUrl).fetchOverview();
      if (!mounted) return;
      setState(() {
        _data = data;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('LIVE ANALYTICS', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
          ],
        ),
        Text(
          data == null ? 'A aguardar dados reais...' : 'Fonte: ${data.source} • atualização automática 10s',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        if (_loading) const LinearProgressIndicator(),
        if (_error != null)
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('OFFLINE / SEM DADOS\n$_error'))),
        if (data != null) ...[
          _totals(data),
          const SizedBox(height: 16),
          _section('Tarefas por estado', data.taskStatus),
          _section('Agentes por função', data.agentRoles),
          _section('Eventos de auditoria', data.eventTypes),
        ],
      ],
    );
  }

  Widget _totals(AnalyticsOverview d) => Row(
        children: [
          Expanded(child: _metric('AGENTS', d.agents)),
          const SizedBox(width: 8),
          Expanded(child: _metric('TASKS', d.tasks)),
          const SizedBox(width: 8),
          Expanded(child: _metric('EVENTS', d.events)),
        ],
      );

  Widget _metric(String label, int value) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [Text('$value', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)), Text(label)]),
        ),
      );

  Widget _section(String title, List<CountItem> items) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (items.isEmpty) const Text('Sem dados reais.'),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(children: [Expanded(child: Text(item.label)), Text('${item.count}', style: const TextStyle(fontWeight: FontWeight.bold))]),
                )),
          ]),
        ),
      );
}
