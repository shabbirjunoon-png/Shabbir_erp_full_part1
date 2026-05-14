import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../services/web_download_stub.dart'
    if (dart.library.html) '../services/web_download_html.dart';
import '../services/native_backup_stub.dart'
    if (dart.library.io) '../services/native_backup_impl.dart';
// ignore: avoid_web_libraries_in_flutter
import '../services/pdf_iframe_stub.dart'
    if (dart.library.html) '../services/pdf_iframe_html.dart';

class PdfPreviewScreen extends StatefulWidget {
  final List<int> pdfBytes;
  final String filename;

  const PdfPreviewScreen({
    super.key,
    required this.pdfBytes,
    required this.filename,
  });

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  bool _showPreview = true;

  void _download(BuildContext context) {
    try {
      if (kIsWeb) {
        triggerWebDownload(widget.pdfBytes, widget.filename);
      } else {
        nativeBackup(widget.pdfBytes, widget.filename);
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Downloading ${widget.filename}', style: GoogleFonts.inter()),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Download failed: $e', style: GoogleFonts.inter()),
        backgroundColor: AppColors.destructive,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final kb = (widget.pdfBytes.length / 1024).toStringAsFixed(1);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            margin: const EdgeInsets.only(left: 16),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.foreground),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PDF', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.foreground)),
            Text(widget.filename, style: GoogleFonts.inter(fontSize: 11, color: AppColors.mutedForeground), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: () => _download(context),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.download_rounded, size: 15, color: AppColors.primary),
                const SizedBox(width: 5),
                Text('Download', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.primary)),
              ]),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _showPreview = !_showPreview),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _showPreview ? AppColors.primary : AppColors.secondary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _showPreview ? AppColors.primary : AppColors.border),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.visibility_outlined, size: 15, color: _showPreview ? Colors.white : AppColors.primary),
                const SizedBox(width: 5),
                Text('Preview', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12, color: _showPreview ? Colors.white : AppColors.primary)),
              ]),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(children: [
              const Icon(Icons.picture_as_pdf_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.filename, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.foreground), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('$kb KB · PDF Document', style: GoogleFonts.inter(fontSize: 11, color: AppColors.mutedForeground)),
                ]),
              ),
              GestureDetector(
                onTap: () => _download(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.download_rounded, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text('Save', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.white)),
                  ]),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          if (_showPreview)
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [AppColors.elevatedShadow],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _PdfViewer(pdfBytes: widget.pdfBytes),
                ),
              ),
            )
          else
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(Icons.picture_as_pdf_outlined, size: 40, color: AppColors.primary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.filename,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.foreground),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$kb KB · PDF ready',
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.mutedForeground),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => _showPreview = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.visibility_outlined, size: 17, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text('Preview', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.primary)),
                            ]),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => _download(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.download_rounded, size: 17, color: Colors.white),
                              const SizedBox(width: 8),
                              Text('Download', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white)),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PdfViewer extends StatelessWidget {
  final List<int> pdfBytes;
  const _PdfViewer({required this.pdfBytes});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return _WebPdfEmbed(pdfBytes: pdfBytes);
    }
    return _NativePdfPlaceholder(pdfBytes: pdfBytes);
  }
}

class _NativePdfPlaceholder extends StatelessWidget {
  final List<int> pdfBytes;
  const _NativePdfPlaceholder({required this.pdfBytes});

  @override
  Widget build(BuildContext context) {
    final kb = (pdfBytes.length / 1024).toStringAsFixed(1);
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.picture_as_pdf_outlined, size: 36, color: AppColors.primary),
        ),
        const SizedBox(height: 16),
        Text('PDF Ready ($kb KB)', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.foreground)),
        const SizedBox(height: 8),
        Text('Tap Download to save the PDF\nto your device.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, color: AppColors.mutedForeground, height: 1.6)),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () {
            nativeBackup(pdfBytes, 'ledger.pdf');
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('PDF saved!', style: GoogleFonts.inter()),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(14)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.download_rounded, size: 18, color: Colors.white),
              const SizedBox(width: 10),
              Text('Download PDF', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _WebPdfEmbed extends StatefulWidget {
  final List<int> pdfBytes;
  const _WebPdfEmbed({required this.pdfBytes});

  @override
  State<_WebPdfEmbed> createState() => _WebPdfEmbedState();
}

class _WebPdfEmbedState extends State<_WebPdfEmbed> {
  String? _iframeId;

  @override
  void initState() {
    super.initState();
    final base64Data = base64Encode(widget.pdfBytes);
    _iframeId = registerPdfIframe(base64Data);
  }

  @override
  void dispose() {
    if (_iframeId != null) {
      unregisterPdfIframe(_iframeId!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_iframeId == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return buildPdfIframeWidget(_iframeId!);
  }
}
