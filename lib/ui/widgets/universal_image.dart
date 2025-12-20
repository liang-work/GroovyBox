import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class UniversalImage extends StatelessWidget {
  final String? uri;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final Widget? fallback;
  final IconData? fallbackIcon;
  final double? fallbackIconSize;
  final Color? fallbackIconColor;
  final BorderRadius? borderRadius;
  final bool useDecorationImage;

  const UniversalImage({
    super.key,
    this.uri,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.fallback,
    this.fallbackIcon = Symbols.image,
    this.fallbackIconSize = 48,
    this.fallbackIconColor = Colors.white54,
    this.borderRadius,
    this.useDecorationImage = false,
  });

  bool _isNetworkUri(String uri) {
    return uri.startsWith('http://') || uri.startsWith('https://');
  }

  Widget _buildFallback() {
    if (fallback != null) {
      return fallback!;
    }

    final icon = Icon(
      fallbackIcon,
      size: fallbackIconSize,
      color: fallbackIconColor,
    );

    if (borderRadius != null) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: borderRadius,
        ),
        child: icon,
      );
    }

    return Container(
      width: width,
      height: height,
      color: Colors.grey[800],
      child: icon,
    );
  }

  Widget _buildNetworkImage() {
    if (useDecorationImage) {
      return CachedNetworkImage(
        imageUrl: uri!,
        fit: fit,
        width: width,
        height: height,
        placeholder: (context, url) => Container(
          width: width,
          height: height,
          color: Colors.grey[800],
          child: const CircularProgressIndicator(),
        ),
        errorWidget: (context, url, error) => _buildFallback(),
      );
    }

    return CachedNetworkImage(
      imageUrl: uri!,
      fit: fit,
      width: width,
      height: height,
      placeholder: (context, url) => Container(
        width: width,
        height: height,
        color: Colors.grey[800],
        child: const CircularProgressIndicator(),
      ),
      errorWidget: (context, url, error) => _buildFallback(),
    );
  }

  Widget _buildFileImage() {
    if (useDecorationImage) {
      return Image.file(
        File(uri!),
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    }

    return Image.file(
      File(uri!),
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) => _buildFallback(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (uri == null || uri!.isEmpty) {
      return _buildFallback();
    }

    if (_isNetworkUri(uri!)) {
      return _buildNetworkImage();
    } else {
      return _buildFileImage();
    }
  }
}
