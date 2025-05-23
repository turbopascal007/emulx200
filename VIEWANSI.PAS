{$R-,S-,I-,D-,F+,V-,B-,N-,L+,O+ }

unit viewansi;

interface

uses crt,dos,
     gentypes,configrt,modem,statret,gensubs,subs1,windows,subs2,textret,
     mailret,userret,flags,mainr1,ansiedit,lineedit,chatstuf,
     mainr2,overret1;

procedure viewansiscreens;

implementation

procedure viewansiscreens;
var bobway:integer;
    p:lstr;
    asciiiii:boolean;
begin
 if numwelcomes<1 then begin
  writeln;
  writeln (^S'There are no Ansi Screens currently available'^R);
  writeln;
  exit;
 end else
 repeat
  asciiiii:=false;
  p:='';
  ansicls;
  writehdr ('Ansi Screens ');
  writeln;
  writeln (^R'There are '^S,numwelcomes,^R' Ansi screens.'^M);
  if exist (textfiledir+'Welcome.ASC') then asciiiii:=true;
  if asciiiii then writeln ('Ansi Screens available: ['^S'1'^R']'^M);
  p:='Choose Screen [#1-'+strr(numwelcomes)+'],';
  if asciiiii then p:=p+'[A],';
  p:=p+'[Q]:';
  writestr (p);
  bobway:=valu(input);
  if upcase(input[1])='A' then begin
   printfile (textfiledir+'WELCOME.ASC');
   writestr ('Press [Return] to continue.*');
  end;
  if valu(input) in [1..numwelcomes] then begin
   if ansigraphics in urec.config then begin
    if bobway>numwelcomes then
    writeln (^M'There are only '+strr(numwelcomes)+' screens!') else
    printfile (textfiledir+'Welcome'+strr(bobway)+'.ans');
    ansigotoxy (1,urec.displaylen);
    writestr ('Press [Return] to continue.*');
   end;
  end;
 until hungupon or (upcase(input[1])='Q');
end;

begin
end.
        O}� cq 