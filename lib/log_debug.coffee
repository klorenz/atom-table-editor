DEBUG = true

module.exports = (prefixes...) ->
  if DEBUG
    console.debug.bind console, prefixes...
  else
    ->
