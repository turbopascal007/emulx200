program config;
{$A-}
{$R-,S+,I-,D+,F-,V-,B-,N-,L+ }
{$M 26384,5000,15000 }

uses dos,crt,

     general,
     gentypes,configrt,xcrt;

const normalcolor=White;
      boldcolor=Yellow;
      barcolor=$1f;
      inputcolor=11;
      choicecolor=15;
      datacolor=15;

      var     buflen:byte;

procedure noise;
var c,cnt:integer;
begin
while not keypressed do
for cnt:=1 to 12000 do sound(cnt);

nosound;
end;

function bioslook:char;    (* Returns 255 if not keypressed *)
var r:registers;
begin
  if keypressed then begin
    r.ah:=1;
    intr ($16,r);
    if r.al=0
      then bioslook:=chr(r.ah+128)
      else bioslook:=chr(r.al)
  end else bioslook:=#255
end;

function bioswait:char;    (* Waits for a key but doesn't take it out *)
var k:char;
begin
  repeat
    k:=bioslook
  until ord(k)<>255;
  bioswait:=k
end;

function bioskey:char;
var r:registers;
begin
  r.ah:=0;
  intr ($16,r);
  if r.al=0
    then bioskey:=chr(r.ah+128)
    else bioskey:=chr(r.al)
end;

procedure writeconfig;
var q:file of configsettype;
begin
  assign (q,'Emulex.bbs');
  rewrite (q);
  write (q,configset);
  close (q)
end;

procedure cleareol;
var aa,bb:byte;
begin
 aa:=wherex;
 bb:=wherey;
 clreol;gotoxy(79,wherey);write('บ');
 gotoxy(aa,bb);
end;

procedure formatconfig;
var cnt:integer;
begin
  fillchar (configset,5272,0);

  versioncode:=thisversioncode;
  longname:='Byte Bandits BBS';
  shortname:='Byte Bandits';
  sysopname:='Sam Brown';
  getdir (0,forumdir);
  if forumdir[length(forumdir)]<>'\' then forumdir:=forumdir+'\';
  textdir:=forumdir+'MSGS\';
  uploaddir:=forumdir+'GFILES\';
  boarddir:=forumdir+'BOARD\';
  asciidownload:='Emulex/2: Keeping the Dream Alive!';
  textfiledir:=forumdir+'MENUS\';
  doordir:=forumdir;
  modemsetupstr:='ATM0V0X4S0=1|';
  modemhangupstr:='+++~~~ATH|';
  modemdialprefix:='ATDT';
  modemdialsuffix:='|';
  defbaudrate:=2400;
  usecom:=1;
  hashayes:=false;
  anonymouslevel:=40;
  numwelcomes:=1;
  mintimeout:=5;
  sysoplevel:=100;
  defudlevel:=0;
  defudpoints:=0;
  normbotcolor:=3;
  normtopcolor:=9;
  outlockcolor:=11;
  splitcolor:=10;
  statlinecolor:=3;
  uploadfactor:=3;
  private:=false;
  autologin:=false;
  useconmode:=true;
  escinmsgs:=false;
  bkspinmsgs:=true;
  requireforms:=true;
  dotchar:='/';
  supportedrates:=[b1200]+[b2400];
  downloadrates:=supportedrates;
  availtime:='4:00 pm';
  unavailtime:='9:00 pm';
  xmodemopentime:='3:00 am';
  xmodemclosetime:='3:00 am';
  for cnt:=1 to 100 do usertime[cnt]:=cnt*2;
  level2nd:=10;
  udlevel2nd:=10;
  udpoints2nd:=0;
  postlevel:=10;
  anonymousstr:='Anonymous';
  usematrix:=true;
  matrixtype:=1;
  newusermatrix:=true;
  systempassword:='PRIVATE';
  remotedoors:=false;
  allowdoors:=false;
  eventtime[0]:=#0;
  eventbatch[0]:=#0;
  directvideomode:=true;
  checksnowmode:=true;
  hangnewusers:=true;
  msgnextlvl:=10;
  appear:='Sam Brown is here.';
  disappear:='Sam Brown has left';
  telenumber:='408 253 7992';
  allowloan:=false;
  lvltoloan:=40;
  maxloan:=5;
  maxdebt:=-5;
  timerestlvl:=60;
  timereststart[0]:=#0;
  timerestend[0]:=#0;
  dszlog:='C:\DSZ.LOG';
  sklog:='C:\SUPERK.LOG';
  newusernote:='New User';
  system2password[0]:=#0;
  system3password[0]:=#0;
  useqr:=true;
  qrlimit:=-25;
  qrmultifactor:=5;
  qrexempt:=60;
  usecliche:=true;
  cliche:='Swashbucklers "Keeping the Dream Alive"';
  ulpercent:=50;
  checkautologin:=true;
  usetrivia:=true;
  readanonlvl:=50;
  listuserlvl:=40;
  ems:=false;
  datascrambling:=false;
  pcrexempt:=60;
  xferpcr:=20;
  gfpcr:=20;
  doorpcr:=15;
  mnplevel:=0;
  matrixfback:=true;
  matrixreqchat:=true;
  leechzmodem:=true;
  commandcom:='C:\DOS\COMMAND.COM';
  {edito:='C:\Q.EXE';}
  userumor:=true;
  filepw:=true;
  writeconfig;
end;

type ttypetype=(TInteger,Tsstr,Tmstr,Tlstr,TBoolean,TChar,TBaudset,
                TPath,TTime,TAttrib,Tusertime,Badtype);
     ptrset=record
       case integer of
         0:(i:^integer);
         1:(l:^lstr);
         2:(b:^boolean);
         3:(k:^char);
         4:(baudsetptr:^baudset)
     end;
     thing=record
       text:mstr;
       descrip:lstr;
       ttype:ttypetype;
       p:pointer;
       r1,r2:integer
     end;

const ttypestr:array [ttypetype] of sstr=
  ('Int','sstr','mstr','lstr','Boo','Char','Baud','Path','Time',
   'Attrib','Usertime','!!!!????');
      colorstr:array [0..15] of mstr=
  ('Black','Blue ','Green ','Cyan ','Red ','Magenta ','Brown ','White ',
   'Gray ','BLUE!','GREEN!','CYAN!','RED!','MAGENTA!','YELLOW!','WHITE!');

const maxthings=200;
      dcol=30;

var top,bot,page,numpages,numthings:integer;
    things:array [1..maxthings] of thing;

procedure cb;
begin
textbackground(black);

  textcolor (boldcolor)
end;

procedure c4;
begin
textbackground(black);

  textcolor (4)
end;

procedure cn;
begin
textbackground(black);

  textcolor (normalcolor)
end;

procedure c7;
begin
textbackground(black);

  textcolor (7)
end;

procedure cs;
begin
textbackground(black);

 textcolor (boldcolor);
end;

procedure cd;
begin
textbackground(black);

 textcolor (normalcolor);

end;
procedure invert;
begin
textbackground(normalcolor);
textcolor(black);
end;

function match(a1,a2:anystr):boolean;
var cnt:integer;
begin
  match:=false;
  while a1[length(a1)]=' ' do a1[0]:=pred(a1[0]);
  while a2[length(a2)]=' ' do a2[0]:=pred(a2[0]);
  if length(a1)<>length(a2) then exit;
  for cnt:=1 to length(a1) do
    if upcase(a1[cnt])<>upcase(a2[cnt]) then exit;
  match:=true
end;

function yesnostr (var b:boolean):sstr;
begin
  if b and (ord(b)<>ord(true)) then b:=true;
  if b then yesnostr:='Yes' else yesnostr:='No'
end;

function strr (n:integer):mstr;
var q:mstr;
begin
  str (n,q);
  strr:=q
end;

function valu (q:mstr):integer;
var i,s:integer;
begin
  val (q,i,s);
  if s=1
    then valu:=0
    else valu:=i
end;

function whichpage (n:integer):integer;
begin
  whichpage:=((n-1) div 20)+1
end;

function whichline (n:integer):integer;
begin
  whichline:=n-20*(whichpage(n)-1)+2
end;

function getbaudstr (var q:baudset):lstr;
var w:lstr;
    cnt:baudratetype;
begin
  w[0]:=chr(0);
  for cnt:=firstbaud to lastbaud do
    if cnt in q then w:=w+strr(baudarray[cnt])+' ';
  if length(w)=0 then w:='None';
  getbaudstr:=w
end;

function varstr (n:integer):string;
var pu:pointer;
    p:ptrset absolute pu;
begin
  pu:=things[n].p;
  case things[n].ttype of
    tinteger:varstr:=strr(p.i^);
    tlstr,tmstr,tsstr,tpath,ttime:varstr:=p.l^;
    tboolean:varstr:=yesnostr(p.b^);
    tchar:varstr:=p.k^;
    tbaudset:varstr:=getbaudstr (p.baudsetptr^);
    tattrib:varstr:=colorstr[p.i^];
    tusertime:varstr:='(Choose this choice to configure user daily time)';
    else varstr:='??!?!?!'
  end
end;

procedure writevar (n:integer);
begin
  cb;
  write (varstr(n));
  cn; cleareol;
  writeln
end;

procedure Box;
begin
clrscr;
cn;
writeln('ษออออออออออออออออออออออออออป                                 ษออออออออออออออออป');
writeln('ฬออออออออออออออออออออออออออสอออออออออออออออออออออออออออออออออสออออออออออออออออน');
writeln('บ                                                                             บ');
writeln('บ                                                                             บ');
writeln('บ                                                                             บ');
writeln('บ                                                                             บ');
writeln('บ                                                                             บ');
writeln('บ                                                                             บ');
writeln('บ                                                                             บ');
writeln('บ                                                                             บ');
writeln('บ                                                                             บ');
writeln('บ                                                                             บ');
writeln('บ                                                                             บ');
writeln('บ                                                                             บ');
writeln('บ                                                                             บ');
writeln('บ                                                                             บ');
writeln('บ                                                                             บ');
writeln('บ                                                                             บ');
writeln('บ                                                                             บ');
writeln('บ                                                                             บ');
writeln('บ                                                                             บ');
writeln('บอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออบ');
writeln('ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ');
end;

procedure gotopage (p:integer);
var cnt,cy:integer;
begin
  if p<1 then p:=1;
  if p>numpages then p:=numpages;
  if p<>page then begin
{    if page<>0 then freeprompts (prompt);}
    page:=p;
    window(1,1,80,25);
    clrscr;box;
    gotoxy (31,1);
    cn; write ('Emulex/2');
    cn; write (' Config: ');
    cn; write ('Page ');
    cb; write (page);
    cn; write (' of ');
    cb; write (numpages);
    cn; writeln (':  ');
    writeln;
    top:=(page-1)*20+1;
    bot:=top+19;
    if bot>numthings then bot:=numthings;
    { beginprompts (prompt);}
    for cnt:=top to top+19 do begin
      cy:=cnt-top+3;
      gotoxy (2,cy);
      cn; cleareol;gotoxy (79,wherey);write('บ');
       gotoxy (2,cy);

      if cnt<=bot then begin
        gotoxy (5,cy);

        Write (things[cnt].text,':');
        gotoxy (dcol,wherey);cs;
        writevar (cnt)
      end
    end
  end
end;

procedure readdata;
var q:text;
    t:mstr;

  procedure dataerror (n:lstr);
  begin
    writeln ('Record ',numthings,': '+n);
    halt
  end;

  procedure illtype;
  begin
    dataerror ('Invalid type: '+t)
  end;

  procedure getrange (t:mstr; var r1,r2:integer);
  var sp,da,n1,n2:integer;
  begin
    sp:=pos(' ',t);
    r1:=-32767;
    r2:=32767;
    if sp=0 then exit;
    t:=copy(t,sp+1,255);
    if length(t)<1 then exit;
    da:=pos('-',t);
    if (da=1) and (length(t)=1) then exit;
    if da=0 then begin
      r1:=valu(t);
      r2:=r1;
      exit
    end;
    n1:=valu(copy(t,1,da-1));
    n2:=valu(copy(t,da+1,255));
    if da=1 then begin
      r2:=n2;
      exit
    end;
    r1:=n1;
    if da=length(t) then exit;
    r2:=n2
  end;

  procedure gettype (t:mstr; var tt:ttypetype);
  var sp:integer;
      fw:mstr;
  begin
    tt:=ttypetype(0);
    sp:=pos(' ',t);
    if sp=0
      then fw:=t
      else fw:=copy(t,1,sp-1);
    while tt<>badtype do
      begin
        if match(fw,ttypestr[tt]) then exit;
        tt:=succ(tt)
      end;
    tt:=badtype;
    illtype
  end;

begin
  assign (q,'Config.Dat');
  reset (q);
  numthings:=0;
  if ioresult<>0 then dataerror ('File CONFIG.DAT not found!');
  while not eof(q) do begin
    numthings:=numthings+1;
    with things[numthings] do begin
      readln (q,text);
      readln (q,descrip);
      readln (q,t);
      gettype (t,ttype);
      if ttype=tinteger then getrange (t,r1,r2)
    end
  end;
  close (q)
end;

procedure assignptrs;
var cnt:integer;

  procedure s (var q);
  begin
    cnt:=cnt+1;
    things[cnt].p:=@q
  end;

begin
  cnt:=0;
  s (longname);
  s (shortname);
  s (sysopname);
  s (autologin);
  s (forumdir);
  s (textdir);
  s (boarddir);
  s (uploaddir);
  s (textfiledir);
  s (doordir);
   S(bimodemdir  );
 s(netfiledir    );

  s (supportedrates);
  s (downloadrates);
  s (defbaudrate);
  s (usecom);
  s (hashayes);
  s (modemsetupstr);
  s (modemhangupstr);
  s (sysoplevel);
  s (anonymouslevel);
  s (numwelcomes);
  s (private);
  s (normbotcolor);
  s (normtopcolor);
  s (outlockcolor);
  s (splitcolor);
  s (statlinecolor);
  s (usertime);
  s (dotchar);
  s (asciidownload);
  s (defudlevel);
  s (defudpoints);
  s (level2nd);
  s (udlevel2nd);
  s (udpoints2nd);
  s (postlevel);
  s (uploadfactor);
  s (availtime);
  s (unavailtime);
  s (xmodemopentime);
  s (xmodemclosetime);
  s (systempassword);
  s (anonymousstr);
  s (requireforms);
  s (remotedoors);
  s (allowdoors);
  s (eventtime);
  s (pcrexempt);

 s(tonextuserlevel);
 S(minimumleveltolistusers);
 S(security);
 S(timeexempt);
 S(timestart       );
 S(timestop          );

 S(pcr);
 S(gfratio);
 S(ratlevel );
  S(xferpcrlist     );
 S(gfilepcrlist      );

 S(extender  );
 S(dream       );
 S(discon        );

 S(pcpaccount          );

 S(pcpnode);
 S(OffHookLine);
 S(timepercentback     );
 S(leveltouseemumail     );
 S(returning               );
 s(Level_To_use_rumors);
 s(Level_to_use_bbslist);
 s(Level_to_use_Listusers);
 S(level_to_use_gambling);
 S(level_To_use_leechlist);
 S(level_to_use_timebank);
 s(Level_to_use_trivia);
 s(Matrixfeedback);
 s(rts_handle);
 s(cts_handle);

end;

procedure byebye;
begin
clrscr;
  gotoxy (1,24);
  cb; writeln ('Config/2 version 1.00 Copyright 1989 by Sam Brown.');
  halt
end;

procedure abortyn;
var q:sstr;
begin
  gotoxy (1,24);cd;
  textcolor (datacolor);
  write ('Abort Without saving [y/n]: ');
  cn;
  cleareol;
  buflen:=1;
  q:=readkey;
  if length(q)>0 then if upcase(q[1])='Y' then byebye
end;

procedure getinput (n:integer; editit:boolean);
var y:integer;
    inp:lstr;
    t:thing;
    pu:pointer;
    p:ptrset absolute pu;

  procedure reshow;
  begin
    gotoxy (dcol,y);
    writevar (n)
  end;

  procedure showintrange;
  begin      c7;
    textcolor (datacolor); {c7}
    with t do
      if r1=-32767
        then if r2=32767
          then write ('No range limitation.')
          else write ('Maximum value: ',r2)
        else if r2=32767
          then write ('Minimum value: ',r1)
          else write ('Valid values range from ',r1,' to ',r2);
    cn
  end;

  procedure doint;
  var n,s:integer;
      k:char;
  begin
    val (inp,n,s);
    gotoxy (1,24);
    if s<>0
      then
        begin      cd;
          textcolor (datacolor);
          writeln ('Invalid number!  A number must be from -32767 to 32767.');
          cn;
          write ('Press any key...');
          cleareol;
          k:=bioskey
        end
      else if (n>=t.r1) and (n<=t.r2)
        then p.i^:=n
        else
          begin      cd;
            textcolor (datacolor);
            writeln ('Range error! Entry Must be within the limits!  ');
            cn;
            write ('Press any key...');
            cleareol;
            k:=bioskey
          end
  end;

  procedure dostr;
  begin
    if (inp='N') or (inp='n') then inp:='';
    p.l^:=inp
  end;

  procedure doboolean;
  begin
    case upcase(inp[1]) of
      'Y':p.b^:=true;
      'N':p.b^:=false
    end
  end;

  procedure dochar;
  begin
    p.k^:=inp[1]
  end;

  procedure dopath;
  var lc:char;
      cur:lstr;
      n:integer;
  begin
    lc:=inp[length(inp)];
    if (length(inp)<>1) or (upcase(lc)<>'N')
      then if (lc<>':') and (lc<>'\') then inp:=inp+'\';
    dostr;
    if inp[length(inp)]='\' then inp[0]:=pred(inp[0]);
    getdir (0,cur);
    chdir (inp);
    n:=ioresult;
    chdir (cur);
    if n=0 then exit;cd;
    textcolor (datacolor);
    gotoxy (1,24);
    write ('Path doesn''t exist!  ');
    cn; write ('Create it now? '); cleareol;
    readln (cur);
    if length(cur)=0 then exit;
    if upcase(cur[1])<>'Y' then exit;
    mkdir (inp);
    if ioresult=0 then exit;
    gotoxy (1,24);cd;
    textcolor (datacolor);
    write ('Error creating directory!  ');
    cn; write ('Press any key...');
    cleareol;
    lc:=bioskey
  end;

  procedure dotime;
  var c,s,l:integer;
      d1,d2,d3,d4:char;
      ap,m:char;

    function digit (k:char):boolean;
    begin
      digit:=ord(k) in [48..57]
    end;

  begin
    l:=length(inp);
    if l=1 then begin
      if upcase(inp[1])='N' then dostr;
      exit
    end;
    if (l<7) or (l>8) then exit;
    c:=pos(':',inp);
    if c<>l-5 then exit;
    s:=pos(' ',inp);
    if s<>l-2 then exit;
    d2:=inp[c-1];
    if l=7
      then d1:='0'
      else d1:=inp[1];
    d3:=inp[c+1];
    d4:=inp[c+2];
    ap:=upcase(inp[s+1]);
    m:=upcase(inp[s+2]);
    if d1='1' then if d2>'2' then d2:='!';
    if (d1>='0') and (d1<='1') and digit(d2) and (d3>='0') and (d3<='5')
       and digit(d4) and ((ap='A') or (ap='P')) and (m='M') then dostr
  end;

  procedure dobaud;
  var inp:lstr;
      n:integer;
      cnt:baudratetype;
  label bfound,again;
  begin
    gotoxy (1,24);
    repeat
      gotoxy (wherex,24);
      write ('Baud Rate to toggle [CR/Quit]: ');
      cleareol;
      buflen:=4;
      readln (inp);
      gotoxy (1,24);
      if length(inp)=0 then exit;
      n:=valu(inp);
      for cnt:=b110 to b19200 do if n=baudarray[cnt] then goto bfound;
      cb; write ('Not supported!  '); cn;
      goto again;
      bfound:
      if cnt in p.baudsetptr^
        then p.baudsetptr^:=p.baudsetptr^-[cnt]
        else p.baudsetptr^:=p.baudsetptr^+[cnt];
      reshow;
      again:
    until 0=1
  end;

  procedure dousertime;
  var input:lstr;
      n:integer;
      buffer:array [1..4096] of byte;
{      b:block;}

    procedure refresh;
    var cnt:integer;
    begin
    clrscr;
{      clearwindow (normalcolor);}
      gotoxy (1,1);
      cn;
      writeln('Level Time ณ Level Time ณ Level Time ณ Level Time ณ Level Time');
      writeln('ฤฤฤฤฤฤฤฤฤฤฤมฤฤฤฤฤฤฤฤฤฤฤฤมฤฤฤฤฤฤฤฤฤฤฤฤมฤฤฤฤฤฤฤฤฤฤฤฤมฤฤฤฤฤฤฤฤฤฤฤ');
      gotoxy (1,3);
      for cnt:=1 to 100 do begin
        write (cnt:4,': ',usertime[cnt]:4);
        if (cnt mod 5)=0 then writeln else write (' ณ ')
      end
    end;

    procedure setone (n,v:integer);
    var x,y:integer;
    begin
      x:=((n-1) mod 5)*13+7;
      y:=((n-1) div 5)+3;
      gotoxy (x,y);
      write (v:4);
      usertime[n]:=v
    end;

    procedure getone (n:integer);
    var x,y,v:integer;
    begin
      x:=((n-1) mod 5)*13+7;
      y:=((n-1) div 5)+3;
      gotoxy (x,y);
      write ('    ');
      gotoxy (x,y);
      buflen:=4;
      readln (input);
{     editstring(input,4,wherex,wherey,black,white,'####');}
      v:=valu(input);
      if (v<1) or (v>1000) then v:=usertime[n];
      setone (n,v)
    end;

    function getn (txt:lstr):integer;
    var input:lstr;
    begin
      gotoxy (1,23);
      write (txt,': ');
      cleareol;
      buflen:=4;
      readln (input);
{      Editstring (input,4,wherex,wherey,black,White,'####');}
      getn:=valu(input)
    end;

    function getlvl (txt:lstr):integer;
    var n:integer;
    begin
      n:=getn (txt);
      if (n<1) or (n>100) then n:=0;
      getlvl:=n
    end;

    procedure pattern;
    var st,en,ba,se,cn:integer;
    begin
      st:=getlvl ('Starting level of pattern');
      if st=0 then exit;
      en:=getlvl ('Ending level of pattern');
      if en<st then exit;
      ba:=getn ('Time for level '+strr(st));
      if (ba<1) or (ba>1000) then exit;
      se:=getn ('Additional time per level');
      if (se<0) or (se>1000) then exit;
      cn:=st;
      repeat
        setone (cn,ba);
        if ba+se<1000
          then ba:=ba+se
          else ba:=1000;
        cn:=cn+1
      until cn>en
    end;

  var k:char;
  begin
    refresh;
    repeat
      repeat
        gotoxy (1,24);
        write ('Number to change, [P]attern, or [Q]uit: ');
        cleareol;
        readln (input)
      until length(input)>0;
      k:=upcase(input[1]);
      n:=valu(input);
      if (n>=1) and (n<=100) then getone(n) else
        case k of
          'P':pattern
        end
    until k='Q';
    gotopage(page);
   { writeblock (b,buffer)}
  end;

  procedure showattribhelp;
  var cnt:integer;

    procedure demo;
    begin
    textbackground(black);
      textcolor (cnt);
      write (cnt:2,')',colorstr[cnt],' ')
    end;

  begin
    gotoxy (1,23);
    for cnt:=0 to 7 do demo;
    gotoxy (1,24);
    for cnt:=8 to 15 do demo;
    cn
  end;

  procedure doattrib;
  var cnt,v:integer;
      k:char;
  begin
    v:=valu(inp);
    if ((v=0) and (inp[1]<>'0')) or (v<0) or (v>15) then begin
      v:=-1;
      for cnt:=0 to 15 do if match (inp,colorstr[cnt]) then v:=cnt;
      if v=-1 then exit
    end;
    p.i^:=v
  end;
var fat:anystr;
    ss:string[2];
    ct:integer;
    lx,ly:byte;
begin
  t:=things[n];
  pu:=t.p;
  gotopage (whichpage(n));
  y:=whichline(n);
  if not (t.ttype in [tbaudset,tusertime]) then begin
    gotoxy (1,24);
{    cleareol;
    writeln;}
    cleareol;
    writeln;
    write (t.descrip);
    cleareol;
    gotoxy (1,24);
    case t.ttype of
      tinteger:
        begin
          buflen:=6;
          showintrange
        end;
      tsstr,ttime:buflen:=15;
      tmstr:buflen:=30;
      tlstr,tpath:buflen:=80;
      tboolean,tchar:buflen:=1;
      tattrib:                 showattribhelp
    end;
    lx:=1;ly:=y;
    if buflen+dcol>79 then buflen:=48;
    gotoxy (dcol,y);
    cleareol;
    inp:=varstr(n);
    fat:='';
    while (inp[length(inp)]=' ') do delete(inp,length(inp),1);
    Editline(inp,lx,dcol,ly,buflen,ss);
      end else inp[0]:=^A;
  if length(inp)<>0 then
    case t.ttype of
      tinteger:doint;
      tsstr,tmstr,tlstr:dostr;
      tboolean:doboolean;
      tchar:dochar;
      tbaudset:dobaud;
      tpath:dopath;
      ttime:dotime;
      tattrib:doattrib;
      tusertime:dousertime
    end;
  reshow;
  gotoxy (1,24);
{  cleareol;
  writeln;}
  cleareol;
  writeln;
  cleareol;
  t.p:=pu;
  things[n]:=t
end;

procedure changenum (ns:integer; editit:boolean);
var n:integer;
begin
n:=ns;
{  n:=ns+top-1;}
  if (n<1) or (n>numthings) then exit;
  getinput (n,editit)
end;

procedure maybemakeconfig;
var f:file of configsettype;
    s,w:integer;
begin
  assign (f,'emulex.bbs');
  reset (f);
  if ioresult=0 then begin
    close (f);
    exit
  end;
  fillchar (configset,sizeof(configset),0);
  formatconfig
end;

var command:sstr;
    i:integer;
    re:integer;
    bb:char;
    fuck1,fuck2:integer;
    done:boolean;
    shit:string[3];
   kode1, Kode:integer;
procedure fixcur;
var cc:integer;
begin
    fuck1:=(page-1)*20+1;
    fuck2:=fuck1+19;
    cc:=i-fuck1+1;

    if bot>numthings then bot:=numthings;
gotoxy (5,cc+2);
write( things[i].text + ':');

end;
procedure Main;
begin
  done:=false;
  invert;fixcur;cd;
  repeat
  invert;fixcur;cd;
      fuck1:=(page-1)*20+1;
    fuck2:=fuck1+19;

    gotoxy (1,24);
    invert;
    Writeln ('[Return]:edit [F10]:Save [PgUp]:Prev. Page [PgDn]:Next Page [Esc]:Abort');cd;
    bb:=bioskey;

      case bb of
         #200:if i>fuck1 then begin
         cd;fixcur;
          dec(i);
          invert;fixcur;
         end;
        #208:if (i<fuck2) and (i<numthings) then begin
          cd;fixcur;
          inc(i);
          invert;fixcur;
         end;
        #187:begin
        cd;fixcur;
              gotoxy (1,1);
              changenum (i,true);
             end;
        #196:begin
        cd;
              writeconfig;
              byebye
             end;
        #27:begin cd;fixcur; done:=true;end;
        #13:begin cd;fixcur; changenum (i,false);end;

        #201:begin cd;fixcur;gotopage (page-1);i:=((page-1)*20+1)+19;end;
        #209:begin cd;fixcur;gotopage (page+1);i:=(page-1)*20+1;end;

      end;
      if i<1 then i:=1;
      if i>numthings then i:=numthings;
  until done;

end;

begin
directvideo:=true;
 textmode (co80);
 window(1,1,80,25);clrscr;
 {exec('command.com','/c type config.1');
 noise;}
  clrscr;

  gotoxy (1,1);
  readdata;
  assignptrs;
  maybemakeconfig;
  readconfig;
  i:=ioresult;
  numpages:=whichpage(numthings);
  page:=0;
  while keypressed do shit:=readkey;
  repeat
  cd;
  clrscr;
  cs;
  exec('command.com','/c type config.2');



  cn;
  write (^M'[S]ave Config [A]bort [#] Choose Page: ');cd;

  shit:=' ';
  shit:=readkey;
  if length(shit)=0 then shit:=' ';
  if upcase(shit[1])='S' then begin writeconfig;byebye;end;
  if (shit=#27) or (upcase(shit[1])='A') then begin abortyn; end;

  if (shit='1') or (shit='2') or (shit='3') or (shit='4') then begin

  val(shit,kode,kode1);
  if kode<1 then kode:=1;
  if kode>numpages then kode:=numpages;
  i:=(kode-1)*20+1;
  gotopage (kode);
  i:=(kode-1)*20+1;

  main;
  end;
  until 0=1;
end.

{



}