from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.modules.premios.router import router as premios_router
from app.modules.admin.router import router as admin_router

app = FastAPI(title=settings.PROJECT_NAME, version="1.0.0")

#permitir que angular pueda consumir esta api local host 4200
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:4200","http://127.0.0.1:4200"],
    allow_methods=["*"],
    allow_headers=["*"],
    allow_credentials=True
)

@app.get("/")
def home():
    return {"message": "Bienvenido al Sistema Web de Apuestas","project": settings.PROJECT_NAME}

@app.get("/health")
def health_check():
    return {"status": "ok","database": "configurada"}

#rutas principales del proceso 6 
app.include_router(premios_router, prefix=f"{settings.API_PREFIX}/premios", tags=["Premios"])

app.include_router(admin_router, prefix=f"{settings.API_PREFIX}/admin", tags=["Administracion"])
