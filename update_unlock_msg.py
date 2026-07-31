import os
import json

translations_dir = r"c:\my-projects\pomodoro_elite\assets\translations"

updates = {
    "tr": "Bu temayı açmak için kısa bir video izle veya Premium'a geç.",
    "en": "Watch a short video or get Premium to unlock this theme.",
    "es": "Mira un video corto u obtén Premium para desbloquear este tema.",
    "fr": "Regardez une courte vidéo ou obtenez Premium pour débloquer ce thème.",
    "de": "Schauen Sie sich ein kurzes Video an oder holen Sie sich Premium, um dieses Design freizuschalten.",
    "pt": "Assista a um vídeo curto ou obtenha o Premium para desbloquear este tema.",
    "it": "Guarda un breve video o ottieni Premium per sbloccare questo tema.",
    "ru": "Посмотрите короткое видео или получите Premium, чтобы разблокировать эту тему.",
    "ar": "شاهد مقطع فيديو قصيرًا أو احصل على Premium لفتح هذا المظهر.",
    "bn": "এই থিমটি আনলক করতে একটি ছোট ভিডিও দেখুন বা প্রিমিয়াম পান।",
    "el": "Παρακολουθήστε ένα σύντομο βίντεο ή αποκτήστε Premium για να ξεκλειδώσετε αυτό το θέμα.",
    "hi": "इस थीम को अनलॉक करने के लिए एक छोटा वीडियो देखें या प्रीमियम प्राप्त करें।",
    "id": "Tonton video pendek atau dapatkan Premium untuk membuka tema ini.",
    "ja": "このテーマのロックを解除するには、短い動画を見るかプレミアムを取得してください。",
    "ko": "이 테마를 잠금 해제하려면 짧은 동영상을 보거나 프리미엄을 이용하세요.",
    "nl": "Bekijk een korte video of neem Premium om dit thema te ontgrendelen.",
    "pl": "Obejrzyj krótki film lub uzyskaj Premium, aby odblokować ten motyw.",
    "sv": "Titta på en kort video eller skaffa Premium för att låsa upp detta tema.",
    "th": "ดูวิดีโอสั้นๆ หรือรับพรีเมียมเพื่อปลดล็อกธีมนี้",
    "uk": "Подивіться коротке відео або отримайте Premium, щоб розблокувати цю тему.",
    "ur": "اس تھیم کو انلاک کرنے کے لیے ایک مختصر ویڈیو دیکھیں یا پریمیم حاصل کریں۔",
    "vi": "Xem một đoạn video ngắn hoặc nhận Premium để mở khóa chủ đề này.",
    "zh": "观看短视频或获取高级版以解锁此主题。"
}

for filename in os.listdir(translations_dir):
    if filename.endswith(".json"):
        filepath = os.path.join(translations_dir, filename)
        lang_code = filename.split(".")[0]
        
        with open(filepath, 'r', encoding='utf-8') as f:
            try:
                data = json.load(f)
            except Exception as e:
                print(f"Error reading {filename}: {e}")
                continue
                
        if lang_code in updates:
            data["unlock_theme_msg"] = updates[lang_code]
            
            with open(filepath, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
                
print("Done fixing unlock_theme_msg in all 23 languages.")
