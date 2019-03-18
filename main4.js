"use strict";

const config = require('./lib/config')
const utils = require('./lib/utils')

const workerInterval = 10000 // 10 secondes en millisecondes
const ccyPair = 'TRY_JPY' // Paire de devise sur laquelle le landbuyer est lancé
const positionAmount = 20 // Montant de chaque position
const distOnTakeProfit = 0.1 // Distance en pips du take profit
const distBetweenPosition = 1 // Distance en pips entre les positions 
const nbOrders = 20 // Nombre d'ordres en dessus de la position ouverte la plus
                   // haute et en dessous de la position ouverte la plus basse

// ------------------------ CONNEXION FX PRACTICE -------------------------------
// const options = {
//  hostname: 'api-fxpractice.oanda.com',
//  streamingHostname: 'stream-fxpractice.oanda.com',
//  port: 443,
//  ssl: true,
//  token: '6494b832545a92eb440d455e03ce1eac-1263e2633790a0c211a56bd21632409c',
//  username: 'coeje',
//  accounts: ['101-001-756041-001'],
//  activeAccount: '101-001-756041-001',
//}
// ------------------------ CONNEXION FX TRADE -------------------------------
const options = {
  hostname: 'api-fxtrade.oanda.com',
  streamingHostname: 'stream-fxtrade.oanda.com',
  port: 443,
  ssl: true,
  token: 'c9b2cebd2412f15225359aa0fae10026-ae0b89033f2a58715fef3ee5706f70fc',
  username: 'coeje',
  accounts: ['001-004-293865-004'],
  activeAccount: '001-004-293865-004',
}

function round(number) {
  return (Math.round(number * 100) / 100)
}

const oanda = new config.Config(options)
const connection = oanda.createContext()

let iteration = 0

let worker = setInterval(() => {
  iteration += 1
  console.log('--------');
  console.log(`Round #${iteration}`)

  let takeProfitOrders = new Array();
  let limitOrders = new Array();
  let ordersToBePlaced = new Array();
  let takeProfitToBePlaced = new Array();
  let searchedOrder = 0;

  // On récupère les infos du compte
  connection.account.get(options.activeAccount, response => {
    utils.handleErrorResponse(response)

    // Les infos du comptes sont stockées dans cette variable
    let account = response.body.account
	//console.log(account)

    // On test si il y a des pendingOrders, 
    if (account.pendingOrderCount > 0) {
      for (let order of account.orders) {
        if (order.type == 'TAKE_PROFIT') {
          takeProfitOrders.push(round(order.price))
        } else if (order.type == 'MARKET_IF_TOUCHED') {
          limitOrders.push(round(order.price))
        }
      }
      
      // On trie nos tableau dans l'ordre croissant
      takeProfitOrders.sort()
      limitOrders.sort()
      
      // On affiche nos tableaux
    /*
      console.log('----')
      console.log('TAKE PROFIT ORDERS')
      console.log(takeProfitOrders)
      console.log('LIMIT ORDERS')
      console.log(limitOrders)
	*/  
      
      let highTradeValue = round(Math.max(...takeProfitOrders) - distOnTakeProfit)
      let lowTradeValue = round(Math.min(...takeProfitOrders) - distOnTakeProfit)

      console.log('----')
      console.log(`high trade: ${highTradeValue}`)
      console.log(`low trade: ${lowTradeValue}`)

      // On rempli un tableau avec les niveau de prix des ordres que l'on devrait ouvrir
      for (let i = 1; i < nbOrders; i++) { 
        searchedOrder = round(i * distBetweenPosition / 100 + highTradeValue)

        if (!limitOrders.includes(searchedOrder)) {
          ordersToBePlaced.push(searchedOrder)
          takeProfitToBePlaced.push (round(searchedOrder + distOnTakeProfit))
        }
      }

       // Idem pour les ordres inférieurs
      for (let i = 1; i < nbOrders; i++) {
        searchedOrder= round(lowTradeValue - i * distBetweenPosition / 100)

        if (!limitOrders.includes(searchedOrder)) {
          ordersToBePlaced.push(searchedOrder),
          takeProfitToBePlaced.push(round(searchedOrder + distOnTakeProfit))
        }
      }
    
      ordersToBePlaced.sort()
      takeProfitToBePlaced.sort()
     
      /*
      console.log('ORDERS TO BE PLACED')
      console.log(ordersToBePlaced)
      console.log('----')
      console.log('TAKE PROFIT TO BE PLACED')
      console.log(takeProfitToBePlaced)
      console.log('----')
      */

      for (let i in ordersToBePlaced) {
        // Ici on créer un objet de type LimitOrderRequest, avec différentes propriétés
        let order = new connection.order.MarketIfTouchedOrderRequest({
          instrument: ccyPair,
          type: 'MARKET_IF_TOUCHED',
          units: positionAmount,
          timeInForce: 'GTC',
          price: ordersToBePlaced[i].toString(),
          takeProfitOnFill: {
            timeInForce: 'GTC',
            price: round(ordersToBePlaced[i] + distOnTakeProfit).toString(),
			description:ccyPair.toString()
          } 
        })

        // Ici on lance réellement la requête
        connection.order.marketIfTouched(
        options.activeAccount,
          order,
          response => {
            utils.handleErrorResponse(response)
            console.log(`Order ${(i + 1)} created, value: ${ordersToBePlaced[i].toString()}`)
          }
        )
      }
    }
  })
}, workerInterval)