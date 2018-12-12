"use strict";

// On met toujours les imports an début de fichier (même si ce n'est pas
// obligatoire).
const config = require('./lib/config')
const utils = require('./lib/utils')

// Ici on met des constantes. C'est comme des variables mais on s'attend à ce
// qu'elles n'évoluent pas pendant l'évaluation du code. L'idée c'est de rendre
// le tout facile à paramétrer en mettant toutes "configs" du code au même
// endroit.
const workerInterval = 3000 // 30 secondes en millisecondes
const ccyPair = 'TRY_JPY' // Paire de devise sur laquelle le landbuyer est lancé
const positionAmount = 20 // Montant de chaque position
const distOnTakeProfit = 0.05 // Distance en pips du take profit
const distBetweenPosition = 1 // Distance en pips entre les positions 
const nbOrders = 10 // Nombre d'ordres en dessus de la position ouverte la plus
                   // haute et en dessous de la position ouverte la plus basse
const orderSide = 'buy'

const options = {
  hostname: 'api-fxpractice.oanda.com',
  streamingHostname: 'stream-fxpractice.oanda.com',
  port: 443,
  ssl: true,
  token: '6494b832545a92eb440d455e03ce1eac-1263e2633790a0c211a56bd21632409c',
  username: 'coeje',
  accounts: ['101-001-756041-001'],
  activeAccount: '101-001-756041-001',
}

// Create config oanda API and create a standard connection.
// Ici on devrait aussi regarder pour traiter correctement les erreurs de
// connection.
const oanda = new config.Config(options)
const connection = oanda.createContext()

// Ici on pose des variables générales (donc à l'extérieur du worker). En JS on
// à pas besoin de déclarer tout les variables au début du fichier comme en C.
// Et c'est pas une pratique qui se fait.
let iteration = 0

function round(number) {
  return (Math.round(number * 100) / 100)
}


// ---------->   WORKER     <-------------------------------------------------------------------------------


// Le code qui travail vraiment. Tout ce qui n'est pas fait/à faire toutes les
// X secondes sera mis dehors, avant ou après.
let worker = setInterval(() => {
  // On affiche à quel iteration on est (c'est pas hyper important) et ça pourra
  // être supprimé par la suite. C'est pratique pour le développement.
  // Tu peux voir qu'ici on utilise une chaîne de caractère spéciale:
  // `du text ${uneVariable}`
  // On appelle ça l'interpolation, ça permet de mettre des variables directement
  // dans des strings.
  iteration += 1
  console.log(`Round #${iteration}`)
  console.log('----');

  // J'ai déplacé tes variables ici. Quelques remarques.
  // 1. Comme tu les vides à la fin, le mieux est de les affecter directement ici
  //    Ce sont des variables qui ne sont utilisées que dans cette boucle, et
  //    surtout on a pas besoin de garder les infos après la fin de la boucle.
  // 2. Pense à utiliser "let" au lieu de "var". Les deux marchent, mais let est
  //    la bonne manière de faire. Si tu trouves des tutos ou des exemples de code
  //    qui écrivent "var", c'est parce que c'est vieux.
  // 3. La convention, en javascript, c'est de faire des variables en camelCase
  //    (donc sans majuscule au début).
  let takeProfitList = new Array();
  let limitOrderList = new Array();
  let orderToBePlacedList = new Array();
  let searchedOrder = 0;

  // On récupère les infos du compte
  connection.account.get(options.activeAccount, response => {
    utils.handleErrorResponse(response)

    // Les infos du comptes sont stockées dans cette variable
    let account = response.body.account

    // On test si il y a des pendingOrders, 
    if (account.pendingOrderCount > 0) {
      // On rempli un tableau nommée takeProfitList et un autre nommé limitOrderList qui contient le price de ces ordres ouverts
      for (let order of account.orders) {
        if (order.type == 'TAKE_PROFIT') { //si l'ordre est de type Take_Profit
          takeProfitList.push(round(order.price)) // on le met dans notre tableau 
        } else if (order.type == 'MARKET_IF_TOUCHED') {
          limitOrderList.push(round(order.price))
        }
      }
      
      // On trie nos tableau dans l'ordre croissant
      takeProfitList.sort()
      limitOrderList.sort()
      
      // On affiche nos tableaux
      console.log('TAKE PROFIT ORDERS');
      console.log(takeProfitList);
      console.log('----');
      console.log('LIMIT ORDERS');
      console.log(limitOrderList);
      console.log('----');
      
      // On renseigne la variable highTradeValue qui est le niveau de prix de la position ouverte la plus haute. Ce prix est calculé par rapport au take profit le plus haut.
      let highTradeValue = round(Math.max(...takeProfitList) - distOnTakeProfit)
      // Idem pour le trade ouvert le plus bas 
      let lowTradeValue = round(Math.min(...takeProfitList) - distOnTakeProfit)

      // On affiche les deux valeurs ainsi calculées
      console.log(`high trade: ${highTradeValue}`)
      console.log(`low trade: ${lowTradeValue}`)
      console.log('----')
   
      // On rempli un tableau avec les niveau de prix des ordres que l'on devrait ouvrir
      for (let i = 1; i < nbOrders; i++) { 
        searchedOrder= round(i * distBetweenPosition / 100 + highTradeValue)
        
        if (limitOrderList.includes(searchedOrder) == false){ // si notre tableau limitOrderList ne contient pas encore l'ordre recherché
          orderToBePlacedList.push(searchedOrder) // alors on l'ajoute au tableau orderToBePlacedList
        } // J'ai ici un probleme ici puisque le programme pousse tous les ordres recherchés dans le tableau, meme si ca existe deja dans le tableau LimitOrder     
      }

      // Idem pour les ordres inférieurs
      for (let i = 1; i < nbOrders; i++) {
        searchedOrder= round(lowTradeValue - i * distBetweenPosition / 100)

        if (limitOrderList.includes(searchedOrder) == false){
          orderToBePlacedList.push(searchedOrder);
        }
      }
      
      console.log('ORDERS TO BE PLACED')
      console.log(orderToBePlacedList)
      console.log('----')

      // Une fois le tableau des orderToBePlacedList rempli on place les ordres avec comme paramètre les prix ainsi obtenus, le montant (const) et le takeprofit (const)
      // J'ai trouvé ca online : 
      /**
      * @method createOrder
      * @param {String} accountId Required.
      * @param {Object} order
      * @param {String} order.instrument Required. Instrument to open the order on.
      * @param {Number} order.units Required. The number of units to open order for.
      * @param {String} order.side Required. Direction of the order, either ‘buy’ or ‘sell’.
      * @param {String} order.type Required. The type of the order ‘limit’, ‘stop’, ‘marketIfTouched’ or ‘market’.
      * @param {String} order.expiry Required. If order type is ‘limit’, ‘stop’, or ‘marketIfTouched’. The value specified must be in a valid datetime format.
      * @param {String} order.price Required. If order type is ‘limit’, ‘stop’, or ‘marketIfTouched’. The price where the order is set to trigger at.
      * @param {Number} order.lowerBound Optional. The minimum execution price.
      * @param {Number} order.upperBound Optional. The maximum execution price.
      * @param {Number} order.stopLoss Optional. The stop loss price.
      * @param {Number} order.takeProfit Optional. The take profit price.
      * @param {Number} order.trailingStop Optional The trailing stop distance in pips, up to one decimal place.
      * @param {Function} callback
      */
      /** 
      LimitOrderRequest.post {
		  type : (LIMIT),
		  intrument : (ccyPair),
		  units : (positionAmount),
		  price : (orderToBePlacedList),
		  takeProfitOnFill : (TakeProfitDetails {
			  price : (orderToBePlacedList + distOnTakeProfit)
		  }
	  }*/
    
    }
  })
}, workerInterval)

/*
TON PSEUDO CODE

// LANDBUYER - PSEUDO CODE
// Dans la liste des ordres ouverts trouver le Take Profit (TP) le plus haut et le TP le plus bas
// Calculer la valeur théorique de l'ordre ouvert le plus haut et le plus bas (TP le plus haut - TakeProfit) et (TP le plus bas - TakeProfit)
let HighTrade = Math.max(account.pendingOrder.TakeProfit.PriceValue - TakeProfit);
console.log (HighTrade);
let LowTrade = Math.min(account.pendingOrder.TakeProfit.PriceValue - TakeProfit);
console.log(LowTrade);

// Placer des ordres au-dessus de l'ordre le plus haut et au dessous de l'ordre le plus bas
For i = 1 to nbOfOrder
if !OpenOrder,PriceValue = HighTrade + Intervall * i //si l'ordre n'existe pas
PostLimitOrder (PriceValue = HighTrade + Intervall * i) //On place un ordre selon les paramètres (Amount, TakeProfit) au dessus du trade ouvert le plus haut
// idem avec les ordres à placer sous le trade ouvert le plus bas
For i = 1 to nbOfOrder
if !OpenOrder,PriceValue = LowTrade - Intervall * i //si l'ordre n'existe pas
PostLimitOrder (PriceValue = LowTrade - Intervall * i) //On place un ordre selon les paramètres (Amount, TakeProfit)
*/