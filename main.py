# main.py
import tkinter as tk
from tkinter import messagebox
import threading
import numpy as np
from recorder import Recorder
from model import ArabicLetterPredictor
from config import RECORD_SECONDS  # still used only as fallback? We'll ignore or repurpose.

class LetterTesterApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Arabic Letter Tester")
        self.root.geometry("600x450")

        # Load model (this may take a few seconds)
        self.predictor = ArabicLetterPredictor()
        self.recorder = Recorder()   # our new recorder

        # Current letter to test
        self.current_letter = "أَ"
        self.setup_ui()

    def setup_ui(self):
        # Large letter display
        self.letter_label = tk.Label(
            self.root,
            text=self.current_letter,
            font=("Arial", 120),
            fg="black"
        )
        self.letter_label.pack(pady=40)

        # Frame for recording buttons
        button_frame = tk.Frame(self.root)
        button_frame.pack(pady=20)

        # Start Recording button
        self.start_button = tk.Button(
            button_frame,
            text="Start Recording",
            font=("Arial", 16),
            command=self.start_recording,
            bg="lightgreen",
            padx=20,
            pady=10
        )
        self.start_button.pack(side=tk.LEFT, padx=10)

        # Stop Recording button (initially disabled)
        self.stop_button = tk.Button(
            button_frame,
            text="Stop Recording",
            font=("Arial", 16),
            command=self.stop_recording,
            bg="lightcoral",
            padx=20,
            pady=10,
            state=tk.DISABLED
        )
        self.stop_button.pack(side=tk.LEFT, padx=10)

        # Result label (True/False)
        self.result_label = tk.Label(
            self.root,
            text="",
            font=("Arial", 24),
            fg="green"
        )
        self.result_label.pack(pady=20)

        # Entry to change the displayed letter
        entry_frame = tk.Frame(self.root)
        entry_frame.pack(pady=10)
        tk.Label(entry_frame, text="Enter Arabic letter:").pack(side=tk.LEFT, padx=5)
        self.letter_entry = tk.Entry(entry_frame, font=("Arial", 14))
        self.letter_entry.pack(side=tk.LEFT, padx=5)
        self.letter_entry.bind("<Return>", self.update_letter)
        tk.Button(entry_frame, text="Set", command=self.update_letter).pack(side=tk.LEFT, padx=5)

    def start_recording(self):
        """Called when Start button is pressed."""
        self.result_label.config(text="")          # Clear previous result
        self.start_button.config(state=tk.DISABLED)
        self.stop_button.config(state=tk.NORMAL)
        # Start recording (this is non‑blocking)
        self.recorder.start_recording()

    def stop_recording(self):
        """Called when Stop button is pressed."""
        self.stop_button.config(state=tk.DISABLED)
        self.start_button.config(state=tk.DISABLED, text="Processing...")
        # Stop recording and get audio data (this is fast)
        audio = self.recorder.stop_recording()

        if len(audio) == 0:
            messagebox.showwarning("No audio", "No audio recorded. Please try again.")
            self.reset_buttons()
            return

        # Run prediction in a separate thread to keep GUI responsive
        thread = threading.Thread(target=self.predict_audio, args=(audio,))
        thread.daemon = True
        thread.start()

    def predict_audio(self, audio):
        """Run prediction (blocking) and update GUI with result."""
        try:
            predicted = self.predictor.predict(audio)
            print(f"Predicted: '{predicted}'")
            is_correct = (predicted == self.current_letter)
            self.root.after(0, self.show_result, is_correct, predicted)
        except Exception as e:
            self.root.after(0, messagebox.showerror, "Prediction Error", str(e))
        finally:
            self.root.after(0, self.reset_buttons)

    def show_result(self, is_correct, predicted):
        if is_correct:
            self.result_label.config(text="✅ True", fg="green")
        else:
            self.result_label.config(
                text=f"❌ False (predicted: {predicted})",
                fg="red"
            )

    def reset_buttons(self):
        self.start_button.config(state=tk.NORMAL, text="Start Recording")
        self.stop_button.config(state=tk.DISABLED)

    def update_letter(self, event=None):
        new_letter = self.letter_entry.get().strip()
        if new_letter:
            self.current_letter = new_letter
            self.letter_label.config(text=self.current_letter)
            self.letter_entry.delete(0, tk.END)
            self.result_label.config(text="")  # Clear previous result

if __name__ == "__main__":
    root = tk.Tk()
    app = LetterTesterApp(root)
    root.mainloop()