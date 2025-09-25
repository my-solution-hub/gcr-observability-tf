import requests
import time
import random
import logging
import os
import sys

logging.basicConfig(level=logging.INFO, handlers=[logging.StreamHandler(sys.stdout)])
logger = logging.getLogger(__name__)

HELLO_SERVICE_URL = os.getenv('HELLO_SERVICE_URL', 'http://hello-service:8080')
WORLD_SERVICE_URL = os.getenv('WORLD_SERVICE_URL', 'http://world-service:5000')
INTERVAL_MIN = int(os.getenv('INTERVAL_MIN', '5'))
INTERVAL_MAX = int(os.getenv('INTERVAL_MAX', '15'))

def generate_traffic():
    endpoints = [
        f"{HELLO_SERVICE_URL}/",
        f"{HELLO_SERVICE_URL}/api/hello",
        f"{WORLD_SERVICE_URL}/",
        f"{WORLD_SERVICE_URL}/api/data",
        f"{WORLD_SERVICE_URL}/health"
    ]
    
    while True:
        try:
            endpoint = random.choice(endpoints)
            response = requests.get(endpoint, timeout=10)
            logger.info(f"Request to {endpoint} - Status: {response.status_code}")
            
        except Exception as e:
            logger.error(f"Request failed to {endpoint}: {e}")
        
        sleep_time = random.randint(INTERVAL_MIN, INTERVAL_MAX)
        time.sleep(sleep_time)

if __name__ == '__main__':
    logger.info("Starting traffic generator...")
    generate_traffic()
