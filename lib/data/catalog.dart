// Products, categories and orders now come from the Laravel API (see models.dart / app_state.dart).
// What remains here is artwork plus the sample data for the milk-subscription and milk-route
// screens, which have no backend yet.
export 'models.dart';

class Img {
  Img._();
  static const sweets = 'assets/images/sweets_platter.jpg';
  static const milkSweets = 'assets/images/milk_sweets.jpg';
  static const namkeen = 'assets/images/namkeen.jpg';
  static const devbhoomi = 'assets/images/devbhoomi.jpg';
}

// ---------------- Milk ----------------
class Milk {
  Milk._();
  static const pricePerLitre = 68;
  static const quantities = ['1 L', '2 L', '3 L', 'Custom'];
  static const frequencies = ['Every day', 'Alternate days', 'Select days'];
  static const slots = ['Morning · 6:00–7:00 AM', 'Morning · 7:00–8:00 AM', 'Evening · 5:00–6:00 PM'];

  static int deliveriesPerWeek(String frequency) => switch (frequency) {
        'Alternate days' => 4,
        'Select days' => 5,
        _ => 7,
      };
}

// ---------------- Staff route ----------------
enum StopStatus { scheduled, delivered, exception }

class DeliveryStop {
  final int number;
  final String name;
  final String address;
  final int litres;
  final String note;
  StopStatus status;

  DeliveryStop(this.number, this.name, this.address, this.litres, this.note, this.status);

  int get charge => litres * Milk.pricePerLitre;
  int get bottles => litres;
}

List<DeliveryStop> buildDemoRoute() {
  const done = [
    'Kavita Pant', 'Suresh Bhatt', 'Meena Arya', 'Deepak Joshi', 'Ritu Tiwari', 'Harish Rawat',
    'Lata Bisht', 'Mohan Negi', 'Sunita Kandpal', 'Gopal Pandey', 'Nisha Mehra', 'Anil Bora',
  ];
  final stops = <DeliveryStop>[
    for (var i = 0; i < done.length; i++)
      DeliveryStop(i + 1, done[i], '${2 + i * 2}, Patel Nagar', 2, 'Leave at the door.', StopStatus.delivered),
  ];
  final pending = <(String, int, int)>[
    ('Aarav Sharma', 24, 2),
    ('Neha Joshi', 28, 1),
    ('Vikram Rawat', 32, 2),
    ('Pooja Bisht', 36, 1),
    ('Rohit Negi', 40, 2),
    ('Anjali Rana', 44, 3),
    ('Kiran Pathak', 48, 2),
    ('Manoj Karki', 52, 2),
    ('Seema Dhami', 56, 1),
    ('Prakash Bisht', 60, 2),
    ('Rekha Adhikari', 64, 3),
    ('Tarun Saini', 68, 3),
  ];
  for (var i = 0; i < pending.length; i++) {
    final p = pending[i];
    stops.add(DeliveryStop(
      13 + i,
      p.$1,
      '${p.$2}, Patel Nagar, Kashipur',
      p.$3,
      i == 0 ? 'Please ring the bell. Hand over at the front door.' : 'Collect empty bottles from the gate.',
      StopStatus.scheduled,
    ));
  }
  return stops;
}
