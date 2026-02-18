from transformers import WhisperForConditionalGeneration

model = WhisperForConditionalGeneration.from_pretrained("./whisper-finetuned-arabic")
print(model.generation_config.forced_decoder_ids)