class Booking {
  final String id;
  final String userId;
  final String eventId;
  final String eventName;
  final int ticketCount;
  final double totalPrice;
  final DateTime bookedAt;

  Booking({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.eventName,
    required this.ticketCount,
    required this.totalPrice,
    required this.bookedAt,
  });
}
