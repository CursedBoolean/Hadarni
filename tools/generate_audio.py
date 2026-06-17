import asyncio
import os
import edge_tts

# ── Voice selection ───────────────────────────────────────────────────────────
# Swap VOICE to try different options:
#   ar-SA-HamedNeural   — Saudi male,   clear MSA diction  ✅ default
#   ar-SA-ZariyahNeural — Saudi female, warm tone
#   ar-EG-ShakirNeural  — Egyptian male, very clear for children
#   ar-EG-SalmaNeural   — Egyptian female
VOICE = "ar-SA-HamedNeural"

OUTPUT_DIR_LETTERS  = "../assets/audio/letters"
OUTPUT_DIR_WORDS    = "../assets/audio/words"
OUTPUT_DIR_FEEDBACK = "../assets/audio/feedback"

# ── Arabic letters (glyphs only — used as filenames) ─────────────────────────
ARABIC_LETTERS = [
    'أ', 'ب', 'ت', 'ث', 'ج', 'ح', 'خ', 'د',
    'ذ', 'ر', 'ز', 'س', 'ش', 'ص', 'ض', 'ط',
    'ظ', 'ع', 'غ', 'ف', 'ق', 'ك', 'ل', 'م',
    'ن', 'ه', 'و', 'ي',
]

# Fatha diacritic (U+064E) — appended to the glyph so TTS says the SHORT
# phoneme sound ("ba", "ta", "sha"…) rather than the full letter name
# ("baa", "taa", "sheen"…).
FATHA = '\u064e'

# Per-letter overrides — use when glyph+fatha sounds wrong.
# Value is the FULL TTS text (replaces f"قُلْ {glyph}{FATHA}").
#   أ  →  "قُلْ آ"  because أَ triggers tanwin (sounds like "an");
#          آ (alef madd) is an unambiguous clean "aa" with no nunation.
LETTER_OVERRIDES: dict[str, str] = {
    'أ': 'قُلْ آ',
}

DEMO_WORDS = [
    'كأس', 'كتاب', 'قلم', 'باب', 'شمس', 'قمر', 'بيت', 'ماء',
]

# Feedback sounds: (filename_without_ext, Arabic text)
FEEDBACK_SOUNDS = [
    ('correct',   'أحسنت! إجابة صحيحة!'),
    ('incorrect', 'حاول مرة أخرى، أنت قادر على ذلك!'),
]


async def generate_audio(text: str, output_path: str) -> None:
    communicate = edge_tts.Communicate(text, VOICE)
    await communicate.save(output_path)
    print(f"Generated: {output_path}".encode('utf-8').decode('cp1252', 'ignore'))


async def main() -> None:
    os.makedirs(OUTPUT_DIR_LETTERS,  exist_ok=True)
    os.makedirs(OUTPUT_DIR_WORDS,    exist_ok=True)
    os.makedirs(OUTPUT_DIR_FEEDBACK, exist_ok=True)

    print(f"Voice: {VOICE}\n")

    # ── Letters ───────────────────────────────────────────────────────────────
    # Prompt: "قُلْ بَ" → TTS says the short sound "ba", not the name "baa"
    print("Generating letter audio prompts...")
    for glyph in ARABIC_LETTERS:
        # Use override if defined, otherwise default glyph+fatha prompt
        text = LETTER_OVERRIDES.get(glyph, f"قُلْ {glyph}{FATHA}")
        path = os.path.join(OUTPUT_DIR_LETTERS, f"{glyph}.mp3")
        await generate_audio(text, path)

    # ── Words ─────────────────────────────────────────────────────────────────
    print("\nGenerating word audio prompts...")
    for word in DEMO_WORDS:
        text = f"قُلْ {word}"
        path = os.path.join(OUTPUT_DIR_WORDS, f"{word}.mp3")
        await generate_audio(text, path)

    # ── Feedback ──────────────────────────────────────────────────────────────
    print("\nGenerating feedback audio sounds...")
    for name, text in FEEDBACK_SOUNDS:
        path = os.path.join(OUTPUT_DIR_FEEDBACK, f"{name}.mp3")
        await generate_audio(text, path)

    print("\nDone!")


if __name__ == "__main__":
    asyncio.run(main())


