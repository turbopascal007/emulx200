  {$R-,S-,I-,D-,f+,V-,B-,N-,L+,O- }
  unit newnet;

  interface
  uses dos,crt,
  gentypes,gensubs,subs1,userret,flags,mainr1,modem,windows,statret,configrt,protocol;



Procedure Net_Send_Overlay;
implementation
Procedure Net_Send_Overlay;
  Var Finished,z:Boolean;
    Outs:Array[1..30] Of Boolean;
    PCP:Char;
    CurBaud:integer;

    function getcurbaud(vv:lstr):integer;
    var tmpbaud,CC:integer;
       done:boolean;
       Bud:sstr;

    begin
    if not carrier then begin

    done:=false;
    bud:=copy(vv,1,4);
          tmpbaud:=valu(bud);
          if tmpbaud<1200 then writeln (usr,'Invalid baud');
          if tmpbaud<1200 then getcurbaud:=baudrate;
          if tmpbaud<1200 then exit;
          if tmpbaud<1200 then tmpbaud:=1200;
         { Write (usr,bud,'=',tmpbaud);}
     curbaud:=tmpbaud;
     getcurbaud:=tmpbaud;
     if baudrate<>tmpbaud then begin
               closeport;
               Writeln (usr,'Changing comm C:',usecom,' B:',tmpbaud) ;
               Setparam(usecom,tmpbaud,False);
             end;
    end;
    end;

  Procedure clearitall;
    Var a:Char;
    Begin
      While numchars>0 Do a:=getchar;write(usr,a);
    End;

  Procedure disco;
    Begin
      dontanswer;
      Delay(500);
      doanswer;
    End;

  Procedure Print_It;

    Begin
    window (1,1,80,25);
      ClrScr;
      GoToXY(1,9);
      WriteLn(Usr,'Outgoing:');
      GoToXY(1,10);
      WriteLn(Usr,'Outgoing to Dest: ');
      GoToXY(1,11);
      WriteLn(Usr,'Outgoing Already Sent: ');
      GoToXY(1,13);
      WriteLn(Usr,'Destination: ');
      GoToXY(63,13);
      WriteLn(Usr,'Time: [  ]');
      GoToXY(1,14);
      WriteLn(Usr,'Status: ');
      GoToXY(30,17);
      WriteLn(Usr,'EmuMail/2 1.61 (C) 1989 by Sam Brown.');
      GoToXY(1,18);
      WriteLn(Usr,'_______________________________________________________________________________');
      GoToXY(5,20);
      WriteLn(Usr,'Modem Response: ');

    End;

  Procedure Send(xx:anystr);
    Var cnt:Integer;
    Begin
      For cnt:=1 To Length(xx) Do Begin
        sendchar(xx[cnt]);
        Delay(90);
        Write(Usr,xx[cnt]);clreol;
      End;
    End;

  Function There_Is_Any_Mail:Boolean;
    Var out:anystr;
      ct:Integer;
      a:Boolean;
    Begin
      GoToXY(11,9);
      There_Is_Any_Mail:=False;
      For ct:=1 To 30 Do Outs[Ct]:=False;
      ct:=0;
      a:=False;
      While (Ct<=30) Do Begin
        cT:=ct+1;
        out:=netfiledir+strr(ct)+'.Out';
        If exist(out) Then Begin
          There_Is_Any_Mail:=True;
          a:=True;
          Outs[ct]:=True;
          Write(Usr,strr(ct)+' ');
        End;
      End;
    End;

  Procedure Check_for_incoming;
    Var tim,simplex,Cnt:Integer;
      joemama,wowie,sometimes,comstring,A,b:lstr;
      ff:File;
      comp:Boolean;

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

   Function  Receive_Mail:boolean;
     var tried:integer;

    begin
    tried:=0;
    clrscr;

    Repeat
    inc(tried);
    receive_mail:=false;

         Comstring:='/C del '+netfiledir+'*.zin';
         Writeln (usr,'DELETING OLD .ZINs - ',comstring);
         EXEC ('Command.com',comstring); {Del old .zins}

           Sometimes:=netfiledir+'1.zin';
           wowie:=sometimes;             {Copy }
           simplex:=1;
           if exist('TestEMA') then exec('Command.com','') else
           simplex:=protocolxfer(False,True,False,4,sometimes); {Zmodem batch}
           if simplex=0 then receive_mail:=true;
           if simplex=0 then begin

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

       end;
             If simplex=0 Then WriteLog(1,1,'EmuMail/2 Mail Linkup, ZIN Rcd')
                   Else WriteLog(1,1,'EmuMail/2 Mail Linkup, ZIN aborted');

      Until (Not carrier) or (simplex=0) or (tried>4) ;
      if simplex=0 then disco;
   end;

    Begin
    gotoxy (9,14);Write (usr,'** Checking for Returning mail!');clreol;
      Repeat
      {  For cnt:=1 to 31 Do Begin
          a:=netfiledir+strr(cnt)+'.zin';
          If Not(exist(a)) Then b:=a;
        End; }

        GoToXY(1,22);
        delay (1000);
        clearitall;
        send (#123+#123+#123);
        A:='';
        Delay(1000);

        tim:=200;

        repeat
        delay(100);dec(tim);
        until (Carrier=false) or (keypressed) or (numchars>0) or (tim=0);

        gotoxy (9,14);
        if tim=0 then begin
        write (usr,'No system Response.Disconnect');
         disco;
         end;

        send (^H+^H+^H+^H+^H+^H+^H+^H+^H+returning+^M);
        delay(1000);
        While numchars>0 Do a:=a+getchar;
        write(usr,a);
        GoToXY(9,14);delay (2000);

        If carrier Then Begin
          clearitall;
          GoToXY(1,24);
        comp:=receive_mail;
          disco;
          GoToXY(9,14);
          print_it;
          Assign(ff,b);
          clearitall;
          gotoxy (9,14);
          if comp then Writeln (Usr,'Got Returning mail!');
          if comp then writelog (1,1,'Emumail> got returning mail');

        End;
        disco ;
      Until (Not carrieR) Or (KeyPressed);
    End;


  Procedure Send_The_Mail;
    Var going:anystr;
      ct:Integer;
      Dest:Lstr;
      joe:Text;

    function ReadRec(Num:Integer):lstr;
      Var t:Text;
         Lo:lstr;
      Begin
      readrec:='';lo:='';
        Assign(t,netfiledir+strr(num)+'.out');
        if exist (netfiledir+strr(num)+'.out') then begin

        Reset(t);
        ReadLn(t,LO);
          textclose(t);

        curbaud:=getcurbaud(lo);

        gotoxy(1,1);write (usr,'Destination=',lo);
       if length(lo)>5 then while lo[1]<>' ' do delete(lo,1,1);
        delete(lo,1,1);
        GoToXY(14,13);
        Write(Usr,lo,'      ');
                         end;

        readrec:=lo;
      End;

    Function isbusy:Boolean;
      Var a,b:Integer;
        c,d:anystr;
        E:Char;
        done:Boolean;
      Begin
        GoToXY(1,22);
        done:=False;
        isbusy:=False;
        If numchars<5 Then exit;

        c:='';
        Repeat
          If numchars>0 Then e:=getchar;Write(Usr,Char(Ord(e) And 127));
          If numchars<5 Then Delay(90);
          c:=c+(Char(Ord(e) And 127));
          If WhereY=24 Then Begin
          GoToXY(1,22);ClrEol;End;
        Until (numchars=0) Or (Length(c)>200);
        If Pos('BUSY',c)>0 Then isbusy:=True;
        If Pos('Busy',c)>0 Then isbusy:=True;
        If Pos('CONNECT',c)>0 Then pcp:='C';
        GoToXY(14,13);
      End;

    Function Call(Var number:sstr):Boolean;
      Var jo:Integer;
        ss,rest,Whereto:anystr;
        loc,cmp:mstr;
        abt:Char;
      Begin
        call:=False;
        if curbaud<>baudrate then begin
        closeport;
        WRiteln (usr,'Adjusting Comm C:',usecom,' b:',curbaud);
        Setparam(usecom,curbaud,False);
        end;
        GoToXY(9,14);
        loc:='';
        Cmp:='';
        If valu(number[1])>0 Then Begin
          loc:=Copy(Returning,1,5);
          cmp:=Copy(Dest,1,5);
          rest:=Copy(Dest,6,255);
        End Else Begin
          rest:=pcpNode;
          ss:=pcpnode;
          Whereto:=Copy(number,6,255);
        End;
        If loc=cmp Then WriteLn(Usr,'Dialing Local: ',rest,'                    ')
        Else WriteLn(Usr,'Dialing: ',number,'                 ');
        online:=False;
        If ss=pcpnode Then Else ss:=number;
        If ss='' Then exit;

        If KeyPressed Then Begin
          abt:=readkey;
          GoToXY(9,14);
          Write(Usr,'Aborted..');ClrEol;
        End;

        doanswer;
        Delay(200);
        GoToXY(1,22);
        send(^M);
        Delay(50);
  if not carrier then       send(^M);
  if not carrier        then send('      '^M);
        Delay(500);
        If loc=cmp Then send('ATDT'+rest+#13) Else send('ATDT'+extender+ss+#13);
        jo:=25000;
        Finished:=False;

        Repeat
          jo:=jo-1;
          If KeyPressed Then Finished:=True;
          If isbusy Then finished:=True;
          GoToXY(70,13);
          If (jo Div 1000)<10 Then Write(Usr,'0');
          Write(Usr,jo Div 1000);
          If carrier Then Finished:=True;
        Until Finished Or (jo<1);

        If rest=pcpnode Then
            If carrier Then Begin
            rest:='C D/'+Copy(number,1,5)+'/12,'+PCPAccount;
            Delay(888);
            If isbusy Then disco;
            GoToXY(9,14);WriteLn(Usr,'Online to Telenet!');
             Send(^M^M^M^M^M);Delay(900);
             If isbusy Then disco;
             Delay(2000);GoToXY(1,22);
             Send(Rest+^M+^M);
             If isbusy Then disco;
             Delay(3000);
             If isbusy Then disco;
             Delay(5000);


        If isbusy Then Begin
          write (usr,'BUSY!!');
          dontanswer;Delay(1000);doanswer;
        finished:=True;End
        Else Begin
          Finished:=False;
          send('ATDT'+Copy(number,12,255)+^M);
        End;

        clearreceivebuffer;
        jo:=30000;


        Repeat
          jo:=jo-1;
          If KeyPressed Then Finished:=True;pcp:=#0;
          If isbusy Then Begin
          dontanswer;Delay(500);doanswer;finished:=True;End;
          If pcp='C' Then finished:=True;
          GoToXY(70,13);
          If (jo Div 1000)<10 Then Write(Usr,'0');
          Write(Usr,jo Div 1000);
          If Not carrier Then Finished:=True;
        Until Finished Or (jo<1);
         end;


        GoToXY(1,22);
        call:=carrier;
      End;

    Procedure Once_Got_Carrier;
    var tima,tim:integer;

      Begin
      send(^M);
        GoToXY(9,14);
        Write(Usr,'Carrier detected...Waiting for response!'); clreol;
        online:=True;

        tim:=200;

        repeat
        delay(100);dec(tim);
        until (Carrier=false) or (keypressed) or (numchars>0) or (tim=0);

        gotoxy (9,14);
        if tim=0 then begin
        write (usr,'No system Response. System Down? Disconnect');
         disco;
         Writelog (1,1,'netmail attempt--No bbs response');
         end;

        GoToXY(1,22);

        Delay(5000);clearitall;
        send(^X^X^H^H^H^H^H^H^H^H);
        Delay(2000);GoToXY(1,22);
        send(^H^H^H+'!Em20N^M'+#13);GoToXY(1,22);
        WriteLn(Usr,^j);
        Delay(1500);
        send(#111+#111);clearitall;
      End;

      procedure Make_the_Arc;
      var cnt:integer;
      tmp:lstr;
      begin
      clrscr;
      Writeln (usr,'-> Creating the Emulex Net Mail Archive.. Stand By <-');
      Writeln (usr,'   _______________________________________________'^M^M);

       assign(joe,netfiledir+'1.zin');
       if exist(netfiledir+'1.zin') then erase(joe);
       Write (usr,'[Del *.tmp]:May say File Not Found ->');
       exec ('Command.com','/c del '+netfiledir+'*.tmp');
       Writeln (usr,'[*.out -> *.TMP] Copying mail to send');
              For Cnt:=1 To 50 Do Begin
          If (Outs[Cnt]=true) Then Begin
            tmp:=readrec(cnt);
            If tmp=dest Then begin
            Exec ('command.com','/c copy '+netfiledir+strr(cnt)+'.out '+netfiledir+strr(cnt)+'.tmp');

            end;

          End;
        End;
        Writeln (usr,'[Zip *.tmp] Zipping All Mail together..');
                    exec ('pkzip.exe','-ea4 '+netfiledir+'1.zin'+' '+netfiledir++'*.tmp');

                    Writeln (usr,'Ready to send!');

      end;

   Procedure Check_All_Mail(Start:Integer);

    Var Position,Cnt:Integer;
        Out:Text;
        Tmp:lstr;
        AckPh:char;

      Procedure Send_The_File(xx:lstr);
        Var comp:Boolean;
          sent:Text;
          Krad:anystr;cnt:Integer;
        Begin
         writeln (usr,^M^M'[Dsz SZ] Begin to Send a packet');
          clearreceivebuffer;
          GoToXY(9,14);

          If carrier Then Begin
            clearitall;
            GoToXY(1,24);
            cnt:=protocolxfer(true,true,true,4,netfiledir+xx);
            print_it;


            GoToXY(9,14);print_it;
            If cnt=0 Then comp:=True Else comp:=False;
            Assign(Sent,netfiledir+xx);

            If comp Then begin {net mail is true }

       For Cnt:=1 To 40 Do Begin
          If Outs[Cnt] Then Begin

            Assign(Joe,netfiledir+strr(cnt)+'.out');
            if exist(netfiledir+strr(cnt)+'.out') then begin
            Reset(joe);
            ReadLn(Joe,Tmp);
            delete (tmp,1,5);
            textclose(Joe);
            If tmp=dest Then erase(joe);
            end;


          End;
        End;
              For Cnt:=1 To 40 Do Begin
          If Outs[Cnt] Then Begin

            Assign(Joe,netfiledir+strr(cnt)+'.tmp');
            Reset(joe);
            ReadLn(Joe,Tmp);
            delete (tmp,1,5);
            textclose(Joe);
            If tmp=dest Then begin
            erase(joe);
            end;
          End;
        End;

             end;

            GoToXY(9,14);
            If comp Then WriteLn(Usr,'EmuMail Transfer Successful..                  ')
            Else WriteLn(Usr,'EmuMail Transfer Failed..                            ');
            if comp then writelog (1,1,'An Emumail sent!') else
                         Writelog (1,1,'An Emumail Sent but Aborted!');
            Delay(1000);
            clearitall;
          End;
        End;


      Begin
          gotoxy(1,3);write (usr,'Dest=',dest);
        GoToXY(21,10);
        For Cnt:=1 To 40 Do Begin
          If Outs[Cnt] Then Begin
                 tmp:=readrec(cnt);
             gotoxy (1,2);write (usr,'compare>',tmp,'=',dest);
            If tmp=dest Then Write(Usr,cnt:1,' ');
          End;
        End;

        position:=24;

        For Cnt:=1 To 30 Do Begin
          If Outs[Cnt] Then Begin
            tmp:=readrec(cnt);
            If Tmp=Dest Then Begin
              GoToXY(position,11);
              Write(Usr,cnt:1,' ');

              if carrier then Make_The_arc;
              If carrier Then Send_The_File('1.ZIN');

              position:=position+2;
              If cnt>9 Then position:=position+1;
              Outs[Cnt]:=False;
            End;
          End;

        End;
      End;



    Begin

    if pcbMover[1]='1' then begin
      ct:=0;
      While (Ct<=60) Do Begin
        inc(cT);
        If Outs[Ct] Then Begin
          dest:=ReadRec(Ct);
          If carrier Then Begin
          dest:=pcbmover;
          write (usr,'Dest=pcbmover');

           { If carrier Then Once_Got_Carrier;  }

            GoToXY(18,10);ClrEol;

            GoToXY(24,11);ClrEol;
            If carrier Then Check_All_Mail(Ct);

          End;
          dontanswer;
          GoToXY(9,14);
          Write(Usr,'Disconnecting..');ClrEol;
          if carrier then disco;
          online:=False;
          GoToXY(1,22);
          Delay(500);
          send(^M'  '^M);
        End;
     End;

    end else begin

      ct:=0;
      While (Ct<=40) Do Begin
        inc(cT);
        If Outs[Ct] Then Begin
          dest:=ReadRec(Ct);
          If Call(Dest) and (dest<>'') Then Begin
            If carrier Then Once_Got_Carrier;
            GoToXY(18,10);ClrEol;
            GoToXY(24,11);ClrEol;
            if not carrier then Write (usr,'LOSS CARRIER?!!');
            If carrier Then Check_All_Mail(Ct);
          {  if carrier then check_For_Incoming;}
          End else write (usr,'Call failed...');

          dontanswer;
          GoToXY(9,14);
          Write(Usr,'Disconnecting..');ClrEol;
          online:=False;
          GoToXY(1,22);
          Delay(500);
          send(^M'  '^M);
        End;
      End;

    End;
    end;

  Begin
  clearitall; while keyhit do pcp:=readkey;
  if PCBMover[1]='1' then  begin

      modeminlock:=False;
    modemoutlock:=False;
    local:=False;
    Window(1,1,80,25);clrscr;

    Print_IT;gotoxy (1,1);write (usr,'Netback 1.00');
    z:=There_Is_Any_Mail;

    If Z Then Begin
      GoToXY(1,22);
      Send_The_Mail;
      If carrier Then dontanswer;
      GoToXY(9,14);
      Write(Usr,'NetMail Send Back complete.. Returning to BBS..');ClrEol;
      ensureclosed;
      Halt(32);
    End Else Begin
      GoToXY(9,14);
      WriteLn(Usr,'No NetMail.. Ending Session!..');
      if carrier then dontanswer;
      ensureclosed;
      Halt(32);
    End;


  end else begin
         closeport;
         writeln (usr,'default comm C:',usecom,' Db:',defbaudrate);
  setparam (usecom,defbaudrate,false);
    modeminlock:=False;
    modemoutlock:=False;
    local:=False;
    Window(1,1,80,25);
    PRint_IT;
    z:=There_Is_Any_Mail;
    If Z Then Begin
      GoToXY(1,22);
      send('     '^M);
      Delay(500);
      send(^M'AT S0=0'^M);
      GoToXY(9,14);
      Write(Usr,'Disabling Auto-Answer..'+pcbmover);ClrEol;
      pcbmover:='';
      Delay(1000);
      Send_The_Mail;
      If carrier Then dontanswer;
      GoToXY(9,14);
      Write(Usr,'NetMail sessions complete.. Returning to BBS..');ClrEol;
      GoToXY(1,22);
      send(^M^M^M'   ');
      Delay(200);
      send(^M'AT S0=1'^M);
      GoToXY(9,14);
      WriteLn(Usr,'Re-Enabling Auto-Answer..');ClrEol;
      Delay(1000);
      Halt(32);
    End Else Begin
      GoToXY(9,14);
      WriteLn(Usr,'No NetMail.. Returning to BBS..');
      Halt(32);
    End;
  End;
  end;

Begin
End.

