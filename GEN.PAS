{$R-}    {Range checking off}
{$B-}    {Boolean short circuiting off}
{$S-}    {Stack checking off}
{$I+}    {I/O checking on}
{$V-}    {Relaxed Var-String Checking}
{$N-}    {No numeric coprocessor}
{$C-}    {Break Checking Off}
{$M 17500,38192,38192} {Emulex Minimail stack and heap}

program gen; {Emulex (C) 1986,1987,1988 by Sam C Brown   }
             {Emulex is a trademark, All Rights Reserved.}

Uses
dos,crt,initial,emulex2,emulex3,emulex45,emulex4,emulex5; {TPU Object Codes}
    { Initial = Globals+low Levels }
    { Emulex 2-5=main code modules }

VAR Q:FILE OF CONFIGSETTYPE;

Procedure Sam_is_god;
Begin
  InitializeAsync;
With AsyncPort[1] do  begin
  end;
  With AsyncPort[2] do  begin
  end;
end;

procedure readconfig;
   VAR i:integer;

    ln:word;
    ll:configsettype absolute mustbefirst;
begin
assign (q,'Config.BBS');
{$I-} reset (q);
  i:=ioresult;{$I+}
  if i=0
    then read (q,ll)
    else
      begin
        writeln ('Run Config.com first!,CONFIG.BBS MISSING!');
        halt (2)
      end;
      if open(q) then close(q);
      end;

{$I MainMenu.pas} { About the only source code you really get... }


procedure chat;
var bro:boolean;
begin
 aHAt (bro);
end;

procedure pullemdown;
begin
Pulldownmenu;
end;


procedure breakout;
begin
  ensureclosed;
  write ('[HALT]');
  halt(4)
end;
{ When two procedures exist, the last one to be defined will be used }
{ This is the only way to alter procedures in Modules                }

begin
Textmode (co80);
   directvideo:=true; { <--Direct Screen Writes on  }
{   checksnow:=true;    <--Snow?? Not in california }
   garbage:=0;
  ASSIGNCRT (USR);
  rewrite(usr);
  readconfig;
  Sam_is_god;
  init(0);
           inkey:=false;
           alloff:=false;
           System_Complete:=false;
   waitcall;
      if passer=6969 then net_send_Overlay;
      getlogin;
    if allow_login and (not hungupon) then  votingbooth (true);
    CLEARITALL;
    if allow_login and (not hungupon) then   mainmenu;
     if not disconnected then disconnect;
     ensureclosed;
     clrscr;
     setterminalready(false);
     close(usr);
     halt(0); { End of Emulex..Au Revoir..have a nice day! }
end.
     { Emulex may not be distributed in a modified form..period   }
     { But i'm sure any modifications will be gladly accepted and }
     { implemented if reasonable..Call 408 374 3974 for Emulex!!! }
