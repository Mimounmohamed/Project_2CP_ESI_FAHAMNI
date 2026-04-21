import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/resource_model.dart';

class ResourceItem extends StatelessWidget {
  final ResourceModel resource;
  final VoidCallback onDelete;

  const ResourceItem({super.key, required this.resource, required this.onDelete});

  IconData get _icon {
    if (resource is LinkResource) {
      return Icons.link_rounded;
    }
    if (resource is MediaResource) {
      return Icons.image_rounded;
    }
    final String docType = resource is DocumentResource
        ? (resource as DocumentResource).docType.toLowerCase()
        : '';
    if (docType == 'pdf') {
      return Icons.picture_as_pdf_rounded;
    }
    return Icons.description_rounded;
  }

  bool get _isLink => resource is LinkResource;

  String get _resourceUrl {
    if (resource is LinkResource) {
      return (resource as LinkResource).linkUrl;
    }
    if (resource is MediaResource) {
      return (resource as MediaResource).mediaUrl;
    }
    if (resource is DocumentResource) {
      return (resource as DocumentResource).fileUrl;
    }
    return '';
  }

  String get _subtitle {
    if (_isLink) {
      return _resourceUrl;
    }
    if (resource is DocumentResource) {
      return (resource as DocumentResource).docType.toUpperCase();
    }
    if (resource is MediaResource) {
      return (resource as MediaResource).platform;
    }
    return resource.contentType;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF000080).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icon, color: const Color(0xFF000080), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resource.title,
                  style: const TextStyle(
                    fontFamily: 'Lexend',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  _subtitle,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Open/Download button
          GestureDetector(
            onTap: () async {
              if (_resourceUrl.isEmpty) {
                return;
              }
              final uri = Uri.parse(_resourceUrl);
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            child: Icon(
              _isLink ? Icons.open_in_new_rounded : Icons.download_rounded,
              color: const Color(0xFF000080),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(Icons.delete_outline_rounded,
                color: Color(0xFFEF4444), size: 20),
          ),
        ],
      ),
    );
  }
}
