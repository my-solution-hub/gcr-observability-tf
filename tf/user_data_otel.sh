#!/bin/bash
yum update -y

# Install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm

# Download and install OpenTelemetry Collector
wget https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v0.89.0/otelcol-contrib_0.89.0_linux_amd64.tar.gz
tar -xzf otelcol-contrib_0.89.0_linux_amd64.tar.gz
mv otelcol-contrib /usr/local/bin/

# Create OpenTelemetry Collector configuration
mkdir -p /etc/otelcol-contrib
cat > /etc/otelcol-contrib/config.yaml << 'EOF'
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

processors:
  batch:
  memory_limiter:
    limit_mib: 512

exporters:
  awscloudwatchmetrics:
    region: ${aws_region}
    namespace: "ObservabilityDemo"
    dimension_rollup_option: "NoDimensionRollup"
    metric_declarations:
      - dimensions: [[service.name], [service.name, service.version]]
        metric_name_selectors:
          - ".*"

  awsxray:
    region: ${aws_region}

  awscloudwatchlogs:
    region: ${aws_region}
    log_group_name: "/aws/otel/observability-demo"
    log_stream_name: "otel-collector"

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [awsxray]
    
    metrics:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [awscloudwatchmetrics]
    
    logs:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [awscloudwatchlogs]

  extensions: []
EOF

# Create systemd service
cat > /etc/systemd/system/otel-collector.service << 'EOF'
[Unit]
Description=OpenTelemetry Collector
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/otelcol-contrib --config=/etc/otelcol-contrib/config.yaml
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Start and enable the service
systemctl daemon-reload
systemctl enable otel-collector
systemctl start otel-collector

# Create log group if it doesn't exist
aws logs create-log-group --log-group-name "/aws/otel/observability-demo" --region ${aws_region} || true
