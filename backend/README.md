# Circe Backend

This directory contains the FastAPI server for the Circe intelligent monitoring system. It provides real-time data synchronization, AI-powered health analysis, and alert management.

## Requirements
- Python 3.10+
- Dependencies listed in `requirements.txt`

## Setup
1. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
2. Configure environment variables:
   Copy `.env.example` to `.env` and fill in the required keys (e.g., database URI, external API keys).
3. Run the development server:
   ```bash
   uvicorn app.main:app --reload
   ```

## Architecture
- **Routers**: Endpoints for authentication, devices, measurements, and alerts.
- **Services**: Business logic, including integration with external APIs.
- **Database**: SQLite (default) for local storage.
