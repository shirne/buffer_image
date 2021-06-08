
library blend_mode;

import 'dart:math';
import 'dart:ui';

import 'package:flutter/painting.dart';

/// a blend mode factory of [BlendMode] in [painting]
abstract class BlendModeAction {
  final BlendMode mode;

  const BlendModeAction._(this.mode);

  factory BlendModeAction(BlendMode mode) {
    switch (mode) {
      case BlendMode.clear:
        return const _BlendModeClear();
      case BlendMode.color:
        return const _BlendModeColor();
      case BlendMode.colorBurn:
        return const _BlendModeColorBurn();
      case BlendMode.colorDodge:
        return const _BlendModeColorDodge();
      case BlendMode.darken:
        return const _BlendModeDarken();
      case BlendMode.difference:
        return const _BlendModeDifference();
      case BlendMode.dst:
        return const _BlendModeDst();
      case BlendMode.dstATop:
        return const _BlendModeDstATop();
      case BlendMode.dstIn:
        return const _BlendModeDstIn();
      case BlendMode.dstOut:
        return const _BlendModeDstOut();
      case BlendMode.dstOver:
        return const _BlendModeDstOver();
      case BlendMode.exclusion:
        return const _BlendModeExclusion();
      case BlendMode.hardLight:
        return const _BlendModeHardLight();
      case BlendMode.hue:
        return const _BlendModeHue();
      case BlendMode.lighten:
        return const _BlendModeLighten();
      case BlendMode.luminosity:
        return const _BlendModeLuminosity();
      case BlendMode.modulate:
        return const _BlendModeModulate();
      case BlendMode.multiply:
        return const _BlendModeMultiply();
      case BlendMode.overlay:
        return const _BlendModeOverlay();
      case BlendMode.plus:
        return const _BlendModePlus();
      case BlendMode.saturation:
        return const _BlendModeSaturation();
      case BlendMode.screen:
        return const _BlendModeScreen();
      case BlendMode.softLight:
        return const _BlendModeSoftLight();
      case BlendMode.src:
        return const _BlendModeSrc();
      case BlendMode.srcATop:
        return const _BlendModeSrcATop();
      case BlendMode.srcIn:
        return const _BlendModeSrcIn();
      case BlendMode.srcOut:
        return const _BlendModeSrcOut();
      case BlendMode.srcOver:
        return const _BlendModeSrcOver();
      case BlendMode.xor:
        return const _BlendModeXor();

      default:
        throw UnimplementedError('Unimplemented BlendMode $mode');
    }
  }
  Color blend(Color src, Color dst);
}

class _BlendModeMultiply extends BlendModeAction {
  const _BlendModeMultiply() : super._(BlendMode.multiply);

  @override
  blend(Color src, Color dst) {
    int red = (src.red * dst.red ~/ 255);
    int green = (src.green * dst.green ~/ 255);
    int blue = (src.blue * dst.blue ~/ 255);
    return Color.fromARGB(src.alpha * dst.alpha ~/ 255, red, green, blue);
  }
}

class _BlendModeXor extends BlendModeAction {
  const _BlendModeXor() : super._(BlendMode.xor);

  @override
  blend(Color src, Color dst) {
    return Color(src.value ^ dst.value);
  }
}

class _BlendModeSrcOver extends BlendModeAction {
  const _BlendModeSrcOver() : super._(BlendMode.srcOver);

  @override
  blend(Color src, Color dst) {
    return Color.alphaBlend(src, dst);
  }
}

class _BlendModeSrcOut extends BlendModeAction {
  const _BlendModeSrcOut() : super._(BlendMode.srcOut);

  @override
  blend(Color src, Color dst) {
    if (src.alpha > 0 && dst.alpha > 0 || (src.alpha == 0 && dst.alpha == 0)) {
      return Color.fromARGB(0, 0, 0, 0);
    }
    return Color.fromARGB(
        src.alpha == 0 ? dst.alpha : 0, src.red, src.green, src.blue);
  }
}

class _BlendModeSrcIn extends BlendModeAction {
  const _BlendModeSrcIn() : super._(BlendMode.srcIn);

  @override
  blend(Color src, Color dst) {
    if (src.alpha == 0 || dst.alpha == 0) {
      return src.withAlpha(0);
    }
    return Color.fromARGB(dst.alpha, src.red, src.green, src.blue);
  }
}

class _BlendModeSrcATop extends BlendModeAction {
  const _BlendModeSrcATop() : super._(BlendMode.srcATop);

  @override
  blend(Color src, Color dst) {
    if (src.alpha == 0 || dst.alpha == 0) {
      return dst;
    }

    Color newColor = Color.alphaBlend(src, dst);

    return newColor.withAlpha(dst.alpha);
  }
}

class _BlendModeSoftLight extends BlendModeAction {
  const _BlendModeSoftLight() : super._(BlendMode.softLight);

  @override
  blend(Color src, Color dst) {
    int red = _channel(src.red, dst.red);
    int green = _channel(src.green, dst.green);
    int blue = _channel(src.blue, dst.blue);
    int alpha = src.alpha + (dst.alpha * (255 - src.alpha)) ~/ 0xff;

    return Color.fromARGB(alpha, red, green, blue);
  }

  int _channel(int src, int dst) {
    if (src < 128) {
      return dst ~/ (255 - src);
    } else {
      return 255 - (255 - dst) ~/ src;
    }
  }
}

class _BlendModeSrc extends BlendModeAction {
  const _BlendModeSrc() : super._(BlendMode.src);

  @override
  blend(Color src, Color dst) {
    return src;
  }
}

class _BlendModeScreen extends BlendModeAction {
  const _BlendModeScreen() : super._(BlendMode.screen);

  @override
  blend(Color src, Color dst) {
    int red = _channel(src.red, dst.red);
    int green = _channel(src.green, dst.green);
    int blue = _channel(src.blue, dst.blue);
    int alpha = _channel(src.alpha, dst.alpha);

    return Color.fromARGB(alpha, red, green, blue);
  }

  int _channel(int src, int dst) {
    return 255 - ((255 - src) * (255 - dst) ~/ 255);
  }
}

class _BlendModeSaturation extends BlendModeAction {
  const _BlendModeSaturation() : super._(BlendMode.saturation);

  @override
  blend(Color src, Color dst) {
    var sHSL = HSLColor.fromColor(src);
    var dHSL = HSLColor.fromColor(dst);
    double alpha = (src.alpha + (dst.alpha * (255 - src.alpha)) / 0xff) / 0xff;
    var nHSL = HSLColor.fromAHSL(alpha, dHSL.hue,
        src.alpha == 0 ? dHSL.saturation : sHSL.saturation, dHSL.lightness);

    return nHSL.toColor();
  }
}

class _BlendModePlus extends BlendModeAction {
  const _BlendModePlus() : super._(BlendMode.plus);

  @override
  blend(Color src, Color dst) {
    double srcAlpha = 1, dstAlpha = 1;
    if (src.alpha == 0) {
      srcAlpha = 0;
    } else if (dst.alpha == 0) {
      dstAlpha = 0;
    } else {
      if (src.alpha > dst.alpha) {
        dstAlpha = dst.alpha / src.alpha;
      } else {
        srcAlpha = src.alpha / dst.alpha;
      }
    }
    int red = _channel(src.red * srcAlpha, dst.red * dstAlpha);
    int green = _channel(src.green * srcAlpha, dst.green * dstAlpha);
    int blue = _channel(src.blue * srcAlpha, dst.blue * dstAlpha);
    int alpha = _channel(src.alpha.toDouble(), dst.alpha.toDouble());

    return Color.fromARGB(alpha, red, green, blue);
  }

  int _channel(double src, double dst) {
    int result = (src + dst).round();
    return result > 255 ? 255 : result;
  }
}

class _BlendModeOverlay extends BlendModeAction {
  const _BlendModeOverlay() : super._(BlendMode.overlay);

  @override
  blend(Color src, Color dst) {
    int red = _channel(src.red, dst.red);
    int green = _channel(src.green, dst.green);
    int blue = _channel(src.blue, dst.blue);
    int alpha = _channel(src.alpha, dst.alpha);

    return Color.fromARGB(alpha, red, green, blue);
  }

  // todo equal ?
  int _channel(int src, int dst) {
    if (dst < src) {
      return src * dst ~/ 255;
    } else {
      return 255 - ((255 - src) * (255 - dst) ~/ 255);
    }
  }
}

class _BlendModeModulate extends BlendModeAction {
  const _BlendModeModulate() : super._(BlendMode.modulate);

  @override
  blend(Color src, Color dst) {
    int red = _channel(src.red, dst.red);
    int green = _channel(src.green, dst.green);
    int blue = _channel(src.blue, dst.blue);
    int alpha = src.alpha + (dst.alpha * (255 - src.alpha)) ~/ 0xff;

    return Color.fromARGB(alpha, red, green, blue);
  }

  int _channel(int src, int dst) {
    return src * dst ~/ 255;
  }
}

class _BlendModeLuminosity extends BlendModeAction {
  const _BlendModeLuminosity() : super._(BlendMode.luminosity);

  @override
  blend(Color src, Color dst) {
    var sHSL = HSLColor.fromColor(src);
    var dHSL = HSLColor.fromColor(dst);
    double alpha = (src.alpha + (dst.alpha * (255 - src.alpha)) ~/ 0xff) / 0xff;
    var nHSL = HSLColor.fromAHSL(alpha, dHSL.hue, dHSL.saturation,
        src.alpha == 0 ? dHSL.lightness : sHSL.lightness);

    return nHSL.toColor();
  }
}

class _BlendModeLighten extends BlendModeAction {
  const _BlendModeLighten() : super._(BlendMode.lighten);

  @override
  blend(Color src, Color dst) {
    int red = max(src.red, dst.red);
    int green = max(src.green, dst.green);
    int blue = max(src.blue, dst.blue);
    int alpha = src.alpha + (dst.alpha * (255 - src.alpha)) ~/ 0xff;

    return Color.fromARGB(alpha, red, green, blue);
  }
}

class _BlendModeHue extends BlendModeAction {
  const _BlendModeHue() : super._(BlendMode.hue);

  @override
  blend(Color src, Color dst) {
    var fHSL = HSLColor.fromColor(src);
    var bHSL = HSLColor.fromColor(dst);
    double alpha = (src.alpha + (dst.alpha * (255 - src.alpha)) ~/ 0xff) / 0xff;
    var nHSL = HSLColor.fromAHSL(alpha, src.alpha == 0 ? bHSL.hue : fHSL.hue,
        bHSL.saturation, bHSL.lightness);

    return nHSL.toColor();
  }
}

class _BlendModeHardLight extends BlendModeAction {
  const _BlendModeHardLight() : super._(BlendMode.hardLight);

  @override
  blend(Color src, Color dst) {
    int red = _channel(src.red, dst.red);
    int green = _channel(src.green, dst.green);
    int blue = _channel(src.blue, dst.blue);
    int alpha = _channel(src.alpha, dst.alpha);

    return Color.fromARGB(alpha, red, green, blue);
  }

  // todo equal ?
  int _channel(int src, int dst) {
    if (src < dst) {
      return src * dst ~/ 255;
    } else {
      return 255 - (255 - dst) * (255 - src) ~/ 255;
    }
  }
}

class _BlendModeExclusion extends BlendModeAction {
  const _BlendModeExclusion() : super._(BlendMode.exclusion);

  @override
  blend(Color src, Color dst) {
    int red = _channel(src.red, dst.red);
    int green = _channel(src.green, dst.green);
    int blue = _channel(src.blue, dst.blue);
    int alpha = src.alpha + (dst.alpha * (255 - src.alpha)) ~/ 0xff;

    return Color.fromARGB(alpha, red, green, blue);
  }

  int _channel(int src, int dst) {
    return src + dst - 2 * src * dst ~/ 255;
  }
}

class _BlendModeDstOver extends BlendModeAction {
  const _BlendModeDstOver() : super._(BlendMode.dstOver);

  @override
  blend(Color src, Color dst) {
    return Color.alphaBlend(dst, src);
  }
}

class _BlendModeDstOut extends BlendModeAction {
  const _BlendModeDstOut() : super._(BlendMode.dstOut);

  @override
  blend(Color src, Color dst) {
    if (dst.alpha == 0) {
      return dst;
    }

    return dst.withAlpha(255 - src.alpha);
  }
}

class _BlendModeDstIn extends BlendModeAction {
  const _BlendModeDstIn() : super._(BlendMode.dstIn);

  @override
  blend(Color src, Color dst) {
    return Color.fromARGB(src.alpha, dst.red, dst.green, dst.blue);
  }
}

class _BlendModeDstATop extends BlendModeAction {
  const _BlendModeDstATop() : super._(BlendMode.dstATop);

  @override
  blend(Color src, Color dst) {
    Color nColor = Color.alphaBlend(dst, src);

    return nColor.withAlpha(src.alpha);
  }
}

class _BlendModeDst extends BlendModeAction {
  const _BlendModeDst() : super._(BlendMode.dst);

  @override
  blend(Color src, Color dst) {
    return dst;
  }
}

class _BlendModeDifference extends BlendModeAction {
  const _BlendModeDifference() : super._(BlendMode.difference);

  @override
  blend(Color src, Color dst) {
    int red = (src.red - dst.red).abs();
    int green = (src.green - dst.green).abs();
    int blue = (src.blue - dst.blue).abs();
    int alpha = src.alpha + (dst.alpha * (255 - src.alpha)) ~/ 0xff;

    return Color.fromARGB(alpha, red, green, blue);
  }
}

class _BlendModeDarken extends BlendModeAction {
  const _BlendModeDarken() : super._(BlendMode.darken);

  @override
  blend(Color src, Color dst) {
    int red = min(src.red, dst.red);
    int green = min(src.green, dst.green);
    int blue = min(src.blue, dst.blue);
    int alpha = src.alpha + (dst.alpha * (255 - src.alpha)) ~/ 0xff;

    return Color.fromARGB(alpha, red, green, blue);
  }
}

class _BlendModeColorDodge extends BlendModeAction {
  const _BlendModeColorDodge() : super._(BlendMode.colorDodge);

  @override
  blend(Color src, Color dst) {
    int red = _channel(src.red, dst.red);
    int green = _channel(src.green, dst.green);
    int blue = _channel(src.blue, dst.blue);
    int alpha = _channel(src.alpha, dst.alpha);
    return Color.fromARGB(alpha, red, green, blue);
  }

  int _channel(int src, int dst) {
    if (src == 255) return 255;
    return dst ~/ (255 - src);
  }
}

class _BlendModeClear extends BlendModeAction {
  const _BlendModeClear() : super._(BlendMode.clear);

  @override
  blend(Color src, Color dst) {
    return Color.fromARGB(0, 0, 0, 0);
  }
}

class _BlendModeColor extends BlendModeAction {
  const _BlendModeColor() : super._(BlendMode.color);

  @override
  blend(Color src, Color dst) {
    var fHSL = HSLColor.fromColor(src);
    var bHSL = HSLColor.fromColor(dst);
    double alpha = (src.alpha + (dst.alpha * (255 - src.alpha)) ~/ 0xff) / 0xff;
    var nHSL =
        HSLColor.fromAHSL(alpha, fHSL.hue, fHSL.saturation, bHSL.lightness);

    return nHSL.toColor();
  }
}

class _BlendModeColorBurn extends BlendModeAction {
  const _BlendModeColorBurn() : super._(BlendMode.colorBurn);

  @override
  blend(Color src, Color dst) {
    int red = _channel(src.red, dst.red);
    int green = _channel(src.green, dst.green);
    int blue = _channel(src.blue, dst.blue);
    int alpha = _channel(src.alpha, dst.alpha);
    return Color.fromARGB(alpha, red, green, blue);
  }

  int _channel(int src, int dst) {
    if (src == 0) return 0;
    return 255 - (255 - dst) ~/ src;
  }
}
