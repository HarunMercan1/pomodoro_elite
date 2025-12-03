import 'package:flutter/material.dart';

class TimeOptionButton extends StatelessWidget {
  final String title;
  final int minutes;
  final VoidCallback onTap;
  final bool isSelected;
  final bool isLightMode;

  // YENİ PARAMETRELER: Rengi dışarıdan alıyoruz
  final Color? activeBackgroundColor;
  final Color? activeTextColor;

  const TimeOptionButton({
    super.key,
    required this.title,
    required this.minutes,
    required this.onTap,
    this.isSelected = false,
    this.isLightMode = false,
    this.activeBackgroundColor,
    this.activeTextColor,
  });

  @override
  Widget build(BuildContext context) {
    const Color darkNavy = Color(0xFF1A2980);

    Color textColor;
    Color borderColor;
    Color backgroundColor;

    if (isLightMode) {
      // --- AYDINLIK MOD (Boşta) ---
      backgroundColor = isSelected ? darkNavy : Colors.transparent;
      textColor = isSelected ? Colors.white : darkNavy.withOpacity(0.8);
      borderColor = isSelected ? Colors.transparent : darkNavy.withOpacity(0.2);
    } else {
      // --- GRADYANLI MODLAR (Çalışıyor/Durdu/Bitti) ---
      // Seçiliyse dışarıdan gelen rengi kullan (Yoksa beyaz yap)
      backgroundColor = isSelected
          ? (activeBackgroundColor ?? Colors.white)
          : Colors.white.withOpacity(0.15);

      // Yazı rengi de dışarıdan geliyor
      textColor = isSelected
          ? (activeTextColor ?? darkNavy)
          : Colors.white.withOpacity(0.9);

      borderColor = isSelected ? Colors.transparent : Colors.white.withOpacity(0.2);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: borderColor,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ]
              : [],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Text(
                "$minutes dk",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  color: textColor.withOpacity(0.8), // Opacity artırıldı
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}