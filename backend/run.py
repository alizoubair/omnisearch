#!/usr/bin/env python3
"""
Omnipaper Backend API - Development Server
Run this script to start the Omnipaper AI document search backend
"""

import uvicorn
import os
from pathlib import Path

if __name__ == "__main__":
    # Ensure we're in the right directory
    os.chdir(Path(__file__).parent)
    
    # Run the server
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8002,
        reload=True,
        log_level="info",
        access_log=True
    )