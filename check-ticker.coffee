envalid      = require 'envalid'
yahooFinance = require 'yahoo-finance'

class Command
  constructor: () ->
    @env = envalid.cleanEnv process.env, {
      TRADING_POST_TOKEN: envalid.str()
      TICKER: envalid.str()
    }

  run: =>
    @_stockInfo (error, info) =>
      console.log 'stockInfo', info
      @die error

  _stockInfo: (callback) =>
    yahooFinance.snapshot {
      symbol: @env.TICKER
      fields: ['a', 'b', 'b2', 'b3', 'b4', 'c1', 'c6', 'd', 'e', 'e7', 'e8',
          'e9','g', 'h', 'j', 'j5', 'k', 'k4', 'l1', 'm3', 'm4', 'm5',
          'm7', 'o', 'p', 'p5', 'p6', 'r', 'r5', 'r6', 'r7', 't8', 'y']
    }, (error, body) =>
      return callback error if error?
      callback null, body

  die: (error) =>
    return process.exit(0) unless error?
    console.error 'Error', error.stack ? JSON.stringify error
    process.exit 1

command = new Command()
command.run()
