import os
from dotenv import load_dotenv

load_dotenv()


class Settings:
  
    PROJECT_NAME: str = os.getenv("PROJECT_NAME", "Sistema Web de Apuestas")
    API_PREFIX: str = os.getenv("API_PREFIX", "/api")
    DATABASE_URL: str = os.getenv(
        "DATABASE_URL",
        "postgresql://postgres:admin@localhost:5432/pronosticos_futbol"
    )


settings = Settings()