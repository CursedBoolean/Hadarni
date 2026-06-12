# evaluate_ngrok.py
# Tests the RAG Flask/ngrok server against the shared test suite.
#
# Usage:
#   python evaluate_ngrok.py https://xxxx.ngrok-free.app
#   python evaluate_ngrok.py https://xxxx.ngrok-free.app --output ngrok_results18.json

import os, json, time, argparse, requests
from shared_test_cases import get_flat_cases

def test_endpoint(ngrok_url: str, output_file: str):
    cases   = get_flat_cases()
    results = []

    print("=" * 60)
    print(f"Testing RAG endpoint — {len(cases)} cases")
    print("=" * 60)

    for c in cases:
        tag = "correct" if c["is_correct"] else "mistake"
        print(f"  [{c['en']} / {tag}] spoken: {c['spoken_text']}")

        payload = {
            "target_letter":      c["ar"],        # Arabic char — v3 format
            "is_correct":         c["is_correct"],
            "child_name":         c["child_name"],
            "spoken_text":        c["spoken_text"],
            "streak":             0,
            "previous_mistakes":  0,
        }

        try:
            r       = requests.post(f"{ngrok_url}/feedback", json=payload, timeout=10)
            res_json = r.json()
        except Exception as e:
            res_json = {"error": str(e)}

        results.append({
            "target_letter_ar": c["ar"],
            "target_letter_en": c["en"],
            "type":             tag,
            "spoken_text":      c["spoken_text"],
            "payload":          payload,
            "response":         res_json,
        })
        time.sleep(0.3)

    with open(output_file, "w", encoding="utf-8") as f:
        json.dump(results, f, ensure_ascii=False, indent=2)

    ok = [r for r in results if "error" not in r.get("response", {})]
    print(f"\n✅ Done. {len(ok)}/{len(results)} successful → {output_file}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("url",    help="ngrok URL e.g. https://xxxx.ngrok-free.app")
    parser.add_argument("--output", default="ngrok_results18.json")
    args = parser.parse_args()
    test_endpoint(args.url.rstrip("/"), args.output)
