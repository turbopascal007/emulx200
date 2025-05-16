
unit windows;

interface

uses gentypes,crt,subs1,configrt;

var winds:array [0..2] of windowrec;
    split,inuse:integer;

procedure getcoor;
procedure usewind (n:byte);
procedure setwind (n:byte; nx1,ny1,nx2,ny2:byte);
procedure initwind (n,nx1,ny1,nx2,ny2,ncolor:byte);
procedure top;
procedure bottom;
procedure wholescreen;
procedure drawsplit;
procedure initwinds;
procedure unsplit;
procedure splitscreen (v:byte);
procedure setoutlock (b:boolean);
procedure bottomline;

implementation

procedure getcoor;
begin
  with winds[inuse] do begin
    cx:=wherex;
    cy:=wherey;
    if cy<1 then cy:=1;
    if cy>(y2-y1)+1 then cy:=(y2-y1)+1
  end
end;

procedure usewind (n:byte);
begin
  getcoor;
  inuse:=n;
  with winds[n] do begin
    window (x1,y1,x2,y2);
    gotoxy (cx,cy);
    textcolor (color);
    textbackground (0);
    lasty:=y2-y1+1
  end
end;

procedure setwind (n:byte; nx1,ny1,nx2,ny2:byte);
var i:integer;
begin
  i:=inuse;
  usewind(n);
  with winds[n] do begin
    x1:=nx1;
    y1:=ny1;
    x2:=nx2;
    y2:=ny2
  end;
  usewind(n);
  if n<>i then usewind(i)
end;

procedure initwind (n,nx1,ny1,nx2,ny2,ncolor:byte);
begin
  with winds[n] do begin
    x1:=nx1;
    y1:=ny1;
    x2:=nx2;
    y2:=ny2;
    cx:=1;
    cy:=1;
    color:=ncolor
  end
end;

procedure top;
begin
  usewind (1)
end;

procedure bottom;
begin
  usewind (2)
end;

procedure wholescreen;
begin
  usewind (0)
end;

procedure drawsplit;
var cnt:integer;
begin
  usewind (0);
  textcolor (splitcolor);
  gotoxy (1,split);
  for cnt:=0 to 79 do write (usr,chr(196));
  bottom
end;

procedure initwinds;
begin
  splitmode:=false;
  initwind (0,1,1,80,25,splitcolor);
  initwind (2,1,1,80,23,normbotcolor);
  split:=0;
  inuse:=0;
  bottom
end;

procedure unsplit;
var y:integer;
begin
  if not splitmode then exit;
  if inuse=2
    then y:=wherey
    else y:=winds[2].cy;
  y:=y+split;
  setwind (2,1,1,80,23);
  setwind (1,1,1,80,split);
  top;
  clrscr;
  splitmode:=false;
  bottom;
  gotoxy (wherex,y)
end;

procedure splitscreen (v:byte);
var x,y:integer;
begin
  if splitmode then unsplit;
  x:=wherex;
  y:=wherey-v;
  splitmode:=true;
  split:=v;
  drawsplit;
  initwind (1,1,1,80,split-1,normtopcolor);
  setwind (2,1,split+1,80,23);
  top;
  clrscr;
  bottom;
  gotoxy (x,y)
end;

procedure setoutlock (b:boolean);
begin
  modemoutlock:=b;
  if b
    then winds[2].color:=outlockcolor
    else winds[2].color:=normbotcolor;
  if inuse=2 then usewind (2)
end;

procedure bottomline;
var o:integer;

  procedure flash (q:mstr);
  begin
    textcolor (16);
    write (usr,q);
    textcolor (0)
  end;

var baud:string;
begin
  if inuse=0 then exit;
  o:=inuse;
  wholescreen;
  gotoxy (1,24);
  textcolor (0);
  textbackground (statlinecolor);
  if timelock then settimeleft (lockedtime);
  write (usr,unam,'Level:',ulvl,' ',timeleft,' left');
  if chatmode
    then flash (' CHAT!')
    else write (usr,' ',sysopavailstr);
  if timelock then flash (' Timelock');
  if modeminlock then flash (' InLock');
  if modemoutlock then flash (' OutLock');
  if tempsysop then flash (' *Sysop*');
  if texttrap then flash (' Trap');
  if printerecho then flash (' Print');
  if sysnext then write (usr,' Sysop next');
  clreol;
  gotoxy (1,25);
  textcolor(0);
  textbackground (statlinecolor);
  if timelock then settimeleft (lockedtime);
  str (baudrate,baud);
  if local then baud:='Local' else baud:=baud+' bps';
  write (usr,baud,' Xfer Level:',urec.udlevel,' GFile Level:',urec.gflevel,' Ph#',urec.phonenum);
  clreol;
  usewind (o);
end;

begin
end.

