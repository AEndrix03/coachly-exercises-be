import httpx


class GeminiRateLimitError(RuntimeError):
    def __init__(self, retry_after, detail):
        super().__init__(detail)
        self.retry_after = retry_after


class GeminiResponseError(RuntimeError):
    pass


class GeminiClient:
    def __init__(self, api_key, model="gemini-2.5-flash", timeout=90):
        self.api_key, self.model, self.timeout = api_key, model, timeout

    def chat(self, prompt, schema):
        url = f"https://generativelanguage.googleapis.com/v1beta/models/{self.model}:generateContent"
        schema = dict(schema)
        schema.setdefault("properties", {key: {"type": "string"} for key in schema.get("required", [])})
        payload = {
            "contents": [{"parts": [{"text": prompt}]}],
            "generationConfig": {
                "temperature": 0.1,
                "maxOutputTokens": 2000,
                # Gemma 4 exposes only minimal/high. Minimal preserves the
                # throughput required for the full dataset; grounding lives in
                # the prompt and deterministic validators rather than hidden
                # reasoning tokens.
                "thinkingConfig": {"thinkingLevel": "minimal"},
                "responseMimeType": "application/json",
                "responseSchema": schema,
            },
        }
        response = httpx.post(url, headers={"x-goog-api-key": self.api_key}, json=payload, timeout=self.timeout, verify=False)
        if response.status_code == 429:
            retry_after = response.headers.get("retry-after")
            try:
                retry_after = float(retry_after) if retry_after is not None else 60.0
            except ValueError:
                retry_after = 60.0
            raise GeminiRateLimitError(retry_after, f"Gemini 429 for {self.model}; retry after {retry_after:.0f}s")
        response.raise_for_status()
        data = response.json()
        candidate = (data.get("candidates") or [{}])[0]
        parts = candidate.get("content", {}).get("parts", [])
        text = "".join(part.get("text", "") for part in parts if part.get("text"))
        if not text:
            reason = candidate.get("finishReason", "unknown")
            raise GeminiResponseError(f"Gemini returned no JSON text (finishReason={reason})")
        if candidate.get("finishReason") == "MAX_TOKENS":
            raise GeminiResponseError("Gemini JSON was truncated at maxOutputTokens")
        return {"response": text, "usage": data.get("usageMetadata", {})}
