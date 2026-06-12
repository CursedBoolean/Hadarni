import torch
import warnings
from transformers import AutoProcessor, AutoModelForSpeechSeq2Seq
import sounddevice as sd

warnings.filterwarnings("ignore")

def test_microphone():
    model_path = "final_model/final_model"
    device = "cuda:0" if torch.cuda.is_available() else "cpu"
    
    print(f"Loading processor and model from {model_path} on {device} (Direct loading to bypass FFmpeg)...")
    try:
        processor = AutoProcessor.from_pretrained(model_path)
        model = AutoModelForSpeechSeq2Seq.from_pretrained(model_path).to(device)
    except Exception as e:
        print(f"Failed to load model: {e}")
        return

    fs = 16000
    seconds = 5
    
    print(f"\n[!] Recording for {seconds} seconds... Speak now! [!]")
    myrecording = sd.rec(int(seconds * fs), samplerate=fs, channels=1, dtype='float32')
    sd.wait()
    
    print("\nProcessing audio...")
    audio_array = myrecording.flatten()
    
    try:
        # Pass the numpy array directly to the processor. 
        # This guarantees NO FFmpeg or libtorchcodec dependency.
        input_features = processor(audio_array, sampling_rate=fs, return_tensors="pt").input_features.to(device)
        
        # Generate transcription
        predicted_ids = model.generate(input_features)
        transcription = processor.batch_decode(predicted_ids, skip_special_tokens=True)[0]
        
        print("\n=== Transcription ===")
        print(transcription)
        print("=====================\n")
    except Exception as e:
        print(f"Transcription failed: {e}")

if __name__ == "__main__":
    test_microphone()
