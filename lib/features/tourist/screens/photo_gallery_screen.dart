import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/prototype/prototype_session.dart';

class PhotoGalleryScreen extends StatefulWidget {
  final String spotId;
  const PhotoGalleryScreen({super.key, required this.spotId});

  @override
  State<PhotoGalleryScreen> createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  int _currentIndex = 0;
  bool _showUI = true;
  final PageController _pageCtrl = PageController();

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spot = PrototypeSession.allSpots.value
        .where((s) => s.id == widget.spotId && s.isActive)
        .firstOrNull;
    if (spot == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.photos)),
        body: Center(
          child: Text(context.l10n.thisAttractionIsNoLongerAvailable),
        ),
      );
    }
    final totalImages = spot.imageUrls.length;

    if (spot.imageUrls.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: EmptyStateWidget(
          icon: Icons.image_not_supported,
          title: context.l10n.noPhotosAvailable,
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Semantics(
        button: true,
        label: context.l10n.togglePhotoControls,
        child: GestureDetector(
          onTap: () => setState(() => _showUI = !_showUI),
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageCtrl,
                itemCount: totalImages,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemBuilder: (context, index) {
                  return Center(
                    child: SafeAppImage(
                      path: spot.imageUrls[index],
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.contain,
                    ),
                  );
                },
              ),
              if (_showUI)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top,
                      left: 8,
                      right: 8,
                      bottom: 8,
                    ),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black87, Colors.transparent],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: context.l10n.close,
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => context.pop(),
                        ),
                        const Spacer(),
                        Text(
                          context.message(
                            '${_currentIndex + 1} / $totalImages',
                          ),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: context.l10n.share,
                          icon: const Icon(Icons.share, color: Colors.white),
                          onPressed: () {
                            SharePlus.instance.share(
                              ShareParams(
                                text: context.l10n.checkOutInBustosBulacanValue(
                                  context.message((spot.name).toString()),
                                ),
                                subject: spot.name,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              if (_showUI)
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: SmoothPageIndicator(
                      controller: _pageCtrl,
                      count: totalImages,
                      effect: const WormEffect(
                        dotHeight: 8,
                        dotWidth: 8,
                        activeDotColor: Colors.white,
                        dotColor: Colors.white30,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
