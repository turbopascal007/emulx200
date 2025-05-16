  {$R-,S-,I-,D-,F+,V-,B-,N-,L+,O+ }

  unit email;

  Interface

  uses crt,gentypes,configrt,gensubs,subs1,subs2,textret,flags,
  mailret,userret,overret1,mainr1,mainr2;

  Procedure emailmenu;

  Implementation

Procedure emailmenu;
  Var lastread:Integer;
    m:mailrec;
    incoming,outgoing:catalogrec;

  Procedure addcatalog(Var c:catalogrec;Var m:mailrec;fpos:Integer);
    Begin
      m.fileindex:=fpos;
      If c.nummail=maxcatalogsize
      Then c.additional:=c.additional+1
      Else Begin
        c.nummail:=c.nummail+1;
        c.mail[c.nummail]:=m
      End
    End;

  Procedure writenummail(Var c:catalogrec;txt:mstr);
    Begin
      WriteLn(^B^M'You have ',c.nummail+c.additional,' ',txt,
      ' message',s(c.nummail));
      If c.additional>0
      Then WriteLn('   Note: Of those, ',
        numthings(c.additional,'is','are'),' uncataloged.')
    End;

  Procedure readcatalogs;
    Var m:mailrec;
      cnt:Integer;
    Begin
      Seek(mfile,1);
      incoming.nummail:=0;
      incoming.additional:=0;
      outgoing.nummail:=0;
      outgoing.additional:=0;
      For cnt:=1 To FileSize(mfile)-1 Do Begin
        Read(mfile,m);
        If m.sentto=unum
        Then addcatalog(incoming,m,cnt);
        If match(m.sentby,unam)
        Then addcatalog(outgoing,m,cnt)
      End
    End;

  Procedure readit(Var m:mailrec);
    Begin
      Write(^B^M'Subject:   '^S,m.title,^M'From: '^S);
      If m.anon
      Then
        Begin
          Write(anonymousstr);
          If issysop Then Write(' (',m.sentby,')')
        End
      Else Write(m.sentby);
      WriteLn(^M'Date: '^S,datestr(m.when),' at ',timestr(m.when));
      WriteLn;
      If Not break Then printtext(m.line)
    End;

  Procedure readincoming(n:Integer);
    Var m:^mailrec;
      cnt:Integer;
    Begin
      m:=Addr(incoming.mail[n]);
      readit(m^);
      If Not(m^.read) Then Begin
        m^.read:=True;
        Seek(mfile,m^.fileindex);
        Write(mfile,m^)
      End;
      For cnt:=n+1 To incoming.nummail Do
        If match(incoming.mail[cnt].sentby,m^.sentby) Then Begin
          WriteLn(^B^M'Another piece of mail from ',m^.sentby,'!');
          exit
        End
    End;

  Procedure listmail(Var c:catalogrec);
    Var n:Integer;
      u:userrec;
      cnt:Integer;
      m:mailrec;
    Begin
      Write('Num  ');
      tab('Subject',30);
      Write('New  Sent ');
      If Ofs(c)=Ofs(incoming) Then WriteLn('by'^M) Else WriteLn('to'^M);
      WriteLn('------------------------------------------'^M);
      If break Then exit;
      For cnt:=1 To c.nummail Do If Not break Then Begin
        m:=c.mail[cnt];
        Write(cnt:2,'.  ');
        If Not break Then tab(m.title,30);
        If Not break Then If m.read Then Write('     ') Else Write('New  ');
        If match(m.sentby,unam)
        Then WriteLn(lookupuname(m.sentto))
        Else WriteLn(m.sentby)
      End
    End;

  Procedure writemail(Var c:catalogrec;num:Integer);
    Begin
      Seek(mfile,c.mail[num].fileindex);
      Write(mfile,c.mail[num])
    End;

  Function checklastread:Boolean;
    Begin
      If (lastread<0) Or (lastread>incoming.nummail) Then lastread:=0;
      checklastread:=lastread=0
    End;

  Function getmsgnumber(Var c:catalogrec;txt:sstr):Integer;
    Var n:Integer;
      inc:Boolean;
    Begin
      inc:=Ofs(c)=Ofs(incoming);
      getmsgnumber:=0;
      If c.nummail=0 Then Begin
        If c.additional>0 Then readcatalogs;
        If c.nummail=0 Then writestr(^M'You have no mail waiting now!');
        If inc Then lastread:=0;
        exit
      End;
      Input:=Copy(Input,2,255);
      If Length(Input)=0
      Then If inc
        Then n:=lastread
        Else n:=0
      Else n:=valu(Input);
      If (n<1) Or (n>c.nummail) Then Begin
        Repeat
          writestr(^M'Message number to '+txt+' [?=list]:');
          If Length(Input)=0 Then exit;
          If Input='?' Then listmail(c)
        Until Input<>'?';
        n:=valu(Input);
        If (n<1) Or (n>c.nummail) Then n:=0
      End;
      getmsgnumber:=n
    End;

  Procedure deletemail(Var c:catalogrec;n:Integer);
    Begin
      delmail(c.mail[n].fileindex);
      WriteLn(c.mail[n].title,' by ',c.mail[n].sentby,' deleted.');
      readcatalogs
    End;

  Procedure nextmail;
    Begin
      lastread:=lastread+1;
      If lastread>incoming.nummail
      Then
        Begin
          lastread:=0;
          If incoming.additional>0
          Then WriteLn('You must delete some old mail first!')
          Else WriteLn('Sorry, no more mail!')
        End
      Else readincoming(lastread)
    End;

  Procedure readnum(n:Integer);
    Begin
      If (n<1) Or (n>incoming.nummail) Then Begin
        lastread:=0;
        exit
      End;
      lastread:=n;
      readincoming(n)
    End;

  Procedure readmail;
    Begin
      readnum(getmsgnumber(incoming,'read'))
    End;

  Procedure listallmail;
    Begin
      If incoming.nummail>0 Then Begin
        writehdr('Incoming mail');
        listmail(incoming)
      End;
      If outgoing.nummail>0 Then Begin
        writehdr('Outgoing mail');
        listmail(outgoing)
      End
    End;

  Procedure newmail;
    Begin
      lastread:=0;
      Repeat
        lastread:=lastread+1;
        If lastread>incoming.nummail Then Begin
          WriteLn('No (more) new mail.');
          lastread:=0;
          exit
        End;
        If Not incoming.mail[lastread].read Then Begin
          readincoming(lastread);
          exit
        End
      Until hungupon
    End;

  Procedure deleteincoming;
    Var n:Integer;
    Begin
      If checklastread Then Begin
        n:=getmsgnumber(incoming,'delete');
        If n=0 Then exit;
        lastread:=n
      End;
      deletemail(incoming,lastread);
      lastread:=lastread-1
    End;

  Procedure killoutgoing;
    Var n:Integer;
    Begin
      n:=getmsgnumber(outgoing,'kill');
      If n<>0 Then deletemail(outgoing,n)
    End;

  Procedure autoreply;
    Var n:Integer;
    Begin
      If checklastread Then Begin
        n:=getmsgnumber(incoming,'reply to');
        If n=0 Then exit;
        lastread:=n
      End;
      With incoming.mail[lastread] Do
        sendmailto(sentby,anon);
      readcatalogs
    End;

  Procedure viewoutgoing;
    Var n:Integer;
    Begin
      n:=getmsgnumber(outgoing,'view');
      If n=0 Then exit;
      readit(outgoing.mail[n])
    End;

  Procedure showinfos;
    Var n:Integer;
    Begin
      If checklastread Then Begin
        n:=getmsgnumber(incoming,'delete');
        If n=0 Then exit;
        lastread:=n
      End;
      showinfoforms(incoming.mail[lastread].sentby)
    End;

  Procedure editmailuser;
    Var n:Integer;
      m:mstr;
    Begin
      If checklastread Then Begin
        n:=getmsgnumber(incoming,'edit the sender');
        If n=0 Then exit;
        lastread:=n
      End;
      m:=incoming.mail[lastread].sentby;
      n:=lookupuser(m);
      If n=0 Then Begin
        WriteLn(^B^R'User ',m,' not found!');
        exit
      End;
      edituser(n)
    End;

  Procedure writecurmsg;
    Var b:Boolean;
    Begin
      b:=checklastread;
      Write(^B^M'Current msg: ');
      If lastread=0
      Then WriteLn('None')
      Else With incoming.mail[lastread] Do
        WriteLn('#',lastread,': ',title,' sent by ',sentby)
    End;

  Procedure showannouncement(un:Integer);
    Var u:userrec;
    Begin
      Seek(ufile,un);
      Read(ufile,u);
      If u.emailannounce>-1 Then Begin
        writehdr(u.handle+'''s Announcement');
        printtext(u.emailannounce);
      End
    End;

  Procedure copymsg(Var m:mailrec;un:Integer);
    Var me:message;
      line:Integer;
      b:Boolean;
    Begin
      me.anon:=m.anon;
      me.title:='Was from '+m.sentby;
      reloadtext(m.line,me);
      showannouncement(un);
      writestr('Add a prologue (A to abort)? *');
      If match(Input,'a') Then exit;
      If yes Then b:=reedit(me,True);
      line:=maketext(me);
      addmail(un,line,me);
      readcatalogs
    End;

  Procedure copymail;
    Var n,un,line:Integer;
    Begin
      If checklastread Then Begin
        n:=getmsgnumber(incoming,'copy');
        If n=0 Then exit;
        lastread:=n
      End;
      n:=lastread;
      writestr('User to copy it to:');
      If Length(Input)=0 Then exit;
      un:=lookupuser(Input);
      If un=0 Then exit;
      copymsg(incoming.mail[n],un)
    End;

  Procedure forwardmail;
    Var n,un:Integer;
    Begin
      If checklastread Then Begin
        n:=getmsgnumber(incoming,'forward');
        If n=0 Then exit;
        lastread:=n
      End;
      n:=lastread;
      writestr('User to forward it to:');
      If Length(Input)=0 Then exit;
      un:=lookupuser(Input);
      If un=0 Then exit;
      copymsg(incoming.mail[n],un);
      deletemail(incoming,n)
    End;

  Const groupclassstr:Array[groupclass] Of String[8]=
    ('Public','Private','Personal');

  Procedure opengfile;
    Begin
      Assign(gfile,'groups');
      Reset(gfile);
      If IOResult<>0 Then Begin
        Close(gfile);
        Rewrite(gfile)
      End
    End;

  Procedure seekgfile(n:Integer);
    Begin
      Seek(gfile,n-1)
    End;

  Function ismember(Var g:grouprec;n:Integer):Boolean;
    Var cnt:Integer;
    Begin
      ismember:=True;
      For cnt:=1 To g.nummembers Do
        If g.members[cnt]=n Then exit;
      ismember:=False
    End;

  Function groupaccess(Var g:grouprec):Boolean;
    Begin
      If issysop Then Begin
        groupaccess:=True;
        exit
      End;
      groupaccess:=False;
      Case g.class Of
        publicgroup:groupaccess:=True;
        personalgroup:groupaccess:=g.creator=unum;
        privategroup:groupaccess:=ismember(g,unum)
      End
    End;

  Function lookupgroup(nm:mstr):Integer;
    Var cnt:Integer;
      g:grouprec;
    Begin
      lookupgroup:=0;
      seekgfile(1);
      For cnt:=1 To FileSize(gfile) Do Begin
        Read(gfile,g);
        If groupaccess(g)
        Then If match(g.name,nm)
          Then Begin
            lookupgroup:=cnt;
            exit
          End
      End
    End;

  Procedure listgroups;
    Var g:grouprec;
      cnt:Integer;
    Begin
      writestr(^M'Name                          Class'^M);
      If break Then exit;
      seekgfile(1);
      For cnt:=1 To FileSize(gfile) Do Begin
        Read(gfile,g);
        If groupaccess(g) Then Begin
          tab(g.name,30);
          WriteLn(groupclassstr[g.class]);
          If break Then exit
        End
      End
    End;

  Function getgroupclass:groupclass;
    Var k:Char;
    Begin
      Repeat
        Input[1]:=#0;
        writestr('Group class p(U)blic, p(R)ivate, p(E)rsonal:');
        k:=UpCase(Input[1]);
        If k In ['U','R','E'] Then Begin
          Case k Of
            'U' :getgroupclass:=publicgroup;
            'R' :getgroupclass:=privategroup;
            'E' :getgroupclass:=personalgroup
          End;
          exit
        End
      Until hungupon;
      getgroupclass:=publicgroup
    End;

  Procedure addmember(Var g:grouprec;n:Integer);
    Begin
      If ismember(g,n) Then Begin
        writestr('That person is already a member!');
        exit
      End;
      If g.nummembers=maxgroupsize Then Begin
        writestr('Sorry, group is full!');
        exit
      End;
      g.nummembers:=g.nummembers+1;
      g.members[g.nummembers]:=n
    End;

  Procedure addgroup;
    Var g:grouprec;
      un:Integer;
    Begin
      writestr('Group name:');
      If (Length(Input)=0) Or (Input='?') Then exit;
      g.name:=Input;
      If lookupgroup(g.name)<>0 Then Begin
        writestr(^M'Group already exists!');
        exit
      End;
      g.class:=getgroupclass;
      g.creator:=unum;
      g.nummembers:=0;
      writestr('Include yourself in the group? *');
      If yes Then addmember(g,unum);
      writestr(^M'Enter names of members, CR when done'^M);
      Repeat
        writestr('Member:');
        If Length(Input)>0 Then Begin
          un:=lookupuser(Input);
          If un=0
          Then writestr('User not found!')
          Else addmember(g,un)
        End
      Until hungupon Or (Length(Input)=0) Or (g.nummembers=maxgroupsize);
      Seek(gfile,FileSize(gfile));
      Write(gfile,g);
      writestr(^M'Group created!');
      writelog(13,1,g.name)
    End;

  Function maybecreategroup(nm:mstr):Integer;
    Begin
      writestr('Create group '+nm+'? *');
      If yes Then Begin
        addtochain(nm);
        addgroup;
        maybecreategroup:=lookupgroup(nm)
      End Else maybecreategroup:=0
    End;

  Function getgroupnum:Integer;
    Var groupname:mstr;
      gn:Integer;
      g:grouprec;
    Begin
      getgroupnum:=0;
      groupname:=Copy(Input,2,255);
      Repeat
        If Length(groupname)=0 Then Begin
          writestr(^M'  Group name [?=list]:');
          If Length(Input)=0 Then exit;
          If Input[1]='/' Then Delete(Input,1,1);
          If Length(Input)=0 Then exit;
          groupname:=Input
        End;
        If groupname='?' Then Begin
          listgroups;
          groupname:=''
        End
      Until Length(groupname)>0;
      gn:=lookupgroup(groupname);
      If gn=0 Then Begin
        writestr('Group not found!');
        gn:=maybecreategroup(groupname);
        If gn=0 Then exit
      End;
      seekgfile(gn);
      Read(gfile,g);
      If Not groupaccess(g)
      Then writestr('Sorry, you may not access that group!')
      Else getgroupnum:=gn
    End;

  Procedure sendmail;
    Var g:grouprec;

    Procedure sendit(showeach:Boolean);
      Var un,line,cnt:Integer;
        me:message;

      Procedure addit(n:Integer);
        Begin
          If n<>unum Then Begin
            If showeach Then WriteLn(lookupuname(n));
            addmail(n,line,me)
          End Else deletetext(line)
        End;

      Begin
        If g.nummembers<1 Then exit;
        writehdr('Sending mail to '+g.name);
        line:=editor(me,False,True);
        If line<0 Then exit;
        addit(g.members[1]);
        If g.nummembers=1 Then exit;
        WriteLn(^B^M);
        For cnt:=2 To g.nummembers Do Begin
          un:=g.members[cnt];
          If un<>unum Then Begin
            line:=maketext(me);
            If line<0 Then Begin
              WriteLn(cnt,' of ',g.nummembers,' completed.');
              exit
            End;
            addit(un)
          End
        End;
        readcatalogs
      End;

    Procedure sendtogroup;
      Var gn:Integer;
      Begin
        gn:=getgroupnum;
        If gn=0 Then exit;
        seekgfile(gn);
        Read(gfile,g);
        sendit(True)
      End;

    Procedure sendtousers;
      Var cnt,un:Integer;
      Begin
        g.name:=Input;
        un:=lookupuser(g.name);
        If un=0 Then Begin
          writestr(^M'User not found.');
          exit
        End;
        g.nummembers:=1;
        g.members[1]:=un;
        cnt:=1;
        showannouncement(un);
        Repeat
          writestr('Carbon copy #'+strr(cnt)+' to:');
          If Length(Input)>0 Then Begin
            un:=lookupuser(Input);
            If un=0
            Then writestr(^M'User not found!'^M)
            Else If ismember(g,un)
              Then writestr(^M'User is already receiving a copy!')
              Else Begin
                cnt:=cnt+1;
                g.nummembers:=cnt;
                g.members[cnt]:=un;
                showannouncement(un)
              End
          End
        Until (Length(Input)=0) Or (cnt=maxgroupsize);
        sendit(g.nummembers>1)
      End;

    Begin
      writestr('User to send mail to:');
      If Length(Input)<>0
      Then If Input[1]='/'
        Then sendtogroup
        Else sendtousers
    End;

  Procedure zippymail;
    Var un:Integer;
      me:message;
      l:Integer;
    Begin
      writestr('Send mail to:');
      If Length(Input)=0 Then exit;
      un:=lookupuser(Input);
      If un=0 Then Begin
        writestr('No such user!');
        exit
      End;
      l:=editor(me,False,False);
      If l<0 Then exit;
      me.title:='-----';
      me.anon:=False;
      addmail(un,l,me);
      readcatalogs
    End;

  {overlay}Procedure sysopmail;

    Function sysopreadnum(Var n:Integer):Boolean;
      Var m:mailrec;
        k:Char;
        done:Boolean;

      Procedure showit;
        Begin
          WriteLn(^B^N^M'Number  '^S,n,
          ^M'Sent by '^S,m.sentby,
          ^M'Sent to '^S,lookupuname(m.sentto),
          ^M'Sent on '^S,datestr(m.when),' at ',timestr(m.when),
          ^M'Title:  '^S,m.title,^M);
          printtext(m.line);
        End;

      Procedure changen(m:Integer);
        Var r2:Integer;
        Begin
          r2:=FileSize(mfile)-1;
          If (m<1) Or (m>r2) Then Begin
            writestr('Continue scan at [1-'+strr(r2)+']:');
            m:=valu(Input)
          End;
          If (m>=1) And (m<=r2) Then Begin
            n:=m-1;
            done:=True
          End
        End;

      Var q:Integer;
      Begin
        sysopreadnum:=False;
        Seek(mfile,n);
        Read(mfile,m);
        showit;
        Repeat
          done:=False;
          q:=menu('E-Mail Scan','ESCAN','QSEODNAC_#R');
          If q<0
          Then changen(-q)
          Else Case q Of
            1:sysopreadnum:=True;
            2:sendmail;
            3:edituser(lookupuser(m.sentby));
            4:edituser(m.sentto);
            5:delmail(n);
            6,9:done:=True;
            7:showit;
            8:changen(0);
          End
        Until (q=1) Or done Or hungupon
      End;

    Procedure someoneelse;
      Var t,last:Integer;
      Begin
        writestr(^M'User name to look at:');
        If (Length(Input)=0) Or hungupon Then exit;
        WriteLn;
        t:=lookupuser(Input);
        If t=0 Then Begin
          writestr('No such user!');
          exit
        End;
        writelog(14,1,Input);
        writestr('Looking in mailbox...');
        last:=searchmail(0,t);
        If last=0 Then writestr('No mail.');
        While last<>0 Do Begin
          Seek(mfile,last);
          Read(mfile,m);
          If sysopreadnum(last) Or hungupon Then exit;
          last:=searchmail(last,t)
        End;
        WriteLn(^B^M'No more mail!')
      End;

    Procedure scanall;
      Var r1,r2:Integer;
        u:userrec;
        n:mstr;
      Begin
        r2:=FileSize(mfile)-1;
        writestr('Start scanning at [1-'+strr(r2)+']:');
        If Length(Input)=0 Then r1:=1 Else r1:=valu(Input);
        If (r1<1) Or (r1>r2) Then exit;
        writelog(14,2,'');
        While r1<FileSize(mfile) Do Begin
          Seek(mfile,r1);
          Read(mfile,m);
          If m.sentto<>0 Then
            If sysopreadnum(r1) Then exit;
          r1:=r1+1
        End;
        WriteLn(^B^M'No more mail!')
      End;

    Procedure groupflags;
      Var gn,bn,un,cnt:Integer;
        bname:sstr;
        ac:accesstype;
        g:grouprec;
        u:userrec;
      Begin
        writestr('Grant all group members access to a sub-board'^M);
        gn:=getgroupnum;
        If gn=0 Then exit;
        writestr('  Sub-board access name/number:');
        WriteLn;
        bname:=Input;
        opentempbdfile;
        bn:=searchboard(bname);
        closetempbdfile;
        If bn=-1 Then Begin
          WriteLn('No such board!');
          exit
        End;
        writelog(14,3,bname);
        For cnt:=1 To g.nummembers Do Begin
          un:=g.members[cnt];
          WriteLn(lookupuname(un));
          Seek(ufile,un);
          Read(ufile,u);
          setuseraccflag(u,bn,letin);
          Seek(ufile,un);
          Write(ufile,u)
        End
      End;

    Procedure deleterange;
      Var first,last,num,cnt:Integer;
      Begin
        writehdr('Mass Mail Delete');
        parserange(FileSize(mfile)-1,first,last);
        If first=0 Then exit;
        num:=last-first;
        If num<>1 Then Begin
          WriteLn('Warning! ',num,' pieces of mail will be deleted!');
          writestr('Are you sure? *');
          If Not yes Then exit
        End;
        For cnt:=last Downto first Do Begin
          delmail(cnt);
          Write(cnt,' ');
          If break Then Begin
            writestr(^B^M'Aborted!');
            exit
          End
        End;
        WriteLn
      End;

    Var q:Integer;
    Begin
      Repeat
        q:=menu('Sysop E-Mail','ESYSOP','QLSGD');
        Case q Of
          2:someoneelse;
          3:scanall;
          4:groupflags;
          5:deleterange;
        End
      Until (q=1) Or hungupon;
      readcatalogs
    End;

  {overlay}Procedure announcement;

    Procedure delannouncement;
      Begin
        If urec.emailannounce=-1 Then Begin
          writestr(^M'You don''t HAVE an announcement.');
          exit
        End;
        deletetext(urec.emailannounce);
        urec.emailannounce:=-1;
        writeurec;
        writestr(^M'Deleted.')
      End;

    Procedure createannouncement;
      Var me:message;
      Begin
        If urec.emailannounce>=0 Then deletetext(urec.emailannounce);
        urec.emailannounce:=editor(me,False,False);
        writeurec
      End;

    Var k:Char;
    Begin
      If urec.emailannounce>=0
      Then showannouncement(unum)
      Else writestr('You don''t have an announcement right now.');
      writestr(^M'C)reate/replace, D)elete, or Q)uit:');
      If Length(Input)=0 Then exit;
      k:=UpCase(Input[1]);
      Case k Of
        'D' :delannouncement;
        'C' :createannouncement
      End
    End;

  {overlay}Procedure groupediting;
    Var curgroup:Integer;
      cg:grouprec;

    Procedure selectgroup;
      Var n:Integer;
        g:grouprec;
      Begin
        Delete(Input,1,1);
        Repeat
          If Length(Input)=0 Then writestr('Select group [?=list]:');
          If Length(Input)=0 Then exit;
          If Input='?' Then Begin
            listgroups;
            n:=0;
            Input[0]:=#0
          End Else Begin
            n:=lookupgroup(Input);
            If n=0 Then Begin
              writestr('Group not found!');
              exit
            End
          End
        Until n>0;
        seekgfile(n);
        Read(gfile,g);
        If groupaccess(g) Then Begin
          curgroup:=n;
          cg:=g
        End Else writestr('You can''t access that group.')
      End;

    Function nocurgroup:Boolean;
      Begin
        nocurgroup:=curgroup=0;
        If curgroup=0 Then writestr('No group as been S)elected!')
      End;

    Function notcreator:Boolean;
      Var b:Boolean;
      Begin
        If nocurgroup Then b:=True Else Begin
          b:=(unum<>cg.creator) And (Not issysop);
          If b Then writestr('You aren''t the creator of this group!')
        End;
        notcreator:=b;
      End;

    Procedure writecurgroup;
      Begin
        seekgfile(curgroup);
        Write(gfile,cg)
      End;

    Procedure deletegroup;
      Var cnt:Integer;
        g:grouprec;
      Begin
        If notcreator Then exit;
        writestr('Delete group '+cg.name+': Are you sure? *');
        If Not yes Then exit;
        writelog(13,2,cg.name);
        For cnt:=curgroup To FileSize(gfile)-1 Do Begin
          seekgfile(cnt+1);
          Read(gfile,g);
          seekgfile(cnt);
          Write(gfile,g)
        End;
        Seek(gfile,FileSize(gfile)-1);
        Truncate(gfile);
        curgroup:=0
      End;

    Procedure listmembers;
      Var cnt:Integer;
      Begin
        If nocurgroup Then exit;
        WriteLn('Creator:           '^S,lookupuname(cg.creator));
        WriteLn('Number of members: '^S,cg.nummembers,^M);
        For cnt:=1 To cg.nummembers Do Begin
          If break Then exit;
          WriteLn(cnt:2,'. ',lookupuname(cg.members[cnt]))
        End
      End;

    Procedure readdmember;
      Var n:Integer;
      Begin
        If notcreator Then exit;
        writestr('User to add:');
        If Length(Input)=0 Then exit;
        n:=lookupuser(Input);
        If n=0
        Then writestr('User not found!')
        Else Begin
          addmember(cg,n);
          writecurgroup
        End
      End;

    Procedure removemember;

      Procedure removemembernum(n:Integer);
        Var cnt:Integer;
        Begin
          cg.nummembers:=cg.nummembers-1;
          For cnt:=n To cg.nummembers Do cg.members[cnt]:=cg.members[cnt+1];
          writecurgroup;
          writestr('Member removed.')
        End;

      Var cnt,n:Integer;
      Begin
        If notcreator Then exit;
        Repeat
          writestr('User to remove [?=list]:');
          If Length(Input)=0 Then exit;
          If Input='?' Then Begin
            Input[0]:=#0;
            listmembers
          End
        Until Length(Input)>0;
        n:=lookupuser(Input);
        If n=0 Then Begin
          writestr('User not found!');
          exit
        End;
        For cnt:=1 To cg.nummembers Do If cg.members[cnt]=n Then Begin
          removemembernum(cnt);
          exit
        End;
        writestr('User isn''t in the group!')
      End;

    Procedure setclass;
      Begin
        If notcreator Then exit;
        WriteLn('Current class: '^S,groupclassstr[cg.class],^M);
        cg.class:=getgroupclass;
        writecurgroup
      End;

    Procedure setcreator;
      Var m:mstr;
        n:Integer;
      Begin
        If notcreator Then exit;
        WriteLn('Current creator: '^S,lookupuname(cg.creator),^M);
        writestr('Enter new creator:');
        If Length(Input)=0 Then exit;
        n:=lookupuser(Input);
        If n=0 Then Begin
          writestr('User not found!');
          exit
        End;
        cg.creator:=n;
        writecurgroup;
        If (n<>unum) And (Not issysop) Then curgroup:=0
      End;

    Procedure addbylevel;
      Var n,cnt:Integer;
        u:userrec;
      Begin
        If notcreator Then exit;
        writestr('Let in all people over level:');
        n:=valu(Input);
        If n=0 Then exit;
        Seek(ufile,1);
        For cnt:=1 To numusers Do Begin
          Read(ufile,u);
          If (Length(u.handle)>0) And (u.level>=n) Then Begin
            If cg.nummembers=maxgroupsize Then Begin
              writestr('Sorry, group is full!');
              exit
            End;
            addmember(cg,cnt)
          End
        End
      End;

    Var q:Integer;
    Begin
      curgroup:=0;
      Repeat
        Write(^B^M^M^R'Group selected: '^S);
        If curgroup=0
        Then WriteLn('None')
        Else WriteLn(cg.name);
        q:=menu('Group editing','GROUP','QS*LGDVMRCAE');
        Case q Of
          2,3:selectgroup;
          4:listgroups;
          5:addgroup;
          6:deletegroup;
          7:listmembers;
          8:readdmember;
          9:removemember;
          10:setcreator;
          11:setclass;
          12:addbylevel
        End
      Until hungupon Or (q=1)
    End;

  Procedure read_mail;
    Var a,b:anystr;
      cnt,c,d:Integer;
    Begin
      d:=incoming.nummail;
      lastread:=0;
      If d=0 Then WriteLn('No mail waiting!');
      If d=0 Then exit;
      cnt:=1;
      While ((cnt<d) Or (cnt=d)) And (incoming.nummail>0) Do Begin
        readnum(cnt);
        Writestr(^B'Email Command [A]gain [D]elete [R]eply [F]orward [L]ist [N]ext [N]:');
        If Input='' Then Input:='N';
        a:=UpCase(Input[1]);
        If a='N' Then Begin
          inc(cnt);
        End Else Begin
          If a='R' Then Begin
            autoreply;
            Writestr('Delete this letter? :');
            If yes Then deleteincoming;
          End;
          If a='D' Then deleteincoming;
          If a='F' Then forwardmail;
          If a='L' Then listallmail;
          If a='N' Then inc(Cnt);
        End;

      End;
    End;

  Var q:Integer;
  Begin
    cursection:=emailsysop;
    If ansigraphics In urec.config Then ansicls;
    writehdr('The Email Section');
    opengfile;
    readcatalogs;
    writenummail(incoming,'Emails Waiting');
    {  writenummail (outgoing,'outgoing');    }
    If incoming.nummail>0 Then WriteLn('Use [R] to read your mail!')
    Else WriteLn('Use [S] to send mail!');
    lastread:=0;
    Repeat
      writecurmsg;

      If (urec.emulation=0) And (Ansigraphics In urec.config) Then

        If WhereY>22 Then Begin ansigotoxy(1,24);WriteLn(^M^M);ansigotoxy(1,22);
        End;
      q:=menu('E-Mail','EMAIL','QRSLN_%@DKAV#E@CFHGI@Z');
      If q<0
      Then readnum(abs(q))
      Else Case q Of
        2:Read_Mail;
        3:sendmail;
        4:listallmail;
        5:newmail;
        6:nextmail;
        7:sysopmail;
        8:deleteincoming;
        9:killoutgoing;
        10:announcement;
        11:viewoutgoing;
        13:editmailuser;
        14:copymail;
        15:forwardmail;
        16:help('Email.hlp');
        17:groupediting;
        18:showinfos;
        19:zippymail
      End
    Until hungupon Or (q=1);
    Close(gfile)
  End;

Begin
End.
S           µL>ÄÅ   