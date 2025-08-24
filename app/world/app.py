from flask import Flask, jsonify, render_template_string
import pymysql
import os
import time
import json
import logging
import sys

# Configure logging to stdout
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[logging.StreamHandler(sys.stdout)]
)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Database configuration from environment variables
DB_HOST = os.getenv('DB_HOST', 'localhost')
DB_PORT = int(os.getenv('DB_PORT', '3306'))
DB_NAME = os.getenv('DB_NAME', 'observability')
DB_USER = os.getenv('DB_USER', 'admin')
DB_PASSWORD = os.getenv('DB_PASSWORD', 'changeme123!')

def get_db_connection():
    logger.debug(f"Connecting to database at {DB_HOST}:{DB_PORT}")
    return pymysql.connect(
        host=DB_HOST,
        port=DB_PORT,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME,
        charset='utf8mb4'
    )

def init_database():
    """Initialize database with sample data"""
    try:
        logger.info("Initializing database...")
        connection = get_db_connection()
        with connection.cursor() as cursor:
            # Create table if not exists
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS world_data (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    message VARCHAR(255) NOT NULL,
                    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
            
            # Insert sample data if table is empty
            cursor.execute("SELECT COUNT(*) FROM world_data")
            count = cursor.fetchone()[0]
            
            if count == 0:
                logger.info("Inserting sample data into database")
                sample_data = [
                    "Hello from the World service!",
                    "Data retrieved from MySQL database",
                    "Observability demo is working perfectly",
                    "Redis cache integration active",
                    "Multi-tier architecture demonstration"
                ]
                
                for message in sample_data:
                    cursor.execute(
                        "INSERT INTO world_data (message) VALUES (%s)",
                        (message,)
                    )
            
            connection.commit()
        connection.close()
        logger.info("Database initialized successfully")
        return True
    except Exception as e:
        logger.error(f"Database initialization error: {e}")
        return False

@app.route('/')
def home():
    logger.info("Home page requested")
    template = """
    <html>
    <head><title>World Service</title></head>
    <body>
        <h1>World Service - Observability Demo</h1>
        <p><a href="/api/data">Get Data from Database</a></p>
        <p><a href="/health">Health Check</a></p>
        <p>This service retrieves data from MySQL database.</p>
    </body>
    </html>
    """
    return render_template_string(template)

@app.route('/api/data')
def get_data():
    """Get random data from database"""
    logger.info("API data request received")
    try:
        connection = get_db_connection()
        with connection.cursor() as cursor:
            cursor.execute("SELECT message, timestamp FROM world_data ORDER BY RAND() LIMIT 1")
            result = cursor.fetchone()
            
        connection.close()
        
        if result:
            response_data = {
                'message': result[0],
                'timestamp': str(result[1]),
                'source': 'mysql_database',
                'service': 'world'
            }
            logger.info(f"Returning data: {result[0]}")
            return json.dumps(response_data)
        else:
            logger.warning("No data found in database")
            return json.dumps({
                'message': 'No data found', 
                'source': 'mysql_database',
                'service': 'world'
            })
            
    except Exception as e:
        logger.error(f"Database query error: {e}")
        return json.dumps({
            'error': str(e), 
            'source': 'mysql_database',
            'service': 'world'
        }), 500

@app.route('/health')
def health():
    """Health check endpoint"""
    logger.debug("Health check requested")
    try:
        # Test database connection
        connection = get_db_connection()
        connection.close()
        logger.debug("Health check passed")
        return 'OK'
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        return f'Database connection failed: {str(e)}', 500

if __name__ == '__main__':
    logger.info("Starting World Service...")
    logger.info(f"Database: {DB_HOST}:{DB_PORT}/{DB_NAME}")
    
    # Wait a bit for database to be ready
    time.sleep(10)
    
    # Initialize database
    if init_database():
        logger.info("Database ready, starting Flask app...")
        app.run(host='0.0.0.0', port=5000, debug=True)
    else:
        logger.error("Failed to initialize database")
        exit(1)
