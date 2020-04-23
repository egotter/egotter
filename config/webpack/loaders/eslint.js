module.exports = {
  test: /\.js$/,
  loader: 'eslint-loader',
  enforce: 'pre',
  options: {failOnError: true, failOnWarning: false}
};
