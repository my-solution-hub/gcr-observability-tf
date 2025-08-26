// OpenTelemetry Web SDK Configuration
import { WebTracerProvider } from '@opentelemetry/sdk-trace-web';
import { Resource } from '@opentelemetry/resources';
import { SemanticResourceAttributes } from '@opentelemetry/semantic-conventions';
import { BatchSpanProcessor } from '@opentelemetry/sdk-trace-base';
import { OTLPTraceExporter } from '@opentelemetry/exporter-otlp-http';
import { getWebAutoInstrumentations } from '@opentelemetry/auto-instrumentations-web';
import { registerInstrumentations } from '@opentelemetry/instrumentation';

// Initialize the tracer provider
const provider = new WebTracerProvider({
  resource: new Resource({
    [SemanticResourceAttributes.SERVICE_NAME]: 'hello-service-web',
    [SemanticResourceAttributes.SERVICE_VERSION]: '1.0.0',
  }),
});

// Configure OTLP exporter
const exporter = new OTLPTraceExporter({
  url: '/api/traces', // Proxy through backend
});

// Add batch span processor
provider.addSpanProcessor(new BatchSpanProcessor(exporter));

// Register the provider
provider.register();

// Register auto-instrumentations
registerInstrumentations({
  instrumentations: [
    getWebAutoInstrumentations({
      '@opentelemetry/instrumentation-document-load': {
        enabled: true,
      },
      '@opentelemetry/instrumentation-user-interaction': {
        enabled: true,
      },
      '@opentelemetry/instrumentation-fetch': {
        enabled: true,
      },
      '@opentelemetry/instrumentation-xml-http-request': {
        enabled: true,
      },
    }),
  ],
});

console.log('OpenTelemetry Web SDK initialized');
