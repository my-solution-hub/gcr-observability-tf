import { getWebAutoInstrumentations } from '@opentelemetry/auto-instrumentations-web';
import { WebTracerProvider } from '@opentelemetry/sdk-trace-web';
import { Resource } from '@opentelemetry/resources';
import { SemanticResourceAttributes } from '@opentelemetry/semantic-conventions';
import { BatchSpanProcessor } from '@opentelemetry/sdk-trace-base';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';
import { registerInstrumentations } from '@opentelemetry/instrumentation';

const provider = new WebTracerProvider({
  resource: new Resource({
    [SemanticResourceAttributes.SERVICE_NAME]: 'hello-service-web',
  }),
});

provider.addSpanProcessor(new BatchSpanProcessor(new OTLPTraceExporter({
  url: '/v1/traces',
})));

provider.register();

registerInstrumentations({
  instrumentations: [getWebAutoInstrumentations()],
});

console.log('OpenTelemetry auto-instrumentation initialized');
