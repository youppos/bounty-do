import 'package:flutter/material.dart';

class SwipeToReveal extends StatefulWidget {
  final Widget child;
  final Widget actionButton;
  final double actionWidth;

  const SwipeToReveal({
    Key? key,
    required this.child,
    required this.actionButton,
    this.actionWidth = 80.0,
  }) : super(key: key);

  @override
  _SwipeToRevealState createState() => _SwipeToRevealState();
}

class _SwipeToRevealState extends State<SwipeToReveal> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _dragExtent = 0.0;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _animation = Tween<double>(begin: 0, end: 0).animate(_controller);
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragExtent += details.primaryDelta!;
      if (_dragExtent > 0) _dragExtent = 0; // Don't allow swipe right
      if (_dragExtent < -widget.actionWidth * 1.5) {
        _dragExtent = -widget.actionWidth * 1.5; // Max drag
      }
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_dragExtent < -widget.actionWidth / 2 || details.primaryVelocity! < -300) {
      // Open
      _isOpen = true;
      _animation = Tween<double>(
        begin: _dragExtent,
        end: -widget.actionWidth,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    } else {
      // Close
      _isOpen = false;
      _animation = Tween<double>(
        begin: _dragExtent,
        end: 0,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    }
    
    _controller.forward(from: 0).then((_) {
      if (!_isOpen) {
        setState(() {
          _dragExtent = 0;
        });
      }
    });
  }

  void close() {
    if (!_isOpen) return;
    _isOpen = false;
    _animation = Tween<double>(
      begin: -widget.actionWidth,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward(from: 0).then((_) {
      setState(() {
        _dragExtent = 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final double currentOffset = _controller.isAnimating 
        ? _animation.value 
        : (_isOpen ? -widget.actionWidth : _dragExtent);

    return GestureDetector(
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Transform.translate(
            offset: Offset(currentOffset, 0),
            child: widget.child,
          ),
          Positioned(
            top: 0,
            bottom: 0,
            right: -widget.actionWidth,
            width: widget.actionWidth,
            child: Transform.translate(
              offset: Offset(currentOffset, 0),
              child: widget.actionButton,
            ),
          ),
        ],
      ),
    );
  }
}
