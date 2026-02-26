from fastapi import FastAPI
from fastapi.responses import JSONResponse

app = FastAPI(title="Dijitle API", version="1.0.0")

@app.get("/")
async def root():
    return {"message": "Welcome to Dijitle API"}

@app.get("/health")
async def health():
    return {"status": "healthy"}

@app.get("/api/v1/status")
async def status():
    return {
        "service": "dijitle-api",
        "status": "running",
        "version": "1.0.0"
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
