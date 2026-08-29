class AnalyticsOverview {
  final String status;
  final String source;
  final String timestamp;
  final int tasks;
  final int agents;
  final int events;
  final List<CountItem> taskStatus;
  final List<CountItem> agentRoles;
  final List<CountItem> eventTypes;

  const AnalyticsOverview({
    required this.status,
    required this.source,
    required this.timestamp,
    required this.tasks,
    required this.agents,
    required this.events,
    required this.taskStatus,
    required this.agentRoles,
    required this.eventTypes,
  });

  factory AnalyticsOverview.fromJson(Map<String, dynamic> json) {
    final totals = Map<String, dynamic>.from(json['totals'] ?? const {});
    List<CountItem> parse(String key, String labelKey) =>
        (json[key] as List? ?? const [])
            .map((item) => CountItem(
                  label: '${item[labelKey] ?? 'unknown'}',
                  count: (item['count'] as num?)?.toInt() ?? 0,
                ))
            .toList();

    return AnalyticsOverview(
      status: '${json['status'] ?? 'unknown'}',
      source: '${json['source'] ?? 'unknown'}',
      timestamp: '${json['timestamp'] ?? ''}',
      tasks: (totals['tasks'] as num?)?.toInt() ?? 0,
      agents: (totals['agents'] as num?)?.toInt() ?? 0,
      events: (totals['events'] as num?)?.toInt() ?? 0,
      taskStatus: parse('task_status', 'status'),
      agentRoles: parse('agent_roles', 'role'),
      eventTypes: parse('event_types', 'type'),
    );
  }
}

class CountItem {
  final String label;
  final int count;
  const CountItem({required this.label, required this.count});
}
