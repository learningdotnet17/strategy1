input int MagicNumber = 101;
input int Slippage = 10;
input double LotSize = 0.1;
input int StopLoss = 0;
input int TakeProfit = 0;
input int    Fast               = 12;   
input int    Slow               = 26;
input int    Smooth             = 9;
input bool   ZeroLag            = true;
input int    SF                 = 1;
input int    RSI_Period         = 8; 
input int    WP                 = 3; 
input bool   PopUp_Alert        = false;
input bool   PushNotifications  = false;  
input bool   ShowMarkersOnCross = true;
input bool executeorders = true;
int gBuyTicket, gSellTicket;
// OnTick() event handler
void OnTick()
{

   double SAR;
   string JBQMPIndicator;
   string JBMACDIndicator;
   //SAR = iCustom(NULL,0,"Parabolic",.18,.20);
   SAR = iSAR(NULL,0,.05,.2,0);
   double MA = iMA(NULL,0,8,0,0,0,0);
   //If order is open, modify SL to be SAR - otherwise if creating an order use SAR for stoploss
   //if SAR < ask, confirmation indicator for a buy. if SAR > ask, confirmation indicator for a sell
   //using JB, only buy when Green Dot appears, MACD < 0 , and SAR < ask
   //using JB, only sell when red dor appears, MACD > 0, and SAR > ask
   //Need to get the timing right - looks like QMP filter triggers, but then goes to null at some point, same with MACD
   double QMP_Buy = iCustom(NULL,0,"QMP Filter",0,Fast,Slow,Smooth,ZeroLag,SF,RSI_Period,WP,PopUp_Alert,PushNotifications,0,1);
   double QMP_Sell = iCustom(NULL,0,"QMP Filter",0,Fast,Slow,Smooth,ZeroLag,SF,RSI_Period,WP,PopUp_Alert,PushNotifications,1,1);
   double UpCross = iCustom(NULL,0,"MACD_Platinum",Fast,Slow,Smooth,ZeroLag,ShowMarkersOnCross,PopUp_Alert,PushNotifications,2,1);
   double DnCross = iCustom(NULL,0,"MACD_Platinum",Fast,Slow,Smooth,ZeroLag,ShowMarkersOnCross,PopUp_Alert,PushNotifications,3,1);
   double MACDAvg = iCustom(NULL,0,"MACD_Platinum",Fast,Slow,Smooth,ZeroLag,ShowMarkersOnCross,PopUp_Alert,PushNotifications,1,1);
   
   if (QMP_Buy != 2147483647) JBQMPIndicator = "Buy";
   if (QMP_Sell != 2147483647)JBQMPIndicator = "Sell";
   if (UpCross != 2147483647 && UpCross < 0) JBMACDIndicator = "Buy";
   if (DnCross != 2147483647 && DnCross > 0) JBMACDIndicator = "Sell";
/*
   if (JBQMPIndicator == NULL || JBMACDIndicator == NULL)
   {
   }else
   {
   Print("QMP Status: " + JBQMPIndicator);
   }


//Logging for testing
         if(OrderType() == OP_BUY && OrderMagicNumber() == MagicNumber)
         {
         Print("Bid: " + Bid + " Ask: " + Ask + " SAR:" + SAR);
         }
         if(OrderType() == OP_SELL && OrderMagicNumber() == MagicNumber)
         {
         Print("Bid: " + Bid + " Ask: " + Ask + " SAR:" + SAR);
         }
*/



 if (executeorders == TRUE)
 {  
   // Current order counts
   int buyCount = 0, sellCount = 0;
   
   for(int order = 0; order <= OrdersTotal() - 1; order++)
   {
      bool select = OrderSelect(order,SELECT_BY_POS);
      
      if(OrderMagicNumber() == MagicNumber && select == true)
      {
         if(OrderType() == OP_BUY) buyCount++;
         else if(OrderType() == OP_SELL) sellCount++;
      }   
   }
   
   // Buy order condition
   if(JBQMPIndicator == "Buy"  && buyCount == 0 && gBuyTicket == 0 && SAR <= Open[0]) //took out && MACDAvg < 0 
   {
      // Close sell order
      for(order = 0; order <= OrdersTotal() - 1; order++)
      {
         select = OrderSelect(order,SELECT_BY_POS);
         
         if(OrderType() == OP_SELL && OrderMagicNumber() == MagicNumber && select == true)
         {
            // Close order
            bool closed = OrderClose(OrderTicket(),OrderLots(),Ask,Slippage,clrRed);
            if(closed == true) order--;
         }
      }
      
      // Open buy order
      Print("Stop Level:" + MarketInfo(_Symbol,MODE_STOPLEVEL));
      gBuyTicket = OrderSend(_Symbol,OP_BUY,LotSize,Ask,Slippage,0,0,"Buy order",MagicNumber,0,clrGreen);
      gSellTicket = 0;
      
      // Add stop loss & take profit to order
      if(gBuyTicket > 0)
      {
         select = OrderSelect(gBuyTicket,SELECT_BY_TICKET);
         
         // Calculate stop loss & take profit
         double stopLoss;
         stopLoss = SAR;
         
                  
         // Verify stop loss & take profit
         double stopLevel = MarketInfo(_Symbol,MODE_STOPLEVEL) * _Point;
         
         RefreshRates();
         double upperStopLevel = Ask + stopLevel;
         double lowerStopLevel = Bid - stopLevel;
         
         if(stopLoss >= lowerStopLevel && stopLoss  != 0) stopLoss = lowerStopLevel - _Point; 
         
         // Modify order
         bool modify = OrderModify(gBuyTicket,0,stopLoss,0,0);
      }
   }
   
      // Sell order condition
   if(JBQMPIndicator == "Sell" && sellCount == 0 && gSellTicket == 0 && SAR >=Open[0]) //took out && MACDAvg > 0 
   {
      // Close buy order
      for(order = 0; order <= OrdersTotal() - 1; order++)
      {
         select = OrderSelect(order,SELECT_BY_POS);
         
         if(OrderType() == OP_BUY && OrderMagicNumber() == MagicNumber && select == true)
         {
            // Close order
            closed = OrderClose(OrderTicket(),OrderLots(),Bid,Slippage,clrRed);
            
            if(closed == true)
            {
               gBuyTicket = 0;
               order--;
            }
         }
      }
      
      // Open sell order
      Print("Stop Level:" + MarketInfo(_Symbol,MODE_STOPLEVEL));
      gSellTicket = OrderSend(_Symbol,OP_SELL,LotSize,Bid,Slippage,0,0,"Sell order",MagicNumber,0,clrRed);
      gBuyTicket = 0;
      
      // Add stop loss & take profit to order
      
      if(gSellTicket > 0)
      {
         select = OrderSelect(gSellTicket,SELECT_BY_TICKET);
         
         // Calculate stop loss & take profit
         stopLoss = SAR;
         
         // Verify stop loss & take profit
         stopLevel = MarketInfo(_Symbol,MODE_STOPLEVEL) * _Point;
         
         RefreshRates();
         upperStopLevel = Ask + stopLevel;
         lowerStopLevel = Bid - stopLevel;
         
         if(stopLoss <= upperStopLevel && stopLoss != 0) stopLoss = upperStopLevel + _Point; 
         
         // Modify order
         modify = OrderModify(gSellTicket,0,stopLoss,0,0);
      }
   }
   
   // Trailing stop (Chapter 20)
   // do a comparison between SAR and last price to see PULL the sar up or down
   // right now, SAR is only re-calculated at the open of the bar (based on the prior close) and we miss catching profits on very long bars
   for(order = 0; order <= OrdersTotal() - 1; order++)
   {
      select = OrderSelect(order,SELECT_BY_POS);
            
      if(OrderMagicNumber() == MagicNumber && select == true)
      {
         RefreshRates();
         
         // Check buy order trailing stops
         if(OrderType() == OP_BUY)
         {
            double ts = ((iHigh(NULL,0,0) - SAR)/4) + SAR;
            double trailStopPrice = ts;
            trailStopPrice = NormalizeDouble(trailStopPrice,_Digits);
            
            double currentStopLoss = NormalizeDouble(OrderStopLoss(),_Digits);
            
           
            if(trailStopPrice > currentStopLoss)
            {
               modify = OrderModify(OrderTicket(),OrderOpenPrice(),trailStopPrice,OrderTakeProfit(),0);
            }
         }
         
         // Check sell order trailing stops
         else if(OrderType() == OP_SELL)
         {
            //ts = (SAR + iLow(NULL,0,0))/2;
            trailStopPrice = SAR;
            trailStopPrice = NormalizeDouble(trailStopPrice,_Digits);
            
            currentStopLoss = NormalizeDouble(OrderStopLoss(),_Digits);
            
           
            if(trailStopPrice < currentStopLoss)
            {
               modify = OrderModify(OrderTicket(),OrderOpenPrice(),trailStopPrice,OrderTakeProfit(),0);
            }
         }
      }
   }   
   
}
 }   

