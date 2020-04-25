const path = require("path");

let configBase = {
    module: {
      rules: [
        {
          test: /\.js$/,
          exclude: path.join(__dirname, 'node_modules'),
          type: "javascript/auto",
          use: [
            {
              loader: 'babel-loader',
              options: {
                cacheDirectory: false
              }
            }
          ]
        }
      ]
    },
    devtool: 'source-map',
    externals: ['worker_threads','ws','perf_hooks'], // exclude nodejs
    resolve: {
      alias: {
        "fs": "html5-fs"
      },
      extensions: ['.js', '.jsx', '.css', '.json', 'otf', 'ttf', 'eot', 'svg'],
      modules: [
        'node_modules'
      ]
    },
    cache: true,
    context: __dirname
};

let configApp = Object.assign({}, configBase, {
    name: "App config",
    entry: "./src/index.js",
    output: {
      path: path.resolve(__dirname, "browser_build"),
      filename: "xmr-sample-app.js"
    },
});

module.exports = [
  configApp
];