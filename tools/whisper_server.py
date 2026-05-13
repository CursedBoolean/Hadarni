"""
Hadarni — Whisper ASR Server
============================
Loads the locally fine-tuned Whisper model and exposes a /transcribe endpoint
that the Flutter app calls after each mic recording.

Start with:
    python -m uvicorn tools.whisper_server:app --host 0.0.0.0 --port 8000 --reload

Endpoint
--------
POST /transcribe
    Form fields:
        audio  : audio file (WAV 16 kHz mono preferred; other formats accepted via librosa)
        target : Arabic letter or word to compare against (str)
    Response JSON:
        {
          "transcript":           "...",   # raw Whisper output
          "is_correct":           true,    # normalised comparison result
          "target":               "...",   # original target
          "target_normalised":    "...",   # after Arabic normalisation
          "transcript_normalised":"..."    # after Arabic normalisation
        }
"""

import re
import tempfile
from pathlib import Path

import librosa
import numpy as np
import torch
from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from transformers import WhisperForConditionalGeneration, WhisperProcessor

# ── Model path ────────────────────────────────────────────────────────────────
# whisper-finetuned-arabic/ lives at the project root, one level above tools/
MODEL_DIR = Path(__file__).parent.parent / "whisper-finetuned-arabic"

if not MODEL_DIR.exists():
    raise FileNotFoundError(
        f"Model directory not found: {MODEL_DIR}\n"
        "Make sure the whisper-finetuned-arabic/ folder is at the project root."
    )

print(f"[Hadarni] Loading Whisper processor from: {MODEL_DIR}")
processor: WhisperProcessor = WhisperProcessor.from_pretrained(str(MODEL_DIR))

print(f"[Hadarni] Loading Whisper model from: {MODEL_DIR}")
model: WhisperForConditionalGeneration = WhisperForConditionalGeneration.from_pretrained(
    str(MODEL_DIR)
)
model.eval()

DEVICE = "cuda" if torch.cuda.is_available() else "cpu"
model = model.to(DEVICE)
print(f"[Hadarni] Model ready on device: {DEVICE}")

# ── Arabic text normalisation ─────────────────────────────────────────────────

def normalise_arabic(text: str) -> str:
    """
    Normalise Arabic text for a forgiving comparison:
    - Strip diacritics (harakat) and tatweel
    - Unify alef variants  →  ا
    - Unify ta marbuta     →  ه
    - Unify ya variants    →  ي
    - Collapse whitespace
    """
    # Remove diacritics (U+064B – U+065F), superscript alef (U+0670), tatweel (U+0640)
    text = re.sub(r"[\u064B-\u065F\u0670\u0640]", "", text)
    # Normalise alef variants
    text = re.sub(r"[أإآٱ]", "ا", text)
    # Normalise ta marbuta
    text = re.sub(r"ة", "ه", text)
    # Normalise ya variants
    text = re.sub(r"[يى]", "ي", text)
    # Collapse whitespace and strip
    return " ".join(text.split()).strip()


def texts_match(predicted: str, target: str) -> bool:
    return normalise_arabic(predicted) == normalise_arabic(target)


# ── FastAPI app ───────────────────────────────────────────────────────────────

app = FastAPI(title="Hadarni Whisper ASR", version="1.0.0")

# Allow all origins so the Flutter dev build (or emulator) can reach the server
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health():
    """Simple liveness check."""
    return {"status": "ok", "device": DEVICE, "model_dir": str(MODEL_DIR)}


@app.post("/transcribe")
async def transcribe(
    audio: UploadFile = File(..., description="Audio file (WAV 16 kHz mono preferred)"),
    target: str = Form(..., description="Target Arabic letter or word"),
):
    """
    Transcribe the uploaded audio with the fine-tuned Whisper model and
    compare the result to the target text.
    """
    # Persist upload to a temp file so librosa can read it
    suffix = Path(audio.filename).suffix if audio.filename else ".wav"
    with tempfile.NamedTemporaryFile(suffix=suffix, delete=False) as tmp:
        content = await audio.read()
        tmp.write(content)
        tmp_path = Path(tmp.name)

    try:
        # Load and resample to 16 kHz mono (Whisper's expected format)
        waveform, _ = librosa.load(str(tmp_path), sr=16000, mono=True)

        # Guard against silent / very short recordings
        if len(waveform) < 1600:  # less than 0.1 s
            raise HTTPException(status_code=422, detail="Audio too short — please speak clearly.")

        # Extract log-mel spectrogram features
        inputs = processor(
            waveform,
            sampling_rate=16000,
            return_tensors="pt",
        )
        input_features = inputs.input_features.to(DEVICE)

        # Build an explicit attention mask (all-ones = full sequence attended to).
        # Without this, transformers warns that pad_token == eos_token makes
        # automatic mask inference unreliable for Whisper.
        attention_mask = torch.ones(
            input_features.shape[:2], dtype=torch.long, device=DEVICE
        )

        # Run inference.
        # Do NOT pass suppress_tokens / begin_suppress_tokens here — they are
        # already stored in the model's saved generation_config.json.  Passing
        # them again causes transformers to create duplicate logits processors
        # which produces warnings and slows down generation significantly.
        # forced_decoder_ids pins the language/task prefix tokens cleanly.
        forced_ids = processor.get_decoder_prompt_ids(language="ar", task="transcribe")
        with torch.no_grad():
            predicted_ids = model.generate(
                input_features,
                attention_mask=attention_mask,
                forced_decoder_ids=forced_ids,
                no_repeat_ngram_size=3,
            )

        transcript: str = processor.batch_decode(
            predicted_ids, skip_special_tokens=True
        )[0].strip()

        is_correct = texts_match(transcript, target)

        return {
            "transcript": transcript,
            "is_correct": is_correct,
            "target": target,
            "target_normalised": normalise_arabic(target),
            "transcript_normalised": normalise_arabic(transcript),
        }

    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc
    finally:
        tmp_path.unlink(missing_ok=True)
