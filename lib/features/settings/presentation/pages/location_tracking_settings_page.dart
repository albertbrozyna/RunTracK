import 'package:flutter/material.dart';
import 'package:run_track/app/config/app_settings.dart';
import 'package:run_track/core/widgets/page_container.dart';
import 'package:run_track/features/settings/data/services/settings_service.dart';

class LocationTrackingSettingsPage extends StatefulWidget {
  const LocationTrackingSettingsPage({super.key});

  @override
  State<LocationTrackingSettingsPage> createState() => _LocationTrackingSettingsPageState();
}

class _LocationTrackingSettingsPageState extends State<LocationTrackingSettingsPage> {
  int _distanceFilter = 15;
  double _positionAccuracy = 30.0;
  double _maxSpeed = 43.0;
  String _accuracyLevel = 'best';

  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
    initialize();
  }

  void initialize(){
    // TODO USE CONST INSTEAD OF THIS NORMAL VALUES
    _maxSpeed = AppSettings.instance.gpsMaxSpeedToDetectJumps ?? 34.0;

  }

  void _setBestSettings() {
    setState(() {
      _distanceFilter = 5;
      _positionAccuracy = 20.0;
      _maxSpeed = 34.0;
      _accuracyLevel = 'best';
    });
    SettingsService.saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("GPS Configuration")),
      body: PageContainer(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader("Hardware Accuracy"),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _accuracyLevel,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: 'best',
                        child: Text("Best (High Battery Usage) - Recommended for Running"),
                      ),
                      DropdownMenuItem(
                        value: 'high',
                        child: Text("High (Standard GPS)"),
                      ),
                      DropdownMenuItem(
                        value: 'medium',
                        child: Text("Medium (Balanced Power)"),
                      ),
                      DropdownMenuItem(
                        value: 'low',
                        child: Text("Low (City/Coarse)"),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _accuracyLevel = value);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                "Determines which sensors (GPS, Wi-Fi, Cell) are used.",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),

              const Divider(height: 40),

              _buildSectionHeader("Filters & Sensitivity"),
              const SizedBox(height: 10),
              _buildSlider(
                title: "Distance Filter",
                description: "Minimum distance (meters) to update location.",
                value: _distanceFilter.toDouble(),
                min: 0,
                max: 50,
                divisions: 50,
                unit: "m",
                onChanged: (val) => setState(() => _distanceFilter = val.toInt()),
              ),

              const SizedBox(height: 20),

              _buildSlider(
                title: "Min Accuracy Threshold",
                description: "Reject points with accuracy worse than X meters.",
                value: _positionAccuracy,
                min: 5,
                max: 100,
                divisions: 19,
                unit: "m",
                onChanged: (val) => setState(() => _positionAccuracy = val),
              ),

              const SizedBox(height: 20),

              _buildSlider(
                title: "Max Human Speed",
                description: "Reject points implying impossible speed.",
                value: _maxSpeed,
                min: 10,
                max: 120,
                divisions: 110,
                unit: "km/h",
                onChanged: (val) => setState(() => _maxSpeed = val),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.star),
                  label: const Text("Select Best Settings for Running"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: Colors.blue.shade100,
                    foregroundColor: Colors.blue.shade900,
                  ),
                  onPressed: _setBestSettings,
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: SettingsService.saveSettings,
                  child: const Text(
                    "Save Configuration",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildSlider({
    required String title,
    required String description,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String unit,
    required Function(double) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text("${value.toStringAsFixed(0)} $unit", style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: "${value.round()} $unit",
          onChanged: onChanged,
        ),
        Text(description, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      ],
    );
  }
}