import json
import os
import glob
import time
import sys

try:
    from deep_translator import GoogleTranslator
except ImportError:
    print("deep-translator not installed. Exiting.")
    sys.exit(1)

source_strings = {
    "premium_active": "💎 Premium Aktif",
    "get_premium": "💎 Premium'a Geç",
    "premium_thanks": "Desteğiniz için teşekkürler! Tüm özellikler açık.",
    "premium_desc": "Pomodoro Elite deneyimini sınırlarına taşıyın.",
    "premium_feature_updates": "Gelecek tüm güncelleme ve yeni özelliklere anında erişim",
    "premium_feature_ads": "Sonsuza kadar reklamsız deneyim",
    "premium_feature_themes": "Tüm özel temaların kilidini aç",
    "premium_feature_support": "Geliştiriciye doğrudan destek ol",
    "get_unlimited_premium": "Sınırsız Premium Al",
    "packages_loading": "Paketler yükleniyor... İnternet bağlantınızı kontrol edin.",
    "restore_purchases_btn": "Satın Almaları Geri Yükle",
    "support_developer": "Geliştiriciye Destek Ol ❤️",
    "support_desc": "Uygulamanın gelişimine katkıda bulunmak ve daha iyi özellikler sunabilmemiz için bize destek olabilirsiniz.",
    "thanks_title": "Teşekkürler! 🎉",
    "purchase_success": "Satın alma işleminiz başarıyla gerçekleşti. Desteğiniz için minnettarız.",
    "transaction_failed": "İşlem Başarısız",
    "purchase_cancelled": "Satın alma işlemi iptal edildi veya bir hata oluştu.",
    "success_title": "Başarılı! 🔄",
    "restore_success": "Satın almalarınız başarıyla geri yüklendi ve hesabınıza tanımlandı.",
    "not_found_title": "Bulunamadı",
    "restore_not_found": "Bu hesaba ait geçmiş bir Premium satın alma kaydı bulunamadı.",
    "ok_btn": "Tamam"
}

# The files are in assets/translations
files = glob.glob("assets/translations/*.json")

def do_translate(text, target_lang):
    # Mapping for ISO codes if they differ
    lang_map = {
        'zh': 'zh-CN',
        'bn': 'bn',
        'ur': 'ur',
        'hi': 'hi',
        'el': 'el'
    }
    tgt = lang_map.get(target_lang, target_lang)
    
    # Try multiple times
    for _ in range(3):
        try:
            return GoogleTranslator(source='tr', target=tgt).translate(text)
        except Exception as e:
            time.sleep(1)
    return text

for file in files:
    filename = os.path.basename(file)
    lang_code = filename.split('.')[0]
    
    with open(file, 'r', encoding='utf-8') as f:
        data = json.load(f)
        
    changed = False
    print(f"Processing {lang_code}...")
    for key, tr_val in source_strings.items():
        if key not in data:
            if lang_code == 'tr':
                translated = tr_val
            else:
                translated = do_translate(tr_val, lang_code)
                time.sleep(0.1) # rate limit prevention
            data[key] = translated
            changed = True
            
    if changed:
        with open(file, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)

print("Done!")
