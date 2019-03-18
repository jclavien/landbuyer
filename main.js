const config = require('./lib/config')
const utils = require('./lib/utils')
const ArgumentParser = require('argparse').ArgumentParser;

// Constante de configuration
const ccyPair = 'TRY_JPY' // Paire de devise sur laquelle le landbuyer est lancé
const positionAmount = 20 // Montant de chaque position
const distOnTakeProfit = 0.1 // Distance en pips du take profit
const distBetweenPosition = 1 // Distance en pips entre les positions 
const nbOrders = 20 // Nombre d'ordres en dessus de la position ouverte la plus
                   // haute et en dessous de la position ouverte la plus basse

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

console.log(options);

// Ceci est vraiment très bien, mais ça empêchera de faire planter
// le programme à tout bout de champs
try {
  const oanda = new config.Config(options)
  const connection = oanda.createContext()

  let iteration = 0

  let worker = setInterval(() => {
    iteration += 1
    
    console.log(``)
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

      // On test si il y a des pendingOrders, 
      if (account.pendingOrderCount > 0) {
        for (let order of account.orders) {
          if (order.type == 'TAKE_PROFIT') {
            takeProfitOrders.push(utils.round(order.price))
          } else if (order.type == 'MARKET_IF_TOUCHED') {
            limitOrders.push(utils.round(order.price))
          }
        }
        
        // On trie nos tableau dans l'ordre croissant
        takeProfitOrders.sort()
        limitOrders.sort()
        
        let highTradeValue = utils.round(Math.max(...takeProfitOrders) - distOnTakeProfit)
        let lowTradeValue = utils.round(Math.min(...takeProfitOrders) - distOnTakeProfit)

        console.log(`[high trade: ${highTradeValue} / low trade: ${lowTradeValue}]`)

        // On rempli un tableau avec les niveau de prix des ordres que l'on devrait ouvrir
        for (let i = 1; i < nbOrders; i++) { 
          searchedOrder = utils.round(i * distBetweenPosition / 100 + highTradeValue)

          if (!limitOrders.includes(searchedOrder)) {
            ordersToBePlaced.push(searchedOrder)
            takeProfitToBePlaced.push (utils.round(searchedOrder + distOnTakeProfit))
          }
        }

         // Idem pour les ordres inférieurs
        for (let i = 1; i < nbOrders; i++) {
          searchedOrder= utils.round(lowTradeValue - i * distBetweenPosition / 100)

          if (!limitOrders.includes(searchedOrder)) {
            ordersToBePlaced.push(searchedOrder),
            takeProfitToBePlaced.push(utils.round(searchedOrder + distOnTakeProfit))
          }
        }
      
        ordersToBePlaced.sort()
        takeProfitToBePlaced.sort()

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
              price: utils.round(ordersToBePlaced[i] + distOnTakeProfit).toString()
            } 
          })

          // Ici on lance réellement la requête
          connection.order.marketIfTouched(
          options.activeAccount,
            order,
            response => {
              utils.handleErrorResponse(response)
              console.log(`- Order ${(i + 1)} created, value: ${ordersToBePlaced[i].toString()}`)
            }
          )
        }
      }
    })
  }, args.interval)
} catch(error) {
  console.log(`ERROR`)
  console.log(error)
}