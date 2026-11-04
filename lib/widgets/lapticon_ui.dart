import 'package:flutter/material.dart';

//piezas visuales reutilizables

class LapticonColors {
  static const fondo1 = Color(0xFF0F172A);
  static const fondo2 = Color(0xFF1E1B4B);
  static const tarjeta = Color(0xFF1E293B);
  static const acento = Color(0xFF38BDF8);
  static const azul1 = Color(0xFF0284C7);
  static const azul2 = Color(0xFF2563EB);
  static const indigo = Color(0xFF4F46E5);
}

const BoxDecoration lapticonFondo = BoxDecoration(
  gradient: LinearGradient(
    colors: [LapticonColors.fondo1, LapticonColors.fondo2],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
);

InputDecoration lapticonInput(String label, IconData icon, {Widget? suffix}) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.white60),
    prefixIcon: Icon(icon, color: LapticonColors.acento),
    suffixIcon: suffix,
    filled: true,
    fillColor: LapticonColors.fondo1,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: LapticonColors.acento, width: 1.5),
    ),
  );
}

class LapticonCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const LapticonCard({super.key, required this.child, this.padding = const EdgeInsets.all(24)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: LapticonColors.tarjeta.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: child,
    );
  }
}

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  const GradientButton({super.key, required this.text, this.onPressed, this.loading = false, this.icon});

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null && !loading;
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [LapticonColors.azul1, LapticonColors.azul2]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: LapticonColors.azul1.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: loading
              ? const SizedBox(
              height: 24, width: 24,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, color: Colors.white, size: 20), const SizedBox(width: 8)],
              Text(text,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}
