#!/bin/bash
yum update -y
yum install -y python3 python3-pip mysql

# Install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm

# Create application directory
mkdir -p /opt/world-app
cd /opt/world-app

# Create Flask application
cat > app.py << 'EOF'
from flask import Flask, jsonify
import pymysql
import os
import time

app = Flask(__name__)

# Database configuration
DB_HOST = '${db_endpoint}'
DB_NAME = '${db_name}'
DB_USER = '${db_user}'
DB_PASSWORD = '${db_password}'

def get_db_connection():
    return pymysql.connect(
        host=DB_HOST,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME,
        charset='utf8mb4'
    )

def init_database():
    try:
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
                sample_data = [
                    "Hello from the World service!",
                    "Data retrieved from MySQL database",
                    "Observability demo is working",
                    "Redis cache integration active"
                ]
                
                for message in sample_data:
                    cursor.execute(
                        "INSERT INTO world_data (message) VALUES (%s)",
                        (message,)
                    )
            
            connection.commit()
        connection.close()
        print("Database initialized successfully")
    except Exception as e:
        print(f"Database initialization error: {e}")

@app.route('/')
def home():
    return '<h1>World Service</h1><p><a href="/api/data">Get Data</a></p>'

@app.route('/api/data')
def get_data():
    try:
        connection = get_db_connection()
        with connection.cursor() as cursor:
            cursor.execute("SELECT message, timestamp FROM world_data ORDER BY RAND() LIMIT 1")
            result = cursor.fetchone()
            
        connection.close()
        
        if result:
            return jsonify({
                'message': result[0],
                'timestamp': str(result[1]),
                'source': 'mysql_database'
            })
        else:
            return jsonify({'message': 'No data found', 'source': 'mysql_database'})
            
    except Exception as e:
        return jsonify({'error': str(e), 'source': 'mysql_database'}), 500

@app.route('/health')
def health():
    return 'OK'

if __name__ == '__main__':
    # Wait for database to be ready
    time.sleep(30)
    init_database()
    app.run(host='0.0.0.0', port=5000)
EOF

# Create requirements.txt
cat > requirements.txt << 'EOF'
Flask==3.0.0
PyMySQL==1.1.0
EOF

# Install Python dependencies
pip3 install -r requirements.txt

# Create systemd service
cat > /etc/systemd/system/world-app.service << 'EOF'
[Unit]
Description=World Flask Application
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/world-app
ExecStart=/usr/bin/python3 /opt/world-app/app.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable world-app
systemctl start world-app
