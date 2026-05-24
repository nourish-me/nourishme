import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

// NourishMe custom icon set from the TestFlight 1.1 design pass.
// Two-tone (pine + amber, food-safety is plum + amber). 24 pt base.
// Renders flat SVG, no tint. Selected/unselected states should rely on
// surrounding container chrome, not icon recolor.
class NMIcons {
  NMIcons._();

  static const _base = 'assets/icons';

  static Widget pregnancy({double size = 24}) =>
      _icon('ic_nm_pregnancy', size);
  static Widget nursing({double size = 24}) =>
      _icon('ic_nm_nursing', size);
  static Widget pumping({double size = 24}) =>
      _icon('ic_nm_pumping', size);
  static Widget multiples({double size = 24}) =>
      _icon('ic_nm_multiples', size);
  static Widget meal({double size = 24}) =>
      _icon('ic_nm_meal', size);
  static Widget foodSafety({double size = 24}) =>
      _icon('ic_nm_food_safety', size);
  static Widget coach({double size = 24}) =>
      _icon('ic_nm_coach', size);
  static Widget journal({double size = 24}) =>
      _icon('ic_nm_journal', size);

  static Widget _icon(String name, double size) => SvgPicture.asset(
        '$_base/$name.svg',
        width: size,
        height: size,
      );
}
