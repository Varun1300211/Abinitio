import os
import google.generativeai as genai

def list_models(api_key=None):
    api_key = api_key or os.getenv("GEMINI_API_KEY")
    if not api_key:
        raise RuntimeError("No API key provided")
    genai.configure(api_key=api_key)

    models = genai.list_models()
    for m in models:
        print(f"Model name: {m.name}")
        print(f"Supported methods: {m.supported_generation_methods}")
        print()

if __name__ == "__main__":
    list_models()
