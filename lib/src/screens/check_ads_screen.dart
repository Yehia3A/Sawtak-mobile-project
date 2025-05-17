import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/advertisement_request.dart';
import '../services/advertisement_service.dart';
import '../services/auth_service.dart';
import '../data/egypt_locations.dart';

class CheckAdsScreen extends StatelessWidget {
  final _adService = AdvertisementService();
  final _authService = AuthService();

  CheckAdsScreen({super.key});

  Future<void> _launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  bool _isValidUrl(String? url) {
    if (url == null || url.isEmpty) return true;
    final uri = Uri.tryParse(url);
    return uri != null && uri.isAbsolute;
  }

  Future<void> _showEditDialog(
    BuildContext context,
    AdvertisementRequest request,
  ) async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final imageUrlController = TextEditingController();
    final linkController = TextEditingController();

    String? selectedCity = request.city;
    String? selectedArea = request.area;
    List<String> availableAreas = getAreasForCity(request.city);

    bool isUpdating = false;

    // Show the dialog
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return WillPopScope(
              onWillPop: () async {
                titleController.dispose();
                descriptionController.dispose();
                imageUrlController.dispose();
                linkController.dispose();
                return true;
              },
              child: AlertDialog(
                title: const Text('Edit Advertisement'),
                content: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Leave fields empty to keep current values',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: titleController,
                          decoration: InputDecoration(
                            labelText: 'Title',
                            hintText: request.title,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: descriptionController,
                          decoration: InputDecoration(
                            labelText: 'Description',
                            hintText: request.description,
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: imageUrlController,
                          decoration: InputDecoration(
                            labelText: 'Image URL',
                            hintText: request.imageUrl,
                          ),
                          validator: (value) {
                            if (value != null &&
                                value.isNotEmpty &&
                                !_isValidUrl(value)) {
                              return 'Please enter a valid URL';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        // City Dropdown
                        DropdownButtonFormField<String>(
                          value: selectedCity,
                          hint: const Text('Select City'),
                          isExpanded: true,
                          items:
                              getAllCities()
                                  .map(
                                    (city) => DropdownMenuItem(
                                      value: city,
                                      child: Text(city),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (newCity) {
                            setState(() {
                              selectedCity = newCity;
                              availableAreas =
                                  newCity != null
                                      ? getAreasForCity(newCity)
                                      : [];
                              selectedArea =
                                  null; // Reset area when city changes
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        // Area Dropdown
                        DropdownButtonFormField<String>(
                          value: selectedArea,
                          hint: const Text('Select Area'),
                          isExpanded: true,
                          items:
                              availableAreas
                                  .map(
                                    (area) => DropdownMenuItem(
                                      value: area,
                                      child: Text(area),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (newArea) {
                            setState(() {
                              selectedArea = newArea;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: linkController,
                          decoration: InputDecoration(
                            labelText: 'Link',
                            hintText:
                                request.link.isEmpty ? 'No link' : request.link,
                          ),
                          validator: (value) {
                            if (value != null &&
                                value.isNotEmpty &&
                                !_isValidUrl(value)) {
                              return 'Please enter a valid URL';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed:
                        isUpdating
                            ? null
                            : () {
                              titleController.dispose();
                              descriptionController.dispose();
                              imageUrlController.dispose();
                              linkController.dispose();
                              Navigator.of(dialogContext).pop();
                            },
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed:
                        isUpdating
                            ? null
                            : () async {
                              if (!formKey.currentState!.validate()) return;

                              // Enhanced validation for city and area
                              if (selectedCity != request.city &&
                                  selectedArea == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please select an area for the new city',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              setState(() => isUpdating = true);

                              try {
                                final updates = <String, dynamic>{};
                                if (titleController.text.isNotEmpty) {
                                  updates['title'] = titleController.text;
                                }
                                if (descriptionController.text.isNotEmpty) {
                                  updates['description'] =
                                      descriptionController.text;
                                }
                                if (imageUrlController.text.isNotEmpty) {
                                  updates['imageUrl'] = imageUrlController.text;
                                }
                                if (selectedCity != request.city) {
                                  updates['city'] = selectedCity;
                                  // If city changed, area must be updated too
                                  updates['area'] = selectedArea;
                                } else if (selectedArea != request.area) {
                                  // If only area changed
                                  updates['area'] = selectedArea;
                                }
                                if (linkController.text.isNotEmpty) {
                                  updates['link'] = linkController.text;
                                }

                                if (updates.isNotEmpty) {
                                  await _adService.updateRequest(
                                    request.id,
                                    updates,
                                  );
                                }

                                // Clean up controllers
                                titleController.dispose();
                                descriptionController.dispose();
                                imageUrlController.dispose();
                                linkController.dispose();

                                if (dialogContext.mounted) {
                                  // Pop the dialog first
                                  Navigator.of(dialogContext).pop();

                                  if (context.mounted) {
                                    // Show success message
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Advertisement updated successfully',
                                        ),
                                      ),
                                    );

                                    // Pop current screen and push a new instance
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(
                                        builder: (context) => CheckAdsScreen(),
                                      ),
                                      (route) =>
                                          false, // Remove all previous routes
                                    );
                                  }
                                }
                              } catch (e) {
                                // Clean up controllers on error
                                titleController.dispose();
                                descriptionController.dispose();
                                imageUrlController.dispose();
                                linkController.dispose();

                                setState(() => isUpdating = false);
                                if (dialogContext.mounted) {
                                  Navigator.of(dialogContext).pop();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e')),
                                    );
                                  }
                                }
                              }
                            },
                    child:
                        isUpdating
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Text('Update'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Image.asset(
            'assets/homepage.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Container(color: Colors.black.withOpacity(0.4)),
          SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  child: const Text(
                    'Your Advertisement Requests',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Requests List
                Expanded(
                  child: StreamBuilder<List<AdvertisementRequest>>(
                    stream: _adService.getAdvertiserRequests(
                      _authService.currentUser?.uid ?? '',
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error: ${snapshot.error}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }

                      final requests = snapshot.data ?? [];

                      if (requests.isEmpty) {
                        return Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white70),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'No requests made',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: requests.length,
                        itemBuilder: (context, index) {
                          final request = requests[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Image
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                  child: AspectRatio(
                                    aspectRatio: 16 / 9,
                                    child: Image.network(
                                      request.imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        return Container(
                                          color: Colors.grey[300],
                                          child: const Center(
                                            child: Icon(
                                              Icons.error_outline,
                                              size: 40,
                                              color: Colors.red,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Header with actions
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  request.title,
                                                  style: const TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Posted by ${request.posterName}',
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (request.status == 'pending')
                                                IconButton(
                                                  icon: const Icon(Icons.edit),
                                                  onPressed:
                                                      () => _showEditDialog(
                                                        context,
                                                        request,
                                                      ),
                                                ),
                                              IconButton(
                                                icon: const Icon(Icons.delete),
                                                onPressed: () {
                                                  _adService.deleteRequest(
                                                    request.id,
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      // Status badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              request.status == 'pending'
                                                  ? Colors.orange
                                                  : Colors.green,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          request.status.toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      // Description
                                      Text(
                                        request.description,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          height: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      // Location
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${request.city}, ${request.area}',
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (request.link.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        // Link
                                        InkWell(
                                          onTap: () => _launchUrl(request.link),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.link,
                                                size: 16,
                                                color: Colors.blue,
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  request.link,
                                                  style: const TextStyle(
                                                    color: Colors.blue,
                                                    decoration:
                                                        TextDecoration
                                                            .underline,
                                                    fontSize: 14,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
