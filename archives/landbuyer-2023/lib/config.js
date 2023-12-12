"use strict";

const Context = require('@oanda/v20/context').Context

/*
 * Oanda API connector
 * Create a config class that can create and return connection context
 */
class Config {
  constructor(options) {
    this.hostname = options.hostname
    this.streamingHostname = options.streamingHostname
    this.port = options.port
    this.ssl = options.ssl
    this.token = options.token
    this.username = options.username
    this.accounts = options.accounts
    this.activeAccount = options.activeAccount
  }

  createContext() {
    let ctx = new Context(
      this.hostname,
      this.port,
      this.ssl,
      "Oanda sample javascript"
    )

    ctx.setToken(this.token)

    return ctx
  }

  createStreamingContext() {
    let ctx = new Context(
      this.streamingHostname,
      this.port,
      this.ssl,
      "Oanda sample streaming javascript"
    )

    ctx.setToken(this.token)

    return ctx
  }
}

exports.Config = Config;