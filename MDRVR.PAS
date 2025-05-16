{$R-,S-,I-,D-,F+,V-,B-,N-,L+}

  { Emulex/2 Modem driver routines}
  unit modem;

  Interface

  uses crt,dos,lctkrnl,lctsupp,lctbbs,lcthayes;




  var transmitsize:word;
  Var icomoffset:Integer;
  Var comport:word;
  var curport:byte;
CONST
  PORTMASK = $000F;                  (* used in port validation *)

  DTR = $01;                         (* Data Terminal Ready *)
  RTS = $02;                         (* Request TO Send *)
  XON = $11;                         (* XON/XOFF characters *)
  XOFF = $13;

  OverRun = $02;                     (* Error Status Masks *)
  BadParity = $04;
  BadFrame = $08;
  BreakDet = $10;

  DeltaCTS = $01;                    (* Deltas = 1 IF bit changed *)
  DeltaDSR = $02;
  DeltaRI  = $04;
  DeltaDCD = $08;
  CTS = $10;                         (* Clear TO Send *)
  DSR = $20;                         (* Data Set Ready *)
  RI  = $40;                         (* Ring Indicator *)
  DCD = $80;                         (* Carrier Detect *)

TYPE
  BPtr = ^BYTE;
  CCB = RECORD                     (* Communications Control Block *)
    OldVector : POINTER;           (* save old interrupt vector *)
    BasePort  : WORD;              (* base 8250 port *)
    IntVec    : BYTE;              (* interrupt vector # for port *)
    IrqMask   : BYTE;              (* the IRQ mask for the port *)
    OldIrq    : BYTE;              (* previous mask *)
    MdmStat   : BYTE;              (* last modem status *)
    MdmCtl    : BYTE;              (* current mdm control value *)
    LastErr   : BYTE;              (* last detected error *)
    IntMask   : BYTE;              (* current int reg mask *)
    XState    : BOOLEAN;           (* TRUE IF auto XON/XOFF *)
    InXRecd   : BOOLEAN;           (* TRUE IF XOFF recd *)
    OutXSent  : BOOLEAN;           (* TRUE IF XOFF auto-sent *)
    BrkRecd   : BOOLEAN;           (* TRUE IF BREAK Detected *)
    TxReady   : BOOLEAN;           (* TRUE IF transmitter available *)
    InBuff    : BPtr;
    InBuffLen : INTEGER;           (* input buffer abs size *)
    InBuffCt  : INTEGER;           (* current # chars in input *)
    InBuffMk  : INTEGER;           (* high-water mark for auto XOFF *)
    InHead    : BPtr;
    InTail    : BPtr;
    InBuffEnd : BPtr;
    OutBuff    : BPtr;
    OutBuffLen : INTEGER;
    OutBuffCt  : INTEGER;
    OutHead    : BPtr;
    OutTail    : BPtr;
    OutBuffEnd : BPtr;
    SaveStk    : POINTER;
    NewStk     : POINTER;
  END;                               (* CCB *)

  CCBPTR = ^CCB;

VAR
{$F+}
  CPorts : ARRAY [0..14] of CCBPTR;


{function PortChange(CPort:INTEGER; NewBase:WORD; NewIrq,NewVector:BYTE):BOOLEAN;

function CommSetup(CPort:INTEGER; Baud:WORD; Parity:char;
                   DataBits, StopBits:INTEGER):BOOLEAN;

function CommOpen(CPort:INTEGER; Baud:WORD; Parity:char; Databits, Stopbits,
                  InSize, OutSize:INTEGER; RaiseMdmCtl:BOOLEAN) : BOOLEAN;

PROCEDURE CommClose(CPort:INTEGER; DropMdmCtl:BOOLEAN);

PROCEDURE CommTx(Cptr:CCBPTR);

function SetModemSignals(CPort : INTEGER; NewSet : BYTE) : BOOLEAN;

function ClearModemSignals(CPort : INTEGER; NewSet : BYTE) : BOOLEAN;

function FlipModemSignals(CPort : INTEGER; NewSet : BYTE) : BOOLEAN;

function SendBreak(CPort : INTEGER) : BOOLEAN;

function ModemStatus(CPort : INTEGER) : BYTE;

function ErrorStatus(CPort : INTEGER) : BYTE;

function EnableXon(CPort:INTEGER; XonFlag:BOOLEAN) : BOOLEAN;

function XoffRecd(CPort:INTEGER) : BOOLEAN;

function XoffSent(CPort:INTEGER) : BOOLEAN;

function BreakRecd(CPort:INTEGER) : BOOLEAN;}

    var  opened:boolean;
{  const  C_PortAddr : Array[1..4] Of Word = ($03F8,$02F8,$03E8,$02E8);
 const C_MCR = 4;}

    procedure initializeAsync;
    Procedure closeport;
    Procedure sendchar(ch:Char);
    Function numchars:word;
    Function getchar:Char;
    Procedure hangup;
    Procedure setparam(comnum:Byte;baud:Integer;parity:Boolean);
    Function carrier:Boolean;
    Procedure setterminalready(b:Boolean);
    Procedure dontanswer;
    Procedure doanswer;
    function transmitbufferused:word;
    Procedure cleartransmitbuffer;
    Procedure clearreceivebuffer;
    Function isspace:boolean;

    implementation


    function isspace:boolean;
    begin
    isspace:=false;
    end;




    Procedure closeport;
          Begin
          if opened then
          CommClose(curport,false);
    end;

    Procedure sendchar(ch:Char);
    var vv:byte;
    begin
            vv:=ord(ch);
    if Lctput(curport,vv) then;
    end;
    Function numchars:word;
    begin
    numchars:=bytesininput(curport);
    end;

    Function getchar:Char;
    var cd:byte;
    begin
    if lctget(curport,cd) then getchar:=chr(cd);
    end;

    Procedure hangup;
    begin
    dontanswer;
    delay(500);
    doanswer;
    end;

    Function carrier:Boolean;
    begin
    carrier:=ModemCarrieron(curport);
    end;

    Procedure setterminalready(b:Boolean);

Var
  P,X : Integer;

Begin
if b then if setmodemsignals (curport,(dtr or RTS)) then ;
if not b then if clearmodemsignals (curport,(dtr or rts)) then;
End;


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
      transmitbufferused:=bytesinoutput(curport);
    end;

    Procedure cleartransmitbuffer;
    begin
    if purgetxbuff(curport) then ;

    end;

    Procedure clearreceivebuffer;
    begin
    if purgerxbuff(curport) then ;

    end;

        Procedure setparam(comnum:Byte;baud:Integer;parity:Boolean);
          Begin

            curport:=comnum;
            comport:=comnum;


            if transmitsize<128 then transmitsize:=128;
            if transmitsize>8192 then transmitsizE:=8192;
          if   CommOpen(Comnum,Baud,'N',8,1,256,transmitsize,true)
          then writeln ('Emulex/2 Modem Driver 3.0');

                     opened:=true;
          End;



        Procedure InitializeAsync;
            { Initialize data areas and install exit proc }
          Var
            i:Word;
          Begin{ InitializeAsync }


        end;

var   FormerExitProc:Pointer;{ Save area for ExitProc pointer }

                    {$F+}Procedure AsyncExit;
            { Exit procedure, close ports }
          Var
            i:Word;
          Begin{ AsyncExit }
           ClosePort;
            ExitProc:=FormerExitProc;
          End;{ AsyncExit }


        Var a,b,c:Char;
          x,y,z:String[255];

        Begin{ Initialization }
        opened:=false;
                 FormerExitProc:=ExitProc;
            ExitProc:=@AsyncExit;

        end.{ Unit }



}
