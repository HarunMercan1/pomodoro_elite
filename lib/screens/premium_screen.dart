import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../providers/purchase_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/app_fonts.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final purchaseProvider = context.watch<PurchaseProvider>();
    final isPremium = purchaseProvider.isPremium;
    final isLoading = purchaseProvider.isLoading;
    final offerings = purchaseProvider.offerings;

    // Arama yap: Premium paket ve Tip paketleri
    Package? premiumPackage;
    List<Package> tipPackages = [];
    
    if (offerings != null && offerings.current != null) {
      final currentOffering = offerings.current!;
      for (var package in currentOffering.availablePackages) {
        final pkgId = package.identifier.toLowerCase();
        final productId = package.storeProduct.identifier.toLowerCase();
        
        if (pkgId.contains('premium') || pkgId == '\$rc_lifetime' || productId.contains('premium')) {
          premiumPackage = package;
        } else if (pkgId.contains('tip') || pkgId.contains('support') || productId.contains('tip')) {
          tipPackages.add(package);
        }
      }
      // Fiyata göre sırala (Düşükten Yükseğe)
      tipPackages.sort((a, b) => a.storeProduct.price.compareTo(b.storeProduct.price));
    }

    return Scaffold(
      backgroundColor: themeProvider.settingsBgColor,
      appBar: AppBar(
        title: Text(
          isPremium ? 'premium_active'.tr() : 'get_premium'.tr(),
          style: AppFonts.poppins(
            context: context,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF38BDF8),
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: themeProvider.settingsTextColor,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Premium Özellikler Kartı
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF475569), Color(0xFF0F172A)], // Platinum/Slate gradient
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF38BDF8).withOpacity(0.2), // Diamond glow
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF38BDF8), Color(0xFF3B82F6)], // Cyan to Blue diamond
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF38BDF8).withOpacity(0.5),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.diamond_rounded, size: 64, color: Colors.white),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          isPremium 
                              ? 'premium_thanks'.tr()
                              : 'premium_desc'.tr(),
                          textAlign: TextAlign.center,
                          style: AppFonts.poppins(
                            context: context,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 28),
                        _buildFeatureRow(Icons.update_rounded, 'premium_feature_updates'.tr()),
                        const SizedBox(height: 16),
                        _buildFeatureRow(Icons.block, 'premium_feature_ads'.tr()),
                        const SizedBox(height: 16),
                        _buildFeatureRow(Icons.palette_rounded, 'premium_feature_themes'.tr()),
                        const SizedBox(height: 16),
                        _buildFeatureRow(Icons.favorite_rounded, 'premium_feature_support'.tr()),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),

                  // Premium Satın Alma Butonu
                  if (!isPremium) ...[
                    if (premiumPackage != null)
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF38BDF8), Color(0xFF3B82F6)], // Cyan to Blue diamond
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF38BDF8).withOpacity(0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () => _purchase(context, premiumPackage!),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            '${'get_unlimited_premium'.tr()} - ${premiumPackage.storeProduct.priceString}',
                            style: AppFonts.poppins(
                              context: context,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.withOpacity(0.2)),
                        ),
                        child: Text(
                          'packages_loading'.tr(),
                          textAlign: TextAlign.center,
                          style: AppFonts.poppins(context: context, color: themeProvider.settingsTextColor.withOpacity(0.7)),
                        ),
                      ),
                      
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () => _restore(context),
                      style: TextButton.styleFrom(
                        foregroundColor: themeProvider.settingsTextColor.withOpacity(0.7),
                      ),
                      child: Text(
                        'restore_purchases_btn'.tr(),
                        style: AppFonts.poppins(
                          context: context,
                          fontSize: 15,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),

                  // Destek (Tip) Alanı
                  if (tipPackages.isNotEmpty) ...[
                    Row(
                      children: [
                        Expanded(child: Divider(color: themeProvider.settingsTextColor.withOpacity(0.1), thickness: 1.5)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'support_developer'.tr(),
                            style: AppFonts.poppins(
                              context: context,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: themeProvider.settingsTextColor,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: themeProvider.settingsTextColor.withOpacity(0.1), thickness: 1.5)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'support_desc'.tr(),
                      textAlign: TextAlign.center,
                      style: AppFonts.poppins(
                        context: context,
                        fontSize: 14,
                        color: themeProvider.settingsTextColor.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ...tipPackages.asMap().entries.map((entry) {
                      final index = entry.key;
                      final package = entry.value;
                      
                      // Play Store'dan gelen başlığın yanındaki parantez içini sil (Örn: "Yıldız Destekçi (Pomodoro Elite...)" -> "Yıldız Destekçi")
                      final cleanTitle = package.storeProduct.title.replaceAll(RegExp(r'\s*\(.*\)'), '');
                      
                      // Paket sırasına göre renk tonlaması (Bronz, Gümüş, Altın / Elmas efekti)
                      final List<List<Color>> cardGradients = [
                        [const Color(0xFF818CF8), const Color(0xFF4F46E5)], // Indigo gradient
                        [const Color(0xFFF472B6), const Color(0xFFDB2777)], // Pink gradient
                        [const Color(0xFFA78BFA), const Color(0xFF7C3AED)], // Purple gradient
                        [const Color(0xFF2DD4BF), const Color(0xFF0D9488)], // Teal gradient
                      ];
                      
                      final gradientColors = cardGradients[index % cardGradients.length];
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                gradientColors[0].withOpacity(0.15),
                                gradientColors[1].withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: gradientColors[0].withOpacity(0.5),
                              width: 1.5,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _purchase(context, package),
                              borderRadius: BorderRadius.circular(24),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: gradientColors,
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: gradientColors[0].withOpacity(0.4),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.favorite_rounded,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            cleanTitle,
                                            style: AppFonts.poppins(
                                              context: context,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: themeProvider.settingsTextColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: gradientColors,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: gradientColors[0].withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        package.storeProduct.priceString,
                                        style: AppFonts.poppins(
                                          context: context,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: AppFonts.poppins(
              context: context,
              fontSize: 15,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  void _showModernDialog(BuildContext context, String title, String message, IconData icon, Color color) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final themeProvider = context.read<ThemeProvider>();
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: themeProvider.settingsBgColor,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: themeProvider.settingsBgColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: color.withOpacity(0.3), width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 24,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 48),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppFonts.poppins(
                    context: context,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.settingsTextColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppFonts.poppins(
                    context: context,
                    fontSize: 15,
                    color: themeProvider.settingsTextColor.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'ok_btn'.tr(),
                      style: AppFonts.poppins(
                        context: context,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _purchase(BuildContext context, Package package) async {
    final provider = context.read<PurchaseProvider>();
    final success = await provider.purchasePackage(package);
    
    if (context.mounted) {
      if (success) {
        _showModernDialog(
          context, 
          'thanks_title'.tr(), 
          'purchase_success'.tr(), 
          Icons.check_circle_rounded, 
          Colors.green
        );
      } else {
        _showModernDialog(
          context, 
          'transaction_failed'.tr(), 
          'purchase_cancelled'.tr(), 
          Icons.error_outline_rounded, 
          Colors.redAccent
        );
      }
    }
  }

  Future<void> _restore(BuildContext context) async {
    final provider = context.read<PurchaseProvider>();
    final success = await provider.restorePurchases();
    
    if (context.mounted) {
      if (success) {
        _showModernDialog(
          context, 
          'success_title'.tr(), 
          'restore_success'.tr(), 
          Icons.restore_rounded, 
          Colors.green
        );
      } else {
        _showModernDialog(
          context, 
          'not_found_title'.tr(), 
          'restore_not_found'.tr(), 
          Icons.search_off_rounded, 
          Colors.orange
        );
      }
    }
  }
}
