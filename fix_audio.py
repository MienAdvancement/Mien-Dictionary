import os
from pydub import AudioSegment, effects

# --- PATHS ---
input_folder = r"D:\Mien\Language\Dictionary\dictionary_app\assets\audio"
output_folder = r"D:\Mien\Language\Dictionary\dictionary_app\assets\audio_fixed"

if not os.path.exists(output_folder):
    os.makedirs(output_folder)

def match_target_amplitude(sound, target_dBFS):
    change_in_dBFS = target_dBFS - sound.dBFS
    return sound.apply_gain(change_in_dBFS)

print("Running Heavy Duty Normalization...")

files = [f for f in os.listdir(input_folder) if f.endswith(('.wav', '.mp3'))]

for filename in files:
    try:
        path = os.path.join(input_folder, filename)
        sound = AudioSegment.from_file(path)

        # 1. Strip silence from start and end (helps the scanner)
        sound = effects.strip_silence(sound)

        # 2. Match to a professional loudness standard (-20.0 is a good target)
        normalized_sound = match_target_amplitude(sound, -20.0)

        # 3. Prevent "Loud" files from distorting (Limiter)
        if normalized_sound.max_dBFS > -1.0:
            normalized_sound = normalized_sound - (normalized_sound.max_dBFS + 1.0)

        normalized_sound.export(os.path.join(output_folder, filename), format="wav")
        print(f"✅ Fixed Volume: {filename}")
    except Exception as e:
        print(f"❌ Error: {filename} - {e}")

print("\nDone! Now move the files from 'audio_fixed' to 'audio' and replace the old ones.")