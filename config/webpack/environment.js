const { environment } = require('@rails/webpacker')

const erb = require('./loaders/erb')
environment.loaders.prepend('erb', erb)

const eslint = require('./loaders/eslint')
environment.loaders.append('eslint', eslint)

module.exports = environment
