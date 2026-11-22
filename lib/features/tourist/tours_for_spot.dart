import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../core/session/app_session.dart';

/// Tours are booked only as packages. From a place, open the one package
/// that stops there, or the package list when several (or none) do.
void openToursForSpot(BuildContext context, String spotId) {
  final packages = AppSession.packagesWithSpot(spotId);
  context.push(
    packages.length == 1
        ? '/tourist/tour-packages/${packages.single.id}'
        : '/tourist/tour-packages',
  );
}
