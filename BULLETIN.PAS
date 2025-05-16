  {$R-,S-,I-,D-,F+,V-,B-,N-,L+,O+ }

  unit bulletin;

  Interface

 uses crt,
  gentypes,configrt,statret,gensubs,subs1,subs2,
  userret,textret,mainr1,mainr2,overret1,flags;

  Procedure bulletinmenu;

  Implementation

Procedure bulletinmenu;
  Var q,curbul,lastreadnum:Integer;
    b:bulrec;
    tff:Text;
    utgoing:lstr;
  Procedure makeboard;Forward;
  procedure sreadcurbul;forward;
  Procedure killbul;Forward;
  Procedure setactive(nn:sstr;NetMail:Boolean);Forward;
  Function sponsoron:Boolean;

    Begin
      sponsoron:=match(curboard.sponsor,unam)
    End;

  Procedure clearorder(Var bo:boardorder);
    Var cnt:Integer;
    Begin
      For cnt:=0 To 255 Do bo[cnt]:=cnt
    End;

  Procedure Change_userm(num,amount:Integer);
    Var u:userrec;
      Krad:Integer;
    Begin
      If num<0 Then exit;
      Seek(ufile,num);
      Read(ufile,u);
      krad:=u.Messages_Waiting;
      kraD:=krad+amount;
      u.messages_Waiting:=krad;
      Seek(ufile,num);
      Write(ufile,u);

    End;


  Procedure carryout(Var bo:boardorder);
    Var u:userrec;
      cnt,un:Integer;

    Procedure doone;
      Var cnt,q:Integer;
        ns,a1,a2:Set Of Byte;
      Begin
        FillChar(ns,32,0);
        FillChar(a1,32,0);
        FillChar(a2,32,0);
        For cnt:=0 To 255 Do Begin
          q:=bo[cnt];
          If q In u.newscanconfig Then ns:=ns+[cnt];
          If q In u.access1 Then a1:=a1+[cnt];
          If q In u.access2 Then a2:=a2+[cnt]
        End;
        u.newscanconfig:=ns;
        u.access1:=a1;
        u.access2:=a2;
        Seek(ufile,un);
        Write(ufile,u)
      End;

    Begin
      WriteLn(^B^S'Adjusting user access flags...');
      Seek(ufile,1);
      For un:=1 To numusers Do Begin
        If (un Mod 10)=0 Then Write(' ',un);
        Read(ufile,u);
        If Length(u.handle)>0 Then doone
      End
    End;

  Procedure switchboards(bnum1,bnum2:Integer;Var bo:boardorder);
    Var bd1,bd2:boardrec;
      n1:Integer;
    Begin
      seekbdfile(bnum1);
      Read(bdfile,bd1);
      seekbdfile(bnum2);
      Read(bdfile,bd2);
      seekbdfile(bnum1);
      writebdfile(bd2);
      seekbdfile(bnum2);
      writebdfile(bd1);
      n1:=bo[bnum1];
      bo[bnum1]:=bo[bnum2];
      bo[bnum2]:=n1
    End;

  Procedure setfirstboard;Forward;

  Procedure seekbfile(n:Integer);
    Begin
      Seek(bfile,n-1);che
    End;

  Function numbuls:Integer;
    Begin
      numbuls:=FileSize(bfile)
    End;

  Procedure getlastreadnum;
    Var oldb:Boolean;
      b:bulrec;
      lr:word;
    Begin
      lastreadnum:=numbuls;
      oldb:=False;
      lr:=urec.lastread[curboardnum];
      If lr=0
      Then lastreadnum:=0
      Else
        While (lastreadnum>0) And (Not oldb) Do Begin
          seekbfile(lastreadnum);
          Read(bfile,b);
          oldb:=b.id=lr;
          If Not oldb Then lastreadnum:=lastreadnum-1
        End
    End;

  Procedure assignbfile;
    Begin
      Assign(bfile,boarddir+curboardname+'.BUL')
    End;

  Procedure formatbfile;
    Begin
      assignbfile;
      Rewrite(bfile);
      curboardnum:=searchboard(curboardname);
      If curboardnum=-1 Then Begin
        curboardnum:=FileSize(bdfile);
        FillChar(curboard,SizeOf(curboard),0);
        writecurboard
              End
    End;

  Procedure openbfile;
    Var b:bulrec;
      i:Integer;
    Begin
      curboardnum:=searchboard(curboardname);
      If curboardnum=-1 Then Begin
        makeboard;
        exit
      End;
      Close(bfile);
      assignbfile;
      Reset(bfile);
      i:=IOResult;
      If IOResult<>0 Then formatbfile;
      seekbdfile(curboardnum);
      Read(bdfile,curboard);
      getlastreadnum;
    End;

  Function boardexist(n:sstr):Boolean;
    Begin
      boardexist:=Not(searchboard(n)=-1)
    End;

  Procedure addbul(Var b:bulrec);
    Var b2:bulrec;
    procedure check;
    var temp:bulrec;
    cnt:longint;
    cnt1:integer;
    begin
    for cnt:=1 to numbuls do begin
    seekbfile(cnt-1);
    read (Bfile,temp);
    if temp.line=b.line then Writeln ('overrite');
    end;

    end;
    Begin
      If numbuls=0 Then b.id:=1 Else Begin
        seekbfile(numbuls);
        Read(bfile,b2);
        If b2.id=65535
        Then b.id:=1
        Else b.id:=b2.id+1
      End;
      seekbfile(numbuls+1);
      Write(bfile,b);
    End;

  Function checkcurbul:Boolean;
    Begin
      If (curbul<1) Or (curbul>numbuls) Then Begin
        checkcurbul:=False;
        curbul:=0
      End Else checkcurbul:=True
    End;

  Procedure getbrec;
    Begin
      If checkcurbul Then Begin
        seekbfile(curbul);
        Read(bfile,b);che
      End
    End;

  Procedure delbul(bn:Integer;deltext:Boolean);
    Var c,un:Integer;
      b:bulrec;
      u:userrec;
    Begin
      If (bn<1) Or (bn>numbuls) Then exit;
      seekbfile(bn);
      Read(bfile,b);
      If deltext Then deletetext(b.line);
      For c:=bn To numbuls-1 Do Begin
        seekbfile(c+1);
        Read(bfile,b);
        seekbfile(c);
        Write(bfile,b)
      End;
      seekbfile(numbuls);
      Truncate(bfile);
      getlastreadnum;
    End;

  Procedure delboard(bdn:Integer);
    Var bd1:boardrec;
      cnt,nbds:Integer;
      bo:boardorder;
    Begin
      clearorder(bo);
      nbds:=FileSize(bdfile)-1;
      If nbds=0 Then Begin
        Close(bdfile);
        Rewrite(bdfile);
        exit
      End;
      For cnt:=bdn To nbds-1 Do Begin
        seekbdfile(cnt+1);
        Read(bdfile,bd1);
        seekbdfile(cnt);
        writebdfile(bd1);
        bo[cnt]:=cnt+1
      End;
      Seek(bdfile,nbds);
      Truncate(bdfile);
      Seek(bifile,nbds);
      Truncate(bifile);
      carryout(bo)
    End;

  Function GetRoute2:Lstr;
    Var FF:File Of NetRec;
      Net:Netrec;
      Cnt,D:Integer;
      A,B:anystr;

    Begin
      ansicls;
      getroute2:='';
      If Not exist(curboard.EmuMail_Type) Then exit;
      Assign(FF,curboard.emumail_type);
      Reset(ff);
      WriteLn(^B^U'                [Emumail NodeList]');
      WriteLn(^B^U'#.   BBS Name                    Location');
      WriteLn(^B^U'--   --------------------------- --------');
      WriteLn;
      For cnt:=1 To FileSize(ff) Do Begin
        Seek(ff,cnt-1);Read(ff,net);
        Tab(strr(cnt),6);
        Tab(net.Boardname,27);
        tab(net.Location,13);
        writeln;

      End;
      Writestr(^M^P'Select Destination node # :');
      If Input='' Then exit;
      d:=valu(Input);If d>FileSize(ff) Then exit;
      Seek(ff,d-1);Read(ff,net);
      If net.citycode='' Then getroute2:=strr(net.callbaud)+' '+net.number
      Else getroute2:=net.citycode+' '+net.number;
                                        writeln;
      Close(fF);

    End;

  Procedure PCBREADHeader;
      {
      Date: 08-15-88 (22:45)              Number: 508
      To: BILL FISHER                     Refer#: 507
      From: SYSOP                           Read: NO
      Subj: COMMENT                       Status: PUBLIC MESSAGE

      More: (Y), (N), (NS), (T), (#), (+), (-)?
      }
    Var q:anystr;
      t:sstr;
      cnt:Integer;
      Replytitle:mstr;
    Begin
      Begin

        If checkcurbul Then Begin
          getbrec;
          If (vt52 in urec.config) or (ansigraphics In urec.config) Then ansicls Else WriteLn(^M^M^M);
          If (b.reply<>0) Then replytitle:='Reply to '+b.title
          Else replytitle:=b.title;
          Write(^R'Date: '^S,datestr(b.when),^R'('^S,timestr(b.when),^R')');
          Asciigotoxy(40,WhereY);
          WriteLn('Number: '^S,curbul);
          WriteLn('  To: '^s,b.sentto);

          q:='From: '^S;
          If b.anon
          Then
            Begin
              q:=q+anonymousstr+^R+']';
              If issysop Then q:=q+' ['+b.leftby+']'
            End
          Else
            Begin
              q:=q+b.leftby+^R;
            End;
          Write(q);asciigotoxy(40,WhereY);
          If b.received=255 Then WriteLn('Read: Yes') Else WriteLn('Read: No');
          Write(^B'Subj: '^S,replytitle,^R);asciigotoxy(40,WhereY);
          WriteLn('Status: PUBLIC MESSAGE');

          printtext(b.line)
        End;
        If b.Tonum=unum Then Begin
          b.received:=255;
          seekbfile(curbul);
          Write(bfile,b);che;
        End;


        If curbul>lastreadnum Then Begin
          lastreadnum:=curbul;
          urec.lastread[curboardnum]:=b.id
        End
      End;
    End;
  Procedure printrawtext(sector:Integer);
    Var q:message;
      x,b:Boolean;
      n:Integer;
      Cnt:integer;
      Buff:anystr;
      done:boolean;
      Kar:char;
    Begin
    done:=false;
      reloadtext(sector,q);
      WriteLn(^B);
      n:=1;
      Repeat

        buff:=q.text[n];

         for cnt:=1 to length(buff) do begin
         kar:=buff[cnt];
         write(kar);
       {  if (kar=^Z) or (kar=#0) then done:=true;}

         end;
        inc(n);
      Until done or break Or (n>q.numlines) Or hungupon;
      x:=xpressed;b:=break;
      WriteLn(^B^M);
      xpressed:=x;break:=b
    End;

  Procedure readcurbul;
    Var q:anystr;
      t:sstr;
      cnt:Integer;
      Replytitle:mstr;
      WasAnsi:boolean;
    Begin
      If urec.emulation=2 Then pcbreadheader Else Begin

        If checkcurbul Then Begin
          getbrec;
          If (b.reply<>0) Then replytitle:='Reply to '+b.title
          Else replytitle:=b.title;
          If (vt52 in urec.config) or (ansigraphics In urec.config) Then ansicls;
          WriteLn(^B'Area Name: '^S,curboard.boardname,^R^M);

          WriteLn(^B'Message #  '^S,curbul,^R' of '^S,numbuls,^R);
          WriteLn(^B'Subject:   '^S,replytitle,^R);
          q:='From:      '^S;
          If b.anon
          Then
            Begin
              q:=q+'['+^S+anonymousstr+^R+']';
              If issysop Then q:=q+' ['+b.leftby+']'
            End
          Else
            Begin
              If b.plevel=-1
              Then t:='unknown'
              Else t:=strr(b.plevel);
              q:=q+b.leftby+^R+'  Level '+^S+t+^R;
            End;
          WriteLn(q);
          Write('To:        '^s,b.sentto,^R);
          If b.received=255 Then WriteLn(^S' [Received]') Else WriteLn;
          If issysop Or (Not b.anon)
          Then WriteLn(^R'Date:      '^S,datestr(b.when),^R' at '^S,timestr(b.when),^R);
          If break Then exit;

   if b.rawmode<>1 then printtext(b.line) else
                        begin
                        wasansi:=ansigraphics in urec.config;
                        urec.config:=urec.config-[ansigraphics];
                        printtext(b.line);
                        if wasansi then urec.config:=urec.config+[ansigraphics];
                        end;

                        {printrawtext(b.line);}
        End;
        If b.Tonum=unum Then Begin
          b.received:=255;
          seekbfile(curbul);
          Write(bfile,b);che;
        End;


        If curbul>lastreadnum Then Begin
          lastreadnum:=curbul;
          urec.lastread[curboardnum]:=b.id
        End
      End;
    End;
  function Longenuff(MM:message):boolean;
  var cnt,total,cnt1:longint;
      A,B:anystr;
      begin
      total:=0;
      for cnt:=1 to mm.numlines do begin
      a:=mm.text[cnt];
      for cnt1:=1 to length(a) do begin
      if  (Ord(a[cnt1])>ord('a')) and (ord(a[cnt1])<ord('z')) then inc(total);
      end;
      end;

      longenuff:=total>100;
      end;
  Function queryaccess:accesstype;
    Begin
      queryaccess:=getuseraccflag(urec,curboardnum)
    End;

  Procedure autodelete;
    Var ccc,cnt:Integer;

    Begin
    ccc:=curbul;
      WriteLn('['^V'Standy by'^R'] ['^V'Erasing old messages'^R']');
      For cnt:=6 Downto 2 Do delbul(cnt,True);
      curbul:=ccc-5;
    End;

  Procedure postbul;
    Var l:Integer;
      m:message;
      b:bulrec;

procedure ECHO_IT;
    Var FF:File Of NetRec;
      Net:Netrec;
      Cnt,D:Integer;
      A,B:anystr;

    Begin
      If Not exist(curboard.EmuMail_Type) Then exit;
      Assign(FF,curboard.emumail_type);
      Reset(ff);
      WriteLn;
      For cnt:=1 To FileSize(ff) Do Begin
        Seek(ff,cnt-1);Read(ff,net);
        UTgoing:=net.number;
        curbul:=numbuls;
       sreadcurbul;
      End;
      Close(fF);

    End;

    Begin
      If ulvl<postlevel Then Begin
        reqlevel(postlevel);
        exit
      End;
      l:=editor(m,True,True);
      If l>=0 Then
        Begin
          if longenuff (m) then urec.nbu:=urec.nbu+1;
          writeurec;

          b.reply:=000;
          b.sentto:=m.sentto;
          b.tonum:=0;
          b.tonum:=lookupuser(b.sentto);
          If b.tonum>0 Then change_userm(b.tonum,1);
          b.fromnum:=unum;
          b.ranon:=0;
          b.received:=0;
          b.anon:=m.anon;
          b.title:=m.title;
          if b.title[1]=#235 then B.rawmode:=1 else b.rawmode:=0;
          b.when:=now;
          b.leftby:=unam;
          b.line:=l;
          b.plevel:=ulvl;
          addbul(b);
          newposts:=newposts+1;
          inc(totalposts);If totalposts>32000 Then totalposts:=0;
          if curboard.emumail_type<>'NODELIST.BBS' then begin


         echo_it;
        end;

          end;

          With curboard Do
            If autodel<=numbuls Then autodelete
    End;


  Procedure spostbul(xyz:lstr;writechg:Boolean);
    Var l:Integer;
      m:message;
      b:bulrec;
      sss:Text;
      fff:anystr;
      SAveB,BoardTo,yyy:lstr;
      nn,jo1:mstr;
      jo2:String[28];
      jo3:sstr;
      Krad:anystr;
    Begin
      saveb:=curboardname;
      Krad:=netfiledir+xyz;
      Assign(sss,krad);
      Reset(sss);
      ReadLn(sss,jo1);
      ReadLn(sss,jo1);{to eliminate header}
      ReadLn(sss,jo1);
      If Not writechg Then Write(' ',jo1);
      if m.title='' then writechg:=false;
      m.title:=jo1;
      b.title:=jo1;
      ReadLn(sss,jo2);
      Boardto:=jo2;

      If boardexist(boardto) Then Begin
        setactive(boardto,True);
      End;

      ReadLn(sss,jo2);
      b.leftby:=jo2;
      If Not writechg Then Write(' ',jo2);
      ReadLn(sss,jo2);
      b.sentto:=jo2;
      If Not writechg Then WriteLn(' ',jo2);
      m.numlines:=0;
      m.anon:=False;

      While Not EoF(sss) Do Begin
        m.numlines:=m.numlines+1;
        ReadLn(sss,m.text[m.numlines]);
      End;

      if m.numlines<1 then writechg:=false;
      b.when:=now;
      b.anon:=False;
      Begin
        If writechg Then b.line:=maketext(m);
        b.plevel:=-1;
        if m.numlines<2 then begin textclose(sss); erase(sss); end else
        textclose(sss);

        If writechg Then Erase(sss);
        If writechg Then addbul(b);
      End;
      setactive(saveb,True);
    End;



  Procedure sreadcurbul;
    Var fff:anystr;
      jo3,t:sstr;
      cnt,n:Integer;
      qa:message;
      x:Boolean;
      name:Text;
      jo1:mstr;
      jo2:String[28];


    Function nextone:anystr;
      Var zed,one:anystr;
        ct:Integer;
        finished:Boolean;
      Begin
        finished:=False;
        NEXTONE:='';
        ct:=0;
        While Not finished And (ct<21) Do Begin
          cT:=ct+1;
          zed:=strr(ct)+'.out';
          If Not exist(netfiledir+zed) Then Begin
            nextone:=zed;
            finished:=True;
          End;

        End;
      End;


    Begin
      fff:=nextone;
      If Length(fff)>0 Then Begin
        Assign(name,netfiledir+fff);
        Rewrite(name);

        If checkcurbul Then Begin
          WriteLn(name,utgoing);
          WriteLn(name,Returning);
          getbrec;
          jo1:=(b.title);
          WriteLn(name,jo1);
          jo1:=(curboardname);
          WriteLn(name,jo1);

          jo2:=(b.leftby);
          WriteLn(name,jo2);
          jo3:=(b.sentto);
          WriteLn(name,jo3);
          WriteLn(name,'[ Area :',curboard.boardname,' ]');
          WriteLn(name,'');
          reloadtext(B.LINE,qa);
          n:=1;
          While (n<(qa.numlines)) Do Begin
            WriteLn(name,QA.TEXT[N]);
            n:=n+1;
          End;
          WriteLn(name,'');
          WriteLn(name,^S'          Forwarded from:   '+Longname);
         { WriteLn(name,'          Exchange Address: '+returning);}
          WriteLn(name,^S'          EmuMail/2  Version: 1.60');
          For n:=1 To 79 Do Write(name,^Z);
          textclose(name);
        End;
      End;
    End;


  Procedure dothem;
    Var zed,one,nextone:anystr;
      ct:Integer;
      jo:Text;
      Krad:anystr;
      finished:Boolean;

    Begin
      Write(^B'['^V'Adding Some EmuMail Exchange Messages'^R']');
      finished:=False;
      nextone:='';
      ct:=0;
      While ct<50 do Begin
      inc(Ct);

        zed:=strr(ct)+'.in';
        Krad:=netfiledir+zed;
        If exist(krad) Then Begin
          nextone:=zed;
          Write(' ',ct);
          spostbul(nextone,True);
          Assign(jo,krad);reset(jo);textclose(jo);
          Erase(jo);
        End;

      End;WriteLn;
    End;


  Procedure getroute;
    Var Krad:anystr;
    Begin
      If ulvl<leveltouseEmumail Then WriteLn(^S'Your access is too low to use EmuMail!');
      If ulvl<leveltouseEmumail Then exit;
      utgoing:='';
      krad:=getroute2;
      If krad='' Then exit;
      utgoing:=krad;
      sreadcurbul;
    End;

  Procedure Replybul(Replyto,Sametitle:mstr);
    Var l:Integer;
      m:message;
      b:bulrec;
      procedure ECHO_IT;
    Var FF:File Of NetRec;
      Net:Netrec;
      Cnt,D:Integer;
      A,B:anystr;

    Begin
      If Not exist(curboard.EmuMail_Type) Then exit;
      Assign(FF,curboard.emumail_type);
      Reset(ff);
      WriteLn;
      For cnt:=1 To FileSize(ff) Do Begin
        Seek(ff,cnt-1);Read(ff,net);
        UTgoing:=net.number;
       sreadcurbul;
      End;
      Close(fF);

    End;

    Begin
      If ulvl<postlevel Then Begin
        reqlevel(postlevel);
        exit
      End;
      l:=editor(m,False,False);
      If l>=0 Then
        Begin
        if longenuff(m) then urec.nbu:=urec.nbu+1;
          writeurec;
          b.reply:=unum;
          b.sentto:=replyto;b.tonum:=0;
          b.tonum:=lookupuser(b.sentto);
          If b.tonum>0 Then change_userm(b.tonum,1);
          b.fromnum:=unum;
          b.received:=0;
          b.ranon:=0;
          b.anon:=m.anon;
          b.title:=sametitle;
          b.when:=now;
          b.leftby:=unam;
          b.line:=l;
          b.plevel:=ulvl;
          addbul(b);
          newposts:=newposts+1;inc(totalposts);
          if curboard.emumail_type <>'NODELIST.BBS' then begin
               Echo_It;
          end;
          With curboard Do
            If autodel<=numbuls Then autodelete
        End;
    End;


Function findThread(Tit:mstr; Startat:integer; Direction:integer):integer;
    var Tempo,tempo1,cnt:integer;
    kewl:lstr;
    done:boolean;

    begin
    tempo:=curbul;
    done:=false;
    findthread:=0;

    if direction=1 then begin
                    for cnt:=(startat+1) to numbuls do
                        begin
                        curbul:=cnt;
                         if (curbul<1) or (curbul>numbuls) then done:=true;
                         if not done then begin
                                 seekbfile(curbul);
                                 Read(bfile,b);che;

                          kewl:=b.title;

                          if match(tit,kewl) then done:=true;
                          if match(tit,kewl) then findthread:=curbul;
                          end;
                          end;
                        end else
                        {reverse thread}
                        begin
                        done:=false;
                             for cnt:=(startat-1) downto 1  do

                        begin
                              curbul:=cnt;
                         if (curbul<1) or (curbul>numbuls) then done:=true;
                         if not done then begin
                                 seekbfile(cnt);
                                 Read(bfile,b);che;


                          if match(tit,b.title) then done:=true;
                          if match(tit,b.title) then findthread:=curbul;
                                           end;

                        end;


                         end;


    end;
  Procedure getbnum(txt:mstr);
    Var q:Boolean;
    Begin
      If Length(Input)>1
      Then curbul:=valu(Copy(Input,2,255))
      Else Begin
        writestr(^M'Bulletin to '+txt+':');
        curbul:=valu(Input)
      End;
      q:=checkcurbul
    End;



  Procedure readbul;
    Var Was,Is,Max:Integer;
      data:anystr;
    Begin
      was:=curbul;
      Max:=numbuls;
      If urec.emulation=2 Then Input:=PCBmover Else
        Writestr('['+^V+'Read Messages'+^W+'] Begin at ['+^S+'1-'+strr(numbuls)+^P+'] ['+^V+strr(lastreadnum)+^W+'] :');
      ansicls;
      If Input='' Then is:=lastreadnum Else is:=valu(Input);

      If is<1 Then is:=1;
      While (is<(max+1)) And (Is>0) Do Begin
        Max:=numbuls;

        curbul:=is;
        readcurbul;

        While WhereY<23 Do WriteLn(^B);

          Writestr('Read Command [!]EmuMail [A]gain [E]nter [D]elete [R]eply [Q]uit :');
        If Input='' Then Input:='&';
        data:=UpCase(Input[1]);
        If data='A' Then dec(is);
        If data='!' Then getroute;
        If data='E' Then postbul;
        If data='D' Then killbul;
        If data='R' Then replybul(b.leftby,b.title);
        If data='Q' Then exit;
        If data='N' Then Exit;
        inc(is);
      End;

    End;

  Procedure readnextbul;
    Var t:Integer;
    Begin
      t:=curbul;
      curbul:=curbul+1;
      readcurbul;
      If curbul=0 Then curbul:=t
    End;



  Procedure readnum(n:Integer);
    Begin
      curbul:=n;
      readcurbul
    End;


  Function haveaccess(n:Integer):Boolean;
    Var a:accesstype;

    Begin
      curboardnum:=n;
      seekbdfile(n);
      Read(bdfile,curboard);
      a:=queryaccess;
      haveaccess:=False;
      If curboard.area_type[1] in [ 'B' , 'L' ] Then
        If (Curboard.level<=ulvl) Then haveaccess:=True;
      If curboard.area_type[1] in [ 'B' , 'G' ] Then
        If (isinlist(curboard.file_list)) Then haveaccess:=True;
    End;

  Procedure makeboard;
    Begin
      formatbfile;
      With curboard Do Begin
        shortname:=curboardname;
        BufLen:=30;
        writestr(^M'Board name: &');
        boardname:=Input;
        BufLen:=30;
        writestr('Co-Sysop [default '+^S+unam+^P+']:');
        If Input='' Then Input:=unam;
        sponsor:=Input;
        writestr('Emu-Mail Echo Conference File Name [NODELIST.BBS]:');
        If Input='' Then Input:='NODELIST.BBS';
        EMuMail_Type:=Input;

        writestr('Access Type: [G]roup [L]evel [B]oth [default L]:');
        If Input='' Then Input:='L';
        Area_Type:=UpCase(Input[1]);
        if not ( area_type[1] in [ 'B' , 'G' , 'L' ] ) then
          area_type := 'L' ;
        if area_type[1] in [ 'G' , 'B' ] then
          begin
            writestr('Group File list [default NONE]:');
            If Input='' Then Input:='None';
            File_List:=Input;
          end
        else
          File_List := 'None';
        if area_type[1] in [ 'L' , 'B' ] then
          begin
            writestr('Minimum access entry:');
            level:=valu(Input);
          end
        else
          level := maxint ;
        writestr('Maximum # of messages:');
        autodel:=valu(Input);
        If autodel<10 Then Begin
          WriteLn('Must be at least 10!');
          autodel:=10
        End;
        setallflags(curboardnum,bylevel);
        writecurboard;
        WriteLn('Message Area created.');
        writelog(4,4,boardname+' ['+shortname+']')
      End
    End;

  Procedure setactive(nn:sstr;Netmail:Boolean);

    Procedure doswitch;
      Var a,b:Integer;
      Begin

        openbfile;
        curbul:=lastreadnum;
        urec.wherebase:=nn;writeurec;
        If (netmail=False) Then Begin
            If (vt52 in urec.config) or (ansigraphics In urec.config) Then ansicls;
          WriteLn('ีอออ['^V'Message Base'^R']อออออออออออออออออออออออออออออธ');

          Write('ณ     '^W'Current Area : '^S,curboard.boardname);
          a:=48-WhereX;
          tab(' ',a);
{          For B:=1 To a Do Write(' ');}

          WriteLn(^R'ณ');
          Write('ณ     '^W'Co-sysop     : '^S,curboard.sponsor);
          a:=48-WhereX;

          {For B:=1 To a Do Write(' ');}
          tab(' ',a);
          WriteLn(^R'ณ');

          Write('ณ     '^W'# of msgs    : '^S,numbuls);
          a:=48-WhereX;

          {For B:=1 To a Do Write(' ');}
          tab (' ',a);
          WriteLn(^R'ณ');

          Write('ณ     '^W'Last Msg Read: '^S,lastreadnum);
          a:=48-WhereX;
         { For B:=1 To a Do Write(' ');}
         tab (' ',a);
          WriteLn(^R'ณ');

          WriteLn('ิออออออออออออออออออออออออออออออออออออออออออออออพ'^B^M);
        End;
      End;

    Procedure tryswitch;
      Var n,s:Integer;

      Procedure denyaccess;
        Var b:bulrec;
        Begin
          reqlevel(curboard.level);
          setfirstboard
        End;

      Begin
        curboardname:=nn;
        curboardnum:=searchboard(nn);
        If netmail Then doswitch Else
          If haveaccess(curboardnum)
          Then doswitch
          Else denyaccess
      End;

    Var b:bulrec;
    Begin
      Curbul:=0;
      Close(bfile);
      Close(ffile);
      Curboardname:=nn;
      If boardexist(nn) Then tryswitch Else Begin
        WriteLn('Area does not exist: '^S,curboardname,^R'!');
        If issysop
         Then
          Begin
           writestr(^M'Create a new area [y/n]? *');
            If yes
             Then
              Begin
                Makeboard;
                Setactive(curboardname,False)
              End
            Else setfirstboard
          End
        Else setfirstboard
      End
    End;

  Function validbname(n:sstr):Boolean;
    Var cnt:Integer;
    Begin
      validbname:=False;
      If (Length(n)=0) Or (Length(n)>8) Then exit;
      For cnt:=1 To Length(n) Do
        If Not(UpCase(n[cnt]) In ['0'..'9','A'..'Z']) Then exit;
      validbname:=True
    End;

  Procedure listboards;
    Var cnt,oldcurboard:Integer;
      printed:Boolean;
    Begin
      oldcurboard:=curboardnum;
      Writehdr('Message Areas');
      WriteLn(^U' Number    Name                            Level ');
      WriteLn(^U' ______    ____                            _____ '^M);
      If break Then exit;
      For cnt:=0 To FileSize(bdfile)-1 Do
        If haveaccess(cnt) Then
          With curboard Do Begin

            Write(^S' ');tab(shortname,7);Write(^W'  ');

            Write(' ');tab(boardname,29);Write(^X'  ');


            WriteLn(' ',level:6);

            If break Then exit
          End;
      curboardnum:=oldcurboard;
      seekbdfile(curboardnum);
      Read(bdfile,curboard)
    End;

  Procedure activeboard;
    Begin
      If Length(Input)>1
      Then Input:=Copy(Input,2,255)
      Else
        Repeat
          listboards;
          writestr(^M^M^P'Area name [?]:');
          If Input='?' Then listboards
        Until (Input<>'?') Or hungupon;
      If hungupon Or (Length(Input)=0) Then exit;
      If Input[1]='*' Then Input:=Copy(Input,2,255);
      If validbname(Input)
      Then setactive(Input,False)
      Else
        Begin
          WriteLn(^M'Invalid board name!');
          setfirstboard
        End
    End;

  Procedure setfirstboard;{ FORWARD }
    Var fbn:sstr;
    Begin
      If FileSize(bdfile)=0 Then exit;
      If Not haveaccess(0)
      Then error('User can''t access first board','','');
      Seek(bifile,0);
      Read(bifile,fbn);
      setactive(fbn,False)
    End;


  Procedure listbuls;
    Var cnt,bn:Integer;
      q:Boolean;
    Begin
      If Length(Input)>1 Then Begin
        curbul:=valu(Copy(Input,2,255));
        q:=checkcurbul
      End;
      If curbul=0
      Then
        Begin
          writestr(^M^P'List messages starting at #*');
          curbul:=valu(Input)
        End
      Else
        If Length(Input)>1
        Then curbul:=valu(Input)
        Else curbul:=curbul+10;
      If Not checkcurbul Then curbul:=1;
      WriteLn('Subjects:'^M);
      For cnt:=0 To 9 Do
        Begin
          bn:=curbul+cnt;
          If (bn>0) And (bn<=numbuls) Then
            Begin
              seekbfile(bn);
              Read(bfile,b);
              Write(^V,bn,'. '^S,b.title,^X' From ');
              If b.anon
              Then WriteLn(anonymousstr)
              Else WriteLn(b.leftby);
              If break Then exit
            End
        End
    End;

  Procedure killbul;
    Var un:Integer;
      u:userrec;
    Begin
      writehdr('Delete Message');
      getbnum('delete');
      If Not checkcurbul Then exit;
      getbrec;
      If (Not match(b.leftby,unam)) And (Not issysop) And (Not sponsoron)
      Then Begin
        WriteLn(^S'You did not enter it.');
        exit
      End;
      WriteLn('Subject:   '^V,b.title,
      ^M'From: '^V,b.leftby,^M^M);
      writestr('Delete it? *');
      If Not yes Then exit;
      un:=lookupuser(b.leftby);
      If un<>0 Then Begin
        writeurec;
        Seek(ufile,un);
        Read(ufile,u);
        u.nbu:=u.nbu-1;
        Seek(ufile,un);
        Write(ufile,u);
        readurec
      End;
      delbul(curbul,True);
      WriteLn(^S'Bulletin deleted.');
      writelog(4,5,b.title)
    End;

  Procedure editbul;
    Var me:message;
    Begin
      getbnum('edit');
      If Not checkcurbul Then exit;
      getbrec;
      If (Not match(b.leftby,unam)) And (Not issysop) And (Not sponsoron)
      Then Begin
        WriteLn(^S'You didn''t enter that message!');
        exit
      End;
      reloadtext(b.line,me);
      me.title:=b.title;
      me.anon:=b.anon;
      If reedit(me,True) Then Begin
        writelog(4,6,b.title);
        deletetext(b.line);
        b.line:=maketext(me);
        If b.line<0 Then Begin
          writestr(^M^S'Deleting Message...');
          delbul(curbul,False)
        End Else Begin
          seekbfile(curbul);
          Write(bfile,b)
        End
      End
    End;


  Procedure sendbreply;
    Begin
      If checkcurbul Then Begin
        getbrec;
        sendmailto(b.leftby,b.anon)
      End Else Begin
        getbnum('reply to');
        If checkcurbul Then sendbreply
      End
    End;

  Procedure EmuMailSponsor;
    Var maxin,maxout,incoming,outgoing:Integer;

    Procedure listall(otay:Boolean);
      Var count:Integer;
      Var disp:Boolean;
      Begin
        If otay Then WriteLn;
        disp:=otay;
        If disp Then WriteLn(^S'   [ Incoming Emumail ]');
        count:=1;
        If disp Then Begin
          tab('Number',8);
          tab('Title',30);
          tab('Author',28);
          WriteLn;
        End;
        maxin:=0;
        While (count<=44) Do Begin
          If exist(netfiledir+strr(count)+'.in') Then Begin
            If disp Then Write(count:3,'     ');
            If Not disp Then incoming:=incoming+1;
            maxin:=count;
            spostbul(strr(count)+'.in',False);
          End;
          count:=count+1;
        End;
        If disp Then Begin
          WriteLn;
          WriteLn(^S'    [ Outgoing Mail ]');
          WriteLn;
        End;
        count:=1;
        If disp Then Begin
          tab('Number',8);
          tab('Title',30);
          tab('Author',28);
          WriteLn;
        End;
        maxout:=0;
        While (count<=44) Do Begin
          If exist(netfiledir+strr(count)+'.out') Then Begin
            If disp Then Write(count:3,'     ');
            If Not disp Then outgoing:=outgoing+1;
            maxout:=count;
            spostbul(strr(count)+'.out',False);
          End;
          count:=count+1;
        End;
      End;

    Procedure Addone;
      Var zed,one,nextone:anystr;
        ct:Integer;
        jo:Text;
        finished:Boolean;

      Begin
        listall(True);
        writestr(^B^P'Enter specific Emumail # to add :');
        If Input='' Then exit;

        finished:=False;
        nextone:='';
        ct:=0;
        zed:=Input+'.in';
        If exist(netfiledir+zed) Then Begin
          nextone:=zed;WriteLn('Adding #',ct);
          spostbul(nextone,True);
          Assign(jo,netfiledir+nextone);
          Erase(jo);
        End;

        WriteLn;
      End;

    Procedure Delete_InOut;
      Var fnm,tmp:lstr;
        t:Text;
      Begin
        WriteLn;
        writestr(^P'Delete [I]ncoming, [O]utgoing, or [Q]uit: *');
        Input:=UpCase(Input[1]);
        If (Input<>'I') And (Input<>'O') Then exit;
        tmp:='Delete Which Message [1-';
        If Input='I' Then Begin
          tmp:=tmp+strr(maxin)+']: *';
          If maxin=0 Then exit;
          writestr(tmp);
          fnm:=Input;
          fnm:=fnm+'.in';
          WriteLn;
        End Else Begin
          tmp:=tmp+strr(maxout)+']: *';
          If maxout=0 Then exit;
          writestr(tmp);
          fnm:=Input;
          fnm:=Input+'.out';
          WriteLn;
        End;
        tmp:='Delete '+fnm+'? *';
        writestr(tmp);
        fnm:=netfiledir+fnm;
        If yes Then Begin
          If exist(fnm) Then Begin
            Assign(t,fnm);
            Erase(t);
            WriteLn('Done..');
          End Else WriteLn('File doesn''t exist!')
        End;
      End;

    Procedure Kill_List;
      Var ff:File Of netrec;
        Net:netrec;
        cnt,d:Integer;
        a,b,c:anystr;
      Begin
      writehdr( 'Kill A Nodelist');
      assign (ff,curboard.EmuMail_type);
      If (exist(curboard.emumail_type))=false then exit;
      Writestr ('Delete '+curboard.Emumail_type+' Nodelist? *');
      if yes then erase(ff);


      End;

    Procedure Add_entry;
      Var ff:File Of netrec;
        Net:netrec;
        cnt,d:Integer;
        a,b,c:anystr;
      Begin
        Writehdr('Add Nodelist Entry');
        Writestr('Enter BBS Name :');
        If Input='' Then exit;Net.Boardname:=Input;
        Writestr('Enter BBS Location :');
        If Input='' Then exit;net.location:=Input;
        Writestr('Enter Baudrate [1200] :');
        If Input='' Then input:='1200';

        net.callbaud:=valu(Input);
        writestr('Tele # [1 NPA XXX xxxx] :');
        If Input='' Then exit;net.number:=Input;
        Writestr('Enter the PCP Location Code (i.e. CASJO) [None] :');
        If Input='' Then net.citycode:='' Else net.citycode:=Input;
        Assign(ff,curboard.Emumail_type);If exist(curboard.Emumail_type) Then Reset(ff)
        Else Rewrite(ff);
        d:=FileSize(ff);
        Seek(ff,d);
        Write(ff,net);
        Close(ff);

      End;
          var kool:text;
    Begin
      If (Not sponsoron) And (Not issysop) Then exit;
      Repeat
        q:=menu('Emumail','EMUMAIL','ABCDEFGHQKLMNOP');
        Case q Of
          1:add_entry;
          4:delete_Inout;
          5:Addone;
          3:Dothem;
          6:begin
             assign(kool,'netsend.bbs');
             rewrite(kool);
             textclose(kool);
            end;
          11:Listall(True);
          10:Kill_List;
          8:help('Emumail.hlp')
        End
      Until (q=9) Or hungupon
    End;



  Procedure boardsponsor;

    Procedure getbgen(txt:mstr;Var q);
      Var s:lstr Absolute q;
      Begin
        WriteLn(^B'Current '^V,txt,^R': '^V,s);
        BufLen:=30;
        writestr('Enter new '+^V+txt+^P+':');
        If Length(Input)>0 Then s:=Input
      End;

    Procedure getbint(txt:mstr;Var i:Integer);
      Var a:anystr;
      Begin
        a:=strr(i);
        getbgen(txt,a);
        i:=valu(a);
        writecurboard
      End;

    Procedure getbstr(txt:mstr;Var q);
      Begin
        getbgen(txt,q);
        writecurboard
      End;




    Procedure getblevel;
      Var b:bulrec;
      Begin
        getbint('level',curboard.level);
        writelog(5,12,strr(curboard.level))
      End;

    Procedure getautodel;
      Var b:bulrec;
      Begin
        With curboard Do Begin
          getbint('auto-delete',autodel);
          If autodel<10
          Then
            Begin
              WriteLn(^B'HEY!  It can''t be less than ten!');
              autodel:=numbuls+1;
              If autodel<10 Then autodel:=10;
              WriteLn(^B'Setting autodelete to ',autodel);
              writecurboard
            End
          Else
            If autodel<=numbuls
            Then
              Begin
                WriteLn(^B'Deleting bulletins...');
                While autodel<=numbuls Do delbul(2,True)
              End
        End;
        writelog(5,11,strr(curboard.autodel))
      End;


    Procedure movebulletin;
      Var b:bulrec;
        tcb:boardrec;
        tcbn,dbn,bnum:Integer;
        tcbname,dbname:sstr;
      Begin
        writehdr('Bulletin Move');
        getbnum('move');
        If Not checkcurbul Then exit;
        bnum:=curbul;
        seekbfile(bnum);
        Read(bfile,b);
        writestr('Move "'+^V+b.title+^P+'" posted by '+^V+b.leftby+^P+
        ' to which board? *');
        If Length(Input)=0 Then exit;
        tcbname:=curboardname;
        dbname:=Input;
        dbn:=searchboard(dbname);
        If dbn=-1 Then Begin
          WriteLn('No such board!');
          exit
        End;
        WriteLn('Moving...');
        delbul(bnum,False);
        Close(bfile);
        Close(ffile);
        curboardname:=dbname;
        openbfile;
        addbul(b);
        Close(bfile);
        Close(ffile);
        curboardname:=tcbname;
        openbfile;
        writelog(5,13,b.title);
        WriteLn(^B'Done!')
      End;


    Procedure setsponsor;
      Var un:Integer;
        b:bulrec;
      Begin
        writestr('New ECHOMAIL CONF. ['+^S+curboard.EmuMail_type+^P+'] :');
        if length(input)=0 then else curboard.EmuMail_Type:=input;
        writestr('New Access Type [G,B,L] ['+^S+curboard.area_type+^P'] :');
        If Length(Input)=0 Then Else Curboard.area_Type:=UpCase(Input[1]);
        if not ( curboard.area_type[1] in [ 'G' , 'B' , 'L' ] ) then
          exit ;
        if curboard.area_type[1] in [ 'G' , 'B' ] then
          begin
            writestr('New Access File List ['+^S+curboard.File_List+^P+'] :');
            If Length(Input)=0 Then Else curboard.File_List:=Input;
          end
        else
          curboard.file_list := 'None' ;
        writestr('New sponsor (Must change to save above modz!) :');
        If Length(Input)=0 Then exit;
        un:=lookupuser(Input);
        If un=0
        Then WriteLn('No such user.')
        Else
          Begin
            curboard.sponsor:=Input;
            writelog(5,8,Input);
            writecurboard;
          End
      End;

    Procedure renameboard;
      Var sn:sstr;
        nfp,nbf,nff:lstr;
        qf:File;
        d:Integer;
      Begin
        getbstr('board name',curboard.boardname);
        sn:=curboard.shortname;
        getbgen('access name/number',sn);
        writelog(5,5,curboard.boardname+' ['+sn+']');
        If match(sn,curboard.shortname) Then exit;
        If Not validbname(sn) Then Begin
          WriteLn('Invalid board name!');
          exit
        End;
        If boardexist(sn) Then Begin
          WriteLn('AREA already exists!');
          exit
        End;
        curboard.shortname:=sn;
        writecurboard;
        Close(bfile);
        Close(ffile);
        nfp:=boarddir+sn+'.';
        nbf:=nfp+'BUL';
        nff:=nfp+'FIL';
        Assign(qf,nbf);
        Erase(qf);
        d:=IOResult;
        Assign(qf,nff);
        Erase(qf);
        d:=IOResult;
        Rename(bfile,nbf);
        Rename(ffile,nff);
        setfirstboard;
        q:=9
      End;

    Procedure killboard;
      Var cnt:Integer;
        f:File;
        fr:filerec;
        bd:boardrec;
      Begin
        writestr('Kill board:  Are you sure? *');
        If Not yes Then exit;
        writelog(5,10,'');
        WriteLn(^B^M'Deleting messages...');
        For cnt:=numbuls Downto 1 Do
          Begin
            delbul(cnt,True);
            Write(^S,cnt,' ')
          End;
        WriteLn(^B^M'Deleting sub-board files...');
        Close(bfile);
        assignbfile;
        Erase(bfile);
        If IOResult<>0 Then WriteLn(^B'Error erasing board file.');
        WriteLn(^M'Removing sub-board...');
        delboard(curboardnum);
        WriteLn(^B'Sub-board erased!');
        setfirstboard;
        q:=9
      End;

    Procedure sortboards;
      Var cnt,Mark,temp:Integer;
        bd1,bd2:boardrec;
        bn1,bn2:sstr;
        bo:boardorder;
      Begin
        writestr('Sort sub-boards: Are you sure? *');
        If Not yes Then exit;
        clearorder(bo);
        Mark:=FileSize(bdfile)-1;
        Repeat
          If Mark<>0 Then Begin
            temp:=Mark;
            Mark:=0;
            For cnt:=0 To temp-1 Do Begin
              Seek(bifile,cnt);
              Read(bifile,bn1);
              Read(bifile,bn2);
              If upstring(bn1)>upstring(bn2) Then Begin
                Mark:=cnt;
                switchboards(cnt,cnt+1,bo)
              End
            End
          End
        Until Mark=0;
        carryout(bo);
        writelog(5,16,'');
        setfirstboard;
        q:=9
      End;

    Procedure orderboards;
      Var numb,curb,newb:Integer;
        bo:boardorder;
      Label exit;
      Begin
        clearorder(bo);
        writehdr('Re-order sub-boards');
        numb:=FileSize(bdfile);
        thereare(numb,'sub-board','sub-boards');
        For curb:=0 To numb-2 Do Begin
          Repeat
            writestr('New board #'+^V+strr(curb+1)+^P+' [?=List, CR to quit]:');
            If Length(Input)=0 Then GoTo exit;
            If Input='?'
            Then
              Begin
                listboards;
                newb:=-1
              End
            Else
              Begin
                newb:=searchboard(Input);
                If newb<0 Then WriteLn('Not found!  Please re-enter...')
              End
          Until (newb>=0);
          switchboards(curb,newb,bo)
        End;
exit:   
        carryout(bo);
        writelog(5,14,'');
        q:=9;
        setfirstboard
      End;

    Begin
      If (Not sponsoron) And (Not issysop) Then exit;
      writelog(4,3,curboard.boardname+' ['+curboard.shortname+']');
      Repeat
        q:=menu('Co-Sysop','SPONSOR','DLSTMWUEQRKC@B@O@VA@H*@');
        Case q Of
          1:getautodel;
          2:getblevel;
          3:setsponsor;
          10:renameboard;
          11:killboard;
          12:sortboards;
          13:movebulletin;
          14:orderboards;
          17:help('Sponsor.hlp');
          18:activeboard;

        End
      Until (q=9) Or hungupon
    End;

  Var beenaborted:Boolean;

  Function aborted:Boolean;
    Begin
      If beenaborted Then Begin
        aborted:=True;
        exit
      End;
      aborted:=xpressed Or hungupon;
      If xpressed Then Begin
        beenaborted:=True;
        WriteLn(^B^S'Newscan aborted!')
      End
    End;

  Procedure newscanboard;
    Var was,is,max:Integer;

    Procedure newscan_area;
      Var data:anystr;
         cp,lastplace, muff:integer;
          shit:lstr;
      Begin
        was:=curbul;
        Max:=numbuls;
        muff:=0;
        While (is<(max+1)) And (Is>0) Do Begin
          Max:=numbuls;

          curbul:=is;
          readcurbul;

            Writestr('Newscan [#] [F,B]Thread [A]gain [E]nter [D]elete [R]eply [S]kip [Q]uit :');
            If Input='' Then Input:='*';
            if valu(input)>0 then is:=valu(input)-1;
            data:=UpCase(Input[1]);
            If data='A' Then dec(is);
            If data='!' Then getroute;
            If data='S' Then exit;
            If data='E' Then postbul;
            If data='D' Then killbul;
            if data='L' then begin if lastplace>0 then is:=lastplace;lastplace:=0; muff:=0; end;
            if data='F' then begin
            shit:=b.title;
                         muff:=findthread (shit,is,1);
                         if (muff>0) and (lastplace=0) then lastplace:=is;
                         if muff>0 then is:=muff-1 else begin
                                   Writestr (^S'[No Match]:');dec(is);end;
                        end;

            if data='B' then begin
                         shit:=b.title;
                         muff:=findthread (shit,is,0);
                         if (muff>0) and (lastplace=0) then lastplace:=is;
                         if muff>0 then is:=muff-1 else begin
                                   Writestr (^S'[No Match]:');dec(is);end;
                        end;

            If data='R' Then replybul(b.leftby,b.title);

            If data='Q' Then Begin
                         beenaborted:=True;
                           exit;
                        End;
            If data='N' Then exit;
                      inc(is);
        End;

      End;



    Var newmsgs:Boolean;
      oldb:Boolean;
      tempcurbul:Integer;
    Begin
      beenaborted:=False;
      newmsgs:=False;
      tempcurbul:=0;
      curbul:=tempcurbul;
      is:=0;
      While (is=0) And (tempcurbul<=numbuls) Do Begin

        inc(tempcurbul);curbul:=tempcurbul;getbrec;

        If b.when>laston Then Begin
          is:=tempcurbul;
          newmsgs:=True;
        End;

      End;

      If (newmsgs) Or (is<>0) Then newscan_Area;
      If aborted Then exit;

      If (Urec.emulation<>2) And newmsgs And (ulvl>=postlevel)
      Then Begin

          writestr(^M'Enter a Message(y/n)? *');

        WriteLn;
        If yes Then postbul
      End
    End;

  Procedure newscanall;
    Var cb:Integer;
    Begin
      beenaborted:=False;
      ansicls;
      If aborted Then exit;
      For cb:=0 To FileSize(bdfile)-1 Do Begin
        If aborted Then exit;
        If haveaccess(cb) And (Not(cb In urec.newscanconfig)) Then Begin
          curboardname:=curboard.shortname;
          openbfile;
          If aborted Then exit;
          If ((vt52 in urec.config) or (ansigraphics In urec.config)) And (WhereY>7) Then ansicls;
          WriteLn(^B^R'Checking area ['^S,curboard.boardname,^R']');
          If aborted Then exit;
          newscanboard
        End
      End;
      If urec.emulation=1 Then WriteLn(^B^M^S'Newscan complete!'^G);
      setfirstboard
    End;

  Procedure noboards;
    Begin
      WriteLn('No message bases exist!');
      If Not issysop Then exit;
      writestr('Create the first message base now? *');
      If Not yes Then exit;
      writestr('Enter its area [name/number]:');
      If Not validbname(Input) Then WriteLn(^B'Invalid message area!') Else Begin
        curboardname:=Input;
        makeboard
      End
    End;

  Procedure togglenewscan;
    Begin
      Write('Newscan this board: ');
      If curboardnum In urec.newscanconfig
      Then
        Begin
          WriteLn('Yes');
          urec.newscanconfig:=urec.newscanconfig-[curboardnum]
        End
      Else
        Begin
          WriteLn('No');
          urec.newscanconfig:=urec.newscanconfig+[curboardnum]
        End
    End;

  Procedure nextsubboard;
    Var cb:Integer;
      obn:sstr;
    Begin
      obn:=curboardname;
      cb:=curboardnum;
      While cb<FileSize(bdfile)-1 Do Begin
        cb:=cb+1;
        If haveaccess(cb) Then Begin
          Seek(bifile,cb);
          Read(bifile,obn);
          setactive(obn,False);
          exit
        End
      End;
      writestr('This is the last sub-board!');
      setactive(obn,False)
    End;

  Var boo:Boolean;
  Procedure PCBMENU;
    Var k:Char;
    Begin

      boo:=checkcurbul;
      If pcbmover='N' Then Begin WriteLn(^B'QuickScanning for all new messages...');newscanall;End;
      If pcbMover='E' Then Begin
        WriteLn('Current Conference:',curboard.boardname);
        Writestr('(J)oin Other Conference (Return)=Continue :');
        If Input='' Then Else If UpCase(Input[1])='J' Then activeboard;
        Postbul;
      End;
      If PCBMover='R' Then Begin

        With curboard Do
          WriteLn(^M'Current Conference ('^S,boardname,^R') ('^S,shortname,^R')');

        If sponsoron Or issysop
        Then WriteLn('(%) for Co-Sysop commands');
        Repeat
          WriteLn(^M'(J)oin Conference (#)=Read num (*)=New Msgs');
          Writestr('View: (1-'+strr(numbuls)+') Command? *');
          If Input='' Then k:=#0 Else K:=UpCase(Input[1]);
          If Input='' Then Else Begin
            If k='J' Then Activeboard;
            If (k='%') And (sponsoron Or issysop) Then boardsponsor;
            If valu(k)>0 Then Begin
              pcbmover:=Input;
              Readbul;
            End;
            If k='*' Then Begin WriteLn(^M'Scanning for new Messages...');
            newscanboard;End;
          End;
        Until hungupon Or (Input='') Or (FileSize(Bdfile)=0);


      End;
    End;

  Label exit;
  Begin
    ansicls;
    cursection:=bulletinsysop;
    openbdfile;
    If FileSize(bdfile)=0 Then Begin
      noboards;
      If FileSize(bdfile)=0 Then Begin
        closebdfile;
        GoTo exit
      End
    End;
    If Not haveaccess(0)
    Then
      Begin
        WriteLn(^B'You do not have access to the message bases!');
        closebdfile;
        GoTo exit
      End;
    If urec.whereBase='' Then setfirstboard Else setactive(urec.wherebase,False);
    If exist(netfiledir+'1.in') Then dothem;
    If exist(netfiledir+'2.in') Then dothem;
  {  If Urec.emulation=2 Then PCBMenu Else} Begin
      Repeat
        boo:=checkcurbul;
        If (vt52 in urec.config) or (ansigraphics In urec.config) Then Begin
          If WhereY>21 Then Begin ansigotoxy(1,24);WriteLn(^B^M^M);ansigotoxy(1,22);
        End;End;


        With curboard Do
          WriteLn(^M,'[Message Bases]'^M'['^S,boardname,^R'] ['^S,shortname,^R'] ['^S,curbul,^R' of '^S,numbuls,^R']');

        If sponsoron Or issysop
        Then WriteLn(^R'['^S'%'^R'] for Co-Sysop commands');

         if curboard.EmuMail_Type='' then begin
             Writeln (usr,'** Automatic Upgrade Activated 1-23-89');
             curboard.EmuMail_type:='NODELIST.BBS';
             writecurboard;end;

        If urec.emulation=1 Then
          q:=menu('Bulletin','BULLET1','PRDFUKT*MQ#_%LNBAVCHES+W!G^')
       Else q:=menu('Message','BULLET','PRDFUKT*MQ#_%LNBAVCHIS+WEG^');

        Case q Of
          1,25:postbul;
          2:readbul;
          4,22:If urec.emulation=1 Then sendmailto(curboard.sponsor,False);
          5:begin pcbmover:='MessageUPLOAD'; postbul;pcbmover:=''; end;
          6:killbul;
          8,16,17:activeboard;
          7:listbuls; {allwithaccess(curboard.level,0,0,curboard.File_List);}
          9:If urec.emulation=1 Then sendbreply;
          12:If Not hungupon Then readnextbul;
          13:boardsponsor;
          15:newscanall;
          18:newscanboard;
          19:If urec.emulation=1 Then togglenewscan;
          20:help('Message.hlp');
          21:editbul;
             24:If urec.emulation=1 Then readnum(lastreadnum+1) Else listallwithaccess(curboard.level,0,0,curboard.File_List);
          26:If (urec.emulation<>1) Then offtheforum;
          27:emumailsponsor;
        Else If q<0 Then readnum(-q)
        End
      Until (q=10) Or hungupon Or (FileSize(bdfile)=0);
      exit:
      close(bfile);
      closebdfile;
      end;
      end;

      begin
      end.