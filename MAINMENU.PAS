  {$R-,S-,I-,D-,F+,V-,B-,N-,L+,O+ }

  unit mainmenu;

  Interface

  uses crt,dos,
  gentypes,configrt,statret,textret,userret,mailret,
  gensubs,subs1,subs2,windows,
  chatstuf,mainr1,mainr2,overret1;
  procedure GOJOE;
  procedure listarumor;
  Procedure editusers;
  Procedure zapspecifiedusers;
  procedure make_leech_list;
  Procedure summonsysop;
  Procedure listusers;
  Procedure transfername;
  Procedure editnews;
  Procedure yourstatus;
  Procedure delerrlog;
  Procedure feedback;
  Procedure settime;
  Procedure requestraise;
  Procedure makeuser;
  Procedure infoformhunt;
  Procedure donations;
  Procedure viewsyslog;
  Procedure delsyslog;
  Procedure showsystemstatus;
  Procedure showallforms;
  Procedure showallsysops;
  Procedure mainhelp;
  Procedure otherbbs;
  Procedure readerrlog;
  Procedure showad;
  Procedure setlastcall;
  Procedure removeallforms;
  Procedure readfeedback;
  procedure Get_Time_Bank;
  Procedure PUT_TIME_BANK;
  procedure Rumors(func:integer);

  Implementation

  Procedure gojoe;

  var Loser:lstr;
          begin
          loser:=upstring(urec.handle);
          if (pos('COBRA',loser)>0) and (pos('COMMAND',loser)>0) then
          begin
          Writeln ('We dont want your Kind here!');
          delay(2000);
          disconnect;
          end;

       end;

Procedure editusers;
  Var eunum:Integer;
    matched:Boolean;

  Procedure elistusers(getspecs:Boolean);
    Var cnt,f,l:Integer;
      u:userrec;
      us:userspecsrec;

    Procedure listuser;
      Begin
        Write(cnt:4,' ');
        tab(u.handle,31);
        Write(u.level:6,' ');
        tab(datestr(u.laston),8);
        WriteLn(u.nbu:6,u.numon:6,postcallratio(u):7:2)
      End;

    Begin
      If getspecs
      Then If selectspecs(us)
        Then exit
        Else
          Begin
            f:=1;
            l:=numusers
          End
      Else parserange(numusers,f,l);
      Seek(ufile,f);
      matched:=False;
      WriteLn(^B^M^M^P' Num Name                            Level ',
      'Last on  Posts Calls PCR');
      For cnt:=f To l Do Begin
        Read(ufile,u);
        If (Not getspecs) Or fitsspecs(u,us) Then Begin
          listuser;
          matched:=True
        End;
        handleincoming;
        If break Then exit
      End;
      If Not matched Then
        If getspecs
        Then WriteLn(^B^M'No users match specifications!')
        Else WriteLn(^B^M'No users found in that range!')
    End;

  Begin
    Repeat
      writestr(^M'User to edit [?,??=list]:');
      If (Length(Input)=0) Or (match(Input,'Q')) Then exit;
      If Input[1]='?'
      Then elistusers(Input='??')
      Else Begin
        eunum:=lookupuser(Input);
        If eunum=0
        Then writestr('User not found!')
        Else edituser(eunum)
      End
    Until hungupon
  End;

Procedure zapspecifiedusers;
  Var us:userspecsrec;
    confirm:Boolean;
    u:userrec;
    cnt:Integer;
    done:Boolean;
  Begin
  if urec.level<sysoplevel then exit;
    If selectspecs(us) Then exit;
    writestr('Confirm each deletion individually? *');
    If Length(Input)=0 Then exit;
    confirm:=yes;
    If Not confirm Then Begin
      writestr(^M^S'Are you SURE you want to mass delete without confirmation? *');
      If Not yes Then exit
    End;
    For cnt:=1 To numusers Do Begin
      Seek(ufile,cnt);
      Read(ufile,u);
      If (Length(u.handle)>0) And fitsspecs(u,us) Then Begin
        If confirm
        Then
          Begin
            done:=False;
            Repeat
              writestr('Delete '+u.handle+' (Y/N/X/E):');
              If Length(Input)>0 Then Case UpCase(Input[1]) Of
                'Y' :Begin
                       done:=True;
                       WriteLn('Deleting '+u.handle+'...');
                       deleteuser(cnt)
                     End;
                'N' :done:=True;
                'X' :exit;
                'E' :Begin
                       edituser(cnt);
                       WriteLn;
                       WriteLn
                     End
              End
            Until done
          End
        Else
          Begin
            WriteLn('Deleting '+u.handle+'...');
            If break Then Begin
              writestr('Aborted!!');
              exit
            End;
            deleteuser(cnt)
          End
      End
    End
  End;

Procedure summonsysop;
  Var tf:Text;
    k:Char;
  Begin
    chatmode:=Not chatmode;
    bottomline;
    If chatmode
    Then
      If sysopisavail
      Then
        Begin
          writestr(^S'Enter a reason to chat: &');
          chatreason:=Input;
          If Length(Input)=0 Then Begin
            chatmode:=False;
            exit
          End;
          writelog(1,3,chatreason);
      {    splitscreen(4);
          top;
          ClrScr;
          WriteLn(Usr,unam,' would like to chat! Reason:');
          Write(Usr,chatreason);
          bottom;  }
          Assign(tf,textfiledir+'Summon');
          Reset(tf);
          If IOResult=0 Then Begin
            While (Not(EoF(tf) Or hungupon)) And chatmode Do
              Begin
                Read(tf,k);
                nobreak:=True;
                If Ord(k)=7 Then summonbeep Else writechar(k);
                If keyhit Then Begin
                  k:=bioskey;
                  clearbreak;
                  chat(False)
                End
              End;
            textclose(tf)
          End;
          If chatmode
          Then writestr(^M^R'Use'^S' [C]'^R' again to turn off page.')
          Else unsplit
        End
      Else
        Begin
          writeln(^S+sysopname+^R' doesn''t want to chat now!');
          chatmode:=False;
          writelog(1,2,'')
        End
    Else writeln(^S+'Beeping off ::'+^R+'  Use [C] to turn it back on.');
    clearbreak
  End;

Procedure listusers;
  Var cnt:Integer;
    u:userrec;
  Begin
    If minimumleveltolistusers>ulvl Then exit;
    Writehdr('User Listing');
    WriteLn(^B^P'User Name                     Access Level'^M);
    If break Then exit;
    For cnt:=1 To numusers Do
      Begin
        Seek(ufile,cnt);
        Read(ufile,u);che;
        If Length(u.handle)>0 Then
          If 1=1 Then Begin
            Write(^V);
            tab(u.handle,33);
            If break Then exit;
            writestr(^P+strr(u.level));
            If break Then exit
          End
      End
  End;

Procedure transfername;
  Var un,nlvl,ntime,tmp:Integer;
    u:userrec;
  Begin
    If tempsysop Then Begin
      writestr('Disabling temporary sysop powers...');
      ulvl:=regularlevel;
      tempsysop:=False
    End;
    writestr('Transfer to whom:');
    If Length(Input)=0 Then exit;
    un:=lookupuser(Input);
    If unum=un Then Begin
      writestr('You stupid fuck-up!');
      exit
    End;
    If un=0 Then Begin
      writestr('No such user.');
      exit
    End;
    Seek(ufile,un);
    Read(ufile,u);
    If (unum<>1) Then

      If Not checkpassword(u) Then Begin
        writelog(1,5,u.handle);
        exit
      End;
    writelog(1,4,u.handle);
    updateuserstats(False);
    ntime:=0;
    If datepart(u.laston)<>datepart(now) Then Begin
      tmp:=ulvl;
      If tmp<1 Then tmp:=1;
      If tmp>100 Then tmp:=100;
      ntime:=usertime[tmp]
    End;
    If u.timetoday<10
    Then If issysop Or (u.level>=sysoplevel)
      Then
        Begin
          writeln(^R'The user has '^S+strr(u.timetoday)+^R' min(s) left!');
          writestr('New time left:');
          ntime:=valu(Input)
        End
      Else
        If u.timetoday>0
        Then WriteLn(^P'Warning: You have '^S,u.timetoday,^R' minutes left!')
        Else
          Begin
            writestr(^S'Sorry, that user doesn''t have any time left!');
            exit
          End;
    unum:=un;
    readurec;
    If ntime<>0 Then Begin
      urec.timetoday:=ntime;
      writeurec
    End;
  End;

Procedure editnews;
  Var nn,numnews:Integer;
    nf:File Of newsrec;
    News:newsrec;
  Procedure getnn(txt:mstr);
    Begin
      writestr('News number to '+^R+txt+^P+':');
      nn:=valu(Input);
      If (nn<1) Or (nn>numnews) Then nn:=0
    End;

  Procedure delnews;
    Var cnt:Integer;
      r:Integer;
      NTmp:newsrec;
    Begin
      If nn=0 Then getnn('delete');
      If nn<>0 Then Begin
        Seek(nf,nn-1);
        Read(nf,Ntmp);che;
        deletetext(Ntmp.Location);
        numnews:=FileSize(nf)-1;
        For cnt:=nn To numnews Do
          Begin
            Seek(nf,cnt);
            Read(nf,nTmp);
            Seek(nf,cnt-1);
            Write(nf,Ntmp)
          End;
        Seek(nf,numnews);
        Truncate(nf)
      End
    End;

  Procedure listnews;
    Var cnt:Integer;
      r,sector:Integer;
      q:buffer;
      l:anystr;
      k:Char;
      Ntmp:newsrec;
    Begin
      clearbreak;
      WriteLn (^S'  News    Min    Max          Title ' ) ;
      WriteLn (^S' Number  Level  Level' ) ;
      WriteLn ;

      For cnt:=1 To numnews Do Begin
        Seek(nf,cnt-1);
        Read(nf,ntmp);r:=ntmp.location;
        Seek(tfile,r);
        Read(tfile,q);

        Write(^R, Cnt:5 , '    ' ,^V, ntmp.level:5,'  '^W,ntmp.maxlevel:5, ' ');
        r:=1;
        k:=' ';
        l:='';
        Writeln (^X,ntmp.title);
{        While (Ord(k)<>13) And Not hungupon Do Begin
          k:=q[r];
          r:=r+1;
          If (k=#0) Or (r>sectorsize) Then k:=Chr(13);
          l:=l+k
        End;
        Write(l);}
        If break Then exit
      End;
{      WriteLn                }
    End;

  Procedure viewnews;
    Var r:Integer;
      Ntmp:newsrec;
    Begin
      If nn=0 Then getnn('view');
      If nn<>0 Then Begin
        Seek(nf,nn-1);
        Read(nf,nTmp);che;
        r:=ntmp.location;
        WriteLn('News #',nn,' ''',ntmp.title,''' From :',ntmp.from);
        WriteLn('Date: ',Datestr(ntmp.when),' Level [',ntmp.level,'-',ntmp.maxlevel,']');
        WriteLn('__________________________');
        printtext(r)
      End
    End;

  Procedure Editone;
    Var r:Integer;
      Ntmp:newsrec;
    Begin
      If nn=0 Then getnn('change');
      If nn<>0 Then Begin
        Seek(nf,nn-1);
        Read(nf,nTmp);che;
        r:=ntmp.location;
        WriteLn('News #',nn,' ''',ntmp.title,''' From :',ntmp.from);
        WriteLn('Date: ',Datestr(ntmp.when),' Level [',ntmp.level,']');
        WriteLn('__________________________');
        ntmp.location:=edittext(r);
        Seek(nf,nn-1);
        Write(nf,ntmp);che;
      End
    End;

  Procedure adddnews;
    Begin
      Close(nf);
      addnews;
      Assign(nf,'News');
      Reset(nf)
    End;

  Var q:Integer;
  Begin
    Assign(nf,'News');
    Reset(nf);
    If IOResult<>0 Then writeln('No news!  Use ['^V'A'^R'] to add some!') Else Begin
      Repeat
        numnews:=FileSize(nf);
        Write(^B^M'News entries: '^S,numnews);
        q:=menu('News edit','NEWS','ADLVQE');
        nn:=valu(Copy(Input,2,255));
        If (nn<1) Or (nn>numnews) Then nn:=0;
        Case q Of
          1:adddnews;
          2:delnews;
          3:listnews;
          4:viewnews;
          6:editone;
        End;
        If numnews=0 Then Begin
          Close(nf);
          Erase(nf);
          writestr('No more news!  Use ['^V'A'^P'] to add some.');
          q:=5
        End
      Until (q=5) Or hungupon
    End;
    Close(nf)
  End;

Procedure Graph_line(Num,outof:Integer);
  Var a,b,cnt:Integer;
    D,e:anystr;
    Q,r:longint;
  Begin
    d:='';
    If 0=0 Then Begin
      If outof=0 Then q:=0 Else q:=(num*100) Div outof;
      Write(q:2,'% [ ');
      If q>0 Then q:=q Div 10;
      For cnt:=1 To 10 Do Begin
        If (q>cnt) Then Write('*') Else Write(' ');
      End;
      WriteLn(' ]  ',num:4,' of ',outof:4);
    End;
  End;

Procedure yourstatus;
  Var c:longint;
  Begin
    writehdr('User Status');

    WriteLn('User Name: '^S,unam);
    WriteLn('Level:     '^S,ulvl);
    WriteLn('File Level:'^S,urec.udlevel);
    WriteLn('Calls:     '^S,urec.numon);
    WriteLn('# of Msgs: '^S,urec.nbu);
    WriteLn('Total time on: '^S,urec.totaltime:0:0);
    WriteLn('Time Today:    '^S,timeleft);

    writehdr('File Xfer');
    WriteLn('  Uploads:     '^S,urec.uploads);
    WriteLn('  Downloads:   '^S,urec.downloads);
    WriteLn('  U/D Ratio:');
    graph_Line(urec.uploads,urec.downloads);
    c:=0;
    If (urec.numon>0) And (urec.nbu>0) Then c:=(urec.nbu*100) Div urec.numon;
    WriteLn('PostCall Ratio:'^S,c);
    Graph_Line(urec.nbu,urec.numon);
  End;

Procedure delerrlog;
  Var e:Text;
    i:Integer;
  Begin
    writestr('Delete error log:  Confirm:');
    If Not yes Then exit;
    Assign(e,'errlog');
    Reset(e);
    i:=IOResult;
    If IOResult=1
    Then WriteLn(^M'No error log!')
    Else Begin
      textclose(e);
      Erase(e);
      writestr('Error log deleted.');
      If IOResult>1
      Then WriteLn('I/O error ',i,' deleting error log!');
      writelog(2,2,'')
    End
  End;

Procedure feedback;
  Var m:mailrec;
    me:message;
  Begin
    writestr(^R'Leave a comment to the sysop? *');
    If Not yes Then exit;
    m.line:=editor(me,False,True);
    If m.line<0 Then exit;
    m.title:=me.title;
    m.sentby:=unam;
    m.anon:=False;
    m.when:=now;
    addfeedback(m);
  End;

Procedure settime;
  Var t:Integer;
    n:longint;
    r:registers;
    d:datetime;
  Begin
    writestr('Current time: '+^S+timestr(now));
    writestr('Current date: '+^S+datestr(now));
    writestr(^R'Enter new time:');
    If Length(Input)<>0
    Then Begin
      t:=timeleft;
      unpacktime(timeval(Input),d);
      r.ch:=d.hour;
      r.cl:=d.min;
      r.dh:=0;
      r.dl:=0;
      r.ah:=$2d;
      Intr($21,r);
      If r.al=$ff Then writestr(^S'Invalid time!');
      settimeleft(t)
    End;
    writestr('Enter new date:');
    If Length(Input)<>0
    Then Begin
      unpacktime(dateval(Input),d);
      r.dl:=d.day;
      r.dh:=d.month;
      r.cx:=d.year;
      r.ah:=$2b;
      Intr($21,r);
      If r.al=$ff Then writestr(^S'Invalid date!')
    End;
    writelog(2,4,'')
  End;


Procedure requestraise;
  Var t:Text;
    q:lstr;
    p,l1,l2:Integer;
    s1,s2:sstr;
    me:message;
    m:mailrec;
  Label nope,found;
  Begin
    Assign(t,textfiledir+'RAISEREQ');
    Reset(t);
    If IOResult<>0 Then GoTo nope;
    printtexttopoint(t);
    While Not EoF(t) Do Begin
      ReadLn(t,q);
      p:=Pos('-',q);
      If p>0
      Then
        Begin
          s1:=Copy(q,1,p-1);
          s2:=Copy(q,p+1,255)
        End
      Else
        Begin
          s1:=Copy(q,1,15);
          s2:=s1
        End;
      Val(s1,l1,p);
      If p=0 Then Val(s2,l2,p);
      If p<>0 Then Begin
        textclose(t);
        error('Invalid range in RAISEREQ: %1','',q);
        exit
      End;
      If (ulvl>=l1) And (ulvl<=l2) Then GoTo found;
      skiptopoint(t)
    End;
nope:
    error('No text for level %1','',strr(ulvl));
    textclose(t);
    p:=IOResult;
    exit;
found:
    printtexttopoint(t);
    textclose(t);
    If hungupon Then exit;
    m.line:=editor(me,False,False);
    If m.line<0 Then exit;
    m.anon:=False;
    m.title:='Raise request; now lvl='+^S+strr(ulvl);
    m.sentby:=unam;
    m.when:=now;
    addfeedback(m);
  End;

Procedure makeuser;
  Var u:userrec;
    un,Ln:Integer;
  Begin
    writehdr('Add a user');
    writestr('Name:');
    If Length(Input)=0 Then exit;
    If lookupuser(Input)<>0 Then Begin
      writestr('Sorry!  Already exists!');
      exit
    End;
    u.handle:=Input;
    writestr('Password:');
    u.password:=Input;
    writestr('Level:');
    If Length(Input)=0 Then exit;
    u.level:=valu(Input);
    if u.level>urec.level then u.level:=urec.level-1;
    un:=adduser(u);
    If un=-1 Then Begin
      writestr('Sorry, no room for new users!');
      exit
    End;
    Ln:=u.level;
    If Ln<1 Then Ln:=1;
    If Ln>100 Then Ln:=100;
    u.timetoday:=usertime[Ln];
    writeufile(u,un);
    writestr('User added as #'+^S+strr(un)+^P+'.');
    writelog(2,8,u.handle)
  End;

Procedure infoformhunt;
  Begin
    writestr('User to search for [CR=all users]:');
    WriteLn(^M);
    showinfoforms(Input)
  End;

Procedure donations;
  Var fn:lstr;
  Begin
    fn:=textfiledir+'Donation';
    If exist(fn)
    Then printfile(fn)
    Else Begin
      writestr('I''m sorry, no information is currently available.');
      If issysop
      Then writestr(
        'Sysop:  To create donation information text, make a file called '+^S+fn)
    End
  End;

Procedure viewsyslog;
  Var n:Integer;
    l:logrec;

  Function lookupsyslogdat(m,s:Integer):Integer;
    Var cnt:Integer;
    Begin
      For cnt:=1 To numsyslogdat Do With syslogdat[cnt] Do
        If (menu=m) And (subcommand=s) Then Begin
          lookupsyslogdat:=cnt;
          exit
        End;
      lookupsyslogdat:=0
    End;

  Function firstentry:Boolean;
    Begin
      firstentry:=(l.menu=0) And (l.subcommand In [1..2])
    End;

  Procedure backup;
    Begin
      While n<>0 Do Begin
        n:=n-1;
        Seek(logfile,n);
        Read(logfile,l);
        If firstentry Then exit
      End;
      n:=-1
    End;

  Procedure showentry(includedate:Boolean);
    Var q:lstr;
      p:Integer;
    Begin
      q:=syslogdat[lookupsyslogdat(l.menu,l.subcommand)].text;
      p:=Pos('%',q);
      If p<>0 Then q:=Copy(q,1,p-1)+l.param+Copy(q,p+1,255);
      If includedate Then q:=q+^V+' on '+^W+datestr(l.when);
      q:=q+^X+' at '+timestr(l.when);
      WriteLn(q)
    End;

  Var b:Boolean;
  Begin
    writehdr('List system log');
    WriteLn('[Space] to skip user, [X] to abort');
    WriteLn;
    writelog(2,6,'');
    n:=FileSize(logfile);
    Repeat
      clearbreak;
      WriteLn(^M);
      backup;
      If n=-1 Then exit;
      Seek(logfile,n);
      Read(logfile,l);
      showentry(True);
      b:=False;
      While Not(EoF(logfile) Or break Or xpressed Or b) Do Begin
        Read(logfile,l);
        b:=firstentry;
        If Not b Then showentry(False);
      End
    Until xpressed
  End;

Procedure delsyslog;
  Begin
  if urec.level<sysoplevel then exit;
    writestr('Delete system log: Confirm:');
    If Not yes Then exit;
    Close(logfile);
    Rewrite(logfile);
    WriteLn(^M'System log deleted.');
    writelog(2,7,unam)
  End;

  procedure make_Leech_list;

      type HighestPCR=record
             Name:mstr;
             PCR:longint;
             end;


  var a,b,c,d,e,cnt,UptoDown:longint;
  done:boolean;
      TMPrec:userrec;
      Posters:array [1..10] of highestpcr;
      LamePosters:array [1..10] of highestpcr;
      Uploaders:array [1..10] of highestpcr;
      LameUploaders:array [1..10] of highestpcr;
      Downloaders:array [1..10] of highestpcr;
      LameDownloaders:array [1..10] of highestpcr;

      TmpPost:highestpcr;


     begin
     Writehdr ('Calculating Statistics');

       for cnt:=1 to 10 do begin
        Posters[cnt].pcr:=0;
        posters[cnt].name:='';
        lamePosters[cnt].pcr:=maxint;
        lameposters[cnt].name:='';
        Downloaders[cnt].pcr:=0;
        downloaders[cnt].name:='';
        lamedownloaders[cnt].pcr:=maxint;
        lamedownloaders[cnt].name:='';
               uploaders[cnt].pcr:=0;
        uploaders[cnt].name:='';
        lameuploaders[cnt].pcr:=maxint;
        lameuploaders[cnt].name:='';

       end;
     for cnt:=3 to numusers do begin
      seek(ufile,cnt-1);
      read(ufile,TmpRec);

      if tmprec.revision<>2 then begin
        tmprec.revision:=2;
        tmprec.kuploaded:=0;
        tmprec.kdownloaded:=0;
        seek(ufile,cnt-1);
        write(ufile,tmpreC);
      end;

        if tmprec.numon>1 then begin

        if tmprec.numon>0 then  d:=(tmprec.nbu*100) div tmprec.numon else d:=0;



      if d>0 then  begin
                          done:=false;
                for e:=1 to 10 do begin
                 if (done=false) and (posters[e].pcr<d) then begin  { sort }
                    if e<10 then begin
                      for a:=9 downto e do begin
                        posters[a+1]:=posters[a];
                      end;
                    end;
                   posters[e].pcr:=d;
                   posters[e].name:=tmprec.handle;
                  Done:=true;
                 end;
         end;
       end;

        begin
                          done:=false;
                for e:=1 to 10 do begin
                 if (done=false) and (lameposters[e].pcr>d) then begin  { sort }
                    if e>1 then begin
                      for a:=9 downto e do begin
                        lameposters[a+1]:=lameposters[a];
                      end;
                    end;
                   lameposters[e].pcr:=d;
                   lameposters[e].name:=tmprec.handle;
                  Done:=true;
                 end;
         end;
       end;

d:=tmprec.kuploaded;

      if d>0 then  begin
                          done:=false;
                for e:=1 to 10 do begin
                 if (done=false) and (Uploaders[e].pcr<d) then begin  { sort }
                    if e<10 then begin
                      for a:=9 downto e do begin
                        Uploaders[a+1]:=uploaders[a];
                      end;
                    end;
                   uploaders[e].pcr:=d;
                   uploaders[e].name:=tmprec.handle;
                  Done:=true;
                 end;
         end;
       end;

        begin
                          done:=false;
                for e:=1 to 10 do begin
                 if (done=false) and (lameuploaders[e].pcr>d) then begin  { sort }
                    if e>1 then begin
                      for a:=9 downto e do begin
                        lameuploaders[a+1]:=lameuploaders[a];
                      end;
                    end;
                   lameuploaders[e].pcr:=d;
                   lameuploaders[e].name:=tmprec.handle;
                  Done:=true;
                 end;
         end;
       end;
d:=tmprec.kdownloaded;

      if d>0 then  begin
                          done:=false;
                for e:=1 to 10 do begin
                 if (done=false) and (downloaders[e].pcr<d) then begin  { sort }
                    if e<10 then begin
                      for a:=9 downto e do begin
                        downloaders[a+1]:=downloaders[a];
                      end;
                    end;
                   downloaders[e].pcr:=d;
                   downloaders[e].name:=tmprec.handle;
                  Done:=true;
                 end;
         end;
       end;

        begin
                          done:=false;
                for e:=1 to 10 do begin
                 if (done=false) and (lamedownloaders[e].pcr>d) then begin  { sort }
                    if e>1 then begin
                      for a:=9 downto e do begin
                        lamedownloaders[a+1]:=lamedownloaders[a];
                      end;
                    end;
                   lamedownloaders[e].pcr:=d;
                   lamedownloaders[e].name:=tmprec.handle;
                  Done:=true;
                 end;
         end;
       end;

      end;
     end;

     Writehdr ('Top 10 PCR ratio');
     for cnt:=1 to 10 do begin
       tab ( (Strr(cnt)+'.') ,4);
       tab (posters[cnt].name,25);
       writeln (posters[cnt].pcr:3,'%');
     end;

     Writehdr ('Top 10 Lamerz Lowest PCR ratio');
     for cnt:=1 to 10 do begin
       tab ( (Strr(cnt)+'.') ,4);
       tab (lameposters[cnt].name,25);
       writeln (lameposters[cnt].pcr:3,'%');
     end;
writestr (^R'Press [Return] to continue :');

     Writehdr ('Top 10 Uploads (in K)');
     for cnt:=1 to 10 do begin
       tab ( (Strr(cnt)+'.') ,4);
       tab (uploaders[cnt].name,25);
       writeln (uploaders[cnt].pcr:3,'K');
     end;

     Writehdr ('Lowest 10 Lamerz by Upload(in K)');
     for cnt:=1 to 10 do begin
       tab ( (Strr(cnt)+'.') ,4);
       tab (lameuploaders[cnt].name,25);
       writeln (lameuploaders[cnt].pcr:3,'K');
     end;
writestr ('Press [Return] to continue :');


     Writehdr ('Top 10 Leeches/downloaders (in K)');
     for cnt:=1 to 10 do begin
       tab ( (Strr(cnt)+'.') ,4);
       tab (downloaders[cnt].name,25);
       writeln (downloaders[cnt].pcr:3,'K');
     end;

     Writehdr ('Lowest 10 Downloaders (in K)');
     for cnt:=1 to 10 do begin
       tab ( (Strr(cnt)+'.') ,4);
       tab (lamedownloaders[cnt].name,25);
       writeln (lamedownloaders[cnt].pcr:3,'K');
     end;
      writestr ('Press [Return] to continue :');

end;


Procedure showsystemstatus;
  Var totalused,totalidle,totalup,totaldown,totalmins,callsday:Real;

  Procedure percent(prompt:mstr;top,bot:Real);
    Var p:Real;
    Begin
      Write(prompt);
      If bot<1 Then Begin
        WriteLn('N/A');
        exit
      End;
      p:=Round(1000*top/bot)/10;
      WriteLn(p:0:1,'%')
    End;

  Begin
    totalused:=numminsused.total+elapsedtime(numminsused);
    totalidle:=numminsidle.total;
    totalup:=totalidle+numminsused.total;
    totalmins:=1440.0*(numdaysup-1.0)+timer;
    totaldown:=totalmins-totalup;
    callsday:=Round(10*numcallers/numdaysup)/10;
    writehdr('System Status');
    WriteLn(versionnum);
    Write('Calls today:       '^S,callstoday);
    If callstoday>callsday Then WriteLn(^P' <- Above Average!') Else WriteLn;
    WriteLn('Call So Far:       '^S,numcallers:0:0);
    WriteLn('# of Days on-line: '^S,numdaysup);
    WriteLn('Daily Calls Avg.:  '^S,callsday:0:1);
    WriteLn('Actual Minutes Use:'^S,numminsused.total:0:0);
    WriteLn('# of Mins. Waiting:'^S,totalidle:0:0);
    WriteLn('# of Mins. Xfer:   '^S,numminsxfer.total:0:0);
    percent('System Usage %:    '^S,totalused,totalmins);
    WriteLn('Total # of Uploads:'^s,Totalfiles);
    WriteLn('Total # of Message:'^s,totalposts);
  End;

  procedure GET_TIME_BANK;
  var MUCH,cnt:integer;

    begin
    cnt:=urec.TimeBank;
    if cnt>255 then cnt:=255;
    Writehdr ('Time Bank Withdrawal');
    Writeln (^M^M'Time Left Today :'^S,timeleft);
    Writeln (    'Time deposits   :'^S,cnt);
    if cnt<1 then writeln (^S'** You are BROKE! ** ');
    Writestr ('Withdraw how much? [0-'+^v+strr( (cnt ))+^P+'] [0] :');
    if input='' then exit;
    much:=valu(input); if (much<1) or (much>( cnt)) then exit;
    urec.timebank:=urec.timebank-much;
    settimeleft (timeleft+much);
    Writeln (^P'Your new time left today = '^S,timelefT);
    writeln (^P'New Time Bank Balance    = '^S,urec.timebank);
    writeurec;

    end;

  procedure PUT_TIME_BANK;
  var MUCH,cnt:integer;

    begin
    cnt:=urec.TimeBank;
    Writehdr ('Time Bank Deposit');
    Writeln (^M^M'Time Left Today :'^S,timeleft);
    Writeln (    'Time deposits   :'^S,cnt);
    Writestr ('Deposit how much? [0-'+^V+strr((timeleft div 2))+^P+'] [0] :');
    if input='' then exit;
    much:=valu(input); if (much<1) or (much>(timeleft div 2)) then exit;
    urec.timebank:=urec.timebank+much;
    settimeleft (timeleft-much);
    Writeln (^P'Your new time left today = '^S,timelefT);
    writeln (^P'New Time Bank Balance    = '^S,urec.timebank);
    writeurec;

    end;

Procedure showallforms;
  Begin
    showinfoforms('')
  End;

Procedure showallsysops;
  Var n:Integer;
    u:userrec;
    q:Set Of configtype;
    s:configtype;

  Procedure showuser;
    Const sectionnames:Array[udsysop..databasesysop] Of String[20]=
      ('File transfer','Message Base','Voting booths',
      'E-mail section','Doors','Main menu','Databases');
    Var s:configtype;
    Begin
      WriteLn(^B^M'Name:  '^S,u.handle,
      ^M'Level: '^S,u.level,^M);
      For s:=udsysop To databasesysop Do
        If s In u.config Then
          WriteLn('Sysop of the '^V,sectionnames[s]);
      writestr(^M'Edit user? *');
      If yes Then edituser(n)
    End;

  Begin
    q:=[];
    For s:=udsysop To databasesysop Do q:=q+[s];
    For n:=1 To numusers Do Begin
      Seek(ufile,n);
      Read(ufile,u);
      If (u.level>=sysoplevel) Or (q*u.config<>[]) Then showuser
    End
  End;



procedure listarumor;

var card,ugbot,p:lstr;
    b:rumorrec;
    aafile:file of rumorrec;
   the, cc:integer;
   function numrumors:integer;
   begin
     numrumors:=filesize(aafile)
   end;

   procedure seekaafile (n:integer);
   begin
     seek (aafile,n-1);
   end;
begin
randomize;
if not exist('rumors.emx') then exit;
assign (aafile,'Rumors.emx');
reset(aafile);
cc:=filesize(aafile);

if cc>0 then begin
         the:=random(cc)+1;
         seekaafile(the);
         read(aafile,b);
         writeln(^R'"'^V+b.data+^R'"');
        end;
        close(aafile);

end;


  procedure rumors(func:integer);

var card,ugbot,p:lstr;
    b:rumorrec;
    rrfile:file of rumorrec;

   function numrumors:integer;
   begin
     numrumors:=filesize(RRFILE)
   end;

   procedure seekRRFILE (n:integer);
   begin
     seek (RRFILE,n-1);
   end;

   function numrumor:integer;
   begin
     numrumor:=filesize (RRFILE);
   end;

   procedure getstring (t:lstr; var m; buf:integer);
   var q:lstr absolute m;
       mm:lstr;
   begin
     writeln (^R'Old '^V,t,^R': '^V,q,^R);
     buflen:=buf;
     writestr ('Enter new '+^S+t+^P+' [CR/no change]:');
     mm:=input;
     if length(mm)<>0 then q:=mm;
     writeln
   end;

    procedure listrumor;
    var cnt,b1,b2:integer;
        showedz:boolean;
    begin
     writehdr ('List quotes');
     close (rrfile);
     if not ( exist('Rumors.emx')) then begin
      writeln (^S'There are no quotes! you may add your own!');
      exit;
     end
     else begin
          reset (RRFILE);

     parserange (numrumor,b1,b2);
     writeln;
     showedz:=false;

writehdr ('Emulex/2 quotes');
Writeln (
^B'[_Quote_Title__________________Sent By_________________Date_________________]');

     if b1>0 then
     for cnt := b1 to b2 do
     begin
     if xpressed then exit;
      seekRRFILE (cnt);
      read (RRFILE,b);

      write (^R'['^V);
      tab (b.title ,28);
      write (^R'] ['^W);
      tab (b.sentby,20);
      write (^R'] ['^X);
      tab (b.dateby,10);
      writeln (^R']');
      Write(^V'"'^R);
      tab (b.data,77);
      writeln(^V'"');
     end;
    end;
    end;

    procedure addrumor;
    begin
     writehdr ('Add a quote');
     writeln (^R'quote Title');
     buflen:=28;
     writestr (': &');
     b.title:=input;
     writeln;
     writeln (^R'Enter quote');
     buflen:=78;
     writestr (': &');
     b.data:=input;
     writeln;
     b.dateby:=datestr(now);
     b.sentby:=unam;
     if ((length(b.title)>0) and (length(b.data)>0)) then begin
     close(rrfile);che;
      if not exist ('rumors.EMX') then rewrite (RRFILE) else reset(rrfile);
      seekRRFILE (numrumors+1);
      write (RRFILE,b);
      writeln (^M^S'quote Added!'^R^M);
     end else
     writeln (^M^S'Bad Entry!'^R^M);
     end;


  procedure changerumor;
  var q,spock:integer;
      doodzdomain:char;

   procedure showrumor (b:rumorrec);
   begin
   writeln (^M^R'[1]... Name:     '^S,b.sentby,
            ^M^R'[2]... Title:   '^S,b.title,
            ^M^R'[3]... quote:',
            ^M^R': '^S,b.data,
            ^M^R'[Q]... Quit');
   end;

   begin
       writehdr ('Change an Entry');
       listrumor;
       writestr (^M'Entry to Change [?]: &');
       if input[1]='?' then listrumor;
       spock:=valu(input);
       if spock<1 then exit;
       if spock>numrumor then exit;
       close(rrfile);reset(rrfile);
       seekRRFILE (spock);
       read (RRFILE,b);
       if not (match (b.sentby,unam)) then begin
        writeln (^M'You didn''t make the entry!'^M);
        exit;
       end;
       repeat
       showrumor (b);
       writestr ('Edit Command: *');
       doodzdomain:=upcase(input[1]);
       case doodzdomain of
        '1':if ulvl>=sysoplevel then getstring ('SentBy',b.sentby,28);
        '2':getstring ('Title',b.title,40);
        '3':begin
             writeln ('quote:');
             writeln ('> ',b.data);
             writeln ('Enter new Description [Return:no change]:');
             buflen:=77;
             writestr ('> &');
             if length(input)<>0 then b.data:=input;
             writeln
            end;
        'Q':;
       end;
       until doodzdomain='Q';
       write (RRFILE,b);
      end;

    Procedure Deleterumor;
      Var bud,cnt,n:Integer;
        f:File;
        KKOOL:rumorrec;
      Begin
      Writehdr ('Delete a quote');
       Writestr ('quote # to delete? :');
       if input='' then exit;
       bud:=valu(input);
       if bud>numrumor then exit;
       n:=bud;
        If n=0 Then exit;
     seek (rrfile,n-1);
     read (rrfile,kkool);

        writestr('Delete '+kkool.title+'? *');
        if ((match (unam,kkool.sentby))=false) and (issysop=false) then exit;

        If Not yes Then exit;

        For cnt:=n+1 To numrumor Do Begin
          seekrrfile(cnt);
          Read(rrfile,kkool);
          seekrrfile(cnt-1);
          Write(rrfile,kkool)
        End;

        seekrrfile(numrumor);
        Truncate(rrfile);
        writestr(^M'Deleted.');
      End;

  procedure rumorlistsysop;
  begin
     writeln;
     repeat
      ugbot:=' ';
      writeln  (^R'['^S'D'^R']elete an Entry');
      writeln  (^R'['^S'C'^R']hange an Entry');
      writeln  (^R'['^S'Q'^R']uit');
      writestr ('[quote List Sysop Command]:');
      ugbot:=upstring(input);
      case ugbot[1] of
       'D':deleterumor;
       'C':changerumor;
       'Q':;
      end;
     until (ugbot[1]='Q');
    end;
procedure loadrumorstocache;

    var the,cc:integer;
begin
if numrumors<1 then exit;
for cc:=1 to numrumors do begin
         seekrrfile(the);
         read(rrfile,b);
end;
end;


label exit;
var q:integer;
begin
    assign (RRFILE,'rumors.emx');
    if exist('rumors.emx') then reset(rrfile) else rewrite(rrfile);

    if func=1 then goto exit;

    repeat
     q:=menu ('Quotes','rumorlIST','LADC%QI');
     writeln;
     case q of
      1:listrumor;
      2:addrumor;
      3:deleterumor;
      4:changerumor;
      5:rumorlistsysop;
      6:goto exit;
     end;
     until (hungupon) or (q=6);
    exit:
    close (RRFILE);
end;

Procedure mainhelp;
  Begin
    help('Mainmenu.hlp')
  End;




procedure otherbbs;

var card,ugbot,p:lstr;
    b:bbsrec;

   function numbbses:integer;
   begin
     numbbses:=filesize(blfile)
   end;

   procedure seekblfile (n:integer);
   begin
     seek (blfile,n-1);
   end;

   function numbbs:integer;
   begin
     numbbs:=filesize (blfile);
   end;

   procedure getstring (t:lstr; var m; buf:integer);
   var q:lstr absolute m;
       mm:lstr;
   begin
     writeln (^R'Old '^V,t,^R': '^S,q,^R);
     buflen:=buf;
     writestr ('Enter new '+^V+t+^P+' [CR/no change]:');
     mm:=input;
     if length(mm)<>0 then q:=mm;
     writeln
   end;

    procedure listbbs;
    var cnt,b1,b2:integer;
        showedz:boolean;
    begin
     writehdr ('BBS List');
     reset (blfile);
     if ioresult<>0 then begin
      writeln ('There are no bbs! you may add your own!');
      exit;
     end
     else begin
     parserange (numbbs,b1,b2);
     writestr ('Display complete Description [y/n]? *');
     writeln;
     showedz:=true;
     if upcase(input[1])='N' then showedz:=false;
writehdr ('Emulex/2 bbs listing');
Writeln (
^B'[_BBS_NUMBER______________________BBS_NAME________________________BAUD__BBS__]');

     if b1>0 then
     for cnt := b1 to b2 do
     begin
     if xpressed then exit;
      seekblfile (cnt);
      read (blfile,b);

      write (^R'['^S);
      tab (b.number,12);
      write (^R'] ['^P);
      tab (b.name,48);
      write (^R'] ['^U);
      tab (b.maxbaud,4);
      write (^R'] ['^P);
      tab (b.ware,4);
      writeln (^R']');
      if showedz then
      begin
       write (^R' ['^U);
       tab (b.extdesc,76);
       writeln (^R']');
      end;
     end;
    end;
    end;

    procedure addbbs;
    begin
     writehdr ('Add a BBS #');
     writeln (^R'Phone Number');
     buflen:=12;
     writestr (': &');
     b.number:=input;
     writeln;
     writeln (^R'BBS Name ');
     buflen:=48;
     writestr (': &');
     b.name:=input;
     writeln;
     writeln (^R'Highest Baud rate');
     buflen:=4;
     writestr (': &');
     b.maxbaud:=input;
     writeln;
     writeln (^R'Software (Emulex of course!)');
     buflen:=4;
     writestr (': &');
     b.ware:=input;
     writeln;
     writeln (^R'Comment');
     buflen:=77;
     writestr (': &');
     b.extdesc:=input;
     b.leftby:=unam;
     if (length(b.number)>0) and (length(b.name)>0) and (length(b.maxbaud)>0)
     and (length(b.ware)>0) then begin
      if not exist ('BBSList.EMX') then rewrite (blfile) ;
      seekblfile (numbbses+1);
      write (blfile,b);
      writeln (^M^S'Entry Added!'^R^M);
     end else
     writeln (^M^S'Bad Entry!'^R^M);
     end;

    procedure Importaddbbs;
    var CC:integer;
    TB:text;
    La:Lstr;
    begin

    if exist('pirate.bbs') then begin
    assign (tb,'pirate.bbs');

     reset(tb);
     writehdr ('Import Pirate.BBS');

     while (not eof(tb)) do begin

     readln (tb,la);
     Writeln (la);

     if (length(la)>60) and (la[1]<>' ') then begin

     b.number:=copy(la,1,13);
     b.name:=copy  (la,16,17);
     b.maxbaud:=copy (la,56,4);
     b.ware:=copy (la,50,4);
     b.extdesc:=copy (la,63,(Length(la)-62));
     b.leftby:=unam;

     if (length(b.number)>0) and (length(b.name)>0) and (length(b.maxbaud)>0)
     and (length(b.ware)>0) then begin

      if not exist ('BBSList.EMX') then rewrite (blfile);
      seekblfile (numbbses+1);
      write (blfile,b);
      writeln (^M^S'Entry Added!'^R^M);
      end;
     end;
     end; {while}
         textclose(Tb);
       end;
     end;

  procedure changebbs;
  var q,spock:integer;
      doodzdomain:char;

   procedure showbbs (b:bbsrec);
   begin
   writeln (^M^R'[1]... Name:     '^S,b.name,
            ^M^R'[2]... Number:   '^S,b.number,
            ^M^R'[3]... Max Baud:     '^S,b.maxbaud,
            ^M^R'[4]... Software: '^S,b.ware,
            ^M^R'[5]... Description:',
            ^M^R': '^S,b.extdesc,
            ^M^R'[Q]... Quit');
   end;

   begin
       writehdr ('Change an Entry');
       listbbs;
       writestr (^M'Entry to Change [?]: &');
       if input[1]='?' then listbbs;
       spock:=valu(input);
       if spock<1 then exit;
       if spock>numbbs then exit;
       seekblfile (spock);
       read (blfile,b);
       if not (match (b.leftby,unam)) then begin
        writeln (^M'You didn''t make the entry!'^M);
        exit;
       end;
       repeat
       showbbs (b);
       writestr ('Edit Command: *');
       doodzdomain:=upcase(input[1]);
       case doodzdomain of
        '1':getstring ('Name',b.name,48);
        '2':getstring ('Number',b.number,12);
        '3':getstring ('Max Baud',b.maxbaud,4);
        '4':getstring ('Software',b.ware,4);
        '5':begin
             writeln ('Description:');
             writeln ('> ',b.extdesc);
             writeln ('Enter new Description [Return:no change]:');
             buflen:=77;
             writestr ('> &');
             if length(input)<>0 then b.extdesc:=input;
             writeln
            end;
        'Q':;
       end;
       until doodzdomain='Q';
       write (blfile,b);
       close (blfile);

      end;

    Procedure Deletebbs;
      Var bud,cnt,n:Integer;
        f:File;
        KKOOL:bbsrec;
      Begin
      Writehdr ('Delete a BBS');
       Writestr ('BBS record # to delete? :');
       if input='' then exit;
       bud:=valu(input);
       if bud>numbbs then exit;
       n:=bud;
        If n=0 Then exit;
     seek (blfile,n-1);
     read (blfile,kkool);

        writestr('Delete '+^S+kkool.name+^P+'? *');
        if ((match (unam,kkool.leftby))=false) and (issysop=false) then exit;

        If Not yes Then exit;

        For cnt:=n+1 To numbbs Do Begin
          seekblfile(cnt);
          Read(blfile,kkool);
          seekblfile(cnt-1);
          Write(blfile,kkool)
        End;

        seekblfile(numbbs);
        Truncate(blfile);
        writestr(^M'Deleted.');
      End;


  procedure bbslistsysop;
  begin
     writeln;
     repeat
      ugbot:=' ';
      writeln  (^R'['^S'D'^R']elete an Entry');
      writeln  (^R'['^S'C'^R']hange an Entry');
  {    writeln  (^R'['^S'S'^R']ort Entries');}
    { writeln  (^R'['^S'T'^R']Textfile'); }
      Writeln  (^R'['^S'I'^R']mport from Elemental Pirate.BBS');
      writeln  (^R'['^S'Q'^R']uit');
      writestr ('[BBS List Sysop Command]:');
      ugbot:=upstring(input);
      case ugbot[1] of
       'D':deletebbs;
       'C':changebbs;
       'I':importaddbbs;
       'S':begin
           end;
       'T':begin
           end;
       'Q':;
      end;
     until (ugbot[1]='Q');
    end;

label exit;
var q:integer;
begin
    assign (blfile,'BBSList.emx');
    repeat
     q:=menu ('BBS List','BBSLIST','LADC%QI');
     writeln;
     case q of
      1:listbbs;
      2:addbbs;
      3:deletebbs;
      4:changebbs;
      5:bbslistsysop;
      6:goto exit;
     end;
     until (hungupon) or (q=6);
    exit:
    close (blfile);
end;


Procedure readerrlog;
  Begin
    If exist('Errlog')
    Then printfile('Errlog')
    Else writestr('No error file!')
  End;

Procedure showad;
  Var fn:lstr;
  Begin
    fn:=textfiledir+'SellMe';
    If exist(fn) Then printfile(fn)
  End;

Procedure setlastcall;

  Function digit(k:Char):Boolean;
    Begin
      digit:=Ord(k) In [48..57]
    End;

  Function validtime(inp:sstr):Boolean;
    Var c,s,l:Integer;
      d1,d2,d3,d4:Char;
      ap,m:Char;
    Begin
      validtime:=False;
      l:=Length(inp);
      If (l<7) Or (l>8) Then exit;
      c:=Pos(':',inp);
      If c<>l-5 Then exit;
      s:=Pos(' ',inp);
      If s<>l-2 Then exit;
      d2:=inp[c-1];
      If l=7
      Then d1:='0'
      Else d1:=inp[1];
      d3:=inp[c+1];
      d4:=inp[c+2];
      ap:=UpCase(inp[s+1]);
      m:=UpCase(inp[s+2]);
      If d1='1' Then If d2>'2' Then d2:='!';
      If (d1>='0') And (d1<='1') And digit(d2) And (d3>='0') And (d3<='5')
      And digit(d4) And ((ap='A') Or (ap='P')) And (m='M')
      Then validtime:=True
    End;

  Function validdate(inp:sstr):Boolean;
    Var k,l:Char;

    Function gchar:Char;
      Begin
        If Length(inp)=0 Then Begin
          gchar:='?';
          exit
        End;
        gchar:=inp[1];
        Delete(inp,1,1)
      End;

    Begin
      validdate:=False;
      k:=gchar;
      l:=gchar;
      If Not digit(k) Then exit;
      If l='/'
      Then If k='0'
        Then exit
        Else
      Else Begin
        If k>'1' Then exit;
        If Not digit(l) Then exit;
        If (l>'2') And (k='1') Then exit;
        l:=gchar;
        If l<>'/' Then exit
      End;
      k:=gchar;
      l:=gchar;
      If l='/'
      Then If k='0'
        Then exit
        Else
      Else Begin
        If k>'3' Then exit;
        If Not digit(l) Then exit;
        If (k='3') And (l>'1') Then exit;
        l:=gchar;
        If l<>'/' Then exit
      End;
      If digit(gchar) And digit(gchar) Then validdate:=True
    End;

  Begin
    WriteLn(^M'Your last call was: '^S,datestr(laston),^R' at '^S,timestr(laston));
    writestr(^M'Enter new newscan date (mm/dd/yy):');
    If Length(Input)>0
    Then If validdate(Input)
      Then laston:=dateval(Input)+timepart(laston)
      Else writestr('Invalid date!');
    writestr(^M'Enter new time (hh:mm am/pm):');
    If Length(Input)>0
    Then If validtime(Input)
      Then laston:=timeval(Input)+datepart(laston)
      Else writestr('Invalid time!')
  End;

Procedure removeallforms;
  Var cnt,ndel:Integer;
    u:userrec;
  Begin
    writestr('Erase ALL info-forms:  Are you sure? *');
    If Not yes Then exit;
    writeurec;
    writestr(^M'Erasing... please stand by...');
    ndel:=0;
    For cnt:=1 To numusers Do Begin
      If (cnt Mod 10)=0 Then Write(^V,cnt,', ');
      Seek(ufile,cnt);
      Read(ufile,u);
      If u.infoform>=0 Then Begin
        deletetext(u.infoform);
        u.infoform:=-1;
        Seek(ufile,cnt);
        Write(ufile,u);
        ndel:=ndel+1
      End
    End;
    WriteLn('done.');
    writestr(^M'All '+^S+strr(ndel)+^R+' forms erased.');
    readurec
  End;

Procedure readfeedback;
  Var ffile:File Of mailrec;
    m:mailrec;
    me:message;
    cur:Integer;

  Function nummessages:Integer;
    Begin
      nummessages:=FileSize(ffile)
    End;

  Function checkcur:Boolean;
    Begin
      If Length(Input)>1 Then cur:=valu(Copy(Input,2,255));
      If (cur<1) Or (cur>nummessages) Then Begin
        writestr(^M'Message out of range!');
        cur:=0;
        checkcur:=True
      End Else Begin
        checkcur:=False;
        Seek(ffile,cur-1);
        Read(ffile,m)
      End
    End;

  Procedure readnum(n:Integer);
    Begin
      cur:=n;
      Input:='';
      If checkcur Then exit;
      WriteLn(^B^M'Message: '^S,cur,
      ^M'Subject:   '^S,m.title,
      ^M'From   : '^S,m.sentby,
      ^M'Date   : '^S,datestr(m.when),' at ',timestr(m.when),^M);
      If break Then exit;
      printtext(m.line)
    End;

  Procedure writecurmsg;
    Begin
      If (cur<1) Or (cur>nummessages) Then cur:=0;
      Write(^B^M'[#'^W,cur,^R'] [Current msg: '^S);
      If cur=0 Then Write('None]') Else Begin
        Seek(ffile,cur-1);
        Read(ffile,m);
        Write(m.title,' from ',m.sentby,']')
      End
    End;

  Procedure delfeedback;
    Var cnt:Integer;
    Begin
      If checkcur Then exit;
      deletetext(m.line);
      For cnt:=cur To nummessages-1 Do Begin
        Seek(ffile,cnt);
        Read(ffile,m);
        Seek(ffile,cnt-1);
        Write(ffile,m)
      End;
      Seek(ffile,nummessages-1);
      Truncate(ffile);
      cur:=cur-1
    End;

  Procedure editusr;
    Var n:Integer;
    Begin
      If checkcur Then exit;
      n:=lookupuser(m.sentby);
      If n=0
      Then writestr('User disappeared!')
      Else edituser(n)
    End;

  Procedure infoform;
    Begin
      If checkcur Then exit;
      showinfoforms(m.sentby)
    End;

  Procedure nextfeedback;
    Begin
      cur:=cur+1;
      If cur>nummessages Then Begin
        writestr(^M'Sorry, no more feedback!');
        cur:=0;
        exit
      End;
      readnum(cur)
    End;

  Procedure readagain;
    Begin
      If checkcur Then exit;
      readnum(cur)
    End;

  Procedure replyfeedback;
  var Passer:anystr;
    Begin
    passer:=m.sentby;
      If checkcur Then exit;
      sendmailto(passer,False);
    End;

  Procedure listfeedback;
    Var cnt:Integer;
    Begin
      If nummessages=0 Then exit;
      thereare(nummessages,'piece of feedback','pieces of feedback');
      If break Then exit;
      WriteLn(^M'#   Subject                        From   '^M);
      Seek(ffile,0);
      For cnt:=1 To nummessages Do Begin
        Read(ffile,m);
        tab(strr(cnt),4);
        If break Then exit;
        tab(m.title,31);
        WriteLn(m.sentby);
        If break Then exit
      End
    End;
    Procedure fix_user_Index;
      Var cnt:Integer;
      var u:userrec;
      n:integer;
      Begin
      Writehdr ('Recreating User Index');
      close (uhfile);
        Rewrite(uhfile);
        If IOResult<>0 Then Begin
          WriteLn(Usr,'Unable to re-create user index file.');
          Halt(1)
        End;

        Seek(ufile,0);

        While Not EoF(ufile) Do Begin
          Read(ufile,u);
          Write(uhfile,u.handle)
        End
      End;

  Var q:Integer;
  Label exit;
  Begin
    Assign(ffile,'Feedback');
    Reset(ffile);
    If IOResult<>0 Then Rewrite(ffile);
    cur:=0;
    Repeat
      If nummessages=0 Then Begin
        writestr('Sorry, no feedback!');
        GoTo exit
      End;{listfeed}
      writecurmsg;

      If (urec.emulation=0) And (Ansigraphics In urec.config) Then

        If WhereY>22 Then Begin ansigotoxy(1,24);WriteLn(^M^M);ansigotoxy(1,22);
        End;

      q:=menu('Feedback','FEED','Q#DEIR_AL!');
      If q<0
      Then readnum(-q)
      Else Case q Of
        3:delfeedback;
        4:editusr;
        5:infoform;
        6:replyfeedback;
        7:nextfeedback;
        8:readagain;
        9:listfeedback;
        10:fix_user_index;
      End
    Until (q=1) Or hungupon;
exit:
    Close(ffile)
  End;

Begin
End.
