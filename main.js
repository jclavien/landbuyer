"use strict";
// Déclaration des variables
var CcyPair
var Amount
var TakeProfit
var Intervall
var NbOfOrder
var Frequency
var PendingOrders
var HighTrade
var LowTrade

//Assignation des valeurs aux paramètres du modèle
CcyPair = 'TRY_JPY' // Paire de devise sur laquelle le landbuyer est lancé
Amount = 20 // montant de chaque position
TakeProfit = 5 // distance en pips du take profit
Intervall = 1 // distance en pips entre les positions 
NbOfOrder = 50 // nombre d'ordres en dessus de la position ouverte la plus haute et en dessous de la position ouverte la plus basse
Frequency = 30 // fréquence en seconde à laquelle le programme se connecte au compte



// import
const config = require('./lib/config')
const utils = require('./lib/utils')

// default config options
// this should be in a separate file
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

// create config oanda API and create a standard connection
const oanda = new config.Config(options)
const connection = oanda.createContext()


// LANDBUYER - PSEUDO CODE
// Dans la liste des ordres ouverts trouver le Take Profit (TP) le plus haut et le TP le plus bas
// Calculer la valeur théorique de l'ordre ouvert le plus haut et le plus bas (TP le plus haut - TakeProfit) et (TP le plus bas - TakeProfit)
HighTrade = Math.max(account.pendingOrder.TakeProfit.PriceValue - TakeProfit);
console.log (HighTrade);
LowTrade = Math.min(account.pendingOrder.TakeProfit.PriceValue - TakeProfit);
console.log(LowTrade);
// Placer des ordres au-dessus de l'ordre le plus haut et au dessous de l'ordre le plus bas
For i = 1 to nbOfOrder
if !OpenOrder,PriceValue = HighTrade + Intervall * i //si l'ordre n'existe pas
PostLimitOrder (PriceValue = HighTrade + Intervall * i) //On place un ordre selon les paramètres (Amount, TakeProfit) au dessus du trade ouvert le plus haut
// idem avec les ordres à placer sous le trade ouvert le plus bas
For i = 1 to nbOfOrder
if !OpenOrder,PriceValue = LowTrade - Intervall * i //si l'ordre n'existe pas
PostLimitOrder (PriceValue = LowTrade - Intervall * i) //On place un ordre selon les paramètres (Amount, TakeProfit)

// VOILA!! A réaliser toutes les 30sec...


// example code that retrieve the account infos
connection.account.get(
  options.activeAccount,
  response => {
    utils.handleErrorResponse(response);

    let account = response.body.account;

    console.log('Account info');
    console.log(account.toString());
    console.log();

    if (account.pendingOrderCount > 0) {
      console.log('Pending Orders');
      console.log('==============');

      for (let order of account.orders) {
        console.log(order.title());
      }

      console.log();
    }

    if (account.openTradeCount > 0) {
      console.log('Open Trades');
      console.log('===========');

      for (let trade of account.trades) {
        console.log(trade.title());
      }

      console.log();
    }

    if (account.openPositionCount > 0) {
      console.log('Positions');
      console.log('=========');

      for (let position of account.positions) {
        console.log(position.summary());

        if (position.long && position.long.units != '0') {
          console.log('  ' + position.long.summary());
        }
        if (position.short && position.short.units != '0') {
          console.log('  ' + position.short.summary());
        }
      }

      console.log();
	  
    }
  }
)
