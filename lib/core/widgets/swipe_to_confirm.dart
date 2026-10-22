import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class SwipeToConfirm extends StatefulWidget {
  final String text;
  final VoidCallback onConfirm;
  final Color trackColor;
  final Color thumbColor;

  const SwipeToConfirm({
    super.key,
    required this.text,
    required this.onConfirm,
    this.trackColor = AppColors.primary,
    this.thumbColor = Colors.white,
  });

  @override
  State<SwipeToConfirm> createState() => _SwipeToConfirmState();
}

class _SwipeToConfirmState extends State<SwipeToConfirm> {
  double _dragPosition = 0;
  bool _isConfirmed = false;
  final double _thumbSize = 56;
  double _maxWidth = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _maxWidth = constraints.maxWidth;
        return Container(
          height: 60,
          decoration: BoxDecoration(
            color: widget.trackColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: widget.trackColor.withValues(alpha: 0.3)),
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Center(
                child: Text(
                  _isConfirmed ? 'Done' : widget.text,
                  style: GoogleFonts.poppins(
                    color: widget.trackColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              Positioned(
                left: _dragPosition,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (_isConfirmed) return;
                    setState(() {
                      _dragPosition += details.delta.dx;
                      if (_dragPosition < 0) {
                        _dragPosition = 0;
                      } else if (_dragPosition > _maxWidth - _thumbSize - 4) {
                        _dragPosition = _maxWidth - _thumbSize - 4;
                        _isConfirmed = true;
                        widget.onConfirm();
                      }
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (!_isConfirmed) {
                      setState(() {
                        _dragPosition = 0;
                      });
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    width: _thumbSize,
                    height: _thumbSize,
                    decoration: BoxDecoration(
                      color: widget.trackColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.trackColor.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isConfirmed ? Icons.check : Icons.arrow_forward_ios,
                      color: widget.thumbColor,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
