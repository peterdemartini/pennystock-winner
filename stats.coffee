_       = require 'lodash'
async   = require 'async'
envalid = require 'envalid'
request = require 'request'

class Command
  constructor: () ->
    @env = envalid.cleanEnv process.env, {
      TRADING_POST_TOKEN: envalid.str()
    }

  run: =>
    @_getTotalSpent (error, totalSpent, totalQuantity) =>
      return @die error if error?
      @_getProfile (error, profile) =>
        return @die error if error?
        async.reduce _.get(profile, 'stocks', []), 0, @_getCurrentPrice, (error, totalNet) =>
          return @die error if error?
          console.log "TOTAL QUANTITY BOUGHT: #{totalQuantity}"
          console.log "TOTAL NET VALUE: #{_.round(totalNet, 2)}"
          console.log "TOTAL BOUGHT: #{_.round(totalSpent, 2)}"
          console.log "RICHES: #{_.round(_.get(profile, 'riches'), 2)}"
          @die()

  _getProfile: (callback) =>
    request.get {
      url: 'https://trading-post.club/profile/'
      json: true
      headers:
        Authorization: "Bearer #{@env.TRADING_POST_TOKEN}"
    }, (error, response, body) =>
      return callback error if error?
      callback null, body

  _getCurrentPrice: (total, { ticker, quantity }, callback) =>
    request.get {
      url: "https://stock.octoblu.com/last-trade-price/#{ticker}"
      json: true
    }, (error, response, body) =>
      return callback error if error?
      price = _.get body, 'price', 0
      callback null, ( price * quantity ) + total

  _getTotalSpent: (callback) =>
    request.get {
      url: 'https://trading-post.club/profile/buy-orders'
      json: true
      headers:
        Authorization: "Bearer #{@env.TRADING_POST_TOKEN}"
    }, (error, response, result) =>
      return callback error if error?
      totals = {}
      totalQuantity = 0
      _.each result, ({price,quantity,ticker}) =>
        totals[ticker] ?= 0
        totals[ticker] += price * quantity
        totalQuantity += quantity
      total = 0
      _.each _.values(totals), (subtotal) =>
        total += subtotal
      callback null, total, totalQuantity

  die: (error) =>
    return process.exit(0) unless error?
    console.error error.stack
    process.exit 1

command = new Command()
command.run()
