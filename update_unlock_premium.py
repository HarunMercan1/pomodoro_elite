import os
import json

translations_dir = r"c:\my-projects\pomodoro_elite\assets\translations"

translations = {
    "tr": {"unlock_premium": "Premium'u Aç"},
    "en": {"unlock_premium": "Unlock Premium"},
    "pt": {"unlock_premium": "Desbloquear Premium"},
    "es": {"unlock_premium": "Desbloquear Premium"},
    "de": {"unlock_premium": "Premium Freischalten"},
    "fr": {"unlock_premium": "Débloquer Premium"},
    "ru": {"unlock_premium": "Разблокировать Premium"},
    "ar": {"unlock_premium": "فتح بريميوم"},
    "bn": {"unlock_premium": "প্রিমিয়াম আনলক করুন"},
    "el": {"unlock_premium": "Ξεκλείδωμα Premium"},
    "hi": {"unlock_premium": "प्रीमियम अनलॉक करें"},
    "id": {"unlock_premium": "Buka Premium"},
    "it": {"unlock_premium": "Sblocca Premium"},
    "ja": {"unlock_premium": "プレミアムのロック解除"},
    "ko": {"unlock_premium": "프리미엄 잠금 해제"},
    "nl": {"unlock_premium": "Premium Ontgrendelen"},
    "pl": {"unlock_premium": "Odblokuj Premium"},
    "sv": {"unlock_premium": "Lås upp Premium"},
    "th": {"unlock_premium": "ปลดล็อกพรีเมียม"},
    "uk": {"unlock_premium": "Розблокувати Premium"},
    "ur": {"unlock_premium": "پریمیم انلاک کریں"},
    "vi": {"unlock_premium": "Mở khóa Premium"},
    "zh": {"unlock_premium": "解锁高级版"}
}

for filename in os.listdir(translations_dir):
    if filename.endswith(".json"):
        filepath = os.path.join(translations_dir, filename)
        lang_code = filename.split(".")[0]
        
        with open(filepath, 'r', encoding='utf-8') as f:
            try:
                data = json.load(f)
            except:
                continue
                
        if lang_code in translations:
            data["unlock_premium"] = translations[lang_code]["unlock_premium"]
            
            with open(filepath, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
                
print("Done fixing all 23 language translations.")
