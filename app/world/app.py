from fastapi import FastAPI, HTTPException
from fastapi.responses import HTMLResponse
import pymysql
import redis
import json
import os
import logging
import sys
from opentelemetry import trace

# Configure logging
logging.basicConfig(level=logging.INFO, handlers=[logging.StreamHandler(sys.stdout)])
logger = logging.getLogger(__name__)

app = FastAPI(title="World Service", version="1.0.0")
tracer = trace.get_tracer(__name__)

# Redis connection
redis_client = redis.Redis(
    host=os.getenv('REDIS_HOST', 'localhost'),
    port=int(os.getenv('REDIS_PORT', '6379')),
    decode_responses=True,
    ssl=True if os.getenv('REDIS_SSL', 'true').lower() == 'true' else False
)

def get_db_connection():
    return pymysql.connect(
        host=os.getenv('DB_HOST', 'localhost'),
        port=int(os.getenv('DB_PORT', '3306')),
        user=os.getenv('DB_USER', 'admin'),
        password=os.getenv('DB_PASSWORD', 'changeme123!'),
        database=os.getenv('DB_NAME', 'observability'),
        charset='utf8mb4'
    )

def init_database():
    try:
        connection = get_db_connection()
        with connection.cursor() as cursor:
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS world_data (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    message VARCHAR(255) NOT NULL,
                    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
            
            cursor.execute("SELECT COUNT(*) FROM world_data")
            if cursor.fetchone()[0] == 0:
                messages = [
                    "Hello from Flask World service!",
                    "Data from MySQL database", 
                    "Flask observability demo working"
                ]
                for msg in messages:
                    cursor.execute("INSERT INTO world_data (message) VALUES (%s)", (msg,))
            connection.commit()
        connection.close()
        logger.info("Database initialized")
        return True
    except Exception as e:
        logger.error(f"Database init error: {e}")
        return False

@app.get("/", response_class=HTMLResponse)
def home():
    return "<h1>FastAPI World Service</h1><p><a href='/api/data'>Get Data</a></p><p><a href='/health'>Health</a></p>"

@app.get("/api/data")
def get_data():
    cache_key = "world_data"
    
    try:
        # Check Redis cache first
        cached_data = redis_client.get(cache_key)
        if cached_data:
            logger.info("Cache hit - returning cached data")
            data = json.loads(cached_data)
            data['source'] = 'redis_cache'
            
            # Add bodysize attribute to current span
            span = trace.get_current_span()
            body_json = json.dumps(data)
            body_size = len(body_json.encode('utf-8'))
            logger.info(f"Setting bodysize attribute: {body_size}")
            span.set_attribute("bodysize", body_size)
            logger.info(f"Span context: {span.get_span_context()}")
            
            return data
        
        logger.info("Cache miss - fetching from database")
        
        # Get data from database
        connection = get_db_connection()
        with connection.cursor() as cursor:
            cursor.execute("SELECT message, timestamp FROM world_data ORDER BY RAND() LIMIT 1")
            result = cursor.fetchone()
        connection.close()
        
        data = {
            'message': result[0] if result else 'No data found',
            'timestamp': str(result[1]) if result else '',
            'source': 'mysql_database',
            'service': 'fastapi-world'
        }
        
        # Cache the result for 5 minutes (300 seconds)
        redis_client.setex(cache_key, 300, json.dumps(data))
        logger.info(f"Data cached for 5 minutes: {data['message']}")
        
        # Add bodysize attribute to current span
        span = trace.get_current_span()
        body_json = json.dumps(data)
        body_size = len(body_json.encode('utf-8'))
        logger.info(f"Setting bodysize attribute: {body_size}")
        
        # Try setting on both current span and any parent spans
        span.set_attribute("bodysize", body_size)
        span.set_attribute("custom.bodysize", body_size)  # Try with custom prefix
        
        # Also try setting on the tracer context
        with tracer.start_as_current_span("bodysize_calculation") as custom_span:
            custom_span.set_attribute("bodysize", body_size)
        
        logger.info(f"Span context: {span.get_span_context()}")
        logger.info(f"Span is recording: {span.is_recording()}")
        
        return data
        
    except Exception as e:
        logger.error(f"Error: {e}")
        raise HTTPException(status_code=500, detail={'error': str(e), 'service': 'fastapi-world'})

@app.get("/health")
def health():
    try:
        connection = get_db_connection()
        connection.close()
        
        # Test Redis connection
        redis_client.ping()
        
        logger.info("Health check OK")
        return 'OK'
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        raise HTTPException(status_code=500, detail=f'Error: {str(e)}')

if __name__ == '__main__':
    import time
    import uvicorn
    time.sleep(10)  # Wait for database
    init_database()
    uvicorn.run(app, host='0.0.0.0', port=5000)
