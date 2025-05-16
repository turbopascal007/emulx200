  {	Revision History....
        881028 - Changed Last caller display to check minimumleveltolistuser
                 - Trogolodyte
        881025 - Fixed display of News items
                 - Troglodyte
  }
  {$R-,S-,I-,D-,F+,V-,B-,N-,L+ }

  unit overret1;

  Interface

  uses crt,
  gentypes,modem,configrt,gensubs,subs1,subs2,userret,textret,flags,mainr1;

  Procedure help(fn:mstr);
  Procedure edituser(eunum:Integer);
  Procedure printnews;
  Procedure sendmodemstr(ss:anystr;endifcarrier:Boolean);
  Function getlastcaller:mstr;
  Procedure showlastcallers;
  Procedure infoform;
  Function selectspecs(Var us:userspecsrec):Boolean;{ True if user aborts }
    Procedure editoldspecs;


    Implementation


  Procedure help(fn:mstr);
    Var tf:Text;
      htopic,cnt:Integer;
    Begin
      fn:=textfiledir+fn;
      Assign(tf,fn);
      Reset(tf);
      If IOResult<>0 Then Begin
        writestr('Sorry, no help is availiable!');
        If issysop Then Begin
          WriteLn('Sysop: To make help, create a file called ',fn);
          WriteLn('Group the lines into blocks separated by periods.');
          WriteLn('The first group is the topic menu; the second is the');
          WriteLn('help for topic 1; the third for topic 2; etc.')
        End;
        exit
      End;
      Repeat
        textclose(tf);
        Assign(tf,fn);
        Reset(tf);
        WriteLn(^M);
        printtexttopoint(tf);
        Repeat
          writestr(^M'Topic number [CR quits]:');
          If hungupon Or (Length(Input)=0) Then
            Begin
              textclose(tf);
              exit
            End;
          htopic:=valu(Input)
        Until (htopic>0);
        For cnt:=2 To htopic Do
          If Not EoF(tf)
          Then skiptopoint(tf);
        If EoF(tf)
        Then writestr('Sorry, no help on that topic!')
        Else printtexttopoint(tf)
      Until 0=1
    End;

  Procedure edituser(eunum:Integer);
    Var eurec:userrec;
      ca:Integer;
      k:Char;
    Const sysopstr:Array[false..true] Of String[6]=('Normal','Sysop');
      sectionnames:Array[udsysop..databasesysop] Of String[20]=
      ('File transfer','Bulletin section','Voting booths',
      'E-mail section','Doors','Main menu','Databases');

    Procedure truesysops;
      Begin
        WriteLn('Sorry, you may not do that without true sysop access!');
        writelog(18,17,'')
      End;

    Function truesysop:Boolean;
      Begin
        truesysop:=ulvl>=sysoplevel
      End;

    Procedure eustatus;
      Var cnt:Integer;
        k:Char;
        c:configtype;
      Begin
        writehdr('Status');
        With eurec Do Begin
  if ulvl>=sysoplevel then begin

          Write(^M'Number:    '^S,eunum,
          ^M'Name:      '^S,handle,
          ^M'Phone #:   '^S,phonenum,
          ^M'Pwd:       '^S);
          end else begin
                    Write(^M'Number:    '^S,eunum,
          ^M'Name:      '^S,handle,
          ^M'Pwd:       '^S);

          end;
          If truesysop
          Then Write(password)
          Else Write('Classified');
          Write(^M'Level:     '^S,level,
          ^M'Last on:   '^S,datestr(laston),', at ',timestr(laston),
          ^M'Posts:     '^S,nbu,
          ^M'Uploads:   '^S,nup,
          ^M'Downloads: '^S,ndn,
          ^M'Wanted:    '^S,yesno(wanted In config),
          ^M'File xfer',
          ^M'  Level:   '^S,udlevel,
          ^M'  Points:  '^S,udpoints,
          ^M'  Uploads: '^S,uploads,
          ^M'  Dnloads: '^S,downloads,
          ^M^M'Time on system:  '^S,totaltime:0:0,
          ^M'Number of calls: '^S,numon,
          ^M'Voting record:   '^S);
          For cnt:=1 To maxtopics Do Begin
            If cnt<>1 Then Write(',');
            Write(voted[cnt])
          End;
          WriteLn(^M);
          For c:=udsysop To databasesysop Do
            If c In eurec.config
            Then WriteLn(^B'Co-Sysop of the '^S,sectionnames[c]);
          WriteLn
        End;
        writelog(18,13,'')
      End;

    Procedure getmstr(t:mstr;Var mm);
      Var m:mstr Absolute mm;
      Begin
        WriteLn('Old ',t,': '^S,m);
        writestr('New '+t+'? *');
        If Length(Input)>0 Then m:=Input
      End;

    Procedure getsstr(t:mstr;Var s:sstr);
      Var m:mstr;
      Begin
        m:=s;
        getmstr(t,m);
        s:=m
      End;

    Procedure getint(t:mstr;Var i:Integer);
      Var m:mstr;
      Begin
        m:=strr(i);
        getmstr(t,m);
        i:=valu(m)
      End;

    Procedure euwanted;
      Begin
        writestr('Wanted status: '^S+yesno(wanted In eurec.config));
        writestr('New wanted status:');
        If yes
        Then eurec.config:=eurec.config+[wanted]
        Else eurec.config:=eurec.config-[wanted];
        writelog(18,1,yesno(wanted In eurec.config))
      End;

    Procedure eudel;
      Begin
        writestr('Delete user --- confirm:');
        If yes Then Begin
          deleteuser(eunum);
          Seek(ufile,eunum);
          Read(ufile,eurec);
          writelog(18,9,'')
        End
      End;

    Procedure euname;
      Var m:mstr;
      Begin
        m:=eurec.handle;
        getmstr('name',m);
        If Not match(m,eurec.handle) Then
          If lookupuser(m)<>0 Then Begin
            writestr('Already exists!  Are you sure? *');
            If Not yes Then exit
          End;
        eurec.handle:=m;
        writelog(18,6,m)
      End;

    Procedure eupassword;
      Begin
        If Not truesysop
        Then truesysops
        Else Begin
          getsstr('password',eurec.password);
          writelog(18,8,'')
        End
      End;

    Procedure eulevel;
      Var n:Integer;
      Begin
        n:=eurec.level;
        getint('level',n);
        If (n>=sysoplevel) And (Not truesysop)
        Then truesysops
        Else Begin
          eurec.level:=n;
          writelog(18,15,strr(n))
        End
      End;

    procedure EuNotes;
    var N:mstr;
    begin
    Write ('User Notes [N] for Null');
     n:=eurec.notes;
     GetMstr('U/Note',n);
     if (length(n)>0) then
     begin
     if upcase(n[1])='N' then n:='';
     eurec.notes:=n;
     end;

    end;

    Procedure euphone;
      Var m:mstr;
        p:Integer;
      Begin
      if ulvl<sysoplevel then exit;
        m:=eurec.phonenum;
        BufLen:=15;
        getmstr('phone number',m);
        p:=1;
        While p<=Length(m) Do
          If (m[p] In ['0'..'9'])
          Then p:=p+1
          Else Delete(m,p,1);
        If Length(m)>7 Then Begin
          eurec.phonenum:=m;
          writelog(18,16,m)
        End
      End;

    Procedure boardflags;
      Var quit:Boolean;

      Procedure listflags;
        Var bd:boardrec;
          cnt:Integer;
        Begin
          Seek(bdfile,0);
          For cnt:=0 To FileSize(bdfile)-1 Do Begin
            Read(bdfile,bd);
            tab(bd.shortname,9);
            tab(bd.boardname,30);
            WriteLn(accessstr[getuseraccflag(eurec,cnt)]);
            If break Then exit
          End
        End;

      Procedure changeflag;
        Var bn,q:Integer;
          bname:mstr;
          ac:accesstype;
        Begin
          BufLen:=8;
          writestr('Board to change access:');
          bname:=Input;
          bn:=searchboard(Input);
          If bn=-1 Then Begin
            WriteLn('Not found!');
            exit
          End;
          WriteLn(^B^M'Current access: '^S,
          accessstr[getuseraccflag(eurec,bn)]);
          getacflag(ac,Input);
          If ac=invalid Then exit;
          setuseraccflag(eurec,bn,ac);
          Case ac Of
            letin:q:=2;
            keepout:q:=3;
            bylevel:q:=4
          End;
          writelog(18,q,bname)
        End;

      Procedure allflags;
        Var ac:accesstype;
        Begin
          writehdr('Set all board access flags');
          getacflag(ac,Input);
          If ac=invalid Then exit;
          writestr('Confirm [Y/N]:');
          If Not yes Then exit;
          setalluserflags(eurec,ac);
          writelog(18,5,accessstr[ac])
        End;

      Begin
        opentempbdfile;
        quit:=False;
        Repeat
          Repeat
            writestr(^M'L)ist flags, C)hange one flag, A)ll flags, or Q)uit:');
            If hungupon Then exit
          Until Length(Input)<>0;
          Case UpCase(Input[1]) Of
            'L' :listflags;
            'C' :changeflag;
            'A' :allflags;
            'Q' :quit:=True
          End
        Until quit;
        closetempbdfile
      End;

    Procedure specialsysop;

      Procedure getsysop(c:configtype);
        Begin
          WriteLn('Section ',sectionnames[c],': '^S,
          sysopstr[c In eurec.config]);
          writestr('Grant sysop access? *');
          If Length(Input)<>0
          Then If yes
            Then
              Begin
                eurec.config:=eurec.config+[c];
                writelog(18,10,sectionnames[c])
              End
            Else
              Begin
                eurec.config:=eurec.config-[c];
                writelog(18,11,sectionnames[c])
              End
        End;

      Begin
        If Not truesysop Then Begin
          truesysops;
          exit
        End;
        writestr
        ('Section of [M]ain [F]ile [B]ulletin [V]oting [E]mail [D]atabase [P]Doors:');
        If Length(Input)=0 Then exit;
        Case UpCase(Input[1]) Of
          'M' :getsysop(mainsysop);
          'F' :getsysop(udsysop);
          'B' :getsysop(bulletinsysop);
          'V' :getsysop(votingsysop);
          'E' :getsysop(emailsysop);
          'D' :getsysop(databasesysop);
          'P' :getsysop(doorssysop)
        End
      End;

    Procedure getlogint(prompt:mstr;Var i:Integer;Ln:Integer);
      Begin
        getint(prompt,i);
        writelog(18,Ln,strr(i))
      End;

    Var q:Integer;
    Begin
      writeurec;
      Seek(ufile,eunum);
      Read(ufile,eurec);
      writelog(2,3,eurec.handle);
      Repeat
        WriteLn('Editing User #',eunum,' Name: ',eurec.handle,^M^M);
        q:=menu('User edit','UEDIT','SDHPLOEWTBQYNIGU');
        Case q Of
          1:eustatus;
          2:eudel;
          3:euname;
          4:eupassword;
          5:eulevel;
          6:getlogint('u/d points',eurec.udpoints,7);
          7:getlogint('u/d level',eurec.udlevel,14);
          8:euwanted;
          9:getlogint('time for today',eurec.timetoday,12);
          10:boardflags;
          12:specialsysop;
          13:euphone;

          14:begin
             showinfoforms(strr(eunum));
             Writestr ('Kill the infoform? *');
             if yes then begin
                            deletetext(eurec.infoform);
        eurec.infoform:=-1;
        end;
        end;

          15:Begin
               getlogint('Gfile level ',eurec.gflevel,7);
               getlogint('Gfile points',eurec.gpoints,7);
             End;
             16:eunotes;
        End
      Until hungupon Or (q=11);
      writeufile(eurec,eunum);
      readurec
    End;

  Procedure printnews;
    Var nfile:File Of newsrec;
      line:Integer;
      Ntmp:newsrec;cnt:Integer;
    Begin
      Assign(nfile,'News');
      Reset(nfile);
      If IOResult<>0 Then exit;
      If FileSize(nfile)=0 Then Begin
        Close(nfile);
        exit
      End;
      writehdr('News: [Ctrl-X] to abort');
      cnt:=0;
      While Not(EoF(nfile) Or break Or hungupon) Do Begin
        Read(nfile,Ntmp);
        If (ntmp.location>=0) And (ntmp.maxlevel>=urec.level) And (urec.level>=ntmp.level) Then Begin
          inc(cnt);

          If urec.emulation<>1 Then Begin
            WriteLn(^B'News #',cnt,' "',ntmp.title,'" from ',ntmp.from);
            WriteLn(^B'Date: ',datestr(ntmp.when),' Level [',ntmp.level,' - ',ntmp.maxlevel,']');
            WriteLn(^B'______________________________');
          End;
          printtext(Ntmp.location)
        End;

      End;

      Close(nfile)
    End;

  Procedure sendmodemstr(ss:anystr;endifcarrier:Boolean);
    Var cnt,Ptr:Integer;
      k:Char;
    Label exit;
    Begin
      writeln(ss);
      Ptr:=0;
      While Ptr<Length(ss) Do
        Begin
          If keyhit Or (carrier=endifcarrier) Then GoTo exit;
          Ptr:=Ptr+1;
          k:=ss[Ptr];
          Case k Of
            '|' :sendchar(^M);
            '~' :Delay(500);
            '^' :Begin
                   Ptr:=Ptr+1;
                   If Ptr>Length(ss)
                   Then k:='^'
                   Else k:=UpCase(ss[Ptr]);
                   If k In ['A'..'Z']
                   Then sendchar(Chr(Ord(k)-64))
                   Else sendchar(k)
                 End;
          Else sendchar(k)
          End;
          Delay(100);
          While numchars>0 Do writecon(getchar)
        End;
      cnt:=0;
      Repeat
        While numchars>0 Do Begin
          cnt:=0;
          writecon(getchar)
        End;
        cnt:=cnt+1
      Until (cnt=1000) Or keyhit Or (carrier=endifcarrier);
exit: 
      break:=keyhit
    End;

  Function getlastcaller:mstr;
    Var qf:File Of lastrec;
      l:lastrec;
    Begin
      getlastcaller:='';
      Assign(qf,'Callers');
      Reset(qf);
      If IOResult=0 Then
        If FileSize(qf)>0
        Then
          Begin
            Seek(qf,0);
            Read(qf,l);
            getlastcaller:=l.name
          End;
      Close(qf)
    End;

  Procedure showlastcallers;
    Var qf:File Of lastrec;
      cnt:Integer;
      l:lastrec;
    Begin
      If minimumleveltolistusers>ulvl Then exit;
      Assign(qf,'Callers');
      Reset(qf);
      If IOResult=0 Then Begin
        writehdr('Recent caller list');
        break:=False;
        For cnt:=0 To FileSize(qf)-1 Do
          If Not break Then Begin
            Read(qf,l);
            tab(l.name,33);
            WriteLn(datestr(l.when)+' '+timestr(l.when))
          End
      End;
      Close(qf)
    End;

  Procedure infoform;
    Var ff:Text;
      fn:lstr;
      k:Char;
      me:message;
    Begin
      WriteLn;
      fn:=textfiledir+'InfoForm';
      If Not exist(fn) Then Begin
        writestr('There isn''t an information form right now.');
        If issysop Then
          WriteLn('Sysop: To make an information form, create a text file',
          ^M'called ',fn,'.  Put a * at the end of each input prompt.');
        exit
      End;
      If urec.infoform<>-1 Then Begin
        writestr('You have already filled out the Questionarre.  Replace it? *');
        If Not issysop Then WriteLn(^B^M'You must be a sysop to change the InfoForm!'^M^M^M);
        If Not issysop Then exit;
        If Not yes Then exit;
        deletetext(urec.infoform);
        urec.infoform:=-1;
        writeurec
      End;
      Assign(ff,fn);
      Reset(ff);
      me.numlines:=1;
      me.title:='';
      me.anon:=False;
      me.text[1]:='Filled out on: '+datestr(now)+' at '+timestr(now);
      While Not EoF(ff) Do Begin
        If hungupon Then Begin
          textclose(ff);
          exit
        End;
        Read(ff,k);
        If k='*' Then Begin
          nochain:=True;
          getstr;
          me.numlines:=me.numlines+1;
          me.text[me.numlines]:=Input
        End Else writechar(k)
      End;
      textclose(ff);
      urec.infoform:=maketext(me);
      writeurec
    End;

  Procedure openusfile;
    Const newusers:userspecsrec=(name:'New users';minlevel:1;maxlevel:1;
      minlaston:-MaxInt;maxlaston:MaxInt;minpcr:-MaxInt;maxpcr:MaxInt);
    Begin
      Assign(usfile,'userspec');
      Reset(usfile);
      If IOResult<>0 Then Begin
        Rewrite(usfile);
        If level2nd<>0 Then newusers.maxlevel:=level2nd;
        Write(usfile,newusers)
      End
    End;

  Procedure editspecs(Var us:userspecsrec);

    Procedure get(tex:String;Var value:Integer;min:Boolean);
      Var vstr:sstr;
      Begin
        BufLen:=6;
        If abs(value)=MaxInt Then vstr:='None' Else vstr:=strr(value);
        writestr(tex+' ['+vstr+']:');
        If Input[0]<>#0
        Then If UpCase(Input[1])='N'
          Then If min
            Then value:=-MaxInt
            Else value:=MaxInt
          Else value:=valu(Input)
      End;

    Procedure getreal(tex:String;Var value:Real;min:Boolean);
      Var vstr:sstr;
        s:Integer;
      Begin
        BufLen:=10;
        If abs(value)=MaxInt Then vstr:='None' Else vstr:=streal(value);
        writestr(tex+' ['+vstr+']:');
        If Length(Input)<>0
        Then If UpCase(Input[1])='N'
          Then If min
            Then value:=-MaxInt
            Else value:=MaxInt
          Else Begin
            Val(Input,value,s);
            If s<>0 Then value:=0
          End
      End;

    Begin
      WriteLn(^B^M'Enter specifications; N for none.'^M);
      BufLen:=30;
      writestr('Specification set name ['+us.name+']:');
      If Length(Input)<>0
      Then If match(Input,'N')
        Then us.name:='Unnamed'
        Else us.name:=Input;
      get('Lowest level',us.minlevel,True);
      get('Highest level',us.maxlevel,True);
      get('Lowest #days since last call',us.minlaston,True);
      get('Highest #days since last call',us.maxlaston,True);
      getreal('Lowest post to call ratio',us.minpcr,True);
      getreal('Highest post to call ratio',us.maxpcr,True)
    End;

  Function getspecs(Var us:userspecsrec):Integer;{ -1:not saved   >0:in file }
    Begin
      With us Do Begin
        name:='Unnamed';{ Assumes USFILE is open !! }
        minlevel:=-MaxInt;
        maxlevel:=MaxInt;
        minlaston:=-MaxInt;
        maxlaston:=MaxInt;
        minpcr:=-MaxInt;
        maxpcr:=MaxInt
      End;
      editspecs(us);
      writestr(^M'Save these specs to disk? *');
      If yes Then Begin
        Seek(usfile,FileSize(usfile));
        Write(usfile,us);
        getspecs:=FileSize(usfile)
      End Else getspecs:=-1
    End;

  Function searchspecs(Var us:userspecsrec;name:mstr):Integer;
    Var v,Pos:Integer;
    Begin
      v:=valu(name);
      Seek(usfile,0);
      Pos:=1;
      While Not EoF(usfile) Do Begin
        Read(usfile,us);
        If match(us.name,name) Or (valu(name)=Pos) Then Begin
          searchspecs:=Pos;
          exit
        End;
        Pos:=Pos+1
      End;
      searchspecs:=0;
      writestr(^M'Not found!')
    End;

  Procedure listspecs;
    Var us:userspecsrec;
      Pos:Integer;

    Procedure writeval(n:Integer);
      Begin
        If abs(n)=MaxInt Then Write('   None') Else Write(n:7)
      End;

    Procedure writevalreal(n:Real);
      Begin
        If abs(n)=MaxInt Then Write('   None') Else Write(n:7:2)
      End;

    Begin
      writehdr('User Specification Sets');
      Seek(usfile,0);
      Pos:=0;
      tab('',35);
      tab('    Level    ',14);
      tab('  Last Call  ',14);
      WriteLn('  Post/Call Ratio  ');
      While Not(break Or EoF(usfile)) Do Begin
        Pos:=Pos+1;
        Read(usfile,us);
        Write(Pos:3,'. ');
        tab(us.name,30);
        writeval(us.minlevel);
        writeval(us.maxlevel);
        writeval(us.minlaston);
        writeval(us.maxlaston);
        writevalreal(us.minpcr);
        writevalreal(us.maxpcr);
        WriteLn
      End
    End;

  Function selectaspec(Var us:userspecsrec):Integer;{  0 = none         }
    Var done:Boolean;{ -1 = not in file  }
      Pos:Integer;{ -2 = added to end }
    Begin
      selectaspec:=0;
      openusfile;
      If FileSize(usfile)=0
      Then selectaspec:=getspecs(us)
      Else
        Repeat
          If hungupon Then exit;
          done:=False;
          writestr(^M'Specification set name (?=list, A=add):');
          If Length(Input)=0
          Then done:=True
          Else If match(Input,'A')
            Then
              Begin
                Pos:=getspecs(us);
                If Pos>0
                Then selectaspec:=-2
                Else selectaspec:=-1;
                done:=True
              End
            Else If match(Input,'?')
              Then listspecs
              Else
                Begin
                  Pos:=searchspecs(us,Input);
                  done:=Pos<>0;
                  selectaspec:=Pos
                End
        Until done;
      Close(usfile)
    End;

  Function selectspecs(Var us:userspecsrec):Boolean;
    Var dummy:Integer;
    Begin
      dummy:=selectaspec(us);
      selectspecs:=dummy=0
    End;

  Procedure deletespecs(Pos:Integer);
    Var cnt:Integer;
      us:userspecsrec;
    Begin
      openusfile;
      For cnt:=Pos To FileSize(usfile)-1 Do Begin
        Seek(usfile,cnt);
        Read(usfile,us);
        Seek(usfile,cnt-1);
        Write(usfile,us)
      End;
      Seek(usfile,FileSize(usfile)-1);
      Truncate(usfile);
      Close(usfile)
    End;

  Procedure editoldspecs;
    Var Pos:Integer;
      us:userspecsrec;
    Begin
      Repeat
        Pos:=selectaspec(us);
        If Pos>0 Then Begin
          BufLen:=1;
          writestr(^M'E)dit or D)elete? *');
          If Length(Input)=1 Then Case UpCase(Input[1]) Of
            'E' :Begin
                   editspecs(us);
                   openusfile;
                   Seek(usfile,Pos-1);
                   Write(usfile,us);
                   Close(usfile)
                 End;
            'D' :deletespecs(Pos)
          End
        End
      Until (Pos=0) Or hungupon
    End;

  Begin
  End.
