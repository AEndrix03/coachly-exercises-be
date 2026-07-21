import httpx

class GeminiClient:
    def __init__(self, api_key, model="gemini-2.5-flash", timeout=90):
        self.api_key, self.model, self.timeout = api_key, model, timeout
    def chat(self, prompt, schema):
        url=f"https://generativelanguage.googleapis.com/v1beta/models/{self.model}:generateContent"
        schema=dict(schema)
        schema.setdefault("properties", {key:{"type":"string"} for key in schema.get("required", [])})
        payload={"contents":[{"parts":[{"text":prompt}]}],"generationConfig":{"temperature":0.1,"maxOutputTokens":1800,"thinkingConfig":{"thinkingLevel":"high"},"responseMimeType":"application/json","responseSchema":schema}}
        response=httpx.post(url,headers={"x-goog-api-key":self.api_key},json=payload,timeout=self.timeout,verify=False); response.raise_for_status()
        data=response.json(); return {"response":data["candidates"][0]["content"]["parts"][0]["text"],"usage":data.get("usageMetadata",{})}
