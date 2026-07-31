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
    "ru": {"login_required": "Требуется вход", "premium_login_required_desc": "Пожалуйста, войдите в свою учетную запись, чтобы приобрести или использовать функции Premium."}
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
                
        changed = False
        default_keys = translations["en"]
        lang_keys = translations.get(lang_code, default_keys)
        
        for key, value in lang_keys.items():
            if key not in data:
                data[key] = value
                changed = True
                
        if changed:
            with open(filepath, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
                
print("Done adding login translation keys.")
