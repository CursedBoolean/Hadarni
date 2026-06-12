# shared_test_cases.py
# ─────────────────────────────────────────────────────────────────
# Single source of truth for both evaluation scripts.
#
# Design decisions:
#   - ONE spoken_text per case (fatha vowel only — matches Whisper training)
#   - TWO mistake cases per letter (the most common confusable sounds)
#   - Same child name pool used consistently across both scripts
#   - Arabic letter (ar) + English name (en) kept together so both
#     scripts can use whichever key their server/model expects
# ─────────────────────────────────────────────────────────────────

# (ar, en, correct_fatha, [mistake1, mistake2], child_name)
TEST_CASES = [
    ("ا", "Alif",  "أَ",  ["عَ", "هَ"],   "ياسمين"),
    ("ب", "Ba",    "بَ",  ["تَ", "نَ"],   "أحمد"),
    ("ت", "Ta",    "تَ",  ["طَ", "ثَ"],   "سارة"),
    ("ث", "Tha",   "ثَ",  ["سَ", "تَ"],   "يوسف"),
    ("ج", "Jeem",  "جَ",  ["حَ", "زَ"],   "ليلى"),
    ("ح", "Haa",   "حَ",  ["خَ", "هَ"],   "عمر"),
    ("خ", "Kha",   "خَ",  ["حَ", "كَ"],   "نور"),
    ("د", "Dal",   "دَ",  ["ذَ", "زَ"],   "فاطمة"),
    ("ذ", "Dhal",  "ذَ",  ["زَ", "دَ"],   "حسن"),
    ("ر", "Ra",    "رَ",  ["زَ", "لَ"],   "مريم"),
    ("ز", "Zay",   "زَ",  ["ذَ", "سَ"],   "ياسين"),
    ("س", "Seen",  "سَ",  ["شَ", "ثَ"],   "كوثر"),
    ("ش", "Sheen", "شَ",  ["سَ", "جَ"],   "آية"),
    ("ص", "Saad",  "صَ",  ["سَ", "ضَ"],   "إبراهيم"),
    ("ض", "Daad",  "ضَ",  ["ظَ", "دَ"],   "زينب"),
    ("ط", "Tah",   "طَ",  ["تَ", "ظَ"],   "محمد"),
    ("ظ", "Zha",   "ظَ",  ["ضَ", "ذَ"],   "رنا"),
    ("ع", "Ain",   "عَ",  ["اَ", "غَ"],   "خالد"),
    ("غ", "Ghain", "غَ",  ["عَ", "قَ"],   "غسان"),
    ("ف", "Fa",    "فَ",  ["بَ", "وَ"],   "هدى"),
    ("ق", "Qaf",   "قَ",  ["كَ", "غَ"],   "ياسمين"),
    ("ك", "Kaf",   "كَ",  ["قَ", "خَ"],   "أحمد"),
    ("ل", "Lam",   "لَ",  ["رَ", "نَ"],   "سارة"),
    ("م", "Meem",  "مَ",  ["نَ", "بَ"],   "يوسف"),
    ("ن", "Noon",  "نَ",  ["مَ", "لَ"],   "ليلى"),
    ("ه", "Ha_2",  "هَ",  ["حَ", "عَ"],   "عمر"),
    ("و", "Waw",   "وَ",  ["فَ", "بَ"],   "نور"),
    ("ي", "Ya",    "يَ",  ["اَ", "وَ"],   "فاطمة"),
]

# Convenience: flat list of dicts for easy iteration
def get_flat_cases() -> list[dict]:
    """
    Returns a flat list of individual test cases, each dict has:
      ar, en, is_correct, spoken_text, child_name
    """
    flat = []
    for ar, en, correct, mistakes, child in TEST_CASES:
        flat.append({
            "ar": ar, "en": en,
            "is_correct": True,
            "spoken_text": correct,
            "child_name": child,
        })
        for mistake in mistakes:
            flat.append({
                "ar": ar, "en": en,
                "is_correct": False,
                "spoken_text": mistake,
                "child_name": child,
            })
    return flat
