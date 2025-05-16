
{$DEFINE OVERLAY}

unit init;

interface

uses crt,dos,
     gentypes,modem,statret,configrt,gensubs,subs1,windows,subs2;

procedure validconfiguration;
procedure initboard (checkfiles30:boolean);

implementation

procedure validconfiguration;
var errs:integer;
    cnt:integer;
    flag:boolean;

  procedure error (q:anystr);
  begin
    if errs=0 then writeln (usr,'Configuration Errors:');
    errs:=errs+1;
    writeln (usr,errs,'. ',q)
  end;

  procedure ispath (var x:lstr; name:lstr);
  begin
   if not exist2(x+'con') then error (name+' Path bad: '+x)
  end;

  procedure isfilename (var xx:lstr; fn:lstr);
  begin
   if not exist(xx) then error (fn+' Filename bad: '+xx)
  end;

  procedure isstring (x:anystr; name:lstr);
  var cnt:integer;
  begin
    if length(x)=0 then begin
      error (name+' has not been set!');
      exit
    end;
    for cnt:=1 to length(x) do if not (x[cnt] in [#32..#255])
      then begin
        error ('Bad '+name+' string');
        exit
      end
  end;

  procedure isinteger (n,r1,r2:integer; name:lstr);
  begin
    if (n<r1) or (n>r2) then error ('Bad '+name+' value: '+strr(n))
  end;

begin
  errs:=0;
  isstring (sysopname,'Sysop Name');
  ispath (textdir,'Path to Message Base');
  ispath (uploaddir,'Path to Ascii Uploads');
  ispath (boarddir,'Path to Sub-board Files');
  ispath (textfiledir,'Path to Menus, etc.');
  isinteger (defbaudrate,110,19200,'default Baud Rate');
  isinteger (usecom,1,2,'COM: port');
  isinteger (mintimeout,1,maxint,'input time out');
  isinteger (sysoplevel,1,maxint,'Co-Sysop Level');
  flag:=true;
  for cnt:=1 to 100 do if flag and (usertime[cnt]<1) then begin
    flag:=false;
    error ('Time per day has non-positive entries')
  end;
  if errs>0 then halt(e_badconfig)
end;

procedure initboard (checkfiles30:boolean);

  procedure formatmfile;
  var m:mailrec;
  begin
    rewrite (mfile);
    fillchar (m,sizeof(m),255);
    write (mfile,m)
  end;

  procedure openmfile;
  var i:integer;
  begin
    close (mfile);
    i:=ioresult;
    assign (mfile,'Mail');
    reset (mfile);
    i:=ioresult;
    if i<>0
      then if i=2
        then formatmfile
        else begin
          writeln (usr,'Fatal error: Unable to open mail file!');
          halt (e_fatalfileerror)
        end
  end;

  procedure openrumorfile;
  var i:integer;
  begin
  end;

  procedure closetfile;
  var n:integer;
  begin
    close (tfile);
    n:=ioresult;
    close (mapfile);
    n:=ioresult
  end;

  procedure formattfile;
  var cnt,p:integer;
      r:real;
      buff:buffer;
      x:string[1];
  const dummystr:sstr='Blank!! ';
  begin
    write (usr,'Message Base not found.  Create new one [y/n]? ');
    buflen:=1;
    readline (x);
    if (length(x)=0) or (upcase(x[1])<>'Y') then halt (e_fatalfileerror);
    rewrite (mapfile);
    if ioresult<>0 then begin
      writeln (usr,'Unable to create Message Base.');
      halt (e_fatalfileerror)
    end;
    p:=-2;
    for cnt:=0 to numsectors do write (mapfile,p);
    p:=1;
    for cnt:=1 to sectorsize do begin
      buff[cnt]:=dummystr[p];
      p:=p+1;
      if p>length(dummystr) then p:=1
    end;
    rewrite (tfile);
    if ioresult<>0 then begin
      writeln (usr,'Unable to create Message Base.');
      halt (e_fatalfileerror)
    end;
    for cnt:=0 to 5 do write (tfile,buff)
  end;

  procedure opentfile;
  var i,j:integer;
  begin
    closetfile;
    assign (tfile,textdir+'Text');
    assign (mapfile,textdir+'BlockMap');
    reset (tfile);
    i:=ioresult;
    reset (mapfile);
    j:=ioresult;
    if (i<>0) or (j<>0) then formattfile;
    firstfree:=-1
  end;

  procedure openufile;
  var u:userrec;
      n,cnt:integer;

    procedure createuhfile;
    var cnt:integer;
    begin
      rewrite (uhfile);
      if ioresult<>0 then begin
        writeln (usr,'Unable to create User Index File.');
        halt (e_fatalfileerror)
      end;
      seek (ufile,0);
      while not eof(ufile) do begin
        read (ufile,u);
        write (uhfile,u.handle)
      end
    end;

  begin
    close (ufile);
    assign (ufile,'Users');
    reset (ufile);
    n:=ioresult;
    if n=0 then begin
      numusers:=filesize(ufile)-1;
      assign (uhfile,'Userindx');
      reset (uhfile);
      if ioresult<>0
        then createuhfile
        else if filesize(uhfile)<>filesize(ufile) then begin
          close (uhfile);
          createuhfile
        end;
      exit
    end;
    close (ufile);
    n:=ioresult;
    rewrite (ufile);
    fillchar (u,sizeof(u),0);
    write (ufile,u);
    u.handle:=sysopname;
   { u.note:='Sysop';
    u.macro1:=u.handle;
    u.macro2:=u.handle;
    u.macro3:=u.handle;}
    u.password:='EMULEXDEFAULT';
    u.phonenum:='1234567890';
    u.timetoday:=9999;
    u.level:=sysoplevel+1;
    u.udlevel:=sysoplevel+1;
    u.udpoints:=sysoplevel+1;
    u.gflevel:=sysoplevel+1;
    u.config:=[lowercase,eightycols,linefeeds,postprompts,asciigraphics];
    u.emailannounce:=-1;
{    u.infoform1:=-1;
    u.infoform2:=-1;
    u.infoform3:=-1;
    u.infoform4:=-1;}
    u.infoform:=-1;
    u.displaylen:=24;
{    u.menutype:=0;}
{    u.defproto:='Z';}
    fillchar (u.access2,32,255);
    if useconmode then u.config:=u.config+[ansigraphics];
    write (ufile,u);
    numusers:=1;
    createuhfile
  end;

  procedure initfile (var f:file);
  var fi:fib absolute f;
  begin
    fi.handle:=0;
    fi.name[0]:=chr(0)
  end;

  procedure openlogfile;

    procedure autodeletesyslog;
    var mx,cnt:integer;
        l:logrec;
    begin
      dontanswer;
      write (usr,'Auto-deleting System Log - please stand by ... ');
      mx:=filesize(logfile) div 2;
      for cnt:=1 to mx do begin
        seek (logfile,cnt+mx-1);
        read (logfile,l);
        seek (logfile,cnt-1);
        write (logfile,l)
      end;
      seek (logfile,mx-1);
      truncate (logfile);
      writeln (usr,'Done.');
      doanswer
    end;

  begin
    assign (logfile,'Syslog');
    reset (logfile);
    if ioresult<>0 then begin
      rewrite (logfile);
      if ioresult<>0 then begin
        writeln (usr,'Unable to create log file');
        halt (e_fatalfileerror)
      end
    end;
    if filesize(logfile)>maxsyslogsize then autodeletesyslog
  end;

  procedure loadsyslogdat;
  var tf:text;
      q:lstr;
      b1,b2,p,s,n:integer;
  begin
    numsyslogdat:=0;
    with syslogdat[0] do begin
      menu:=0;
      subcommand:=0;
      text:='SYSLOG.DAT entry not found: %'
    end;
    assign (tf,'syslog.dat');
    reset (tf);
    if ioresult=0 then begin
      while not eof(tf) do begin
        readln (tf,q);
        p:=pos(' ',q);
        if p<>0 then begin
          val (copy(q,1,p-1),b1,s);
          if s=0 then begin
            delete (q,1,p);
            p:=pos(' ',q);
            if p<>0 then begin
              val (copy(q,1,p-1),b2,s);
              if s=0 then begin
                delete (q,1,p);
                if numsyslogdat=maxsyslogdat
                  then writeln (usr,'Too many SYSLOG.DAT entries')
                  else begin
                    numsyslogdat:=numsyslogdat+1;
                    with syslogdat[numsyslogdat] do begin
                      menu:=b1;
                      subcommand:=b2;
                      text:=copy(q,1,30)
                    end
                  end
              end
            end
          end
        end
      end;
      textclose (tf)
    end;
    if numsyslogdat=0 then writeln (usr,'SYSLOG.DAT file missing or invalid')
  end;

  procedure doesfilesequal30;
  var f:array [1..14] of file;
      cnt,i:integer;
  begin
    {$IFNDEF OVERLAY}
    for cnt:=1 to 14 do begin
      assign (f[cnt],'CON');
      reset (f[cnt]);
      i:=ioresult;
      if i<>0 then begin
        writeln (usr,^M^J'Fatal error:  You MUST put the command',
           ^M^J^J'   FILES=30',
           ^M^J^J'in your CONFIG.SYS file on the disk from which you boot.',
           ^M^J^J'Note:  If you have been modifying TCS, then you may',
             ^M^J'       be leaving a file open.');
        halt (e_files30)
      end
    end;
    for cnt:=14 downto 1 do close(f[cnt])
    {$ENDIF}
  end;

procedure readexefiledata;
var f:text;
begin
  dszfn:=forumdir+'DSZ.COM';
  dsz2fn:=forumdir+'DSZ.EXE';
  jmodemfn:=forumdir+'JMODEM.COM';
  lynxfn:=forumdir+'LYNX.EXE';
  jbatchfn:=forumdir+'JBATCH.COM';
  super8kfn:=forumdir+'SUPERK.COM';
  pkarc:=forumdir+'PKARC.EXE';
  pkarc2:=forumdir+'PKPAK.EXE';
  pak:=forumdir+'PAK.EXE';
  pkzip:=forumdir+'PKZIP.EXE';
end;

procedure readsysopmacros;
var ff:text;
    ummbobway,killer:integer;
begin
end;

var k,klux:char;
    cnt:integer;
begin
  with textrec(system.output) do begin
    openfunc:=@opendevice;
    closefunc:=@closedevice;
    flushfunc:=@writechars;
    inoutfunc:=@writechars
  end;
  with textrec(system.input) do begin
    inoutfunc:=@readcharfunc;
    openfunc:=@ignorecommand;
    closefunc:=@ignorecommand;
    flushfunc:=@ignorecommand
  end;
  fillchar (urec,sizeof(urec),0);
  urec.config:=[lowercase,eightycols,asciigraphics];
  iocode:=0;
  linecount:=0;
  sysopavail:=bytime;
  errorparam:='';
  errorproc:='';
  unam:='';
  chainstr:='';
  chatreason:='';
  sendstr:='';
  ulvl:=0;
  unum:=-1;
  logonunum:=-2;
  echoit:=true;
  break:=false;
  atmenu:=false;
  nochain:=false;
  nobreak:=false;
  wordwrap:=false;
  beginwithspacesok:=false;
  dots:=false;
  online:=false;
  local:=true;
  chatmode:=false;
  texttrap:=false;
  printerecho:=false;
  fillchar (urec,sizeof(urec),0);
  usecapsonly:=false;
  uselinefeeds:=true;
  if datascrambling then scrambled:=true else scrambled:=false;
  noscramble:=false;
  curattrib:=0;
  buflen:=80;
  baudrate:=defbaudrate;
  parity:=false;
  timelock:=false;
  ingetstr:=false;
  modeminlock:=false;
  modemoutlock:=false;
  tempsysop:=false;
  sysnext:=false;
  forcehangup:=false;
  requestbreak:=false;
  disconnected:=false;
  notitle:=false;
  nosendprompt:=false;
  emailing:=false;
  periods:=false;
  validprotos:=['X','Y','Z','J','L','G','O','1','S','K','R','P','W'];
  cursection:=mainsysop;
  regularlevel:=0;
  setparam (usecom,baudrate,parity);
{  if cts_handle then setctsmode(usecom,true);}
  doanswer;
  initwinds;
  for cnt:=1 to numsysfiles do initfile (sysfiles[cnt]);
  cls;
  opentfile;
  loadsyslogdat;
  readstatus;
  openufile;
  openlogfile;
  openmfile;
{ openrumorfile; }
  readexefiledata;
  readsysopmacros;
  overlaypath:=forumdir;
end;


procedure assignname (var t:text; nm:lstr);
begin
  with textrec(t) do begin
    move (nm[1],name,length(nm));
    name[length(nm)]:=#0
  end
end;

var r:registers;
begin
  { textmode (bw80); }
  checkbreak:=false;
  checkeof:=false;
  directvideo:=directvideomode;
  checksnow:=checksnowmode;
  r.ah:=15;
  intr ($10,r);
  if r.al=7
    then screenseg:=$b000
    else screenseg:=$b800;
  textrec(system.input).mode:=fminput;
  move (output,usr,sizeof(text));           { Set up device drivers }
  move (output,direct,sizeof(text));
  move (system.input,directin,sizeof(text));
  with textrec(direct) do begin
    openfunc:=@opendevice;
    closefunc:=@closedevice;
    flushfunc:=@directoutchars;
    inoutfunc:=@directoutchars;
    bufptr:=@buffer
  end;
  with textrec(directin) do begin
    mode:=fminput;
    inoutfunc:=@directinchars;
    openfunc:=@ignorecommand;
    flushfunc:=@ignorecommand;
    closefunc:=@ignorecommand;
    bufptr:=@buffer
  end;
  with textrec(usr) do bufptr:=@buffer;
  assignname (usr,'USR');
  assignname (direct,'DIRECT');
  assignname (directin,'DIRECT-IN');
  assignname (system.output,'OUTPUT');
  assignname (system.input,'INPUT')
end.
