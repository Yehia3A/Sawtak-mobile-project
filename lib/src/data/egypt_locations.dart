class EgyptLocation {
  final String city;
  final List<String> areas;

  const EgyptLocation({required this.city, required this.areas});
}

// This is a sample of Egyptian cities and areas
// You can expand this list with more cities and areas
const egyptLocations = [
  EgyptLocation(
    city: 'Cairo',
    areas: [
      'Maadi',
      'Nasr City',
      'Heliopolis',
      'New Cairo',
      'Downtown',
      '6th of October',
      'Zamalek',
      'Garden City',
      'Dokki',
      'Mohandessin',
    ],
  ),
  EgyptLocation(
    city: 'Alexandria',
    areas: [
      'Miami',
      'Montazah',
      'Glim',
      'Sidi Gaber',
      'Ibrahimia',
      'Sporting',
      'Stanley',
      'San Stefano',
      'Smouha',
    ],
  ),
  EgyptLocation(
    city: 'Giza',
    areas: [
      'Haram',
      'Faisal',
      'Dokki',
      'Agouza',
      'Mohandessin',
      'Sheikh Zayed',
      'Smart Village',
    ],
  ),
  EgyptLocation(
    city: 'Suez',
    areas: [
      'Arbaeen',
      'Faisal',
      'Port Tawfik',
      'Suez District',
      'Attaka',
      'El Ganayen',
    ],
  ),
  EgyptLocation(
    city: 'Port Said',
    areas: [
      'Al-Arab',
      'Al-Manakh',
      'Port Fouad',
      'Al-Zohour',
      'Al-Dawahi',
      'Al-Sharq',
    ],
  ),
  EgyptLocation(
    city: 'Luxor',
    areas: ['East Bank', 'West Bank', 'Karnak', 'New Luxor', 'Old Market'],
  ),
  EgyptLocation(
    city: 'Aswan',
    areas: [
      'Aswan City',
      'Elephantine Island',
      'New Aswan',
      'El Sad El Aali',
      'Gharb Soheil',
    ],
  ),
];

// Helper function to get areas for a specific city
List<String> getAreasForCity(String city) {
  final location = egyptLocations.firstWhere(
    (loc) => loc.city == city,
    orElse: () => const EgyptLocation(city: '', areas: []),
  );
  return location.areas;
}

// Get list of all cities
List<String> getAllCities() {
  return egyptLocations.map((loc) => loc.city).toList();
}
