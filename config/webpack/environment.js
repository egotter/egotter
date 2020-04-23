const { environment } = require('@rails/webpacker')

const eslint = require('./loaders/eslint')
environment.loaders.append('eslint', eslint)

module.exports = environment
