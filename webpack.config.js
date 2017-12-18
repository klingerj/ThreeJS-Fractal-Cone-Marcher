const path = require('path');

module.exports = {
  entry: path.join(__dirname, "src/main"),
  output: {
    path: path.join(__dirname, "build"),
    filename: "bundle.js"
  },
  module: {
    loaders: [
      {
        test: /\.js$/,
        exclude: /(node_modules|bower_components)/,
        loader: 'babel-loader',
        query: {
          presets: ['es2015']
        }
      },
      {
        test: /\.glsl$/,
        loader: 'webpack-glsl-loader'
      },
      {
        test: /\.(obj|bmp|gif|png)$/,
        loader: 'file-loader?name=./assets/[name]-[hash:6].[ext]'
      }
    ]
  },
  devtool: 'source-map',
  devServer: {
    port: 7000
  }
}