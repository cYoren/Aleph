import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Widest a column of reading text should get. On a tablet a full-width line
/// of Hebrew or a word list runs so long the eye loses its place.
const double kReadableMaxWidth = 720;

/// Horizontal padding that keeps content at most [kReadableMaxWidth] wide and
/// centred, and never less than [minimum] at the edges of a phone.
double readableGutter(BuildContext context, {double minimum = 16}) {
  final width = MediaQuery.sizeOf(context).width;
  return math.max(minimum, (width - kReadableMaxWidth) / 2);
}
