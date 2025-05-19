import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/advertisement_request.dart';
import '../services/advertisement_service.dart';
import '../services/auth_service.dart';
import '../data/egypt_locations.dart';

class CheckAdsScreen extends StatelessWidget {
  final _adService = AdvertisementService();
  final _authService = AuthService();
  final String userRole;

  CheckAdsScreen({super.key, required this.userRole});

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
                              return;
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

                                // First we initialize all fields with their current values
                                updates['title'] = request.title;
                                updates['description'] = request.description;
                                updates['imageUrl'] = request.imageUrl;
                                updates['city'] = selectedCity ?? request.city;
                                updates['area'] = selectedArea ?? request.area;
                                updates['link'] = request.link;

                                // Then we override ONLY the fields that have new values
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
                                if (linkController.text.isNotEmpty) {
                                  updates['link'] = linkController.text;
                                }

                                await _adService.updateRequest(
                                  request.id,
                                  updates,
                                );

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
                                        builder:
                                            (context) => CheckAdsScreen(
                                              userRole: userRole,
                                            ),
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
          // Background image
          Image.asset(
            'assets/homepage.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),

          SafeArea(
            child: Column(
              children: [
                // Header with improved styling
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.campaign_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Advertisements',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Manage your ad requests',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Requests List with frosted glass effect
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.only(top: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                        ),
                        child: StreamBuilder<List<AdvertisementRequest>>(
                          stream:
                              userRole == 'gov_admin'
                                  ? _adService.getPendingRequests()
                                  : _adService.getAdvertiserRequests(
                                    _authService.currentUser?.uid ?? '',
                                  ),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (snapshot.hasError) {
                              return Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: Colors.red,
                                      size: 48,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Error: ${snapshot.error}',
                                      style: const TextStyle(color: Colors.red),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              );
                            }

                            final requests = snapshot.data ?? [];

                            if (requests.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.campaign_outlined,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No advertisements yet',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'theres no ad requests yet',
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
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
                                  elevation: 0,
                                  color: Colors.white.withOpacity(0.8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Image with gradient overlay
                                      Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                  top: Radius.circular(15),
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
                                          // Status badge overlay
                                          Positioned(
                                            top: 12,
                                            right: 12,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color:
                                                    request.status == 'pending'
                                                        ? Colors.orange
                                                        : Colors.green,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.2),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
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
                                          ),
                                        ],
                                      ),

                                      // Content
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Title and actions row
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        request.title,
                                                        style: const TextStyle(
                                                          fontSize: 20,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        'Posted by ${request.posterName}',
                                                        style: TextStyle(
                                                          color:
                                                              Colors.grey[600],
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                // Action buttons with improved styling
                                                if (request.status ==
                                                    'pending') ...[
                                                  if (userRole ==
                                                      'gov_admin') ...[
                                                    ElevatedButton.icon(
                                                      icon: const Icon(
                                                        Icons.check,
                                                        color: Colors.white,
                                                      ),
                                                      label: const Text(
                                                        'Accept',
                                                      ),
                                                      style:
                                                          ElevatedButton.styleFrom(
                                                            backgroundColor:
                                                                Colors.green,
                                                            foregroundColor:
                                                                Colors.white,
                                                          ),
                                                      onPressed: () async {
                                                        await _adService
                                                            .acceptRequest(
                                                              request.id,
                                                            );
                                                        if (context.mounted) {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                'Ad accepted.',
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      },
                                                    ),
                                                    const SizedBox(width: 8),
                                                    ElevatedButton.icon(
                                                      icon: const Icon(
                                                        Icons.close,
                                                        color: Colors.white,
                                                      ),
                                                      label: const Text(
                                                        'Reject',
                                                      ),
                                                      style:
                                                          ElevatedButton.styleFrom(
                                                            backgroundColor:
                                                                Colors.red,
                                                            foregroundColor:
                                                                Colors.white,
                                                          ),
                                                      onPressed: () async {
                                                        await _adService
                                                            .rejectRequest(
                                                              request.id,
                                                            );
                                                        if (context.mounted) {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                'Ad rejected.',
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      },
                                                    ),
                                                  ] else ...[
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.edit,
                                                      ),
                                                      color: Colors.blue,
                                                      onPressed:
                                                          () => _showEditDialog(
                                                            context,
                                                            request,
                                                          ),
                                                    ),
                                                  ],
                                                ],
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.delete,
                                                  ),
                                                  color: Colors.red,
                                                  onPressed: () {
                                                    showDialog(
                                                      context: context,
                                                      builder:
                                                          (
                                                            context,
                                                          ) => AlertDialog(
                                                            title: const Text(
                                                              'Delete Advertisement',
                                                            ),
                                                            content: const Text(
                                                              'Are you sure you want to delete this advertisement?',
                                                            ),
                                                            actions: [
                                                              TextButton(
                                                                onPressed:
                                                                    () => Navigator.pop(
                                                                      context,
                                                                    ),
                                                                child:
                                                                    const Text(
                                                                      'Cancel',
                                                                    ),
                                                              ),
                                                              TextButton(
                                                                onPressed: () {
                                                                  _adService
                                                                      .deleteRequest(
                                                                        request
                                                                            .id,
                                                                      );
                                                                  Navigator.pop(
                                                                    context,
                                                                  );
                                                                },
                                                                style: TextButton.styleFrom(
                                                                  foregroundColor:
                                                                      Colors
                                                                          .red,
                                                                ),
                                                                child:
                                                                    const Text(
                                                                      'Delete',
                                                                    ),
                                                              ),
                                                            ],
                                                          ),
                                                    );
                                                  },
                                                ),
                                              ],
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
                                            const SizedBox(height: 16),
                                            // Location with icon
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.amber,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.location_on,
                                                    size: 16,
                                                    color: Colors.white,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${request.city}, ${request.area}',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (request.link.isNotEmpty) ...[
                                              const SizedBox(height: 12),
                                              // Link with improved styling
                                              InkWell(
                                                onTap:
                                                    () => _launchUrl(
                                                      request.link,
                                                    ),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 8,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.amber
                                                        .withOpacity(0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.link,
                                                        size: 16,
                                                        color: Colors.amber,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Flexible(
                                                        child: Text(
                                                          request.link,
                                                          style: TextStyle(
                                                            color: Colors.amber,
                                                            decoration:
                                                                TextDecoration
                                                                    .underline,
                                                            fontSize: 14,
                                                          ),
                                                          maxLines: 1,
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
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
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/check_ads'),
        icon: const Icon(Icons.list),
        label: const Text('Your Ads'),
        backgroundColor: Colors.amber,
      ),
    );
  }
}
