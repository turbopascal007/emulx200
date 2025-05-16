
{$F+}


Unit MODEM;

INTERFACE

{----------------------------------------------------------------------------}

Const
  C_MinBaud = 50;
  C_MaxBaud = 115200;

  { Base port addresses & interrupt usage }

  C_MaxPort = 4;
  C_MaxCom : Byte = C_MaxPort;
  C_PortAddr : Array[1..C_MaxPort] Of Word = ($03F8,$02F8,$03E8,$02E8);
  C_PortInt : Array[1..C_MaxPort] Of Byte = (4,3,4,3);

{----------------------------------------------------------------------------}

Type
  C_PointerArray = Array[1..C_MaxPort] Of Pointer;
  C_WordArray = Array[1..C_MaxPort] Of Word;
  C_ByteArray = Array[1..C_MaxPort] Of Byte;
  C_CharArray = Array[1..C_MaxPort] Of Char;
  C_BooleanArray = Array[1..C_MaxPort] Of Boolean;

{----------------------------------------------------------------------------}

Var
  C_InBufPtr,C_OutBufPtr : C_PointerArray;    { Input/output buffer pointers }
  C_InHead,C_OutHead     : C_WordArray;       { Input/output head pointers }
  C_InTail,C_OutTail     : C_WordArray;       { Input/output tail pointers }
  C_InSize,C_OutSize     : C_WordArray;       { Input/output buffer sizes }
  C_RTSOn,C_RTSOff       : C_WordArray;       { RTS assert/drop buffer points }
  C_StartChar,C_StopChar : C_CharArray;       { Soft hndshake start/stop char }
  C_Status,C_Ctrl        : C_ByteArray;       { STATUS and CONTROL registers }
  C_XL3Ptr               : C_ByteArray;
  C_PortOpen             : C_BooleanArray;    { Port open/close flags }
  C_Temp : Word;                              { Used for debugging }

var   FormerExitProc:Pointer;{ Save area for ExitProc pointer }

{----------------------------------------------------------------------------}

{ Procedure headers - required for UNITization }

Function  ComReadCh(CCom:Byte) : Char;
Function  ComReadChW(CCom:Byte) : Char;
Procedure ComWriteCh(CCom:Byte; Ch:Char);
Procedure ComWriteChW(CCom:Byte; Ch:Char);
Procedure SetDTR(CCom:Byte; Assert:Boolean);
Procedure SetRTS(CCom:Byte; Assert:Boolean);
Procedure SetOUT1(CCom:Byte; Assert:Boolean);
Procedure SetOUT2(CCom:Byte; Assert:Boolean);
Function  CTSStat(CCom:Byte) : Boolean;
Function  DSRStat(CCom:Byte) : Boolean;
Function  RIStat(CCom:Byte) : Boolean;
Function  DCDStat(CCom:Byte) : Boolean;
Procedure SetRTSMode(CCom:Byte; Mode:Boolean; RTSOn,RTSOff:Word);
Procedure SetCTSMode(CCom:Byte; Mode:Boolean);
Procedure SoftHandshake(CCom:Byte; Mode:Boolean; Start,Stop:Char);
Procedure ClearCom(CCom:Byte; IO:Char);
Function  ComBufferLeft(CCom:Byte; IO:Char) : Word;
Procedure ComWaitForClear(CCom:Byte);
Procedure ComWrite(CCom:Byte; St:String);
Procedure ComWriteln(CCom:Byte; St:String);
Procedure ComWriteWithDelay(CCom:Byte; St:String; Dly:Word);
Procedure ComReadln(CCom:Byte; Var St:String; Size:Byte; Echo:Boolean);
Function  ComExist(CCom:Byte) : Boolean;
Function  ComTrueBaud(Baud:Longint) : Real;
Procedure ComParams(CCom:Byte; Baud:LongInt; WordSize:Byte; Parity:Char; StopBits:Byte);
Function  OpenCom(CCom:Byte; InBufferSize,OutBufferSize:Word) : Boolean;
Procedure CloseCom(CCom:Byte);
Procedure CloseAllComs;
{Function Comused(CCom:Byte; IO:Char) : Word;}

  var transmitsize:word;
  Var icomoffset:Integer;

  Var comport:word;

      CurPort:integer;

    procedure initializeAsync;
    Procedure closeport;

    Procedure sendchar(ch:Char);
    Function  numchars:word;
    Function  getchar:Char;
    Procedure hangup;
    Procedure setparam(comnum:Byte;baud:Integer;parity:Boolean);
    Function  carrier:Boolean;
    Procedure setterminalready(b:Boolean);
    Procedure dontanswer;
    Procedure doanswer;
    function  transmitbufferused:word;
    Procedure cleartransmitbuffer;
    Procedure clearreceivebuffer;

 {----------------------------------------------------------------------------}

IMPLEMENTATION

Uses DOS,CRT;

{$L async.OBJ}

Const
  C_IER = 1;                           { 8250 register offsets }
  C_IIR = 2;
  C_LCR = 3;
  C_MCR = 4;
  C_LSR = 5;
  C_MSR = 6;
  C_SCR = 7;

Var
  C_OldINTVec : C_PointerArray;        { Storage for old hardware INT vectors }
  X : Byte;                            { Used by initialization code }

Procedure INT_Handler; External;



Function ComReadChW(CCom:Byte) : Char; External;

Function ComReadCh(CCom:Byte) : Char; External;


Procedure ComWriteCh(CCom:Byte; Ch:Char); External;


Procedure ComWriteChW(CCom:Byte; Ch:Char); External;



    Procedure closeport;
          Begin
 {         closecom(curport);}
    end;

    Procedure sendchar(ch:Char);
    begin
    repeat until combufferleft(curport,'O')>0;
    comwritechw(curport,ch);
    end;

    Function numchars:word;
    begin
    numchars:=356-combufferleft(curport,'I');
    end;

    Function getchar:Char;
    begin
    getchar:=comreadch(curport);
    end;

    Procedure hangup;
    begin
   setdtr(curport,false);
    delay(500);

    setdtr(curport,true);
    end;

    Function carrier:Boolean;
    begin
    carrier:=dcdstat(curport);
    end;

    Procedure setterminalready(b:Boolean);
    begin
     setdtr(curport,b);
    end;

    Procedure dontanswer;
    begin
    setterminalready(False);
    end;

    Procedure doanswer;
    begin
    setterminalready(true);
    end;

    function transmitbufferused:word;
    begin
 {    transmitbufferused:=c_outready(curport);}
    end;

    Procedure cleartransmitbuffer;
    begin
    clearcom(curport,'I');
    end;
    Procedure clearreceivebuffer;
    begin
    clearcom(curport,'O');
    end;

        Procedure setparam(comnum:Byte;baud:Integer;parity:Boolean);
          Begin
            comport:=comnum;
            curport:=comnum;
            setdtr(curport,true);
            setrts(curport,true);


            if transmitsize<128 then transmitsize:=128;
            if transmitsize>8192 then transmitsizE:=2096;
if c_portopen[curport]=false then   if not   OPenCom(curport,356,transmitsize) then write (':: COM ERROR');
        comparams (curport,baud,8,'N',1);
            setctsmode(curport,true);
          End;



{  }

procedure  initializeasync;
begin
end;
{****************************************************************************}
{*                                                                          *}
{*  Procedure SetDTRu(CCom:Byte; Assert:Boolean);                         *}
{*                                                                          *}
{*  CCom:Byte    ->  Port # to use (1 - C_MaxCom)                        *}
{*                      Call ignored if out-of-range                        *}
{*  Assert:Boolean  ->  DTR assertion flag (TRUE to assert DTR)             *}
{*                                                                          *}
{*  Provides a means to control the port's DTR (Data Terminal Ready) signal *}
{*  line.  When [Assert] is TRUE, the DTR line is placed in the "active"    *}
{*  state, signalling to a remote system that the host is "on-line"         *}
{*  (although not nessesarily ready to receive data - see SetRTS).          *}
{*                                                                          *}
{****************************************************************************}

Procedure SetDTR(CCom:Byte; Assert:Boolean);

Var
  P,X : Integer;

Begin
  If (CCom<1) Or (CCom>C_MaxCom) Then Exit;
  P := C_PortAddr[CCom];

  X := Port[P+C_MCR];
  If Assert Then
    X := X Or $01
  Else
    X := X And $FE;
  Port[P+C_MCR] := X;
End;

{****************************************************************************}
{*                                                                          *}
{*  Procedure SetRTS(CCom:Byte; Assert:Boolean)                          *}
{*                                                                          *}
{*  CCom:Byte    ->  Port # to use (1 - C_MaxCom)                        *}
{*                      Call ignored if out-of-range                        *}
{*  Assert:Boolean  ->  RTS assertion flag (Set TRUE to assert RTS)         *}
{*                                                                          *}
{*  SetRTS allows a program to manually control the Request-To-Send (RTS)   *}
{*  signal line.  If RTS handshaking is disabled (see C_Ctrl definition     *}
{*  and the the SetRTSMode procedure), this procedure may be used.  SetRTS  *}
{*  should NOT be used if RTS handshaking is enabled.                       *}
{*                                                                          *}
{****************************************************************************}

Procedure SetRTS(CCom:Byte; Assert:Boolean);

Var
  P,X : Integer;

Begin
  If (CCom<1) Or (CCom>C_MaxCom) Then Exit;
  P := C_PortAddr[CCom];

  X := Port[P+C_MCR];
  If Assert Then
    X := X Or $02
  Else
    X := X And $FD;
  Port[P+C_MCR] := X;
End;

{****************************************************************************}
{*                                                                          *}
{*  Procedure SetOUT1(CCom:Byte; Assert:Boolean)                         *}
{*                                                                          *}
{*  CCom:Byte    ->  Port # to use (1 - C_MaxCom)                        *}
{*                      Call ignored if out-of-range                        *}
{*  Assert:Boolean  ->  OUT1 assertion flag (set TRUE to assert OUT1 line)  *}
{*                                                                          *}
{*  SetOUT1 is provided for reasons of completeness only, since the         *}
{*  standard PC/XT/AT configurations do not utilize this control signal.    *}
{*  If [Assert] is TRUE, the OUT1 signal line on the 8250 will be set to a  *}
{*  LOW logic level (inverted logic).  The OUT1 signal is present on pin 34 *}
{*  of the 8250 (but not on the port itself).                               *}
{*                                                                          *}
{****************************************************************************}

Procedure SetOUT1(CCom:Byte; Assert:Boolean);

Var
  P,X : Integer;

Begin
  If (CCom<1) Or (CCom>C_MaxCom) Then Exit;
  P := C_PortAddr[CCom];

  X := Port[P+C_MCR];
  If Assert Then
    X := X Or $04
  Else
    X := X And $FB;
  Port[P+C_MCR] := X;
End;

{****************************************************************************}
{*                                                                          *}
{*  Procedure SetOUT2(CCom:Byte; Assert:Boolean)                         *}
{*                                                                          *}
{*  CCom:Byte    ->  Port # to use (1 - C_MaxCom)                        *}
{*                      Call ignored if out-of-range                        *}
{*  Assert:Boolean  ->  OUT2 assertion flag (set TRUE to assert OUT2 line)  *}
{*                                                                          *}
{*  The OUT2 signal line, although not available on the port itself, is     *}
{*  used to gate the 8250 <INTRPT> (interrupt) line and thus acts as a      *}
{*  redundant means of controlling 8250 interrupts.  When [Assert] is TRUE, *}
{*  the /OUT2 line on the 8250 is lowered, which allows the passage of the  *}
{*  <INTRPT> signal through a gating arrangement, allowing the 8250 to      *}
{*  generate interrupts.  Int's can be disabled bu unASSERTing this line.   *}
{*                                                                          *}
{****************************************************************************}

Procedure SetOUT2(CCom:Byte; Assert:Boolean);

Var
  P,X : Integer;

Begin
  If (CCom<1) Or (CCom>C_MaxCom) Then Exit;
  P := C_PortAddr[CCom];

  X := Port[P+C_MCR];
  If Assert Then
    X := X Or $08
  Else
    X := X And $F7;
  Port[P+C_MCR] := X;
End;

{****************************************************************************}
{*                                                                          *}
{*  Function CTSStat(CCom:Byte) : Boolean                                *}
{*                                                                          *}
{*  CCom:Byte  ->  Port # to use (1 - C_MaxCom)                          *}
{*                    Call ignored if out-of-range                          *}
{*  Returns status of Clear-To-Send line (TRUE if CTS asserted)             *}
{*                                                                          *}
{*  CTSStat provides a means to interrogate the Clear-To-Send hardware      *}
{*  handshaking line.  In a typical arrangement, when CTS is asserted, this *}
{*  signals the host (this computer) that the receiver is ready to accept   *}
{*  data (in contrast to the DSR line, which signals the receiver as        *}
{*  on-line but not nessesarily ready to accept data).  An automated mech-  *}
{*  ansim (see CTSMode) is provided to do this, but in cases where this is  *}
{*  undesirable or inappropriate, the CTSStat function can be used to int-  *}
{*  terrogate this line manually.                                           *}
{*                                                                          *}
{****************************************************************************}

Function CTSStat(CCom:Byte) : Boolean;

Begin
  If (CCom<1) Or (CCom>C_MaxCom) Then
    CTSStat := False
  Else
    CTSStat := (Port[C_PortAddr[CCom]+C_MSR] And $10) > 0;
End;

{****************************************************************************}
{*                                                                          *}
{*  Function DSRStat(CCom:Byte) : Boolean                                *}
{*                                                                          *}
{*  CCom:Byte  ->  Port # to use (1 - C_MaxCom)                          *}
{*                    Call ignored if out-of-range                          *}
{*  Returns status of Data Set Ready (DSR) signal line.                     *}
{*                                                                          *}
{*  The Data Set Ready (DSR) line is typically used by a remote station     *}
{*  to signal the host system that it is on-line (although not nessesarily  *}
{*  ready to receive data yet - see CTSStat).  A remote station has the DSR *}
{*  line asserted if DSRStat returns TRUE.                                  *}
{*                                                                          *}
{****************************************************************************}

Function DSRStat(CCom:Byte) : Boolean;

Begin
  If (CCom<1) Or (CCom>C_MaxCom) Then
    DSRStat := False
  Else
    DSRStat := (Port[C_PortAddr[CCom]+C_MSR] And $20) > 0;
End;

{****************************************************************************}
{*                                                                          *}
{*  Function RIStat(CCom:Byte) : Boolean                                 *}
{*                                                                          *}
{*  CCom:Byte  ->  Port # to use (1 - C_MaxCom)                          *}
{*                    Call ignored if out-of-range                          *}
{*                                                                          *}
{*  Returns the status of the Ring Indicator (RI) line.  This line is       *}
{*  typically used only by modems, and indicates that the modem has detect- *}
{*  ed an incoming call if RIStat returns TRUE.                             *}
{*                                                                          *}
{****************************************************************************}

Function RIStat(CCom:Byte) : Boolean;

Begin
  If (CCom<1) Or (CCom>C_MaxCom) Then
    RIStat := False
  Else
    RIStat := (Port[C_PortAddr[CCom]+C_MSR] And $40) > 0;
End;

{****************************************************************************}
{*                                                                          *}
{*  Function DCDStat(CCom:Byte) : Boolean                                *}
{*                                                                          *}
{*  CCom:Byte  ->  Port # to use (1 - C_MaxCom)                          *}
{*                    Call ignored if out-of-range                          *}
{*                                                                          *}
{*  Returns the status of the Data Carrier Detect (DCD) line from the rem-  *}
{*  ote device, typically a modem.  When asserted (DCDStat returns TRUE),   *}
{*  the modem indicates that it has successfuly linked with another modem   *}
{*  device at another site.                                                 *}
{*                                                                          *}
{****************************************************************************}

Function DCDStat(CCom:Byte) : Boolean;

Begin
  If (CCom<1) Or (CCom>C_MaxCom) Then
    DCDStat := False
  Else
    DCDStat := (Port[C_PortAddr[CCom]+C_MSR] And $80) > 0;
End;

{****************************************************************************}
{*                                                                          *}
{*  Procedure SetRTSMode(CCom:Byte; Mode:Boolean; RTSOn,RTSOff:Word)     *}
{*                                                                          *}
{*  CCom:Byte  ->  Port # to use (1 - C_MaxCom).                         *}
{*                    Request ignored if out of range or unopened.          *}
{*  Mode:Boolean  ->  TRUE to enable automatic RTS handshake                *}
{*  RTSOn:Word    ->  Buffer-usage point at which the RTS line is asserted  *}
{*  RTSOff:Word   ->  Buffer-usage point at which the RTS line is dropped   *}
{*                                                                          *}
{*  SetRTSMode enables or disables automated RTS handshaking.  If [MODE] is *}
{*  TRUE, automated RTS handshaking is enabled.  If enabled, the RTS line   *}
{*  will be DROPPED when the # of buffer bytes used reaches or exceeds that *}
{*  of [RTSOff].  The RTS line will then be re-asserted when the buffer is  *}
{*  emptied down to the [RTSOn] usage point.  If either [RTSOn] or [RTSOff] *}
{*  exceeds the input buffer size, they will be forced to (buffersize-1).   *}
{*  If [RTSOn] > [RTSOff] then [RTSOn] will be the same as [RTSOff].        *}
{*  The actual handshaking control is located in the interrupt driver for   *}
{*  the port (see ASYNC11.ASM).                                             *}
{*                                                                          *}
{****************************************************************************}

Procedure SetRTSMode(CCom:Byte; Mode:Boolean; RTSOn,RTSOff:Word);

Var
  X : Byte;

Begin
  If (CCom<1) Or (CCom>C_MaxPort) Or (Not C_PortOpen[CCom]) Then Exit;

  X := C_Ctrl[CCom];
  If Mode Then X := X Or $01 Else X := X And $FE;
  C_Ctrl[CCom] := X;

  If Mode Then
    Begin
      If (RTSOff >= C_InSize[CCom]) Then RTSOff := C_InSize[CCom] - 1;
      If (RTSOn > RTSOff) Then RTSOff := RTSOn;
      C_RTSOn[CCom] := RTSOn;
      C_RTSOff[CCom] := RTSOff;
    End;
End;

{****************************************************************************}
{*                                                                          *}
{*  Procedure SetCTSMode(CCom:Byte; Mode:Boolean)                        *}
{*                                                                          *}
{*  CCom:Byte  ->  Port # to use (1 - C_MaxCom).                         *}
{*                    Request ignored if out of range or unopened.          *}
{*  Mode:Boolean  ->  Set to TRUE to enable automatic CTS handshake.        *}
{*                                                                          *}
{*  SetCTSMode allows the enabling or disabling of automated CTS handshak-  *}
{*  ing.  If [Mode] is TRUE, CTS handshaking is enabled, which means that   *}
{*  if the remote drops the CTS line, the transmitter will be disabled      *}
{*  until the CTS line is asserted again.  Automatic handshake is disabled  *}
{*  if [Mode] is FALSE.  CTS handshaking and "software" handshaking (pro-   *}
{*  vided by the SoftHandshake procedure) ARE compatable and may be used    *}
{*  in any combination.  The actual logic for CTS handshaking is located    *}
{*  in the communications interrupt driver (see ASYNC11.ASM).               *}
{*                                                                          *}
{****************************************************************************}

Procedure SetCTSMode(CCom:Byte; Mode:Boolean);

Var
  X : Byte;

Begin
  If (CCom<1) Or (CCom>C_MaxPort) Or (Not C_PortOpen[CCom]) Then Exit;

  X := C_Ctrl[CCom];
  If Mode Then X := X Or $02 Else X := X And $FD;
  C_Ctrl[CCom] := X;
End;

{****************************************************************************}
{*                                                                          *}
{*  Procedure SoftHandshake(CCom:Byte; Mode:Boolean; Start,Stop:Char)    *}
{*                                                                          *}
{*  CCom:Byte  ->  Port # to use (1 - C_MaxCom).                         *}
{*                    Request ignored if out of range or unopened.          *}
{*  Mode:Boolean  ->  Set to TRUE to enable transmit software handshake     *}
{*  Start:Char    ->  START control character (usually ^Q)                  *}
{*                    Defaults to ^Q if character passed is >= <Space>      *}
{*  Stop:Char     ->  STOP control character (usually ^S)                   *}
{*                    Defaults to ^S if character passed is >= <Space>      *}
{*                                                                          *}
{*  SoftHandshake controls the usage of "Software" (control-character)      *}
{*  handshaking on transmission.  If "software handshake" is enabled        *}
{*  ([Mode] is TRUE), transmission will be halted if the character in       *}
{*  [Stop] is received.  Transmission is re-enabled if the [Start] char-    *}
{*  acter is received.  Both the [Start] and [Stop] characters MUST be      *}
{*  CONTROL characters (i.e. Ord(Start) and Ord(Stop) must both be < 32).   *}
{*  Also, <Start> and <Stop> CANNOT be the same character.  If either one   *}
{*  of these restrictions are violated, the defaults (^Q for <Start> and ^S *}
{*  for <Stop>) will be used.  Software handshaking control is implimented  *}
{*  within the communications interrupt driver (see ASYNC11.ASM).           *}
{*                                                                          *}
{****************************************************************************}

Procedure SoftHandshake(CCom:Byte; Mode:Boolean; Start,Stop:Char);

Var
  X : Byte;

Begin
  If (CCom<1) Or (CCom>C_MaxPort) Or (Not C_PortOpen[CCom]) Then Exit;

  X := C_Ctrl[CCom];
  If Mode Then
    Begin
      X := X Or $04;
      If Start=Stop Then Begin Start := ^Q; Stop := ^S; End;
      If Start>#32 Then Start := ^Q;
      If Stop>#32 Then Stop := ^S;
      C_StartChar[CCom] := Start;
      C_StopChar[CCom] := Stop;
    End
  Else
    X := X And $FB;
  C_Ctrl[CCom] := X;
End;

{****************************************************************************}
{*                                                                          *}
{*  Procedure ClearCom(CCom:Byte); IO:Char)                              *}
{*                                                                          *}
{*  CCom:Byte  ->  Port # to use (1 - C_MaxCom).                         *}
{*                    Request ignored if out of range or unopened.          *}
{*  IO:Char       ->  Action code; I=Input, O=Output, B=Both                *}
{*                    No action taken if action code unrecognized.          *}
{*                                                                          *}
{*  ClearCom allows the user to completely clear the contents of either     *}
{*  the input (receive) and/or output (transmit) buffers.  The "action      *}
{*  code" passed in <IO> determines if the input (I) or output (O) buffer   *}
{*  is cleared.  Action code (B) will clear both buffers.  This is useful   *}
{*  if you wish to cancel a transmitted message or ignore part of a         *}
{*  received message.                                                       *}
{*                                                                          *}
{****************************************************************************}

Procedure ClearCom(CCom:Byte; IO:Char);

Var
  P,X : Word;

Begin
  If (CCom<1) Or (CCom>C_MaxCom) Or (Not C_PortOpen[CCom]) Then Exit;

  IO := Upcase(IO);
  P := C_PortAddr[CCom];

  Inline($FA);
  If (IO='I') Or (IO='B') Then
    Begin
      C_InHead[CCom] := 0;
      C_InTail[CCom] := 0;
      C_Status[CCom] := (C_Status[CCom] And $EC) Or $01;
      X := Port[P] + Port[P+C_LSR] + Port[P+C_MSR] + Port[P+C_IIR];
    End;
  If (IO='O') Or (IO='B') Then
    Begin
      C_OutHead[CCom] := 0;
      C_OutTail[CCom] := 0;
      C_Status[CCom] := (C_Status[CCom] And $D3) Or $04;
      X := Port[P+C_LSR] + Port[P+C_MSR] + Port[P+C_IIR];
    End;
  Inline($FB);
End;

{****************************************************************************}
{*                                                                          *}
{*  Procedure ComBufferLeft(CCom:Byte; IO:Char) : Word                   *}
{*                                                                          *}
{*  CCom:Byte  ->  Port # to use (1 - C_MaxCom).                         *}
{*                    Returns 0 if Port # invalid or unopened.              *}
{*  IO:Char       ->  Action code; I=Input, O=Output                        *}
{*                    Returns 0 if action code unrecognized.                *}
{*                                                                          *}
{*  ComBufferLeft will return a number (bytes) indicating how much space    *}
{*  remains in the selected buffer.  The INPUT buffer is checked if <IO> is *}
{*  (I), and the output buffer is interrogated when <IO> is (O).  Any other *}
{*  "action code" will return a result of 0.  Use this function when it is  *}
{*  important to avoid program delays due to calls to output procedures or  *}
{*  to prioritize the reception of data (to prevent overflows).             *}
{*                                                                          *}
{****************************************************************************}

Function ComBufferLeft(CCom:Byte; IO:Char) : Word;

Begin
  ComBufferLeft := 0;
  If (CCom<1) Or (CCom>C_MaxCom) Or (Not C_PortOpen[CCom]) Then Exit;
  IO := Upcase(IO);

  If IO = 'I' Then
    If C_InHead[CCom] >= C_InTail[CCom] Then
      ComBufferLeft := C_InSize[CCom]-(C_InHead[CCom]-C_InTail[CCom])
    Else
      ComBufferLeft := C_InTail[CCom]-C_InHead[CCom];

  If IO = 'O' Then
    If C_OutHead[CCom] >= C_OutTail[CCom] Then
      ComBufferLeft := C_OutHead[CCom]-C_OutTail[CCom]
    Else
      ComBufferLeft := C_OutSize[CCom]-(C_OutTail[CCom]-C_OutHead[CCom]);
End;
Function Comused(CCom:Byte; IO:Char) : Word;

Begin
  Comused := 0;
  If (CCom<1) Or (CCom>C_MaxCom) Or (Not C_PortOpen[CCom]) Then Exit;
  IO := Upcase(IO);

  If IO = 'I' Then
    If C_InHead[CCom] >= C_InTail[CCom] Then
      Comused := C_InSize[CCom]-(C_InHead[CCom]-C_InTail[CCom])
    Else
      Comused := C_InTail[CCom]-C_InHead[CCom];
End;

{****************************************************************************}
{*                                                                          *}
{*  Procedure ComWaitForClear(CCom:Byte)                                 *}
{*                                                                          *}
{*  CCom:Byte  ->  Port # to use (1 - C_MaxCom).                         *}
{*                    Exits immediately if out of range or port unopened.   *}
{*                                                                          *}
{*  A call to ComWaitForClear will stop processing until the selected out-  *}
{*  put buffer is completely emptied.  Typically used just before a call    *}
{*  to the CloseCom procedure to prevent premature cut-off of messages in   *}
{*  transit.                                                                *}
{*                                                                          *}
{****************************************************************************}

Procedure ComWaitForClear(CCom:Byte);

Var
  Empty : Boolean;

Begin
  If (CCom<1) Or (CCom>C_MaxCom) Or (Not C_PortOpen[CCom]) Then Exit;
  Repeat
    Empty := (C_Status[CCom] And $04) = $04;
    Empty := Empty And ((Port[C_PortAddr[CCom]+C_IER] And $02) = $00);
  Until Empty;
End;

{****************************************************************************}
{*                                                                          *}
{*  Procedure ComWrite(CCom:Byte; St:String)                             *}
{*                                                                          *}
{*  CCom:Byte  ->  Port # to use (1 - C_MaxCom).                         *}
{*                    Exits immediately if out of range or port unopened.   *}
{*  St:String     ->  String to send                                        *}
{*                                                                          *}
{*  Sends string <St> out communications port <CCom>.                    *}
{*                                                                          *}
{****************************************************************************}

Procedure ComWrite(CCom:Byte; St:String);

Var
  X : Byte;

Begin
  If (CCom<1) Or (CCom>C_MaxCom) Or (Not C_PortOpen[CCom]) Then Exit;

  For X := 1 To Length(St) Do
    ComWriteChW(CCom,St[X]);
End;

{****************************************************************************}
{*                                                                          *}
{*  Procedure ComWriteln(CCom:Byte; St:String);                          *}
{*                                                                          *}
{*  CCom:Byte  ->  Port # to use (1 - C_MaxCom).                         *}
{*                    Exits immediately if out of range or port unopened.   *}
{*  St:String     ->  String to send                                        *}
{*                                                                          *}
{*  Sends string <St> with a CR and LF appended.                            *}
{*                                                                          *}
{****************************************************************************}

Procedure ComWriteln(CCom:Byte; St:String);

Var
  X : Byte;

Begin
  If (CCom<1) Or (CCom>C_MaxCom) Or (Not C_PortOpen[CCom]) Then Exit;

  For X := 1 To Length(St) Do
    ComWriteChW(CCom,St[X]);
  ComWriteChW(CCom,#13);
  ComWriteChW(CCom,#10);
End;

{****************************************************************************}
{*                                                                          *}
{*  Procedure ComWriteWithDelay(CCom:Byte; St:String; Dly:Word);         *}
{*                                                                          *}
{*  CCom:Byte  ->  Port # to use (1 - C_MaxCom).                         *}
{*                    Exits immediately if out of range or port unopened.   *}
{*  St:String     ->  String to send                                        *}
{*  Dly:Word      ->  Time, in milliseconds, to delay between each char.    *}
{*                                                                          *}
{*  ComWriteWithDelay will send string <St> to port <CCom>, delaying     *}
{*  for <Dly> milliseconds between each character.  Useful for systems that *}
{*  cannot keep up with transmissions sent at full speed.                   *}
{*                                                                          *}
{****************************************************************************}

Procedure ComWriteWithDelay(CCom:Byte; St:String; Dly:Word);

Var
  X : Byte;

Begin
  If (CCom<1) Or (CCom>C_MaxCom) Or (Not C_PortOpen[CCom]) Then Exit;

  ComWaitForClear(CCom);
  For X := 1 To Length(St) Do
    Begin
      ComWriteChW(CCom,St[X]);
      ComWaitForClear(CCom);
      Delay(Dly);
    End;
End;

{****************************************************************************}
{*                                                                          *}
{* Procedure ComReadln(CCom:Byte; Var St:String; Size:Byte; Echo:Boolean)*}
{*                                                                          *}
{*  CCom:Byte  ->  Port # to use (1 - C_MaxCom).                         *}
{*                    Exits immediately if out of range or port unopened.   *}
{*  St:String     <-  Edited string from remote                             *}
{*  Size:Byte;    ->  Maximum allowable length of input                     *}
{*  Echo:Boolean; ->  Set TRUE to echo received characters                  *}
{*                                                                          *}
{*  ComReadln is the remote equivalent of the standard Pascal READLN pro-   *}
{*  cedure with some enhancements.  ComReadln will accept an entry of up to *}
{*  40 printable ASCII characters, supporting ^H and ^X editing commands.   *}
{*  Echo-back of the entry (for full-duplex operation) is optional.  All    *}
{*  control characters, as well as non-ASCII (8th bit set) characters are   *}
{*  stripped.  If <Echo> is enabled, ASCII BEL (^G) characters are sent     *}
{*  when erroneous characters are intercepted.  Upon receipt of a ^M (CR),  *}
{*  the procedure is terminated and the final string result returned.       *}
{*                                                                          *}
{****************************************************************************}

Procedure ComReadln(CCom:Byte; Var St:String; Size:Byte; Echo:Boolean);

Var
  Len,X : Byte;
  Ch : Char;
  Done : Boolean;

Begin
  St := '';
  If (CCom<1) Or (CCom>C_MaxCom) Or (Not C_PortOpen[CCom]) Then Exit;

  Done := False;
  Repeat
    Len := Length(St);
    Ch := Chr(Ord(ComReadChW(CCom)) And $7F);

    Case Ch Of
      ^H : If Len > 0 Then
             Begin
               Dec(Len);
               St[0] := Chr(Len);
               If Echo Then ComWrite(CCom,#8#32#8);
             End
           Else
             ComWriteChW(CCom,^G);
      ^M : Begin
             Done := True;
             If Echo Then ComWrite(CCom,#13#10);
           End;
      ^X : Begin
             St := '';
             If Len = 0 Then ComWriteCh(CCom,^G);
             If Echo Then
               For X := 1 to Len Do
                 ComWrite(CCom,#8#32#8);
           End;
      #32..#127 : If Len < Size Then
                    Begin
                      Inc(Len);
                      St[Len] := Ch;
                      St[0] := Chr(Len);
                      If Echo Then ComWriteChW(CCom,Ch);
                    End
                  Else
                    If Echo Then ComWriteChW(CCom,^G);
    Else
      If Echo Then ComWriteChW(CCom,^G)
    End;

  Until Done;
End;

{****************************************************************************}
{*                                                                          *}
{*  Function ComExist(CCom:Byte) : Boolean                               *}
{*                                                                          *}
{*  CCom:Byte  ->  Port # to use (1 - C_MaxCom)                          *}
{*                    Returns FALSE if out of range                         *}
{*  Returns TRUE if hardware for selected port is detected & tests OK       *}
{*                                                                          *}
{*  Function ComExist performs a high-speed short loopback test on the      *}
{*  selected port to determine if it indeed exists.  Use this function      *}
{*  before attempts to OPEN a port for I/O (although this function is       *}
{*  called by OpenCom to prevent such an occurance).                        *}
{*  NOTE!  Although pains are taken to preserve the 8250 state before the   *}
{*  port test takes place, it is nonetheless recommended that this function *}
{*  NOT be called while a port is actually OPEN.  Doing so may cause the    *}
{*  port to behave erratically.                                             *}
{*                                                                          *}
{****************************************************************************}

Function ComExist(CCom:Byte) : Boolean;

Const
  TestByte1 : Byte = $0F;
  TestByte2 : Byte = $F1;

Var
  P : Word;
  M,L,B1,B2 : Byte;

Begin
  ComExist := False;
  If (CCom<1) Or (CCom>C_MaxPort) Then Exit;

  P := C_PortAddr[CCom];
  M := Port[P+C_MCR] ;                            { Save MCR }
  L := Port[P+C_LCR];                            { Save LCR }
  Port[P+C_MCR] :=$10;
                         { Enable loopback mode }
  Port[P+C_LCR] := $80;                          { Enable divisor latch mode }
  B1 := Port[P];                                 { Save current baud rate }
  B2 := Port[P+1];
  Port[P] := 4;                                  { Set baud rate to 28000 }
  Port[P+1] := 0;
  Port[P+C_LCR] := $03;                          { Transmit mode 28000:8N1 }
  Port[P] := TestByte1;                          { Test byte #1 }
  Delay(20);                                     { Wait a bit for loopback }
  Port[P] := TestByte2;                          { Test byte #2 }
  Delay(20);                                     { Wait a bit for loopback }
  ComExist := True;                              { Test passed: Port exists }
  Port[P+C_LCR] := $80;                          { Restore baud rate }
  Port[P] := B1;
  Port[P+1] := B2;
  Port[P+C_LCR] := L;                            { Restore parameters }
  Port[P+C_MCR] := M;                            { Restore control lines }
End;

{****************************************************************************}
{*                                                                          *}
{*  Function ComTrueBaud(Baud:Longint) : Real                               *}
{*                                                                          *}
{*  Baud:Longint  ->  User baud rate to test.                               *}
{*                    Should be between C_MinBaud and C_MaxBaud.            *}
{*  Returns the actual baud rate based on the accuracy of the 8250 divider. *}
{*                                                                          *}
{*  The ASYNC11 communications package allows the programmer to select ANY  *}
{*  baud rate, not just those that are predefined by the BIOS or other      *}
{*  agency.  Since the 8250 uses a divider/counter chain to generate it's   *}
{*  baud clock, many non-standard baud rates can be generated.  However,    *}
{*  the binary counter/divider is not always capable of generating the      *}
{*  EXACT baud rate desired by a user.  This function, when passed a valid  *}
{*  baud rate, will return the ACTUAL baud rate that will be generated.     *}
{*  The baud rate is based on a 8250 input clock rate of 1.73728 MHz.       *}
{*                                                                          *}
{****************************************************************************}

Function ComTrueBaud(Baud:Longint) : Real;

Var
  X : Real;
  Y : Word;

Begin
  X := Baud;
  If X < C_MinBaud Then X := C_MinBaud;
  If X > C_MaxBaud Then X := C_MaxBaud;
  ComTrueBaud := 115200 / Round($900/(X/50));
End;

{****************************************************************************}
{*                                                                          *}
{*  Procedure ComParams(CCom:Byte; Baud:Longint;                         *}
{*                      WordSize:Byte; Parity:Char; StopBits:Byte);         *}
{*                                                                          *}
{*  CCom:Byte   ->  Port # to initialize.  Must be (1 - C_MaxCom)        *}
{*                     Procedure aborted if port # invalid or unopened.     *}
{*  Baud:Longint   ->  Desired baud rate.  Should be (C_MinBaud - C_MaxBaud)*}
{*                     C_MinBaud or C_MaxBaud used if out of range.         *}
{*  WordSize:Byte  ->  Word size, in bits.  Must be 5 - 8 bits.             *}
{*                     8-bit word used if out of range.                     *}
{*  Parity:Char    ->  Parity classification.                               *}
{*                     May be N)one, E)ven, O)dd, M)ark or S)pace.          *}
{*                     N)one selected if classification unknown.            *}
{*  StopBits:Byte  ->  # of stop bits to pad character with.  Range (1-2)   *}
{*                     1 stop bit used if out of range.                     *}
{*                                                                          *}
{*  ComParams is used to configure an OPEN'ed port for the desired comm-    *}
{*  unications parameters, namely baud rate, word size, parity form and     *}
{*  # of stop bits.  A call to this procedure will set up the port approp-  *}
{*  riately, as well as assert the DTR, RTS and OUT2 control lines and      *}
{*  clear all buffers.                                                      *}
{*                                                                          *}
{****************************************************************************}

Procedure ComParams(CCom:Byte; Baud:LongInt; WordSize:Byte; Parity:Char; StopBits:Byte);

Const
  C_Stopbit1    = $00;                 { Bit masks for parity, stopbits }
  C_Stopbit2    = $04;
  C_NoParity    = $00;
  C_OddParity   = $08;
  C_EvenParity  = $18;
  C_MarkParity  = $28;
  C_SpaceParity = $38;

Var
  X : Real;
  Y,P : Word;
  DivMSB,DivLSB : Byte;
  WS,SB,PTY : Byte;

Begin
  If (CCom<1) Or (CCom>C_MaxPort) Or (Not C_PortOpen[CCom]) Then Exit;

  Inline($FA);
  P := C_PortAddr[CCom];

  { Calculate baud rate divisors }

  X := Baud;
  If X < C_MinBaud Then X := C_MinBaud;
  If X > C_MaxBaud Then X := C_MaxBaud;
  Y := Round($900/(X/50));
  DivMSB := Hi(Y);
  DivLSB := Lo(Y);

  { Determine parity mask }
  { Default if unknown: No parity }

  Case UpCase(Parity) Of
    'N' : PTY := C_NoParity;
    'E' : PTY := C_EvenParity;
    'O' : PTY := C_OddParity;
    'M' : PTY := C_MarkParity;
    'S' : PTY := C_SpaceParity;
  Else
    PTY := C_NoParity;
  End;

  { Determine stop-bit mask }
  { Default if out of range: 1 Stop bit }

  Case StopBits Of
    1 : SB := C_StopBit1;
    2 : SB := C_StopBit2;
  Else
    SB := C_StopBit1;
  End;

  { Determine word-size mask }
  { Default if out of range: 8 bit word size }

  If (WordSize >= 5) And (WordSize <= 8) Then
    WS := WordSize - 5
  Else
    WS := 3;

  { Initialize line-control register }

  Y := Port[P] + Port[P+C_LSR];
  Port[P+C_LCR] := WS + SB + PTY;

  { Initialize baud rate divisor latches }

  Port[P+C_LCR] := Port[P+C_LCR] Or $80;
  Port[P] := DivLSB;
  Port[P+1] := DivMSB;
  Port[P+C_LCR] := Port[P+C_LCR] And $7F;
  X := Port[P] + Port[P+C_LSR] + Port[P+C_MSR] + Port[P+C_IIR];

  { Assert RS323 control lines (DTR,RTS,OUT2) & exit }

  Port[P+C_MCR] := $0B;

  ClearCom(CCom,'B');
  Inline($FB);
End;

{****************************************************************************}
{*                                                                          *}
{*  Function OpenComCCom:Byte; InBufferSize,OutBufferSize:Word):Boolean *}
{*                                                                          *}
{*  CCom:Byte        ->  Port # to OPEN (1 - C_MaxCom)                   *}
{*                          Request will fail if out of range or port OPEN  *}
{*  InBufferSize:Word   ->  Requested size of input (receive) buffer        *}
{*  OutBufferSize:Word  ->  Requested size of output (transmit) buffer      *}
{*  Returns success/fail status of OPEN request (TRUE if OPEN successful)   *}
{*                                                                          *}
{*  OpenCom must be called before any activity (other than existence check, *}
{*  see the ComExist function) takes place.  OpenCom initializes the        *}
{*  interrupt drivers and serial communications hardware for the selected   *}
{*  port, preparing it for I/O.  Memory for buffers is allocated on the     *}
{*  Pascal "heap", thus freeing data-segment memory for larger more data-   *}
{*  intensive programs.  Once a port has been OPENed, a call to ComParams   *}
{*  should be made to set up communications parameters (baud rate, parity   *}
{*  and the like).  Once this is done, I/O can take place on the port.      *}
{*  OpenCom will return a TRUE val     ue if the opening procedure was success-  *}
{*  ful, or FALSE if it is not.                                             *}
{*                                                                          *}
{****************************************************************************}

Function OpenCom(CCom:Byte; InBufferSize,OutBufferSize:Word) : Boolean;

Var
  TempVec : Pointer;
  P : Word;
  IntLn,X : Byte;

Begin
  { Ensure that port was not previously open }

  OpenCom := False;
  If (CCom<1) Or (CCom>C_MaxPort) Or C_PortOpen[CCom] Then Exit;
  If Not ComExist(CCom) Then

  { Clear any pending activity from 8250 interrupt queue }

  Inline($FA);
  P := C_PortAddr[CCom];
  Port[P+C_IER] := $0D;
  X := Port[P] + Port[P+C_LSR] + Port[P+C_MSR] + Port[P+C_IIR];

  { Set up interrupt vectors & 8259 PIC }

  IntLn := C_PortInt[CCom];
  GetIntVec(8+IntLn,TempVec);

  If C_OldINTVec[IntLn] <> TempVec Then
    Begin
      C_OldINTVec[IntLn] := TempVec;
      SetIntVec(8+IntLn,@Int_Handler);
      Port[$21] := Port[$21] And (($01 SHL IntLn) XOR $FF);
      X := Port[$21];
    End;

  { Allocate memory for I/O buffers }

  C_InSize[CCom] := InBufferSize;
  C_OutSize[CCom] := OutBufferSize;
  GetMem(C_InBufPtr[CCom],InBufferSize);
  GetMem(C_OutBufPtr[CCom],OutBufferSize);

  { Set up default parameters for port }

  C_RTSOn[CCom] := InBufferSize - 2;
  C_RTSOff[CCom] := InBufferSize - 1;
  C_StartChar[CCom] := ^Q;
  C_StopChar[CCom] := ^S;
  C_PortOpen[CCom] := True;
  OpenCom := True;

  Inline($FB);
End;

{****************************************************************************}
{*                                                                          *}
{*  Procedure CloseCom(CCom:Byte)                                        *}
{*                                                                          *}
{*  CCom:Byte  ->  Port # to close                                       *}
{*                    Request ignored if port closed or out of range.       *}
{*                                                                          *}
{*  CloseCom will un-link the interrupt drivers for a port, deallocate it's *}
{*  buffers and drop the DTR and RTS signal lines for a port opened with    *}
{*  the OpenCom function.  It should be called before exiting your program  *}
{*  to ensure that the port is properly shut down.                          *}
{*  NOTE:  CloseCom shuts down a communications channel IMMEDIATELY,        *}
{*         even if there is data present in the input or output buffers.    *}
{*         Therefore, you may wish to call the ComWaitForClear procedure    *}
{*         before closing the ports.                                        *}
{*                                                                          *}
{****************************************************************************}

Procedure CloseCom(CCom:Byte);

Var
  ClosePort : Boolean;
  P,IntLn,X : Word;
  shit:word;

Begin
  If (CCom<1) Or (CCom>C_MaxPort) Or (Not C_PortOpen[CCom]) Then Exit;

  { Drop RS232 control lines (DTR,RTS,OUT2) and reset 8250 interrupt mode }

  Inline($FA);
  P := C_PortAddr[CCom];
  shit:=port[p+c_mcr];
{  Port[P+C_MCR] := shit or $011;}
port [$20]:=$20;
{010}
  Port[P+C_IER] := 0;
  port[p+c_mcr] :=port[p+c_mcr] or 1;

  C_PortOpen[CCom] := False;

  { Reset INT vectors & 8259 PIC if all COMs on selected INT are closed }

  IntLn := C_PortInt[CCom];
  ClosePort := True;
  For X := 1 To C_MaxCom Do
    If C_PortOpen[X] And (C_PortInt[X] = IntLn) Then
      ClosePort := False;

  If ClosePort Then
    Begin
      Port[$21] := Port[$21] Or ($01 SHR IntLn);
      X := Port[$21];
      SetIntVec(8+IntLn,C_OldINTVec[IntLn]);
    End;
  X := Port[P] + Port[P+C_LSR] + Port[P+C_MSR] + Port[P+C_IIR];

  { Deallocate buffers }

  FreeMem(C_InBufPtr[CCom],C_InSize[CCom]);
  FreeMem(C_OutBufPtr[CCom],C_OutSize[CCom]);
  Inline($FB);
End;

{****************************************************************************}
{*                                                                          *}
{*  Procedure CloseAllComs                                                  *}
{*                                                                          *}
{*  CloseAllComs will CLOSE all currently OPENed ports.  See the CloseCom   *}
{*  procedure description for more details.                                 *}
{*                                                                          *}
{****************************************************************************}

Procedure CloseAllComs;

Var
  X : Byte;

Begin
  For X := 1 To C_MaxCom Do
    If C_PortOpen[X] Then
      CloseCom(X);
End;

{****************************************************************************}
{*                                                                          *}
{*                        UNIT Initialization Code                          *}
{*                                                                          *}
{****************************************************************************}

                    {$F+}Procedure AsyncExit;
            { Exit procedure, close ports }
          Var
            i:Word;
          Begin{ AsyncExit }
           Closeallcoms;
            ExitProc:=FormerExitProc;
          End;{ AsyncExit }



Begin
                 FormerExitProc:=ExitProc;
            ExitProc:=@AsyncExit;




  For x := 1 to C_MaxPort Do
    Begin
      C_PortOpen[x] := False;
      C_InBufPtr[x] := Nil;
      C_OutBufPtr[x] := Nil;
      C_OldIntVec[x] := Nil;
      C_InHead[x] := 0;
      C_OutHead[x] := 0;
      C_InTail[x] := 0;
      C_OutTail[x] := 0;
      C_InSize[x] := 0;
      C_OutSize[x] := 0;
      C_RTSOn[x] := 0;
      C_RTSOff[x] := 0;
      C_StartChar[x] := ^Q;
      C_StopChar[x] := ^S;
      C_Status[x] := 5;
      C_Ctrl[x] := 0;
      C_XL3Ptr[x] := 0;
      Port[C_PortAddr[x]+C_MCR] := $00;
    End;

End.
