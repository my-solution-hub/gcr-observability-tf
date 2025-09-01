from flask import Flask, jsonify
import pymysql
import redis
import json
import os
import logging
import sys

# Configure logging
logging.basicConfig(level=logging.INFO, handlers=[logging.StreamHandler(sys.stdout)])
logger = logging.getLogger(__name__)

app = Flask(__name__)

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

@app.route('/')
def home():
    return "<h1>Flask World Service</h1><p><a href='/api/data'>Get Data</a></p><p><a href='/health'>Health</a></p>"

@app.route('/api/data')
def get_data():
    cache_key = "world_data"
    
    try:
        # Check Redis cache first
        cached_data = redis_client.get(cache_key)
        if cached_data:
            logger.info("Cache hit - returning cached data")
            data = json.loads(cached_data)
            data['source'] = 'redis_cache'
            return jsonify(data)
        
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
            'service': 'flask-world'
        }
        
        # Cache the result for 5 minutes (300 seconds)
        redis_client.setex(cache_key, 300, json.dumps(data))
        logger.info(f"Data cached for 5 minutes: {data['message']}")
        
        return jsonify(data)
        
    except Exception as e:
        logger.error(f"Error: {e}")
        return jsonify({'error': str(e), 'service': 'flask-world'}), 500

@app.route('/health')
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
        return f'Error: {str(e)}', 500

if __name__ == '__main__':
    import time
    time.sleep(10)  # Wait for database
    init_database()
    app.run(host='0.0.0.0', port=5000)
