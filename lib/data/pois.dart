import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Point of Interest data class
class PointOfInterest {
  final String name;
  final String nameBn;
  final LatLng location;
  final IconData icon;
  final Color color;
  final String category;
  final String description;
  final String? phone;
  final String? imageUrl;
  final bool isCustom;

  const PointOfInterest({
    required this.name,
    this.nameBn = '',
    required this.location,
    required this.icon,
    required this.color,
    required this.category,
    this.description = 'A notable place in Kushtia District.',
    this.phone,
    this.imageUrl,
    this.isCustom = false,
  });

  PointOfInterest copyWith({
    String? name,
    String? nameBn,
    LatLng? location,
    IconData? icon,
    Color? color,
    String? category,
    String? description,
    String? phone,
    String? imageUrl,
    bool? isCustom,
  }) {
    return PointOfInterest(
      name: name ?? this.name,
      nameBn: nameBn ?? this.nameBn,
      location: location ?? this.location,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      category: category ?? this.category,
      description: description ?? this.description,
      phone: phone ?? this.phone,
      imageUrl: imageUrl ?? this.imageUrl,
      isCustom: isCustom ?? this.isCustom,
    );
  }
}

/// All predefined Points of Interest in Kushtia District
const List<PointOfInterest> kushtiaPOIs = [
  // --- RESIDENCES ---
  PointOfInterest(
    name: "Shafin's Family Residence",
    nameBn: 'সাফিনদের বাড়ি',
    location: LatLng(23.914392, 89.117662),
    icon: Icons.home,
    color: Colors.deepPurple,
    category: 'Residence',
    description: 'The residence of Shafin and family.',
  ),

  // --- GOVERNMENT ---
  PointOfInterest(
    name: 'Deputy Commissioner Office (DC Court)',
    nameBn: 'জেলা প্রশাসকের কার্যালয়',
    location: LatLng(23.9085, 89.1225),
    icon: Icons.account_balance,
    color: Colors.brown,
    category: 'Government',
  ),
  PointOfInterest(
    name: 'Kushtia Municipality',
    nameBn: 'কুষ্টিয়া পৌরসভা',
    location: LatLng(23.9065, 89.1235),
    icon: Icons.location_city,
    color: Colors.brown,
    category: 'Government',
  ),
  PointOfInterest(
    name: 'Police Superintendent Office',
    nameBn: 'পুলিশ সুপারের কার্যালয়',
    location: LatLng(23.9095, 89.1215),
    icon: Icons.security,
    color: Colors.brown,
    category: 'Government',
  ),
  PointOfInterest(
    name: 'Circuit House',
    nameBn: 'সার্কিট হাউজ',
    location: LatLng(23.9055, 89.1265),
    icon: Icons.villa,
    color: Colors.brown,
    category: 'Government',
  ),

  // --- EDUCATION ---
  PointOfInterest(
    name: 'Islamic University',
    nameBn: 'ইসলামী বিশ্ববিদ্যালয়',
    location: LatLng(23.7245, 89.1535),
    icon: Icons.school,
    color: Colors.blue,
    category: 'Education',
    description: 'A major public research university.',
    phone: '+880-71-74560',
  ),
  PointOfInterest(
    name: 'Kushtia Govt College',
    nameBn: 'কুষ্টিয়া সরকারি কলেজ',
    location: LatLng(23.9050, 89.1245),
    icon: Icons.school,
    color: Colors.blue,
    category: 'Education',
    description: 'Premier government college.',
  ),
  PointOfInterest(
    name: 'Kushtia Zilla School',
    nameBn: 'কুষ্টিয়া জেলা স্কুল',
    location: LatLng(23.9065, 89.1180),
    icon: Icons.school,
    color: Colors.blue,
    category: 'Education',
  ),
  PointOfInterest(
    name: 'Police Lines School',
    nameBn: 'পুলিশ লাইন্স স্কুল',
    location: LatLng(23.9120, 89.1100),
    icon: Icons.school,
    color: Colors.blue,
    category: 'Education',
  ),
  PointOfInterest(
    name: 'Kushtia Medical College',
    nameBn: 'কুষ্টিয়া মেডিকেল কলেজ',
    location: LatLng(23.9000, 89.1150),
    icon: Icons.school,
    color: Colors.blue,
    category: 'Education',
  ),

  // --- HEALTH ---
  PointOfInterest(
    name: 'Kushtia General Hospital',
    nameBn: 'কুষ্টিয়া জেনারেল হাসপাতাল',
    location: LatLng(23.9100, 89.1280),
    icon: Icons.local_hospital,
    color: Colors.red,
    category: 'Hospital',
    description: '250-bed General Hospital.',
    phone: '16263',
  ),
  PointOfInterest(
    name: 'Sono Hospital',
    nameBn: 'সনো হাসপাতাল',
    location: LatLng(23.9020, 89.1300),
    icon: Icons.local_hospital,
    color: Colors.red,
    category: 'Hospital',
    description: 'Famous diagnostic center and hospital.',
  ),
  PointOfInterest(
    name: 'Ad-Din Hospital',
    nameBn: 'আদ-দ্বীন হাসপাতাল',
    location: LatLng(23.8980, 89.1250),
    icon: Icons.local_hospital,
    color: Colors.red,
    category: 'Hospital',
  ),
  PointOfInterest(
    name: 'Diabetes Hospital',
    nameBn: 'ডায়াবেটিস হাসপাতাল',
    location: LatLng(23.9210, 89.1310),
    icon: Icons.local_hospital,
    color: Colors.red,
    category: 'Hospital',
  ),

  // --- RELIGIOUS ---
  PointOfInterest(
    name: 'Lalon Shah Mazar',
    nameBn: 'লালন শাহ মাজার',
    location: LatLng(23.7765, 89.1620),
    icon: Icons.mosque,
    color: Colors.green,
    category: 'Religious',
    description: 'Shrine of Fakir Lalon Shah.',
  ),
  PointOfInterest(
    name: 'Boro Jame Masjid',
    nameBn: 'বড় জামে মসজিদ',
    location: LatLng(23.9068, 89.1195),
    icon: Icons.mosque,
    color: Colors.green,
    category: 'Religious',
    description: 'Central mosque of Kushtia town.',
  ),
  PointOfInterest(
    name: 'Thanapara Jame Masjid',
    nameBn: 'থানাপাড়া জামে মসজিদ',
    location: LatLng(23.9090, 89.1210),
    icon: Icons.mosque,
    color: Colors.green,
    category: 'Religious',
  ),

  // --- BANK & ATM ---
  PointOfInterest(
    name: 'Islami Bank Main Br.',
    nameBn: 'ইসলামী ব্যাংক',
    location: LatLng(23.9060, 89.1210),
    icon: Icons.account_balance,
    color: Colors.indigo,
    category: 'Bank',
  ),
  PointOfInterest(
    name: 'Sonali Bank Corp.',
    nameBn: 'সোনালী ব্যাংক',
    location: LatLng(23.9055, 89.1190),
    icon: Icons.account_balance,
    color: Colors.indigo,
    category: 'Bank',
  ),
  PointOfInterest(
    name: 'DBBL ATM Booth',
    nameBn: 'ডাচ-বাংলা এটিএম',
    location: LatLng(23.9085, 89.1230),
    icon: Icons.atm,
    color: Colors.indigo,
    category: 'ATM',
  ),

  // --- FOOD ---
  PointOfInterest(
    name: 'Kheya Restaurant',
    nameBn: 'খেয়া রেস্তোরাঁ',
    location: LatLng(23.9040, 89.1260),
    icon: Icons.restaurant,
    color: Colors.pink,
    category: 'Restaurant',
    description: 'Riverside dining.',
  ),
  PointOfInterest(
    name: 'Mouban Restaurant',
    nameBn: 'মৌবন রেস্তোরাঁ',
    location: LatLng(23.9075, 89.1225),
    icon: Icons.restaurant,
    color: Colors.pink,
    category: 'Restaurant',
    description: 'Sweets and snacks.',
  ),
  PointOfInterest(
    name: 'Jahangir Hotel',
    nameBn: 'জাহাঙ্গীর হোটেল',
    location: LatLng(23.9030, 89.1180),
    icon: Icons.restaurant,
    color: Colors.pink,
    category: 'Restaurant',
    description: 'Famous for local food.',
  ),
  PointOfInterest(
    name: 'KFC (Ruma)',
    nameBn: 'কেএফসি',
    location: LatLng(23.9070, 89.1240),
    icon: Icons.fastfood,
    color: Colors.pink,
    category: 'Restaurant',
  ),

  // --- HOTELS ---
  PointOfInterest(
    name: 'Hotel River View',
    nameBn: 'হোটেল রিভার ভিউ',
    location: LatLng(23.9045, 89.1270),
    icon: Icons.hotel,
    color: Colors.teal,
    category: 'Hotel',
  ),
  PointOfInterest(
    name: 'Desha Tarc',
    nameBn: 'দিশা টার্ক',
    location: LatLng(23.8800, 89.1100),
    icon: Icons.hotel,
    color: Colors.teal,
    category: 'Hotel',
    description: 'Training center and rest house.',
  ),
  PointOfInterest(
    name: 'Hotel Al-Amin',
    nameBn: 'হোটেল আল-আমিন',
    location: LatLng(23.9060, 89.1200),
    icon: Icons.hotel,
    color: Colors.teal,
    category: 'Hotel',
  ),

  // --- FUEL ---
  PointOfInterest(
    name: 'Mondol Filling Station',
    nameBn: 'মন্ডল ফিলিং স্টেশন',
    location: LatLng(23.8950, 89.1150),
    icon: Icons.local_gas_station,
    color: Colors.orange,
    category: 'Fuel',
  ),
  PointOfInterest(
    name: 'Biswas Filling Station',
    nameBn: 'বিশ্বাস ফিলিং স্টেশন',
    location: LatLng(23.9150, 89.1120),
    icon: Icons.local_gas_station,
    color: Colors.orange,
    category: 'Fuel',
  ),

  // --- MARKETS ---
  PointOfInterest(
    name: 'Kushtia Bazar',
    nameBn: 'কুষ্টিয়া বাজার',
    location: LatLng(23.9070, 89.1200),
    icon: Icons.store,
    color: Colors.purple,
    category: 'Market',
    description: 'Main market area.',
  ),
  PointOfInterest(
    name: 'NS Road Market',
    nameBn: 'এন এস রোড',
    location: LatLng(23.9060, 89.1220),
    icon: Icons.shopping_bag,
    color: Colors.purple,
    category: 'Market',
  ),

  // --- LANDMARKS ---
  PointOfInterest(
    name: 'Lalon Shah Bridge',
    nameBn: 'লালন শাহ সেতু',
    location: LatLng(24.0720, 89.0380),
    icon: Icons.architecture,
    color: Colors.brown,
    category: 'Landmark',
  ),
  PointOfInterest(
    name: 'Hardinge Bridge',
    nameBn: 'হার্ডিঞ্জ ব্রিজ',
    location: LatLng(24.0795, 89.0290),
    icon: Icons.train,
    color: Colors.brown,
    category: 'Landmark',
  ),

  // --- PARKS & NATURE ---
  PointOfInterest(
    name: 'Kushtia Municipal Park',
    nameBn: 'কুষ্টিয়া পৌর পার্ক',
    location: LatLng(23.9065, 89.1235),
    icon: Icons.park,
    color: Colors.green,
    category: 'Park',
    description: 'Central park for recreation.',
  ),
  PointOfInterest(
    name: 'Renwick Jajneswar Park',
    nameBn: 'রেনউইক যজ্ঞেশ্বর পার্ক',
    location: LatLng(23.9110, 89.1320),
    icon: Icons.nature_people,
    color: Colors.green,
    category: 'Park',
    description: 'Beautiful riverside scenic spot.',
  ),

  // --- TRANSPORT ---
  PointOfInterest(
    name: 'Majampur Bus Stand',
    nameBn: 'মজমপুর বাস স্ট্যান্ড',
    location: LatLng(23.9020, 89.1200),
    icon: Icons.directions_bus,
    color: Colors.indigo,
    category: 'Transport',
    description: 'Main bus terminal of Kushtia.',
  ),
  PointOfInterest(
    name: 'Kushtia Court Station',
    nameBn: 'কুষ্টিয়া কোর্ট স্টেশন',
    location: LatLng(23.9080, 89.1250),
    icon: Icons.train,
    color: Colors.indigo,
    category: 'Transport',
  ),
  PointOfInterest(
    name: 'Jagati Railway Station',
    nameBn: 'জগতি রেলওয়ে স্টেশন',
    location: LatLng(23.8880, 89.1350),
    icon: Icons.train,
    color: Colors.indigo,
    category: 'Transport',
    description: 'First railway station in East Bengal (1862).',
  ),

  // --- HISTORY ---
  PointOfInterest(
    name: 'Tagore Lodge',
    nameBn: 'টেগর লজ',
    location: LatLng(23.9015, 89.1462),
    icon: Icons.history_edu,
    color: Colors.brown,
    category: 'History',
    description: "Rabindranath Tagore's town residence.",
  ),
  PointOfInterest(
    name: 'Shilaidaha Kuthibari',
    nameBn: 'শিলাইদহ কুঠিবাড়ি',
    location: LatLng(23.9197, 89.2200),
    icon: Icons.history_edu,
    color: Colors.brown,
    category: 'History',
    description: 'Historic mansion of Rabindranath Tagore.',
  ),
  PointOfInterest(
    name: 'Lalon Akhara',
    nameBn: 'লালন আখড়া',
    location: LatLng(23.8958, 89.1522),
    icon: Icons.music_note,
    color: Colors.brown,
    category: 'History',
    description: 'Shrine of Lalon Shah.',
  ),

  // --- SHOPPING ---
  PointOfInterest(
    name: 'Lovely Tower',
    nameBn: 'লাভলী টাওয়ার',
    location: LatLng(23.9055, 89.1215),
    icon: Icons.shopping_bag,
    color: Colors.purple,
    category: 'Shopping',
    description: 'Famous shopping mall.',
  ),
  PointOfInterest(
    name: 'Porisundari Market',
    nameBn: 'পরীসুন্দরী মার্কেট',
    location: LatLng(23.9060, 89.1220),
    icon: Icons.shopping_bag,
    color: Colors.purple,
    category: 'Shopping',
  ),

  // --- SERVICE ---
  PointOfInterest(
    name: 'Kushtia Fire Service',
    nameBn: 'ফায়ার সার্ভিস স্টেশন',
    location: LatLng(23.9000, 89.1200),
    icon: Icons.local_fire_department,
    color: Colors.deepOrange,
    category: 'Service',
  ),


  // --- NEW SUGGESTIONS (Restaurants & Cafes) ---
  PointOfInterest(
    name: 'Karamay Chinese Restaurant',
    nameBn: 'কারাময় চাইনিজ রেস্টুরেন্ট',
    location: LatLng(23.9065, 89.1228),
    icon: Icons.restaurant,
    color: Colors.pink,
    category: 'Restaurant',
    description: 'Popular for Thai Soup & Sizzling dishes. Located at Ma-Mony Super Market.',
  ),
  PointOfInterest(
    name: 'Cafe De Pasta',
    nameBn: 'ক্যাফে ডি পাস্তা',
    location: LatLng(23.9058, 89.1252),
    icon: Icons.local_cafe,
    color: Colors.brown,
    category: 'Restaurant',
    description: 'Top hangout spot with vibrant vibes.',
  ),
  PointOfInterest(
    name: 'Café Kustia',
    nameBn: 'ক্যাফে কুষ্টিয়া',
    location: LatLng(23.9075, 89.1245),
    icon: Icons.local_cafe,
    color: Colors.brown,
    category: 'Restaurant',
    description: 'Artisan coffee spot.',
  ),
  PointOfInterest(
    name: 'Meherjaan Dining',
    nameBn: 'মেহেরজান ডাইনিং',
    location: LatLng(23.9042, 89.1215),
    icon: Icons.restaurant,
    color: Colors.pink,
    category: 'Restaurant',
    description: 'Known for Indian and Kabab dishes.',
  ),
  PointOfInterest(
    name: 'Chhaya Coffee House',
    nameBn: 'ছায়া কফি হাউস',
    location: LatLng(23.9088, 89.1235),
    icon: Icons.local_cafe,
    color: Colors.brown,
    category: 'Restaurant',
    description: 'Youth favorite coffee spot.',
  ),

  // --- NEW SUGGESTIONS (Landmarks) ---
  PointOfInterest(
    name: 'Mir Mosharraf Hossain House',
    nameBn: 'মীর মশাররফ হোসেনের বাস্তুভিটা',
    location: LatLng(23.8650, 89.1850), // Approx Lahinipara
    icon: Icons.history_edu,
    color: Colors.brown,
    category: 'History',
    description: 'Historic home of the renowned novelist in Lahinipara.',
  ),
  PointOfInterest(
    name: 'Jhaudia Shahi Mosque',
    nameBn: 'ঝাউদিয়া শাহী মসজিদ',
    location: LatLng(23.7750, 89.0553),
    icon: Icons.mosque,
    color: Colors.green,
    category: 'History',
    description: 'Beautiful Mughal-era architecture in Jhaudia.',
  ),
  PointOfInterest(
    name: 'Pakshi Railway Bridge',
    nameBn: 'পাকশী রেলওয়ে ব্রিজ',
    location: LatLng(24.0678, 89.0277),
    icon: Icons.train,
    color: Colors.indigo,
    category: 'Landmark',
    description: 'Scenic outlook near Hardinge Bridge.',
  ),

  // --- NEW BATCH 2 (More Food) ---
  PointOfInterest(
    name: "Mamma's Kitchen",
    nameBn: 'মামাস কিচেন',
    location: LatLng(23.9055, 89.1230), // Approx
    icon: Icons.restaurant,
    color: Colors.pink,
    category: 'Restaurant',
    description: 'Highly rated restaurant famous for platters.',
  ),
  PointOfInterest(
    name: 'Tales of Tehari',
    nameBn: 'টেলস অফ তেহারি',
    location: LatLng(23.9005, 89.1280), // Peartola Approx
    icon: Icons.rice_bowl,
    color: Colors.pink,
    category: 'Restaurant',
    description: 'Specializes in Tehari and traditional food.',
  ),
  PointOfInterest(
    name: "Faimu's Flavour",
    nameBn: 'ফাইমুস ফ্লেভার',
    location: LatLng(23.9062, 89.1218), // Central Approx
    icon: Icons.fastfood,
    color: Colors.pink,
    category: 'Restaurant',
  ),
  PointOfInterest(
    name: "Chili's Food Park",
    nameBn: 'চিলিস ফুড পার্ক',
    location: LatLng(23.9083, 89.1227), // NS Road opp Public Library
    icon: Icons.local_dining,
    color: Colors.pink,
    category: 'Restaurant',
    description: 'Open air food court on NS Road.',
  ),
  PointOfInterest(
    name: 'Dhoa Restaurant',
    nameBn: 'ধোঁয়া রেস্তোরাঁ',
    location: LatLng(23.9035, 89.1195), // Chand Mohammad Rd Approx
    icon: Icons.restaurant,
    color: Colors.pink,
    category: 'Restaurant',
  ),
  PointOfInterest(
    name: 'Nabanno Cafe',
    nameBn: 'নবান্ন ক্যাফে',
    location: LatLng(23.9050, 89.1240), // MM Hossain Rd Approx
    icon: Icons.local_cafe,
    color: Colors.brown,
    category: 'Restaurant',
    description: 'Fast food and coffee.',
  ),

  // --- STREET FOOD ---
  PointOfInterest(
    name: "Shahed's Chotpoti House",
    nameBn: 'শাহেদের চটপটি',
    location: LatLng(23.9018, 89.1201), // Near Thana More/Shaheed Minar
    icon: Icons.fastfood,
    color: Colors.orange,
    category: 'Street Food',
    description: 'Famous chotpoti and fuchka spot at Thana More.',
  ),
  PointOfInterest(
    name: 'Kushtia Fuchka Park',
    nameBn: 'কুষ্টিয়া ফুচকা পার্ক',
    location: LatLng(23.9009, 89.1233), // Near Medical College
    icon: Icons.fastfood,
    color: Colors.orange,
    category: 'Street Food',
    description: 'Tanduri Mania & Fuchka.',
  ),
  PointOfInterest(
    name: 'Municipal Park Street Food',
    nameBn: 'পৌর পার্ক স্ট্রিট ফুড',
    location: LatLng(23.9065, 89.1235),
    icon: Icons.fastfood,
    color: Colors.orange,
    category: 'Street Food',
    description: 'Variety of street food stalls inside and around the park.',
  ),
  PointOfInterest(
    name: 'College More Fuchka',
    nameBn: 'কলেজ মোড় ফুচকা',
    location: LatLng(23.9050, 89.1245), // Near Govt College
    icon: Icons.fastfood,
    color: Colors.orange,
    category: 'Street Food',
  ),
];
