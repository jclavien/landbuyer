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
const nbOrders = 50 // Nombre d'ordres en dessus de la position ouverte la plus
                   // haute et en dessous de la position ouverte la plus basse

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
var TakeProfitList = new Array();
var LimitOrderList = new Array();
let round = 0

// Le code qui travail vraiment. Tout ce qui n'est pas fait/à faire toutes les
// X secondes sera mis dehors, avant ou après.
let worker = setInterval(() => {
  // On affiche à quel round on est (c'est pas hyper important) et ça pourra
  // être supprimé par la suite. C'est pratique pour le développement.
  // Tu peux voir qu'ici on utilise une chaîne de caractère spéciale:
  // `du text ${uneVariable}`
  // On appelle ça l'interpolation, ça permet de mettre des variables directement
  // dans des strings.
  round += 1
  console.log(`Round #${round}`)
  console.log('----');

  // On récupère les infos du compte
  connection.account.get(options.activeAccount, response => {
    utils.handleErrorResponse(response)

    // Les infos du comptes sont stockées dans cette variable
    let account = response.body.account

    // On test si il y a des pendingOrders, si non, on ne fait rien
    if (account.pendingOrderCount > 0) {
      // Ici c'est un peu compliqué parce que la doc est pas hyper clair sur ce
      // que représentent ces objets, et ils contiennent une volée et demi de
      // valeurs. Donc il va falloir aller à tâtons et regarder ce qu'il te semble
      // juste.
      // J'ai codé la suite qui permet de calculer tes "highTradeValue"/... mais la
      // suite et juste un pseudo code pour voir si ça te semble correct.

      // On parcours tous les orders
      // Ici on affiche le titre + le prix de l'ordre, c'est pour du débug, ça permet
      // d'avoir une vue d'ensemble des tes ordres.
      for (let order of account.orders) {
		  if (order.type == 'TAKE_PROFIT') { //si l'ordre est de type Take_Profit
			TakeProfitList.push(order.price);// on le met dans notre tableau 
			
       // console.log(`Ordre: ${order.title()},Type d'ordre : ${order.type}, Prix: ${order.price}`);
	  
      }
	  if (order.type == 'MARKET_IF_TOUCHED') {
		LimitOrderList.push(order.price);
	  }
	  
		  }
	
		  TakeProfitList.sort()
		  LimitOrderList.sort()
		  console.log('TAKE PROFIT ORDERS');
		    console.log(TakeProfitList);
			console.log('----');
		console.log('LIMIT ORDERS');
		    console.log(LimitOrderList);
			
      console.log('----');
      
      // Ici on calcule les maximums et les minimums. Le code semble compliqué et c'est
      // normal. On peut pas faire comme tu proposait. Parce que tu demandes de faire un
      // maximum sur un objet compliqué avec un opération mathématique. Donc on doit faire
      // ce qui suit. Je pourrais t'expliqué à l'occasion.
     // let highTradeValue = Math.max.apply(Math, account.orders.map((o) => {
    //   return o.price - distOnTakeProfit
    // }))
	let highTradeValue = Math.round((Math.max(...TakeProfitList) - distOnTakeProfit)*100)/100;	
	
     // let lowTradeValue = Math.min.apply(Math, account.orders.map((o) => {
     //   return o.price - distOnTakeProfit
     // }))
	let lowTradeValue = Math.round((Math.min(...TakeProfitList) - distOnTakeProfit)*100)/100;	
      console.log(`high trade: ${highTradeValue}`)
      console.log(`low trade: ${lowTradeValue}`)
      console.log('----')
	 
	
      // Ici, j'imagine que la suite de l'algorithme consiste à placer des ordres
      // comme je dis, c'est codé mais commenté parce que pas testé. Je veux que tu me
      // valide les trucs précédant avant.

      // On place les ordres supérieurs
      for (let i = 0; i < nbOrders; i++) {
        // Ici je ne comprends pas la suite de l'aglo, "Si QUEL ordre n'existe pas?" --> REPONSE : l'ordre dont le prix = HighTrade + Intervall * i
      
	  }

      // On place les ordres inférieurs
      for (let i = 0; i < nbOrders; i++) {
        // Ici je ne comprends pas la suite de l'aglo, "Si QUEL ordre n'existe pas?" --> REPONSE : l'ordre dont le prix = LowTrade - Intervall * i
      }
	  
	 //Réinitialisation des tableaux
	 TakeProfitList = []; 
	 LimitOrderList = [];
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