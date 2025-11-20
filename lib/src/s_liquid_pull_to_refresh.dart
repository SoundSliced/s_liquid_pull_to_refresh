import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

// The over-scroll distance that moves the indicator to its maximum
// displacement, as a percentage of the scrollable's container extent.
const double _kDragContainerExtentPercentage = 0.25;

// How much the scroll's drag gesture can overshoot the LiquidPullToRefresh's
// displacement; max displacement = _kDragSizeFactorLimit * displacement.
const double _kDragSizeFactorLimit = 1.5;

// When the scroll ends, the duration of the progress indicator's animation
// to the LiquidPullToRefresh's displacement.
// const Duration _kIndicatorSnapDuration = Duration(milliseconds: 150);

// The duration of the ScaleTransitionIn of box that starts when the
// refresh action has completed.
const Duration _kIndicatorScaleDuration = Duration(milliseconds: 200);

/// The signature for a function that's called when the user has dragged a
/// [SLiquidPullToRefresh] far enough to demonstrate that they want the app to
/// refresh. The returned [Future] must complete when the refresh operation is
/// finished.
///
/// Used by [SLiquidPullToRefresh.onRefresh].
typedef SRefreshCallback = Future<void> Function();

// The state machine moves through these modes only when the scrollable
// identified by scrollableKey has been scrolled to its min or max limit.
enum _SLiquidPullToRefreshMode {
  drag, // Pointer is down.
  armed, // Dragged far enough that an up event will run the onRefresh callback.
  snap, // Animating to the indicator's final "displacement".
  refresh, // Running the refresh callback.
  done, // Animating the indicator's fade-out after refreshing.
  canceled, // Animating the indicator's fade-out after not arming.
}

class SLiquidPullToRefresh extends StatefulWidget {
  const SLiquidPullToRefresh({
    super.key,
    this.animSpeedFactor = 1.0,
    required this.child,
    required this.onRefresh,
    this.color,
    this.backgroundColor,
    this.height,
    this.springAnimationDurationInMilliseconds = 1000,
    this.borderWidth = 2.0,
    this.showChildOpacityTransition = true,
  }) : assert(animSpeedFactor >= 1.0);

  /// The widget below this widget in the tree.
  ///
  /// The progress indicator will be stacked on top of this child. The indicator
  /// will appear when child's Scrollable descendant is over-scrolled.
  ///
  /// Typically a [ListView] or [CustomScrollView].
  final Widget child;

  /// The distance from the child's top or bottom edge to where the box
  /// will settle after the spring effect.
  ///
  /// default is set to 100.0
  final double? height;

  /// Duration in milliseconds of springy effect that occurs when
  /// we leave dragging after full drag.
  ///
  /// default to 1000
  final int springAnimationDurationInMilliseconds;

  /// To regulate the "speed of the animation" towards the end.
  /// To hasten it give a value > 1.0 and vice versa.
  ///
  /// default to 1.0
  final double animSpeedFactor;

  /// Border width of progressing circle in Progressing Indicator
  ///
  /// default to 2.0
  final double borderWidth;

  /// Whether to show child opacity transition or not.
  ///
  /// default to true
  final bool showChildOpacityTransition;

  /// A function that's called when the user has dragged the progress indicator
  /// far enough to demonstrate that they want the app to refresh. The returned
  /// [Future] must complete when the refresh operation is finished.
  final SRefreshCallback onRefresh;

  /// The progress indicator's foreground color. The current theme's
  /// [Theme.of(context).colorScheme.secondary] by default.
  final Color? color;

  /// The progress indicator's background color. The current theme's
  /// [ThemeData.canvasColor] by default.
  final Color? backgroundColor;

  @override
  SLiquidPullToRefreshState createState() => SLiquidPullToRefreshState();
}

class SLiquidPullToRefreshState extends State<SLiquidPullToRefresh> {
  // Direct value storage instead of AnimationControllers
  double _springValue = 0.0;
  double _progressingRotateValue = 0.0;
  double _progressingPercentValue = 0.25;
  double _progressingStartAngleValue = -2.0 / 3.0;
  double _ringRadiusValue = 1.0;
  double _ringOpacityValue = 1.0;
  double _peakHeightUpValue = 0.0;
  double _peakHeightDownValue = 1.0;
  double _indicatorTranslateWithPeakValue = 0.0;
  double _indicatorRadiusWithPeakValue = 0.0;
  double _indicatorTranslateValue = 0.0;
  double _radiusValue = 1.0;
  double _positionValue = 0.0;
  Color? _valueColorValue;
  Timer? _progressingTimer;

  _SLiquidPullToRefreshMode? _mode;
  Future<void>? _pendingRefreshFuture;
  bool? _isIndicatorAtTop;
  double? _dragOffset;

  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    // Values initialized in field declarations
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateValueColor();
  }

  void _updateValueColor() {
    final ThemeData theme = Theme.of(context);
    final baseColor = widget.color ?? theme.colorScheme.secondary;
    final t = (_positionValue / (1.0 / _kDragSizeFactorLimit)).clamp(0.0, 1.0);
    _valueColorValue = Color.lerp(
      baseColor.withValues(alpha: 0.0),
      baseColor.withValues(alpha: 1.0),
      t,
    );
  }

  // Track all active animation cancelers
  final Set<VoidCallback> _activeAnimationCancelers = <VoidCallback>{};

  Future<void> _animateValue({
    required double Function() getCurrentValue,
    required void Function(double) setValue,
    required double targetValue,
    required Duration duration,
    Curve curve = Curves.linear,
  }) async {
    final startValue = getCurrentValue();
    final startTime = DateTime.now();
    bool cancelled = false;
    void cancel() => cancelled = true;
    _activeAnimationCancelers.add(cancel);
    try {
      while (!cancelled &&
          !_disposed &&
          mounted &&
          DateTime.now().difference(startTime) < duration) {
        final elapsed = DateTime.now().difference(startTime).inMilliseconds;
        final t = (elapsed / duration.inMilliseconds).clamp(0.0, 1.0);
        final curvedT = curve.transform(t);
        final value = startValue + (targetValue - startValue) * curvedT;
        if (cancelled || _disposed) break;
        if (mounted) setState(() => setValue(value));
        await Future.delayed(const Duration(milliseconds: 16)); // ~60fps
      }
      if (!cancelled && !_disposed && mounted) {
        setState(() => setValue(targetValue));
      }
    } finally {
      _activeAnimationCancelers.remove(cancel);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _progressingTimer?.cancel();
    _progressingTimer = null;
    super.dispose();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification &&
        notification.metrics.extentBefore == 0.0 &&
        _mode == null &&
        _start(notification.metrics.axisDirection)) {
      setState(() {
        _mode = _SLiquidPullToRefreshMode.drag;
      });
      return false;
    }
    bool? indicatorAtTopNow;
    switch (notification.metrics.axisDirection) {
      case AxisDirection.down:
        indicatorAtTopNow = true;
        break;
      case AxisDirection.up:
        indicatorAtTopNow = false;
        break;
      case AxisDirection.left:
      case AxisDirection.right:
        indicatorAtTopNow = null;
        break;
    }
    if (indicatorAtTopNow != _isIndicatorAtTop) {
      if (_mode == _SLiquidPullToRefreshMode.drag ||
          _mode == _SLiquidPullToRefreshMode.armed) {
        _dismiss(_SLiquidPullToRefreshMode.canceled);
      }
    } else if (notification is ScrollUpdateNotification) {
      if (_mode == _SLiquidPullToRefreshMode.drag ||
          _mode == _SLiquidPullToRefreshMode.armed) {
        if (notification.metrics.extentBefore > 0.0) {
          _dismiss(_SLiquidPullToRefreshMode.canceled);
        } else {
          if (_dragOffset != null) {
            _dragOffset = _dragOffset! - notification.scrollDelta!;
          }
          _checkDragOffset(notification.metrics.viewportDimension);
        }
      }
      if (_mode == _SLiquidPullToRefreshMode.armed &&
          notification.dragDetails == null) {
        // On iOS start the refresh when the Scrollable bounces back from the
        // OverScroll (ScrollNotification indicating this don't have dragDetails
        // because the scroll activity is not directly triggered by a drag).
        _show();
      }
    } else if (notification is OverscrollNotification) {
      if (_mode == _SLiquidPullToRefreshMode.drag ||
          _mode == _SLiquidPullToRefreshMode.armed) {
        if (_dragOffset != null) {
          _dragOffset = _dragOffset! - notification.overscroll / 2.0;
        }
        _checkDragOffset(notification.metrics.viewportDimension);
      }
    } else if (notification is ScrollEndNotification) {
      switch (_mode) {
        case _SLiquidPullToRefreshMode.armed:
          _show();
          break;
        case _SLiquidPullToRefreshMode.drag:
          _dismiss(_SLiquidPullToRefreshMode.canceled);
          break;
        default:
          // do nothing
          break;
      }
    }
    return false;
  }

  bool _handleGlowNotification(OverscrollIndicatorNotification notification) {
    if (notification.depth != 0 || !notification.leading) return false;
    if (_mode == _SLiquidPullToRefreshMode.drag) {
      notification.disallowIndicator();
      return true;
    }
    return false;
  }

  // Stop showing the progress indicator.
  Future<void> _dismiss(_SLiquidPullToRefreshMode newMode) async {
    await Future<void>.value();
    // This can only be called from _show() when refreshing and
    // _handleScrollNotification in response to a ScrollEndNotification or
    // direction change.
    assert(newMode == _SLiquidPullToRefreshMode.canceled ||
        newMode == _SLiquidPullToRefreshMode.done);
    setState(() {
      _mode = newMode;
    });
    // Cancel all running animations
    for (final cancel in _activeAnimationCancelers.toList()) {
      cancel();
    }
    _activeAnimationCancelers.clear();
    _disposed = true;
    switch (_mode) {
      case _SLiquidPullToRefreshMode.done:
        //stop progressing animation
        if (_progressingTimer != null) {
          _progressingTimer!.cancel();
          _progressingTimer = null;
        }

        final animDuration = Duration(
            milliseconds: (widget.springAnimationDurationInMilliseconds /
                    widget.animSpeedFactor)
                .round());
        final shortDuration = Duration(
            milliseconds: (widget.springAnimationDurationInMilliseconds /
                    (widget.animSpeedFactor * 5))
                .round());

        // Start parallel animations
        final futures = <Future>[
          // progress ring disappear animation
          _animateValue(
            getCurrentValue: () => _ringOpacityValue,
            setValue: (v) => _ringOpacityValue = v,
            targetValue: 0.0,
            duration: animDuration,
          ),
          // indicator translate out
          _animateValue(
            getCurrentValue: () => _indicatorTranslateWithPeakValue,
            setValue: (v) => _indicatorTranslateWithPeakValue = v,
            targetValue: 0.0,
            duration: animDuration,
          ),
          _animateValue(
            getCurrentValue: () => _indicatorTranslateValue,
            setValue: (v) => _indicatorTranslateValue = v,
            targetValue: 0.0,
            duration: animDuration,
          ),
        ];

        // Wait for parallel animations, then do peak animation
        await Future.wait(futures);

        await _animateValue(
          getCurrentValue: () => _peakHeightDownValue,
          setValue: (v) => _peakHeightDownValue = v,
          targetValue: 0.3,
          duration: animDuration,
        );

        _animateValue(
          getCurrentValue: () => _radiusValue,
          setValue: (v) => _radiusValue = v,
          targetValue: 0.0,
          duration: shortDuration,
        );

        setState(() => _peakHeightDownValue = 0.175);
        await _animateValue(
          getCurrentValue: () => _peakHeightDownValue,
          setValue: (v) => _peakHeightDownValue = v,
          targetValue: 0.1,
          duration: shortDuration,
          curve: Curves.easeOut,
        );
        setState(() => _peakHeightDownValue = 0.0);

        await _animateValue(
          getCurrentValue: () => _positionValue,
          setValue: (v) => _positionValue = v,
          targetValue: 0.0,
          duration: animDuration,
        );
        break;

      case _SLiquidPullToRefreshMode.canceled:
        await _animateValue(
          getCurrentValue: () => _positionValue,
          setValue: (v) => _positionValue = v,
          targetValue: 0.0,
          duration: _kIndicatorScaleDuration,
        );
        break;
      default:
        assert(false);
    }
    // Reset _disposed to false for next use unless widget is disposed
    if (mounted && _mode == newMode) {
      _dragOffset = null;
      _isIndicatorAtTop = null;
      setState(() {
        _mode = null;
      });
      _disposed = false;
    }
  }

  bool _start(AxisDirection direction) {
    assert(_mode == null);
    assert(_isIndicatorAtTop == null);
    assert(_dragOffset == null);
    switch (direction) {
      case AxisDirection.down:
        _isIndicatorAtTop = true;
        break;
      case AxisDirection.up:
        _isIndicatorAtTop = false;
        break;
      case AxisDirection.left:
      case AxisDirection.right:
        _isIndicatorAtTop = null;
        // we do not support horizontal scroll views.
        return false;
    }
    setState(() {
      _dragOffset = 0.0;
      _positionValue = 0.0;
      _springValue = 0.0;
      _progressingRotateValue = 0.0;
      _progressingPercentValue = 0.25;
      _progressingStartAngleValue = -2.0 / 3.0;
      _ringOpacityValue = 1.0;
      _ringRadiusValue = 1.0;
      _peakHeightUpValue = 0.0;
      _peakHeightDownValue = 1.0;
      _indicatorTranslateWithPeakValue = 0.0;
      _indicatorRadiusWithPeakValue = 0.0;
      _indicatorTranslateValue = 0.0;
      _radiusValue = 1.0;
    });
    return true;
  }

  void _checkDragOffset(double containerExtent) {
    assert(_mode == _SLiquidPullToRefreshMode.drag ||
        _mode == _SLiquidPullToRefreshMode.armed);
    double newValue =
        _dragOffset! / (containerExtent * _kDragContainerExtentPercentage);
    if (_mode == _SLiquidPullToRefreshMode.armed) {
      newValue = math.max(newValue, 1.0 / _kDragSizeFactorLimit);
    }
    setState(() {
      _positionValue = newValue.clamp(0.0, 1.0);
      _updateValueColor();
    });
    if (_mode == _SLiquidPullToRefreshMode.drag &&
        _valueColorValue != null &&
        (_valueColorValue!.a * 255.0).round().clamp(0, 255) == 255) {
      _mode = _SLiquidPullToRefreshMode.armed;
    }
  }

  void _show() async {
    assert(_mode != _SLiquidPullToRefreshMode.refresh);
    assert(_mode != _SLiquidPullToRefreshMode.snap);
    final Completer<void> completer = Completer<void>();
    _pendingRefreshFuture = completer.future;
    _mode = _SLiquidPullToRefreshMode.snap;

    final animDuration =
        Duration(milliseconds: widget.springAnimationDurationInMilliseconds);

    // Cancel any existing timer before starting a new one
    _progressingTimer?.cancel();
    _progressingTimer = null;
    if (_disposed) return;

    // Kick off animations (do not await yet)
    final animationFutures = <Future>[
      _animateValue(
        getCurrentValue: () => _positionValue,
        setValue: (v) => _positionValue = v,
        targetValue: 1.0 / _kDragSizeFactorLimit,
        duration: animDuration,
      ),
      _animateValue(
        getCurrentValue: () => _peakHeightUpValue,
        setValue: (v) => _peakHeightUpValue = v,
        targetValue: 1.0,
        duration: animDuration,
      ),
      _animateValue(
        getCurrentValue: () => _indicatorTranslateWithPeakValue,
        setValue: (v) => _indicatorTranslateWithPeakValue = v,
        targetValue: 1.0,
        duration: animDuration,
      ),
      _animateValue(
        getCurrentValue: () => _indicatorTranslateValue,
        setValue: (v) => _indicatorTranslateValue = v,
        targetValue: 1.0,
        duration: animDuration,
      ),
      _animateValue(
        getCurrentValue: () => _ringOpacityValue,
        setValue: (v) => _ringOpacityValue = v,
        targetValue: 1.0,
        duration: animDuration,
      ),
    ];

    // Enter refresh mode immediately so tests and callers see the state change
    if (mounted && _mode == _SLiquidPullToRefreshMode.snap) {
      setState(() {
        _mode = _SLiquidPullToRefreshMode.refresh;
      });

      // Start progress ring timer
      _progressingTimer =
          Timer.periodic(const Duration(milliseconds: 16), (timer) {
        if (_disposed ||
            !mounted ||
            _mode != _SLiquidPullToRefreshMode.refresh) {
          timer.cancel();
          _progressingTimer = null;
          return;
        }
        setState(() {
          final now = DateTime.now().millisecondsSinceEpoch;
          final t = (now % 1000) / 1000.0;
          _progressingRotateValue = t;
          final percent = t <= 0.5 ? 2 * t : 2 * (1 - t);
          _progressingPercentValue = 0.25 + (percent * (5 / 6 - 0.25));
          _progressingStartAngleValue =
              t >= 0.5 ? -2 / 3 + ((t - 0.5) * 2 * (1 / 2 - (-2 / 3))) : -2 / 3;
        });
      });

      // Invoke refresh callback immediately
      final Future<void> refreshResult = widget.onRefresh();
      refreshResult.whenComplete(() {
        if (!_disposed &&
            mounted &&
            _mode == _SLiquidPullToRefreshMode.refresh) {
          completer.complete();
          _dismiss(_SLiquidPullToRefreshMode.done);
        }
      });
    }

    // Allow initial animations to finish (non-blocking for refresh completion)
    await Future.wait(animationFutures);

    // Decorative spring animation (skip if already dismissed)
    if (!_disposed && mounted && _mode == _SLiquidPullToRefreshMode.refresh) {
      await _animateValue(
        getCurrentValue: () => _springValue,
        setValue: (v) => _springValue = v,
        targetValue: 0.5,
        duration: animDuration,
        curve: Curves.elasticOut,
      );
    }
  }

  /// Show the progress indicator and run the refresh callback as if it had
  /// been started interactively. If this method is called while the refresh
  /// callback is running, it quietly does nothing.
  ///
  /// Creating the [SLiquidPullToRefresh] with a [GlobalKey<LiquidPullToRefreshState>]
  /// makes it possible to refer to the [SLiquidPullToRefreshState].
  ///
  /// The future returned from this method completes when the
  /// [SLiquidPullToRefresh.onRefresh] callback's future completes.
  ///
  /// If you await the future returned by this function from a [State], you
  /// should check that the state is still [mounted] before calling [setState].
  ///
  /// When initiated in this manner, the progress indicator is independent of any
  /// actual scroll view. It defaults to showing the indicator at the top. To
  /// show it at the bottom, set `atTop` to false.
  Future<void>? show({bool atTop = true}) {
    if (_mode != _SLiquidPullToRefreshMode.refresh &&
        _mode != _SLiquidPullToRefreshMode.snap) {
      if (_mode == null) _start(atTop ? AxisDirection.down : AxisDirection.up);
      _show();
    }
    return _pendingRefreshFuture;
  }

  final GlobalKey _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterialLocalizations(context));

    // assigning default color and background color
    Color defaultColor = Theme.of(context).colorScheme.secondary;
    Color defaultBackgroundColor = Theme.of(context).canvasColor;

    // assigning default height
    double defaultHeight = 100.0;

    // checking whether to take default values or not
    Color color = (widget.color != null) ? widget.color! : defaultColor;
    Color backgroundColor = (widget.backgroundColor != null)
        ? widget.backgroundColor!
        : defaultBackgroundColor;
    double height = (widget.height != null) ? widget.height! : defaultHeight;

    final Widget child = NotificationListener<ScrollNotification>(
      key: _key,
      onNotification: _handleScrollNotification,
      child: NotificationListener<OverscrollIndicatorNotification>(
          onNotification: _handleGlowNotification, child: widget.child),
    );

    if (_mode == null) {
      assert(_dragOffset == null);
      assert(_isIndicatorAtTop == null);
      return child;
    }
    assert(_dragOffset != null);
    assert(_isIndicatorAtTop != null);

    return Stack(
      children: <Widget>[
        widget.showChildOpacityTransition
            ? Opacity(
                // -0.01 is done for elasticOut curve
                opacity: (_positionValue - (1 / 3) - 0.01).clamp(0.0, 1.0),
                child: child,
              )
            : Transform.translate(
                offset: Offset(0.0, _positionValue),
                child: child,
              ),
        ClipPath(
          clipper: SCurveHillClipper(
            centreHeight: height,
            curveHeight: height / 2 * _springValue, // 50.0
            peakHeight: height *
                3 /
                10 *
                ((_peakHeightUpValue != 1.0) //30.0
                    ? _peakHeightUpValue
                    : _peakHeightDownValue),
            peakWidth:
                (_peakHeightUpValue != 0.0 && _peakHeightDownValue != 0.0)
                    ? height * 35 / 100 //35.0
                    : 0.0,
          ),
          child: Container(
            height: _positionValue * height * 2, // 100.0
            color: color,
          ),
        ),
        SizedBox(
          // color: Colors.purple,
          height: height, //100.0
          child: Align(
            alignment: Alignment(
              0.0,
              (1.0 -
                  (0.36 * _indicatorTranslateWithPeakValue) -
                  (0.64 * _indicatorTranslateValue)),
            ),
            child: Transform(
              transform: Matrix4.identity()
                ..rotateZ(_progressingRotateValue * 5 * math.pi / 6),
              alignment: FractionalOffset.center,
              child: _SCircularProgress(
                backgroundColor: backgroundColor,
                progressCircleOpacity: _ringOpacityValue,
                innerCircleRadius: height *
                    15 /
                    100 * // 15.0
                    ((_mode != _SLiquidPullToRefreshMode.done)
                        ? _indicatorRadiusWithPeakValue
                        : _radiusValue),
                progressCircleBorderWidth: widget.borderWidth,
                //2.0
                progressCircleRadius: (_ringOpacityValue != 0.0)
                    ? (height * 2 / 10) * _ringRadiusValue //20.0
                    : 0.0,
                startAngle: _progressingStartAngleValue * math.pi,
                progressPercent: _progressingPercentValue,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class SProgressRingCurve extends Curve {
  @override
  double transform(double t) {
    if (t <= 0.5) {
      return 2 * t;
    } else {
      return 2 * (1 - t);
    }
  }
}

//******************************************************* */

/// Progress Indicator for [SLiquidPullToRefresh]
class _SCircularProgress extends StatefulWidget {
  final double innerCircleRadius;
  final double progressPercent;
  final double progressCircleOpacity;
  final double progressCircleRadius;
  final double progressCircleBorderWidth;
  final Color backgroundColor;
  final double startAngle;

  const _SCircularProgress({
    // ignore: unused_element_parameter
    super.key,
    required this.innerCircleRadius,
    required this.progressPercent,
    required this.progressCircleRadius,
    required this.progressCircleBorderWidth,
    required this.backgroundColor,
    required this.progressCircleOpacity,
    required this.startAngle,
  });

  @override
  _SCircularProgressState createState() => _SCircularProgressState();
}

class _SCircularProgressState extends State<_SCircularProgress> {
  @override
  Widget build(BuildContext context) {
    double containerLength =
        2 * math.max(widget.progressCircleRadius, widget.innerCircleRadius);

    return SizedBox(
      //  color: Colors.purple,
      height: containerLength,
      width: containerLength,
      child: Stack(
        children: <Widget>[
          Opacity(
            opacity: widget.progressCircleOpacity,
            child: SizedBox(
              height: widget.progressCircleRadius * 2,
              width: widget.progressCircleRadius * 2,
              child: CustomPaint(
                painter: SRingPainter(
                  startAngle: widget.startAngle,
                  paintWidth: widget.progressCircleBorderWidth,
                  progressPercent: widget.progressPercent,
                  trackColor: widget.backgroundColor,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Container(
              width: widget.innerCircleRadius * 2,
              height: widget.innerCircleRadius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.backgroundColor,
              ),
            ),
          )
        ],
      ),
    );
  }
}

class SRingPainter extends CustomPainter {
  final double paintWidth;
  final Paint trackPaint;
  final Color trackColor;
  final double progressPercent;
  final double startAngle;

  SRingPainter({
    required this.startAngle,
    required this.paintWidth,
    required this.progressPercent,
    required this.trackColor,
  }) : trackPaint = Paint()
          ..color = trackColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = paintWidth
          ..strokeCap = StrokeCap.square;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - paintWidth) / 2;

    final progressAngle = 2 * math.pi * progressPercent;

    canvas.drawArc(
        Rect.fromCircle(
          center: center,
          radius: radius,
        ),
        startAngle,
        progressAngle,
        false,
        trackPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

//********************************************************** */

/// Clipper for [SLiquidPullToRefresh]
class SCurveHillClipper extends CustomClipper<Path> {
  final double centreHeight;
  double curveHeight;
  final double peakHeight;
  final double peakWidth;

  SCurveHillClipper({
    required this.centreHeight,
    required this.curveHeight,
    required this.peakHeight,
    required this.peakWidth,
  });

  @override
  Path getClip(Size size) {
    var path = Path();
    if (size.height >= centreHeight) {
      if (curveHeight > (size.height - centreHeight)) {
        curveHeight = size.height - centreHeight;
      }

      path.lineTo(0.0, centreHeight);

      path.quadraticBezierTo(size.width / 4, centreHeight + curveHeight,
          (size.width / 2) - (peakWidth / 2), centreHeight + curveHeight);

      path.quadraticBezierTo(
          (size.width / 2) - (peakWidth / 4),
          centreHeight + curveHeight - peakHeight,
          (size.width / 2),
          centreHeight + curveHeight - peakHeight);

      path.quadraticBezierTo(
          (size.width / 2) + (peakWidth / 4),
          centreHeight + curveHeight - peakHeight,
          (size.width / 2) + (peakWidth / 2),
          centreHeight + curveHeight);

      path.quadraticBezierTo(size.width * 3 / 4, centreHeight + curveHeight,
          size.width, centreHeight);

      path.lineTo(size.width, 0.0);

      path.lineTo(0.0, 0.0);
    } else {
      path.lineTo(0.0, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, 0.0);
      path.lineTo(0.0, 0.0);
    }

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}
