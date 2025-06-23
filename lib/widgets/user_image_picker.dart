import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class UserImagePicker extends StatefulWidget {
  const UserImagePicker({super.key, required this.onImagePicked});

  final void Function(File pickedImage)? onImagePicked;

  @override
  State<UserImagePicker> createState() => _UserImagePickerState();
}

class _UserImagePickerState extends State<UserImagePicker>
    with SingleTickerProviderStateMixin {
  File? _pickedImageFile;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _pickImage() async {
    HapticFeedback.lightImpact();
    if (mounted) {
      _animationController.forward().then((_) {
        if (mounted) {
          _animationController.reverse();
        }
      });
    }

    if (mounted) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => _buildImageSourceSelector(),
      );
    }
  }

  Future<void> _getImage(ImageSource source) async {
    Navigator.of(context).pop();

    try {
      final pickedImage = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 300,
        maxHeight: 300,
      );
      if (pickedImage == null) return;

      if (mounted) {
        setState(() {
          _pickedImageFile = File(pickedImage.path);
        });
      }

      // Call the callback if provided
      if (widget.onImagePicked != null) {
        widget.onImagePicked!(_pickedImageFile!);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildImageSourceSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Select Profile Photo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSourceOption(
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      onTap: () => _getImage(ImageSource.camera),
                    ),
                    _buildSourceOption(
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      onTap: () => _getImage(ImageSource.gallery),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: const Color(0xFF4CAF50)),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2E7D32),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF4CAF50), width: 3),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4CAF50).withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: _pickedImageFile != null
                  ? Image.file(_pickedImageFile!, fit: BoxFit.cover)
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF4CAF50).withOpacity(0.1),
                            const Color(0xFF81C784).withOpacity(0.1),
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.add_a_photo,
                        size: 30,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
