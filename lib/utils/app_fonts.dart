import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';

class AppFonts {
  static TextStyle poppins({
    BuildContext? context,
    TextStyle? textStyle,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    List<FontFeature>? fontFeatures,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
  }) {
    // Mevcut locale'i kontrol et
    // Not: Context yoksa, EasyLocalization.of(context) çalışmaz, bu yüzden genelde widget içinde context ile çağıracağız.
    // Ancak statik tanımlarda context olmayabilir. Bu durumda varsayılan locale eklenebilir veya parametre olarak geçilebilir.

    // Eğer parametre olarak locale gelmediyse, global bir context kontrolü zor.
    // Bu nedenle kullanımı: AppFonts.poppins(context: context, ...) şeklinde yapmak en güvenlisi.

    // Ancak mevcut kod yapısını çok bozmamak için şöyle bir yöntem izleyebiliriz:
    // BuildContext'i zorunlu kılmak en sağlıklısı.

    return _getFont(
      isBebas: false,
      context: context,
      textStyle: textStyle,
      color: color,
      backgroundColor: backgroundColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      textBaseline: textBaseline,
      height: height,
      locale: locale,
      foreground: foreground,
      background: background,
      shadows: shadows,
      fontFeatures: fontFeatures,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      decorationThickness: decorationThickness,
    );
  }

  static TextStyle bebasNeue({
    BuildContext? context,
    TextStyle? textStyle,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? height,
    Locale? locale,
  }) {
    return _getFont(
      isBebas: true,
      context: context,
      textStyle: textStyle,
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      height: height,
      locale: locale,
    );
  }

  // Yardımcı metod
  static TextStyle _getFont({
    required bool isBebas,
    BuildContext? context,
    TextStyle? textStyle,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    List<FontFeature>? fontFeatures,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
  }) {
    // 1. Yazı stilini oluştur
    TextStyle baseStyle = TextStyle(
      color: color,
      backgroundColor: backgroundColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      textBaseline: textBaseline,
      height: height,
      locale: locale,
      foreground: foreground,
      background: background,
      shadows: shadows,
      fontFeatures: fontFeatures,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      decorationThickness: decorationThickness,
    );

    // Eğer dışarıdan bir style geldiyse onunla birleştir
    if (textStyle != null) {
      baseStyle = textStyle.merge(baseStyle);
    }

    // 2. Locale kontrolü (Ukraynaca mı?)
    // Bu kısım biraz trick gerektiriyor. Eğer context yoksa, o anki locale'i bilemeyiz.
    // Ancak EasyLocalization.currentLocale veya Intl.getCurrentLocale() işe yarayabilir mi?
    // EasyLocalization context tree'de olduğu için context olmadan erişmek zor olabilir.
    // Çözüm: Parametre olarak 'context' istemek en garantisidir.
    // Fakat kodda çok fazla değişiklik gerektirebilir.
    // Alternatif: Global bir key veya statik bir değişken üzerinden locale'i takip etmek.

    // Şimdilik varsayılan davranış:
    // Eğer locale 'uk' ise GoogleFonts kullan.
    // Locale parametresi verilmediyse ne olacak?

    // ÇÖZÜM: main.dart içinde MaterialApp build edildiğinde EasyLocalization context'i oluşuyor.
    // Biz bu methodu widget build içinde çağıracağımız için `context.locale` parametresini
    // zorunlu tutarak ilerleyelim. Daha temiz olur.
    // Kullanım: AppFonts.poppins(context: context, ...)

    // 2. Locale kontrolü
    Locale? currentLocale = locale;

    // Eğer locale parametre olarak gelmediyse context üzerinden almaya çalış
    if (currentLocale == null && context != null) {
      currentLocale = context.locale;
    }

    // Ukraynaca kontrolü
    bool isUkrainian = currentLocale?.languageCode == 'uk';

    if (isUkrainian) {
      if (isBebas) {
        // Bebas Neue (Google Fonts) genelde sadece Latin destekler.
        // Bu yüzden Ukraynaca için ona en çok benzeyen ve Kiril destekleyen 'Oswald' kullanıyoruz.
        return GoogleFonts.oswald(
          textStyle: baseStyle,
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: letterSpacing,
          height: height,
        );
      } else {
        // Poppins (Google Fonts) genelde sadece Latin/Devanagari destekler.
        // Ukraynaca için Poppins'e en yakın geometrik sans-serif olan 'Montserrat' kullanıyoruz.
        return GoogleFonts.montserrat(
          textStyle: baseStyle,
          color: color,
          backgroundColor: backgroundColor,
          fontSize: fontSize,
          fontWeight: fontWeight,
          fontStyle: fontStyle,
          letterSpacing: letterSpacing,
          wordSpacing: wordSpacing,
          decoration: decoration,
          decorationColor: decorationColor,
          decorationStyle: decorationStyle,
          decorationThickness: decorationThickness,
        );
      }
    } else {
      // Diğer diller için yerel font
      return baseStyle.copyWith(
        fontFamily: isBebas ? 'BebasNeue' : 'Poppins',
      );
    }
  }
}
