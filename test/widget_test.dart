import 'package:flutter/material.dart';

class MediaTile extends StatelessWidget {
  final bool isVideo;
  const MediaTile({super.key, required this.isVideo});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // The Background Image
        Positioned.fill(
          child: Container(
            color: Colors.grey[900],
            child: const Icon(Icons.image, color: Colors.white24), // Placeholder
          ),
        ),

        // The Minimal Symbol for Videos
        if (isVideo)
          const Positioned(
            bottom: 6,
            right: 6,
            child: Icon(
              Icons.play_circle_outline, 
              color: Colors.white, 
              size: 18,
            ),
          ),
          
        // Optional: Cloud/Sync icon as seen in your target image
        const Positioned(
          bottom: 6,
          left: 6,
          child: Icon(
            Icons.cloud_done_outlined,
            color: Colors.white70,
            size: 14,
          ),
        ),
      ],
    );
  }
}