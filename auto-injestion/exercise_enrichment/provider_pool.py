import json, threading, time
from collections import deque
from concurrent.futures import ThreadPoolExecutor, as_completed
from .gemini import GeminiClient

class RateLimitedGemini:
    def __init__(self, api_key, model, rpm=29):
        self.client=GeminiClient(api_key, model); self.limit=rpm; self.lock=threading.Lock(); self.calls=deque()
    def chat(self, prompt, schema):
        with self.lock:
            while True:
                now=time.monotonic()
                while self.calls and now-self.calls[0] >= 60: self.calls.popleft()
                if len(self.calls) < self.limit: break
                time.sleep(max(0.5, 60-(now-self.calls[0])+1))
            self.calls.append(time.monotonic())
            return self.client.chat(prompt,schema)

class GeminiPool:
    def __init__(self, api_key, models):
        self.workers=[RateLimitedGemini(api_key,m) for m in models]
    def process(self, records, schema, handler):
        results=[]
        def task(index, record, worker):
            prompt="""Sei un revisore tecnico di un catalogo di esercizi. Arricchisci davvero il record: non restituire proposed vuoto. Mantieni i valori corretti, completa translations in italiano e inglese con descrizione, executionTips e safetyTips. Non inventare UUID, codici di catalogo o percentuali muscolari. Se un valore non è determinabile, conserva quello originale e usa unresolved_issues. Restituisci solo JSON conforme allo schema.\n\nINPUT:\n"""+json.dumps({"original":record,"schema":schema},default=str,ensure_ascii=False)
            for attempt in range(3):
                try: return index,handler(worker.chat(prompt,schema),record)
                except Exception as exc:
                    print(f"[enrich] {record.get('id')} {type(exc).__name__}: {exc}",flush=True)
                    if "429" not in str(exc) or attempt==2: return index,exc
                    time.sleep(60)
        with ThreadPoolExecutor(max_workers=len(self.workers)) as pool:
            futures=[pool.submit(task,i,r,self.workers[i%len(self.workers)]) for i,r in enumerate(records)]
            for future in as_completed(futures): results.append(future.result())
        return [x[1] for x in sorted(results)]
