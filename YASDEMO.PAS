Program YasDemo;
{
  YasDemo Version 1.1 - Quick and dirty, multiple async port demo for YASYNC.

  Run like this:

    yasdemo nedpshbbbbb [...]

  Where: n   = Serial port number, 1..4
         e   = Echo option, E=Echo keyboard on screen (HDX), N=No Echo (FDX)
         d   = Data bits, 5..8
         p   = Parity, E,O,N,0 or 1
         s   = Stop bits, 1 or 2
         h   = Handshaking: N=None, D=Dtr/Dsr, C=Rts/Cts, X=Xon/Xoff
         b.. = Data rate, bits per second

  Example:

    yasdemo 3N7E2X1200 1E8N1N9600 2E8N1N9600

  Translation - Establish three windows:

    1. COM3, No Echo, 7 bits, even parity, 2 stop bits, Xon/Xoff handshaking,
       1200 Bps.

    2. COM1, Echo, 8 bits, no parity, 1 stop bit, no handshaking, 9600 Bps.

    3. COM2, Echo, 8 bits, no parity, 1 stop bit, no handshaking, 9600 Bps.

  Note.. Some hardware serial port configurations preclude concurrent
  use of more than one serial port at a time.  In particular, two ports which
  share an interrupt may "fight" over the irq line if not connected through
  appropriate logic so either may trigger the interrupt independently.  This
  sometimes results in one port appearing to function only when interrupts
  occur regularly on the other port.  This is a sign of incorrect hardware
  design or installation.

  The format of the control line was chosen for convenience of interprtation,
  not ease of use.  If anyone feels the urge to correct this deficiency, please
  don't hesitate.

  By: Edwin T. Floyd [76067,747]
      Hughston Sports Medicine Foundation
      P.O. Box 9517
      Columbus, GA 31995
      (404) 324-6074

  This demo program is contributed to the public domain.

  12-20-87 E. Floyd - Version 1.0
  12-21-87 E. Floyd - V 1.1 Added Echo option, documented for C'Serv upload
}
Uses Crt, Dos, Yasync;

Const
  BufferSize = 4096; { Transmit and receive buffers }

Type
  ScreenWindowType = Record
  { Control information for screen window }
    WindowOk : Boolean;
    Rate : LongInt;   { Data rate in bits per second }
    ComPort : Word;   { Serial port number }
    Bits : Word;      { Number of data bits }
    Stop : Word;      { Number of stop bits }
    ErrorCount : Word;   { Number of error interrupts }
    OverrunCount : Word; { Number of overrun errors }
    ParityCount : Word;  { Number of parity errors }
    FrameCount : Word;   { Number of framing errors }
    BreakCount : Word;   { Number of break signals received }
    TimeoutCount : Word; { Number of timeouts }
    Parity : Char;    { Parity (N,E,O,0,1) }
    HandShake : Char; { Handshaking option (N,D,C,X) }
    Echo : Char;      { Echo option (N,E) }
    WinX1, WinY1, WinX2, WinY2, CursorX, CursorY : Byte;
    Message : String[80];
  End;

Var
  ScreenWindow : Array[1..MaxPorts] Of ScreenWindowType;
  W, InUse, KeyBoardScreen : Word;
  Done : Boolean;
  Ch : Char;

{$F+} Procedure ErrorProc(ComPort : Word); {$F-}
{ Error handler; Far call, don't use DOS - may be called from intrpt handler.
  Note.. These are word-size counters and could easily overflow.  A practical
  implementation would either use LongInts or check for impending overflow. }
Begin { ErrorProc }
  With AsyncPort[ComPort], ScreenWindow[UserData] Do Begin
    Inc(ErrorCount);
    If (LineStatus And LSROverrun) <> 0 Then Inc(OverrunCount);
    If (LineStatus And LSRParity) <> 0 Then Inc(ParityCount);
    If (LineStatus And LSRFrame) <> 0 Then Inc(FrameCount);
    If (LineStatus And LSRBreak) <> 0 Then Inc(BreakCount);
    If (LineStatus And LSRTimeout) <> 0 Then Inc(TimeoutCount);
  End;
End;  { ErrorProc }

Procedure InterpretParm(w : Word; s : String);
{ Interpret startup parameter passed on command line. }
Var
  i : Word;
  bad : Boolean;
  sm : String[5];
Begin { InterpretParm }
  bad := false;
  With ScreenWindow[w] Do Begin
    WindowOk := False;
    ErrorCount := 0; { Clear error counters }
    OverrunCount := 0;
    ParityCount := 0;
    FrameCount := 0;
    BreakCount := 0;
    TimeoutCount := 0;
    Str(w, sm);
    Val(Copy(s, 1, 1), ComPort, i);
    If i <> 0 Then bad := True;
    If (ComPort < 1) Or (ComPort > MaxPorts) Then bad := True;
    Echo := UpCase(s[2]);
    If Not (Echo In ['N','E']) Then bad := True;
    Val(Copy(s, 3, 1), Bits, i);
    If i <> 0 Then bad := True;
    Parity := UpCase(s[4]);
    Val(Copy(s, 5, 1), Stop, i);
    If i <> 0 Then bad := True;
    HandShake := UpCase(s[6]);
    If Not (HandShake In ['N','D','C','X']) Then bad := True;
    Val(Copy(s, 7, 5), Rate, i);
    If i <> 0 Then bad := True;
    If bad Then Begin
      Message := 'Error in specification for window ' + sm
        + ': "' + s + '" (nedpshbbbbb)';
    End Else Begin
      With AsyncPort[ComPort] Do Begin
        If PortOpen Then Message := 'COM' + sm + ' Already open ' Else Begin
          RtsHand := False;
          TransmitSize := BufferSize;
          ReceiveSize := BufferSize;
          ErrorRoutine := @ErrorProc;
          UserData := w;
          Case HandShake Of
            'N' : ;
            'D' : Begin
              WaitForDsr := True;
              DtrHand := True;
            End;
            'C' : Begin
              WaitForCts := True;
              RtsHand := True;
            End;
            'X' : Begin
              WaitForXon := True;
              XoHand := True;
              XoTransparent := False;
            End;
          End;
          If OpenPort(ComPort, Rate, Bits, Stop, Parity) Then Begin
            Str(ComPort, sm);
            Message := 'COM' + sm + ' ';
            Str(Rate, sm);
            Message := Message + sm + ' Bps,  ';
            Str(Bits, sm);
            Message := Message + sm + ' Data bits, ';
            Str(Stop, sm);
            Message := Message + sm + ' Stop bits, ' + Parity + ' Parity, '
             + Handshake + ' Handshake';
            WindowOk := True;
          End Else Begin
            Case PortOpenError Of
              1 : Message := 'Port number out of range (1..4)';
              2 : Message := 'Baud rate out of range (50..115200)';
              3 : Message := 'Word length out of range (5..8)';
              4 : Message := 'Stop bits out of range (1..2)';
              5 : Message := 'Invalid parity (N,E,O,1,0)';
              6 : Message := 'Buffer size invalid (2..32767)';
              7 : Message := 'Insufficient heap space for buffers';
              8 : Message := 'UART not responding';
              9 : Message := 'Program bug - should never happen';
            End;
            Message := '"' + s + '" (ndpshbbbbb), Error: ' + Message
          End;
        End;
      End;
    End;
  End;
End;  { InterpretParm }

Procedure SetKeyboardScreen(W : Word);
{ Set keyboard active screen }
Begin { SetKeyboardScreen }
  Window(1, 1, 80, 25);
  TextColor(Black);
  TextBackground(White);
  GoToXY(66, Succ(ScreenWindow[KeyboardScreen].WinY2));
  ClrEol;
  GoToXY(66, Succ(ScreenWindow[W].WinY2));
  Write('^^Keyboard^^');
  TextColor(White);
  TextBackground(Black);
  KeyboardScreen := W;
End;  { SetKeyboardScreen }

Begin { YasDemo }
  InUse := 0;
  While (InUse < ParamCount) And (InUse < MaxPorts) Do Begin
    { Interpret parameter line }
    Inc(InUse);
    InterpretParm(InUse, ParamStr(InUse));
  End;
  If InUse > 0 Then Begin { We have some windows }
    KeyboardScreen := 1;
    TextBackground(White); { Write header and underlines in reverse video }
    TextColor(Black);
    ClrScr;
    Write('    YasDemo Version 1.1, Press: F1 - change screens, F9 - break, F10 - exit ');
    For W := 1 To InUse Do With ScreenWindow[W] Do Begin
      { Set window location & size and write underline message }
      WinX1 := 1;
      WinY1 := Pred(W) * (24 Div InUse) + 2;
      WinX2 := 80;
      WinY2 := WinY1 + (24 Div InUse) - 2;
      GoToXY(1, Succ(WinY2));
      ClrEol;
      Write(Message);
      CursorX := 1;
      CursorY := 24 Div InUse - 1;
    End;
    TextBackground(Black);
    TextColor(White);
    For W := 1 To InUse Do With ScreenWindow[W] Do Begin { Clear windows }
      Window(WinX1, WinY1, WinX2, WinY2);
      ClrScr;
    End;
    Done := False;
    SetKeyboardScreen(KeyboardScreen);
    W := 1;
    Repeat { Main loop }
      If KeyPressed Then Begin { We have a keystroke }
        Ch := ReadKey;
        If (Ch = #0) And KeyPressed Then Begin { Extended key code }
          Ch := ReadKey;
          Case Ch Of
            #59 {F1} : SetKeyboardScreen(Succ(KeyboardScreen Mod InUse));
            #67 {F9} : With ScreenWindow[KeyboardScreen] Do
              If WindowOk Then SendBreak(ComPort);
            #68 {F10}: Done := True;
            Else Write(^G); { Beep }
          End;
        End
        Else With ScreenWindow[KeyboardScreen] Do Begin { Send keystroke }
          If Echo = 'E' Then Begin
            Window(WinX1, WinY1, WinX2, WinY2);
            GoToXY(CursorX, CursorY);
            Write(Ch);
            CursorX := WhereX;
            CursorY := WhereY;
          End;
          If WindowOk Then If Not SendPort(ComPort, Ch) Then Write(^G);
        End;
      End;
      With ScreenWindow[W] Do Begin { Check for received character }
        If WindowOk Then Begin
          If ReadPort(ComPort, Ch) Then Begin { We have received a character }
            Window(WinX1, WinY1, WinX2, WinY2);
            GoToXY(CursorX, CursorY);
            Write(Ch);
            CursorX := WhereX;
            CursorY := WhereY;
          End;
        End;
      End;
      W := Succ(W Mod InUse);
    Until Done;
    { Finished, display error counts }
    Window(1, 1, 80, 25);
    ClrScr;
    For W := 1 To InUse Do With ScreenWindow[W] Do Begin
      If WindowOk Then ClosePort(ComPort);
      WriteLn('Port COM', ComPort, ', ', ErrorCount, ' Error interrupts');
      WriteLn('  ', OverrunCount, ' Overrun errors');
      WriteLn('  ', ParityCount, ' Parity errors');
      WriteLn('  ', FrameCount, ' Framing errors');
      WriteLn('  ', BreakCount, ' Break signals received');
      WriteLn('  ', TimeoutCount, ' Timeouts');
    End;
  End Else Begin { No windows, tell them how to run program }
    WriteLn('Run like this:');
    WriteLn;
    WriteLn('  YASDEMO nedpshbbbbb [...]');
    WriteLn;
    WriteLn('Where: n   = Serial port number, 1..4');
    WriteLn('       e   = Echo option, E=Echo keyboard on screen (HDX), N=No Echo (FDX)');
    WriteLn('       d   = Data bits, 5..8');
    WriteLn('       p   = Parity, E,O,N,0 or 1');
    WriteLn('       s   = Stop bits, 1..2');
    WriteLn('       h   = Handshaking: N=None, D=Dtr/Dsr, C=Rts/Cts, X=Xon/Xoff');
    WriteLn('       b.. = Data rate, bits per second');
  End;
End.  { YasDemo }
