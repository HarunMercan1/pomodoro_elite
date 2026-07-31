import os
import json

translations_dir = r"c:\my-projects\pomodoro_elite\assets\translations"

translations = {
    "tr": "Reklamları kaldır, temaları aç",
    "en": "Remove ads, unlock themes",
    "pt": "Remova anúncios, desbloqueie temas",
    "es": "Eliminar anuncios, desbloquear temas",
    "de": "Werbung entfernen, Themen freischalten",
    "fr": "Supprimer les pubs, débloquer les thèmes",
    "ru": "Удалить рекламу, разблокировать темы"
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
                
        # Only add if not present
        if "premium_subtitle" not in data:
            subtitle = translations.get(lang_code, translations["en"])
            data["premium_subtitle"] = subtitle
            
            with open(filepath, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
                
print("Done adding premium_subtitle to JSON files.")
