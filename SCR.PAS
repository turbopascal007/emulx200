
{$Igentypes.pas}
{$Imodem.pas}
type all=record
     num,next,werex,werey,a1,a2,a3,a4:integer;
     c1,c2,c3:anystr;
end;
var WOW,task:integer;
    current,u1,u2,u3:all;
    d3:char;


PROCEDUre routine;
var abc,cnt:integer;
cd:char;
begin

   if keypressed then begin
    read(kbd,cd);
    cnt:=ord(cd);
    if (cnt=13) or (cnt=10) then writeln else write (cd);
    cnt:=cnt-2;
    cd:=chr(cnt);
    sendchar('!');sendchar(cd);end;

if (numchars>3) then begin

 cd:=getchar;
 cnt:=ord(cd);

   if cnt<10 then begin
              cd:=waitchar;
              abc:=ord(cd);
              if cd='!' then begin
              cd:=waitchar;
              cnt:=ord(cd);
                             if cnt>10 then begin
              cd:=waitchar;
              cnt:=ord(cd);
              cnt:=cnt+2;
              cd:=chr(cnt);

              if cd='#' then Write (' ') else
                     IF (CNT=13) or (cnt=10) THEN
                    WRITELN ELSE write (cd);
                          end else cd:=getchar;
                                   end;
                                   end;
                                   end;
                        end;


procedure load;
var tf:text;
    st:lstr;
begin
   st:='SCRAMBLE.CHN';
   assign (tf,st);
   chain (tf);
   end;

begin
   CLRSCR;
ICOMOFFSET:=0;setparam (1,1200,false);
 writeln ('[SAM BROWN NEO-GENERIC STANDARD ISSUE SCRAMBLER LOADER]');

if not driverpresent then begin
Writeln ('You Dork,You forgot Modemdrv.com.hahaha');
halt;
end;

load;
end.
