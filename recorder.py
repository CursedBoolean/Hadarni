# recorder.py
import sounddevice as sd
import numpy as np
from config import SAMPLE_RATE

class Recorder:
    def __init__(self, fs=SAMPLE_RATE):
        self.fs = fs
        self.audio_data = []
        self.stream = None
        self.is_recording = False

    def start_recording(self):
        """Start recording asynchronously."""
        self.audio_data = []  # Clear previous recording
        self.is_recording = True
        # Create an input stream that calls callback with each block
        self.stream = sd.InputStream(
            samplerate=self.fs,
            channels=1,
            dtype='float32',
            callback=self._callback
        )
        self.stream.start()
        print("Recording started...")

    def _callback(self, indata, frames, time, status):
        """Called for each audio block while recording."""
        if self.is_recording:
            # Append a copy of the data
            self.audio_data.append(indata.copy())

    def stop_recording(self):
        """Stop recording and return the concatenated audio as a 1D array."""
        if self.stream is not None:
            self.stream.stop()
            self.stream.close()
            self.stream = None
        self.is_recording = False
        if self.audio_data:
            # Concatenate all blocks along axis 0, then flatten to 1D
            return np.concatenate(self.audio_data, axis=0).flatten()
        else:
            # No data recorded (maybe start was never called, or very short)
            return np.array([], dtype=np.float32)