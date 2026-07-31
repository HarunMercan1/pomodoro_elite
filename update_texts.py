import os
import json

translations_dir = r"c:\my-projects\pomodoro_elite\assets\translations"

updates = {
    "tr": {"premium_active": "💎 Premium Kullanıcısınız", "get_unlimited_premium": "Premium Al"},
    "en": {"premium_active": "💎 You are a Premium User", "get_unlimited_premium": "Get Premium"},
    "es": {"premium_active": "💎 Eres un Usuario Premium", "get_unlimited_premium": "Obtener Premium"},
    "fr": {"premium_active": "💎 Vous êtes un Utilisateur Premium", "get_unlimited_premium": "Obtenir Premium"},
    "de": {"premium_active": "💎 Sie sind ein Premium-Benutzer", "get_unlimited_premium": "Premium Holen"},
    "pt": {"premium_active": "💎 Você é um Usuário Premium", "get_unlimited_premium": "Obter Premium"},
    "it": {"premium_active": "💎 Sei un Utente Premium", "get_unlimited_premium": "Ottieni Premium"},
    "ru": {"premium_active": "💎 Вы - Premium пользователь", "get_unlimited_premium": "Получить Premium"},
    "ar": {"premium_active": "💎 أنت مستخدم مميز", "get_unlimited_premium": "احصل على بريميوم"},
    "bn": {"premium_active": "💎 আপনি একজন প্রিমিয়াম ব্যবহারকারী", "get_unlimited_premium": "প্রিমিয়াম পান"},
    "el": {"premium_active": "💎 Είστε Χρήστης Premium", "get_unlimited_premium": "Αποκτήστε Premium"},
    "hi": {"premium_active": "💎 आप एक प्रीमियम उपयोगकर्ता हैं", "get_unlimited_premium": "प्रीमियम प्राप्त करें"},
    "id": {"premium_active": "💎 Anda adalah Pengguna Premium", "get_unlimited_premium": "Dapatkan Premium"},
    "ja": {"premium_active": "💎 プレミアムユーザーです", "get_unlimited_premium": "プレミアムを取得"},
    "ko": {"premium_active": "💎 프리미엄 사용자입니다", "get_unlimited_premium": "프리미엄 받기"},
    "nl": {"premium_active": "💎 U bent een Premium Gebruiker", "get_unlimited_premium": "Krijg Premium"},
    "pl": {"premium_active": "💎 Jesteś Użytkownikiem Premium", "get_unlimited_premium": "Zdobądź Premium"},
    "sv": {"premium_active": "💎 Du är en Premium-användare", "get_unlimited_premium": "Skaffa Premium"},
    "th": {"premium_active": "💎 คุณคือผู้ใช้พรีเมียม", "get_unlimited_premium": "รับพรีเมียม"},
    "uk": {"premium_active": "💎 Ви - Premium користувач", "get_unlimited_premium": "Отримати Premium"},
    "ur": {"premium_active": "💎 آپ ایک پریمیم صارف ہیں", "get_unlimited_premium": "پریمیم حاصل کریں"},
    "vi": {"premium_active": "💎 Bạn là Người dùng Premium", "get_unlimited_premium": "Nhận Premium"},
    "zh": {"premium_active": "💎 您是高级用户", "get_unlimited_premium": "获取高级版"}
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
            data["premium_active"] = updates[lang_code]["premium_active"]
            data["get_unlimited_premium"] = updates[lang_code]["get_unlimited_premium"]
            
            with open(filepath, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
                
print("Done fixing premium texts in all 23 languages.")
