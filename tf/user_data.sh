#!/bin/bash
yum update -y
yum install -y httpd

# Start and enable httpd
systemctl start httpd
systemctl enable httpd

# Create a simple index page
cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Observability Demo</title>
</head>
<body>
    <h1>AWS China Observability Demo</h1>
    <h2>Instance: ${instance_name}</h2>
    <p>Timestamp: $(date)</p>
    <p>Region: $(curl -s http://169.254.169.254/latest/meta-data/placement/region)</p>
    <p>Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</p>
</body>
</html>
EOF

# Install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm
