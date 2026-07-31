import os
import json

translations_dir = r"c:\my-projects\pomodoro_elite\assets\translations"

translations = {
    "tr": {"login_required": "Üye Girişi Gerekli", "premium_login_required_desc": "Premium satın almak veya özelliklerini kullanmak için lütfen hesabınıza giriş yapın."},
    "en": {"login_required": "Login Required", "premium_login_required_desc": "Please log in to your account to purchase or use Premium features."},
    "pt": {"login_required": "Login Necessário", "premium_login_required_desc": "Faça login na sua conta para comprar ou usar os recursos Premium."},
    "es": {"login_required": "Inicio de Sesión Requerido", "premium_login_required_desc": "Inicie sesión en su cuenta para comprar o usar las funciones Premium."},
    "de": {"login_required": "Anmeldung Erforderlich", "premium_login_required_desc": "Bitte melden Sie sich an, um Premium-Funktionen zu kaufen oder zu nutzen."},
    "fr": {"login_required": "Connexion Requise", "premium_login_required_desc": "Veuillez vous connecter pour acheter ou utiliser les fonctionnalités Premium."},
    "ru": {"login_required": "Требуется вход", "premium_login_required_desc": "Пожалуйста, войдите в свою учетную запись, чтобы приобрести или использовать функции Premium."},
    "ar": {"login_required": "تسجيل الدخول مطلوب", "premium_login_required_desc": "يرجى تسجيل الدخول إلى حسابك لشراء أو استخدام ميزات Premium."},
    "bn": {"login_required": "লগইন প্রয়োজন", "premium_login_required_desc": "প্রিমিয়াম বৈশিষ্ট্যগুলি কিনতে বা ব্যবহার করতে অনুগ্রহ করে আপনার অ্যাকাউন্টে লগ ইন করুন।"},
    "el": {"login_required": "Απαιτείται Σύνδεση", "premium_login_required_desc": "Συνδεθείτε στον λογαριασμό σας για να αγοράσετε ή να χρησιμοποιήσετε λειτουργίες Premium."},
    "hi": {"login_required": "लॉगिन आवश्यक", "premium_login_required_desc": "प्रीमियम सुविधाएँ खरीदने या उपयोग करने के लिए कृपया अपने खाते में लॉग इन करें।"},
    "id": {"login_required": "Diperlukan Login", "premium_login_required_desc": "Silakan masuk ke akun Anda untuk membeli atau menggunakan fitur Premium."},
    "it": {"login_required": "Accesso Richiesto", "premium_login_required_desc": "Accedi al tuo account per acquistare o utilizzare le funzionalità Premium."},
    "ja": {"login_required": "ログインが必要です", "premium_login_required_desc": "プレミアム機能を購入または使用するには、アカウントにログインしてください。"},
    "ko": {"login_required": "로그인 필요", "premium_login_required_desc": "프리미엄 기능을 구매하거나 사용하려면 계정에 로그인하세요."},
    "nl": {"login_required": "Inloggen Vereist", "premium_login_required_desc": "Log in op uw account om Premium-functies te kopen of te gebruiken."},
    "pl": {"login_required": "Wymagane Logowanie", "premium_login_required_desc": "Zaloguj się na swoje konto, aby kupić lub korzystać z funkcji Premium."},
    "sv": {"login_required": "Inloggning Krävs", "premium_login_required_desc": "Logga in på ditt konto för att köpa eller använda Premium-funktioner."},
    "th": {"login_required": "จำเป็นต้องเข้าสู่ระบบ", "premium_login_required_desc": "โปรดเข้าสู่ระบบบัญชีของคุณเพื่อซื้อหรือใช้คุณสมบัติพรีเมียม"},
    "uk": {"login_required": "Потрібен Вхід", "premium_login_required_desc": "Увійдіть у свій обліковий запис, щоб придбати або використовувати функції Premium."},
    "ur": {"login_required": "لاگ ان درکار ہے", "premium_login_required_desc": "پریمیم خصوصیات خریدنے یا استعمال کرنے کے لیے براہ کرم اپنے اکاؤنٹ میں لاگ ان کریں۔"},
    "vi": {"login_required": "Yêu cầu Đăng nhập", "premium_login_required_desc": "Vui lòng đăng nhập vào tài khoản của bạn để mua hoặc sử dụng các tính năng Premium."},
    "zh": {"login_required": "需要登录", "premium_login_required_desc": "请登录您的帐户以购买或使用高级功能。"}
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
                
        # Force overwrite with the correct language specific string
        if lang_code in translations:
            data["login_required"] = translations[lang_code]["login_required"]
            data["premium_login_required_desc"] = translations[lang_code]["premium_login_required_desc"]
            
            with open(filepath, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
                
print("Done fixing all 23 language translations.")
