  {$R-,S-,I-,D-,F+,V-,B-,N-,L+ }

  unit mainr2;

  Interface

  uses gentypes,modem,subs1,subs2,gensubs,statret,configrt,overret1,
  textret,userret,mailret,zedit,lineedit,ansiedit,mainr1;

  Function edittext(where:Integer):Integer;
  Procedure offtheforum;
  Function reedit(Var m:message;g:Boolean):Boolean;
    Function editor(Var m:message;totitle:Boolean;gettitle:Boolean):Integer;
    Procedure seekbdfile(n:Integer);
    Procedure writebdfile(Var bd:boardrec);
    Procedure writecurboard;
    Procedure addnews;
    Procedure sendmailto(uname:mstr;anon:Boolean);
    Procedure addfeedback(Var m:mailrec);
    Procedure hangupmodem;
    Procedure setupmodem;
    Procedure dialnumber(num:lstr);
    Procedure disconnect;

    Implementation

   Function reedit(Var m:message;g:Boolean):Boolean;
    Begin
    if pcbmover='MessageUPLOAD' then begin
    reedit:=zeditor(m,g);trimmessage(m);
    pcbmover:='';
    end else begin

      If ansigraphics In urec.config
      Then reedit:=ansireedit(m,g) else
            if vt52 in urec.config then reedit:=Zeditor(m,g)
      Else reedit:=linereedit(m,g);
      trimmessage(m);
      end;
    End;

  Function editor(Var m:message;totitle:Boolean;gettitle:Boolean):Integer;

    Function getthetitle:Boolean;
      Begin
        m.anon:=False;
        getthetitle:=True;
        If gettitle Then Begin
          BufLen:=30;
          If urec.emulation=1 Then writestr(^M^M'Title: &') Else
            writestr(^M^M'Subject: &');
          If Length(Input)=0 Then Begin
            getthetitle:=False;
            exit
          End;
          m.title:=Input;
          {  totitle:=true;    }
          If totitle Then Begin
            totitle:=False;
            BufLen:=30;
            writestr('To [Return=All] : &');
            m.sentto:=Input;
            If Length(Input)=0 Then Begin
              m.sentto:='All'
          End;End;

          If urec.emulation<>2 Then
            If ulvl>=anonymouslevel Then Begin
              BufLen:=1;
              writestr('Anonymous [y/n]? *');
              m.anon:=yes
            End;

        End;
      End;

    Begin
      editor:=-1;
      m.numlines:=0;
      If getthetitle
      Then If reedit(m,gettitle)
        Then editor:=maketext(m)
    End;

  Procedure seekbdfile(n:Integer);
    Begin
      Seek(bdfile,n);
      Seek(bifile,n);che
    End;

  Procedure writebdfile(Var bd:boardrec);
    Begin
      Write(bdfile,bd);
      Write(bifile,bd.shortname)
    End;

  Procedure writecurboard;
    Begin
      seekbdfile(curboardnum);
      writebdfile(curboard);che
    End;

  Procedure addnews;
    Var newline,r:Integer;
      nfile:File Of newsrec;
      Ntmp,atmp:newsrec;
      numnews,cnt:Integer;
      m:message;
    Begin
      writehdr('Adding to the news');
      Writestr('Minimum Level to read news [1] :');
      If Input='' Then Input:='1';
      ntmp.level:=valu(Input);
      Writestr('Maximum Level to read news [32767] :');
      If Input='' Then Input:='32767';
      ntmp.Maxlevel:=valu(Input);

      newline:=editor(m,False,True);
      Ntmp.when:=now;ntmp.from:=unam;Ntmp.title:=m.title;
      ntmp.location:=newline;
      If newline<0 Then exit;
      r:=IOResult;
      Assign(nfile,'News');
      Reset(nfile);
      r:=IOResult;
      If r<>0
      Then
        Begin
          If r<>1 Then WriteLn('Error ',r,' opening news file; recreating.');
          Rewrite(nfile);
          Write(nfile,ntmp);
          numnews:=0
        End
      Else
        Begin
          numnews:=FileSize(nfile);
          For cnt:=numnews-1 Downto 0 Do
            Begin
              Seek(nfile,cnt);
              Read(nfile,atmp);
              Seek(nfile,cnt+1);
              Write(nfile,atmp)
            End;
          che;
          Seek(nfile,0);
          Write(nfile,Ntmp)
        End;
      WriteLn('News added.  News items: ',numnews+1);
      writelog(2,1,'');
      Close(nfile)
    End;

  Procedure sendmailto(uname:mstr;anon:Boolean);
    Var un:Integer;
      me:message;
      line:Integer;
      u:userrec;
    Begin
      If Length(uname)=0 Then exit;
      un:=lookupuser(uname);
      If un=0 Then WriteLn('User not found.') Else Begin
        If anon And (ulvl<sysoplevel) Then uname:=anonymousstr;
        Seek(ufile,un);
        Read(ufile,u);
        If u.emailannounce>-1 Then Begin
          writehdr(u.handle+'''s Announcement');
          printtext(u.emailannounce)
        End;
        writehdr('Sending mail to '+uname);
        line:=editor(me,False,True);
        If line>=0 Then addmail(un,line,me)
      End
    End;

  Procedure addfeedback(Var m:mailrec);
    Var ffile:File Of mailrec;
    Begin
      Assign(ffile,'Feedback');
      Reset(ffile);
      If IOResult<>0 Then Begin
        Close(ffile);
        Rewrite(ffile)
      End;
      Seek(ffile,FileSize(ffile));
      Write(ffile,m);
      Close(ffile);
      newfeedback:=newfeedback+1;
    End;

  Procedure hangupmodem;
    Var tries:Integer;
    Begin
      tries:=0;
      While carrier And (tries<5) Do Begin
        hangup;
        sendmodemstr(modemhangupstr,False);
        tries:=tries+1
      End;
      setparam(usecom,baudrate,parity)
    End;

  Procedure setupmodem;
    Begin
      If carrier Then exit;
      WriteLn(Usr,^M^J'[Sending Modem INIT string]'^M);
      sendmodemstr(modemsetupstr,True);
    End;

  Procedure dialnumber(num:lstr);
    Begin
      sendmodemstr(modemdialprefix+num+modemdialsuffix,True)
    End;

  Procedure disconnect;
    Begin
      If online Then hangupmodem;
      online:=True;
      writelog(0,3,'');
      If (unum>0) And Not disconnected Then updateuserstats(True);
      disconnected:=True
    End;

  Function edittext(where:Integer):Integer;
    Var me:message;
      Yaw:Integer;
    Begin
      reloadtext(where,me);

      If reedit(me,True) Then Begin
        deletetext(where);
        yaw:=maketext(me);

        If yaw<0 Then Begin
          writestr(^M'Deleting it..');
        End;

      End;
      edittext:=yaw;
    End;



  Procedure offtheforum;
    Var q,n:Integer;
      tn:File Of Integer;
      Fn:File Of LastMSG;
      Rec:lastmsg;
      m:message;
    Begin

      If urec.emulation=2 Then Input:='Y' Else
        writestr('Would you like to logoff now [y/n]? *');
      If yes Then Begin
        If (urec.emulation<>2) And (ToNextUserLevel<ulvl) Then Begin
          writestr('Leave a note to next users? *');
          If yes Then Begin
            q:=editor(m,False,False);
            If q>=0 Then Begin

              Assign(fn,'LastMsg');

              If exist('Lastmsg') Then Begin
                Seek(fn,1);Read(fn,rec);
                deletetext(rec.tonext);
                Close(fn);
              End;

              Rewrite(fn);
              Seek(Fn,1);
              rec.from:=unam;
              rec.tonext:=q;
              Write(fn,rec);Close(fn);
            End
          End;
        End;
        printfile(textfiledir+'Logoff.bbs');
        disconnect;dontanswer;
    End;End;



  Begin
  End.
#L#M#N#O#P#