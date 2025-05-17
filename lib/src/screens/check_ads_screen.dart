import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/advertisement_request.dart';
import '../services/advertisement_service.dart';
import '../services/auth_service.dart';

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
    if (url == null || url.isEmpty) return true; // Empty is valid (no change)
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
    final cityController = TextEditingController();
    final areaController = TextEditingController();
    final linkController = TextEditingController();

    bool isUpdating = false;

    // Show the dialog
    return showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing while updating
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
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
                      TextFormField(
                        controller: cityController,
                        decoration: InputDecoration(
                          labelText: 'City',
                          hintText: request.city,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: areaController,
                        decoration: InputDecoration(
                          labelText: 'Area',
                          hintText: request.area,
                        ),
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
                            cityController.dispose();
                            areaController.dispose();
                            linkController.dispose();
                            Navigator.of(context).pop();
                          },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed:
                      isUpdating
                          ? null
                          : () async {
                            if (!formKey.currentState!.validate()) return;

                            setState(() => isUpdating = true);

                            try {
                              // Create updates map with only changed fields
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
                              if (cityController.text.isNotEmpty) {
                                updates['city'] = cityController.text;
                              }
                              if (areaController.text.isNotEmpty) {
                                updates['area'] = areaController.text;
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

                              // Dispose controllers after successful update
                              titleController.dispose();
                              descriptionController.dispose();
                              imageUrlController.dispose();
                              cityController.dispose();
                              areaController.dispose();
                              linkController.dispose();

                              if (context.mounted) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Advertisement updated successfully',
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              setState(() => isUpdating = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
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
            );
          },
        );
      },
    ).then((_) {
      // Ensure controllers are disposed if dialog is dismissed
      if (titleController.hasListeners) titleController.dispose();
      if (descriptionController.hasListeners) descriptionController.dispose();
      if (imageUrlController.hasListeners) imageUrlController.dispose();
      if (cityController.hasListeners) cityController.dispose();
      if (areaController.hasListeners) areaController.dispose();
      if (linkController.hasListeners) linkController.dispose();
    });
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
