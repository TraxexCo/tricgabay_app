import 'package:flutter/material.dart';

/// The production builder creates the native map. Widget tests supply a local
/// map substitute so viewport tests never need platform channels or a provider.
class MapSurface extends StatelessWidget {
  final WidgetBuilder builder;
  static WidgetBuilder? testBuilder;
  const MapSurface({super.key, required this.builder});
  @override
  Widget build(BuildContext context) => (testBuilder ?? builder)(context);
}
