import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/resource_model.dart';
import '../Teacher_Service_Details/service_details_service.dart';

class ResourceTab extends StatefulWidget {
  final String serviceId;

  const ResourceTab({super.key, required this.serviceId});

  @override
  State<ResourceTab> createState() => _ResourcesTabState();
}

class _ResourcesTabState extends State<ResourceTab> {
  final _service = CourseDetailsService();
  List<ResourceModel> _resources = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _service.getResources(widget.serviceId);
    setState(() {
      _resources = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_resources.isEmpty) {
      return const Center(
        child: Text('No resources yet',
            style: TextStyle(fontFamily: 'Nunito', color: Color(0xFF94A3B8))),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      itemCount: _resources.length,
      itemBuilder: (_, i) => _ResourceItem(resource: _resources[i]),
    );
  }
}

class _ResourceItem extends StatelessWidget {
  final ResourceModel resource;
  const _ResourceItem({required this.resource});

  IconData get _icon {
    if (resource is DocumentResource) {
      final doc = resource as DocumentResource;
      switch (doc.docType) {
        case 'pdf': return Icons.insert_drive_file_outlined;
        case 'image': return Icons.image_outlined;
        default: return Icons.description_outlined;
      }
    } else if (resource is MediaResource) {
      return Icons.play_circle_outline_rounded;
    } else {
      return Icons.link_rounded;
    }
  }

  Color get _iconColor {
    if (resource is LinkResource) return const Color(0xFF6366F1);
    if (resource is MediaResource) return const Color(0xFFEF4444);
    return const Color(0xFF3B82F6);
  }

  String get _subtitle {
    if (resource is DocumentResource) {
      return (resource as DocumentResource).docType.toUpperCase();
    } else if (resource is MediaResource) {
      return (resource as MediaResource).platform;
    } else if (resource is LinkResource) {
      return (resource as LinkResource).linkUrl;
    }
    return '';
  }

  String get _url {
    if (resource is DocumentResource) return (resource as DocumentResource).fileUrl;
    if (resource is MediaResource) return (resource as MediaResource).mediaUrl;
    if (resource is LinkResource) return (resource as LinkResource).linkUrl;
    return '';
  }

  bool get _isLink => resource is LinkResource || resource is MediaResource;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: _iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icon, color: _iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resource.title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _subtitle,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () async {
              if (_url.isEmpty) return;
              await launchUrl(
                Uri.parse(_url),
                mode: LaunchMode.externalApplication,
              );
            },
            child: Icon(
              _isLink ? Icons.open_in_new_rounded : Icons.download_rounded,
              color: const Color(0xFF64748B),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}