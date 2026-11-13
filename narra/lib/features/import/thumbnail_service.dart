import 'dart:io';
import 'dart:ui' as ui;

import 'package:pdfrx/pdfrx.dart';

class ThumbnailResult {
  const ThumbnailResult({this.path, this.pageCount});

  final String? path;
  final int? pageCount;
}

abstract interface class ThumbnailService {
  /// Renders the first page of [pdfPath] to a PNG at [outPath].
  Future<ThumbnailResult> createForPdf(String pdfPath, String outPath);
}

class PdfrxThumbnailService implements ThumbnailService {
  /// Three times the library thumbnail width, so covers stay sharp on
  /// high-density displays.
  static const renderWidth = 306.0;

  @override
  Future<ThumbnailResult> createForPdf(String pdfPath, String outPath) async {
    final document = await PdfDocument.openFile(pdfPath);
    try {
      final pageCount = document.pages.length;
      if (pageCount == 0) return const ThumbnailResult(pageCount: 0);
      final page = document.pages.first;
      final rendered = await page.render(
        fullWidth: renderWidth,
        fullHeight: renderWidth * page.height / page.width,
        backgroundColor: 0xFFFFFFFF,
      );
      if (rendered == null) return ThumbnailResult(pageCount: pageCount);
      final image = await rendered.createImage();
      rendered.dispose();
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (png == null) return ThumbnailResult(pageCount: pageCount);
      await File(outPath).writeAsBytes(png.buffer.asUint8List(), flush: true);
      return ThumbnailResult(path: outPath, pageCount: pageCount);
    } finally {
      await document.dispose();
    }
  }
}
