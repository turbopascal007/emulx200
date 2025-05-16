  {$R-,S-,I-,D-,F+,V-,B-,N-,L+ }

  unit subs2;

  { $define testingdevices}(* Activate this define for test mode *)

  Interface

  uses printer,dos,crt,gentypes,configrt,gensubs,subs1,windows,modem,statret,chatstuf,
  flags;
  Procedure cleartoeol;
  Procedure Execute(What,params:lstr);
  Procedure ListAllWithAccess(Lvl,gf,fle:Integer;List:lstr);
  Function isinlist(Listname:lstr):Boolean;
  Procedure ansigotoxy(X,y:Integer);
  Procedure ansiwindow(x1,y1,x2,y2:Integer);
  Procedure asciigotoxy(x,y:Integer);
  Procedure ansicls;
  Procedure beepbeep;
  Procedure summonbeep;
  Procedure abortttfile(er:Integer);
  Procedure openttfile;
  Procedure writecon(k:Char);
  Procedure toggleavail;
  Function charready:Boolean;
  Function readchar:Char;
  Function waitforchar:Char;
  Procedure clearchain;
  Function charpressed(k:Char):Boolean;{ TRUE if K is in typeahead }
  Procedure addtochain(l:lstr);
  Procedure directoutchar(k:Char);
  Procedure handleincoming;
  Procedure writechar(k:Char);
  {$F+}
  Function opendevice(Var t:textrec):Integer;
    Function closedevice(Var t:textrec):Integer;
    Function cleardevice(Var t:textrec):Integer;
    Function ignorecommand(Var t:textrec):Integer;
    Function directoutchars(Var t:textrec):Integer;
    Function writechars(Var t:textrec):Integer;
    Function directinchars(Var t:textrec):Integer;
    Function readcharfunc(Var t:textrec):Integer;
    {$F-}
    Function getinputchar:Char;
    Procedure getstr;
    Procedure writestr(s:anystr);
    Procedure cls;
    Procedure writehdr(q:anystr);
    Function issysop:Boolean;
    Procedure reqlevel(l:Integer);
    Procedure printfile(fn:lstr);
    Procedure printtexttopoint(Var tf:Text);
    Procedure skiptopoint(Var tf:Text);
    Function minstr(blocks:Integer):sstr;
    Procedure parserange(numents:Integer;Var f,l:Integer);
    Function menu(mname:mstr;mfn:sstr;choices:anystr):Integer;
    Function checkpassword(Var u:userrec):Boolean;
    Function getpassword:Boolean;
    Procedure getacflag(Var ac:accesstype;Var tex:mstr);
type
  ByteCast =
    record
      LoB, HiB : Byte;
    end;

var
  SaveInt21 : Pointer;
  WindPos : Word;
  WindLo : Word;
  WindHi : Word;
  WindAttr : Byte;
    Implementation
 var fschat:boolean;

 Procedure Execute(What,params:lstr);
  begin
  Writeln (usr,'(Executing Dos Shell..',what,params,')');
  closeport;
  exec(what,params);
  setparam(usecom,baudrate,parity);
  end;

  Procedure beepbeep;
    Begin
      NoSound;
      Sound(200);
      Delay(10);
      NoSound
    End;

  Procedure summonbeep;
    Var cnt:Integer;
    Begin
      NoSound;
      cnt:=1330;
      Repeat
        Sound(cnt);
        Delay(10);
        cnt:=cnt+500;
      Until cnt>5300;
      NoSound
    End;

  Procedure abortttfile(er:Integer);
    Var n:Integer;
    Begin
      specialmsg('<Texttrap error '+strr(er)+'>');
      texttrap:=False;
      textclose(ttfile);
      n:=IOResult
    End;

  Procedure openttfile;
    Var n:Integer;
    Begin
      appendfile('Texttrap',ttfile);
      n:=IOResult;
      If n=0
      Then texttrap:=True
      Else abortttfile(n)
    End;

  Procedure writecon(k:Char);
    Var r:registers;
    Begin
      If k=^J
      Then Write(Usr,k)
      Else
        Begin
          r.dl:=Ord(k);
          r.ah:=2;
          Intr($21,r)
        End
    End;

  Procedure toggleavail;
    Begin
      If sysopavail=notavailable
      Then sysopavail:=available
      Else sysopavail:=Succ(sysopavail)
    End;

  Function charready:Boolean;
    Var k:Char;
    Begin
      If modeminlock Then While numchars>0 Do k:=getchar;
      If hungupon Or keyhit
      Then charready:=True
      Else If online
        Then charready:=(Not modeminlock) And (numchars>0)
        Else charready:=False
    End;

  Function readchar:Char;

    Procedure toggletempsysop;
      Begin
        If tempsysop
        Then ulvl:=regularlevel
        Else
          Begin
            regularlevel:=ulvl;
            ulvl:=sysoplevel
          End;
        tempsysop:=Not tempsysop
      End;

    Procedure togviewstats;
    Var
      LastCall : DateTime ;
      Begin
        If splitmode
        Then unsplit
        Else
          Begin
            splitscreen(7);
            top;
            ClrScr;
            unpacktime(urec.laston,lastcall);
            Write(Usr,'File Level    : ',urec.udlevel,
            ^M^J'File Points   : ',urec.udpoints,
            ^M^J'# of Uploads  : ',urec.uploads,
            ^M^J'# of Downloads: ',urec.downloads,
            ^M^J'Last Time On  : ',lastcall.Month:2,'/',lastcall.Day:2,'/',
                                   lastcall.year:4);
            Window(40,1,80,5);
            GoToXY(1,1);
            Write(Usr,'Posts     : ',urec.nbu,
            ^M^J'UpLoads   : ',urec.nup,
            ^M^J'DownLoads : ',urec.ndn,
            ^M^J'Total Time: ',urec.totaltime:0:0,
            ^M^J'Num. calls: ',urec.numon);
            Window(1,1,80,5);
            bottom
          End;
      End;

    Procedure showhelp;
      Begin
        If splitmode
        Then unsplit
        Else Begin
          splitscreen(10);
          top;
          ClrScr;
          Write(Usr,
          'Chat with user: [F1]             Sysop commands:[F2]'^M^J,
          'Sysop gets the system next:[F7]  Stop his time :[F8]'^M^J,
          'Lock out all modem input:[F9]    Lock out modem output:[F10]'^M^J,
          'Chat availabily toggle:[Alt-A]   Toggle Temp. Sysop Access   :[Alt-T]'^M^J,
          'Add 1 minute time   :[Alt-M]     Remove 1 minute Time  :[Alt-L]'^M^J,
          'Set Time Left to 0:[Alt-K]',elapsedtime(numminsidle),',',
           elapsedtime(numminsused),',',elapsedtime(numminsxfer));
        End;
      End;

    Procedure toggletexttrap;
      Var n:Integer;
      Begin
        If texttrap
        Then
          Begin
            textclose(ttfile);
            n:=IOResult;
            If n<>0 Then abortttfile(n);
            texttrap:=False
          End
        Else openttfile
      End;

    Var k,k1:Char;
      ret:Char;
      dorefresh:Boolean;
      TT:integer;
    Begin
      requestchat:=False;
      requestcom:=False;
      reqspecial:=False;
      If keyhit
      Then
        Begin
          k:=bioskey;
          ret:=k;
          If Ord(k)>127 Then Begin
            ret:=#0;
            dorefresh:=ingetstr;
            Case Ord(k)-128 Of
              availtogglechar:
                Begin
                  toggleavail;
                  chatmode:=False;
                  dorefresh:=True
                End;
              sysopcomchar:
                Begin
                  requestcom:=True;
                  requestchat:=True
                End;
              breakoutchar:Halt(e_controlbreak);
              lesstimechar:urec.timetoday:=urec.timetoday-1;
              moretimechar:urec.timetoday:=urec.timetoday+1;
              notimechar:settimeleft(-1);
              chatchar:begin fschat:=false; requestchat:=True;end;
              FSCHATCHAR:begin requestchat:=true;fschat:=true;end;
              sysnextchar:sysnext:=Not sysnext;
                           timelockchar:If timelock Then timelock:=False Else Begin
                             timelock:=True;
                             lockedtime:=timeleft
                           End;
              inlockchar:modeminlock:=Not modeminlock;
              outlockchar:setoutlock(Not modemoutlock);
              tempsysopchar:toggletempsysop;
              bottomchar:bottomline;
              viewstatchar:togviewstats;
              sysophelpchar:If dorefresh Then showhelp;
              texttrapchar:toggletexttrap;
              printerechochar:printerecho:=Not printerecho;
              72:ret:=^E;
              75:ret:=^S;
              77:ret:=^D;
              80:ret:=^X;
              115:ret:=^A;
              116:ret:=^F;
              73:ret:=^R;
              81:ret:=^C;
              71:ret:=^Q;
              79:ret:=^W;
              83:ret:=^G;
              82:ret:=^V;
              117:ret:=^P;
            End;
            If dorefresh Then bottomline
          End
        End
      Else
        Begin
          k:=getchar;

          if DOUBLE_CHECK then begin
                     tt:=0;
                     repeat
                     inc(tt);
                     until   (tt>200) or ((numchars)>0) or hungupon;

                     k1:=getchar;
                     if k1<>k then k:=#0;
                     if k1<>k then while numchars>0 do k1:=getchar;
        end;

          If modeminlock
          Then ret:=#0
          Else ret:=k
        End;
      {If ret='+' Then Write(' '^H);}
      readchar:=ret
    End;

  Function waitforchar:Char;
    Var t:Integer;
      k:Char;
    Begin
      t:=timer+mintimeout;
      If t>=1440 Then t:=t-1440;
      Repeat
        If timer=t Then forcehangup:=True
      Until charready;
      waitforchar:=readchar;
    End;

  Procedure clearchain;
    Begin
      chainstr[0]:=#0
    End;

  Function charpressed(k:Char):Boolean;{ TRUE if K is in typeahead }
    Begin
      charpressed:=Pos(k,chainstr)>0
    End;

  Procedure addtochain(l:lstr);
    Begin
      If Length(chainstr)<>0 Then chainstr:=chainstr+',';
      chainstr:=chainstr+l
    End;

  Procedure directoutchar(k:Char);
    Var n:Integer;
    Begin
      If inuse<>1
      Then writecon(k)
      Else Begin
        bottom;
        writecon(k);
        top
      End;
      If WhereY>lasty Then GoToXY(WhereX,lasty);
      If online And (Not modemoutlock) And ((k<>#10) Or uselinefeeds)
      Then sendchar(k);
      If texttrap Then Begin
        Write(ttfile,k);
        n:=IOResult;
        If n<>0 Then abortttfile(n)
      End;
      If printerecho Then Write(Lst,k)
    End;

  Procedure handleincoming;
    Var k:Char;
    Begin
      k:=readchar;
      Case UpCase(k) Of
        'X',^X,^K,^C,#27,' ' :Begin
                                WriteLn(direct);
                                break:=True;
                                linecount:=0;
                                xpressed:=(UpCase(k)='X') Or (k=^X);
                                if k=^X then cleartransmitbuffer;
                                If xpressed Then clearchain;
                              End;
        ^S:k:=waitforchar;
      Else If Length(chainstr)<255 Then chainstr:=chainstr+k
      End
    End;

  Procedure writechar(k:Char);

    Procedure endofline;

      Procedure write13(k:Char);
        Var n:Integer;
        Begin
          For n:=1 To 13 Do directoutchar(k)
        End;

      Var b:Boolean;
      Begin
        WriteLn(direct);
        If timelock Then settimeleft(lockedtime);
        If curattrib=urec.statcolor Then ansicolor(urec.regularcolor);
        linecount:=linecount+1;
        If (linecount>=urec.displaylen-1) And (Not dontstop)
        And (moreprompts In urec.config) Then Begin
          linecount:=1;
          Write(direct,'More (Y/N/C)?');
          Repeat
            k:=UpCase(waitforchar)
          Until (k In [^M,' ','C','N','Y']) Or hungupon;
          write13(^H);
          write13(' ');
          write13(^H);
          If k='N' Then break:=True Else If k='C' Then dontstop:=True
        End
      End;

    Begin
      If hungupon Then exit;
      If k<=^Z Then
        Case k Of
          ^J,#0:exit;
          ^Q:k:=^H;
          ^B:Begin
               clearbreak;
               exit
             End
        End;
      If break Then exit;
      If k<=^Z Then Begin
        Case k Of
          ^G:beepbeep;
          ^L:cls;
          ^N,^R:ansireset;
          ^S:ansicolor(urec.statcolor);
          ^P:ansicolor(urec.promptcolor);
          ^U:ansicolor(urec.inputcolor);
          ^V:if urec.Highgraph=255 then ansicolor(urec.statcolor);
          ^W:if urec.highgraph=255 then ansicolor(urec.promptcolor);
          ^X:if urec.highgraph=255 then ansicolor(urec.inputcolor);
          ^H:directoutchar(k);
          ^M:endofline;

        End;
        exit;
      End;
{      If usecapsonly Then k:=UpCase(k);}
      directoutchar(k);
      If (keyhit Or ((Not modemoutlock) And online And (numchars>0)))
      And (Not nobreak) Then handleincoming
    End;

  Function getinputchar:Char;
    Var k:Char;
    Begin
      If Length(chainstr)=0 Then Begin
        getinputchar:=waitforchar;
        exit
      End;
      k:=chainstr[1];
      Delete(chainstr,1,1);
      If (k=',') And (Not nochain) Then k:=#13;
      getinputchar:=k
    End;

    {$ifdef testingdevices}

  Procedure devicedone(Var t:textrec;m:mstr);
    Var r:registers;
      cnt:Integer;
    Begin
      Write(Usr,'Device ');
      cnt:=0;
      While t.name[cnt]<>#0 Do Begin
        Write(Usr,t.name[cnt]);
        cnt:=cnt+1
      End;
      WriteLn(Usr,' ',m,'... press any key');
      r.ax:=0;
      Intr($16,r);
      If r.al=3 Then Halt
    End;

    {$endif}

    {$F+}

  Function opendevice;
    Begin
      {$ifdef testingdevices}devicedone(t,'opened');{$endif}
      t.handle:=1;
      t.mode:=fminout;
      t.bufend:=0;
      t.bufpos:=0;
      opendevice:=0
    End;

  Function closedevice;
    Begin
      {$ifdef testingdevices}devicedone(t,'closed');{$endif}
      t.handle:=0;
      t.mode:=fmclosed;
      t.bufend:=0;
      t.bufpos:=0;
      closedevice:=0
    End;

  Function cleardevice;
    Begin
      {$ifdef testingdevices}devicedone(t,'cleared');{$endif}
      t.bufend:=0;
      t.bufpos:=0;
      cleardevice:=0
    End;

  Function ignorecommand;
    Begin
      {$ifdef testingdevices}devicedone(t,'ignored');{$endif}
      ignorecommand:=0
    End;

  Function directoutchars;
    Var cnt:Integer;
    Begin
      For cnt:=t.bufend To t.bufpos-1 Do
        directoutchar(t.bufptr^[cnt]);
      t.bufend:=0;
      t.bufpos:=0;
      directoutchars:=0
    End;

  Function writechars;
    Var cnt:Integer;
    Begin
      For cnt:=t.bufend To t.bufpos-1 Do
        writechar(t.bufptr^[cnt]);
      t.bufend:=0;
      t.bufpos:=0;
      writechars:=0
    End;

  Function isinlist(Listname:lstr):Boolean;
    Var cnt:Integer;
      FF:Text;
      A,b:lstr;
    Begin
      a:=listname;
      isinlist:=False;
      If a='' Then exit;
      If match('NONE',a) Then exit;
      If exist(a) Then Begin
        Assign(ff,a);Reset(ff);cnt:=IOResult;If cnt<>0 Then exit;
        Repeat
          ReadLn(ff,b);
          If match(B,Unam) Then isinlist:=True;
        Until EoF(fF);
        textclose(ff);
        cnt:=IOResult;
      End Else isinlist:=False;
    End;
  Procedure ListAllWithAccess(Lvl,gf,fle:Integer;List:lstr);
    Var cnt:Integer;
      kk:userrec;
      A,b:lstr;

    Begin
    if minimumleveltolistusers>ulvl then exit;
      If (match(list,'NONE')) Or (list='') Then Else Begin
        If exist(list) Then Begin
          WriteLn('-Via Group Access-');
          printfile(list);
          WriteLn('-End-- Normal Access');
        End;
      End;
      For cnt:=1 To FileSize(ufile) Do Begin
        Seek(ufile,cnt-1);Read(ufile,kk);
        If lvl>0 Then If kk.level>=lvl Then WriteLn(kk.handle);
        If gf>0 Then If kk.gflevel>=gf Then WriteLn(kk.handle);
        If fle>0 Then If kk.udlevel>=fle Then WriteLn(kk.handle);

      End;
    End;


  Function directinchars;
    Begin
      With t Do Begin
        bufptr^[0]:=waitforchar;
        t.bufpos:=0;
        t.bufend:=1
      End;
      directinchars:=0
    End;

  Function readcharfunc;
    Begin
      With t Do Begin
        bufptr^[0]:=getinputchar;
        t.bufpos:=0;
        t.bufend:=1
      End;
      readcharfunc:=0
    End;

    {$F-}

  Procedure getstr;
    Var marker,cnt:Integer;
      p:Byte Absolute Input;
      k:Char;
      oldinput:anystr;
      done,wrapped:Boolean;
      wordtowrap:lstr;

    Procedure bkspace;

      Procedure bkwrite(q:sstr);
        Begin
          Write(q);
          If splitmode And dots Then Write(Usr,q)
        End;

      Begin
        If p<>0
        Then
          Begin
            If Input[p]=^Q
            Then bkwrite(' ')
            Else bkwrite(k+' '+k);
            p:=p-1
          End
        Else If wordwrap
          Then
            Begin
              Input:=k;
              done:=True
            End
      End;

    Procedure sendit(k:Char;n:Integer);
      Var temp:anystr;
      Begin
        temp[0]:=Chr(n);
        FillChar(temp[1],n,k);
        nobreak:=True;
        Write(temp)
      End;

    Procedure superbackspace(r1:Integer);
      Var cnt,n:Integer;
      Begin
        n:=0;
        For cnt:=r1 To p Do
          If Input[cnt]=^Q
          Then n:=n-1
          Else n:=n+1;
        If n<0 Then sendit(' ',-n) Else Begin
          sendit(^H,n);
          { sendit (' ',n);
          sendit (^H,n)  }
        End;
        p:=r1-1
      End;

    Procedure cancelent;
      Begin
        superbackspace(1)
      End;

    Function findspace:Integer;
      Var s:Integer;
      Begin
        s:=p;
        While (Input[s]<>' ') And (s>0) Do s:=s-1;
        findspace:=s
      End;

    Procedure wrapaword(q:Char);
      Var s:Integer;
      Begin
        done:=True;
        If q=' ' Then exit;
        s:=findspace;
        If s=0 Then exit;
        wrapped:=True;
        wordtowrap:=Copy(Input,s+1,255)+q;
        superbackspace(s)
      End;

    Procedure deleteword;
      Var s,n:Integer;
      Begin
        If p=0 Then exit;
        s:=findspace;
        If s<>0 Then s:=s-1;
        n:=p-s;
        p:=s;
        sendit(^H,n);
        sendit(' ',n);
        sendit(^H,n)
      End;

    Procedure addchar(k:Char);
      Begin
        If p<BufLen
        Then If (k<>' ') Or (p>0) Or wordwrap Or beginwithspacesok
          Then
            Begin
              p:=p+1;
              Input[p]:=k;
              If dots
              Then
                Begin
                  writechar(dotchar);
                  If splitmode Then Write(Usr,k)
                End
              Else writechar(k)
            End
          Else
        Else If wordwrap Then wrapaword(k)
      End;

    Procedure repeatent;
      Var cnt:Integer;
      Begin
        For cnt:=1 To Length(oldinput) Do addchar(oldinput[cnt])
      End;

    Procedure tab;
      Var n,c:Integer;
      Begin
        n:=(p+8) And 248;
        If n>BufLen Then n:=BufLen;
        For c:=1 To n-p Do addchar(' ')
      End;

    Procedure getinput;
      Begin
        oldinput:=Input;
        ingetstr:=True;
        done:=False;
        bottomline;
        If splitmode And dots Then top;
        p:=0;
        Repeat
          clearbreak;
          nobreak:=True;
          k:=getinputchar;
          If hungupon Then Begin
            Input:='';
            k:=#13;
            done:=True
          End;
          Case k Of
            ^I:tab;
            ^H:bkspace;
            ^M:done:=True;
            ^R:repeatent;
            ^X,#27:cancelent;
            ^W:deleteword;
            ' '..'~' :addchar(k);
            ^Q:If wordwrap And bkspinmsgs Then addchar(k)
          End;
          If requestchat Then Begin
            p:=0;
            WriteLn(^B^N^M^M^B);
            if fschat then splitscreenchat(requestcom) else
            chat(requestcom);
            Write(^B^M^M^P,lastprompt);
            requestchat:=False
          End
        Until done;
        WriteLn;
        If splitmode And dots Then Begin
          WriteLn(Usr);
          bottom
        End;
        ingetstr:=False;
        ansireset
      End;

    Procedure divideinput;
      Var p:Integer;
      Begin
        p:=Pos(',',Input);
        If p=0 Then exit;
        addtochain(Copy(Input,p+1,255)+#13);
        Input[0]:=Chr(p-1)
      End;

    Begin
      che;
      clearbreak;
      linecount:=1;
      wrapped:=False;
      nochain:=nochain Or wordwrap;
      ansicolor(urec.inputcolor);
      getinput;
      If Not nochain Then divideinput;
      While Input[Length(Input)]=' ' Do Input[0]:=Pred(Input[0]);
      If Not wordwrap Then
        While (Length(Input)>0) And (Input[1]=' ') Do Delete(Input,1,1);
      If wrapped Then chainstr:=wordtowrap;
      wordwrap:=False;
      nochain:=False;
      beginwithspacesok:=False;
      dots:=False;
      BufLen:=80;
      linecount:=1
    End;

  Procedure writestr(s:anystr);
    Var k:Char;
      ex:Boolean;
    Begin
      che;
      clearbreak;
      ansireset;
      uselinefeeds:=true; {(linefeeds In urec.config;)}
      usecapsonly:=Not(lowercase In urec.config);
      k:=s[Length(s)];
      s:=Copy(s,1,Length(s)-1);
      Case k Of
        ':' :Begin
               Write(^P,s,': ');
               lastprompt:=s+': ';
               getstr
             End;
        ';' :Write(s);
        '*' :Begin
               Write(^P,s);
               lastprompt:=s;
               getstr
             End;
        '&' :Begin
               nochain:=True;
               Write(^P,s);
               lastprompt:=s;
               getstr
             End
        Else WriteLn(s,k)
      End;
      clearbreak
    End;

  Procedure cls;
    Begin
      bottom;
      ClrScr;
      bottomline
    End;


  Procedure AnsiGotoxy(x,y:Integer);
    Begin


      If Not(ansigraphics In urec.config) Then asciigotoxy(x,y);
      If Not(ansigraphics In urec.config) Then exit;
      Write(direct,#27'[');
      If y<>1 Then Write(direct,strr(y));
      If x<>1 Then Write(direct,';',strr(x));
      Write('H');
    End;

  Procedure AsciiGotoxy(x,y:Integer);
    Var a,b,c,d:Integer;
    Begin
    if vt52 in urec.config then begin
      wvt52(#234+#234+#01+chr(x)+chr(y));gotoxy(x,y);
    end else begin

      A:=y-WhereY;
      If a>0 Then For c:=1 To a Do WriteLn;
      a:=x-WhereX;
      If a>0 Then For c:=1 To a Do Write(' ');
    End;end;
  Procedure Ansiwindow(x1,y1,x2,y2:Integer);
    Var a,b,c,cnt:Integer;

    Begin
    if vt52 in urec.config then begin
           wvt52(#234+#234+#10+Chr(x1)+Chr(y1)+Chr(x2)+Chr(y2));
           modemoutlock:=true;
           end;
      if  Not( (ansigraphics In urec.config) or (vt52 in urec.config)) Then exit;
      ansigotoxy(x1,y1);
      Write(^B'Ú');
      For cnt:=1 To ((x2-x1)-1) Do Write('Ä');
      Write(^B'¿');

      For cnt:=1 To ((y2-y1)-1) Do Begin
        b:=y1+cnt;
        ansigotoxy(x1,b);cleartoeol;
        Write(^B'³');ansigotoxy(x2,b);Write('³');
      End;
      ansigotoxy(x1,y2);
      Write(^B'À');
      For cnt:=1 To ((x2-x1)-1) Do Write('Ä');
      Write(^B'Ù');

          if vt52 in urec.config then modemoutlock:=false;


    End;

  Procedure ansicls;
    Begin
  if vt52 in urec.config then begin
   wvt52(#234+#234+#04);
   clrscr;
    end else
     Write(direct,#27'[2J')
    End;

  Procedure cleartoeol;
    Begin
    if vt52 in urec.config then begin
    wvt52(#234+#234+#27);clreol;
    end else   Write(direct,#27'[K')
    End;

  Procedure savecursor;
    Begin
      Write(direct,#27'[s')
    End;

  Procedure restorecursor;
    Begin
      Write(direct,#27'[u')
    End;

  Procedure ansicmove(k:Char;n:Integer);
    Var cnt:Integer;
    Begin
      If n<1 Then exit;
      Write(direct,#27'[');
      If n<>1 Then Write(direct,strr(n));
      Write(direct,k)
    End;

  Procedure writehdr(q:anystr);
    Var cnt,a,b:Integer;
    Begin
    if vt52 in urec.config then begin
    wvt52 (#234+#50+q+#0+#0);modemoutlock:=true;
               end;

                 Write(^B);dontstop:=True;nobreak:=True;

       Begin
        Write(^M'Ú');
        For cnt:=1 To 38 Do Write(direct,'Ä');
        WriteLn(direct,'¿');
        Write(direct,'³');
      End;
      For cnt:=1 To ((40-Length(q)) Div 2) Do Write(direct,' ');
      Write(^V,q,^R);
       Begin
        b:=40-WhereX;
        For a:=1 To b Do Write(direct,' ');
        WriteLn(direct,'³');
        Write(direct,'À');
        For cnt:=1 To 38 Do Write(direct,'Ä');
        WriteLn(direct,'Ù');
      End;
      if vt52 in urec.config then modemoutlock:=false;
    End;

  Function issysop:Boolean;
    Begin
      issysop:=(ulvl>=sysoplevel) Or (cursection In urec.config)
    End;

  Procedure reqlevel(l:Integer);
    Begin
      WriteLn(^B'Sorry, but level '^S,l,^R' is required.')
    End;

  Procedure printfile(fn:lstr);

    Procedure getextension(Var fname:lstr);

      Procedure tryfiles(a,b,c,d:Integer);
        Var q:Boolean;

        Function tryfile(n:Integer):Boolean;
          Const exts:Array[1..4] Of String[3]=('','ANS','ASC','69');
          Var Krad:sstr;
            c:Boolean;
          Begin
            c:=False;
            If urec.emulation>0 Then krad:=strr(urec.emulation) Else krad:='';
            If exist(Fname+krad+'.'+exts[n]) Then Begin
              c:=True;Fname:=fname+krad+'.'+exts[n];
            End;

            If (Not exist(fname+'.'+exts[n])) And (Not c) Then tryfile:=False Else
              If (Not c) Then Begin
                c:=True;
                fname:=fname+'.'+exts[n]
              End;
            tryfile:=c;
          End;

        Begin
          If tryfile(a) Then exit;
          If tryfile(b) Then exit;
          If tryfile(c) Then exit;
          q:=tryfile(d)
        End;

      Begin
        If Pos('.',fname)<>0 Then exit;
        If ansigraphics In urec.config Then tryfiles(2,3,1,4) Else
          If asciigraphics In urec.config Then tryfiles(3,1,4,2) Else
            tryfiles(1,4,3,2);
      End;

    Var tf:Text;
      k:Char;
    Begin
      clearbreak;
      WriteLn;
      getextension(fn);
      if not exist(fn) then begin

        fileerror('Printfile',fn);
        exit
                            end;
      Assign(tf,fn);
      Reset(tf);
      iocode:=IOResult;
      If iocode<>0 Then Begin
              fileerror('Printfile',fn);
        exit

      End;
      clearbreak;
      While Not(EoF(tf) Or break Or hungupon) Do
        Begin
          Read(tf,k);
          Write(k)
        End;
      If break Then WriteLn(^B);
      WriteLn;
      textclose(tf);
      curattrib:=0;
      ansireset
    End;

  Procedure printtexttopoint(Var tf:Text);
    Var l:lstr;
        Notdone:boolean ;
    Begin
      l:='';
      NotDone := True ;
      clearbreak;
      While NotDone And Not(EoF(tf) Or hungupon) And (l<>'.') Do Begin
      {  if isspace then
          begin
            NotDone := False ;
            cleartransmitbuffer ;
          end ;}
        If Not break Then WriteLn(l);
        ReadLn(tf,l)
      End
    End;

  Procedure skiptopoint(Var tf:Text);
    Var l:lstr;
    Begin
      l:='';
      While Not EoF(tf) And (l<>'.') Do
        ReadLn(tf,l)
    End;

  Function minstr(blocks:Integer):sstr;
    Var min,sec:Integer;
      rsec:Real;
      ss:sstr;
    Begin
      rsec:=1.38*blocks*(1200/baudrate);
      min:=Trunc(rsec/60.0);
      sec:=Trunc(rsec-(min*60.0));
      ss:=strr(sec);
      If Length(ss)<2 Then ss:='0'+ss;
      minstr:=strr(min)+':'+ss
    End;

  Procedure parserange(numents:Integer;Var f,l:Integer);
    Var rf,rl:mstr;
      p,v1,v2:Integer;
    Begin
      f:=0;
      l:=0;
      If numents<1 Then exit;
      Repeat
        writestr('Choose  [1-'+^V+strr(numents)+^R+' [Return]=all ?/help]:');
        If Input='?' Then printfile(textfiledir+'Rangehlp');
        If (Length(Input)>0) And (UpCase(Input[1])='Q') Then exit
      Until (Input<>'?') Or hungupon;
      If hungupon Then exit;
      If Length(Input)=0 Then Begin
        f:=1;
        l:=numents
      End Else Begin
        p:=Pos('-',Input);
        v1:=valu(Copy(Input,1,p-1));
        v2:=valu(Copy(Input,p+1,255));
        If p=0 Then Begin
          f:=v2;
          l:=v2
        End Else If p=1 Then Begin
          f:=1;
          l:=v2
        End Else If p=Length(Input) Then Begin
          f:=v1;
          l:=numents
        End Else Begin
          f:=v1;
          l:=v2
        End
      End;
      If (f<1) Or (l>numents) Or (f>l) Then Begin
        f:=0;
        l:=0;
        writestr('Invalid range!')
      End;
      WriteLn(^B)
    End;

  Function menu(mname:mstr;mfn:sstr;choices:anystr):Integer;
    Var k:Char;
      sysmenu,percent,needsys:Boolean;
      n,p,i:Integer;
      prompt:lstr;


    Procedure Print_Prompt;
      Var a,b:Integer;
        c,d:anystr;

      Begin

        BufLen:=80;
        clearbreak;dontstop:=True;nobreak:=True;

        lastprompt:='['+^V+strr(timeleft)+^R+' left] '+^V+mname+^R+' menu [?] :';

        If urec.Emulation=1 Then Begin
          Prompt:=^R+mname+' Menu [?=Help] :';
          lastprompt:=prompt;
          Writestr(Prompt);
        End;


        If (urec.Emulation<1) Or (urec.emulation>2) Then

          If (vt52 in urec.config) or (ansigraphics In urec.config) Then
               Begin
              if vt52 in urec.config then wvt52(#234+#42);
            clearbreak;dontstop:=True;nobreak:=True;
            ansigotoxy(26,24);Write(^R'[ '^V,mname,' menu'^R' ]      ['^V,timeleft,^R' left]  ',^V+timestr(now));
            ansigotoxy(1,23);Write(^P'Command [? for help] :');cleartoeol;getstr;
            ansigotoxy(1,24);cleartoeol;
            ansigotoxy(1,23);cleartoeol;
          End else          Begin

            prompt:=^B+'['+^V+strr(timeleft)+^R+' left] '+^V+mname+^R+' menu [?] :';
            writestr(prompt);
          End
      End;



    Begin
      sysmenu:=False;
      percent:=False;
      For p:=1 To Length(choices)-1 Do
        If choices[p]='%'
        Then If choices[p+1]='@'
          Then percent:=True
          Else
        Else If choices[p+1]='@'
          Then sysmenu:=True;
      WriteLn(^B);
      Repeat
        If chatmode
        Then summonbeep;

        If (timeleft<1) Or (timetillevent<=2) Then Begin
          printfile(textfiledir+'Timesup');
          forcehangup:=True;
          menu:=0;

          exit
        End;

        Print_Prompt;{emulation}

        n:=0;
        If Length(Input)=0
        Then k:='_'
        Else
          Begin
            If match(Input,'/OFF') Then Begin
              forcehangup:=True;
              menu:=0;
              exit
            End;
            n:=valu(Input);
           If n>0
            Then k:='#'
            Else
             k:=UpCase(Input[1])
          End;
        p:=1;
        i:=1;
        If k='?'
        Then
          Begin
          if (not sysmenu) and (vt52 in urec.config) and ((mfn='MAIN') or (mfn='FILE') or (MFN='BULLET')) then begin
             if mfn='MAIN' then WVT52(#234+#1+#2);
             if mfn='BULLET' then wvt52(#234+#1+#3);
             if mfn='FILE' then Wvt52(#234+#1+#4);

             end else begin
            printfile(textfiledir+mfn+'M');
            If sysmenu And issysop Then printfile(textfiledir+mfn+'S') ;
            end;
          End
        Else
          While p<=Length(choices) Do Begin
            needsys:=False;
            If p<Length(choices)
            Then If choices[p+1]='@'
              Then needsys:=True;
            If UpCase(choices[p])=k
            Then If needsys And (Not issysop)
              Then
                Begin
                  reqlevel(sysoplevel);
                  p:=255;
                  needsys:=False
                End
              Else p:=256
            Else
              Begin
                p:=p+1;
                If needsys Then p:=p+1;
                i:=i+1
              End
          End
      Until (p=256) Or hungupon;
      WriteLn(^B^M);
      If hungupon
      Then menu:=0
      Else
        If k='#' Then menu:=-n Else menu:=i ;
    End;

  Function getpassword:Boolean;
    Var t:sstr;
    Begin
      getpassword:=False;
      dots:=True;
      BufLen:=15;
      getstr;
      If Input=''
      Then exit
      Else Begin
        t:=Input;
        dots:=True;
        writestr('Once more to verify:');
        If Not match(t,Input) Then Begin
          WriteLn('Try again! Compare mismatch!');
          getpassword:=hungupon;
          exit
        End;
        urec.password:=t;
        getpassword:=True
      End
    End;

  Function checkpassword(Var u:userrec):Boolean;
    Var tries:Integer;
    Begin
      tries:=0;
      checkpassword:=True;
      Repeat
        splitscreen(5);
        top;
        WriteLn(Usr,'*Password Entry* [Close your Eyes!]');
        WriteLn(Usr,'Handle: ',u.handle);
        WriteLn(Usr,'Password: ',u.password);
        Write(Usr,'Typed so far: ');
        bottom;
        dots:=True;

        If u.emulation=0 Then writestr(^M'Enter your Password:');
        unsplit;
        If hungupon Then Begin
          checkpassword:=False;
          exit
        End;
        If match(Input,u.password)
        Then exit
        Else tries:=tries+1;
      Until tries>3;
      checkpassword:=False
    End;

  Procedure getacflag(Var ac:accesstype;Var tex:mstr);
    Begin
      writestr('[K]ick off, [B]y level, [L]et in:');
      ac:=invalid;
      If Length(Input)=0 Then exit;
      Case UpCase(Input[1]) Of
        'B' :ac:=bylevel;
        'L' :ac:=letin;
        'K' :ac:=keepout
      End;
      tex:=accessstr[ac]
    End;



begin
end.