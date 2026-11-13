import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/library/domain/document.dart';
import '../theme/tokens.dart';

typedef ThumbnailImageResolver = ImageProvider Function(String path);

/// How thumbnail files become images. Tests swap in pre-loaded bytes.
final thumbnailImageResolverProvider = Provider<ThumbnailImageResolver>(
  (ref) => (path) => FileImage(File(path)),
);

/// First-page preview of a document with the soft page shadow from the
/// reference. PDFs use their rendered cover; text documents preview their
/// opening lines.
class DocumentThumbnail extends ConsumerWidget {
  const DocumentThumbnail({super.key, required this.document, required this.size});

  final LibraryDocument document;
  final Size size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thumb = document.thumbnailPath;
    final Widget content;
    if (thumb != null) {
      content = Image(
        image: ref.watch(thumbnailImageResolverProvider)(thumb),
        fit: BoxFit.cover,
        width: size.width,
        height: size.height,
        errorBuilder: (_, _, _) => const SizedBox.expand(),
      );
    } else if (document.kind == DocumentKind.text) {
      content = _TextPreview(path: document.filePath, width: size.width);
    } else {
      content = const SizedBox.expand();
    }

    // Corner radius scales with the thumbnail (8px on the 102px library
    // cover, as measured in the reference).
    final radius = BorderRadius.circular(size.width * 0.08);
    // The shadow sits on an unclipped outer box; only the page content is
    // clipped to the rounded corners.
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: const [
          BoxShadow(color: NarraColors.thumbnailShadow, blurRadius: 14, offset: Offset(0, 4)),
          BoxShadow(color: Color(0x0D000000), blurRadius: 1.5),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: ColoredBox(
          color: NarraColors.surface,
          child: SizedBox(width: size.width, height: size.height, child: content),
        ),
      ),
    );
  }
}

class _TextPreview extends StatefulWidget {
  const _TextPreview({required this.path, required this.width});

  final String path;
  final double width;

  @override
  State<_TextPreview> createState() => _TextPreviewState();
}

class _TextPreviewState extends State<_TextPreview> {
  late final Future<String> _text = _load();

  Future<String> _load() async {
    final file = File(widget.path);
    if (!await file.exists()) return '';
    final text = await file.readAsString();
    return text.length > 900 ? text.substring(0, 900) : text;
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.width / 102;
    return FutureBuilder<String>(
      future: _text,
      builder: (context, snapshot) => Padding(
        padding: EdgeInsets.all(8 * scale),
        child: Text(
          snapshot.data ?? '',
          overflow: TextOverflow.clip,
          style: narraText(3.6 * scale, color: const Color(0xFF444444), lineHeight: 5.4 * scale),
        ),
      ),
    );
  }
}
