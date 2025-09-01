const path = require('path');

module.exports = {
  entry: './src/main/resources/static/js/otel-init.js',
  output: {
    filename: 'otel-bundle.js',
    path: path.resolve(__dirname, 'src/main/resources/static/js'),
  },
  mode: 'production'
};
