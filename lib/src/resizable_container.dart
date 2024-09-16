import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_resizable_container/src/extensions/box_constraints_ext.dart';
import 'package:flutter_resizable_container/src/resizable_container_divider.dart';
import 'package:flutter_resizable_container/src/resizable_controller.dart';

/// A container that holds multiple child [Widget]s that can be resized.
///
/// Dividing lines will be added between each child. Dragging the dividers
/// will resize the children along the [direction] axis.
class ResizableContainer extends StatefulWidget {
  /// Creates a new [ResizableContainer] with the given [direction] and list
  /// of [children] Widgets.
  ///
  /// The sum of the [children]'s starting ratios must be equal to 1.0.
  const ResizableContainer({
    super.key,
    required this.direction,
    required this.manager,
    required ResizableDivider? divider,
    required this.maxDuration,
  }) : divider = divider ?? const ResizableDivider();

  /// The controller that will be used to manage programmatic resizing of the children.
  final ResizableControllerManager manager;

  /// The direction along which the child widgets will be laid and resized.
  final Axis direction;

  /// Configuration values for the dividing space/line between this container's [children].
  final ResizableDivider divider;

  final double maxDuration;

  @override
  State<ResizableContainer> createState() => _ResizableContainerState();
}

class _ResizableContainerState extends State<ResizableContainer> {
  double getDurationInSeconds(int index) {
    final ratios = widget.manager.controller.ratios;

    if (ratios.isEmpty || index >= ratios.length) {
      return 0;
    }

    final totalDuration = widget.maxDuration;
    final duration = totalDuration * ratios[index];
    return duration;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableSpace = _getAvailableSpace(constraints);
        widget.manager.setAvailableSpace(availableSpace);

        return AnimatedBuilder(
          animation: widget.manager.controller,
          builder: (context, _) {
            return Flex(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              direction: widget.direction,
              children: [
                for (var i = 0; i < widget.manager.children().length; i++) ...[
                  // build the child
                  Builder(
                    builder: (context) {
                      final height = _getChildSize(
                        index: i,
                        direction: Axis.vertical,
                        constraints: constraints,
                      );

                      final width = _getChildSize(
                        index: i,
                        direction: Axis.horizontal,
                        constraints: constraints,
                      );

                      return SizedBox(
                        height: height,
                        width: width,
                        child: Stack(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                    child: widget.manager.children()[i].child),
                                if (i <
                                    widget.manager.children().length - 1) ...[
                                  ResizableContainerDivider(
                                    config: widget.divider,
                                    direction: widget.direction,
                                    onResizeUpdate: (delta) =>
                                        widget.manager.adjustChildSize(
                                      index: i,
                                      delta: delta,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Center(
                              child: Text(
                                getDurationInSeconds(i).toStringAsFixed(2),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                ),
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  double _getAvailableSpace(BoxConstraints constraints) {
    final totalSpace = constraints.maxForDirection(widget.direction);
    final numDividers = widget.manager.children().length - 1;
    final dividerSpace = numDividers * widget.divider.thickness +
        numDividers * widget.divider.padding;
    return totalSpace;
  }

  double _getChildSize({
    required int index,
    required Axis direction,
    required BoxConstraints constraints,
  }) {
    return direction != direction
        ? constraints.maxForDirection(direction)
        : widget.manager.controller.sizes[index];
  }
}
