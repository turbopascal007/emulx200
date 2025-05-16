{$R-,S-,I-,D-,F+,V-,B-,N-,L-,O+ }

  unit getlogin;

  Interface

  uses dos,crt,
  ansilog,gentypes,configrt,modem,userret,statret,gensubs,subs1,subs2,windows,
  mailret,textret,overret1,mainr1,mainr2,protocol,newnet;

  Procedure getloginproc;
  Procedure returnfromdoor;

  Implementation

Procedure getloginproc;
  Var allow_in:Boolean;
  Var tries:integer;
      imdone:boolean;

  Procedure addlastcaller(n:mstr);
  Var qf:File Of lastrec;
      last,cnt:Integer;

      l:lastrec;
    Begin
      Assign(qf,'Callers');
      Reset(qf);
      If IOResult<>0 Then Rewrite(qf);
      last:=FileSize(qf);
      If last>maxlastcallers Then last:=maxlastcallers;
      For cnt:=last-1 Downto 0 Do Begin
        Seek(qf,cnt);
        Read(qf,l);
        Seek(qf,cnt+1);
        Write(qf,l)
      End;
      With l Do Begin
        name:=n;
        when:=now;
        callnum:=Round(numcallers)
      End;
      Seek(qf,0);
      Write(qf,l);
      Close(qf)
    End;

  Procedure byebye(byefile:sstr);
    Begin
      printfile(textfiledir+byefile);
      unum:=-1;
      disconnect
    End;

 function check_tele(PHONE:mstr):boolean;
 var cnt:integer;
     CO:sstr;
     ok:boolean;
 begin
 Writehdr('User Verification');
 Writeln (^B^M'Your account has been subjected to an illegal logon attempt,');
 writeln ('You must complete the last four digits of your phone # to logon now.');
 if length(phone)<>10 then phone:='5555551212';
 cnt:=0;ok:=false;
 co:=copy(phone,7,4);
 repeat
 inc(cnt);
 buflen:=4;
 Writeln (usr,'Users Phone # is ',phone);
 Write ('Complete your Telephone # [xxx]-xxx-');getstr;
 ok:=co=input;
 until ok or (cnt>2) or hungupon;
 if not ok then writeln ('Incorrect!');
 if not ok then byebye('nicetry');
 check_tele:=ok;
 end;

  Procedure inituser;
    Var asc:Boolean;

    Procedure center(c:lstr;a,b:sstr);
      Var cnt:Integer;
        tmp:lstr;
      Begin
        a:='ณ';
        b:=a;
        FillChar(tmp[1],80,32);
        If Length(a)+Length(b)+Length(c)>39
        Then c[0]:=Chr(39-Length(a)-Length(b));

        tmp[0]:=Chr((39-Length(c)-Length(a)-Length(b)) Div 2);

        c:=a+tmp+c;
        tmp[0]:=Chr(39-Length(c)-Length(b));
        c:=c+tmp+b;
        While c[Length(c)]=' ' Do c[0]:=Pred(c[0]);
        WriteLn(c)
      End;

    Var m:mailrec;
      cnt:Integer;
      tmp:lstr;
      Fn:File Of Lastmsg;
      Rec:lastmsg;
      TOtalcalls,dang,chang,bang:Integer;

    Const inoutstr:Array[false..true] Of String[3]=('Out','In');


    Begin
      readurec;
      If urec.regularcolor=0 Then urec.regularcolor:=white;
      If urec.promptcolor=0 Then urec.promptcolor:=white;
      If urec.statcolor=0 Then urec.statcolor:=white;
      If urec.inputcolor=0 Then urec.inputcolor:=white;

      If (Timeexempt>=urec.level) Then Begin
        If withintime(TimeStop,TimeStart) Then ByeBye('CallLatr');
        If withintime(TimeStop,TimeStart) Then exit;
      End;

      If ulvl=-1 Then Begin
        byebye('Trashcan');
        exit
      End;
      If requireforms And (urec.infoform<0) Then infoform;
      If local
      Then tmp:=' (Local)'
      Else tmp:=' at '+baudstr;
      writelog(0,1,unam+tmp);
      With urec Do Begin
        numon:=numon+1;
        numcallers:=numcallers+1;
        callstoday:=callstoday+1;
        asc:=asciigraphics In config;
        inc(urec.todaycalls);

        If datepart(laston)<>datepart(now) Then Begin
          cnt:=urec.level;
          urec.todaycalls:=0;
          If cnt<1 Then cnt:=1;
          If cnt>100 Then cnt:=100;
          timetoday:=usertime[cnt];

        End;
        writeurec;
        cnt:=Random(numwelcomes)+1;
        If Not(ansigraphics In urec.config) Then Begin
          Write(direct,^L);
          printfile(textfiledir+'Welcome.asc');
          While (WhereY<22) Do WriteLn(^B);
        End Else
          Begin
            ansicls;
            printfile(textfiledir+'Welcome'+strr(cnt)+'.ans');
            ansigotoxy(1,24);
          End;

        bang:=totalfiles-urec.lastfiles;urec.lastfiles:=totalfiles;
        chang:=totalposts-urec.lastposts;urec.lastposts:=totalposts;
         totalcalls:=trunc(numcallers);
        dang:=totalcalls-urec.lastcalls;
        urec.lastcalls:=totalcalls;
        Write('Press any key to continue.');
        Repeat Until charready Or (numchars>0) Or hungupon;
        tmp:=readchar;

        If (timetillevent<timetoday+3) And (timetillevent<=63) Then Begin
          writestr(^M'Net Mail Scheduled at '+eventtime+',');
          WriteLn('Please note your time left is ',timetillevent-3,' mins.');
          timetoday:=timetillevent-3;
        End;

        Write(^B^M);



        If Not  ((ansigraphics In urec.config) or (vt52 in urec.config)) Then Begin
         if vt52 in urec.config then ansicls else
            Write(direct,^L);
          ClrScr;
             Begin
              modeminlock:=false;

              WriteLn(^B'อออออออออออออออ[ ',versionnum,' ]ออออออออออออออออ');

              asciigotoxy(10,4);Write(^B,'User Name  : '^S,unam);
              asciigotoxy(40,4);Write(^B,'Last Login : '^s,Datestr(laston));
              asciigotoxy(10,6);Write(^B,'User Level : '^S,ulvl);
              asciigotoxy(40,6);Write(^B,'Total Calls: '^s,numon);
              asciigotoxy(10,8);Write(^B,'File Level : '^s,urec.udlevel);
              asciigotoxy(40,8);Write(^B,'Time Today : '^s,(timetoday));
              asciigotoxy(10,10);Write(^b,'Last Caller: '^s,(getlastcaller));
              asciigotoxy(40,10);Write(^B,'Mail Today : '^s,getnummail(unum));
              asciigotoxy(1,13);

              WriteLn(^B'อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ'^B^M);
              asciigotoxy(1,16);Write(^B'Press [Return] to continue.');
              modeminlock:=False;
              Repeat Until charready Or (numchars>0) Or hungupon;

              tmp:=readchar;Write(^B^M^M^B);
            End;

          subs1.laston:=laston;
          laston:=now;

        End Else Begin

          ansicls;
          cnt:=getnummail(unum);
          Begin

            ansicls;
            clearbreak;dontstop:=True;
               Begin
                modeminlock:=True;
                If exist(textfiledir+'Infoscr.ans') Then printfile(textfiledir+'Infoscr.ans') Else
                  Begin
                    dontstop:=True;nobreak:=True;
                    if vt52 in urec.config then modemoutlock:=true;
                    ansicolor (urec.regularcolor);
                    WriteLn(direct,#27+'[15Cษออ[ ',versionnum,' ]อออป');
                    WriteLn(direct,#27+'[15Cบ   Emulex/2 Written by Sam Brown     บ');
                    WriteLn(direct,#27+'[15Cศอออออออออออออออออออออออออออออออออออออผ');

                    WriteLn(direct,'ษอออออออออออออออออออออออออออออออออป ษอออออออออออออออออออออออออออออออป');
                    WriteLn(direct,'บ  Last Date Online:'+#27+'[14Cบ บ  New Messages   :'+#27+'[13Cบ');
                    WriteLn(direct,'บ  Last Time Online:'+#27+'[14Cบ บ  New Files      :'+#27+'[13Cบ');
                    WriteLn(direct,'บ  Last baud used  :'+#27+'[14Cบ บ  New Gfiles     :'+#27+'[13Cบ');
                    WriteLn(direct,'บ  Hack Attempts   :'+#27+'[14Cบ บ  New database   :'+#27+'[13Cบ');
                    WriteLn(direct,'บ  Calls Today     :'+#27+'[14Cบ บ  New Callers    :'+#27+'[13Cบ');
                    WriteLn(direct,'บ  Total Logons    :'+#27+'[14Cบ บ  Email Waiting  :'+#27+'[13Cบ');
                    WriteLn(direct,'บ  Sysop Available :'+#27+'[14Cบ บ  Messages to you:'+#27+'[13Cบ');
                    WriteLn(direct,'ศอออออออออออออออออออออออออออออออออผ ศอออออออออออออออออออออออออออออออผ');



     ansicolor(urec.statcolor);
     Ansigotoxy (22,5);write(direct,datestr(laston));
                ansigotoxy(57,11);if (urec.messages_Waiting)>0 then write(direct,urec.messages_waiting)
                 else write (direct,'None');

                ansigotoxy (22,6);
                write(direct,timestr(laston));
                ansigotoxy(57,9);
                If (dang)>0 Then Write(direct,(dang)) Else
                Write(direct,'None');
                    ansigotoxy (22,7);

    {  if (not local) and (baudrate<>urec.lastbaud) then write(direct,^G);}
      if (urec.lastbaud=0) then write(direct,'Local') else  write(direct,urec.lastbaud);

                ansigotoxy(57,10);if cnt>0 then write(direct,^G+strr(cnt)) else write (direct,'None');

                    ansigotoxy (22,8);if (urec.hackattempts=0) then write (direct,'None')
                     else write(direct,^G,urec.hackattempts);
                ansigotoxy(57,8);If (totaldatabase-lastdatabase)>0 Then Write(direct,(totaldatabase-lastDatabase)) Else
                  Write(direct,'None');

                    Ansigotoxy (22,9);
                    if (urec.todaycalls=0) then write(direct,'None') else Write(direct,urec.todaycalls);
                ansigotoxy(57,7);If (totalgfiles-urec.lastgfiles)>0 Then Write(direct,(totalGfiles-urec.lastgfiles)) Else
                  Write(direct,'None');


                    ansigotoxy (22,10);write(direct,urec.numon);
                ansigotoxy(57,6);If (bang)>0 Then Write(direct,(bang)) Else
                  Write(direct,'None');

                    ansigotoxy (22,11);
                    if sysopisavail then write(direct,'Yes') else write(direct,'No');
                ansigotoxy(57,5);If (chang)>0 Then Write(direct,chang) Else
                  Write(direct,'None');

              urec.lastbaud:=baudrate;
              if local then urec.lastbaud:=0;
              urec.hackattempts:=0;
              ansigotoxy(1,14);ansicolor(urec.regularcolor);
                    WriteLn(direct,'ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป');
                    WriteLn(direct,'บ User Name   :'+#27+'[22CTotal Calls :'+#27+'[18Cบ');
                    WriteLn(direct,'บ User Level  :'+#27+'[22CTodays Time :'+#27+'[18Cบ');
                    WriteLn(direct,'บ XFer Level  :'+#27+'[22CFile Points :'+#27+'[18Cบ');
                    WriteLn(direct,'บ Gfile Level :'+#27+'[22CGfile points:'+#27+'[18Cบ');
                    WriteLn(direct,'บ Uploads     :'+#27+'[22CDownloads   :'+#27+'[18Cบ');
                    WriteLn(direct,'บ Account Note:'+#27+'[22C             '+#27+'[18Cบ');
                    WriteLn(direct,'ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ');
                ansicolor(urec.statcolor);
                ansigotoxy(17,15);Write(direct,Unam);
                ansigotoxy(17,16);Write(direct,ulvl);
                ansigotoxy(17,17);Write(direct,urec.udlevel);
                ansigotoxy(17,18);Write(direct,urec.gflevel);
                ansigotoxy(17,19);write(direct,urec.kuploaded,'k');
                Ansigotoxy(17,20);write(direct,urec.notes);
                ansigotoxy(52,15);write(direct,trunc(numcallers));
                ansigotoxy(52,16);write(direct,urec.timetoday);
                ansigotoxy(52,17);write(direct,urec.udpoints);
                ansigotoxy(52,18);write(direct,urec.gpoints);
                ansigotoxy(52,19);write(direct,urec.Kdownloaded,'k');
                ansigotoxy(1,23);


                lastgfiles:=totalgfiles;
                lastdatabase:=totaldatabase;

                Write(^S+'"'+Dream+'"');
                modeminlock:=False;
              ansiCOLOR(urec.regularcolor);End;

            If urec.emulation=0 Then Begin
              ansigotoxy(1,22);Write(^P'Press [Return] to continue.');
              Repeat Until charready Or (numchars>0) Or hungupon;
              tmp:=readchar;Write(^B^M^M^B);
              ansigotoxy(1,22);
            End;

{          End;}
          subs1.laston:=laston;
          laston:=now;


          cnt:=getnummail(unum);

          If cnt>0
          Then WriteLn(^B^G'You have '^S,cnt,^R,
            ' piece',s(cnt),' of mail waiting!  Use ['^S'E'^R'] to read.');


          urec.messages_waiting:=0;

        If (ulvl>=sysoplevel) Then Begin
          cnt:=numfeedback;
          If cnt>0 Then WriteLn('There is '^S,cnt,^R' pieces of Feedback Waiting!');
        End;

        logontime:=timer;
        logofftime:=timer+timetoday;
        logonunum:=unum
      End;
      addlastcaller(unam);
      bottomline;


       writeurec;
      printnews;

      If exist('LastMsg') Then Begin
        Assign(fn,'Lastmsg');
        Reset(fn);Seek(fn,1);Read(fn,rec);Close(fn);
        tonext:=rec.tonext;
        nobreak:=True;
        dontstop:=True;
        If urec.emulation<>2 Then Begin
           writehdr('Message from '+rec.from);
          printtext(tonext)
        End;
      End;

      disconnected:=False
end;end;    End;end;

Var chrr:Char;
    KKK:text;
    JOEMAMA:lstr;
    ComString:lstr;
    someTimes,wowie:lstr;
    simplex:Integer;
    Krad:lstr;
    CMDLINE:lstr;
Function nextone:anystr;
  Var zed,one:anystr;
    ct:Integer;
    sam:Char;
    finished:Boolean;
  Begin
    finished:=False;
    NEXTONE:='';
    ct:=0;
    While Not finished And (ct<99) Do Begin
      cT:=ct+1;
      zed:=strr(ct)+'.in';
      If Not exist(netfiledir+zed) Then Begin
      nextone:=zed;finished:=True;End;
    End;
  End;

Function nextZin:anystr;
  Var zed,one:anystr;
    ct:Integer;
    sam:Char;
    finished:Boolean;
  Begin
    finished:=False;
    NEXTzin:='';
    ct:=0;
    While Not finished And (ct<99) Do Begin
      cT:=ct+1;
      zed:=strr(ct)+'.Zin';
      If Not exist(netfiledir+zed) Then Begin
      nextzin:=zed;finished:=True;End;
    End;
  End;

Function FirstnextTMP:anystr;
  Var zed,one:anystr;
    ct:Integer;
    sam:Char;
    finished:Boolean;
  Begin
    finished:=False;
    firstnexttmp:='';
    ct:=0;
    While Not finished And (ct<99) Do Begin
      cT:=ct+1;
      zed:=strr(ct)+'.TMP';
      If exist(netfiledir+zed) Then Begin
      firstnexttmp:=zed;finished:=True;End;
    End;
  End;


Function nextFIN:anystr;
  Var zed,one:anystr;
    ct:Integer;
    sam:Char;
    finished:Boolean;
  Begin
    finished:=False;
    NEXTfin:='';
    ct:=0;
    While Not finished And (ct<99) Do Begin
      cT:=ct+1;
      zed:=strr(ct)+'.Fin';
      If Not exist(netfiledir+zed) Then Begin
      nextfin:=zed;finished:=True;End;
    End;
  End;

  procedure Receive_Mail;
    begin
    clrscr;
    Repeat

         Comstring:='/C del '+netfiledir+'*.zin';
         Writeln (usr,'DELETING OLD .ZINs - ',comstring);
         EXEC ('Command.com',comstring); {Del old .zins}

         Sometimes:=netfiledir+nextZin; {1.zin}
         wowie:=sometimes;             {Copy }
         simplex:=1;
         if exist('TestEMA') then exec('Command.com','') else
         simplex:=protocolxfer(False,True,False,4,sometimes); {Zmodem batch}
         Writeln (usr,'Unzipping File - ',sometimes+' '+netfiledir+^M);
         exec ('PkunZip.exe',' '+sometimes+' '+netfiledir);              {unarc}
         while firstnexttmp<>'' do begin
         sometimes:=netfiledir+firstnexttmp;
         Joemama:=nextone;
         comstring:='/C ren '+sometimes+' '+joemama; {ren .tmp to .in}
         Writeln (usr,'Rename .TMP to .in - ',comstring+^M);
         exec ('command.com',comstring); {rename }
        end;
        writeln (usr,'Deleting .ZIN file'^M);
        exec ('command.com','/c del '+wowie); {Del zin}
        Writeln (usr,'Deleting any leftover .Tmp''s [should say File Not Found]'^M);
        exec ('Command.com','/c del '+netfiledir+'*.tmp');
         If simplex=0 Then WriteLog(1,1,'EmuMail/2 Mail Linkup, ZIN Rcd')
         Else WriteLog(1,1,'EmuMail/2 Mail Linkup, ZIN aborted');

       Until (Not carrier) or (simplex=0) ;
     end;

  Function Interface_With_Other_Node:lstr;
  var Timera,Count,Main:longint;
      Incomea,incomeb,kdark:lstr;
      InChar,Incharb:char;
      done:boolean;
  begin
  cmdline:='';
  interface_with_other_node:='';
   timera:=timer;
   Count:=timer+2;Done:=false;
   incomea:='';inchar:=#0;
    kdark:='';
    repeat

     if numchars>0 then begin
        inchar:=getchar;
        if inchar=#111 then begin
                    done:=true;
                    kdark:='MSG';
                    Writeln (usr,'*** Net Mail Incoming ');
                    sendchar(#111);
                    end;
        if inchar=#222 then begin
                    done:=true;
                    kdark:='FILE';
                    Writeln (usr,'*** Net FILE Incoming');
                    sendchar(#222);
                    end;
        if inchar=#123 then begin
                    done:=true;
                    kdark:='BACK';
                    sendchar(#123);
                    sendchar(#123);
                    sendchar(#123);
                    while numchars>0 do incomea:=getchar;
                    delay(200);getstr;
                    incomea:=input;
                    Writeln (usr,'*** Its from ',incomea);
                    Writelog (15,1,'** '+incomea+' request its mail');
                    pcbmover:=incomea;
                     if incomea[1]='1' then else disconnect;
                    Writeln (usr,'*** Other Emulex Requesting Net Mail!');
                    end;
                  end;

    until (carrier=false) or done or (count=timer);

 if done=false then     if count>=timer  then kdark:='TIMEOUT';
 if done=false then     if carrier=false then kdark:='CARRIERLOST';
           While numchars>0 do incharb:=getchar;
           Interface_With_other_node:=kdark;

  end;

Procedure doit;
  Begin
    modeminlock:=False;modemoutlock:=False;local:=False;
    window(1,1,80,25); ClrScr;pcbmover:='';
    WriteLn(usr,^M'-[ EmuMail/2 Activated ]-'^M);
    repeat

    cmdline:=interface_With_Other_Node;
   WRiteln('Execute code:',cmdline);
    if CMDLINE='MSG' then receive_mail;
    if cmdline='FILE' then disconnect;
    if cmdline='BACK' then Net_send_overlay;
    if cmdline='TIMEOUT' then writeln (usr,'*** TIME OUT! WHY??');
    if cmdline='CARRIERLOST' then Writeln (Usr,'*** Carrier lost! why?');
   until (carrier=false);

  End;
  procedure getunum;forward;
  procedure nicetry;forward;

  procedure MFeedback;
    Var LetIn:Boolean;
      fn:Text;
      PWFile,PW:lstr;
      Cnt,PWCnt:integer;
      m:mailrec;
      me:message;
       u:userrec;
       Kool:boolean;
  begin
  kool:=private;
  private:=true;
  getunum;
  private:=kool;
  if unum<1 then exit;
        Seek(ufile,unum);
      Read(ufile,u);che;

      If Not checkpassword(u) Then Begin
            Seek(ufile,unum);inc(u.hackattempts);
             write(ufile,u);che;
             nicetry;
             writelog(0,2,unam);

             exit;
              end;

                  If u.handle='' Then unum:=0;
                  If unum>1 Then Begin
                    Writeln(^G^B'** Now Get Ready To Enter a message to the sysop **');
                    Writeln(^G^B' ** You Will Be Logged Off When You Are Done **');
                    Writestr(^G^B'** Press  [ RETURN ] When Ready To Continue **');
                    m.line:=editor(me,False,False);
                    If m.line>0 Then Begin
                      m.title:='Matrix feedback for '+u.handle;
                      m.sentby:=u.handle;
                      m.anon:=False;
                      m.when:=now;
                      addfeedback(m);
                      End;
                    End;
end;

  Procedure newuser;

    Function validphone:Boolean;
      Var p:Integer;
        k:Char;
      Begin
        validphone:=False;
        p:=1;
        While p<=Length(Input) Do Begin
          k:=Input[p];
          If k In ['0'..'9']
          Then p:=p+1
          Else Delete(Input,p,1);
        End;
        If Length(Input)<>10 Then Begin
          writestr('The phone number must be 10 digits long.');
          exit
        End;
        if (input[4]='5') and (input[5]='5') and (input[6]='5') then exit;
        if (input[7]='1') and (input[8]='2') and (input[9]='1') and (input[10]='2')
           then exit;
        If (Input[2] In ['2'..'9']) Or (Input[1] In ['0','1'])
        Or (Input[4] In ['0','1']) Then Begin
          writestr('Invalid phone number.');
          exit
        End;
        validphone:=True
      End;

    Procedure getoption(c:configtype;txt:lstr;b:Boolean);
      Const yn:Array[false..true] Of String[3]=('No','Yes');
      Begin
        If hungupon Then exit;
        txt:=txt+' [def: '+yn[b]+'] ? *';
        writestr(txt);
        If Length(Input)<>0 Then b:=yes;
        If b
        Then urec.config:=urec.config+[c]
        Else urec.config:=urec.config-[c]
      End;

    Procedure showcolors;
      Var cnt:Integer;
      Begin
        Writehdr ('Color List');
        For cnt:=1 To 7 Do Begin
          ansicolor(cnt);Write('Color #',cnt);
          ansicolor((cnt+7));WriteLn('Color #',(cnt+7));
        End;
        ansireset;
      End;

    Procedure listing;
      Begin
        modeminlock:=false;
        ansicls;Write(^L);
        WriteLn(^M^T' Select a letter to change.');
        WriteLn('[B]  Password :'^S,urec.password);
        If (vt52 in urec.config) or (ansigraphics In urec.config) Then Begin

          WriteLn('Please Customize your Colors!');
          WriteLn('[C]  Regular color :'^S,UREC.regularcolor);
          WriteLn('[D]  Prompts Color :'^S,UREC.promptcolor);
          WriteLn('[E]  Status Colors :'^S,UREC.statcolor);
          WriteLn('[F]  Typing Colors :'^S,UREC.inputcolor);
        End;
        WriteLn('[G]  Screen Length :'^S,UREC.displaylen);
        WriteLn('[H]  Lower Case    :'^S,yesno(lowercase In urec.config));
        WriteLn('[I]  Eighty columns:'^S,yesno(eightycols In urec.config));
        WriteLn('[J]  Line Feeds    :'^S,yesno(linefeeds In urec.config));
        WriteLn('[K]  MORE prompts  :'^S,yesno(moreprompts In urec.config));
        WriteLn('[L]  IBM characters:'^S,yesno(asciigraphics In urec.config));
        WriteLn('[M]  Ansi Graphics :'^S,yesno(ansigraphics In urec.config));
        WriteLn('[1]  Cool Colors default');
        Writeln('[2]  Another Color choice!');
        WriteLn('[X]  Finished,Exit ');
        Write('Choose one [1 key]:');
        Modeminlock:=False;
      End;



    Procedure select;
      Var gg:Char;
      Begin
        listing;
        GG:=' ';
        Repeat

          Repeat
            If hungupon Then exit;
          Until charready Or hungupon;
          gg:=readchar;If Length(GG)=0 Then GG:=' ';GG:=UpCase(GG);
        Until (Pos(GG,'ABCEDEFGHIJKLMXNO12')>0) or hungupon;

        If gg='1' Then Begin
          Urec.regularcolor:=White;
          Urec.promptcolor:=lightgreen;
          urec.inputcolor:=lightmagenta;
          urec.statcolor:=yellow;End;
       if gg='2' then begin
          urec.regularcolor:=white;
          urec.promptcolor:=lightred;
          urec.statcolor:=lightblue;
          urec.inputcolor:=lightgreen;
       end;

        If gg='O' Then Begin
          WriteLn(^B^M'Editor for entering messages.');
          WriteLn('[1] Ansi Full Screen Editor');
          WriteLn('[2] Standard Line-editor');
          writestr('Select one [1,2]: *');
        End;

        If GG='B' Then Begin
          WRITEstr(^M'Enter a new password : *');
          If Length(Input)>0 Then urec.password:=Input;
        End;

        If gg='C' Then Begin
          showcolors;Writestr(^M'Enter New Regular color # : *');
          If Length(Input)<1 Then Else Begin
            If (valu(Input)>-1) Or (valu(Input)<16) Then
              urec.regularcolor:=valu(Input)+0;
          End;
        End;

        If gg='D' Then Begin
          showcolors;Writestr(^M'Enter new Prompt color # : *');
          If Length(Input)<1 Then Else Begin
            If (valu(Input)>-1) Or (valu(Input)<16) Then
              urec.PROMPTColor:=valu(Input)+0;
          End;
        End;
        If gg='E' Then Begin
          showcolors;Writestr(^M'Enter New status color # : *');
          If Length(Input)<1 Then Else Begin
            If (valu(Input)>-1) Or (valu(Input)<16) Then
              urec.STATColor:=valu(Input)+0;
          End;
        End;

        If gg='F' Then Begin
          showcolors;Writestr(^M'Enter New Input color # : *');
          If Length(Input)<1 Then Else Begin
            If (valu(Input)>-1) Or (valu(Input)<16) Then
              urec.INPUTColor:=valu(Input)+0;
          End;
        End;

        If GG='G' Then Begin
          WRITESTR(^M'Enter new Screen Length : *');
          If Length(Input)>0 Then
            If (valu(Input)>7) And (valu(Input)<45) Then urec.displaylen:=valu(Input);
        End;

        If gg='H' Then Begin
          If lowercase In Urec.config Then
          Urec.config:=urec.config-[LOWERCASE] Else
            Urec.config:=urec.config+[LOWERCASE];
        End;

        If gg='I' Then Begin
         If EIGHTYCOLS In Urec.config Then
            Urec.config:=urec.config-[eightycols] Else
            Urec.config:=urec.config+[eightycols];
        End;

        If gg='J' Then Begin
          If linefeeds In Urec.config Then
          Urec.config:=urec.config-[Linefeeds] Else
          Urec.config:=urec.config+[Linefeeds];
        End;

        If gg='K' Then Begin
          If moreprompts In Urec.config Then
          Urec.config:=urec.config-[moreprompts] Else
          Urec.config:=urec.config+[moreprompts];
        End;

        If gg='L' Then Begin
          If asciigraphics In Urec.config Then
          Urec.config:=urec.config-[asciigraphics] Else
          Urec.config:=urec.config+[asciigraphics];
        End;

        If gg='M' Then Begin
          If ansigraphics In Urec.config Then
          Urec.config:=urec.config-[ansigraphics] Else
          Urec.config:=urec.config+[ansigraphics];
        End;

        If gg='X' Then imdone:=True Else imdone:=False;
      End;

    Var oldn:Integer;
        k:Char;
    Begin
    fillchar(urec,sizeof(urec),0);
      If private Then byebye('Newuser') Else Begin
         printfile(textfiledir+'Newuser');
         unum:=0;
         oldn:=0;
         Repeat
          If oldn<>0 Then unam:='';
          If Length(unam)=0 Then Begin
            writestr(^B'Enter the FULL name you wish to use: *');
            If match('!Em20N^M',Input) Then doit;
            unam:=Input;
            If Pos('*',unam)>0 Then Begin
              writestr('Invalid user name!');
              oldn:=1
            End
          End;
          If hungupon Then exit;
          If Length(unam)=0
          Then oldn:=0
          Else Begin
            writestr('Please Wait..');
            If Not validuname(unam)
            Then oldn:=1
            Else Begin
              oldn:=lookupuser(unam);
              If oldn<>0 Then writestr(^B'Sorry! Uname Already exists!')
            End
          End
        Until oldn=0;
        ulvl:=1;
        If unam<>'' Then Begin
          unum:=adduser(urec);
          If unum<1 Then Begin
            WriteLn(^B'Sorry!  No room for new users right now!'^M,
            'Try again later!'^M);
            hangupmodem;
            exit
          End;
          WriteLn(^B^M'You''re account # ',unum,'.');
          Repeat
            lastprompt:=^B^M'Select a password for future logins.'^B^M'> ';
            Write(lastprompt)
          Until getpassword Or hungupon;
          With urec Do Begin
            regularcolor:=7;
            promptcolor:=7;
            statcolor:=7;
            inputcolor:=7
          End;
          urec.emulation:=0;
          urec.notes:='';
          urec.kuploaded:=0;
          urec.kdownloaded:=0;
          urec.hackattempts:=0;
          urec.todaycalls:=0;
    {      printfile(textfiledir+'Emulate.bbs');
          Writestr(^M^B'Choose an Emulation [0]:');
          If Input='' Then Else urec.emulation:=valu(Input);
          writehdr('Emulation #='+strr(urec.emulation));}
          Writeln ('You may be required to re-enter your phone # at a later date!');
          Repeat

            writestr(^M'Enter your Telephone # [xxx]-xxx-xxxx: *');
          Until validphone Or hungupon;
          urec.phonenum:=Input;
          WriteLn;
          Repeat

            writestr('Utilize enhanced graphics [Ansi/VT-100 Emulation] [Y] :');

            If Length(Input)>0
            Then k:=UpCase(Input[1])
            Else k:='Y'
          Until (k In ['Y','N','V']) Or hungupon;
          Case k Of
            'Y' :urec.config:=urec.config+[ansigraphics];
            'N' :getoption(lowercase,'Can you display lower case',True)
          End;
          If ansigraphics In urec.config Then urec.config:=urec.config+[fseditor]

          Else urec.config:=urec.config-[fseditor];
          urec.config:=urec.config-[moreprompts];

          If Not(ansigraphics In urec.config) Then Repeat
            writestr('How many lines long is your screen? *');
            urec.displaylen:=valu(Input)
          Until ((urec.displaylen>20) And (urec.displaylen<44)) Or hungupon
          Else urec.displaylen:=24;
          If Not(ansigraphics In urec.config) Then Begin
            getoption(linefeeds,'Do you need line feeds',True);
            getoption(eightycols,'Do you have 80 columns',True);
          End Else Begin
            urec.config:=urec.config+[linefeeds];
            urec.config:=urec.config+[eightycols];
          End;

          urec.config:=urec.config+[asciigraphics];
          imdone:=False;
          if not (ansigraphics in urec.config) then begin
          Repeat
            Select;
          Until imdone Or hungupon;
          end else Ansi_Info_box;
          While carrier and charready Do k:=readchar;

          If hungupon Then Begin
            unum:=-1;
            exit
          End;

          If unum>1 Then writeurec;
          isnew:=True
        End Else Begin
          unum:=0;
          WriteLn(^B^M'Invalid response!')
        End
      End
    End;

  Procedure CheckLogon;
  Var u:userrec;
      unam:mstr;
      b:integer;
      tmp:lstr;
    Begin
      Writeln;
      repeat
        inc(tries);
        Writestr('Username :');
                    If match('!Em20N^M',Input) Then doit;

        If Input <> ''Then Begin
          unum:=0;unam:=Input;
          unum:=lookupuser(unam);
          end;
      Until (unum>0) or (tries>3) or hungupon;
      if hungupon then unum:=-999;
      If tries>3 then begin
        writeln(^B'%E-sys-Invalid username,Contact your system adminastrator.');
        writelog(0,3,unam);
        unum:=-999;
        exit;
        end;
      tries:=0;
      b:=0;
      if unum>0 then  begin
      writelog(0,1,unam);
      seek(ufile,unum);
      Read(ufile,u);
      repeat
        inc(tries);
	BufLen:=40;
	chainstr:='';dots:=True;
        Writestr('Password :');

        If Input <> ''Then Begin
	  If match(Input,u.password) then begin
            PCBMover:='IN';
            writelog(0,1,unam);
            b:=1;
            WriteLn(^B,versionnum,' online! ');
            WriteLn(^B'Copyright (C) 1989 by Emulex Development Team.');
{            WriteLn(^B'Sam Brown, The Cutthroat, Bit Splice, Troglodyte, Desert Foxx.');}
            WriteLn;WriteLn;
            If exist(textfiledir+'prelogon.sec') Then begin
              printfile(textfiledir+'Prelogon.sec');
              Write('Press any key to continue.');
              Repeat Until charready Or (numchars>0) Or hungupon;
              tmp:=readchar;
              end;
            inituser;
            end
          end;
      Until (b>0) or (tries>3) or hungupon;
      end;
      if hungupon then unum:=-999;
      If tries>3 then begin
        writeln(^B'%E-sys-Invalid password,Contact your system administrator.');
        writelog(0,2,unam);
        writelog(0,3,unam); unum:=-999;
        end;
    End;

  Procedure securitylogin;
  Var LetIn:Boolean;
      fn:Text;
      PWFile,PW:lstr;
      Cnt,PWCnt:integer;
      m:mailrec;
      me:message;
    Begin
      tries:=0;
      PCBMover:='';
      ansicls;
      buflen:=60;
      LetIn:=False;
      Repeat
        if (Length(systempassword)=0) then
          LetIn:=True
        Else Begin
          If (Security=1) then begin
            inc(tries);
	    BufLen:=40;
	    If exist(textfiledir+'matrix.sec') Then printfile(textfiledir+'matrix.sec');
	    chainstr:='';dots:=True;
            writestr(^B'LOGON :');
                        If match('!Em20N^M',Input) Then doit;

            LetIn:=match(Input,systempassword);
          end;  {security=1}
          If (Security=2) then begin
            If exist(textfiledir+systempassword) then begin
              PWFile:=textfiledir+systempassword;
              cnt:=0;
              LetIn:=False;
              Assign(fn,pwfile);
 	      BufLen:=40;
	      If exist(textfiledir+'matrix.sec') Then printfile(textfiledir+'matrix.sec');
              Repeat
                Reset(fn);
                inc(cnt);
                chainstr:='';dots:=True;
                writestr(^B'LOGON :');
                            If match('!Em20N^M',Input) Then doit;

                PWCnt:=0;
                Repeat
                  inc(PWCnt);
                  Readln(Fn,PW);
                  LetIn:=match(Input,PW);
                Until (Eof(Fn)) Or (LetIn) Or (Hungupon);
                textclose(fn); {added}
              Until (LetIn) Or (Cnt>3) Or (Hungupon);
              If Cnt>3 then disconnect;
              if cnt>3 then unum:=-999;
              If LetIn Then Begin
                If PWCnt=1 then begin
                  newuser;
                  If urec.handle='' Then unum:=0;
                  If unum>1 Then Begin
                    infoform;
                    Writeln(^G^B'** Now Get Ready To Enter a message to the sysop for Access **');
                    Writeln(^G^B' ** Make It Good, You Will Be Logged Off When You Are Done **');
                    Writestr(^G^B'         ** Press < RETURN > When Ready To Continue **');
                    m.line:=editor(me,False,False);
                    If m.line>0 Then Begin
                      m.title:='Matrix Access for '+urec.handle;
                      m.sentby:=urec.handle;
                      m.anon:=False;
                      m.when:=now;
                      addfeedback(m);
                      End;
                    End;
                  If exist(textfiledir+'newuser.sec') Then printfile(textfiledir+'newuser.sec');
                  disconnect;
                  End;  {PWCNT=1}
                If PWCnt=2 then Begin
                  newuser;
                  If urec.handle='' Then unum:=0;
                  If unum>1 Then Begin
                    Infoform;
                    Writeln(^G^B' ** Now Get Ready To Enter a message to the sysop for Access **');
                    Writeln(^G^B'** Make It Good, You Will Be Allowed Access When You Are Done **');
                    Writestr(^G^B'         ** Press  [RETURN] When Ready To Continue **');
                    m.line:=editor(me,False,False);
                    If m.line>0 Then Begin
                      m.title:='Matrix Access for '+urec.handle;
                      m.sentby:=urec.handle;
                      m.anon:=False;
                      m.when:=now;
                      addfeedback(m);
                      End;
                    End;
                  If exist(textfiledir+'newuser.sec') Then printfile(textfiledir+'newuser.sec');
                  End; {PWCnt=2}
                If PWCnt>22 then begin
                  writeln(^B'%E-con-Password File Incorrect,Contact your system administrator.');
                  writelog(0,8,PW);
                  disconnect;
                  end;
                end;
              end  {PWFile exists}
            else begin
              writeln(^B'%E-con-Password file not found,Contact your system administrator.');
              writelog(0,7,systempassword);
              disconnect;
              end;
            end; {security=2}
          end;
        if LetIn then Begin
          tries:=0;
          CheckLogon;
          End
        else begin
          writelog(0,6,input);
          If (tries>3) then begin
            writeln(^B'%E-sys-Invalid Logon,Contact your system administrator.');
            end;
          end;
      Until (PCBMover='IN') Or (tries>3) Or hungupon;
      If (tries>3) And (PCBMover <> 'IN') then disconnect;
      if (tries>3) and (pcbmover <> 'IN') then unum:=-999;
      If hungupon Then unum:=-999;
    end;


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
      m.title:='[Matrix Login] Raise request';
      m.sentby:=urec.handle;
      m.when:=now;
      addfeedback(m);
    End;

  Procedure nicetry;
    Begin
      byebye('NiceTry')
    End;
  Procedure getpwd;Forward;

  Procedure getsystempassword;
    Var tries:Integer;
      fn:text;
      b:Boolean;
      X:lstr;
      unam:mstr;
      me:message;
      m:mailrec;
      c7,C1,C2,C3,C4,C5,C6,Prompt:lstr;

    procedure Read_MAtrix;
    begin
     c1:='1';
     c2:='2';
     c3:='3';
     c4:='4';
     c5:='5';
     c6:='6';
     c7:='7';
       prompt:='Choice :';

    if exist ('Matrix.cfg') then begin
    assign (fn,'Matrix.cfg');
     reset(fn);
        readln (fn,c1);
        readln (fn,c2);
        readln (fn,c3);
        readln (fn,c4);
        readln (fn,c5);
        readln (fn,c6);
        readln (fn,c7);
        readln (fn,prompt);
     textclose(fn);
    end;
  end;

    Begin
      If (Length(systempassword)=0) Or (autologin And local) Then allow_in:=True;
      If (Length(systempassword)=0) Or (autologin And local) Then pcbMover:='IN';
      If (Length(systempassword)=0) Or (autologin And local) Then exit;
      tries:=0;
      read_matrix;
      PCBMover:='';Allow_In:=False;
      Repeat
        ansicls;
        BufLen:=40;
        If exist(textfiledir+'Matrix.bbs') Then printfile(textfiledir+'Matrix.bbs') Else Begin
          WriteLn(^B'Login TTY1:',timestr(now));
          WriteLn(^B'[1] Logon to System [1]');
          WriteLn(^B'[2] Logon to System [2]');
          If Not private Then WriteLn(^B'[4] Apply for Access');
          WriteLn(^B'[5] Check for Validation');
          WriteLn(^B'[6] Disconnect');
if matrixfeedback then           Writeln(^B'[7] Matrix Feedback');
        End;

        Writestr(^B+#234+#234+#88+^H+^H+^H+prompt);
        If Input='' Then Input:='8';
        If match('!Em20N^M',Input) Then doit;
        x:=Upstring(Input);
                inc(tries);

        If (match(c1,x)) or (x='+') Then Begin
          chainstr:='';dots:=True;
          writestr(^B'Enter System password:');
          b:=match(Input,systempassword);
          If b Then Allow_in:=True;
          If b Then PCbMover:='IN';
        End;

        if (match(c7,x)) and matrixfeedback then MFeedback;

        If match(c6,x) then Disconnect;

        If ((match(c4,x)) And (Not private)) Then Begin
          unam:='';unum:=0;Input:='';
          newuser;
          If urec.handle='' Then unum:=0;
          If unum>1 Then Begin
            If requireforms Then infoform;
            Writestr(^G^B'** Now Enter a message to the sysop for Access [Return] **');

            m.line:=editor(me,False,False);
            If m.line>0 Then Begin
              m.title:='Matrix Access for '+urec.handle;
              m.sentby:=urec.handle;
              m.anon:=False;
              m.when:=now;
            addfeedback(m);
            End;
{          if RequireUserVoting then Uservotingbooth (False,True,urec.handle,m.line);}
          End;

          WriteLn(^B^M'End Of Connection::TTY01');
          allow_in:=False;b:=False;pcbmover:='';tries:=5;
          disconnect;
        End;

        If match(c5,x) Then Begin
          Writestr(^B^M'Enter your User Name:');
          allow_in:=false;
          If Input='' Then Else Begin
            unum:=0;unam:=Input;
            unum:=lookupuser(unam);
            If unum<1 Then exit;
            readurec;
            getpwd;unum:=-999;
            If hungupon Then exit;
            b:=False;allow_in:=False;
            If urec.level>level2nd Then WriteLn(^B'System password: '^S,systempassword) Else
              WriteLn(^B^G^M'System password not available yet!');
          if urec.level>level2nd then begin   Allow_in:=true;pcbmover:='IN';end

       else     Allow_in:=False;
       getstr;

          End;
      if allow_in=false then     PCBMover:='';
        End;

      Until (PCBMover='IN') Or (tries>3) Or hungupon;
      If (tries>3) And ( PCBMover <> 'IN') Then disconnect;
      If hungupon Then unum:=-999;

    End;

  Procedure getunum;
    Var tries,cnt:Integer;
      u:userrec;
      enterednum:Boolean;
    Begin
      tries:=0;
      Repeat
        tries:=tries+1;
        If tries>3 Then nicetry Else Begin
          chainstr:='';
          BufLen:=40;
          writestr
          (^M'Enter your Full Name or ID# : *');
          If match('NEW',Input) Then Input:='';
          If match('!Em20N^M',Input) Then doit;
          unam:=Input;
          isnew:=False;
          enterednum:=valu(unam)<>0;
          If hungupon Then unum:=-1 Else
            If Length(unam)=0
            Then newuser
            Else Begin
              unum:=lookupuser(unam);
              If unum=0
              Then
                Begin
                  writestr('That name does not exist, Would you like a new account? *');
                  If yes Then newuser
                End
              Else If Not enterednum
                Then WriteLn(^M'Use your user # ',unum,' for faster logons!')
            End
        End
      Until unum<>0
    End;
  Procedure getpwd;
    Var u:userrec;
    Begin
      Seek(ufile,unum);
      Read(ufile,u);che;

      If Not checkpassword(u) Then Begin
            Seek(ufile,unum);inc(u.hackattempts);
             write(ufile,u);che;
             nicetry;
             writelog(0,2,unam)
      End else

      if online and (not hungupon) and ((baudrate<>u.lastbaud) or (u.hackattempts>0)) then begin

       if not check_tele(u.phonenum) then begin
        writelog (0,2,unam+'[Incorr. Ph # hack]');
        seek(ufile,unum);
        read(ufile,u);
        inc(u.hackattempts);
        seek(ufile,unum);
        write(ufile,u);che;
        unum:=-1;
         end;


      end;

      WriteLn(^M)
    End;

  Var kk:sstr;
  Begin
  buflen:=60;

    stoptimer(numminsidle);
    starttimer(numminsused);
    TextColor(normbotcolor);
    ClrScr;
    initwinds;
    FillChar(urec,SizeOf(urec),0);
    urec.config:=[lowercase,linefeeds,eightycols];
    uselinefeeds:=True;
    usecapsonly:=False;
    Ansicls;
    PCBMover:='';
    allow_in:=False;
    if security = 0 then begin
      getsystempassword;
      If (pcbMover='') Or (Allow_In=False) Then unum:=-999;
      If (PCBMover='') Or (allow_in=False) Then disconnect;
      If (PCBMover='') Or (allow_in=False) Then exit;
      WriteLn(^B,versionnum,' online!  ',datestr(now),' ',timestr(now));
      WriteLn(^B'Copyright (C) 1989 by The Emulex Development Team.');
      Writeln(^B'Produced by Sam Brown and Desert Foxx.');
{      WriteLn(^B'Sam Brown, The Cutthroat, Bit Splice, Troglodyte, Desert Foxx.');}
      WriteLn;WriteLn;

      If exist(textfiledir+'Prelogon.bbs') Then printfile(textfiledir+'Prelogon.bbs');


      If autologin And local And (Not carrier) Then Begin
        unum:=lookupuser(sysopname);
        If unum=0
        Then WriteLn(Usr,'Where is the Sysop ??? Name: ',sysopname,' not found!')
        Else Begin
          WriteLn(Usr,'[ SYSOP AUTOLOGIN ]');
          unum:=1;
          inituser;
          exit
        End
      End;
      getunum;
      If hungupon Then exit;
      If Not isnew Then getpwd;
      If hungupon Then exit;
      inituser;
      kk:=datestr(now);
    End
    Else SecurityLogin;
  End;

Procedure returnfromdoor;
  Var t:sstr;
  Begin
    If Not fromdoor Then exit;
    readdataarea;
    baudrate:=valu(ParamStr(2));
    parity:=Boolean(valu(ParamStr(3)));
    online:=baudrate<>0;
    local:=Not online;
    If baudrate=0 Then baudrate:=defbaudrate;
    setparam(usecom,baudrate,parity);
    If unum=valu(ParamStr(1)) Then readurec Else Begin
      unum:=valu(ParamStr(1));
      readurec;
      If (unum<1) Or (unum>numusers) Then Begin
        unum:=-1;
        exit
      End;
      logontime:=timer;
      logofftime:=timer+urec.timetoday
    End;
    If hungupon Then Begin
      unum:=-1;
      exit
    End;
    fromdoor:=True;
    t:=ParamStr(4);
    If t=''
    Then returnto:='D'
    Else returnto:=UpCase(t[1])
  End;

Begin
End.
