import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_flow_chart/flutter_flow_chart.dart';
import 'package:flutter_flow_chart/src/ui/segment_handler.dart';

/// Arrow style enumeration
enum ArrowStyle {
  /// A curved arrow which points nicely to each handlers
  curve,

  /// A segmented line where pivot points can be added and curvature between
  /// them can be adjusted with a tension.
  segmented,

  /// A rectangular shaped line.
  rectangular,
}

/// Styles for tail of the arrow.
enum ArrowEndingStyle {
  /// draw the tail as circle.
  circle,

  /// draw the tail as triangle.
  triangle,
}

/// Arrow parameters used by [DrawArrow] widget
class ArrowParams extends ChangeNotifier {
  ///
  ArrowParams({
    this.thickness = 1.7,
    this.headRadius = 6,
    double tailLength = 25.0,
    this.color = Colors.black,
    this.style = ArrowStyle.curve,
    this.tension = 1.0,
    this.startArrowPosition = Alignment.centerRight,
    this.endArrowPosition = Alignment.centerLeft,
    this.endingStyle = ArrowEndingStyle.circle,
    this.endingSize = const Size(12, 16),
  }) : _tailLength = tailLength;

  ///
  factory ArrowParams.fromMap(Map<String, dynamic> map) {
    final endingSize = map['endingSize'] as Map<String, dynamic>? ??
        const {'width': 12, 'height': 16};
    return ArrowParams(
      thickness: (map['thickness'] as num).toDouble(),
      headRadius: ((map['headRadius'] ?? 6.0) as num).toDouble(),
      tailLength: ((map['tailLength'] ?? 25.0) as num).toDouble(),
      color: Color(map['color'] as int),
      style: ArrowStyle.values[map['style'] as int? ?? 0],
      endingStyle: ArrowEndingStyle.values[map['endingStyle'] as int? ?? 0],
      endingSize: Size(
        (endingSize['width'] as num? ?? 12).toDouble(),
        (endingSize['height'] as num? ?? 16).toDouble(),
      ),
      tension: ((map['tension'] ?? 1) as num).toDouble(),
      startArrowPosition: Alignment(
        (map['startArrowPositionX'] as num).toDouble(),
        (map['startArrowPositionY'] as num).toDouble(),
      ),
      endArrowPosition: Alignment(
        (map['endArrowPositionX'] as num).toDouble(),
        (map['endArrowPositionY'] as num).toDouble(),
      ),
    );
  }

  ///
  factory ArrowParams.fromJson(String source) =>
      ArrowParams.fromMap(json.decode(source) as Map<String, dynamic>);

  /// Arrow thickness.
  double thickness;

  /// The radius of arrow tip.
  double headRadius;

  /// Arrow color.
  final Color color;

  /// The start position alignment.
  final Alignment startArrowPosition;

  /// The end position alignment.
  final Alignment endArrowPosition;

  /// The tail length of the arrow.
  double _tailLength;

  /// The style of the arrow.
  ArrowStyle? style;

  /// The curve tension for pivot points when using [ArrowStyle.segmented].
  /// 0 means no curve on segments.
  double tension;

  /// The ending style of the arrow.
  ArrowEndingStyle endingStyle;

  /// The size of the ending.
  Size endingSize;

  ///
  ArrowParams copyWith({
    double? thickness,
    Color? color,
    ArrowStyle? style,
    double? tension,
    Alignment? startArrowPosition,
    Alignment? endArrowPosition,
    ArrowEndingStyle? endingStyle,
    Size? endingSize,
  }) {
    return ArrowParams(
      thickness: thickness ?? this.thickness,
      color: color ?? this.color,
      style: style ?? this.style,
      tension: tension ?? this.tension,
      startArrowPosition: startArrowPosition ?? this.startArrowPosition,
      endArrowPosition: endArrowPosition ?? this.endArrowPosition,
      endingStyle: endingStyle ?? this.endingStyle,
      endingSize: endingSize ?? this.endingSize,
    );
  }

  ///
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'thickness': thickness,
      'headRadius': headRadius,
      'tailLength': _tailLength,
      'color': color.toARGB32(),
      'style': style?.index,
      'tension': tension,
      'startArrowPositionX': startArrowPosition.x,
      'startArrowPositionY': startArrowPosition.y,
      'endArrowPositionX': endArrowPosition.x,
      'endArrowPositionY': endArrowPosition.y,
      'endingStyle': endingStyle.index,
      'endingSize': {'width': endingSize.width, 'height': endingSize.height},
    };
  }

  ///
  String toJson() => json.encode(toMap());

  ///
  void setScale(double currentZoom, double factor) {
    thickness = thickness / currentZoom * factor;
    headRadius = headRadius / currentZoom * factor;
    _tailLength = _tailLength / currentZoom * factor;
    endingSize =
        Size(endingSize.width, endingSize.height) / currentZoom * factor;
    notifyListeners();
  }

  ///
  double get tailLength => _tailLength;
}

/// Notifier to update arrows position, starting/tail points and params
class DrawingArrow extends ChangeNotifier {
  DrawingArrow._();

  /// Singleton instance of this.
  static final instance = DrawingArrow._();

  ArrowParams _params = ArrowParams();

  /// Arrow parameters.
  ArrowParams get params => _params;

  /// Sets the parameters.
  void setParams(ArrowParams params) {
    _params = params;
    notifyListeners();
  }

  /// Starting arrow offset.
  Offset _from = Offset.zero;
  Offset get from => _from;

  ///
  void setFrom(Offset from) {
    _from = from;
    notifyListeners();
  }

  Offset _to = Offset.zero;

  /// Tail arrow offset.
  Offset get to => _to;

  ///
  void setTo(Offset to) {
    _to = to;
    notifyListeners();
  }

  ///
  Size _srcElementSize = Size.zero;

  /// The size of the source element.
  Size get srcElementSize => _srcElementSize;

  /// Sets the size of the source element.
  void setSrcElementSize(Size size) {
    _srcElementSize = size;
    notifyListeners();
  }

  Size _destElementSize = Size.zero;

  /// The size of the destination element.
  Size get destElementSize => _destElementSize;

  /// Sets the size of the destination element.
  void setDestElementSize(Size size) {
    _destElementSize = size;
    notifyListeners();
  }

  ///
  bool isZero() {
    return from == Offset.zero && to == Offset.zero;
  }

  ///
  void reset() {
    _params = ArrowParams();
    _from = Offset.zero;
    _to = Offset.zero;
    _srcElementSize = Size.zero;
    _destElementSize = Size.zero;
    notifyListeners();
  }
}

/// Draw arrow from [srcElement] to [destElement]
/// using [arrowParams] parameters
class DrawArrow extends StatefulWidget {
  ///
  DrawArrow({
    required this.srcElement,
    required this.destElement,
    required List<Pivot> pivots,
    super.key,
    ArrowParams? arrowParams,
  })  : arrowParams = arrowParams ?? ArrowParams(),
        pivots = PivotsNotifier(pivots);

  ///
  final ArrowParams arrowParams;

  ///
  final FlowElement<dynamic> srcElement;

  ///
  final FlowElement<dynamic> destElement;

  ///
  final PivotsNotifier pivots;

  @override
  State<DrawArrow> createState() => _DrawArrowState();
}

class _DrawArrowState extends State<DrawArrow> {
  @override
  void initState() {
    super.initState();
    widget.srcElement.addListener(_elementChanged);
    widget.destElement.addListener(_elementChanged);
    widget.pivots.addListener(_elementChanged);
  }

  @override
  void dispose() {
    widget.srcElement.removeListener(_elementChanged);
    widget.destElement.removeListener(_elementChanged);
    widget.pivots.removeListener(_elementChanged);
    super.dispose();
  }

  void _elementChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    var from = Offset.zero;
    var to = Offset.zero;
    from = Offset(
      widget.srcElement.position.dx +
          widget.srcElement.handlerSize / 2.0 +
          (widget.srcElement.size.width *
              ((widget.arrowParams.startArrowPosition.x + 1) / 2)),
      widget.srcElement.position.dy +
          widget.srcElement.handlerSize / 2.0 +
          (widget.srcElement.size.height *
              ((widget.arrowParams.startArrowPosition.y + 1) / 2)),
    );
    to = Offset(
      widget.destElement.position.dx +
          widget.destElement.handlerSize / 2.0 +
          (widget.destElement.size.width *
              ((widget.arrowParams.endArrowPosition.x + 1) / 2)),
      widget.destElement.position.dy +
          widget.destElement.handlerSize / 2.0 +
          (widget.destElement.size.height *
              ((widget.arrowParams.endArrowPosition.y + 1) / 2)),
    );

    return RepaintBoundary(
      child: Builder(
        builder: (context) {
          return CustomPaint(
            painter: ArrowPainter(
              params: widget.arrowParams,
              from: from,
              to: to,
              pivots: widget.pivots.value,
              srcElementSize: widget.srcElement.size,
              destElementSize: widget.destElement.size,
            ),
            child: Container(),
          );
        },
      ),
    );
  }
}

/// Paint the arrow connection taking in count the
/// [ArrowParams.startArrowPosition] and
/// [ArrowParams.endArrowPosition] alignment.
class ArrowPainter extends CustomPainter {
  ///
  ArrowPainter({
    required this.params,
    required this.from,
    required this.to,
    required this.srcElementSize,
    required this.destElementSize,
    List<Pivot>? pivots,
  }) : pivots = pivots ?? [];

  ///
  final Size srcElementSize;

  ///
  final Size destElementSize;

  ///
  final ArrowParams params;

  ///
  final Offset from;

  ///
  final Offset to;

  ///
  final Path path = Path();

  ///
  final List<List<Offset>> lines = [];

  ///
  final List<Pivot> pivots;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeWidth = params.thickness;

    if (params.style == ArrowStyle.curve) {
      drawCurve(canvas, paint);
    } else if (params.style == ArrowStyle.segmented) {
      drawLine();
    } else if (params.style == ArrowStyle.rectangular) {
      drawRectangularLine(canvas, paint);
    }
    drawEnding(canvas);

    paint
      ..color = params.color
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, paint);
  }

  /// Calculate the line end offset as per [ArrowParams.endArrowPosition] and [ArrowParams.endingStyle].
  /// e.g. when [ArrowParams.endingStyle] is [ArrowEndingStyle.triangle], it should avoid drawing the line into the triangle,
  /// so the line end offset should be adjusted by [ArrowParams.endingSize]. Besides, the triangle heading must be corrected when dragging.
  Offset calculateLineEndOffset(Offset originalTo) {
    Offset p;
    switch (params.endingStyle) {
      case ArrowEndingStyle.triangle:
        switch (params.endArrowPosition) {
          case Alignment.topCenter:
            p = Offset(originalTo.dx, originalTo.dy - params.endingSize.height);
          case Alignment.bottomCenter:
            p = Offset(originalTo.dx, originalTo.dy + params.endingSize.height);
          case Alignment.centerRight:
            p = Offset(originalTo.dx + params.endingSize.height, originalTo.dy);
          case Alignment.centerLeft:
            p = Offset(originalTo.dx - params.endingSize.height, originalTo.dy);
          default:
            p = Offset(originalTo.dx, originalTo.dy);
        }
      case ArrowEndingStyle.circle:
        switch (params.endArrowPosition) {
          case Alignment.topCenter:
            p = Offset(originalTo.dx, originalTo.dy - params.headRadius);
          case Alignment.bottomCenter:
            p = Offset(originalTo.dx, originalTo.dy + params.headRadius);
          case Alignment.centerRight:
            p = Offset(originalTo.dx + params.headRadius, originalTo.dy);
          case Alignment.centerLeft:
            p = Offset(originalTo.dx - params.headRadius, originalTo.dy);
          default:
            p = Offset(originalTo.dx, originalTo.dy);
        }
    }
    return p;
  }

  /// Draw the ending of arrow line.
  void drawEnding(Canvas canvas) {
    switch (params.endingStyle) {
      case ArrowEndingStyle.triangle:
        drawTriangleEnding(canvas);
      case ArrowEndingStyle.circle:
        drawCircleEnding(canvas);
    }
  }

  /// Draw the ending of arrow line as a circle.
  void drawCircleEnding(Canvas canvas) {
    Offset center;
    switch (params.endArrowPosition) {
      case Alignment.topCenter:
      case Alignment.bottomCenter:
      case Alignment.centerLeft:
      case Alignment.centerRight:
        center = to;
      default:
        // when dragging
        final dX = to.dx - from.dx;
        final dY = to.dy - from.dy;
        if (dY.abs() > dX.abs()) {
          // vertical heading
          if (dY > 0) {
            // heading down
            center = Offset(to.dx, to.dy + params.headRadius);
          } else {
            // heading up
            center = Offset(to.dx, to.dy - params.headRadius);
          }
        } else {
          // horizontal headding
          if (dX > 0) {
            // heading right
            center = Offset(to.dx + params.headRadius, to.dy);
          } else {
            // heading left
            center = Offset(to.dx - params.headRadius, to.dy);
          }
        }
    }
    canvas.drawCircle(
      center,
      params.headRadius,
      Paint()
        ..strokeWidth = params.thickness
        ..color = params.color,
    );
  }

  /// Draw a triangle ending.
  void drawTriangleEnding(Canvas canvas) {
    final endingPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = params.color;
    final endingPath = Path()..moveTo(to.dx, to.dy);
    switch (params.endArrowPosition) {
      case Alignment.topCenter:
        endingPath
          ..relativeLineTo(
              -params.endingSize.width / 2, -params.endingSize.height)
          ..relativeLineTo(params.endingSize.width, 0)
          ..relativeLineTo(
              -params.endingSize.width / 2, params.endingSize.height);
      case Alignment.bottomCenter:
        endingPath
          ..relativeLineTo(
              -params.endingSize.width / 2, params.endingSize.height)
          ..relativeLineTo(params.endingSize.width, 0)
          ..relativeLineTo(
              -params.endingSize.width / 2, -params.endingSize.height);
      case Alignment.centerLeft:
        endingPath
          ..relativeLineTo(
              -params.endingSize.height, -params.endingSize.width / 2)
          ..relativeLineTo(0, params.endingSize.width)
          ..relativeLineTo(
              params.endingSize.height, -params.endingSize.width / 2);
      case Alignment.centerRight:
        endingPath
          ..relativeLineTo(
              params.endingSize.height, -params.endingSize.width / 2)
          ..relativeLineTo(0, params.endingSize.width)
          ..relativeLineTo(
              -params.endingSize.height, -params.endingSize.width / 2);
      default:
        final dX = to.dx - from.dx;
        final dY = to.dy - from.dy;
        if (dY.abs() > dX.abs()) {
          // vertical heading
          if (dY > 0) {
            // heading down
            endingPath
              ..relativeLineTo(-params.endingSize.width / 2, 0)
              ..relativeLineTo(
                  params.endingSize.width / 2, params.endingSize.height)
              ..relativeLineTo(
                  params.endingSize.width / 2, -params.endingSize.height);
          } else {
            // heading up
            endingPath
              ..relativeLineTo(-params.endingSize.width / 2, 0)
              ..relativeLineTo(
                  params.endingSize.width / 2, -params.endingSize.height)
              ..relativeLineTo(
                  params.endingSize.width / 2, params.endingSize.height);
          }
        } else {
          // horizontal headding
          if (dX > 0) {
            // heading right
            endingPath
              ..relativeLineTo(0, -params.endingSize.width / 2)
              ..relativeLineTo(
                params.endingSize.height,
                params.endingSize.width / 2,
              )
              ..relativeLineTo(
                -params.endingSize.height,
                params.endingSize.width / 2,
              );
          } else {
            // heading left
            endingPath
              ..relativeLineTo(0, -params.endingSize.width / 2)
              ..relativeLineTo(
                -params.endingSize.height,
                params.endingSize.width / 2,
              )
              ..relativeLineTo(
                params.endingSize.height,
                params.endingSize.width / 2,
              );
          }
        }
    }

    endingPath.close();
    canvas.drawPath(endingPath, endingPaint);
  }

  /// Draw a segmented line with a tension between points.
  void drawLine() {
    final points = [from];
    for (final pivot in pivots) {
      points.add(pivot.pivot);
    }
    points.add(to);

    path.moveTo(points.first.dx, points.first.dy);

    for (var i = 0; i < points.length - 1; i++) {
      final p0 = (i > 0) ? points[i - 1] : points[0];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = (i != points.length - 2) ? points[i + 2] : p2;

      final cp1x = p1.dx + (p2.dx - p0.dx) / 6 * params.tension;
      final cp1y = p1.dy + (p2.dy - p0.dy) / 6 * params.tension;

      final cp2x = p2.dx - (p3.dx - p1.dx) / 6 * params.tension;
      final cp2y = p2.dy - (p3.dy - p1.dy) / 6 * params.tension;

      path.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
    }
  }

  /// Draw a rectangular line
  void drawRectangularLine(Canvas canvas, Paint paint) {
    // calculating offsetted pivot
    Offset pivot0;
    Offset pivot1;
    Offset? pivot2;
    Offset? pivot3;
    Offset? pivot4;
    Offset? pivot5;
    var dragging = false;
    final end = calculateLineEndOffset(to);
    // from bottomcenter handler
    if (params.startArrowPosition.y == 1) {
      pivot0 = Offset(from.dx, from.dy + params.headRadius);
      pivot1 = Offset(pivot0.dx, pivot0.dy + params.tailLength);
      if (params.endArrowPosition.y == -1) {
        final dY = end.dy - pivot1.dy;
        if (dY > 0) {
          pivot2 = Offset(end.dx, pivot1.dy);
        } else {
          double x;
          if (end.dx > pivot1.dx) {
            x = end.dx - destElementSize.width / 2 - 10;
          } else {
            x = end.dx + destElementSize.width / 2 + 10;
          }
          pivot2 = Offset(x, pivot1.dy);
          pivot3 = Offset(pivot2.dx, pivot2.dy - params.tailLength + dY);
          pivot4 = Offset(end.dx, pivot3.dy);
        }
      } else if (params.endArrowPosition.y == 1) {
        if (pivot1.dy < end.dy) {
          double x;
          if (end.dx > pivot1.dx) {
            x = end.dx - destElementSize.width / 2 - 10;
          } else {
            x = end.dx + destElementSize.width / 2 + 10;
          }
          pivot2 = Offset(x, pivot1.dy);
          pivot3 = Offset(pivot2.dx, end.dy + params.tailLength);
          pivot4 = Offset(end.dx, pivot3.dy);
        } else {
          pivot2 = Offset(end.dx, pivot1.dy);
        }
      } else if (params.endArrowPosition.x == 1) {
        final dHY = end.dy - pivot1.dy - destElementSize.height / 2 - 10;
        if (dHY < 0) {
          if (dHY.abs() < destElementSize.height + 10 + params.headRadius) {
            if (end.dx > pivot1.dx) {
              pivot2 = Offset(to.dx - destElementSize.width - 10, pivot1.dy);
              pivot3 = Offset(pivot2.dx, pivot2.dy + dHY);
              pivot4 = Offset(end.dx + params.tailLength, pivot3.dy);
              pivot5 = Offset(pivot4.dx, end.dy);
            } else {
              pivot2 = Offset(end.dx + params.tailLength, pivot1.dy);
              pivot3 = Offset(pivot2.dx, end.dy);
            }
          } else {
            pivot2 = Offset(end.dx + params.tailLength, pivot1.dy);
            pivot3 = Offset(pivot2.dx, end.dy);
          }
        } else {
          pivot2 = Offset(end.dx + params.tailLength, pivot1.dy);
          pivot3 = pivot4 = Offset(pivot2.dx, end.dy);
        }
      } else if (params.endArrowPosition.x == -1) {
        if (to.dx < pivot1.dx) {
          if (end.dy - pivot1.dy > destElementSize.height / 2 + 10) {
            pivot2 = Offset(end.dx - params.tailLength, pivot1.dy);
            pivot3 = Offset(pivot2.dx, end.dy);
          } else {
            pivot2 = Offset(
                to.dx + destElementSize.width + params.tailLength, pivot1.dy);
            if (end.dy + destElementSize.height / 2 > pivot1.dy) {
              pivot3 =
                  Offset(pivot2.dx, end.dy - destElementSize.height / 2 - 10);
              pivot4 = Offset(end.dx - params.tailLength, pivot3.dy);
              pivot5 = Offset(pivot4.dx, end.dy);
            } else {
              pivot3 =
                  Offset(pivot2.dx, end.dy + destElementSize.height / 2 + 10);
              pivot4 = Offset(end.dx - params.tailLength, pivot3.dy);
              pivot5 = Offset(pivot4.dx, end.dy);
            }
          }
        } else {
          pivot2 = Offset(end.dx - params.tailLength, pivot1.dy);
          pivot3 = Offset(pivot2.dx, end.dy);
        }
      } else {
        dragging = true;
      }
    } else if (params.startArrowPosition.y == -1) {
      // from top center
      pivot0 = Offset(from.dx, from.dy - params.headRadius);
      pivot1 = Offset(pivot0.dx, pivot0.dy - params.tailLength);
      if (params.endArrowPosition.y == -1) {
        if (end.dy - params.tailLength > pivot1.dy) {
          pivot2 = Offset(end.dx, pivot1.dy);
        } else {
          pivot2 = Offset(pivot1.dx, end.dy - params.tailLength);
          pivot3 = Offset(end.dx, pivot2.dy);
        }
      } else if (params.endArrowPosition.y == 1) {
        if (pivot1.dy - params.tailLength > end.dy) {
          pivot2 = Offset(end.dx, pivot1.dy);
        } else {
          if (from.dx < to.dx) {
            pivot2 = Offset(end.dx - destElementSize.width / 2 - 10, pivot1.dy);
          } else {
            pivot2 = Offset(end.dx + destElementSize.width / 2 + 10, pivot1.dy);
          }
          pivot3 = Offset(pivot2.dx, end.dy + params.tailLength);
          pivot4 = Offset(end.dx, pivot3.dy);
        }
      } else if (params.endArrowPosition.x == 1) {
        if (pivot1.dy - destElementSize.height / 2 - 10 > end.dy) {
          pivot2 = Offset(end.dx + params.tailLength, pivot1.dy);
          pivot3 = Offset(pivot2.dx, end.dy);
        } else {
          if (from.dx < to.dx) {
            final tDy = end.dy - destElementSize.height / 2 - 10;
            pivot2 = Offset(pivot1.dx, tDy > pivot1.dy ? pivot1.dy : tDy);
            pivot3 = Offset(end.dx + params.tailLength, pivot2.dy);
            pivot4 = Offset(pivot3.dx, end.dy);
          } else {
            pivot2 = Offset(end.dx + params.tailLength, pivot1.dy);
            pivot3 = Offset(pivot2.dx, end.dy);
          }
        }
      } else if (params.endArrowPosition.x == -1) {
        final dHY = end.dy - pivot1.dy;
        if (dHY.abs() < destElementSize.height / 2 + 10 && to.dx < from.dx) {
          pivot2 = Offset(pivot1.dx, end.dy - 10 - destElementSize.height / 2);
          pivot3 = Offset(end.dx - params.tailLength, pivot2.dy);
          pivot4 = Offset(pivot3.dx, end.dy);
        } else {
          pivot2 = Offset(end.dx - params.tailLength, pivot1.dy);
          pivot3 = Offset(pivot2.dx, end.dy);
        }
      } else {
        dragging = true;
      }
    } else if (params.startArrowPosition.x == -1) {
      // from left center
      pivot0 = Offset(from.dx - params.headRadius, from.dy);
      pivot1 = Offset(pivot0.dx - params.tailLength, pivot0.dy);
      if (params.endArrowPosition.y == -1) {
        if (pivot1.dy > to.dy + destElementSize.height / 2) {
          if (pivot1.dx <
              end.dx + destElementSize.width / 2 + params.tailLength) {
            if (to.dx < from.dx + destElementSize.width / 2) {
              pivot2 = Offset(pivot1.dx,
                  to.dy + destElementSize.height + params.tailLength);
              pivot3 = Offset(
                  end.dx - destElementSize.width / 2 - params.tailLength,
                  pivot2.dy);
              pivot4 = Offset(pivot3.dx, end.dy - params.tailLength);
              pivot5 = Offset(end.dx, pivot4.dy);
            } else {
              pivot2 = Offset(pivot1.dx, end.dy - params.tailLength);
              pivot3 = Offset(end.dx, pivot2.dy);
            }
          } else {
            pivot2 = Offset(pivot1.dx, end.dy - params.tailLength);
            pivot3 = Offset(end.dx, pivot2.dy);
          }
        } else {
          if (end.dx < pivot1.dx) {
            if (pivot1.dy > end.dy - params.tailLength) {
              pivot2 = Offset(pivot1.dx, end.dy - params.tailLength);
              pivot3 = Offset(end.dx, pivot2.dy);
            } else {
              pivot2 = Offset(end.dx, pivot1.dy);
            }
          } else {
            if (pivot1.dy + destElementSize.height / 2 + params.tailLength <
                end.dy) {
              pivot2 = Offset(pivot1.dx, end.dy - params.tailLength);
              pivot3 = Offset(end.dx, pivot2.dy);
            } else {
              pivot2 = Offset(pivot1.dx,
                  pivot1.dy + destElementSize.height / 2 + params.tailLength);
              pivot3 = Offset(
                  end.dx - destElementSize.width / 2 - params.tailLength,
                  pivot2.dy);
              pivot4 = Offset(pivot3.dx, end.dy - params.tailLength);
              pivot5 = Offset(end.dx, pivot4.dy);
            }
          }
        }
      } else if (params.endArrowPosition.y == 1) {
        if (pivot1.dy - params.tailLength > end.dy) {
          if (end.dx < pivot1.dx) {
            pivot2 = Offset(end.dx, pivot1.dy);
          } else {
            if (end.dy + params.tailLength <
                from.dy - destElementSize.height / 2 - params.tailLength) {
              pivot2 = Offset(pivot1.dx, end.dy + params.tailLength);
              pivot3 = Offset(end.dx, pivot2.dy);
            } else {
              pivot2 = Offset(pivot1.dx,
                  pivot1.dy - destElementSize.height / 2 - params.tailLength);
              final tX = end.dx - destElementSize.width / 2 - params.tailLength;
              pivot3 = Offset(
                  tX < pivot2.dx ? pivot2.dx + params.thickness + 1 : tX,
                  pivot2.dy);
              pivot4 = Offset(pivot3.dx, end.dy + params.tailLength);
              pivot5 = Offset(end.dx, pivot4.dy);
            }
          }
        } else {
          if (end.dx + srcElementSize.width / 2 + params.tailLength <
              pivot1.dx) {
            pivot2 = Offset(pivot1.dx, end.dy + params.tailLength);
            pivot3 = Offset(end.dx, pivot2.dy);
          } else {
            final tX = to.dx - destElementSize.width / 2 - params.tailLength;
            var tY = pivot1.dy;
            if (tY > to.dy - srcElementSize.height - params.tailLength &&
                pivot1.dy < to.dy + params.tailLength) {
              if (pivot1.dx <
                  to.dx - destElementSize.width / 2 - params.tailLength) {
                tY = end.dy + params.tailLength;
                final tYSrc =
                    from.dy + destElementSize.height / 2 + params.tailLength;
                pivot2 = Offset(pivot1.dx, max(tY, tYSrc));
                pivot3 = Offset(end.dx, pivot2.dy);
              } else {
                tY = to.dy - srcElementSize.height - params.tailLength;
                pivot2 = Offset(pivot1.dx, tY);
                pivot3 = Offset(tX, pivot2.dy);
                pivot4 = Offset(pivot3.dx, end.dy + params.tailLength);
                pivot5 = Offset(end.dx, pivot4.dy);
              }
            } else {
              pivot2 = Offset(tX < pivot1.dx ? tX : pivot1.dx, tY);
              tY = end.dy + params.tailLength;
              final tYMin =
                  pivot1.dy + destElementSize.height / 2 + params.tailLength;
              pivot3 = Offset(pivot2.dx, tY > tYMin ? tY : tYMin);
              pivot4 = Offset(end.dx, pivot3.dy);
            }
          }
        }
      } else if (params.endArrowPosition.x == -1) {
        if (pivot1.dy <
            end.dy - destElementSize.height / 2 - params.tailLength) {
          if (to.dx > from.dx) {
            pivot2 = Offset(pivot1.dx, end.dy);
          } else {
            pivot2 = Offset(end.dx - params.tailLength, pivot1.dy);
            pivot3 = Offset(pivot2.dx, end.dy);
          }
        } else if (pivot1.dy <= end.dy) {
          if (from.dx > to.dx) {
            pivot2 = Offset(pivot1.dx,
                end.dy - destElementSize.height / 2 - params.tailLength);
            pivot3 = Offset(end.dx - params.tailLength, pivot2.dy);
            pivot4 = Offset(pivot3.dx, end.dy);
          } else {
            pivot2 = Offset(pivot1.dx,
                pivot1.dy - srcElementSize.height / 2 - params.tailLength);
            pivot3 = Offset(end.dx - params.tailLength, pivot2.dy);
            pivot4 = Offset(pivot3.dx, end.dy);
          }
        } else {
          if (pivot1.dy <
              end.dy + destElementSize.height / 2 + params.tailLength) {
            if (to.dx > from.dx) {
              pivot2 = Offset(pivot1.dx,
                  pivot1.dy - srcElementSize.height / 2 - params.tailLength);
              pivot3 = Offset(end.dx - params.tailLength, pivot2.dy);
              pivot4 = Offset(pivot3.dx, end.dy);
            } else {
              pivot2 = Offset(pivot1.dx,
                  end.dy + destElementSize.height / 2 + params.tailLength);
              pivot3 = Offset(end.dx - params.tailLength, pivot2.dy);
              pivot4 = Offset(pivot3.dx, end.dy);
            }
          } else {
            if (to.dx > from.dx) {
              pivot2 = Offset(pivot1.dx, end.dy);
            } else {
              pivot2 = Offset(end.dx - params.tailLength, pivot1.dy);
              pivot3 = Offset(pivot2.dx, end.dy);
            }
          }
        }
      } else if (params.endArrowPosition.x == 1) {
        if (pivot1.dy <
            end.dy - destElementSize.height / 2 - params.tailLength) {
          if (pivot1.dx > end.dx + params.tailLength) {
            pivot2 = Offset(end.dx + params.tailLength, pivot1.dy);
            pivot3 = Offset(pivot2.dx, end.dy);
          } else {
            pivot2 =
                Offset(pivot1.dx, end.dy - destElementSize.height / 2 - 10);
            pivot3 = Offset(end.dx + params.tailLength, pivot2.dy);
            pivot4 = Offset(pivot3.dx, end.dy);
          }
        } else if (pivot1.dy <= end.dy) {
          if (pivot1.dx > to.dx + params.tailLength * 2) {
            pivot2 = Offset(end.dx + params.tailLength, pivot1.dy);
            pivot3 = Offset(pivot2.dx, end.dy);
          } else {
            if (from.dx > to.dx) {
              pivot2 = Offset(pivot1.dx, pivot1.dy + 10);
              pivot3 = Offset(end.dx + params.tailLength, pivot2.dy);

              pivot4 = Offset(pivot3.dx, end.dy);
            } else {
              final dX = to.dx - params.tailLength - destElementSize.width;
              pivot2 = Offset(dX < pivot1.dx ? dX : pivot1.dx, pivot1.dy);
              pivot3 = Offset(pivot2.dx,
                  end.dy + params.tailLength + destElementSize.height / 2);
              pivot4 = Offset(end.dx + params.tailLength, pivot3.dy);
              pivot5 = Offset(pivot4.dx, end.dy);
            }
          }
        } else {
          if (from.dx > to.dx + params.tailLength * 2) {
            pivot2 = Offset(pivot1.dx, end.dy);
          } else {
            if (from.dx > to.dx) {
              pivot2 = Offset(pivot1.dx, pivot1.dy - 10);
              pivot3 = Offset(end.dx + params.tailLength, pivot2.dy);
              pivot4 = Offset(pivot3.dx, end.dy);
            } else {
              final tX = to.dx - destElementSize.width - params.tailLength;
              pivot2 = Offset(tX < pivot1.dx ? tX : pivot1.dx, pivot1.dy);
              pivot3 = Offset(pivot2.dx,
                  end.dy - destElementSize.height / 2 - params.tailLength);
              pivot4 = Offset(end.dx + params.tailLength, pivot3.dy);
              pivot5 = Offset(pivot4.dx, end.dy);
            }
          }
        }
      } else {
        dragging = true;
      }
    } else if (params.startArrowPosition.x == 1) {
      // from right center
      pivot0 = Offset(from.dx + params.headRadius, from.dy);
      pivot1 = Offset(pivot0.dx + params.tailLength, pivot0.dy);
      if (params.endArrowPosition.y == -1) {
        if (end.dy > pivot1.dy + params.tailLength) {
          if (end.dx > pivot1.dx) {
            pivot2 = Offset(end.dx, pivot1.dy);
          } else {
            pivot2 = Offset(pivot1.dx, pivot1.dy + 10);
            pivot3 = Offset(end.dx, pivot2.dy);
          }
        } else {
          if (to.dy + destElementSize.height < pivot1.dy &&
              to.dx - destElementSize.width / 2 < pivot1.dx &&
              pivot1.dx < to.dx + destElementSize.width / 2) {
            pivot2 = Offset(
                to.dx + destElementSize.width / 2 + params.tailLength,
                pivot1.dy);
            pivot3 = Offset(pivot2.dx, end.dy - params.tailLength);
            pivot4 = Offset(end.dx, pivot3.dy);
          } else {
            pivot2 = Offset(pivot1.dx, end.dy - params.tailLength);
            pivot3 = Offset(end.dx, pivot2.dy);
          }
        }
      } else if (params.endArrowPosition.y == 1) {
        if (pivot1.dy > end.dy + params.tailLength) {
          if (pivot1.dx < end.dx) {
            pivot2 = Offset(end.dx, pivot1.dy);
          } else {
            final dY = end.dy + params.tailLength;
            final tDY = from.dy - destElementSize.height / 2;
            if (dY > tDY &&
                end.dx + params.tailLength < from.dx - srcElementSize.width) {
              pivot2 = Offset(pivot1.dx, tDY - 10);
              pivot3 = Offset(end.dx + params.tailLength, pivot2.dy);
              pivot4 = Offset(pivot3.dx, end.dy + params.tailLength);
              pivot5 = Offset(end.dx, pivot4.dy);
            } else {
              pivot2 = Offset(pivot1.dx, dY);
              pivot3 = Offset(end.dx, pivot2.dy);
            }
          }
        } else {
          final dX = end.dx - destElementSize.width / 2 - 10;
          if (dX >= pivot1.dx) {
            pivot2 = Offset(dX, pivot1.dy);
            pivot3 = Offset(pivot2.dx, end.dy + params.tailLength);
            pivot4 = Offset(end.dx, pivot3.dy);
          } else {
            if (pivot1.dx > to.dx - destElementSize.width / 2 &&
                pivot1.dx < to.dx + destElementSize.width / 2) {
              pivot2 =
                  Offset(to.dx + destElementSize.width / 2 + 10, pivot1.dy);
              pivot3 = Offset(pivot2.dx, end.dy + params.tailLength);
              pivot4 = Offset(end.dx, pivot3.dy);
            } else {
              var dY = end.dy + params.tailLength;
              final tDY = from.dy + srcElementSize.height / 2 + 10;
              if (from.dx > to.dx + destElementSize.width / 2 && dY < tDY) {
                dY = tDY;
              }
              pivot2 = Offset(pivot1.dx, dY);
              pivot3 = Offset(end.dx, pivot2.dy);
            }
          }
        }
      } else if (params.endArrowPosition.x == -1) {
        if (end.dx > pivot1.dx + params.tailLength) {
          pivot2 = Offset(end.dx - params.tailLength, pivot1.dy);
          pivot3 = Offset(pivot2.dx, end.dy);
        } else {
          if (pivot1.dx < end.dx) {
            double dY;
            if (to.dy > from.dy) {
              final tDY = end.dy - 10;
              if (tDY > pivot1.dy) {
                dY = tDY;
              } else {
                dY = pivot1.dy + to.dy - from.dy;
              }
            } else {
              final tDY = end.dy + 10;
              if (tDY < pivot1.dy) {
                dY = tDY;
              } else {
                dY = pivot1.dy - (from.dy - to.dy);
              }
            }
            pivot2 = Offset(pivot1.dx, dY);
            pivot3 = Offset(end.dx - params.tailLength, pivot2.dy);
            pivot4 = Offset(pivot3.dx, end.dy);
          } else {
            double dY;
            if (end.dy > pivot1.dy) {
              final tDY = to.dy - destElementSize.height / 2 - 10;
              dY = tDY > pivot1.dy ? tDY : pivot1.dy;
            } else {
              final tDY = to.dy + destElementSize.height / 2 + 10;
              dY = tDY < pivot1.dy ? tDY : pivot1.dy;
            }
            pivot2 = Offset(pivot1.dx, dY);
            pivot3 = Offset(end.dx - params.tailLength, pivot2.dy);
            pivot4 = Offset(pivot3.dx, end.dy);
          }
        }
      } else if (params.endArrowPosition.x == 1) {
        if (to.dy + destElementSize.height / 2 + params.headRadius >
            pivot1.dy) {
          if (pivot1.dy < end.dy - destElementSize.height / 2 - 10) {
            if (to.dx > from.dx) {
              pivot2 = Offset(end.dx + params.tailLength, pivot1.dy);
              pivot3 = Offset(pivot2.dx, end.dy);
            } else {
              pivot2 = Offset(pivot1.dx, end.dy);
            }
          } else {
            if (to.dx > from.dx) {
              pivot2 = Offset(to.dx - destElementSize.width - 10, pivot1.dy);
              pivot3 =
                  Offset(pivot2.dx, to.dy - destElementSize.height / 2 - 10);
              pivot4 = Offset(end.dx + params.tailLength, pivot3.dy);
              pivot5 = Offset(pivot4.dx, end.dy);
            } else {
              final eDY =
                  from.dy + srcElementSize.height / 2 + params.headRadius + 10;
              if (end.dy > eDY) {
                pivot2 = Offset(pivot1.dx, end.dy);
              } else {
                pivot2 = Offset(pivot1.dx, eDY);
                pivot3 = Offset(end.dx + params.tailLength, pivot2.dy);
                pivot4 = Offset(pivot3.dx, end.dy);
              }
            }
          }
        } else {
          if (to.dx > from.dx) {
            pivot2 = Offset(end.dx + params.tailLength, pivot1.dy);
            pivot3 = Offset(pivot2.dx, end.dy);
          } else {
            pivot2 = Offset(pivot1.dx, end.dy);
          }
        }
      } else {
        dragging = true;
      }
    } else {
      // won't happend
      pivot0 = pivot1 = pivot2 = Offset(end.dx, end.dy);
    }

    if (dragging) {
      // dragging
      final dX = to.dx - from.dx;
      final dY = to.dy - from.dy;
      if (dY.abs() > dX.abs()) {
        // vertical heading
        pivot2 = Offset(end.dx, pivot1.dy);
      } else {
        // horizontal heading
        if (dX >= 0) {
          pivot2 = Offset(end.dx - params.tailLength, pivot1.dy);
          pivot3 = Offset(pivot2.dx, end.dy);
        } else {
          pivot2 = Offset(end.dx + params.tailLength, pivot1.dy);
          pivot3 = Offset(pivot2.dx, end.dy);
        }
      }
    }

    lines.addAll([
      [pivot0, pivot1],
    ]);
    path
      ..moveTo(pivot0.dx, pivot0.dy)
      ..lineTo(pivot1.dx, pivot1.dy);
    if (pivot2 != null) {
      path.lineTo(pivot2.dx, pivot2.dy);
      lines.add([pivot1, pivot2]);
    }
    if (pivot3 != null) {
      path.lineTo(pivot3.dx, pivot3.dy);
      lines.add([pivot2!, pivot3]);
    }
    if (pivot4 != null) {
      path.lineTo(pivot4.dx, pivot4.dy);
      lines.add([pivot3!, pivot4]);
    }
    if (pivot5 != null) {
      path.lineTo(pivot5.dx, pivot5.dy);
      lines.add([pivot4!, pivot5]);
    }
    path.lineTo(end.dx, end.dy);
  }

  /// Draws a curve starting/tail the handler linearly from the center
  /// of the element.
  void drawCurve(Canvas canvas, Paint paint) {
    var distance = 0.0;

    var dx = 0.0;
    var dy = 0.0;

    final p0 = Offset(from.dx, from.dy);
    final p4 = calculateLineEndOffset(to);

    distance = (p4 - p0).distance / 3;

    // checks for the arrow direction
    if (params.startArrowPosition.x > 0) {
      dx = distance;
    } else if (params.startArrowPosition.x < 0) {
      dx = -distance;
    }
    if (params.startArrowPosition.y > 0) {
      dy = distance;
    } else if (params.startArrowPosition.y < 0) {
      dy = -distance;
    }
    final p1 = Offset(from.dx + dx, from.dy + dy);
    dx = 0;
    dy = 0;

    // checks for the arrow direction
    if (params.endArrowPosition.x > 0) {
      dx = distance;
    } else if (params.endArrowPosition.x < 0) {
      dx = -distance;
    }
    if (params.endArrowPosition.y > 0) {
      dy = distance;
    } else if (params.endArrowPosition.y < 0) {
      dy = -distance;
    }
    final p3 = params.endArrowPosition == Alignment.center
        ? Offset(to.dx, to.dy)
        : Offset(to.dx + dx, to.dy + dy);
    final p2 = Offset(
      p1.dx + (p3.dx - p1.dx) / 2,
      p1.dy + (p3.dy - p1.dy) / 2,
    );

    path
      ..moveTo(p0.dx, p0.dy)
      ..conicTo(p1.dx, p1.dy, p2.dx, p2.dy, 1)
      ..conicTo(p3.dx, p3.dy, p4.dx, p4.dy, 1);
  }

  @override
  bool shouldRepaint(ArrowPainter oldDelegate) {
    return true;
  }

  @override
  bool? hitTest(Offset position) => false;
}

/// Notifier for pivot points.
class PivotsNotifier extends ValueNotifier<List<Pivot>> {
  ///
  PivotsNotifier(super.value) {
    for (final pivot in value) {
      pivot.addListener(notifyListeners);
    }
  }

  /// Add a pivot point.
  void add(Pivot pivot) {
    value.add(pivot);
    pivot.addListener(notifyListeners);
    notifyListeners();
  }

  /// Remove a pivot point.
  void remove(Pivot pivot) {
    value.remove(pivot);
    pivot.removeListener(notifyListeners);
    notifyListeners();
  }

  /// Insert a pivot point.
  void insert(int index, Pivot pivot) {
    value.insert(index, pivot);
    pivot.addListener(notifyListeners);
    notifyListeners();
  }

  /// Remove a pivot point by its index.
  void removeAt(int index) {
    value.removeAt(index).removeListener(notifyListeners);
    notifyListeners();
  }
}
