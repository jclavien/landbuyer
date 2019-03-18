"use strict"

/*
 * Generic function that prints out response details if the HTTP response
 * wasn't 2XX
 */
exports.handleErrorResponse = function(response) {
  if (response.statusCode.startsWith('2')) {
    return true
  } else {

    let s = response.method
        + ' ' + response.path
        + ' ' + response.statusCode

    if (response.statusMessage !== undefined) {
      s += ' ' + response.statusMessage
    }

    return response
  }
}

/*
 * Function that prints out the summary for transactions found in an Order
 * create response message
 */
exports.dumpOrderCreateResponse = function(response) {
  [ 'orderCreateTransaction',
    'longOrderCreateTransaction',
    'shortOrderCreateTransaction',
    'orderFillTransaction',
    'longOrderFillTransaction',
    'shortOrderFillTransaction',
    'orderCancelTransaction',
    'longOrderCancelTransaction',
    'shortOrderCancelTransaction',
    'orderReissueTransaction',
    'orderRejectTransaction',
    'orderReissueRejectTransaction',
    'replacingOrderCancelTransaction',
  ].forEach(
    transactionName => {
      var transaction = response.body[transactionName]
      if (!transaction) { return }
      console.log(transaction.summary())
    }
  )
}

exports.round = function(number, decimalNumber = 2) {
  let multiplicator = Math.pow(10, decimalNumber)
  return (Math.round(number * multiplicator) / multiplicator)
}
