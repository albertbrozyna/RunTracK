import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:latlong2/latlong.dart';
import 'package:run_track/app/navigation/app_routes.dart';
import 'package:run_track/app/theme/app_colors.dart';
import 'package:run_track/features/competitions/data/models/competition.dart';

class CompetitionMapPage extends StatefulWidget {
  const CompetitionMapPage({super.key});

  @override
  State<CompetitionMapPage> createState() => _CompetitionMapPageState();
}

class _CompetitionMapPageState extends State<CompetitionMapPage> {
  // Kontroler mapy do sterowania widokiem
  final MapController _mapController = MapController();

  // Ustawienia początkowe (np. Warszawa)
  LatLng _searchCenter = const LatLng(52.2297, 21.0122);
  double _radiusInKm = 10.0; // Domyślny promień 10 km

  // Stream z zawodami
  late Stream<List<Competition>> _competitionsStream;

  // Czy przycisk "Szukaj tutaj" powinien być widoczny?
  bool _showSearchHereButton = false;

  @override
  void initState() {
    super.initState();
    // Inicjalizacja streamu na starcie
    _updateQuery();
  }

  /// Główna funkcja tworząca zapytanie do Firestore
  void _updateQuery() {
    setState(() {
      final collectionRef = FirebaseFirestore.instance.collection('competitions');
      final centerGeoPoint = GeoFirePoint(GeoPoint(_searchCenter.latitude, _searchCenter.longitude));

      // Magia geoflutterfire_plus
      _competitionsStream = GeoCollectionReference(collectionRef)
          .subscribeWithin(
        center: centerGeoPoint,
        radiusInKm: _radiusInKm,
        field: 'geo', // Nazwa pola w bazie (ustaliliśmy to wcześniej)
        geopointFrom: (data) => (data['geo'] as Map<String, dynamic>)['geopoint'] as GeoPoint,
        strictMode: true,
      )
          .map((snapshots) {
        return snapshots.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['competitionId'] = doc.id; // Dodajemy ID
          return Competition.fromMap(data);
        }).toList();
      });

      // Ukryj przycisk po odświeżeniu
      _showSearchHereButton = false;
    });
  }

  /// Obsługa kliknięcia w marker zawodów
  void _onCompetitionTapped(Competition competition) {
    Navigator.pushNamed(
      context,
      AppRoutes.competitionDetails, // Upewnij się, że masz taką trasę
      arguments: competition,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. MAPA
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _searchCenter,
              initialZoom: 11.0,
              // Wykrywanie przesunięcia mapy
              onPositionChanged: (position, hasGesture) {
                if (hasGesture) {
                  setState(() {
                    _showSearchHereButton = true;
                  });
                }
              },
            ),
            children: [
              // Warstwa kafelków (OpenStreetMap)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.runtrack.app',
              ),

              // Warstwa wizualizująca promień (Niebieskie koło)
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: _searchCenter,
                    color: Colors.blue.withOpacity(0.15),
                    borderColor: Colors.blue.withOpacity(0.7),
                    borderStrokeWidth: 2,
                    useRadiusInMeter: true,
                    radius: _radiusInKm * 1000, // km na metry
                  ),
                ],
              ),

              // Warstwa markerów (Zawody)
              StreamBuilder<List<Competition>>(
                stream: _competitionsStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();

                  final competitions = snapshot.data!;

                  return MarkerLayer(
                    markers: competitions.map((comp) {
                      if (comp.location == null) return null;

                      return Marker(
                        point: comp.location!,
                        width: 50,
                        height: 50,
                        child: GestureDetector(
                          onTap: () => _onCompetitionTapped(comp),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.primary, width: 2),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
                                    ]
                                ),
                                child: const Icon(Icons.emoji_events, color: AppColors.primary, size: 24),
                              ),
                              // Opcjonalnie mały trójkącik na dole, żeby wyglądało jak pinezka
                            ],
                          ),
                        ),
                      );
                    }).whereType<Marker>().toList(),
                  );
                },
              ),
            ],
          ),

          // 2. PRZYCISK "SZUKAJ W TYM OBSZARZE"
          // Pojawia się tylko gdy przesuniemy mapę
          if (_showSearchHereButton)
            Positioned(
              top: 100, // Poniżej slidera
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Aktualizuj środek wyszukiwania do aktualnego środka mapy
                    setState(() {
                      _searchCenter = _mapController.camera.center;
                      _updateQuery();
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text("Szukaj w tym obszarze"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
            ),

          // 3. UI KONTROLNE (Slider i Back Button)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 16,
                  right: 16,
                  bottom: 16
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Górny pasek z przyciskiem powrotu
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.black),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Znajdź zawody",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(color: Colors.black, blurRadius: 4)]
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Karta ze Sliderem promienia
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
                        ]
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Promień szukania:",
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                            Text(
                              "${_radiusInKm.toStringAsFixed(0)} km",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppColors.primary,
                            thumbColor: AppColors.primary,
                            trackHeight: 2.0,
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0),
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
                          ),
                          child: Slider(
                            value: _radiusInKm,
                            min: 1.0,
                            max: 100.0,
                            divisions: 99,
                            onChanged: (value) {
                              setState(() {
                                _radiusInKm = value;
                              });
                            },
                            // Aktualizujemy zapytanie dopiero jak użytkownik puści suwak (oszczędność odczytów)
                            onChangeEnd: (value) {
                              _updateQuery();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. PRZYCISK "MOJA LOKALIZACJA" (Opcjonalnie)
          Positioned(
            bottom: 30,
            right: 20,
            child: FloatingActionButton(
              onPressed: () {
                // Tutaj dodałbyś logikę Geolocator.getCurrentPosition()
                // Na razie wraca do domyślnego środka
                _mapController.move(_searchCenter, 13.0);
              },
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}