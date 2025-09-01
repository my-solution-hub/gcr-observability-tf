// OpenTelemetry Web SDK Configuration using CDN
// Load OpenTelemetry from CDN
const script = document.createElement('script');
script.src = 'https://unpkg.com/@opentelemetry/api@1.7.0/build/esm/index.js';
script.type = 'module';
document.head.appendChild(script);

// Simple fetch instrumentation without full SDK
function initializeSimpleTracing() {
  // Basic tracing setup
  const originalFetch = window.fetch;
  
  window.fetch = function(...args) {
    const startTime = Date.now();
    console.log('OpenTelemetry: Starting fetch request', args[0]);
    
    return originalFetch.apply(this, args)
      .then(response => {
        const duration = Date.now() - startTime;
        console.log('OpenTelemetry: Fetch completed', {
          url: args[0],
          status: response.status,
          duration: duration + 'ms'
        });
        return response;
      })
      .catch(error => {
        const duration = Date.now() - startTime;
        console.log('OpenTelemetry: Fetch failed', {
          url: args[0],
          error: error.message,
          duration: duration + 'ms'
        });
        throw error;
      });
  };
}

// Initialize simple tracing
initializeSimpleTracing();
console.log('OpenTelemetry Web SDK initialized with basic instrumentation');
