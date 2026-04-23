import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

bool useMainLayoutRail(BuildContext context) {
  final responsive = ResponsiveBreakpoints.of(context);
  return responsive.largerThan(TABLET) ||
      MediaQuery.of(context).size.width > 1100;
}
