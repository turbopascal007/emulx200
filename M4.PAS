{ Emulex/2 Modem driver routines}
{ Copyright 1988/9 Emulex Canadian Development Ltd. }

unit modem;

Interface

uses crt,
     dos,
     gentypes;

  Const
  YasyncVersion = 14; { Current version * 10 }
  MaxPorts = 4;       { Maximum number of ports supported }
  DefaultBufferSize = 2048; { Default size of receive & transmit buffers }
  BaudRateDividend : LongInt = 115200; { Used to compute baud rate divisor }
  TimeoutMilliseconds : LongInt = 1000; { Retry Send until timeout ms }
  BreakMiliseconds : Word = 300; { Duration of break signal }

  { These constants define the bits for the Line Status Register }
  LSRRcvReady = $01;  { Received data ready }
  LSROverrun  = $02;  { OverRun error }
  LSRParity   = $04;  { Parity error }
  LSRFrame    = $08;  { Framing error }
  LSRBreak    = $10;  { Break detected }
  LSRXhReady  = $20;  { Transmit hold register empty }
  LSRXsReady  = $40;  { Transmit shift register empty }
  LSRTimeout  = $80;  { Time out (software implemented) }

  { These constants define the bits for the Modem Status Register }
  MSRctsDelta = $01;  { Clear To Send changed }
  MSRdsrDelta = $02;  { DataSet Ready changed }
  MSRriDelta  = $04;  { Ring Indicate changed }
  MSRcdDelta  = $08;  { Carrier Detect changed }
  MSRcts      = $10;  { Clear To Send }
  MSRdsr      = $20;  { DataSet Ready }
  MSRri       = $40;  { Ring Indicate }
  MSRcd       = $80;  { Carrier Detect }

Type
  AsyncBuffer = Array[0..32767] Of Byte;
  {
    Note, AsyncBuffer is for the buffer pointer declarations below.  The actual
    buffer size is specified in Async_Control.
  }
  Async_Control = Record
  {
    This record contains control information used to manage the activity of
    a port.  Certain fields may be altered before calling OpenPort.  These
    are marked with an "*" in the comments.  For instance...

      With AsyncPort[2] Do Begin
        ReceiveSize := 10000;
        TransmitSize := 8000;
        WaitForXon := True;
        XoHand := True;
        XoTransparent := False;
      End;
      OpenPort(2, 9600, 7, 1, 'E');

    ...sets buffer sizes and Xon/Xoff handshaking for COM2 and opens COM2 at
    9600 bps, 7 bits, 1 stop bit, even parity.  Fields not marked with "*"
    in comments are used internally by YAsync; do not alter these fields.
    Do not alter any fields while a port is open.
  }
    PortOpen : Boolean;       { True if port is currently open }
    VectorIndex : Byte;       { Index to interrupt vector save area }

    IrqNumber : Byte;         { *IRQ number }
    IntNumber : Byte;         { *Interrupt number }
    BasePort : Word;          { *Base I/O port for UART }
    {
      The IRQ, Interrupt and base port numbers are set to default values during
      initialization.  The defaults (see implementation Const's for details)
      should be appropriate for most systems, but they may be reset if
      necessary before calling OpenPort.
    }
    LineStatus : Byte;        { Line status register for ErrorRoutine,
                                  Decode with LSRxxx constants above }
    ModemStatus : Byte;       { Modem status register for ModemRoutine,
                                  Decode with MSRxxx constants above }
    UserData : Word;          { This field is unused by YAsync routines }

    WaitForXon : Boolean;     { *Inhibit transmit between Xoff and Xon }
    WaitForCts : Boolean;     { *Inhibit transmit if not Cts }
    WaitForDsr : Boolean;     { *Inhibit transmit if not Dsr }
    WaitForCd  : Boolean;     { *Inhibit transmit if not Cd }
    XoHand : Boolean;         { *Handshake receive buffer with Xon/Xoff }
    RtsHand : Boolean;        { *Handshake receive buffer with Rts }
    DtrHand : Boolean;        { *Handshake receive buffer with Cts }
    XoTransparent : Boolean;  { *Pass Xon/Xoff through to data stream }
    {
      If XoTransparent is False, Xon and Xoff characters are not placed in
      the receive buffer (they will still have their handshaking effect if
      WaitForXon is True).  The defaults are:
        WaitForXon = False
        WaitForCts = False
        WaitForDsr = False
        WaitForCd = False
        XoHand = False
        RtsHand = True
        DtrHand = False
        XoTransparent = True
    }
    TransmitEnabled : Boolean;{ If False, transmit is inhibited }
    SenderEnabled : Boolean;  { Handshake signal was sent to sender }
    AwaitingXon : Boolean;    { True if waiting for Xon }
    AwaitingCts : Boolean;    { True if waiting for Cts }
    AwaitingDsr : Boolean;    { True if waiting for Dsr }
    AwaitingCd  : Boolean;    { True if waiting for Cd }
    AwaitingCh  : Boolean;    { True if waiting for character to transmit }
    StreamInsert : Byte;      { Character to be forced into output stream }

    ErrorRoutine : Pointer;   { *Pointer to routine for line status interrupt }
    ModemRoutine : Pointer;   { *Pointer to routine for modem status intrpt }
    {
      These routines must be declared as Far-calls ($F+) at the global level
      with a one-Word value parameter, the port number.  Do NOT declare
      them as "Interrupt" type procedures.  These routines, though not
      "Interrupt" type routines, are called from the interrupt service routine,
      therefore they should follow the same rules as an ISR - no DOS services,
      reentrant, etc.  ErrorRoutine should examine LineStatus to determine the
      cause of the error; ModemRoutine should examine ModemStatus.
    }
    ReceiveBuffer : ^AsyncBuffer;  { *Receive buffer }
    ReceiveSize : Word;            { *0..32767 }
    ReceiveHead : Word;
    ReceiveTail : Word;
    TransmitBuffer : ^AsyncBuffer; { *Transmit buffer }
    TransmitSize : Word;           { *0..32767 }
    TransmitHead : Word;
    TransmitTail : Word;
    ReleaseReceive : Boolean; { YAsync obtained receive buffer, must release }
    ReleaseTransmit : Boolean;{ Ditto, transmit buffer }
    {
      Buffers are allocated from the heap if the corresponding pointer is Nil
      when OpenPort is called.  You may allocate a buffer yourself and place
      its address in ReceiveBuffer or TransmitBuffer, and its size in
      ReceiveSize or TransmitSize.  Alternatively, you may change the size of
      the automatically allocated buffer by changing ReceiveSize or
      TransmitSize before calling OpenPort.
    }
  End;

  SetOfChar = Set of Char; { Used by LineReadPort below }

Var
  comport,usecom:integer;
  AsyncPort: Array[1..MaxPorts] Of Async_Control;
  PortOpenError : Byte;  { Error code from open routine..
                           0 Normal, open successful
                           1 Port number out of range (1..4)
                           2 Baud rate out of range (50..115200)
                           3 Word length out of range (5..8)
                           4 Stop bits out of range (1..2)
                           5 Invalid parity (N,E,O,1,0)
                           6 Buffer size invalid (2..32767)
                           7 Insufficient heap space for buffers
                           8 UART not responding
                           9 Program bug - should never happen
                         }


  procedure sendbreak;
  procedure initializeAsync;
  Procedure closeport;
  procedure AsyncExit;
  Procedure sendchar(ch:Char);
  Function numchars:word;
  Function getchar:Char;
  Procedure hangup;
  Procedure setparam(baud:Integer);
  Function carrier:Boolean;
  Procedure setterminalready(dtr:Boolean);
  Procedure dontanswer;
  Procedure doanswer;
  function transmitbufferused:word;
  Procedure cleartransmitbuffer;
  Procedure clearreceivebuffer;
  Function isspace:boolean;

Implementation


Const
  { These are the offsets from BasePort of the 8250 control registers }
  DLL = 0; { Divisor Latch Least-significant-byte (LCR bit $80 on) }
  DLM = 1; { Divisor Latch Most-significant-byte (LCR bit $80 on) }
  RBR = 0; { Receiver Buffer Register (read) }
  THR = 0; { Transmitter Holding Register (write) }
  IER = 1; { Interrupt Enable Register }
  IIR = 2; { Interrupt Identification Register (read only) }
  LCR = 3; { Line Control Register }
  MCR = 4; { Modem Control Register }
  LSR = 5; { Line Status Register }
  MSR = 6; { Modem Status Register }

  { These constants define the bits for the Modem Control Register }
  MCRloop     = $10; { Loopback mode }
  MCRout2     = $08; { Out2, must be on for interrupts }
  MCRout1     = $04; { Out1 ? }
  MCRrts      = $02; { Request to send }
  MCRdtr      = $01; { Data terminal ready }

  { These are the default base ports, IRQs and interrupts }
  BasePorts : Array[1..MaxPorts] Of Word = ($03F8,$02F8,$03E8,$02E8);
  IRQs : Array[1..MaxPorts] Of Byte = (4,3,4,3);
  Interrupts : Array[1..MaxPorts] Of Byte = (12,11,12,11);

  XOn  = 17; {^Q, DC1, XOn }
  XOff = 19; {^S, DC3, XOff }

Type
  VectorType = Record
    UseCount : Byte;  { Number of ports using this interrupt vector }
    IntrptNo : Byte;  { Interrupt number for this vector }
    Vector : Pointer; { Old value of vector }
    NextPort : Word;  { Next port to process }
    PortList : Array[0..MaxPorts] Of Word; { Open ports using this vector }
  End;

Var
  FormerExitProc : Pointer; { Save area for ExitProc pointer }
  VectorSave : Array[1..MaxPorts] Of VectorType;

  Procedure CallFar(ComPort:Word;proc:Pointer);
      Inline($5B/{ pop bx   ; save @proc in cx:bx }
        $59/{ pop cx }
        $0E/{ push cs  ; set up return address }
        $E8/$00/$00/{ call $ }
        $58/{ pop ax }
        $05/$08/$00/{ add ax,8 }
        $50/{ push ax }
        $51/{ push cx  ; restore @proc to stack }
        $53/{ push bx }
        $CB);{ retf     ; go to proc }

  Procedure DisableInterrupts; { Disable 80x86/8 interrupts }
        Inline($FA);

  Procedure EnableInterrupts; { Enable 80x86/8 interrupts }
	  Inline($FB);

  Procedure SendBreak; { Send break signal }
  Var Timer : LongInt;
      LastTail : Word;
  Begin { SendBreak }
    With AsyncPort[ComPort] Do Begin
      If TransmitSize > 0 Then Begin { Allow transmit buffer to empty }
	Timer := TimeoutMilliseconds;
	LastTail := TransmitTail;
	While (TransmitHead <> TransmitTail) And (Timer > 0) Do Begin
	  Dec(Timer);
	  Delay(1);
	  If LastTail <> TransmitTail Then Begin
	    LastTail := TransmitTail;
	    Timer := TimeoutMilliseconds;
	  End;
	End;
	If Timer = 0 Then Begin
	  LineStatus := LSRTimeout;
	  If ErrorRoutine <> Nil Then CallFar(ComPort, ErrorRoutine);
	End;
      End;
      Port[BasePort+LCR] := Port[BasePort+LCR] Or $40; { Turn on break }
      Delay(BreakMiliseconds);
      Port[BasePort+LCR] := Port[BasePort+LCR] And $BF; { Turn off break }
    End;
  End;  { SendBreak }

  Function numchars:Word; { Return number of receive buffer bytes used }
  Begin
    With AsyncPort[ComPort] Do Begin
      DisableInterrupts;
      If ReceiveHead<ReceiveTail Then numchars:=(ReceiveSize-ReceiveTail)+ReceiveHead
	Else numchars:=ReceiveHead-ReceiveTail;
      EnableInterrupts;
    End;
  End;

  Function TransmitBufferUsed:Word; { Return number of transmit buffer bytes used }
  Begin
    With AsyncPort[ComPort] Do Begin
      DisableInterrupts;
      If TransmitHead<TransmitTail Then TransmitBufferUsed:=(TransmitSize-TransmitTail)+TransmitHead
	Else TransmitBufferUsed:=TransmitHead-TransmitTail;
      EnableInterrupts;
    End;
  End;{ TransmitBufferUsed }

  Procedure SetTerminalReady(Dtr:Boolean); { Set DTR on/off }
  Begin
    If transmitbufferused>0 Then Delay(1000);
    If transmitbufferused>0 Then Delay(1000);
    If transmitbufferused>0 Then Delay(1000);
    With AsyncPort[ComPort] Do Begin
      If Dtr Then Port[BasePort+MCR]:=Port[BasePort+MCR] Or MCRdtr
	Else Port[BasePort+MCR]:=Port[BasePort+MCR] And Not MCRdtr;
    End;
  End;

  Procedure dontanswer;
  Begin
    setterminalready(False);
  End;

  Procedure doanswer;
  Begin
    setterminalready(True);
  End;

  Procedure hangup;
  Begin
    dontanswer;
  End;

  Procedure SetRTS(Rts:Boolean); { Set RTS on/off }
  Begin
    With AsyncPort[ComPort] Do Begin
      If Rts Then Port[BasePort+MCR]:=Port[BasePort+MCR] Or MCRrts
	Else Port[BasePort+MCR]:=Port[BasePort+MCR] And Not MCRrts;
    End;
  End;{ SetRTS }

  Procedure EnableTransmit; { Enable buffered transmit, restart interrupt if necessary }
  Begin
    With AsyncPort[ComPort] Do Begin
      TransmitEnabled:=True;
      DisableInterrupts;
      If (TransmitHead<>TransmitTail) And AwaitingCh Then Begin
	Port[BasePort+THR]:=TransmitBuffer^[TransmitTail];
	TransmitTail:=Succ(TransmitTail);
	If TransmitTail=TransmitSize Then TransmitTail:=0;
      End;
      EnableInterrupts;
    End;
  End;

  Procedure EnableSender; { Enable sender via handshaking signal }
  Begin
    With AsyncPort[ComPort] Do Begin
      If Not SenderEnabled Then Begin
	If XoHand Then Begin
	  DisableInterrupts;
	  If AwaitingCh Then Port[BasePort+THR]:=XOn
	    Else StreamInsert:=XOn;
	  EnableInterrupts;
	End;
	If DtrHand Then SetTerminalready(True);
	If RtsHand Then SetRts(True);
	SenderEnabled:=True;
      End;
    End;
  End;{ EnableSender }

  Procedure DisableSender; { Disable sender via handshaking signal }
  Begin
    With AsyncPort[ComPort] Do Begin
      If SenderEnabled Then Begin
	If XoHand Then Begin
	  DisableInterrupts;
	  If AwaitingCh Then Port[BasePort+THR]:=XOff
	    Else StreamInsert:=XOff;
	  EnableInterrupts;
	End;
	If DtrHand Then SetTerminalready(False);
	If RtsHand Then SetRts(False);
	SenderEnabled:=False;
      End;
    End;
  End;{ DisableSender }

  Procedure ClearTransmitBuffer; { Discard all unsent characters in the transmit buffer. }
  Begin
    With AsyncPort[ComPort] Do Begin
      DisableInterrupts;
      TransmitHead:=0;
      TransmitTail:=0;
      EnableInterrupts;
    End;
  End;{ ClearTransmitBuffer }

  Procedure ClearReceiveBuffer; { Discard all unsent characters in the receive buffer. }
  Begin
    With AsyncPort[ComPort] Do Begin
      DisableInterrupts;
      ReceiveHead:=0;
      ReceiveTail:=0;
      EnableInterrupts;
      EnableSender;
    End;
  End;

  Procedure AsyncISR(VectorNo:Word);
  Var i,Next:Word;
      work:Byte;
      done:Boolean;
  Begin
    EnableInterrupts;
    With VectorSave[VectorNo] Do Begin
      Inc(NextPort);
      If NextPort>UseCount Then NextPort:=1;
      i:=NextPort;
      Repeat
	ComPort:=PortList[i];
	With AsyncPort[ComPort] Do Begin
	  done:=False;
	  Repeat
	    Case Port[BasePort+IIR] Of
	      $06:Begin{ Received character error or break }
		    LineStatus:=Port[BasePort+LSR];
		    If (LineStatus And LSRBreak)<>0 Then Begin
		      LineStatus:=LineStatus And Not LSRFrame;
		      work:=Port[BasePort+RBR];
		    End;
		    If ErrorRoutine<>Nil Then CallFar(ComPort,ErrorRoutine);
		  End;
	      $04:Begin{ Received data ready }
		    work:=Port[BasePort+RBR];
		    If XoTransparent Or ((work<>XOff) And (work<>XOn)) Then Begin
		      next:=Succ(ReceiveHead);
		      If next=ReceiveSize Then next:=0;
		      If next=ReceiveTail Then Begin
			LineStatus:=LSROverrun;
			If ErrorRoutine<>Nil Then CallFar(ComPort,ErrorRoutine);
		      End Else Begin
			ReceiveBuffer^[ReceiveHead]:=work;
			ReceiveHead:=next;
		      End;
		      If (XoHand Or RtsHand Or DtrHand) And SenderEnabled Then Begin
			If ReceiveHead<ReceiveTail Then next:=(ReceiveSize-ReceiveTail)+ReceiveHead
			  Else next:=ReceiveHead-ReceiveTail;
			If next>(ReceiveSize-(ReceiveSize Shr 2)) Then DisableSender;
		      End;
		    End;
		  End;

	      $02:Begin{ Transmit holding register empty }
		    If StreamInsert>0 Then Begin
		      Port[BasePort+THR]:=StreamInsert;
		      StreamInsert:=0;
		    End Else If (TransmitHead<>TransmitTail) And TransmitEnabled Then Begin
		      Port[BasePort+THR]:=TransmitBuffer^[TransmitTail];
		      Inc(TransmitTail);
		      If TransmitTail=TransmitSize Then TransmitTail:=0;
		    End Else AwaitingCh:=True;
		  End;

	      $00:Begin{ Modem status change }
		    ModemStatus:=Port[BasePort+MSR];
		    AwaitingCts:=WaitForCts And ((ModemStatus And MSRcts)=0);
		    AwaitingDsr:=WaitForDsr And ((ModemStatus And MSRdsr)=0);
		    AwaitingCd:=WaitForCd And ((ModemStatus And MSRcd)=0);
		    If (AwaitingCts Or AwaitingDsr Or AwaitingCd Or AwaitingXon) Then TransmitEnabled:=False
		      Else If Not TransmitEnabled Then EnableTransmit;
		    If ModemRoutine<>Nil Then CallFar(ComPort,ModemRoutine);
		  End;
	      Else done:=True;
	    End;
	  Until done;
	End;
	Inc(i);
	If i>UseCount Then i:=1;
      Until i=NextPort;
    End;
    DisableInterrupts;
    Port[$20]:=$20;{ Non-specific EOI to 8259 }
  End;

  Procedure AsyncISR1;Interrupt;Begin AsyncISR(1);End;
  Procedure AsyncISR2;Interrupt;Begin AsyncISR(2);End;
  Procedure AsyncISR3;Interrupt;Begin AsyncISR(3);End;
  Procedure AsyncISR4;Interrupt;Begin AsyncISR(4);End;

  Procedure ClosePort; { Release async port }
  Var Timer:LongInt;
      i,LastTail:Word;
  Begin
    With AsyncPort[ComPort] Do Begin
      If PortOpen Then Begin
(*	{ Allow transmit buffer to empty }
	Timer := TimeoutMilliseconds;
	LastTail := TransmitTail;
	While nd (Timer > 0) Do Begin
	  Dec(Timer);
	  Delay(1);
	  If LastTail <> TransmitTail Then Begin
	    LastTail := TransmitTail;
	    Timer := TimeoutMilliseconds;
	  End;
	End;
	If Timer = 0 Then Begin
	  LineStatus := LSRTimeout;
	  If ErrorRoutine <> Nil Then CallFar(ComPort, ErrorRoutine);
	End; *)
	With VectorSave[VectorIndex] Do Begin
	  i:=0;
	  Repeat Inc(i) Until (i>=UseCount) Or (PortList[i]=ComPort);
	  PortList[i]:=PortList[UseCount];
	  Dec(UseCount);
	  If UseCount=0 Then Begin{ No more ports using this irq }
	    Port[$21] := Port[$21] Or (1 Shl IrqNumber);
	    SetIntVec(IntrptNo,Vector);
	  End;
	End;
	If ReleaseReceive Then Begin { Free buffers }
	  FreeMem(ReceiveBuffer,ReceiveSize);
	  ReceiveBuffer:=Nil;
	End;
	If ReleaseTransmit Then Begin
	  FreeMem(TransmitBuffer,TransmitSize);
	  TransmitBuffer:=Nil;
	End;
	PortOpen:=False;
	port[$20]:=$20;
	Port[BasePort+IER]:=0;
	Port[BasePort+MCR] := port [baseport+mcr] or McRdTr;
      End;
    End;
  End;

  Function OpenPort(ComPort:Word;{ Com 1-4 }
                          BaudRate:LongInt;{ BPS, 50..115200 }
                          WordLength:Word;{ 5..8 bits }
                          StopBits:Word;{ 1..2 stop bits }
                          Parity:Char{ N,E,O,1,0 }
                          ):Boolean;{ Return True if open successful }
  Var BaudDivisor:Word;
      Work,FreeSave:Byte;
  Begin
    If (ComPort<1) Or (ComPort>MaxPorts) Then PortOpenError:=1
     Else With AsyncPort[ComPort] Do Begin
      If PortOpen Then ClosePort Else Begin{ Precautionary... }
        port[$20]:=$20;
        Port[BasePort+IER]:=0;
        Port[BasePort+MCR] := port [baseport+mcr] or McRdTr;
      End;
      PortOpenError:=0;
      Parity:=UpCase(Parity);
      if (receivesize<16) or (receivesize>2048) then receivesize:=64;
      if (transmitsize<16) or (transmitsize>2048) then transmitsize:=512;
      If (BaudRate<50) Or (BaudRate>115200) Then PortOpenError:=2
       Else If (WordLength<5) Or (WordLength>8) Then PortOpenError:=3
        Else If (StopBits<1) Or (StopBits>2) Then PortOpenError:=4
         Else If Not(Parity In ['N','E','O','1','0']) Then PortOpenError:=5
          Else If (ReceiveSize<2) Or (ReceiveSize>32767) Or (TransmitSize<2) Or (TransmitSize>32767)
           Then PortOpenError:=6 Else Begin
      ReleaseReceive:=False;
      ReleaseTransmit:=False;
      If ReceiveBuffer=Nil Then Begin
        If MaxAvail<ReceiveSize Then PortOpenError:=7 Else Begin
          GetMem(ReceiveBuffer,ReceiveSize);
          ReleaseReceive:=True;
        End;
      End;
      If TransmitBuffer=Nil Then Begin
        If MaxAvail<TransmitSize Then PortOpenError:=7 Else ReleaseTransmit:=True;
      End;
      If ReleaseReceive Then Begin
        FreeMem(ReceiveBuffer,ReceiveSize);
        ReceiveBuffer:=Nil;
      End;
     End;
     If (PortOpenError=0) And ((Port[BasePort+IIR] And $F8)<>0) Then PortOpenError:=8;
     If PortOpenError=0 Then Begin { Get buffers }
       If ReceiveBuffer=Nil Then GetMem(ReceiveBuffer,ReceiveSize);
       ReceiveHead:=0;
       ReceiveTail:=0;
       If TransmitBuffer=Nil Then GetMem(TransmitBuffer,TransmitSize);
       TransmitHead:=0;
       TransmitTail:=0;
       BaudDivisor:=BaudRateDividend Div BaudRate; { Set baud rate }
       Port[BasePort+LCR]:=$80;
       Port[BasePort+DLM]:=Hi(BaudDivisor);
       Port[BasePort+DLL]:=Lo(BaudDivisor);
       Work:=WordLength-5; { Set Word Length, Stop Bits, Parity }
{       If StopBits=2 Then Work:=Work Or $04; }
{       Case Parity Of
         'N' :;
         'O' :Work:=Work Or $08;
         'E' :Work:=Work Or $18;
         '1' :Work:=Work Or $28;
         '0' :Work:=Work Or $38;
       End; }
       Port[BasePort+LCR]:=Work;
       LineStatus:=Port[BasePort+LSR]; { Read registers to reset pending conditions }
       ModemStatus:=Port[BasePort+MSR];
       Work:=Port[BasePort+RBR];
       AwaitingXon:=False;
       AwaitingCh:=True;
       SenderEnabled:=True;
       FreeSave:=0; { Set interrupts }
       VectorIndex:=1;
       While (VectorIndex<=MaxPorts) And
        ((VectorSave[VectorIndex].UseCount=0) Or (VectorSave[VectorIndex].IntrptNo<>IntNumber)) Do Begin
         If (FreeSave=0) And (VectorSave[VectorIndex].UseCount=0) Then FreeSave:=VectorIndex;
         Inc(VectorIndex);
       End;
       If VectorIndex<=MaxPorts Then With VectorSave[VectorIndex] Do Begin
         DisableInterrupts;
         Inc(UseCount);
         PortList[UseCount]:=ComPort;
       End Else If FreeSave=0 Then PortOpenError:=9{ This should never happen }
        Else With VectorSave[FreeSave] Do Begin{ Save old vector }
          VectorIndex:=FreeSave;
          UseCount:=1;
          PortList[1]:=ComPort;
          IntrptNo:=IntNumber;
          GetIntVec(IntrptNo,Vector);
          Case VectorIndex Of
            1:SetIntVec(IntrptNo,@AsyncISR1);
            2:SetIntVec(IntrptNo,@AsyncISR2);
            3:SetIntVec(IntrptNo,@AsyncISR3);
            4:SetIntVec(IntrptNo,@AsyncISR4);
           Else PortOpenError:=9;{ This shouldn't happen }
          End;
          Port[$21]:=Port[$21] And Not(1 Shl IrqNumber);
        End;
       PortOpen:=True;
       Port[BasePort+MCR]:=MCRout2+MCRrts+MCRdtr;
       Port[BasePort+IER]:=$0F;{ Enable 8250 interrupts }
       EnableInterrupts;
       AwaitingCts:=WaitForCts And ((ModemStatus And MSRcts)=0);
       AwaitingDsr:=WaitForDsr And ((ModemStatus And MSRdsr)=0);
       AwaitingCd:=WaitForCd And ((ModemStatus And MSRcd)=0);
       TransmitEnabled:=Not(AwaitingCts Or AwaitingDsr Or AwaitingCd);
     End;
     OpenPort:=PortOpen And (PortOpenError=0);
    End;
  End;

  Procedure setparam(Baud:Integer);
  Begin
    comport:=usecom;
    If Not openport(comport,baud,8,1,'N') Then Begin
      WriteLn('Error opening Com',comport,' at ',baud,' baud');
      Halt(9);
    End;
  End;

  Function carrier:Boolean;
  Begin
    carrier:=(Port[BasePorts[Comport]+$06] And 128)=128;
  End;

  Procedure Sendchar(Ch:Char);
  Var Timer:LongInt;
      next:Word;
  Begin
    With AsyncPort[ComPort] Do Begin
      Timer:=TimeoutMilliseconds;
      next:=Succ(TransmitHead);
      If next=TransmitSize Then next:=0;
      While (next=TransmitTail) And (Timer>0) Do Begin
        Delay(1);
        Dec(Timer);
      End;
      If Timer>0 Then Begin
        DisableInterrupts;
        If TransmitEnabled And AwaitingCh Then Begin
          Port[BasePort+THR]:=Ord(Ch);
          AwaitingCh:=False;
        End Else Begin
          TransmitBuffer^[TransmitHead]:=Ord(Ch);
          TransmitHead:=next;
        End;
        EnableInterrupts;
      End Else Begin
        LineStatus:=LSRTimeout;
        If ErrorRoutine<>Nil Then CallFar(ComPort,ErrorRoutine);
      End;
    End;
  End;

  Function getchar:Char; { Returns received character from buffer }
  Var ch:Char;
      bufused:Word;
      Rch:Byte Absolute Ch;
  Begin
    With AsyncPort[ComPort] Do Begin
      If ReceiveHead=ReceiveTail Then Else Begin
        Rch:=ReceiveBuffer^[ReceiveTail];
        DisableInterrupts;
        Inc(ReceiveTail);
        If ReceiveTail=ReceiveSize Then ReceiveTail:=0;
        EnableInterrupts;
        getchar:=ch;
      End;
      If Not SenderEnabled And (XoHand Or RtsHand Or DtrHand) Then Begin
        DisableInterrupts;
        If ReceiveHead<ReceiveTail Then bufused:=(ReceiveSize-ReceiveTail)+ReceiveHead
         Else bufused:=ReceiveHead-ReceiveTail;
        EnableInterrupts;
        If bufused<(ReceiveSize Shr 1) Then EnableSender;
      End;
    End;
  End;

  Function isspace:boolean; { Returns true if first char in buffer is space..
                              if it is, removes it .. }
  Var ch:char;
  Begin
    isspace:=false;
    With AsyncPort[ComPort] Do
      if receivehead=receivetail then isspace := false
        else if receivebuffer^[receivetail] = ord(^X) then begin
          cleartransmitbuffer;
          ch := getchar ;
          isspace := true ;
        end else isspace := false;
  End;

  Procedure AsyncExit; { Exit procedure, close ports }
  Var i:Word;
  Begin
    For i:=1 To MaxPorts Do ClosePort;
    ExitProc:=FormerExitProc;
  End;

  Procedure InitializeAsync; { Initialize data areas and install exit proc }
  Var i:Word;
  Begin
    For i:=1 To MaxPorts Do Begin
      With AsyncPort[i] Do Begin
        PortOpen:=False;
        IrqNumber:=IRQs[i];
        IntNumber:=Interrupts[i];
        VectorIndex:=0;
        BasePort:=BasePorts[i];
        LineStatus:=0;
        ModemStatus:=0;
        UserData:=0;
        WaitForXon:=False; {True}
        WaitForCts:=False; {True}
        WaitForDsr:=False; {True}
        WaitForCd:=False;
        RtsHand:=False; {True}
        DtrHand:=True;
        XoHand:=False;
        XoTransparent:=false;
        TransmitEnabled:=True;
        AwaitingXon:=False;
        AwaitingCts:=False;
        AwaitingDsr:=False;
        AwaitingCd:=False;
        AwaitingCh:=True;
        SenderEnabled:=True;
        StreamInsert:=0;
        ErrorRoutine:=Nil;
        ModemRoutine:=Nil;
        ReceiveBuffer:=Nil;
        ReceiveSize:=DefaultBufferSize;
        ReceiveHead:=0;
        ReceiveTail:=0;
        TransmitBuffer:=Nil;
        TransmitSize:=DefaultBufferSize;
        TransmitHead:=0;
        TransmitTail:=0;
        ReleaseReceive:=True;
        ReleaseTransmit:=True;
      End;
      With VectorSave[i] Do Begin
        UseCount:=0;
        IntrptNo:=0;
        Vector:=Nil;
        NextPort:=1;
      End;
    End;
    PortOpenError:=0;
    FormerExitProc:=ExitProc;
    ExitProc:=@AsyncExit;
  End;

End.
