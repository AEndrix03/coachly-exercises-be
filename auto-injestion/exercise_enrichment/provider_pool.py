import json, threading, time
from concurrent.futures import ThreadPoolExecutor, as_completed
from .gemini import GeminiClient

class RateLimitedGemini:
    def __init__(self, api_key, model, rpm=30):
        self.client=GeminiClient(api_key, model); self.interval=60/rpm; self.lock=threading.Lock(); self.last=0
    def chat(self, prompt, schema):
        with self.lock:
            delay=self.interval-(time.monotonic()-self.last)
            if delay>0: time.sleep(delay)
            try: return self.client.chat(prompt,schema)
            finally: self.last=time.monotonic()

class GeminiPool:
    def __init__(self, api_key, models):
        self.workers=[RateLimitedGemini(api_key,m) for m in models]
    def process(self, records, schema, handler):
        results=[]
        def task(index, record, worker):
            prompt=json.dumps({"original":record,"schema":schema},default=str,ensure_ascii=False)
            for attempt in range(3):
                try: return index,handler(worker.chat(prompt,schema),record)
                except Exception as exc:
                    if "429" not in str(exc) or attempt==2: return index,exc
                    time.sleep(60)
        with ThreadPoolExecutor(max_workers=len(self.workers)) as pool:
            futures=[pool.submit(task,i,r,self.workers[i%len(self.workers)]) for i,r in enumerate(records)]
            for future in as_completed(futures): results.append(future.result())
        return [x[1] for x in sorted(results)]
