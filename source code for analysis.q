//import
dbtc:("SDFFFFF"; enlist ",") 0: `C:/Users/wicky/Downloads/5530proj/daily_btc.csv;dbtc
dbtc: select from dbtc where date <=2024.03.10;dbtc
deth:("SDFFFFF"; enlist ",") 0: `C:/Users/wicky/Downloads/5530proj/daily_eth.csv;deth
deth: select from deth where date <=2024.03.10;deth
hbtc:("SDTFFFFF"; enlist ",") 0: `C:/Users/wicky/Downloads/5530proj/hourly_btc.csv;hbtc
hbtc: select from hbtc where date <=2024.03.10, date>=2021.01.01;hbtc
heth:("SDTFFFFF"; enlist ",") 0: `C:/Users/wicky/Downloads/5530proj/hourly_eth.csv;heth
heth: select from heth where date <=2024.03.10, date>=2021.01.01;heth
//calculate return
dbtc:update rtn:-1+close%prev close from dbtc;dbtc
deth:update rtn:-1+close%prev close from deth;deth
hbtc:update rtn:-1+close%prev close from hbtc;hbtc
heth:update rtn:-1+close%prev close from heth;heth
//functions
MA:{[x;n] n mavg x};
EMA:{[x;n] ema[2%(n+1);x]};
MACD:{[x;nFast;nSlow;nSig] diff:EMA[x;nFast]-EMA[x;nSlow]; sig:EMA[diff;nSig]; diff - sig};
RSI:{[x;n] x1:x - prev x; u:0|x1; d: 0|neg x1; 100 - 100%1+ EMA[u;n]%EMA[d;n] };
//funcitons for daily signals
cross_signal:{[m]
 m: update signalside:?[signal>0;1i;-1i], j:sums 1^i - prev i by sym from m;
 m: update signalidx:fills ?[0= deltas signalside;0N;j] by sym from m;
 update n:sums abs signalside, signaltime:first date by sym,signalidx from m
 }; 
 
cross_signal_bench:{[m]
 r: select from cross_signal[m] where n=1, 1 = abs signalside ;
 r: r upsert 0!select by sym from m; //add last row per symbol 
 r:update bps:10000*signalside*-1+pxexit%pxenter, nholds:(next j)-j by sym from update pxexit:next pxenter by sym from `sym`date xasc r;
 delete from r where null signalside
 };
//funcitons for hourly signals
cross_signal:{[m]
 m: update signalside:?[signal>0;1i;-1i], j:sums 1^i - prev i by sym from m;
 m: update signalidx:fills ?[0= deltas signalside;0N;j] by sym from m;
 update n:sums abs signalside, signaltime:first time by sym,signalidx from m
 }; 

cross_signal_bench:{[m]
 r: select from cross_signal[m] where n=1, 1 = abs signalside ;
 r: r upsert 0!select by sym from m; //add last row per symbol 
 r:update bps:10000*signalside*-1+pxexit%pxenter, nholds:(next j)-j by sym from update pxexit:next pxenter by sym from `sym`date`time xasc r; //this line handle the hourly data
 delete from r where null signalside
 };
//calculate the result for daily BTC  
dbtc: update emaS:EMA[close;5], emaL:EMA[close;30], macd:MACD[close;15;30;15] from dbtc;dbtc
result:cross_signal_bench[update signal:macd, pxenter:next open by sym from dbtc];
result:cross_signal_bench[update  signal:emaS-emaL, pxenter:next open by sym from dbtc];
result
//calculate the result for daily ETH  
deth: update emaS:EMA[close;5], emaL:EMA[close;30], macd:MACD[close;15;30;15] from deth;deth
result:cross_signal_bench[update signal:macd, pxenter:next open by sym from deth];
result:cross_signal_bench[update  signal:emaS-emaL, pxenter:next open by sym from deth];
result
//calculate the result for hourly BTC  
hbtc: update emaS:EMA[close;5], emaL:EMA[close;30], macd:MACD[close;15;30;15] from hbtc;hbtc
result:cross_signal_bench[update signal:macd, pxenter:next open by sym from hbtc];
result:cross_signal_bench[update  signal:emaS-emaL, pxenter:next open by sym from hbtc];
result
//calculate the result for hourly ETH  
heth: update emaS:EMA[close;5], emaL:EMA[close;30], macd:MACD[close;15;30;15] from heth;heth
result:cross_signal_bench[update signal:macd, pxenter:next open by sym from heth];
result:cross_signal_bench[update  signal:emaS-emaL, pxenter:next open by sym from heth];
result
//performance analsis
payoff: select avg_return:avg ((bps % 10000) * pxenter) ,acc_return: sum ((bps % 10000) * pxenter) by sym from result;payoff
winningTrades: select wins: count i by sym from result where bps > 0;winningTrades
losingTrades: select loses: count i by sym from result where bps < 0;losingTrades
averageWin: select avg_win: avg bps by sym from result where bps > 0;averageWin
averageLoss: select avg_lose: avg bps by sym from result where bps < 0;averageLoss
analysis: payoff lj winningTrades lj losingTrades lj averageWin lj averageLoss;
analysis: update winlose_ratio: wins % loses from analysis;analysis
