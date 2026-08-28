from dataclasses import dataclass
import os

@dataclass(frozen=True)
class AIResponse:
    provider: str
    model: str
    text: str

class AIGateway:
    """Provider-neutral AI boundary. Network calls are intentionally opt-in via adapters."""
    def __init__(self, provider: str | None = None, model: str | None = None):
        self.provider = provider or os.getenv("BENNU_AI_PROVIDER", "none")
        self.model = model or os.getenv("BENNU_AI_MODEL", "")

    def status(self) -> dict:
        return {"provider": self.provider, "model": self.model, "configured": self.provider != "none"}

    def complete(self, prompt: str) -> AIResponse:
        if not prompt.strip():
            raise ValueError("prompt is required")
        if self.provider == "none":
            raise RuntimeError("AI provider is not configured")
        raise NotImplementedError("Configure a provider adapter before enabling network inference")
