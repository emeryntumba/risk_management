//+------------------------------------------------------------------+
//|                                                 RiskExitGold.mq5 |
//|                                                     Emery Ntumba |
//|                https://www.github.com/emerynutmba/risk_exit_gold |
//+------------------------------------------------------------------+
#property copyright "Emery Ntumba"
#property link      "https://www.github.com/emerynutmba/risk_exit_gold"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Expert Advisor : RiskExitGold                                   |
//| Description : Ferme les trades XAUUSD selon chandelier M15      |
//+------------------------------------------------------------------+
#property strict

input double seuil_ecart_cloture = 4.0; // Minimum entre Close et High/Low
input double seuil_declenchement = 3.0; // Déclenchement de clôture (en unités)

//+------------------------------------------------------------------+
void OnTick()
{
   // Vérifier si la période est bien M15
   if(Period() != PERIOD_M15)
      return;

   string symbol = "GOLD";

   // Récupérer les données du chandelier précédent (Index 1)
   double prevHigh = iHigh(symbol, PERIOD_M15, 1);
   double prevLow = iLow(symbol, PERIOD_M15, 1);
   double prevClose = iClose(symbol, PERIOD_M15, 1);

   // Parcourir les positions ouvertes
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(!PositionGetTicket(i)) continue;

      string posSymbol = PositionGetString(POSITION_SYMBOL);
      if(posSymbol != symbol) continue;

      ulong ticket = PositionGetInteger(POSITION_TICKET);
      double volume = PositionGetDouble(POSITION_VOLUME);
      int type = (int)PositionGetInteger(POSITION_TYPE);

      if(type == POSITION_TYPE_BUY)
      {
         double ecartHighClose = prevHigh - prevClose;
         if(ecartHighClose >= seuil_ecart_cloture)
         {
            double seuil = prevLow - seuil_declenchement;
            double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
            if(bid <= seuil)
            {
               Print("📉 Fermeture position BUY (seuil atteint): Bid = ", bid, " | Seuil = ", seuil);
               trade_close(ticket);
            }
         }
      }

      if(type == POSITION_TYPE_SELL)
      {
         double ecartCloseLow = prevClose - prevLow;
         if(ecartCloseLow >= seuil_ecart_cloture)
         {
            double seuil = prevHigh + seuil_declenchement;
            double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
            if(ask >= seuil)
            {
               Print("📈 Fermeture position SELL (seuil atteint): Ask = ", ask, " | Seuil = ", seuil);
               trade_close(ticket);
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Fonction de fermeture de position                               |
//+------------------------------------------------------------------+
void trade_close(ulong ticket)
{
   MqlTradeRequest request;
   MqlTradeResult  result;

   ZeroMemory(request);
   ZeroMemory(result);

   if(!PositionSelectByTicket(ticket))
      return;

   string symbol = PositionGetString(POSITION_SYMBOL);
   double volume = PositionGetDouble(POSITION_VOLUME);
   int type = (int)PositionGetInteger(POSITION_TYPE);

   request.action = TRADE_ACTION_DEAL;
   request.symbol = symbol;
   request.volume = volume;
   request.position = ticket;
   request.deviation = 10;
   request.type = (type == POSITION_TYPE_BUY) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
   request.price = (type == POSITION_TYPE_BUY) ? SymbolInfoDouble(symbol, SYMBOL_BID)
                                               : SymbolInfoDouble(symbol, SYMBOL_ASK);
   request.magic = 123456;

   if(!OrderSend(request, result))
   {
      Print("❌ Erreur fermeture position #", ticket, " | Code: ", result.retcode);
   }
   else
   {
      Print("✅ Position #", ticket, " fermée avec succès !");
   }
}
