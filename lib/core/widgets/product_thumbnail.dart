import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import 'app_spacing.dart';

/// Square product thumbnail with a tappable fullscreen Hero preview.
///
/// `imageUrl` is the already-resolved public URL (constructed in the data
/// layer via `Supabase.storage.from(bucket).getPublicUrl(path)`).  Null/empty
/// shows a placeholder icon so cards never error out for products without
/// catalog images.
class ProductThumbnail extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final String? heroTag;
  final String? captionForFullscreen;

  const ProductThumbnail({
    super.key,
    required this.imageUrl,
    this.size = 56,
    this.heroTag,
    this.captionForFullscreen,
  });

  bool get _hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSpacing.rMd);
    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppConstants.softSurface(context),
        borderRadius: radius,
        border: Border.all(color: AppConstants.softBorder(context)),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.local_florist_outlined,
        size: size * 0.5,
        color: AppConstants.textFaint(context),
      ),
    );

    if (!_hasImage) return placeholder;

    final tag = heroTag ?? imageUrl!;
    final image = ClipRRect(
      borderRadius: radius,
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, _) => Container(
          width: size,
          height: size,
          color: AppConstants.softSurface(context),
        ),
        errorWidget: (_, _, _) => placeholder,
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: () => _openFullscreen(context, tag),
        child: Hero(tag: tag, child: image),
      ),
    );
  }

  void _openFullscreen(BuildContext context, String tag) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, _, _) => _FullscreenImage(
          imageUrl: imageUrl!,
          heroTag: tag,
          caption: captionForFullscreen,
        ),
      ),
    );
  }
}

class _FullscreenImage extends StatelessWidget {
  final String imageUrl;
  final String heroTag;
  final String? caption;

  const _FullscreenImage({
    required this.imageUrl,
    required this.heroTag,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const SizedBox.expand(),
          ),
          Center(
            child: Hero(
              tag: heroTag,
              child: InteractiveViewer(
                maxScale: 5,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (_, _) => const SizedBox(
                    height: 48,
                    width: 48,
                    child: CircularProgressIndicator(
                      color: AppConstants.primaryColor,
                      strokeWidth: 2.5,
                    ),
                  ),
                  errorWidget: (_, _, _) => Icon(
                    Icons.broken_image_outlined,
                    size: 64,
                    color: AppConstants.textFaint(context),
                  ),
                ),
              ),
            ),
          ),
          if (caption != null && caption!.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s16, vertical: AppSpacing.s14),
                  color: Colors.black54,
                  child: Text(
                    caption!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
