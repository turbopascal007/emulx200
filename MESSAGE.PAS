uses dos,crt,gentypes,subs1,gensubs,subs2,statret,configrt,textret,mailret,userret;

const unused=-2; eom=-1;
       TestMode:boolean=true;
type blockmaptype=array [0..numsectors] of integer;
var blockmap:blockmaptype;
    numblocks,totalblocks:integer;
    DoDoors:boolean;

var wholemapfile:file of blockmaptype;
    ufile:file of userrec;
    mfile:file of mailrec;
    bfile:file of bulrec;
    bdfile:file of boardrec;
    dofile:file of doorrec;
    fbfile:file of mailrec;
    newsfile:file of newsrec;
    logfile:text;

procedure tctb (f,b:integer);
begin
  textcolor (f);
  textbackground (b)
end;

procedure inverse;
begin
  tctb (0,6)
end;

procedure bold;
begin
  tctb (14,1)
end;

procedure normal;
begin
  tctb (13,0)
end;

procedure center (l:lstr);
begin
  clreol;
  gotoxy (40-length(l) div 2,wherey);
  writeln (l)
end;

procedure status (s:lstr);
var x,y:integer;
begin
  x:=wherex;
  y:=wherey;
  window (1,1,80,25);
  gotoxy (1,25);
  bold;
  clreol;
  gotoxy (40-length(s) div 2,wherey);
  write (s);
  normal;
  window (1,3,80,23);
  gotoxy (x,y)
end;

procedure nostatus;
begin
  status ('')
end;

procedure waitkey;
var k:char;
begin
  writeln;
  if length(ParamStr(1))=0 then begin
    writeln;
    center ('Press any key to continue..');
    k:=readkey;
  end;
end;

procedure openfiles;
var mnf:lstr;

  procedure assgn (var f; l:lstr);
  var ff:file absolute f;
  begin
    mnf:=l;
    assign (ff,l);
    writeln ('  Opening file ',l,'...');
  end;

  procedure error;
  begin
    writeln ('Fatal error:  File ',mnf,' not found!  Sorry, I can''t continue!');
    halt
  end;

begin
  status ('Locating Data Files');
  {$I-}
  assgn (tfile,textdir+'Text');
  reset (tfile);
  if ioresult<>0 then error;
  assgn (mapfile,textdir+'BlockMap');
  reset (mapfile);
  if ioresult<>0 then error;
  assign (wholemapfile,mnf);
  reset (wholemapfile);
  assgn (ufile,'Users');
  reset (ufile);
  if ioresult<>0 then error;
  assgn (mfile,'Mail');
  reset (mfile);
  if ioresult<>0 then error;
  assgn (bdfile,boarddir+'Boarddir');
  reset (bdfile);
  if ioresult<>0 then error;
if not exist('doors') then dodoors:=false else begin
dodoors:=true;
  assgn (dofile,'Doors');
  reset (dofile);
  if ioresult<>0 then dodoors:=false else dodoors:=true;
  end;
  if dodoors=false then writeln ('  ---No Doors to process');

  assgn (fbfile,'Feedback');
  reset (fbfile);
  if ioresult<>0 then error;
  assgn (newsfile,'News');
  reset (newsfile);
  if ioresult<>0 then error;
  {$I+}
  nostatus
end;

procedure readblockmap;
var cnt:integer;
begin
  status ('Reading blockmap file');
  numblocks:=filesize(mapfile)-1;
  if numblocks<>numsectors then
    writeln ('BlockMap: File size error!  The file size should be ',(numsectors+1)*2,' bytes!');
{  if numblocks>numsectors then numblocks:=numsectors;
  seek (wholemapfile,0);
  read (wholemapfile,blockmap);
  for cnt:=numblocks+1 to numsectors do blockmap[cnt]:=-2;}

  totalblocks:=filesize(tfile);
  nostatus
end;

procedure writeblockmap (block,val:integer);
var cnt:integer;
begin
  seek (mapfile,block);
  write (mapfile,val);
  blockmap[block]:=val
end;

function percentstr (r:real):sstr;
var tmp:sstr;
begin
  str (r*100:0:0,tmp);
  percentstr:=tmp+'%'
end;

procedure init;
begin
{  textmode (bw80); }
  normal;
  clrscr;
  window (1,1,80,25);
  bold;
  center ('FCP/Emulex '+versionnum+'          Message Base Utilities         10/21/87');
  normal;
  window (1,3,80,23);
  status ('Reading Configuration File');
  readconfig;
  readstatus;
  gotoxy (1,1);
  writeln ('Hello, ',sysopname,'.');
  writeln;
  openfiles;
  waitkey
end;

procedure writelog (a:anystr);
begin
  writeln;
  writeln;
  writeln ('NOTE: ',a);
  writeln (logfile,a)
end;

function lookupuname (unum:integer):mstr;
var u:userrec;
begin
  if (unum<1) or (unum>filesize(ufile)-1)
    then lookupuname:='[Unknown]'
    else begin
      seek (ufile,unum);
      read (ufile,u);
      lookupuname:=u.handle
    end
end;

procedure max (var s; maxlength:integer);
var b:byte absolute s;
begin
  if b>maxlength then b:=maxlength
end;

procedure erasebul;
var b:bulrec;
    bd:boardrec;
    cnt,n:integer;
begin
  n:=filepos(bfile);
  seek (bfile,n-1);
  read (bfile,b);
  seek (bdfile,filepos(bdfile)-1);
  read (bdfile,bd);
  writelog ('Bulletin erased:  Sub-board '+bd.boardname+' ['+bd.shortname+
            '], title='+b.title+' posted by '+b.leftby);
  for cnt:=n to filesize(bfile)-1 do begin
    seek (bfile,cnt);
    read (bfile,b);
    seek (bfile,cnt-1);
    write (bfile,b)
  end;
  seek (bfile,filesize(bfile)-1);
  truncate (bfile);
  seek (bfile,n)
end;

procedure erasemail;
var m:mailrec;
    cnt,n:integer;
begin
  n:=filepos(mfile);
  seek (mfile,n-1);
  read (mfile,m);
  max (m.title,30);
  max (m.sentby,30);
  writelog ('E-mail erased: From '+m.sentby+' to '+lookupuname(m.sentto)+
            ': Title='+m.title);
  for cnt:=n to filesize(mfile)-1 do begin
    seek (mfile,cnt);
    read (mfile,m);
    seek (mfile,cnt-1);
    write (mfile,m)
  end;
  seek (mfile,filesize(mfile)-1);
  truncate (mfile);
  seek (mfile,n)
end;

procedure erasefeedback;
var m:mailrec;
    cnt,n:integer;
begin
  n:=filepos(fbfile);
  seek (fbfile,n-1);
  read (fbfile,m);
  writelog ('Feedback erased: From '+m.sentby+': Title='+m.title);
  for cnt:=n to filesize(fbfile)-1 do begin
    seek (fbfile,cnt);
    read (fbfile,m);
    seek (fbfile,cnt-1);
    write (fbfile,m)
  end;
  seek (fbfile,filesize(fbfile)-1);
  truncate (fbfile);
  seek (fbfile,n)
end;

procedure erasedoorinfo;
var d:doorrec;
    n:integer;
begin
  n:=filepos(dofile);
  seek (dofile,n-1);
  read (dofile,d);
  writelog ('Door info erased: '+d.name);
  d.info:=-1;
  seek (dofile,n-1);
  write (dofile,d)
end;

procedure erasenews;
var ne:newsrec;
    cnt,n:integer;
begin
  n:=filepos(newsfile);
  writelog ('News item erased.');
  for cnt:=n to filesize(newsfile)-1 do begin
    seek (newsfile,cnt);
    read (newsfile,ne);
    seek (newsfile,cnt-1);
    write (newsfile,ne)
  end;
  seek (newsfile,filesize(newsfile)-1);
  truncate (newsfile);
  seek (newsfile,n)
end;

procedure eraseinfoform;
var u:userrec;
    n:integer;
begin
  n:=filepos(ufile);
  seek (ufile,n-1);
  read (ufile,u);
  writelog ('Info-form for user '+u.handle+' erased.');
  u.infoform:=-1;
  seek (ufile,n-1);
  write (ufile,u)
end;

procedure erasenewinfo(which:integer);
var u:userrec;
    n:integer;
begin
  n:=filepos(ufile);
  seek (ufile,n-1);
  read (ufile,u);
  writelog ('Info-form #'+strr(which)+' for user '+u.handle+' erased.');
 { u.NewInfos[Which]:=-1;}
  seek (ufile,n-1);
  write (ufile,u)
end;

procedure eraseannouncement;
var u:userrec;
    n:integer;
begin
  n:=filepos(ufile);
  seek (ufile,n-1);
  read (ufile,u);
  writelog ('E-Mail announcement for user '+u.handle+' erased.');
  u.emailannounce:=-1;
  seek (ufile,n-1);
  write (ufile,u)
end;

procedure erasetonext;
begin
  writelog ('Message to next user erased.');
  tonext:=-1;
  writestatus
end;

procedure simpleanalyze;
var cnt:integer;
    holes,nummessages:integer;
begin
  readblockmap;
  status ('Analyzing..');
  holes:=0;
  nummessages:=0;
  for cnt:=0 to totalblocks-1 do begin
    case blockmap[cnt] of
      unused:holes:=holes+1;
      eom:nummessages:=nummessages+1
    end
  end;
  writeln;
  nostatus;
  Gotoxy(1,20);
  write ('      Total blocks: ',totalblocks);
  Gotoxy(40,20);
  writeln ('Number of messages: ',nummessages);
  write ('             Holes: ',holes);
  Gotoxy(40,21);
  writeln ('        Efficiency: ',percentstr (1-holes/totalblocks));
  write ('   Expansion limit: ',numsectors);
  Gotoxy(40,22);
  writeln ('  % expansion free: ',percentstr (1-totalblocks/numsectors))
end;

var numbuls,numforms,numannouncements,numdoors,nummail,numfeedback,numnews,
    numtonext,numwandering,bksbuls,bksforms,bksannouncements,bksdoors,bksmail,
    bksfeedback,bksnews,bkstonext,bkswandering,numholes,crosslinked,notending,
    wandering,c,cnt,X,Y:integer;
    news:newsrec;
    bd:boardrec;
    d:doorrec;
    u:userrec;
    m:mailrec;
    b:bulrec;
    fn:lstr;
    mustbeerased:boolean;

procedure mediumanalyze;

  procedure maerror (l:lstr; var counter:integer);
  begin
    writelog ('[Error> '+l);
    counter:=counter+1
  end;

  procedure register (sector:integer; var num,bks:integer);
  var os,oos,tmp:integer;
  begin
    mustbeerased:=false;
    if sector=-1 then exit;
    num:=num+1;
    os:=-1;
    repeat
      bks:=bks+1;
      oos:=os;
      os:=sector;
      sector:=blockmap[os];
      blockmap[os]:=-3;
    until (sector<0);
    case sector of
      unused:begin
           maerror ('Message ends with unused block!',notending);
           writeblockmap (os,eom);
           blockmap[os]:=-3
         end;
      -3:begin
           maerror ('Message is cross-linked and must be erased!',crosslinked);
         if not testmode then   mustbeerased:=true;
         end
    end
  end;

  procedure doline (q:lstr; num,bks:integer);
  begin
    write (q);
    gotoxy (40,wherey);
    writeln (num:4,' for ',bks:4,' blocks (',percentstr(bks/totalblocks),')')
  end;

begin
  readblockmap;
  status ('Analyzing [Logging to file Analyze.Med]');
  assign (logfile,'analyze.med');
  rewrite (logfile);
  numbuls:=0; numforms:=0; numannouncements:=0; numdoors:=0; nummail:=0;
  numfeedback:=0; numnews:=0; numtonext:=0; numwandering:=0;
  bksbuls:=0; bksforms:=0; bksannouncements:=0; bksdoors:=0; bksmail:=0;
  bksfeedback:=0; bksnews:=0; bkstonext:=0; bkswandering:=0;
  numholes:=0; crosslinked:=0; notending:=0;

  writeln;
  writeln ('Analyzing Message Base..');
  seek (bdfile,0);
  while not eof(bdfile) do begin
    read (bdfile,bd);
    fn:=boarddir+bd.shortname+'.bul';
    assign (bfile,fn);
    {$I-} reset (bfile); {$I+}
    if ioresult<>0 then writeln ('  Sub File ',fn,' Missing!') else begin
      write ('  Sub: ',bd.shortname,':[',bd.boardname,']: [');
      X:=WhereX;
      Y:=WhereY;
      For Cnt:=1 to (Filesize(BFile) DIV 10) do Write(' ');
      Write(']');
      cnt:=0;
      while not eof(bfile) do begin
        cnt:=cnt+1;
        if (cnt mod 10)=0 then Begin
          Gotoxy(Y,X);
          write (cnt);
        End;
        read (bfile,b);
        register (b.line,numbuls,bksbuls);
  if not testmode then       if mustbeerased then erasebul;
      end;
      If Cnt<>0 then writeln(Cnt,']') else writeln('None]');
      close (bfile);
    end;
  end;

  writeln;
  write ('Analyzing E-Mail: [');
  seek (mfile,0);
  X:=WhereX;
  Y:=WhereY;
  For Cnt:=1 to (Filesize(MFile) DIV 10) do Write(' ');
  Write(']');
  cnt:=0;
  while not eof(mfile) do begin
    cnt:=cnt+1;
    if (cnt mod 10)=0 then Begin
      Gotoxy(Y,X);
      write (cnt);
    End;
    read (mfile,m);
    register (m.line,nummail,bksmail);
if not testmode then     if mustbeerased then erasemail;
  end;
  If Cnt<>0 then writeln(Cnt,']') else writeln('None]');

  write ('Analyzing Feedback: [');
  seek (fbfile,0);
  X:=WhereX;
  Y:=WhereY;
  For Cnt:=1 to (Filesize(FbFile) DIV 10) do Write(' ');
  Write(']');
  cnt:=0;
  while not eof(fbfile) do begin
    cnt:=cnt+1;
    if (cnt mod 5)=0 then Begin
      Gotoxy(Y,X);
      write (cnt);
    End;
    read (fbfile,m);
    register (m.line,numfeedback,bksfeedback);
if not testmode then     if mustbeerased then erasefeedback;
  end;
  If Cnt<>0 then writeln(Cnt,']') else writeln('None]');

if dodoors then begin
  write ('Analyzing Door Information: [');
  seek (dofile,0);
  X:=WhereX;
  Y:=WhereY;
  For Cnt:=1 to (Filesize(DoFile) DIV 10) do Write(' ');
  Write(']');
  Cnt:=0;
  while not eof(dofile) do begin
    read (dofile,d);
    Gotoxy(Y,X);
    write(Cnt);
    Cnt:=Cnt+1;
    register (d.info,numdoors,bksdoors);
if not testmode then     if mustbeerased then erasedoorinfo
  end;
  If Cnt<>0 then writeln(Cnt,']') else writeln('None]');
end;
  write ('Analyzing News Items: [');
  seek (newsfile,0);
  X:=WhereX;
  Y:=WhereY;
  For Cnt:=1 to (Filesize(DoFile) DIV 10) do Write(' ');
  Write(']');
  Cnt:=0;
  while not eof(newsfile) do begin
    read (newsfile,news);
    write(Cnt);
    Gotoxy(Y,X);
    Cnt:=Cnt+1;
    register (news.location,numnews,bksnews);
if not testmode then     if mustbeerased then erasenews;
  end;
  If Cnt<>0 then writeln(Cnt,']') else writeln('None]');

  write ('Analyzing User Info [Announcements/Infoforms]: [');
  seek (ufile,1);
  X:=WhereX;
  Y:=WhereY;
  For Cnt:=1 to (Filesize(UFile) DIV 10) do Write(' ');
  Write(']');
  cnt:=0;
  while not eof(ufile) do begin
    cnt:=cnt+1;
    if (cnt mod 25)=0 then Begin
      Gotoxy(Y,X);
      write (Cnt);
    End;
    read (ufile,u);
{    for c:=1 to 10 do begin
      register(u.NewInfos[C],numforms,bksforms);
      if mustbeerased then erasenewinfo(c);
    end;}
    register (u.infoform,numforms,bksforms);
if not testmode then     if mustbeerased then eraseinfoform;
    register (u.emailannounce,numannouncements,bksannouncements);
if not testmode then     if mustbeerased then eraseannouncement;
  end;
  If Cnt<>0 then writeln(Cnt,']') else Writeln('None]');

  write ('Analyzing AutoMessage..');
  register (tonext,numtonext,bkstonext);
if not testmode then   if mustbeerased then erasetonext;

  writeln;
  write ('Locating Holes/Wandering Message Blocks..');
  for cnt:=0 to totalblocks-1 do
    if blockmap[cnt]<>-3
      then if blockmap[cnt]=-2
        then numholes:=numholes+1
        else begin
          bkswandering:=bkswandering+1;
          if blockmap[cnt]=-1 then numwandering:=numwandering+1;
          writeblockmap (cnt,-2)
        end;

  writeln;
  writeln;
  doline ('Messages',numbuls,bksbuls);
  doline ('Electronic Mail',nummail,bksmail);
  doline ('Feedback',numfeedback,bksfeedback);
  doline ('News Items',numnews,bksnews);
  doline ('Door Information',numdoors,bksdoors);
  doline ('Infoforms',numforms,bksforms);
  doline ('Announcements',numannouncements,bksannouncements);
  doline ('AutoMessage',numtonext,bkstonext);
  doline ('Wandering Message Blocks',numwandering,bkswandering);
  doline ('Holes',numholes,numholes);
  nostatus;
  writeln;
  writeln ('Note:  See file  Analyze.med  for a log of exactly what happened!');
  close (logfile)
end;

procedure complexanalyze;
Var Holes,Fills,Old,New,HowMany,TotalFixed:Integer;
    Q:Buffer;
    H,M:Array[1..300] of Integer;
    RunAgain:Boolean;

  Function FindNext(P:Integer):Integer;
  Var C:Integer;
  Begin
    FindNext:=-1;
    For C:=P+1 to TotalBlocks-1 do If BlockMap[C]<>-2 then Begin
      FindNext:=C;
      Exit;
    End;
  End;

begin
  ReadBlockMap;
(*  MediumAnalyze;
  TotalFixed:=0;
  If (Holes=0) then Begin
    Writeln;
    Writeln('Text file is optimized already!');
    Exit;
  End;
  Write('How many holes do you want to Leave? ');
  Readln(HowMany);
  Repeat
    RunAgain:=False;
    Holes:=0;
    Cnt:=0;
    While (Cnt<TotalBlocks) and (Holes<300) do Begin
      If BlockMap[Cnt]=-2 then Begin
        Holes:=Holes+1;
        Write(Cnt,' ');
        H[Holes]:=Cnt;
      End;
      Cnt:=Cnt+1;
    End;
    Writeln;Writeln;
    If Holes=300 then RunAgain:=True;
    TotalFixed:=TotalFixed+Holes;
    Cnt:=TotalBlocks-1;
    Fills:=0;
    While (Cnt>H[Holes]) and (Fills<Holes) do Begin
      If BlockMap[Cnt]>=0 then Begin
        Fills:=Fills+1;
        M[Fills]:=Cnt;
        Write(Cnt,' ');
      End;
      Cnt:=Cnt-1;
    End;
    Writeln; }
    For Cnt:=1 to TotalBlocks-1 do Begin
{      Old:=M[Cnt];
      New:=H[Cnt];
      Write('Text ',Cnt,': From ',Old,' to ',New,'      ');
      Writeln('BMap : From ',BlockMap[Old],' to ',BlockMap[New]); }
      Seek(TFile,Old);
      Read(TFile,Q);
      Seek(TFile,New);
      Write(TFile,Q);
      BlockMap[New]:=BlockMap[Old];
      BlockMap[Old]:=-2;
      Seek(MapFile,New);
      Write(MapFile,BlockMap[New]);
      Seek(MapFile,Old);
      Write(MapFile,BlockMap[Old]);
    End;
  Until Not RunAgain; *)
  Seek(MapFile,2485);
  While (HowMany=-1) do Read(MapFile,HowMany);
  HowMany:=-2;
  For Cnt:=1 to 50 do Write(MapFile,HowMany);
end;

procedure mainmenu;
var k:char;
    l:sstr;
begin
  assign (tfile,textdir+'Text');
  Reset(TFile);
  repeat
    clrscr;
    nostatus;
    if length(ParamStr(1))=0 then begin
      writeln ('   Message Base / Text Optimizer');
      writeln ('   Written by: Ken Dudah    Modified for FCP');
      writeln;
      writeln ('   A. Analyze Text:         Current Msg Allocation/Optimization info.');
      writeln ('   B. Opt/Error Correcting: Optimize/Fix Text errors');
      writeln ('   C. Complex Optimization: Not written');
      writeln ('   D. Quit:                 Return to DOS');
      writeln;
      write ('   Enter Command: ');
      repeat
        k:=readkey;
        k:=upcase(k)
      until (k>='A') and (k<='D');
      writeln (k);
      writeln;
    end else begin
      l:=paramstr(1);
      k:=upcase(L[1]);
      if (k<'A') or (k>'D') then halt;
    end;
    case k of
      'A':simpleanalyze;
      'B':mediumanalyze;
      'C':complexanalyze;
      'D':begin
            window (1,1,80,25);
            clrscr;
            gotoxy (1,24);
            center ('Bye!');
            writeln;
            halt
          end
    end;
    waitkey;
  until length(ParamStr(1))>0;
end;

begin
  init;
  mainmenu
end.
