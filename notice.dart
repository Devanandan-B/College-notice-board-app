class Notice {
  final String id;
  final String title;
  final String? description;
  final DateTime eventDate;
  final String? venue;
  final String? clubId;
  final String createdBy;

  Notice({
    required this.id,
    required this.title,
    this.description,
    required this.eventDate,
    this.venue,
    this.clubId,
    required this.createdBy,
  });

  factory Notice.fromMap(Map<String, dynamic> map) => Notice(
        id: map['id'] as String,
        title: map['title'] as String,
        description: map['description'] as String?,
        eventDate: DateTime.parse(map['event_date'] as String),
        venue: map['venue'] as String?,
        clubId: map['club_id'] as String?,
        createdBy: map['created_by'] as String,
      );
}
