//+------------------------------------------------------------------+
//| 中文一键交易面板 (MT4 版)                                     |
//| 功能：快捷手数、买多卖空、分批平仓、追踪止损、保本、K线倒计时   |
//+------------------------------------------------------------------+
#property copyright "2026"
#property link      ""
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| 输入参数（全部可在图表设置里调整）                             |
//+------------------------------------------------------------------+
input double    DefaultLot        = 0.05;        // 默认手数
input int       Inp_Slippage      = 50;          // 滑点
input int       Inp_Magic         = 20260405;    // 魔术号
input int       StopLoss_Pips     = 200;         // 止损点数
input int       PANEL_X           = 5;           // 面板X坐标
input int       PANEL_Y           = 280;         // 面板Y坐标
input int       PANEL_WIDTH       = 340;         // 面板宽度
input int       PANEL_HEIGHT      = 210;         // 面板高度
input int       FONT_SIZE         = 18;          // 字体大小
input int       InpTrailingStep   = 150;         // 追踪止损步长

// 颜色参数
input color     COL_PANEL_BG      = C'220,240,255';   // 面板背景
input color     COL_PANEL_BORDER  = C'100,150,200';   // 面板边框
input color     COL_BTN_BUY_BG    = C'30,144,255';    // 买多按钮
input color     COL_BTN_SELL_BG   = C'255,60,60';     // 卖空按钮
input color     COL_BTN_FUNC_BG   = C'0,255,255';     // 功能按钮
input color     COL_BTN_CLOSE_BG  = C'100,150,200';   // 平仓按钮
input color     COL_BTN_LOT_BG    = C'65,105,225';    // 手数按钮
input color     COL_BTN_BUY_PART  = C'120,180,255';   // 多单分批
input color     COL_BTN_SELL_PART = C'255,200,200';   // 空单分批
input color     COL_TEXT_WHITE    = clrWhite;         // 白色文字
input color     COL_TEXT_BLACK    = clrBlack;         // 黑色文字
input color     COL_COUNTDOWN     = clrRed;           // 倒计时颜色

//+------------------------------------------------------------------+
//| 全局变量                                                         |
//+------------------------------------------------------------------+
double currentLot = 0.05;          // 当前选择手数
int    digits;                     // 品种小数位数
datetime lastBarTime = 0;          // 上一根K线时间
int    barSeconds = 0;             // K线周期秒数
double g_point;                    // 点值

bool   g_trail_buy  = false;       // 多单追踪开关
bool   g_trail_sell = false;       // 空单追踪开关

//+------------------------------------------------------------------+
//| 初始化：加载时执行                                               |
//+------------------------------------------------------------------+
int OnInit()
{
   digits   = Digits;
   g_point  = Point;
   currentLot = DefaultLot;
   
   CreateButtons();       // 创建面板
   InitCountdown();       // 初始化倒计时
   
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| 反初始化：移除EA时一次性清空所有对象，无残留                     |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   int total = ObjectsTotal();
   for(int i = total - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i);
      
      // 清空本EA创建的所有对象
      if(name == "panel_bg"               ||  // 背景
         name == "edit_lot"               ||  // 手数输入框
         name == "cd_label"               ||  // 倒计时
         StringFind(name, "btn_") == 0   ||  // 所有按钮
         StringFind(name, "lot_") == 0)      // 所有快捷手数
      {
         ObjectDelete(0, name);
      }
   }
}

//+------------------------------------------------------------------+
//| 创建面板背景矩形                                                 |
//+------------------------------------------------------------------+
void CreatePanelBg(int x,int y,int w,int h)
{
   ObjectCreate(0,"panel_bg",OBJ_RECTANGLE,0,0,0);
   ObjectSetInteger(0,"panel_bg",OBJPROP_XDISTANCE,PANEL_X + x);
   ObjectSetInteger(0,"panel_bg",OBJPROP_YDISTANCE,PANEL_Y + y);
   ObjectSetInteger(0,"panel_bg",OBJPROP_XSIZE,PANEL_WIDTH);
   ObjectSetInteger(0,"panel_bg",OBJPROP_YSIZE,PANEL_HEIGHT);
   ObjectSetInteger(0,"panel_bg",OBJPROP_COLOR,COL_PANEL_BORDER);
   ObjectSetInteger(0,"panel_bg",OBJPROP_BGCOLOR,COL_PANEL_BG);
   ObjectSetInteger(0,"panel_bg",OBJPROP_ZORDER,0);
}

//+------------------------------------------------------------------+
//| 创建所有按钮与界面                                               |
//+------------------------------------------------------------------+
void CreateButtons()
{
   OnDeinit(0);  // 先清空旧对象
   CreatePanelBg(0, -42, 340, 210);

   // 手数输入框
   CreateEdit("edit_lot", 10, -35, 70, 25, DoubleToString(currentLot));
   
   // 快捷手数
   CreateButton("lot_001",  85, -35, 45, 25, "0.01", COL_TEXT_WHITE, COL_BTN_LOT_BG);
   CreateButton("lot_005", 135, -35, 45, 25, "0.05", COL_TEXT_WHITE, COL_BTN_LOT_BG);
   CreateButton("lot_010", 185, -35, 45, 25, "0.10", COL_TEXT_WHITE, COL_BTN_LOT_BG);
   CreateButton("lot_020", 235, -35, 45, 25, "0.20", COL_TEXT_WHITE, COL_BTN_LOT_BG);

   // 买多 / 卖空
   CreateButton("btn_buy",   10,   5, 150, 30, "买多",         COL_TEXT_WHITE, COL_BTN_BUY_BG);
   CreateButton("btn_sell", 170,   5, 150, 30, "卖空",         COL_TEXT_WHITE, COL_BTN_SELL_BG);

   // 功能区
   CreateButton("btn_close_all",  10, 45, 100, 25, "全平仓",    COL_TEXT_WHITE, COL_BTN_CLOSE_BG);
   CreateButton("btn_be",        115, 45, 100, 25, "一键保本",  COL_TEXT_BLACK, COL_BTN_FUNC_BG);

   // 追踪止损
   CreateButton("btn_trail_buy",  220, 45, 100, 25, g_trail_buy ? "关闭" : "多跟踪止损", COL_TEXT_WHITE, COL_BTN_BUY_BG);
   CreateButton("btn_trail_sell", 220, 75, 100, 25, g_trail_sell ? "关闭" : "空跟踪止损", COL_TEXT_WHITE, COL_BTN_SELL_BG);

   // 多单分批平仓
   CreateButton("btn_buy_20",   10, 110, 60, 25, "平多20%", COL_TEXT_WHITE, COL_BTN_BUY_PART);
   CreateButton("btn_buy_30",   75, 110, 60, 25, "平多30%", COL_TEXT_WHITE, COL_BTN_BUY_PART);
   CreateButton("btn_buy_50",  140, 110, 60, 25, "平多50%", COL_TEXT_WHITE, COL_BTN_BUY_PART);
   CreateButton("btn_buy_80",  205, 110, 60, 25, "平多80%", COL_TEXT_WHITE, COL_BTN_BUY_PART);
   CreateButton("btn_buy_all", 270, 110, 60, 25, "全平多",  COL_TEXT_WHITE, COL_BTN_BUY_PART);

   // 空单分批平仓
   CreateButton("btn_sell_20",  10, 140, 60, 25, "平空20%", COL_TEXT_WHITE, COL_BTN_SELL_PART);
   CreateButton("btn_sell_30",  75, 140, 60, 25, "平空30%", COL_TEXT_WHITE, COL_BTN_SELL_PART);
   CreateButton("btn_sell_50", 140, 140, 60, 25, "平空50%", COL_TEXT_WHITE, COL_BTN_SELL_PART);
   CreateButton("btn_sell_80", 205, 140, 60, 25, "平空80%", COL_TEXT_WHITE, COL_BTN_SELL_PART);
   CreateButton("btn_sell_all",270, 140, 60, 25, "全平空",  COL_TEXT_WHITE, COL_BTN_SELL_PART);
}

//+------------------------------------------------------------------+
//| 创建单个按钮                                                     |
//+------------------------------------------------------------------+
void CreateButton(string name,int x,int y,int w,int h,string txt,color txtc,color bgc)
{
   ObjectCreate(0,name,OBJ_BUTTON,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,PANEL_X + x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,PANEL_Y + y);
   ObjectSetInteger(0,name,OBJPROP_XSIZE,w);
   ObjectSetInteger(0,name,OBJPROP_YSIZE,h);
   ObjectSetString(0,name,OBJPROP_TEXT,txt);
   ObjectSetInteger(0,name,OBJPROP_COLOR,txtc);
   ObjectSetInteger(0,name,OBJPROP_BGCOLOR,bgc);
}

//+------------------------------------------------------------------+
//| 创建输入框                                                       |
//+------------------------------------------------------------------+
void CreateEdit(string name,int x,int y,int w,int h,string def)
{
   ObjectCreate(0,name,OBJ_EDIT,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,PANEL_X + x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,PANEL_Y + y);
   ObjectSetInteger(0,name,OBJPROP_XSIZE,w);
   ObjectSetInteger(0,name,OBJPROP_YSIZE,h);
   ObjectSetString(0,name,OBJPROP_TEXT,def);
   ObjectSetInteger(0,name,OBJPROP_COLOR,clrWhite);
   ObjectSetInteger(0,name,OBJPROP_BGCOLOR,clrMidnightBlue);
}

//+------------------------------------------------------------------+
//| 鼠标点击事件处理                                                 |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,const long& lparam,const double& dparam,const string& sparam)
{
   // 手数输入框修改
   if(id == CHARTEVENT_OBJECT_ENDEDIT && sparam == "edit_lot")
   {
      double v = StringToDouble(ObjectGetString(0, sparam, OBJPROP_TEXT));
      if(v >= 0.01) currentLot = v;
   }

   if(id != CHARTEVENT_OBJECT_CLICK) return;
   string name = sparam;

   // 快捷手数
   if(name == "lot_001") { currentLot = 0.01; CreateButtons(); }
   if(name == "lot_005") { currentLot = 0.05; CreateButtons(); }
   if(name == "lot_010") { currentLot = 0.10; CreateButtons(); }
   if(name == "lot_020") { currentLot = 0.20; CreateButtons(); }

   // 开仓
   if(name == "btn_buy")  OpenOrder(OP_BUY);
   if(name == "btn_sell") OpenOrder(OP_SELL);

   // 平仓功能
   if(name == "btn_close_all") CloseAll();
   if(name == "btn_be")        BreakEven();

   // 追踪止损开关
   if(name == "btn_trail_buy")  { g_trail_buy  = !g_trail_buy;  CreateButtons(); }
   if(name == "btn_trail_sell") { g_trail_sell = !g_trail_sell; CreateButtons(); }

   // 多单分批
   if(name == "btn_buy_20")   ClosePart(OP_BUY, 0.2);
   if(name == "btn_buy_30")   ClosePart(OP_BUY, 0.3);
   if(name == "btn_buy_50")   ClosePart(OP_BUY, 0.5);
   if(name == "btn_buy_80")   ClosePart(OP_BUY, 0.8);
   if(name == "btn_buy_all")  ClosePart(OP_BUY, 1.0);

   // 空单分批
   if(name == "btn_sell_20")  ClosePart(OP_SELL, 0.2);
   if(name == "btn_sell_30")  ClosePart(OP_SELL, 0.3);
   if(name == "btn_sell_50")  ClosePart(OP_SELL, 0.5);
   if(name == "btn_sell_80")  ClosePart(OP_SELL, 0.8);
   if(name == "btn_sell_all") ClosePart(OP_SELL, 1.0);
}

//+------------------------------------------------------------------+
//| 开仓函数                                                         |
//+------------------------------------------------------------------+
bool OpenOrder(int cmd)
{
   double price = (cmd == OP_BUY) ? Ask : Bid;
   double sl    = 0.0;

   if(cmd == OP_BUY)
      sl = NormalizeDouble(price - StopLoss_Pips * g_point, digits);
   else
      sl = NormalizeDouble(price + StopLoss_Pips * g_point, digits);

   int ticket = OrderSend(Symbol(), cmd, currentLot, price, Inp_Slippage, sl, 0, "", Inp_Magic, 0, clrRed);
   if(ticket < 0) Print("开仓失败 错误码:", GetLastError());
   return ticket > 0;
}

//+------------------------------------------------------------------+
//| 全部平仓                                                         |
//+------------------------------------------------------------------+
void CloseAll()
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderSymbol() != Symbol() || OrderMagicNumber() != Inp_Magic) continue;
         if(OrderType() == OP_BUY)  OrderClose(OrderTicket(), OrderLots(), Bid, 3, clrRed);
         if(OrderType() == OP_SELL) OrderClose(OrderTicket(), OrderLots(), Ask, 3, clrRed);
      }
   }
}

//+------------------------------------------------------------------+
//| 一键保本（止损移到开仓价+100点）                                 |
//+------------------------------------------------------------------+
void BreakEven()
{
   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderSymbol() != Symbol() || OrderMagicNumber() != Inp_Magic) continue;
         double op    = OrderOpenPrice();
         double newSL = 0;

         if(OrderType() == OP_BUY)
            newSL = NormalizeDouble(op + 100 * g_point, digits);
         if(OrderType() == OP_SELL)
            newSL = NormalizeDouble(op - 100 * g_point, digits);
         
         OrderModify(OrderTicket(), OrderOpenPrice(), newSL, OrderTakeProfit(), 0);
      }
   }
}

//+------------------------------------------------------------------+
//| 分批平仓                                                         |
//+------------------------------------------------------------------+
void ClosePart(int cmd,double pct)
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderSymbol() != Symbol() || OrderMagicNumber() != Inp_Magic) continue;
         if(OrderType() != cmd) continue;

         double closeLot = NormalizeDouble(OrderLots() * pct, 2);
         if(closeLot < 0.01)  closeLot = 0.01;
         if(closeLot > OrderLots()) closeLot = OrderLots();

         if(cmd == OP_BUY)  OrderClose(OrderTicket(), closeLot, Bid, 3);
         if(cmd == OP_SELL) OrderClose(OrderTicket(), closeLot, Ask, 3);
      }
   }
}

//+------------------------------------------------------------------+
//| 多单追踪止损                                                     |
//+------------------------------------------------------------------+
void TrailBuy()
{
   if(!g_trail_buy) return;

   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderSymbol() != Symbol() || OrderMagicNumber() != Inp_Magic) continue;
         if(OrderType() != OP_BUY) continue;

         double newSL = NormalizeDouble(Bid - InpTrailingStep * g_point, digits);
         if(newSL > OrderStopLoss() && newSL > 0)
         {
            OrderModify(OrderTicket(), OrderOpenPrice(), newSL, OrderTakeProfit(), 0);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| 空单追踪止损                                                     |
//+------------------------------------------------------------------+
void TrailSell()
{
   if(!g_trail_sell) return;

   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderSymbol() != Symbol() || OrderMagicNumber() != Inp_Magic) continue;
         if(OrderType() != OP_SELL) continue;

         double newSL = NormalizeDouble(Ask + InpTrailingStep * g_point, digits);
         if(newSL < OrderStopLoss() && newSL > 0)
         {
            OrderModify(OrderTicket(), OrderOpenPrice(), newSL, OrderTakeProfit(), 0);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| 初始化K线倒计时                                                  |
//+------------------------------------------------------------------+
void InitCountdown()
{
   int p = Period();
   if(p == PERIOD_M1)      barSeconds = 60;
   else if(p == PERIOD_M5) barSeconds = 300;
   else if(p == PERIOD_M15)barSeconds = 900;
   else if(p == PERIOD_M30)barSeconds = 1800;
   else if(p == PERIOD_H1) barSeconds = 3600;
   else barSeconds = 60;
   
   lastBarTime = Time[0];
}

//+------------------------------------------------------------------+
//| 倒计时文字                                                       |
//+------------------------------------------------------------------+
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

//+------------------------------------------------------------------+
//| 显示倒计时标签                                                   |
//+------------------------------------------------------------------+
void ShowCountdownLabel()
{
   int X = PANEL_X + 10;
   int Y = PANEL_Y + 175;
   
   ObjectDelete(0, "cd_label");
   ObjectCreate(0, "cd_label", OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "cd_label", OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, "cd_label", OBJPROP_XDISTANCE, X);
   ObjectSetInteger(0, "cd_label", OBJPROP_YDISTANCE, Y);
   ObjectSetString(0, "cd_label", OBJPROP_TEXT, GetCountdownText());
   ObjectSetInteger(0, "cd_label", OBJPROP_COLOR, COL_COUNTDOWN);
   ObjectSetInteger(0, "cd_label", OBJPROP_FONTSIZE, FONT_SIZE);
   ObjectSetInteger(0, "cd_label", OBJPROP_BACK, true);
}

//+------------------------------------------------------------------+
//| 每TICK执行                                                       |
//+------------------------------------------------------------------+
void OnTick()
{
   ShowCountdownLabel();
   TrailBuy();
   TrailSell();
}
//+------------------------------------------------------------------+