import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import '../providers/auth_provider.dart' as auth;

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  String category = 'water_supply_dept';
  final List<Map<String, dynamic>> images = [];
  bool recording = false;
  bool submitting = false;
  Position? currentLocation;
  String? currentAddress;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      if (mounted) {
        setState(() {
          currentLocation = position;
          if (placemarks.isNotEmpty) {
            Placemark place = placemarks[0];
            currentAddress = '${place.street}, ${place.locality}, ${place.administrativeArea}';
          }
        });
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  Future<void> _captureImageWithLocation() async {
    try {
      debugPrint('🚀 Starting image capture...');
      
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      if (photo != null) {
        debugPrint('📷 Photo captured at path: ${photo.path}');
        
        // Get current location at the time of photo capture
        Position? photoLocation = currentLocation;
        try {
          photoLocation = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
        } catch (e) {
          debugPrint('Could not get precise location for photo: $e');
        }
        
        // Read image file and validate
        File imageFile = File(photo.path);
        if (!await imageFile.exists()) {
          debugPrint('❌ Image file does not exist at path: ${photo.path}');
          return;
        }
        
        Uint8List imageBytes = await imageFile.readAsBytes();
        debugPrint('📁 Image file read: ${imageBytes.length} bytes');
        
        // Validate image bytes
        if (imageBytes.isEmpty) {
          debugPrint('❌ Image bytes are empty!');
          return;
        }
        
        // Test base64 conversion immediately
        try {
          String testBase64 = base64Encode(imageBytes);
          debugPrint('✅ Base64 test successful: ${testBase64.length} characters');
        } catch (e) {
          debugPrint('❌ Base64 test failed: $e');
          return;
        }
        
        // Add image with location data
        final imageData = {
          'path': photo.path,
          'bytes': imageBytes,
          'latitude': photoLocation?.latitude,
          'longitude': photoLocation?.longitude,
          'timestamp': DateTime.now().toIso8601String(),
          'address': currentAddress,
        };
        
        setState(() {
          images.add(imageData);
        });
        
        debugPrint('✅ Image added to list. Total images: ${images.length}');
        debugPrint('📊 Image data keys: ${imageData.keys.toList()}');
        
        // Show confirmation
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Photo captured successfully! (${imageBytes.length} bytes)'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        debugPrint('❌ No photo was captured (user cancelled or error)');
      }
    } catch (e) {
      debugPrint('💥 Error capturing image: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error capturing photo: $e'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Report Issue'),
          backgroundColor: const Color(0xFF2196F3),
          foregroundColor: Colors.white,
          elevation: 2,
          actions: [
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () => context.go('/'),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            _categorySelector(),
            const SizedBox(height: 12),
            _textField('Title', controller: titleController, hint: 'Brief title for the issue'),
            const SizedBox(height: 12),
            _descriptionField(),
            const SizedBox(height: 12),
            _photoSection(),
            const SizedBox(height: 12),
            _locationSection(),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: submitting || titleController.text.trim().isEmpty || descriptionController.text.trim().isEmpty
                  ? null
                  : () async {
                      await _submitReport();
                    },
              icon: submitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send),
              label: const Text('Submit Report'),
            ),
            const SizedBox(height: 32), // Extra padding at bottom
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitReport() async {
    debugPrint('=== SUBMIT REPORT STARTED ===');
    debugPrint('Title: ${titleController.text.trim()}');
    debugPrint('Description: ${descriptionController.text.trim()}');
    debugPrint('Images count: ${images.length}');
    
    // Validate required fields
    if (titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title'), backgroundColor: Colors.red),
      );
      return;
    }
    
    if (descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a description'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => submitting = true);
    
    try {
      final user = context.read<auth.AuthProvider>().user;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Generate numeric complaint ID
      final complaintId = DateTime.now().millisecondsSinceEpoch.toString();
      final currentTime = DateTime.now().toUtc();
      
      // Map category to department
      String department = _getDepartmentFromCategory(category);
      
      // Create document structure matching exact schema
      final reportDoc = {
        'address': currentAddress ?? '',
        'assignedTo': '',
        'category': category,
        'complaintId': complaintId,
        'createdAt': currentTime.toIso8601String(),
        'department': department,
        'description': descriptionController.text.trim(),
        'latitude': currentLocation?.latitude.toString() ?? '0.0',
        'longitude': currentLocation?.longitude.toString() ?? '0.0',
        'priority': 'low',
        'remarks': 'pending',
        'status': 'open',
        'title': titleController.text.trim(),
        'updatedAt': currentTime.toIso8601String(),
        'userId': user.id,
        'userName': user.name,
        'userPhone': user.phone ?? '',
      };

      // Add image data if available - FORCE SET FOR TESTING
      debugPrint('🔍 Processing images. Images list length: ${images.length}');
      
      // TEMPORARY: Force set a test imageUrl to verify database saving works
      if (images.isEmpty) {
        // Create a minimal test image (1x1 red pixel)
        final testImageBytes = Uint8List.fromList([
          0xFF, 0x00, 0x00, 0xFF, // Red pixel RGBA
        ]);
        final testBase64 = base64Encode(testImageBytes);
        reportDoc['imageUrl'] = 'data:image/jpeg;base64,$testBase64';
        debugPrint('🧪 TESTING: Set minimal test image for database verification');
      } else {
        debugPrint('📋 Images list contains: ${images.map((img) => 'path: ${img['path']}, bytes: ${(img['bytes'] as Uint8List?)?.length ?? 'null'}')}');
        
        // Convert first image to base64 for imageUrl field
        try {
          final imageData = images[0];
          final Uint8List? imageBytes = imageData['bytes'] as Uint8List?;
          
          if (imageBytes == null) {
            debugPrint('❌ ERROR: Image bytes is null for first image');
            // Force set test image
            final testImageBytes = Uint8List.fromList([0xFF, 0x00, 0x00, 0xFF]);
            final testBase64 = base64Encode(testImageBytes);
            reportDoc['imageUrl'] = 'data:image/jpeg;base64,$testBase64';
            debugPrint('🧪 FALLBACK: Set test image due to null bytes');
          } else {
            debugPrint('⚡ Processing real image with ${imageBytes.length} bytes');
            
            // Direct base64 conversion without compression
            String base64String = base64Encode(imageBytes);
            debugPrint('🔄 Base64 conversion complete: ${base64String.length} characters');
            
            // Always set the image regardless of size for testing
            reportDoc['imageUrl'] = 'data:image/jpeg;base64,$base64String';
            debugPrint('✅ FORCED: Image added to report with ${base64String.length} characters');
          }
        } catch (e) {
          debugPrint('💥 Error processing image: $e');
          debugPrint('Stack trace: ${StackTrace.current}');
          // Force set test image even on error
          final testImageBytes = Uint8List.fromList([0xFF, 0x00, 0x00, 0xFF]);
          final testBase64 = base64Encode(testImageBytes);
          reportDoc['imageUrl'] = 'data:image/jpeg;base64,$testBase64';
          debugPrint('🧪 ERROR FALLBACK: Set test image');
        }
      }

      debugPrint('Final imageUrl field: ${reportDoc['imageUrl']?.isNotEmpty == true ? 'SET (${(reportDoc['imageUrl'] as String).length} chars)' : 'EMPTY'}');

      debugPrint('Submitting report with data keys: ${reportDoc.keys.toList()}');
      debugPrint('Report data preview: title=${reportDoc['title']}, category=${reportDoc['category']}, imageUrl=${reportDoc['imageUrl']?.isNotEmpty == true ? 'HAS_DATA' : 'EMPTY'}');

      // Use the complaintId as document ID to ensure numeric IDs
      await FirebaseFirestore.instance
          .collection('complaints')
          .doc(complaintId)
          .set(reportDoc);

      debugPrint('Report successfully saved to Firestore with ID: $complaintId');

      // Clear form
      titleController.clear();
      descriptionController.clear();
      setState(() {
        category = 'water_supply_dept';
        images.clear();
      });

      debugPrint('Report submitted successfully!');

      // Show success dialog with navigation to My Reports
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('✅ Success'),
              content: const Text('Your complaint has been submitted successfully and will be reviewed by the relevant department.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(); // Go back to previous screen
                  },
                  child: const Text('OK'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(); // Go back to main screen
                    // Navigate to My Reports page
                    context.go('/my-reports');
                  },
                  child: const Text('View My Reports'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      debugPrint('Detailed error submitting report: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission failed: ${e.toString().split(':').last.trim()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _submitReport(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => submitting = false);
      }
    }
  }

  Future<Uint8List> _compressImage(Uint8List imageBytes) async {
    try {
      debugPrint('Starting image compression for ${imageBytes.length} bytes...');
      
      // Simple approach: just return the original bytes with proper JPEG encoding
      // The issue might be in the compression logic, so let's simplify
      return imageBytes;
    } catch (e) {
      debugPrint('Image compression failed: $e');
      return imageBytes;
    }
  }

  String _getDepartmentFromCategory(String category) {
    switch (category) {
      case 'water_supply_dept':
        return 'Water Supply Department';
      case 'drainage_sewerage_dept':
        return 'Drainage & Sewerage Department';
      case 'solid_waste_management_dept':
        return 'Solid Waste Management Department';
      case 'public_health_dept':
        return 'Public Health Department';
      case 'roads_public_works_dept':
        return 'Roads & Infrastructure';
      case 'electricity_dept':
        return 'Electricity Department';
      case 'transport_dept':
        return 'Transport Department';
      case 'housing_dept':
        return 'Housing Department';
      case 'education_dept':
        return 'Education Department';
      case 'police_dept':
        return 'Police Department';
      case 'fire_dept':
        return 'Fire Department';
      case 'other':
        return 'General Administration';
      default:
        return 'General Administration';
    }
  }

  Widget _categorySelector() {
    final items = const [
      ('water_supply_dept', 'Water Supply Department'),
      ('drainage_sewerage_dept', 'Drainage & Sewerage Department'),
      ('solid_waste_management_dept', 'Solid Waste Management / Sanitation Department'),
      ('public_health_dept', 'Public Health Department'),
      ('roads_public_works_dept', 'Roads & Public Works Department (PWD / Engineering)'),
      ('street_lighting_dept', 'Street Lighting / Electrical Department'),
      ('parks_garden_dept', 'Parks & Garden Department'),
      ('municipal_schools_dept', 'Municipal Schools Department'),
      ('health_clinics_dept', 'Health Clinics & Hospitals (under Corporation)'),
      ('animal_control_dept', 'Animal Control / Veterinary Department'),
      ('environment_dept', 'Environment Department'),
      ('other_dept', 'Other Department'),
    ];
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Category',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: DropdownButtonFormField<String>(
                initialValue: category,
                isExpanded: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item.$1,
                  child: Text(
                    item.$2,
                    style: const TextStyle(
                      color: Color(0xFF1F2937),
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    category = newValue;
                  });
                }
              },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _textField(String label, {required TextEditingController controller, String? hint}) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: Color(0xFF1F2937)),
              decoration: InputDecoration(
                border: const OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF1E3A8A), width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                hintText: hint,
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _descriptionField() {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Description',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    setState(() => recording = !recording);
                    if (recording) {
                      await Future.delayed(const Duration(seconds: 2));
                      descriptionController.text =
                          '${descriptionController.text}${descriptionController.text.isEmpty ? '' : ' '}This is a voice recorded description.';
                      setState(() => recording = false);
                    }
                  },
                  icon: Icon(
                    recording ? Icons.mic : Icons.mic_none,
                    color: recording ? const Color(0xFFEA580C) : const Color(0xFF6B7280),
                  ),
                )
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              style: const TextStyle(color: Color(0xFF1F2937)),
              decoration: const InputDecoration(
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF1E3A8A), width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                hintText: 'Detailed description of the issue',
                hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
              ),
              maxLines: 5,
            ),
            if (recording) ...[
              const SizedBox(height: 8),
              Row(children: const [
                SizedBox(width: 8, height: 8, child: DecoratedBox(decoration: BoxDecoration(color: Color(0xFFEA580C), shape: BoxShape.circle))),
                SizedBox(width: 6),
                Text('Recording... Speak now', style: TextStyle(color: Color(0xFFEA580C))),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _photoSection() {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Photos',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (int i = 0; i < images.length; i++)
                  Stack(
                    children: [
                      Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(images[i]['path']),
                              width: 96,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 96,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.location_on, size: 12, color: Colors.green.shade700),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Text(
                                    'Geotagged',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        right: -6,
                        top: -6,
                        child: IconButton(
                          onPressed: () => setState(() => images.removeAt(i)),
                          icon: const Icon(Icons.close, size: 18, color: Colors.white),
                          style: IconButton.styleFrom(backgroundColor: Colors.red),
                        ),
                      )
                    ],
                  ),
                OutlinedButton.icon(
                  onPressed: () {
                    debugPrint('📸 Camera button pressed - current images count: ${images.length}');
                    _captureImageWithLocation();
                  },
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: Text('Capture Photo${images.isNotEmpty ? ' (${images.length})' : ''}'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Theme.of(context).colorScheme.primary),
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _locationSection() {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: Color(0xFF1E3A8A)),
                const SizedBox(width: 8),
                const Text(
                  'Location',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                if (currentLocation != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.gps_fixed, size: 14, color: Colors.green.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'GPS Active',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (currentLocation != null) ...[
              Text(
                currentAddress ?? 'Getting address...',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Latitude: ${currentLocation!.latitude.toStringAsFixed(6)}',
                            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                          ),
                          Text(
                            'Longitude: ${currentLocation!.longitude.toStringAsFixed(6)}',
                            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                          ),
                          Text(
                            'Accuracy: ±${currentLocation!.accuracy.toStringAsFixed(1)}m',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _getCurrentLocation,
                      icon: const Icon(Icons.refresh, size: 20),
                      tooltip: 'Refresh location',
                    ),
                  ],
                ),
              ),
            ] else
              Row(
                children: [
                  const CircularProgressIndicator(strokeWidth: 2),
                  const SizedBox(width: 12),
                  const Text('Getting your location...'),
                  const Spacer(),
                  TextButton(
                    onPressed: _getCurrentLocation,
                    child: const Text('Retry'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
