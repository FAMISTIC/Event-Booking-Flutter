class Event {
  final String id;
  final String name;
  final DateTime date;
  final String venue;
  final int totalTickets;
  final int availableTickets;
  final double ticketPrice;
  final DateTime createdAt;

  Event({
    required this.id,
    required this.name,
    required this.date,
    required this.venue,
    required this.totalTickets,
    required this.availableTickets,
    required this.ticketPrice,
    required this.createdAt,
  });

  bool get isVIPWindowActive {
    final now = DateTime.now();
    return now.difference(createdAt).inHours < 24;
  }

  bool get isPast => date.isBefore(DateTime.now());
}
