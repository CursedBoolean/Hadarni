import asyncio
import os
import edge_tts

# Constants
VOICE = "ar-SA-ZariyahNeural"
OUTPUT_DIR_LETTERS = "../assets/audio/letters"
OUTPUT_DIR_WORDS = "../assets/audio/words"
OUTPUT_DIR_FEEDBACK = "../assets/audio/feedback"

ARABIC_LETTERS = [
    'أ', 'ب', 'ت', 'ث', 'ج', 'ح', 'خ', 'د',
    'ذ', 'ر', 'ز', 'س', 'ش', 'ص', 'ض', 'ط',
    'ظ', 'ع', 'غ', 'ف', 'ق', 'ك', 'ل', 'م',
    'ن', 'ه', 'و', 'ي',
]

DEMO_WORDS = [
    'كأس', 'كتاب', 'قلم', 'باب', 'شمس', 'قمر', 'بيت', 'ماء',
]

# Feedback sounds: (filename_without_ext, Arabic text)
FEEDBACK_SOUNDS = [
    ('correct',   'أحسنت! إجابة صحيحة!'),
    ('incorrect', 'حاول مرة أخرى، أنت قادر على ذلك!'),
]

async def generate_audio(text: str, output_path: str):
    communicate = edge_tts.Communicate(text, VOICE)
    await communicate.save(output_path)
    print(f"Generated: {output_path}".encode('utf-8').decode('cp1252', 'ignore'))

async def main():
    # Ensure directories exist
    os.makedirs(OUTPUT_DIR_LETTERS, exist_ok=True)
    os.makedirs(OUTPUT_DIR_WORDS, exist_ok=True)
    os.makedirs(OUTPUT_DIR_FEEDBACK, exist_ok=True)

    print("Generating letter audio prompts...")
    for letter in ARABIC_LETTERS:
        text = f"قُلْ {letter}"
        # We use the letter itself as the filename.
        # Flutter handles UTF-8 paths well.
        path = os.path.join(OUTPUT_DIR_LETTERS, f"{letter}.mp3")
        await generate_audio(text, path)

    print("\nGenerating word audio prompts...")
    for word in DEMO_WORDS:
        text = f"قُلْ {word}"
        path = os.path.join(OUTPUT_DIR_WORDS, f"{word}.mp3")
        await generate_audio(text, path)

    print("\nGenerating feedback audio sounds...")
    for name, text in FEEDBACK_SOUNDS:
        path = os.path.join(OUTPUT_DIR_FEEDBACK, f"{name}.mp3")
        await generate_audio(text, path)

if __name__ == "__main__":
    asyncio.run(main())

