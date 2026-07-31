import os
import json

translations_dir = r"c:\my-projects\pomodoro_elite\assets\translations"

translations = {
    "tr": {"star_supporter": "Yıldız Destekçi", "super_star_supporter": "Süper Yıldız Destekçi"},
    "en": {"star_supporter": "Star Supporter", "super_star_supporter": "Super Star Supporter"},
    "pt": {"star_supporter": "Apoiador Estrela", "super_star_supporter": "Apoiador Super Estrela"},
    "es": {"star_supporter": "Patrocinador Estrella", "super_star_supporter": "Patrocinador Súper Estrella"},
    "de": {"star_supporter": "Sterne-Unterstützer", "super_star_supporter": "Super-Sterne-Unterstützer"},
    "fr": {"star_supporter": "Supporter Étoile", "super_star_supporter": "Supporter Super Étoile"},
    "ru": {"star_supporter": "Звездный спонсор", "super_star_supporter": "Супер Звездный спонсор"}
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
                
print("Done adding supporter keys to JSON files.")
