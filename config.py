import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

class Config:
    DB_USER = os.getenv("DB_USER", "finpilot_user")
    DB_PASSWORD = os.getenv("DB_PASSWORD", "SASUMETHA@2014")
    DB_DSN = os.getenv("DB_DSN", "localhost:1521/XEPDB1")
    SECRET_KEY = os.getenv("SECRET_KEY", "finpilot-super-secret-key-2026")
