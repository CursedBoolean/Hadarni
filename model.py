# model_inference.py
import numpy as np
import torch
import librosa
from transformers import WhisperProcessor, WhisperForConditionalGeneration
from config import MODEL_PATH, SAMPLE_RATE

class ArabicLetterPredictor:
    def __init__(self, model_path=MODEL_PATH):
        self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        print(f"Loading model from {model_path} on {self.device}...")
        self.processor = WhisperProcessor.from_pretrained(model_path)
        self.model = WhisperForConditionalGeneration.from_pretrained(model_path).to(self.device)
        self.model.eval()
        print("Model loaded.")

    def predict(self, audio_array):
        """
        audio_array: numpy array of shape (samples,) at 16kHz.
        Returns transcribed text (string).
        """
        # Ensure audio is float32 and at correct sample rate
        if audio_array.dtype != np.float32:
            audio_array = audio_array.astype(np.float32)

        # Process audio to input features
        input_features = self.processor.feature_extractor(
            audio_array, sampling_rate=SAMPLE_RATE, return_tensors="pt"
        ).input_features.to(self.device)

        # Generate transcription
        with torch.no_grad():
            predicted_ids = self.model.generate(input_features)
        transcription = self.processor.tokenizer.batch_decode(
            predicted_ids, skip_special_tokens=True
        )[0]
        return transcription.strip()