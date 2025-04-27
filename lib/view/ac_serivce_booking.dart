import 'package:flutter/material.dart';

class AcServiceBookingScreen extends StatefulWidget {
  const AcServiceBookingScreen({super.key});

  @override
  State<AcServiceBookingScreen> createState() => _AcServiceBookingScreenState();
}

class _AcServiceBookingScreenState extends State<AcServiceBookingScreen> {
  Map<String, int> selectedServices = {};
  TextEditingController totalPriceController = TextEditingController();

  void increaseQuantity(String service, int price) {
    setState(() {
      selectedServices[service] = (selectedServices[service] ?? 0) + 1;
    });
    updateTotalPrice();
  }

  void decreaseQuantity(String service) {
    setState(() {
      if (selectedServices.containsKey(service) && selectedServices[service]! > 0) {
        selectedServices[service] = selectedServices[service]! - 1;
        if (selectedServices[service] == 0) {
          selectedServices.remove(service);
        }
      }
    });
    updateTotalPrice();
  }

  void updateTotalPrice() {
    int total = 0;
    selectedServices.forEach((service, quantity) {
      int price = services
          .expand((category) => category["services"])
          .firstWhere((s) => s["name"] == service)["price"];
      total += price * quantity;
    });
    totalPriceController.text = "₹$total";
  }

  bool get isBookingAvailable => selectedServices.isNotEmpty;
List<Map<String, dynamic>> services = [
      {
        "category": "AIR CONDITIONER",
        "services": [
          {"name": "General Service", "price": 500},
          {"name": "Detailed Service", "price": 750},
          {"name": "Installation- Regular AC", "price": 1350},
          {"name": "Installation- Inverter AC", "price": 1650},
          {"name": "Uninstallation", "price": 700},
          {"name": "Inspection Charges", "price": 350},
        ]
      },
      {
        "category": "FRIDGE",
        "services": [
          {"name": "Service - Single Door", "price": 449},
          {"name": "Service - Double Door", "price": 549},
          {"name": "Service - Side by Side", "price": 899},
          {"name": "Service - Chest Deep Freezer", "price": 599},
          {"name": "Inspection Charges", "price": 349},
        ]
      },
      {
        "category": "WASHING MACHINE",
        "services": [
          {"name": "Semi Automatic", "price": 449},
          {"name": "Fully Automatic - Top Load", "price": 549},
          {"name": "Fully Automatic - Front Load", "price": 799},
          {"name": "Clothes Dryer", "price": 349},
          {"name": "Inspection Charges", "price": 350},
        ]
      },
      {
        "category": "TELEVISION",
        "services": [
          {"name": "LCD/LED TV upto 20 Inches", "price": 349},
          {"name": "LED TV 21 to 41 Inches", "price": 499},
          {"name": "LED TV above 42 Inches", "price": 599},
          {"name": "TV Installation", "price": 459},
          {"name": "Inspection Charges", "price": 349},
        ]
      },
      {
        "category": "MICROWAVE OVEN",
        "services": [
          {"name": "Service Charges", "price": 459},
          {"name": "Inspection Charges", "price": 349},
        ]
      },
      {
        "category": "GAS STOVE",
        "services": [
          {"name": "Service - 2 Burners", "price": 299},
          {"name": "Service - 3 Burners", "price": 349},
          {"name": "Service - 4 Burners", "price": 399},
          {"name": "Hob Service", "price": 449},
          {"name": "Chimney", "price": 549},
          {"name": "Cooking Range Service", "price": 999},
          {"name": "Fitting Charge/Inspection", "price": 249},
        ]
      },
      {
        "category": "WATER PURIFIER",
        "services": [
          {"name": "Service Charges", "price": 399},
          {"name": "Inspection Charges", "price": 259},
        ]
      },
      {"category": "MIXER", "services": [{"name": "Service Charges", "price": 350}]},
      {"category": "GRINDER", "services": [{"name": "Service Charges", "price": 399}]},
      {"category": "CHIMNEY", "services": [{"name": "Service Charges", "price": 599}]},
      {"category": "INDUCTION COOKER", "services": [{"name": "Service Charges", "price": 350}]},
      {"category": "COOKING RANGE", "services": [{"name": "Service Charges", "price": 599}]},
      {"category": "FITNESS EQUIPMENT", "services": [{"name": "Service Charges", "price": 1500}]},
    ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("APPLIANCE REPAIRS", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: services.map((category) {
          return ExpansionTile(
            title: Text(category["category"],
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            children: category["services"].map<Widget>((service) {
              return ServiceItem(
                service: service,
                quantity: selectedServices[service["name"]] ?? 0,
                onIncrease: () => increaseQuantity(service["name"], service["price"]),
                onDecrease: () => decreaseQuantity(service["name"]),
              );
            }).toList(),
          );
        }).toList(),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: totalPriceController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: "Total Price",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: isBookingAvailable ? () {} : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isBookingAvailable ? Colors.black : Colors.grey[300],
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
              ),
              child: const Text("BOOK NOW", style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

class ServiceItem extends StatelessWidget {
  final Map<String, dynamic> service;
  final int quantity;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  const ServiceItem({
    super.key,
    required this.service,
    required this.quantity,
    required this.onIncrease,
    required this.onDecrease,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(service["name"], style: const TextStyle(fontSize: 14))),
          Text("₹${service["price"]}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          Row(
            children: [
              IconButton(icon: const Icon(Icons.remove), onPressed: quantity > 0 ? onDecrease : null),
              Text("$quantity", style: const TextStyle(fontSize: 16)),
              IconButton(icon: const Icon(Icons.add), onPressed: onIncrease),
            ],
          ),
        ],
      ),
    );
  }
}
