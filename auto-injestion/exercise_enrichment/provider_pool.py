import json
import threading
import time
from collections import deque
from concurrent.futures import ThreadPoolExecutor, as_completed

from .gemini import GeminiClient


def _compact_translations(value):
    if isinstance(value, str):
        try:
            value = json.loads(value)
        except json.JSONDecodeError:
            return {}
    if not isinstance(value, dict):
        return {}
    compact = {}
    for language in ("it", "en"):
        source = value.get(language, {})
        if isinstance(source, dict):
            compact[language] = {
                "name": str(source.get("name", ""))[:120],
                "description": str(source.get("description", ""))[:500],
            }
    return compact


class RateLimitedGemini:
    """Independent rolling RPM/TPM limiter for one Gemini model."""

    def __init__(self, api_key, model, rpm=29, tpm=16000):
        self.client = GeminiClient(api_key, model)
        self.limit, self.tpm = rpm, tpm
        self.lock = threading.Lock()
        self.calls, self.tokens = deque(), deque()

    def chat(self, prompt, schema):
        with self.lock:
            while True:
                now = time.monotonic()
                while self.calls and now - self.calls[0] >= 60:
                    self.calls.popleft()
                while self.tokens and now - self.tokens[0][0] >= 60:
                    self.tokens.popleft()

                estimated = max(1024, len(prompt) // 4 + 2000)
                used = sum(count for _, count in self.tokens)
                if len(self.calls) < self.limit and used + estimated <= self.tpm:
                    break

                waits = []
                if len(self.calls) >= self.limit:
                    waits.append(61 - (now - self.calls[0]))
                if used + estimated > self.tpm:
                    waits.append(61 - (now - self.tokens[0][0]))
                wait_for = max(0.5, max(waits))
                print(f"[quota] model={self.client.model} waiting={wait_for:.1f}s", flush=True)
                time.sleep(wait_for)

            self.calls.append(time.monotonic())

        # Do not hold the quota lock during network I/O: this model is still
        # serialized by the caller, while the other model can run concurrently.
        result = self.client.chat(prompt, schema)
        actual = result.get("usage", {}).get("totalTokenCount", estimated)
        with self.lock:
            self.tokens.append((time.monotonic(), actual))
            print(
                f"[quota] model={self.client.model} tokens={actual} "
                f"rpm={len(self.calls)}/{self.limit} "
                f"tpm={sum(count for _, count in self.tokens)}/{self.tpm}",
                flush=True,
            )
        return result


class GeminiPool:
    def __init__(self, api_key, models):
        self.workers = [RateLimitedGemini(api_key, model) for model in models]

    def process(self, records, schema, handler):
        results = []

        def task(index, source_record, worker):
            record = {
                key: source_record.get(key)
                for key in (
                    "id", "name", "difficulty", "mechanics", "force", "unilateral",
                    "bodyweight", "overall_risk", "spotter_required",
                    "_allowed_catalogs", "_candidate_variations",
                )
            }
            record["translations"] = _compact_translations(source_record.get("translations"))
            prompt = """Sei un revisore tecnico di un catalogo di esercizi.
Restituisci esclusivamente JSON conforme allo schema e usa soltanto codici presenti in _allowed_catalogs e UUID presenti in _candidate_variations. Non inventare percentuali di attivazione muscolare.

Regole di affidabilita e qualita:
1. Verifica internamente che ogni campo sia meccanicamente coerente con il nome, i dati originali e l'esercizio realmente noto. Non mostrare il ragionamento.
2. I cataloghi includono codice e denominazioni reali: scegli un codice solo se denominazione e funzione corrispondono esattamente. Non usare il codice semanticamente piu vicino come sostituto di un attrezzo, muscolo o categoria assente.
3. Non inventare: non aggiungere un muscolo, attrezzo, tag, variante, rischio, istruzione o descrizione che non sia specificamente plausibile per quell'esercizio. Se non sei sicuro, conserva il dato originale oppure lascia la proposta di quel campo vuota; non sostituirla con testo generico.
4. Non confondere esercizi con nomi simili, movimenti diversi, varianti, lati del corpo, macchine e attrezzi. Una variante e pertinente soltanto se modifica in modo reale presa, carico, attrezzo, angolo, lato o schema motorio.
5. Compila sempre italiano e inglese naturale, semanticamente equivalenti, senza campi inglesi vuoti. Non tradurre alla lettera se risulta innaturale.
6. description_it e description_en: una o due frasi fattuali e concise che identificano esattamente il movimento; niente marketing, preamboli, benefici generici, diagnosi o dettagli ripetuti.
7. execution_tips_it/en e safety_tips_it/en: 3-5 punti pratici, completi e specifici del gesto. Includi setup, traiettoria, respirazione/controllo quando pertinenti e i rischi tecnici reali; non ripetere la descrizione. Ogni punto deve restare sotto 22 parole.
8. Elenca in modo completo muscoli, categorie, attrezzatura e tag pertinenti usando solo i codici disponibili. Non aggiungere attrezzi opzionali come se fossero necessari, ne muscoli non coinvolti in modo rilevante.
9. Conserva e aggiungi solo varianti realmente pertinenti. Se serve un nuovo tag o esercizio, usa rispettivamente new_tag_candidates o new_exercise_candidates, ma solo quando la denominazione e reale e specifica.

INPUT:
""" + json.dumps({"original": record}, default=str, ensure_ascii=False)
            for attempt in range(3):
                try:
                    return index, handler(worker.chat(prompt, schema), record)
                except Exception as exc:
                    print(f"[enrich] {record.get('id')} {type(exc).__name__}: {exc}", flush=True)
                    transient = (
                        hasattr(exc, "retry_after")
                        or type(exc).__name__ in {"ReadTimeout", "ConnectError"}
                        or "503" in str(exc)
                        or "500" in str(exc)
                    )
                    if not transient or attempt == 2:
                        return index, exc
                    time.sleep(getattr(exc, "retry_after", (5, 20, 60)[attempt]))

        with ThreadPoolExecutor(max_workers=len(self.workers)) as pool:
            futures = [
                pool.submit(task, index, record, self.workers[index % len(self.workers)])
                for index, record in enumerate(records)
            ]
            for future in as_completed(futures):
                results.append(future.result())
        return sorted(results)
