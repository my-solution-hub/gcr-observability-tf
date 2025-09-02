import { getWebAutoInstrumentations } from '@opentelemetry/auto-instrumentations-web';
import { WebTracerProvider } from '@opentelemetry/sdk-trace-web';
import { Resource } from '@opentelemetry/resources';
import { SemanticResourceAttributes } from '@opentelemetry/semantic-conventions';
import { BatchSpanProcessor } from '@opentelemetry/sdk-trace-web';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';
import { AWSXRayPropagator } from '@opentelemetry/propagator-aws-xray';
import { AWSXRayIdGenerator } from '@opentelemetry/id-generator-aws-xray';
import { registerInstrumentations } from '@opentelemetry/instrumentation';

// Get dynamic values from meta tags or environment
const getResourceAttribute = (name, fallback) => {
  const meta = document.querySelector(`meta[name="${name}"]`);
  return meta ? meta.getAttribute('content') : fallback;
};

const provider = new WebTracerProvider({
  resource: new Resource({
    [SemanticResourceAttributes.SERVICE_NAME]: 'hello-frontend',
    [SemanticResourceAttributes.SERVICE_VERSION]: getResourceAttribute('service.version', '1.0.0'),
    [SemanticResourceAttributes.DEPLOYMENT_ENVIRONMENT]: getResourceAttribute('deployment.environment', 'dev'),
    'k8s.cluster.name': getResourceAttribute('k8s.cluster.name', 'unknown'),
    'k8s.namespace.name': getResourceAttribute('k8s.namespace.name', 'default'),
  }),
  idGenerator: new AWSXRayIdGenerator(),
});

provider.addSpanProcessor(new BatchSpanProcessor(new OTLPTraceExporter({
  url: '/v1/traces',
  headers: {
    'Content-Type': 'application/json',
  },
})));

// Register X-Ray propagator
provider.register({
  propagator: new AWSXRayPropagator(),
});

// Full auto-instrumentation with trace propagation
registerInstrumentations({
  instrumentations: getWebAutoInstrumentations({
    '@opentelemetry/instrumentation-user-interaction': {
      enabled: true,
    },
    '@opentelemetry/instrumentation-fetch': {
      enabled: true,
      propagateTraceHeaderCorsUrls: [/.*/],
      clearTimingResources: true,
    },
    '@opentelemetry/instrumentation-xml-http-request': {
      enabled: true,
      propagateTraceHeaderCorsUrls: [/.*/],
    },
  }),
});

console.log('OpenTelemetry with X-Ray propagation initialized');
