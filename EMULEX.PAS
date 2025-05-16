program Emulex2;
    {
    COMPILER DIRECTIVES


    Code    Directive          State          Note
    }
    {$A-            Align Data  Off            Don't change }
    {$B-    Boolean evaluation  Short Cicuit   Don't change }
    {$D-     Debug information  Off            Makes code larger/slower }
    {$E-             Emulation  On             Simulate 8087 }
    {$F+       Force far calls  Off            Makes code larger/slower }
    {$I-          I/O checking  Off            Don't change }
    {$L+           Link buffer  Memory         Change if you have enough memory }
    {$N-    Numeric processing  Software       Change if you have an 8087 }
    {$O+               Overlay  Off            Disable Overlays }
    {$R-        Range checking  Off            Don't change }
    {$S-        Stack checking  Off            Makes code larger/slower }
    {$V-   Var-string checking  Relaxed        Don't change }

    {$M 63000,3000,25000   Stack/heap  64k/none       Don't change }

    Uses
    initovr,
    Crt,{ Turbo Pascal CRT library }
    Dos,{ Turbo Pascal DOS library }
    Printer,{ Turbo Pascal Printer library }

    gentypes,{ All type and constant declarations }
    configrt,{ Configuration declarations / procedures }
    modem,{ Modem support }
    statret,{ System status declarations / procedures }
    gensubs,{ General subroutines: lowest level }
    subs1,{ First subroutine library }
    windows,{ Routines to manage the split screen }
    subs2,{ Second subroutine library: higer level I/O }
    textret,{ Message base routines }
    mailret,{ E-mail routines }
    userret,{ User routines }
    flags,{ Board access flag routines }
    mainr1,{ High-level routines, set one }
    ansiedit,{ Full-screen editor }
    lineedit,{ Line editor }
    mainr2,{ High-level routines set two }
    overret1,{ High-level routines, set three }
    Main,{ Main menu shell }

    chatstuf,{ Chat mode routines }
    Configur,{   Configuration section }
    Database,{        Database section }
    Doors,{            Door section }
    MainMenu,{ Main menu commands }
    Waitcall,{ Waiting for calls }
    Getlogin,{ Log-in procedure }
    Init,
    Bulletin, {        Bulletin section }
    gfiles,
      Email,  { Electronic mail section }
    Filexfer, {   File transfer section }
    voting,   { Initialization routines }
    trivia;
    {CHATSTUF}
    {$O CONFIGUR}
    {$O DATABASE}
    {$O Doors}
    {$O MAINMENU}
    {$O WAITCALL}
    {$O init}
    {$O GETLOGIN}
    {$O Bulletin}
    {$O GFILES}
    {$O EMAIL}
    {$O filexfer}
    {$O VOTING}
    {$O TRIVIA}
  Var gotoforumterm:Boolean;
          sysfi:fib absolute logfile;

  Begin
  double_check:=false;
            InitializeAsync;
            With AsyncPort[1] Do Begin
            ReceiveSize:=150;
            TransmitSize:=550;
            WaitForXon:=false;
            waitforCTS:=true;
            XoHand:=False;
            XoTransparent:=true;

          End;

          With AsyncPort[3] Do Begin
            ReceiveSize:=150;
            TransmitSize:=550;
            WaitForXon:=false;
            XoHand:=False;
            XoTransparent:=true;

          End;

          With AsyncPort[2] Do Begin
            ReceiveSize:=150;
            TransmitSize:=550;
            WaitForXon:=false;
            waitforCTS:=true;
            XoHand:=False;
            XoTransparent:=true;
          End;
    FillChar(urec,SizeOf(urec),0);
    checkbreak:=False;
    Randomize ;
    readconfig;
    validconfiguration;
    initboard(true);
    fromdoor:=ParamCount>=3;
    Repeat
      gotoforumterm:=False;
      returnfromdoor;
      If Not fromdoor Then Begin
        gotoforumterm:=waitforacall;
        getloginproc;
        If PcBMover='' Then gotoforumterm:=True;
      End;
      If  gotoforumterm=false Then Begin
        votingbooth(True);
        mainmenuproc;
        fromdoor:=False;
        If Not disconnected Then disconnect;
        ensureclosed;
        ClrScr;
        If sysnext Then Begin
          dontanswer;
          Halt(4)
        End;
        initboard(False)
      End;
      gotoforumterm:=False;
      ensureclosed;
    Until Not gotoforumterm;
    dontanswer;
    Halt(0);
  End.
