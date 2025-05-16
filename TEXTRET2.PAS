{$R-,S-,I-,D-,F+,V-,B-,N-,L+ }
{$M 65500,0,0 }

unit textret;

interface

uses crt,gentypes,configrt,gensubs,subs1,statret,modem;

procedure reloadtext (sector:integer; var q:message);
procedure deletetext (sector:integer);
function maketext (var q:message):integer;
function copytext (sector:integer):integer;
procedure printtext (sector:integer);

implementation

procedure reloadtext (sector:integer; var q:message);
var k:char;
    sectorptr,tmp,n:integer;
    buff:buffer;
    x:boolean;

  procedure setbam (sector,val:integer);
  begin
    seek (mapfile,sector);
    write (mapfile,val)
  end;

  procedure chk;
  begin
    iocode:=ioresult;
    if iocode<>0 then writeln (usr,'(Error ',iocode,' reading message)')
  end;

begin
  sectorptr:=32767;
  n:=1;
  q.text[1]:='';
  repeat
    if sectorptr>sectorsize then begin
      if sector<0 then exit;
      seek (tfile,sector); chk;
      read (tfile,buff); chk;
      seek (mapfile,sector); chk;
      read (mapfile,tmp); chk;
      if tmp=-2 then begin
        tmp:=-1;
        seek (mapfile,sector); chk;
        write (mapfile,tmp); chk;
      end;
      sector:=tmp;
      sectorptr:=1
    end;
    k:=buff[sectorptr];
    case k of
      #0,#10:;
      #13:if n>=maxmessagesize
            then k:=#0
            else begin
              n:=n+1;
              q.text[n]:=''
            end
      else q.text[n]:=q.text[n]+k
    end;
    sectorptr:=sectorptr+1
  until k=#0;
  q.numlines:=n;
  chk
end;

procedure deletetext (sector:integer);
var next:integer;

  procedure setbam (sector,val:integer);
  begin
    seek (mapfile,sector);
    write (mapfile,val)
  end;

begin
  while sector>=0 do begin
    seek (mapfile,sector);
    read (mapfile,next);
    setbam (sector,-2);
    sector:=next
  end
end;

function maketext (var q:message):integer;
var line,pos,sector,prev:integer;
    bufptr:integer;
    curline:anystr;
    k:char;
    buff:buffer;

  procedure setbam (sector,val:integer);
  begin
    seek (mapfile,sector);
    write (mapfile,val)
  end;

  function nextblank (first:integer; linkit:boolean):integer;
  var cnt,i,blank:integer;
  begin
    nextblank:=-1;
    if first<-1 then first:=-1;
    if first>=numsectors then exit;
    seek (mapfile,first+1);
    for cnt:=first+1 to numsectors do begin
      read (mapfile,i);
      if i=-2 then begin
        blank:=cnt;
        if (first>=0) and linkit then setbam (first,blank);
        nextblank:=blank;
        exit
      end
    end
  end;

  function firstblank:integer;
  begin
    firstblank:=nextblank (-1,false)
  end;

  procedure ensuretfilesize (sector:integer);
  var cnt:integer;
      buff:buffer;
  begin
    if sector<filesize(tfile) then exit;
    if (sector<0) or (sector>numsectors) then exit;
    fillchar (buff,sizeof(buff),'*');
    seek (tfile,filesize(tfile));
    for cnt:=filesize(tfile) to sector do write (tfile,buff);
    fillchar (buff,sizeof(buff),'!')
  end;

  procedure writesector (sector:integer; var q:buffer);
  var n:integer;
  begin
    if (sector<0) or (sector>numsectors) then exit;
    seek (mapfile,sector);
    read (mapfile,n);
    if n<>-2 then begin
      error ('Overwrite error sector=%1!','',strr(sector));
      exit
    end;
    ensuretfilesize (sector);
    seek (tfile,sector);
    write (tfile,q)
  end;

  procedure flushbuf;
  begin
    writesector (sector,buff);
    prev:=sector;
    sector:=nextblank(prev,true);
    bufptr:=1;
  end;

  procedure outofroom;
  begin
    writeln (^B'Sorry, out of room!');
    maketext:=-1
  end;

begin
  if q.numlines=0 then begin
    writeln (^B'Message blank!');
    maketext:=-1;
    exit
  end;
  if firstfree>=0 then begin
    sector:=firstfree;
    seek (mapfile,sector);
    read (mapfile,prev)
  end else prev:=-1;
  if prev<>-2 then begin
    firstfree:=firstblank;
    sector:=firstfree
  end;
  maketext:=sector;
  if sector=-1 then begin
    outofroom;
    exit
  end;
  bufptr:=1;
  for line:=1 to q.numlines do begin
    curline:=q.text[line]+^M;
    if line=q.numlines then curline:=curline+chr(0);
    for pos:=1 to length(curline) do begin
      k:=curline[pos];
      buff[bufptr]:=k;
      bufptr:=bufptr+1;
      if bufptr>sectorsize then begin
        flushbuf;
        if sector=-1 then begin
          outofroom;
          exit
        end
      end
    end
  end;
  if bufptr>1 then flushbuf;
  setbam (prev,-1);
  firstfree:=nextblank(firstfree,false);
  if firstfree=-1 then firstfree:=firstblank
end;

function copytext (sector:integer):integer;
var me:message;
begin
  reloadtext (sector,me);
  copytext:=maketext (me)
end;

function charhit:boolean;
var k:char;
begin
  if modeminlock then while numchars>0 do k:=getchar;
  if hungupon or keyhit
    then charhit:=true
    else if online
      then charhit:=(not modeminlock) and (numchars>0)
      else charhit:=false
end;

procedure printtext (sector:integer);
var q:message;
    x,bub:boolean;
    n,m,t,w,b,y,mm,i:integer;
    p:byte;
    cs,css,a,s,c:string;
    kay,thegog:char;
    validcolors:array [0..16] of integer;
    validcommands:array [0..26] of integer;
begin
  reloadtext (sector,q);
  writeln (^B);
  n:=1;
  repeat
   mm:=0;
   repeat
    if length(q.text[n])>0 then begin
    p:=0;
    mm:=mm+1;
    s:=copy(q.text[n],mm,1);
    if s='|' then p:=mm
     else p:=0;
    if p>0 then begin
     cs:=copy(q.text[n],p+1,1);
     css:=copy(q.text[n],p+2,1);
     a:=cs+css;
     validcommands:=
      ('00','01','02','03','04','05','06','07','08','09','10','11','12','13','14',
      '15','K','k','N','n','C','c','T','t','D','d');
  {} begin {}
      if
      (a='00') or (a='01') or (a='02') or (a='03') or (a='04') or (a='05') or
      (a='06') or (a='07') or (a='08') or (a='09') or (a='10') or (a='11') or
      (a='12') or (a='13') or (a='14') or (a='15') then
     begin
      b:=valu(a);
      delete (q.text[n],p+1,1);
      delete (q.text[n],p+1,1);
      c:=strr(b);
      if (c='01') or (c='02') or (c='03') or (c='04') or (c='05') or
         (c='06') or (c='07') or (c='08') or (c='09') then
      begin
       delete (c,1,1);
       b:=valu(c);
      end;
      if b=0 then begin
       ansicolor (0);
      end;
      ansicolor (b);
     end;
     if (cs='K') or (cs='k') then
     begin
      delete (q.text[n],p+1,1);
      write ('*');
      thegog:=bioskey;
     end;
     if (cs='N') or (cs='n') then
     begin
      delete (q.text[n],p+1,1);
      write (urec.handle);
     end;
{
     if (cs='T') or (cs='t') then
     begin
     delete (q.text[n],p+1,1);
      write (timestr(now));
     end;
     if (cs='D') or (cs='d') then
     begin
      delete (q.text[n],p+1,1);
      write (datestr(now));
     end;
}
     if (cs='C') or (cs='c') then
     begin
      delete (q.text[n],p+1,1);
      if (ansigraphics in urec.config) then write (#27+'[2J') else
       write (^L);
     end;
    end else write (s);
    end
   else write (s);
  end;
  until mm=length(q.text[n]);
   writeln;
   n:=n+1;
  until break or (n>q.numlines) or hungupon;
  x:=xpressed; bub:=break;
  writeln (^B^M);
  xpressed:=x; break:=bub;
  ansicolor (urec.regularcolor)
end;

begin
end.
