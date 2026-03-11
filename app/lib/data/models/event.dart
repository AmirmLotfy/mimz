/// Event model
class MimzEvent {
  final String id;
  final String title;
  final EventStatus status;
  final int participants;
  final String description;
  final DateTime? startsAt;

  const MimzEvent({
    required this.id,
    required this.title,
    this.status = EventStatus.upcoming,
    this.participants = 0,
    this.description = '',
    this.startsAt,
  });

  factory MimzEvent.fromJson(Map<String, dynamic> json) => MimzEvent(
        id: json['id'] as String,
        title: json['title'] as String,
        status: EventStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => EventStatus.upcoming,
        ),
        participants: json['participants'] as int? ?? 0,
        description: json['description'] as String? ?? '',
        startsAt: json['startsAt'] != null
            ? DateTime.tryParse(json['startsAt'] as String)
            : null,
      );
}

enum EventStatus { live, upcoming, completed }
