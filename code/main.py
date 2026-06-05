import os
from fastapi import FastAPI, HTTPException

app = FastAPI(title="CNZ Voting API")

votes: dict[str, int] = {}

REQUIRED_CONFIG = os.environ.get("APP_CONFIG_PATH", "/config/settings.conf")


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/ready")
def ready():
    if not os.path.exists(REQUIRED_CONFIG):
        raise HTTPException(status_code=503, detail=f"Config not found: {REQUIRED_CONFIG}")
    return {"status": "ready"}


@app.get("/votes")
def get_votes():
    return votes


@app.post("/votes/{talk}")
def vote(talk: str):
    votes[talk] = votes.get(talk, 0) + 1
    return {"talk": talk, "votes": votes[talk]}
