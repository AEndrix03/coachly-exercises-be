import httpx

class OllamaClient:
    def __init__(self, base_url, model, timeout=300): self.base_url=base_url.rstrip('/'); self.model=model; self.timeout=timeout
    def tags(self): return httpx.get(self.base_url+"/api/tags", timeout=self.timeout).raise_for_status().json()
    def health(self):
        r=httpx.get(self.base_url+"/api/tags",timeout=self.timeout); return r.is_success
    def chat(self, prompt, schema):
        payload={"model":self.model,"messages":[{"role":"system","content":"Return only JSON conforming to the supplied schema."},{"role":"user","content":prompt}],"stream":False,"format":schema,"options":{"temperature":0.1,"seed":42}}
        return httpx.post(self.base_url+"/api/chat",json=payload,timeout=self.timeout).raise_for_status().json()
