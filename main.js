const config = require('./lib/config')
const utils = require('./lib/utils')
const ArgumentParser = require('argparse').ArgumentParser;

// On parse des arguments pour la ligne de commande
const parser = new ArgumentParser({
  version: '1.0.0',
  addHelp: true,
  description: 'Landbyer CLI software'
})

parser.addArgument(['-i', '--interval'], {
    help: 'Worker interval in [millisecond]',
    type: Number,
    defaultValue: 10000,
  }
)

parser.addArgument(['-d', '--dev'], {
    help: 'Dev mode option',
    action: 'storeTrue',
    type: Boolean,
    defaultValue: false,
  }
)

let args = parser.parseArgs()

// ------------------------ CONNEXION FX TRADE -------------------------------
const options = !args.dev ? {
  hostname: 'api-fxtrade.oanda.com',
  streamingHostname: 'stream-fxtrade.oanda.com',
  port: 443,
  ssl: true,
  token: 'c9b2cebd2412f15225359aa0fae10026-ae0b89033f2a58715fef3ee5706f70fc',
  username: 'coeje',
  accounts: ['001-004-293865-004'],
  activeAccount: '001-004-293865-004',
} : {
  hostname: 'api-fxpractice.oanda.com',
  streamingHostname: 'stream-fxpractice.oanda.com',
  port: 443,
  ssl: true,
  token: '6494b832545a92eb440d455e03ce1eac-1263e2633790a0c211a56bd21632409c',
  username: 'coeje',
  accounts: ['101-001-756041-001'],
  activeAccount: '101-001-756041-001',
};

// Constante de configuration
const instruments = [
  {
    ccyPair: 'TRY_JPY', // Paire de devise sur laquelle le landbuyer est lancé
    roundDecimalNumber: 2, // Nombre de décimale à utiliser
    positionAmount: 40, // Montant de chaque position
    distOnTakeProfit: 0.1, // Distance en pips du take profit
    distBetweenPosition: 1, // Distance en pips entre les positions 
    nbOrders: 50, // Nombre d'ordres en dessus de la position ouverte la plus
                 // haute et en dessous de la position ouverte la plus basse
  }, {
    ccyPair: 'USD_CHF',
    roundDecimalNumber: 4,
    positionAmount: 30,
    distOnTakeProfit: 0.0010,
    distBetweenPosition: 0.01,
    nbOrders: 50,
  }, {
    ccyPair: 'EUR_ZAR',
    roundDecimalNumber: 2,
    positionAmount: -8,
    distOnTakeProfit: -0.04,
    distBetweenPosition: 1,
    nbOrders: 50,
  }, {
    ccyPair: 'NZD_JPY',
    roundDecimalNumber: 2,
    positionAmount: 10,
    distOnTakeProfit: 0.10,
    distBetweenPosition: 0.1,
    nbOrders: 5,
  }
]

console.log(options)

// Ceci est vraiment très bien, mais ça empêchera de faire planter
// le programme à tout bout de champs
const oanda = new config.Config(options)
const connection = oanda.createContext()

let iteration = 0

let worker = setInterval(() => {
  iteration += 1
  
  console.log(``)
  console.log(`Round #${iteration}`)

  // On récupère les infos du compte
  connection.account.get(options.activeAccount, response => {
    if (utils.handleErrorResponse(response)) {

      // Les infos du comptes sont stockées dans cette variable
      let account = response.body.account

      // On test si il y a des pendingOrders
      if (account.pendingOrderCount > 0) {
        instruments.forEach(opt => {
          console.log(`  Instruments #${opt.ccyPair}`)

          let tradeOrders = new Array();
          let limitOrders = new Array();
          let ordersToBePlaced = new Array();
          let takeProfitToBePlaced = new Array();
          let searchedOrder = 0;

          for (let trade of account.trades) {
            if (trade.instrument == opt.ccyPair) {
              tradeOrders.push(utils.round(trade.price, opt.roundDecimalNumber))
            }
          }

          for (let order of account.orders) {
            if (order.instrument == opt.ccyPair && order.type == 'MARKET_IF_TOUCHED') {
              limitOrders.push(utils.round(order.price, opt.roundDecimalNumber))
            }
          }
          
          // On trie nos tableau dans l'ordre croissant
          limitOrders.sort()
          tradeOrders.sort()

          let highTradeValue = utils.round(Math.max(...tradeOrders), opt.roundDecimalNumber)
          let lowTradeValue = utils.round(Math.min(...tradeOrders), opt.roundDecimalNumber)

          console.log(`    [high trade: ${highTradeValue} / low trade: ${lowTradeValue}]`)

          // On rempli un tableau avec les niveau de prix des ordres que l'on devrait ouvrir
          for (let i = 1; i < opt.nbOrders; i++) { 
            searchedOrder = utils.round(i * opt.distBetweenPosition / 100 + highTradeValue, opt.roundDecimalNumber)

            if (!limitOrders.includes(searchedOrder)) {
              ordersToBePlaced.push(searchedOrder)
              takeProfitToBePlaced.push(utils.round(searchedOrder + opt.distOnTakeProfit, opt.roundDecimalNumber))
            }
          }

           // Idem pour les ordres inférieurs
          for (let i = 1; i < opt.nbOrders; i++) {
            searchedOrder= utils.round(lowTradeValue - i * opt.distBetweenPosition / 100, opt.roundDecimalNumber)

            if (!limitOrders.includes(searchedOrder)) {
              ordersToBePlaced.push(searchedOrder),
              takeProfitToBePlaced.push(utils.round(searchedOrder + opt.distOnTakeProfit, opt.roundDecimalNumber))
            }
          }
        
          ordersToBePlaced.sort()
          takeProfitToBePlaced.sort()

          for (let i in ordersToBePlaced) {
            // Ici on créer un objet de type LimitOrderRequest, avec différentes propriétés
            let order = new connection.order.MarketIfTouchedOrderRequest({
              instrument: opt.ccyPair,
              type: 'MARKET_IF_TOUCHED',
              units: opt.positionAmount,
              timeInForce: 'GTC',
              price: ordersToBePlaced[i].toString(),
              takeProfitOnFill: {
                timeInForce: 'GTC',
                price: utils.round(ordersToBePlaced[i] + opt.distOnTakeProfit, opt.roundDecimalNumber).toString()
              } 
            })

            // Ici on lance réellement la requête
            connection.order.marketIfTouched(
            options.activeAccount,
              order,
              response => {
                if (utils.handleErrorResponse(response)) {
                  console.log(`    Order ${(i + 1)} created, value: ${ordersToBePlaced[i].toString()}`)
                 
                } else {
                  console.log('    Error during create order')
                }
              }
            )
          }
        })
      } else {
        console.log('Error during account access')
      }
    }
  })
}, args.interval)
