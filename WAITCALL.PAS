  {$R-,S-,I-,D-,F+,V-,B-,N-,L+,O+ }

  unit waitcall;

  Interface

  uses dos,crt,
  gentypes,statret,configrt,modem,gensubs,subs1,subs2,mailret,mainmenu,userret,
  overret1,mainr1,mainr2,newnet;

  Function waitforacall:Boolean;

  Implementation

Function waitforacall:Boolean;

  Var wscount:Integer;
    mustgetbaud:Boolean;
    WhichStatus:Byte;
  Procedure maybewritestatus;
    Begin
      inc(wscount);
      If wscount>20 Then Begin
        writestatus;
        wscount:=0
      End
    End;


  Function checkforhayesreport:Boolean;{ Looks for CONNECT 300 }
    Var n:longint;
      q:lstr;
      p,b:Integer;
      k:Char;
      bd,brate:baudratetype;
    Begin
      WriteLn(Usr,'[ Hayes Result Detection ]');
      Delay(200);

      q:='';k:=' ';

      bd:=b110;

      While (numchars>0) And (Length(q)<99) Do Begin
      k:=getchar;q:=q+k;End;
      Delay(666);
      While (numchars>0) And (Length(q)<150) Do Begin
      k:=getchar;q:=q+k;End;


      WriteLn(Usr,^M'Modem Detect result code ->',q);
      if defbaudrate=19200 then writeln (usr,'[] 19.2k Lock-In Mode []');
      If Not carrier Then exit;

      if defbaudrate=19200 then bd:=b19200 else begin


      If Pos('5',q)>0  Then bd:=b1200;
      If Pos('10',q)>0 Then bd:=b2400;
      If Pos('12',q)>0 Then bd:=b1200;
      If Pos('24',q)>0 Then bd:=b2400;
if defbaudrate<>19200 then      If Pos('13',q)>0 Then bd:=b9600;

      If Pos('14',q)>0 Then bd:=b4800;
      If Pos('16',q)>0 Then bd:=b2400;

if defbaudrate<>19200 then       If Pos('17',q)>0 Then bd:=b9600;
      if pos('18',q)>0 then bd:=b19200;

if defbaudrate<>19200 then       If Pos('19',q)>0 Then bd:=b9600;

if defbaudrate<>19200 then       If Pos('96',q)>0 Then bd:=b9600;
      end;
      If Not(bd>b110) Then WriteLn(Usr,'[ Set Modem to VERBAL EXTENDED result codes! ]');

      If (bd>b110) Then Begin
        parity:=False;
        baudrate:=baudarray[bd];
        mustgetbaud:=False;
        checkforhayesreport:=True;
      End Else Checkforhayesreport:=False;

    End;


  Procedure receivecall;
    Var b:Byte;
      timeout,autoswitch:Integer;
      k:Char;
      brate:baudratetype;

    Procedure nextrate(Var b:baudratetype);
      Var ob:baudratetype;
      Begin
        ob:=b;
        Repeat
          b:=Succ(b);
          If b>b19200 Then b:=b110;
          If b=ob Then exit
        Until b In supportedrates
      End;

    Procedure disconnect;
      Begin
        If carrier Then hangupmodem;
        baudrate:=defbaudrate;
        parity:=False;
        closeport;
        setparam(usecom,baudrate,parity);
        setupmodem
      End;

    Function seconds:Integer;
      Var r:registers;
      Begin
        r.ah:=$2c;
        Intr($21,r);
        seconds:=r.dh
      End;

    Label abort,connected;
    Begin

      local:=False;
      online:=False;
      TextColor(normbotcolor);
      Window(1,1,80,25);
      ClrScr;
      Window(1,1,80,24);
      If checkforhayesreport Then GoTo connected;
      If Not mustgetbaud Then GoTo connected;
      brate:=b110;
      parity:=False;
      timeout:=timer+2;
      Repeat
        nextrate(brate);
        baudrate:=baudarray[brate];
        TextColor(outlockcolor);
        textbackground(0);
        Write(Usr,^M^J'Trying ',baudrate,' BAUD: ');
        closeport;
        setparam(usecom,baudrate,parity);
{        if cts_handle then setctsmode(curport,true);}
        cleartransmitbuffer;
        clearreceivebuffer;
        autoswitch:=seconds+3;
        If autoswitch>59 Then autoswitch:=autoswitch-60;
        Repeat Until (Not carrier) Or (numchars>0) Or (keyhit) Or
        (timer>=timeout) Or (autoswitch=seconds);
        If timer>=timeout Then hangupmodem;
        If Not carrier Then GoTo abort;
        If keyhit
        Then
          Begin
            k:=bioskey;
            Case UpCase(k) Of
              #13:GoTo connected;
              ' ':goto connected;
              'D' :GoTo abort;
            End
          End
        Else
          Begin
            If numchars>0 Then Begin
              b:=Ord(getchar);
              Write(Usr,b,' received.')
            End Else b:=0;
            If b<>13
            Then If b=141
              Then parity:=True
              Else
                Begin
                  Delay(200);
                  While numchars>0 Do b:=Ord(getchar)
                End
          End
      Until (b=13) Or (b=141) Or (timer>timeout);
      If timer<=timeout Then Begin
connected:
closeport;
        setparam(usecom,baudrate,parity);
{                if cts_handle then setctsmode(curport,true);}

        If parity
        Then baudstr:='E,7'
        Else baudstr:='N,8';
        baudstr:=strr(baudrate)+','+baudstr+',1';
        online:=True;
        urec.config:=[lowercase,linefeeds,eightycols];
        {  writestr (^M^M'Connected at '+baudstr+^M^M);}
        Inc(newcalls);
        If carrier Then exit
      End;
abort:
      disconnect
    End;

  Procedure exitprog;
    Begin
      dontanswer;
      Window(1,1,80,25);
      TextColor(normtopcolor);
      textbackground(0);
      ClrScr;
      WriteLn(Usr,'Emulex/2 (C) 1989 by Emulex Development Systems Ltd.');
      Writeln(Usr,'Call SwashBucklers II for help and the Newest Emulex!');
      ensureclosed;
      Halt(4)
    End;

  Procedure checkday;
    Begin
      If lastdayup<>datestr(now) Then Begin
        lastdayup:=datestr(now);
        inc(numdaysup);
        callstoday:=0;
        writestatus
      End
    End;

  Procedure dotimedevent;
    Var tf:Text;
    Begin
      Window(1,1,80,25);
      ClrScr;
      Writelog (1,1,'::Emumail Activated!');
      WriteLn(Usr,'Executing Emumail event: ',eventbatch);
      WriteLn(Usr);
{      Assign(tf,'Door.bat');
      Rewrite(tf);
      WriteLn(tf,eventbatch);
      textclose(tf);}
      timedeventdate:=datestr(now);
      ensureclosed;
      net_send_overlay;
    End;

  Function statusscreen:Char;
    Const statwindx=5;
      statwindy=1;
      firstcolx=15;
      firstline=5;
      secondcolx=54;

    Procedure col1;
      Begin
        Window(statwindx+firstcolx,statwindy+firstline,80,25);
      End;

    Procedure col2;
      Begin
        Window(statwindx+secondcolx,statwindy+firstline,80,25);
      End;

    Procedure percent(r1,r2:Real);
      Begin
        If (r2<1) Then exit;
        r2:=Round((r1/r2)*1000)/10;
        WriteLn(Usr,r2:0:1,'%')
      End;

    Procedure drawstatus;
      Var totalidle,totalup,totalmins,r:Real;
        tmp:LongInt;
        kay:sstr;
      Begin
        col1;
        tmp:=timetillevent;
        If tmp<=30 Then Begin
          GoToXY(1,13);
          Write(Usr,'EmuMail scheduled in ',tmp,' minutes!  ');
          If tmp<=5 Then Begin
            dontanswer;
            If tmp<=2 Then dotimedevent
          End
        End;
        If carrier Or keyhit Then exit;
        GoToXY(1,2);
        WriteLn(Usr,callstoday);
        tmp:=elapsedtime(numminsidle);
        Write(Usr,tmp);
        GoToXY(1,6);
        WriteLn(Usr,numdaysup);
        r:=Round(10*numcallers/numdaysup)/10;
        WriteLn(Usr,r:0:1);
        WriteLn(Usr,timestr(now),' ');
        Write(Usr,datestr(now),'  ');
        col2;
        GoToXY(1,3);
        totalidle:=numminsidle.total+elapsedtime(numminsidle);
        WriteLn(Usr,totalidle:0:0);
        totalup:=totalidle+numminsused.total;
        WriteLn(Usr,totalup:0:0);
        totalmins:=1440.0*(numdaysup-1.0)+timer;
        If (totalup<1) Or (totalmins<1) Then exit;
        percent(numminsused.total,totalmins);
        percent(numminsxfer.total,totalmins);
        percent(totalidle,totalmins);
        percent(totalup,totalmins);
        percent(totalmins-totalup,totalmins);
        col1;
        GoToXY(1,1);
        maybewritestatus;
      End;

    Procedure writeavail;
      Var m:sstr;
      Begin

        GoToXY(1,12);
        m:=sysopavailstr;
        While Length(m)<15 Do m:=m+' ';
        Write(Usr,m);
        GoToXY(1,1)
      End;

    Var cnt,numsmail:Integer;
      k:Char;
      tmp:mstr;
      b:Byte;
      done:Boolean;

    Function shouldexit:Boolean;
      Begin
        shouldexit:=done Or carrier
      End;

    Procedure handlekey(k:Char;beforeabout:Boolean);
      Begin
        b:=Ord(k)-128;
        Case b Of
          availtogglechar:Begin
                            toggleavail;
                            If Not beforeabout Then writeavail
                          End;
          59,60,61,62,63,64,65,66,67,68:Begin
                                 done:=True;
                                 statusscreen:=k
                               End
        End
      End;

    Function interrupted(beforeabout:Boolean):Boolean;
      Begin
        If keyhit Then Begin
          k:=bioskey;
          handlekey(k,beforeabout)
        End;
        done:=done Or carrier;
        interrupted:=done
      End;

    Procedure sendstring(x:lstr);
      Var cnt:Integer;
        k:Char;
      Begin
        For cnt:=1 To Length(x) Do Begin
          sendchar(x[cnt]);
          Delay(20);
        End;
        Delay(50);
        cleartransmitbuffer;
        clearreceivebuffer;
      End;

    Procedure phonesringing;
      Begin
        sendstring('  ATA'#13)
      End;

    Procedure connectcode(k:Char);
      Var timer:word Absolute $40:$6c;
        t:word;
        k2:Char;
        bd:baudratetype;
      Begin
        t:=timer+18;
        Repeat
        Until (timer>t) Or carrier Or (numchars>0);
        k2:=getchar;{ Will be #0 if no chars }
        Case k Of
          '1' :Case k2 Of
            #0:bd:=b300;
            '0' :bd:=b2400;
            '6' :bd:=b9600;
            Else exit
            End;
          '5' :bd:=b1200;
        Else exit
        End;
        If bd In supportedrates Then Begin
          parity:=False;
          baudrate:=baudarray[bd];
          mustgetbaud:=False;
          t:=timer+18;
          Repeat Until carrier Or (timer>t)
        End
      End;

    Procedure BBS_Status;
      Begin
        Window(statwindx,statwindy,80,25);
        GoToXY(1,1);
        If interrupted(True) Then exit;
        WriteLn(Usr,'                   ีออออออออออออออออออออออออออออออธ                 ');
        WriteLn(Usr,'                   ณ ',versionnum,' ณ                 ');
        WriteLn(Usr,'ีออออออออออออออออออต       Node #1 On-line        ฦออออออออออออออออธ');
        WriteLn(Usr,'ณ                  ิออออออออออออออออออออออออออออออพ                ณ');
        WriteLn(Usr,'ณ                                                                  ณ');
        If interrupted(True) Then exit;
        WriteLn(Usr,'ณ Last caller:                      Total mins used:               ณ');
        WriteLn(Usr,'ณ Calls today:                      Used by transfer:              ณ');
        WriteLn(Usr,'ณ Mins idle:                        Minutes idle:                  ณ');
        If interrupted(True) Then exit;
        WriteLn(Usr,'ณ Sysop mail:                       Minutes Online:                ณ');
        WriteLn(Usr,'ณ Total calls:                      Percent Used:                  ณ');
        WriteLn(Usr,'ณ Total days:                       Percent Xfer:                  ณ');
        If interrupted(True) Then exit;
        WriteLn(Usr,'ณ Calls/day:                        Percent Idle:                  ณ');
        WriteLn(Usr,'ณ Time:                             Percent Up:                    ณ');
        WriteLn(Usr,'ณ Date:                             Percent Down:                  ณ');
        If interrupted(True) Then exit;
        WriteLn(Usr,'ณ New Calls:                        New Uploads:                   ณ');
        WriteLn(Usr,'ณ New Messages:                     Feedback:                      ณ');
        WriteLn(Usr,'ณ Chat Stat:                        New Email:                     ณ');
        WriteLn(Usr,'ณ                                                                  ณ');
        WriteLn(Usr,'ิออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออพ');
        If (FSearch ('DSZ.COM','.;'+getenv('PATH')) = '') And
           (FSearch ('DSZ.EXE','.;'+getenv('PATH')) = '') Then
           Writeln('Where is DSZ?');
        If (FSearch ('PKZIP.EXE','.;'+getenv('PATH')) = '') And
           (FSearch ('PKUNZIP.EXE','.;'+getenv('PATH')) = '') Then
           Writeln('Where is PKZIP/UNZIP?');
        If (getenv('comspec') = '') or Not exist(getenv('comspec')) Then Writeln(' Invalid Comspec');
        if (not match('KERMIE',getenv('dszlog') ) )then writeln ('Add line SET DSZLOG=kermie to batch file');

        if diskfree(0)<32767 then write (usr,'**DANGER LOW DISK SPACE**');
        If interrupted(True) Then exit;
        Window(1,1,80,25);
        GoToXY(1,24);
        WriteLn(Usr,'[F10]: Login Locally [F2]: Exit Emulex/2 [F4]: AreaEd.Com   [F6]:SysLog');
        Write  (Usr,'[F1] : Yourterm.BAT  [F3]: Force EmuMail [F5]: UserEdit.com');
        If interrupted(True) Then exit;
        numsmail:=getnummail(1)+numfeedback;
        tmp:=getlastcaller;
        col1;
        GoToXY(1,1);
        TextColor(normtopcolor);
        Write(Usr,Copy(tmp,1,20));
        GoToXY(1,4);
        WriteLn(Usr,numsmail);
        Write(Usr,numcallers:0:0);
        GoToXY(1,10);
        WriteLn(Usr,newcalls);
        Write(Usr,newposts);
        writeavail;
        col2;
        GoToXY(1,1);
        WriteLn(Usr,numminsused.total:0:0);
        Write(Usr,numminsxfer.total:0:0);
        GoToXY(1,10);
        WriteLn(Usr,newuploads);
        WriteLn(Usr,newfeedback);
        Write(Usr,newmail);

      End;
      var T1 , T2:sstr;
      KKool:file of byte;
    Begin
      Cleartransmitbuffer;
      Clearreceivebuffer;
      statusscreen:=#0;
      done:=False;
      Window(1,1,80,25);
      TextColor(normbotcolor);
      ClrScr;
      BBS_Status;
       if exist('NetSend.BBS') then begin
                    assign(kkool,'Netsend.bbs');
                    erase(kkool);
                    net_send_overlay;
                    End;
      Repeat
        checkday;
        If carrier Then exit;
        drawstatus;
        If Carrier Then exit;
        cnt:=0;
        t1:=timestr(now);

        Repeat
         if timestr(now)<>t1 then done:=true;
          If keypressed  Then done:=True;
          If carrier Then done:=True;
        Until (carrier) Or done;
        If carrier Then exit;

      Until done;
    End;
Procedure Dosyslog;
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
      If includedate Then q:=q+' on '+datestr(l.when);
      q:=q+' at '+timestr(l.when);
      WriteLn(usr,q)
    End;

  Var b:Boolean;
  krad:char;
  Begin
  window (1,1,80,25);clrscr;
    writehdr('List system log');
    WriteLn(usr,'[Space] to skip user, [X] to abort');
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
        if wherey>20 then begin
        Writeln (usr,'Press [Return] for more');
        krad:=readkey;
        clrscr;if upcase(krad)='X' then exit;end;
      End;

    Until xpressed;
  End;

 Procedure delsyslog;
  Begin
    writestr('Delete system log: Confirm:');
    If Not yes Then exit;
    Close(logfile);
    Rewrite(logfile);
    WriteLn(usr,^M'System log deleted.');
    writelog(2,7,unam)
  End;

  Var k:Char;
    ay:sstr;
    offhook:lstr;
  Label exit;
  Begin
    waitforacall:=False;
    closeport;
    setparam(usecom,defbaudrate,False);
{            if cts_handle then setctsmode(curport,true);}

    setupmodem;
    starttimer(numminsidle);
    wscount:=0;
    local:=False;
    ClrScr;

    Repeat
      doanswer;

      If Not carrier Then Begin
        ClearTransmitbuffer;
        ClearReceiveBuffer;
      End;

      mustgetbaud:=True;

      k:=statusscreen;

      If carrier Then Begin
        receivecall;
        If carrier Then GoTo exit;
      End;

      Case Ord(k)-128 Of
        59:Begin
             local:=False;
             online:=False;
             writestatus;
             waitforacall:=True;
             dontanswer;
             Window(1,1,80,25);
             TextColor(normtopcolor);
             textbackground(0);
             ClrScr;
             GoToXY(30,24);
             WriteLn(Usr,'Executing YourTerm.bat!');
             ensureclosed;
             Halt(128);

           End;
        60:exitprog;
        61:net_send_overlay;
        62:EXEC ('AREAED.COM','');
        63:exec ('Useredit.com','');
        64:begin DoSysLog; delsyslog; end;
        65:begin unum:=1;readurec;readfeedback;ulvl:=-999;unam:='><';unum:=-999;end;
        66:begin unum:=1;readurec;editnews;ulvl:=-999;unam:='';unum:=-999;end;
        67:      sendmodemstr('ATX0D|',true);

        68:Begin
	     offhook:='+++~~~AT H1|';
             if discon then Begin
   if not carrier then  sendmodemstr(offhookline,true);
      End else

             dontanswer;
             local:=True;
             online:=False;
             newfeedback:=0;
             newuploads:=0;
             newcalls:=0;
             newposts:=0;
             newmail:=0;
             writestatus;
             GoTo exit
           End
      End
    Until 0=1;
exit:

      End;
      begin
      end.
