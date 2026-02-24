import csv
import json

CSV_PATH = r"assets/data/mien_translation_feb23.csv"
JSON_PATH = r"assets/data/mien_translation_feb23.json"

with open(CSV_PATH, encoding="utf-8-sig", newline="") as f:
    rows = list(csv.DictReader(f))

with open(JSON_PATH, "w", encoding="utf-8") as f:
    json.dump(rows, f, ensure_ascii=False, indent=2)

print("JSON updated successfully.")
