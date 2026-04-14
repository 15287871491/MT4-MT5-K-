//+------------------------------------------------------------------+
//| 中文仓位控制面板 - 全参数可调版
//| 整体位置 / 颜色 全部在顶部参数控制
//+------------------------------------------------------------------+
#property copyright "2026"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| 输入参数 —— 全部在这里改
//+------------------------------------------------------------------+
input double    DefaultLot        = 0.05;                // 仓位大小
input int       Inp_Slippage      = 50;                // 滑点
input ulong     Inp_Magic         = 20260405;          // 魔术码
input int       StopLoss_Pips     = 200;                // 止损点数
input int       PANEL_X           = 5;                 // 整个面板左右位置
input int       PANEL_Y           = 280;               // 整个面板上下位置
input int       FONT_SIZE         = 18;                // 倒计时字体大小

input int       InpTrailingStep   = 150;     // 追踪步长

// 面板颜色
input color     COL_PANEL_BG      = clrLightBlue;      // 面板背景色
input color     COL_PANEL_BORDER  = clrSteelBlue;      // 面板边框色
// 按钮颜色
input color     COL_BTN_BUY_BG    = clrDodgerBlue;     // 买多按钮背景
input color     COL_BTN_SELL_BG   = clrRed;            // 卖空按钮背景
input color     COL_BTN_FUNC_BG   = clrCyan;           // 功能按钮背景
input color     COL_BTN_CLOSE_BG  = clrSlateBlue;      // 平仓按钮背景
input color     COL_BTN_LOT_BG    = clrRoyalBlue;      // 手数按钮背景
input color     COL_BTN_BUY_PART  = clrMediumSlateBlue;// 多单分批背景
input color     COL_BTN_SELL_PART = clrLightPink;      // 空单分批背景
// 文字颜色
input color     COL_TEXT_WHITE    = clrWhite;          // 白色文字
input color     COL_TEXT_BLACK    = clrBlack;          // 黑色文字
// 倒计时颜色
input color     COL_COUNTDOWN     = clrRed;            // 倒计时文字颜色

//+------------------------------------------------------------------+
//| 全局变量
//+------------------------------------------------------------------+
double currentLot = 0.05;
int digits;
datetime lastBarTime = 0;
int      barSeconds  = 0;
double g_point;

bool   g_trail_buy  = false;   // 多单追踪开关
bool   g_trail_sell = false;   // 空单追踪开关

//+------------------------------------------------------------------+
//| 初始化
//+------------------------------------------------------------------+
int OnInit()
{
   g_point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   digits   = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   
   currentLot = DefaultLot;
   CreateButtons();
   InitCountdown();
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| 注销清理
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   ObjectsDeleteAll(0, 0);
}

//+------------------------------------------------------------------+
//| 创建面板背景
//+------------------------------------------------------------------+
void CreatePanelBg(int x, int y, int w, int h)
{
   ObjectCreate(0, "panel_bg", OBJ_RECTANGLE, 0, 0, 0);
   ObjectSetInteger(0, "panel_bg", OBJPROP_XDISTANCE, PANEL_X + x);
   ObjectSetInteger(0, "panel_bg", OBJPROP_YDISTANCE, PANEL_Y + y);
   ObjectSetInteger(0, "panel_bg", OBJPROP_XSIZE, w);
   ObjectSetInteger(0, "panel_bg", OBJPROP_YSIZE, h);
   ObjectSetInteger(0, "panel_bg", OBJPROP_COLOR, COL_PANEL_BORDER);
   ObjectSetInteger(0, "panel_bg", OBJPROP_BGCOLOR, COL_PANEL_BG);
   ObjectSetInteger(0, "panel_bg", OBJPROP_ZORDER, 0);
}

//+------------------------------------------------------------------+
//| 创建所有按钮
//+------------------------------------------------------------------+
void CreateButtons()
{
   OnDeinit(0);
   CreatePanelBg(0, -42, 340, 210);

   // 手数输入框
   CreateEdit("edit_lot", 10, -35, 70, 25, DoubleToString(currentLot, 2));
   
   // 快捷手数
   CreateButton("lot_001",  85, -35, 45, 25, "0.01", COL_TEXT_WHITE, COL_BTN_LOT_BG);
   CreateButton("lot_005", 135, -35, 45, 25, "0.05", COL_TEXT_WHITE, COL_BTN_LOT_BG);
   CreateButton("lot_010", 185, -35, 45, 25, "0.10", COL_TEXT_WHITE, COL_BTN_LOT_BG);
   CreateButton("lot_020", 235, -35, 45, 25, "0.20", COL_TEXT_WHITE, COL_BTN_LOT_BG);

   // 开仓
   CreateButton("btn_buy",   10,  5, 150, 30, "买多",   COL_TEXT_WHITE, COL_BTN_BUY_BG);
   CreateButton("btn_sell", 170, 5, 150, 30, "卖空",   COL_TEXT_WHITE, COL_BTN_SELL_BG);

   // 功能行
   CreateButton("btn_close_all", 10, 45, 100, 25, "全平仓", COL_TEXT_WHITE, COL_BTN_CLOSE_BG);
   CreateButton("btn_be",        115, 45, 100, 25, "一键保本",COL_TEXT_BLACK,COL_BTN_FUNC_BG);

   // 独立追踪按钮
   CreateButton("btn_trail_buy",  220, 45, 100, 25, g_trail_buy ? "关闭" : "多跟踪止损", COL_TEXT_WHITE, COL_BTN_BUY_BG);
   CreateButton("btn_trail_sell", 220, 75, 100, 25, g_trail_sell ? "关闭" : "空跟踪止损", COL_TEXT_WHITE, COL_BTN_SELL_BG);

   // 多单分批
   CreateButton("btn_buy_20",   10, 110, 60,25,"平多20%",COL_TEXT_WHITE,COL_BTN_BUY_PART);
   CreateButton("btn_buy_30",   75, 110, 60,25,"平多30%",COL_TEXT_WHITE,COL_BTN_BUY_PART);
   CreateButton("btn_buy_50",  140, 110, 60,25,"平多50%",COL_TEXT_WHITE,COL_BTN_BUY_PART);
   CreateButton("btn_buy_80",  205, 110, 60,25,"平多80%",COL_TEXT_WHITE,COL_BTN_BUY_PART);
   CreateButton("btn_buy_all", 270, 110, 60,25,"全平多", COL_TEXT_WHITE,COL_BTN_BUY_PART);

   // 空单分批
   CreateButton("btn_sell_20",  10,140,60,25,"平空20%",COL_TEXT_WHITE,COL_BTN_SELL_PART);
   CreateButton("btn_sell_30",  75,140,60,25,"平空30%",COL_TEXT_WHITE,COL_BTN_SELL_PART);
   CreateButton("btn_sell_50", 140,140,60,25,"平空50%",COL_TEXT_WHITE,COL_BTN_SELL_PART);
   CreateButton("btn_sell_80", 205,140,60,25,"平空80%",COL_TEXT_WHITE,COL_BTN_SELL_PART);
   CreateButton("btn_sell_all",270,140,60,25,"全平空",COL_TEXT_WHITE,COL_BTN_SELL_PART);
}

//+------------------------------------------------------------------+
//| 按钮创建
//+------------------------------------------------------------------+
void CreateButton(string name, int x, int y, int w, int h, string text, color txtCol, color bgCol)
{
   ObjectCreate(0, name, OBJ_BUTTON, 0,0,0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, PANEL_X + x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, PANEL_Y + y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetString(0,  name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, txtCol);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bgCol);
}

//+------------------------------------------------------------------+
//| 输入框
//+------------------------------------------------------------------+
void CreateEdit(string name, int x, int y, int w, int h, string def)
{
   ObjectCreate(0, name, OBJ_EDIT, 0,0,0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, PANEL_X + x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, PANEL_Y + y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetString(0,  name, OBJPROP_TEXT, def);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, clrMidnightBlue);
}

//+------------------------------------------------------------------+
//| 鼠标事件
//+------------------------------------------------------------------+
void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
{
   if(id == CHARTEVENT_OBJECT_ENDEDIT && sparam == "edit_lot")
   {
      double v = StringToDouble(ObjectGetString(0, sparam, OBJPROP_TEXT));
      if(v >= 0.01) currentLot = v;
   }

   if(id != CHARTEVENT_OBJECT_CLICK) return;
   string name = sparam;

   if(name == "lot_001") { currentLot = 0.01; CreateButtons(); }
   if(name == "lot_005") { currentLot = 0.05; CreateButtons(); }
   if(name == "lot_010") { currentLot = 0.10; CreateButtons(); }
   if(name == "lot_020") { currentLot = 0.20; CreateButtons(); }

   if(name == "btn_buy") OpenOrder(ORDER_TYPE_BUY);
   if(name == "btn_sell") OpenOrder(ORDER_TYPE_SELL);

   if(name == "btn_close_all") CloseAll();
   if(name == "btn_be") BreakEven();

   // 独立追踪开关
   if(name == "btn_trail_buy")  { g_trail_buy  = !g_trail_buy;  CreateButtons(); }
   if(name == "btn_trail_sell") { g_trail_sell = !g_trail_sell; CreateButtons(); }

   if(name == "btn_buy_20") ClosePart(POSITION_TYPE_BUY, 0.2);
   if(name == "btn_buy_30") ClosePart(POSITION_TYPE_BUY, 0.3);
   if(name == "btn_buy_50") ClosePart(POSITION_TYPE_BUY, 0.5);
   if(name == "btn_buy_80") ClosePart(POSITION_TYPE_BUY, 0.8);
   if(name == "btn_buy_all") ClosePart(POSITION_TYPE_BUY, 1.0);

   if(name == "btn_sell_20") ClosePart(POSITION_TYPE_SELL, 0.2);
   if(name == "btn_sell_30") ClosePart(POSITION_TYPE_SELL, 0.3);
   if(name == "btn_sell_50") ClosePart(POSITION_TYPE_SELL, 0.5);
   if(name == "btn_sell_80") ClosePart(POSITION_TYPE_SELL, 0.8);
   if(name == "btn_sell_all") ClosePart(POSITION_TYPE_SELL, 1.0);
}

//+------------------------------------------------------------------+
//| 开仓
//+------------------------------------------------------------------+
bool OpenOrder(ENUM_ORDER_TYPE type)
{
   MqlTradeRequest req; 
   MqlTradeResult res; 
   ZeroMemory(req); 
   ZeroMemory(res);

   double price = (type == ORDER_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double sl    = 0.0;

   if(type == ORDER_TYPE_BUY)
   {
      sl = NormalizeDouble(price - StopLoss_Pips * g_point, digits);
   }
   else
   {
      sl = NormalizeDouble(price + StopLoss_Pips * g_point, digits);
   }

   req.action        = TRADE_ACTION_DEAL;
   req.symbol        = _Symbol;
   req.volume        = currentLot;
   req.type          = type;
   req.price         = price;
   req.sl            = sl;
   req.deviation     = Inp_Slippage;
   req.magic         = Inp_Magic;
   req.type_filling  = ORDER_FILLING_IOC;

   bool ok = OrderSend(req, res);
   if(!ok) Print("开仓失败 错误码:",res.retcode," 价格:",price," SL:",sl);
   return ok;
}

//+------------------------------------------------------------------+
//| 全平仓
//+------------------------------------------------------------------+
void CloseAll()
{
   for(int i = PositionsTotal()-1; i>=0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket) && PositionGetInteger(POSITION_MAGIC) == Inp_Magic)
      {
         MqlTradeRequest req; MqlTradeResult res; ZeroMemory(req); ZeroMemory(res);
         req.action=TRADE_ACTION_DEAL;
         req.symbol=_Symbol;
         req.volume=PositionGetDouble(POSITION_VOLUME);
         req.type=(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
         req.price=(req.type==ORDER_TYPE_SELL) ? SymbolInfoDouble(_Symbol,SYMBOL_BID) : SymbolInfoDouble(_Symbol,SYMBOL_ASK);
         req.deviation=Inp_Slippage;
         req.magic=Inp_Magic;
         req.type_filling=ORDER_FILLING_IOC;
         req.position=ticket;
         OrderSend(req,res);
      }
   }
}

//+------------------------------------------------------------------+
//| 一键保本
//+------------------------------------------------------------------+
void BreakEven()
{
   int BE_SHIFT_PIPS = 100;
   
   for(int i=0; i<PositionsTotal(); i++)
   {
      ulong t = PositionGetTicket(i);
      if(!PositionSelectByTicket(t)) continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol || PositionGetInteger(POSITION_MAGIC)!=Inp_Magic) continue;
      
      double op = PositionGetDouble(POSITION_PRICE_OPEN);
      bool isBuy = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY;
      double newSL = isBuy ? NormalizeDouble(op + BE_SHIFT_PIPS*g_point, digits)
                           : NormalizeDouble(op - BE_SHIFT_PIPS*g_point, digits);
      
      MqlTradeRequest req; MqlTradeResult res; ZeroMemory(req); ZeroMemory(res);
      req.action=TRADE_ACTION_SLTP;
      req.symbol=_Symbol;
      req.position=t;
      req.sl=newSL;
      req.tp=PositionGetDouble(POSITION_TP);
      OrderSend(req,res);
   }
}

//+------------------------------------------------------------------+
//| 分批平仓
//+------------------------------------------------------------------+
void ClosePart(ENUM_POSITION_TYPE posType, double percent)
{
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double min  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   
   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket) 
      || PositionGetInteger(POSITION_MAGIC)!=Inp_Magic 
      || PositionGetInteger(POSITION_TYPE)!=posType) continue;
      
      double total    = PositionGetDouble(POSITION_VOLUME);
      double closeVol = MathCeil(total * percent / step) * step;
      if(closeVol < min) closeVol = min;
      if(closeVol > total) closeVol = total;
      
      MqlTradeRequest req; MqlTradeResult res; ZeroMemory(req); ZeroMemory(res);
      req.action=TRADE_ACTION_DEAL;
      req.symbol=_Symbol;
      req.volume=closeVol;
      req.type=(posType==POSITION_TYPE_BUY) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
      req.price=(req.type==ORDER_TYPE_SELL) ? SymbolInfoDouble(_Symbol,SYMBOL_BID) : SymbolInfoDouble(_Symbol,SYMBOL_ASK);
      req.deviation=Inp_Slippage;
      req.magic=Inp_Magic;
      req.type_filling=ORDER_FILLING_IOC;
      req.position=ticket;
      OrderSend(req,res);
   }
}

//+------------------------------------------------------------------+
//| 多单追踪
//+------------------------------------------------------------------+
void TrailBuy()
{
   if(!g_trail_buy) return;

   for(int i=0; i<PositionsTotal(); i++)
   {
      ulong t = PositionGetTicket(i);
      if(!PositionSelectByTicket(t)) continue;
      if(PositionGetInteger(POSITION_MAGIC) != Inp_Magic) continue;
      if(PositionGetInteger(POSITION_TYPE) != POSITION_TYPE_BUY) continue;

      double bid    = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double sl     = PositionGetDouble(POSITION_SL);
      double newSL  = bid - InpTrailingStep * g_point;
      newSL = NormalizeDouble(newSL, digits);

      if(newSL > sl)
      {
         MqlTradeRequest req; MqlTradeResult res; ZeroMemory(req); ZeroMemory(res);
         req.action   = TRADE_ACTION_SLTP;
         req.symbol   = _Symbol;
         req.position = t;
         req.sl       = newSL;
         req.tp       = PositionGetDouble(POSITION_TP);
         OrderSend(req, res);
      }
   }
}

//+------------------------------------------------------------------+
//| 空单追踪
//+------------------------------------------------------------------+
void TrailSell()
{
   if(!g_trail_sell) return;

   for(int i=0; i<PositionsTotal(); i++)
   {
      ulong t = PositionGetTicket(i);
      if(!PositionSelectByTicket(t)) continue;
      if(PositionGetInteger(POSITION_MAGIC) != Inp_Magic) continue;
      if(PositionGetInteger(POSITION_TYPE) != POSITION_TYPE_SELL) continue;

      double ask    = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double sl     = PositionGetDouble(POSITION_SL);
      double newSL  = ask + InpTrailingStep * g_point;
      newSL = NormalizeDouble(newSL, digits);

      if(newSL < sl)
      {
         MqlTradeRequest req; MqlTradeResult res; ZeroMemory(req); ZeroMemory(res);
         req.action   = TRADE_ACTION_SLTP;
         req.symbol   = _Symbol;
         req.position = t;
         req.sl       = newSL;
         req.tp       = PositionGetDouble(POSITION_TP);
         OrderSend(req, res);
      }
   }
}

//+------------------------------------------------------------------+
//| 倒计时
//+------------------------------------------------------------------+
void InitCountdown()
{
   int period = _Period;
   if(period == PERIOD_M1) barSeconds = 60;
   else if(period == PERIOD_M5) barSeconds = 300;
   else if(period == PERIOD_M15) barSeconds = 900;
   else if(period == PERIOD_M30) barSeconds = 1800;
   else if(period == PERIOD_H1) barSeconds = 3600;
   else if(period == PERIOD_H4) barSeconds = 14400;
   else if(period == PERIOD_D1) barSeconds = 86400;
   else barSeconds = 60;
   
   lastBarTime = iTime(_Symbol, _Period, 0);
}

string GetCountdownText()
{
   datetime now  = TimeCurrent();
   datetime next = lastBarTime + barSeconds;
   int rem       = next - now;
   if(rem <= 0) { InitCountdown(); rem = barSeconds; }
   int m = rem / 60;
   int s = rem % 60;
   return StringFormat("K线收盘：%02d:%02d", m, s);
}

void ShowCountdownLabel()
{
   int X = PANEL_X + 10;
   int Y = PANEL_Y + 175;
   
   ObjectDelete(0, "cd_label");
   ObjectCreate(0, "cd_label", OBJ_LABEL, 0,0,0);
   ObjectSetInteger(0, "cd_label", OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, "cd_label", OBJPROP_XDISTANCE, X);
   ObjectSetInteger(0, "cd_label", OBJPROP_YDISTANCE, Y);
   ObjectSetString(0,  "cd_label", OBJPROP_TEXT, GetCountdownText());
   ObjectSetInteger(0, "cd_label", OBJPROP_COLOR, COL_COUNTDOWN);
   ObjectSetInteger(0, "cd_label", OBJPROP_FONTSIZE, FONT_SIZE);
   ObjectSetInteger(0, "cd_label", OBJPROP_BACK, true);
}

void OnTick()
{
   ShowCountdownLabel();
   TrailBuy();
   TrailSell();
}
//+------------------------------------------------------------------+