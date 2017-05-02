async   = require 'async'
envalid = require 'envalid'
request = require 'request'

class Command
  constructor: () ->
    @env = envalid.cleanEnv process.env, {
      TRADING_POST_TOKEN: envalid.str()
    }

  run: =>
    @_getProfile (error, profile) =>
      return @die error if error?
      async.eachSeries profile.stocks, @_sellStock, (error) =>
        @die error

  _getProfile: (callback) =>
    request.get {
      url: 'https://trading-post.club/profile/'
      json: true
      headers:
        Authorization: "Bearer #{@env.TRADING_POST_TOKEN}"
    }, (error, response, body) =>
      return callback error if error?
      callback null, body

  _sellStock: ({ ticker, quantity }, callback) =>
    return callback null if quantity < 1
    console.log { ticker, quantity }
    request.post {
      url: 'https://trading-post.club/profile/sell-orders'
      json: { ticker, quantity }
      headers:
        Authorization: "Bearer #{@env.TRADING_POST_TOKEN}"
    }, (error, response) =>
      return callback error if error?
      return callback new Error "Unexpected status code #{response.statusCode}" if response.statusCode > 299
      callback null

  die: (error) =>
    return process.exit(0) unless error?
    console.error error.stack
    process.exit 1

command = new Command()
command.run()
