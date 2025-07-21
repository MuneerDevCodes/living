import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:living/style/theme.dart';

/// Performance optimization service for handling image caching and lazy loading
class PerformanceService {
  static const int _defaultCacheSize = 100; // Number of images to cache
  static const Duration _defaultCacheDuration = Duration(days: 7);
  
  /// Preload images for better performance
  static Future<void> preloadImages(List<String> imageUrls, BuildContext context) async {
    for (String url in imageUrls) {
      try {
        await precacheImage(
          CachedNetworkImageProvider(url),
          context,
        );
      } catch (e) {
        // Silently handle preload errors
        debugPrint('Failed to preload image: $url');
      }
    }
  }

  /// Clear image cache
  static Future<void> clearImageCache() async {
    await CachedNetworkImage.evictFromCache('');
  }

  /// Get cached network image with loading and error states
  static Widget getCachedImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => placeholder ?? _buildShimmerPlaceholder(width, height),
      errorWidget: (context, url, error) => errorWidget ?? _buildErrorWidget(),
      imageBuilder: (context, imageProvider) {
        Widget image = Image(image: imageProvider, fit: fit);
        if (borderRadius != null) {
          image = ClipRRect(borderRadius: borderRadius, child: image);
        }
        return image;
      },
    );
  }

  /// Build shimmer loading placeholder
  static Widget _buildShimmerPlaceholder(double? width, double? height) {
    return Shimmer.fromColors(
      baseColor: AppColors.borderLight,
      highlightColor: AppColors.white,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.borderLight,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Build error widget for failed image loads
  static Widget _buildErrorWidget() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.borderLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.broken_image,
        color: AppColors.mutedText,
        size: 32,
      ),
    );
  }
}

/// Lazy loading widget for lists
class LazyLoadingList<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final int itemsPerPage;
  final Widget? loadingWidget;
  final bool hasMoreItems;
  final VoidCallback? onLoadMore;
  final ScrollController? scrollController;

  const LazyLoadingList({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.itemsPerPage = 20,
    this.loadingWidget,
    this.hasMoreItems = false,
    this.onLoadMore,
    this.scrollController,
  });

  @override
  State<LazyLoadingList<T>> createState() => _LazyLoadingListState<T>();
}

class _LazyLoadingListState<T> extends State<LazyLoadingList<T>> {
  late ScrollController _scrollController;
  int _visibleItems = 0;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_onScroll);
    _visibleItems = widget.itemsPerPage;
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreItems();
    }
  }

  Future<void> _loadMoreItems() async {
    if (_isLoadingMore || !widget.hasMoreItems) return;

    setState(() {
      _isLoadingMore = true;
    });

    if (widget.onLoadMore != null) {
      await Future.delayed(const Duration(milliseconds: 100));
      widget.onLoadMore!();
    } else {
      setState(() {
        _visibleItems = (_visibleItems + widget.itemsPerPage)
            .clamp(0, widget.items.length);
      });
    }

    setState(() {
      _isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = widget.items.take(_visibleItems).toList();
    
    return ListView.builder(
      controller: _scrollController,
      itemCount: visibleItems.length + (widget.hasMoreItems ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == visibleItems.length) {
          return widget.loadingWidget ?? 
                 const Center(child: CircularProgressIndicator());
        }
        return widget.itemBuilder(context, visibleItems[index], index);
      },
    );
  }
}

/// Visibility-aware widget for lazy loading
class VisibilityAwareWidget extends StatelessWidget {
  final Widget child;
  final VoidCallback? onVisible;
  final VoidCallback? onInvisible;
  final double visibilityFraction;

  const VisibilityAwareWidget({
    super.key,
    required this.child,
    this.onVisible,
    this.onInvisible,
    this.visibilityFraction = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: key ?? UniqueKey(),
      onVisibilityChanged: (info) {
        if (info.visibleFraction >= visibilityFraction) {
          onVisible?.call();
        } else {
          onInvisible?.call();
        }
      },
      child: child,
    );
  }
}

/// Optimized grid view with lazy loading
class OptimizedGridView<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double childAspectRatio;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final int itemsPerPage;
  final bool hasMoreItems;
  final VoidCallback? onLoadMore;
  final Widget? loadingWidget;

  const OptimizedGridView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.crossAxisCount = 2,
    this.crossAxisSpacing = 10,
    this.mainAxisSpacing = 10,
    this.childAspectRatio = 1.0,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.itemsPerPage = 20,
    this.hasMoreItems = false,
    this.onLoadMore,
    this.loadingWidget,
  });

  @override
  State<OptimizedGridView<T>> createState() => _OptimizedGridViewState<T>();
}

class _OptimizedGridViewState<T> extends State<OptimizedGridView<T>> {
  late ScrollController _scrollController;
  int _visibleItems = 0;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _visibleItems = widget.itemsPerPage;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreItems();
    }
  }

  Future<void> _loadMoreItems() async {
    if (_isLoadingMore || !widget.hasMoreItems) return;

    setState(() {
      _isLoadingMore = true;
    });

    if (widget.onLoadMore != null) {
      await Future.delayed(const Duration(milliseconds: 100));
      widget.onLoadMore!();
    } else {
      setState(() {
        _visibleItems = (_visibleItems + widget.itemsPerPage)
            .clamp(0, widget.items.length);
      });
    }

    setState(() {
      _isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = widget.items.take(_visibleItems).toList();
    
    return GridView.builder(
      controller: _scrollController,
      padding: widget.padding,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        crossAxisSpacing: widget.crossAxisSpacing,
        mainAxisSpacing: widget.mainAxisSpacing,
        childAspectRatio: widget.childAspectRatio,
      ),
      itemCount: visibleItems.length + (widget.hasMoreItems ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == visibleItems.length) {
          return widget.loadingWidget ?? 
                 const Center(child: CircularProgressIndicator());
        }
        return widget.itemBuilder(context, visibleItems[index], index);
      },
    );
  }
} 