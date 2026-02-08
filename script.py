import os
import json

def create_hijaiyah_mapping(dataset_path, output_file="metadata.json"):
    # Metadata for each folder (1-28) in standard Arabic order
    hijaiah_meta = {
        "1":  {"name": "Alif",  "char": "أَ", "ipa": "/a/",   "confusion": ["ha", "ain"], "tip": "Open mouth vertically."},
        "2":  {"name": "Ba",    "char": "بَ", "ipa": "/ba/",  "confusion": ["ta"], "tip": "Press lips together and pop."},
        "3":  {"name": "Ta",    "char": "تَ", "ipa": "/ta/",  "confusion": ["tha", "da"], "tip": "Touch tip of tongue to teeth."},
        "4":  {"name": "Tha",   "char": "ثَ", "ipa": "/θa/",  "confusion": ["sa", "ta"], "tip": "Put tongue between teeth."},
        "5":  {"name": "Jeem",  "char": "جَ", "ipa": "/d͡ʒa/", "confusion": ["sha", "za"], "tip": "Make a strong 'J' sound."},
        "6":  {"name": "Ha",    "char": "حَ", "ipa": "/ħa/",  "confusion": ["ha", "kha"], "tip": "Deep breathy 'H' from throat."},
        "7":  {"name": "Kha",   "char": "خَ", "ipa": "/xa/",  "confusion": ["ha", "ghain"], "tip": "Make a snoring sound."},
        "8":  {"name": "Dal",   "char": "دَ", "ipa": "/da/",  "confusion": ["tha", "ta"], "tip": "Short 'D' sound."},
        "9":  {"name": "Dhal",  "char": "ذَ", "ipa": "/ða/",  "confusion": ["za", "tha"], "tip": "Tongue between teeth for 'Dh'."},
        "10": {"name": "Ra",    "char": "رَ", "ipa": "/ra/",  "confusion": ["za", "la"], "tip": "Roll your tongue slightly."},
        "11": {"name": "Zay",   "char": "زَ", "ipa": "/za/",  "confusion": ["seen", "ra"], "tip": "Buzz like a bee."},
        "12": {"name": "Seen",  "char": "سَ", "ipa": "/sa/",  "confusion": ["sheen", "saad"], "tip": "Sharp 'S' whistling sound."},
        "13": {"name": "Sheen", "char": "شَ", "ipa": "/ʃa/",  "confusion": ["seen", "jeem"], "tip": "Be quiet: 'Shhh'."},
        "14": {"name": "Saad",  "char": "صَ", "ipa": "/sˤa/", "confusion": ["seen", "daad"], "tip": "Heavy, thick 'S' sound."},
        "15": {"name": "Daad",  "char": "ضَ", "ipa": "/dˤa/", "confusion": ["dal", "zaad"], "tip": "The hardest letter! Use side of tongue."},
        "16": {"name": "Tah",   "char": "طَ", "ipa": "/tˤa/", "confusion": ["ta", "daad"], "tip": "Strong, heavy 'T'."},
        "17": {"name": "Zha",   "char": "ظَ", "ipa": "/ðˤa/", "confusion": ["za", "dhal"], "tip": "Heavy, buzzy 'Zh'."},
        "18": {"name": "Ain",   "char": "عَ", "ipa": "/ʕa/",  "confusion": ["alif", "ha"], "tip": "Tighten your throat."},
        "19": {"name": "Ghain", "char": "غَ", "ipa": "/ɣa/",  "confusion": ["kha", "qaf"], "tip": "Gargle some water sound."},
        "20": {"name": "Fa",    "char": "فَ", "ipa": "/fa/",  "confusion": ["ba", "va"], "tip": "Teeth on bottom lip."},
        "21": {"name": "Qaf",   "char": "قَ", "ipa": "/qa/",  "confusion": ["kaf", "ghain"], "tip": "Click the back of your throat."},
        "22": {"name": "Kaf",   "char": "كَ", "ipa": "/ka/",  "confusion": ["qaf", "ta"], "tip": "Light 'K' sound."},
        "23": {"name": "Lam",   "char": "لَ", "ipa": "/la/",  "confusion": ["ra", "noon"], "tip": "Lick the roof of your mouth."},
        "24": {"name": "Meem",  "char": "مَ", "ipa": "/ma/",  "confusion": ["noon", "ba"], "tip": "Hum with lips closed."},
        "25": {"name": "Noon",  "char": "نَ", "ipa": "/na/",  "confusion": ["meem", "la"], "tip": "Hum through your nose."},
        "26": {"name": "Ha",    "char": "هَ", "ipa": "/ha/",  "confusion": ["ain", "alif"], "tip": "A soft sighing sound."},
        "27": {"name": "Waw",   "char": "وَ", "ipa": "/wa/",  "confusion": ["fa", "ba"], "tip": "Round your lips like an 'O'."},
        "28": {"name": "Ya",    "char": "يَ", "ipa": "/ja/",  "confusion": ["alif", "za"], "tip": "Smiling 'Y' sound."}
    }

    dataset_list = []

    # Iterate through numbered folders
    for folder_num in sorted(os.listdir(dataset_path), key=lambda x: int(x) if x.isdigit() else 99):
        folder_dir = os.path.join(dataset_path, folder_num)
        
        if os.path.isdir(folder_dir) and folder_num in hijaiah_meta:
            meta = hijaiah_meta[folder_num]
            
            for file_name in os.listdir(folder_dir):
                if file_name.endswith(('.wav', '.mp3', '.m4a')):
                    entry = {
                        "file_path": f'Dataset Telkom 16KHz/Dataset Telkom 16KHz/ {os.path.join(folder_num, file_name)}',
                        "letter_index": int(folder_num),
                        "letter_name": meta["name"],
                        "arabic_char": meta["char"],
                        "ipa": meta["ipa"],
                        "is_correct": True,
                        "feedback_success": f"Excellent! That was a perfect {meta['name']}!",
                        "teaching_tip": meta["tip"],
                        "confusion_targets": meta["confusion"]
                    }
                    dataset_list.append(entry)

    # Save to JSON
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(dataset_list, f, ensure_ascii=False, indent=4)
    
    print(f"Success! Created {output_file} with {len(dataset_list)} entries.")

# Usage: 
# create_hijaiyah_mapping("/path/to/your/kaggle/dataset")

dataset_path = "C:/Users/DESKTOP/Downloads/archive/Dataset Telkom 16KHz/Dataset Telkom 16KHz"

create_hijaiyah_mapping(dataset_path=dataset_path)

