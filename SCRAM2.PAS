uses dos,crt,gentypes,modem;
var shift:integer;

type all=record
     num,next,werex,werey,a1,a2,a3,a4:integer;
     c1,c2,c3:anystr;
end;
var SCRAM,WOW,task:integer;
    current,u1,u2,u3:all;
    d3:char;
   Xtron,wammy,sAMMY:BOOLEAN;
procedure swit2;
begin
if wammy=true then wammy:=false else wammy:=true;
end;

procedure switchit;
var xx,yy:integer;

begin
xx:=wherex;yy:=wherey;
window (1,1,80,24);
if sammy then begin
sammy:=false;gotoxy (1,24); write ('Scramble OFF! Keyed to #',scram );
end else begin
sammy:=true;
gotoxy (1,24); write ('Scramble On! Keyed to #',scram );
end;
if xtron then write (' Xtron Scrambling on!') else write ('                       ');
window (1,1,80,23);
gotoxy (xx,yy);
end;


PROCEDUre routine;
var abc,cnt:integer;
ed,cd:char;
begin

   if keypressed then begin
    cd:=readkey;
    ed:=cd;
    cnt:=ord(cd);
 IF (cnt=27) and keypressed  then begin
 cd:=readkey; if cd=';' then  switchit;
   if cd='<' then  swit2;
   if cd='=' then scram:=scram+1;
   if cd='>' then scram:=scram-1;
   if cd='C' then Xtron:=true else xtron:=false;
IF CD='D' THEN HALT;
switchit;switchit;
   cd:=chr(8);
    end;

if cnt=27 then EXIT;
  {    cnt:=ord(cd);}
    IF (CNT>32) AND SAMMY THEN if xtron then cnt:=(cnt xor 255)+(scram-100) else cnt:=cnt+scram;
    if (cnt<0) or (cnt>255) then cnt:=0;
    cd:=chr(cnt);
  sendchar(cd);end;

   if (numchars>0) AND NOT KEYPRESSED then begin
     begin
    cd:=getchar;
  if cd=#2 then begin
  xtron:=false;end;
  if cd=#4 then
  begin
  xtron:=true;end;
   cnt:=ord(cd);
   if (cnt>(scram-1)) then begin
    if xtron then cnt:=(cnt xor 255)+(scram-100) else cnt:=cnt-scram;
   if xtron then Textcolor (lightBlue) else  textcolor(LightRed);
    end else textcolor (White);
   if (cnt>0) or (cnt<256) then cd:=chr(cnt) else cd:=' ';
 IF CNT=10 THEN WRITELN ELSE
 write (cd);
                   end;
    end;
    end;

VAR YO:STRING[3];
begin
   CLRSCR;{-256 com2}  {2 for com2}
if paramcount>0 then yo:=PARAMSTR(1) else yo:='1';

if yo='2' then icomoffset:=-256 else
ICOMOFFSET:=-256;
if yo='2' then setparam (2,1200,false) else setparam (1,1200,false);
comparams(1,1200,7,'E',1);
scram:=126;shift:=0;
textcolor (LightBlue);
textcolor (White);
window (1,1,80,23);
gotoxy (1,3);
SAMMY:=FALSE;
wammy:=false;

repeat

routine;
routine;
UNTIL 0=1;

end.
