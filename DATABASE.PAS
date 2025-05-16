{ Revision History
  881026 - Cleaned up Group / Level access
         - Troglodyte
}
  {$R-,S-,I-,D-,F+,V-,B-,N-,L+,O+ }

  unit database;

  Interface

  uses crt,gentypes,gensubs,subs1,subs2,overret1;

 Procedure datamenu;

   Implementation

Procedure datamenu;
  Var curbase:baserec;
    curbasenum:Integer;

  Procedure packentry(Var p:parsedentry;Var a:anystr);
    Var cnt:Integer;
    Begin
      a:='';
      For cnt:=1 To curbase.numcats Do
        If Length(a)+Length(p[cnt])>254 Then Begin
          WriteLn('Entry to big, truncated.');
          exit
        End Else a:=a+p[cnt]+#1
    End;

  Procedure parseentry(Var oa:anystr;Var p:parsedentry);
    Var d,cnt:Integer;
      a:anystr;
    Begin
      a:=oa;
      For cnt:=1 To curbase.numcats Do Begin
        d:=Pos(#1,a);
        If d=0
        Then p[cnt]:=''
        Else
          Begin
            p[cnt]:=Copy(a,1,d-1);
            a:=Copy(a,d+1,255)
          End
      End
    End;

  Procedure makenewbase;

    Function getnumber(r1,r2:Integer;txt:mstr):Integer;
      Var t:Integer;
      Begin
        Repeat
          writestr(txt+':');
          t:=valu(Input);
          If (t<r1) Or (t>r2) Then
            WriteLn('Sorry, must be from ',r1,' to ',r2,'.')
        Until (t>=r1) And (t<=r2);
        getnumber:=t
      End;

    Var n,cnt:Integer;
      b:baserec;
      p:parsedentry;
    Begin
      n:=FileSize(ddfile)+1;
      writehdr('Create database number '+strr(n));
      writestr('Database name:');
      If Length(Input)=0 Then exit;
      b.basename:=Input;
      Writestr('Access Type [G]roup [L]evel [B]oth [L] :');
      If Input='' Then Input:='L';
      b.Area_Type:=UpCase(Input[1]);
      if not ( b.area_type in [ 'G' , 'B' , 'L' ] ) then exit ;
      if b.area_type in [ 'G' , 'B' ] then
        begin
          Writestr('Group File List [None] :');
          If Input='' Then Input:='None';
          b.File_List:=Input;
        end
      else
        b.file_list := 'None' ;
      if b.area_type in [ 'L' , 'B' ] then
        begin
          writestr('Access level [1] :');
          If Length(Input)=0
          Then b.level:=1
          Else b.level:=valu(Input);
        end
      else
        b.level := maxint ;
      b.numcats:=getnumber(1,maxcats,'Number of categories');
      b.numents:=0;
      For cnt:=1 To b.numcats Do Begin
        writestr('Category #'+strr(cnt)+' name:');
        If Length(Input)=0 Then exit;
        p[cnt]:=Input
      End;
      curbase:=b;
      packentry(p,b.catnames);
      Seek(ddfile,n-1);
      Write(ddfile,b);
      WriteLn('Database created!');
      writelog(7,2,b.basename);
      curbase:=b;
      curbasenum:=n
    End;

  Function Hasaccess(X:baserec):Boolean;
    Var cnt,a:Integer;
      b,d:anystr;
      e:Boolean;

    Begin
      e:=False;
      If (X.area_type in ['L' , 'B'] ) Then
        If ulvl>=x.level Then e:=True;
      If (X.area_type in ['G' , 'B'] ) Then
        If isinlist(x.file_list) Then e:=True;
      hasaccess:=e;

    End;

  Procedure nobases;
    Begin
      Rewrite(ddfile);
      WriteLn('No databases exist!');
      If Not issysop Then exit;
      writestr('Create first database now? *');
      If Not yes Then exit;
      makenewbase
    End;

  Procedure openddfile;
    Begin
      Assign(ddfile,'DataDir');
      Reset(ddfile);
      If IOResult<>0
      Then nobases
      Else Begin
        Reset(ddfile);
        If FileSize(ddfile)=0 Then Begin
          Close(ddfile);
          nobases
        End
      End
    End;

  Procedure writecurbase;
    Begin
      Seek(ddfile,curbasenum-1);
      Write(ddfile,curbase)
    End;

  Procedure readcurbase;
    Begin
      Seek(ddfile,curbasenum-1);
      Read(ddfile,curbase)
    End;

  Procedure openefile;
    Var i:Integer;
    Begin
      readcurbase;
      If isopen(efile) Then Close(efile);
      i:=IOResult;
      Assign(efile,'Database.'+strr(curbasenum));
      Reset(efile);
      If IOResult<>0 Then Rewrite(efile);
      curbase.numents:=FileSize(efile);
      writecurbase
    End;

  Function getparsedentry(Var p:parsedentry):Boolean;
    Var cnt:Integer;
      pr:parsedentry;
      nonblank:Boolean;
    Begin
      nonblank:=False;
      parseentry(curbase.catnames,pr);
      WriteLn('(*=',unam,')');
      For cnt:=1 To curbase.numcats Do Begin
        writestr(pr[cnt]+': &');
        If Length(Input)>0 Then nonblank:=True;
        If Input='*'
        Then p[cnt]:=unam
        Else p[cnt]:=Input
      End;
      getparsedentry:=nonblank
    End;

  Function getentry(Var a:anystr):Boolean;
    Var p:parsedentry;
    Begin
      getentry:=getparsedentry(p);
      packentry(p,a)
    End;

  Const shownumbers:Boolean=False;
  Procedure showparsedentry(Var p:parsedentry);
    Var cnt:Integer;
      pr:parsedentry;
    Begin
      parseentry(curbase.catnames,pr);
      For cnt:=1 To curbase.numcats Do Begin
        If shownumbers Then Write(cnt,'. ');
        WriteLn(pr[cnt],': '^S,p[cnt]);
        If break Then exit
      End;
      shownumbers:=False
    End;

  Procedure showentry(Var a:anystr);
    Var p:parsedentry;
    Begin
      parseentry(a,p);
      showparsedentry(p)
    End;

  Procedure showentrynum(Var a:anystr;num:Integer);
    Begin
      WriteLn(^M,num,':');
      showentry(a)
    End;

  Function noentries:Boolean;
    Begin
      If curbase.numents>0
      Then noentries:=False
      Else
        Begin
          WriteLn('Sorry, database is empty!');
          noentries:=True
        End
    End;

  Procedure changeentryrec(Var e:entryrec);
    Var p:parsedentry;
      c:Integer;
      done:Boolean;
    Begin
      parseentry(e.data,p);
      Repeat
        shownumbers:=True;
        showparsedentry(p);
        writestr(^M'Category number to change [CR to exit]:');
        done:=Length(Input)=0;
        If Not done Then Begin
          c:=valu(Input);
          If (c>0) And (c<=curbase.numcats) Then Begin
            writestr('New value [*=Your name, CR to leave unchanged]: &');
            If Length(Input)<>0 Then
              If Input='*'
              Then p[c]:=unam
              Else p[c]:=Input
          End
        End
      Until done;
      packentry(p,e.data)
    End;

  Procedure adddata;
    Var e:entryrec;
    Begin
      writehdr('Add an entry');
      If Not getentry(e.data) Then Begin
        WriteLn('Blank entry!');
        exit
      End;
      writestr(^M'Make changes (Y/N/X)? *');
      If Length(Input)<>0 Then
        Case UpCase(Input[1]) Of
          'X' :Begin
                 writestr('Entry not added.');
                 exit
               End;
          'Y' :changeentryrec(e)
        End;
      e.when:=now;
      e.addedby:=unum;
      Seek(efile,curbase.numents);
      Write(efile,e);
      curbase.numents:=curbase.numents+1;
      writecurbase
    End;

  Procedure listdata;
    Var cnt,f,l:Integer;
      e:entryrec;
    Begin
      If noentries Then exit;
      WriteLn;
      parserange(curbase.numents,f,l);
      If f=0 Then exit;
      WriteLn;
      For cnt:=f To l Do Begin
        Seek(efile,cnt-1);
        Read(efile,e);
        showentrynum(e.data,cnt);
        If break Then exit
      End
    End;

  Function getdatanum(txt:mstr):Integer;
    Var n:Integer;
    Begin
      getdatanum:=0;
      If noentries Then exit;
      Repeat
        writestr(^M'Entry to '+txt+' [?=list]:');
        If Length(Input)=0 Then exit;
        If Input='?' Then Begin
          listdata;
          Input:=''
        End
      Until Length(Input)>0;
      n:=valu(Input);
      If (n>0) And (n<=curbase.numents) Then getdatanum:=n
    End;

  Function notuseradded(Var e:entryrec):Boolean;
    Var b:Boolean;
    Begin
      b:=Not((e.addedby=unum) Or issysop);
      notuseradded:=b;
      If b Then writestr('You didn''t add this entry!')
    End;

  Procedure changedata;
    Var n:Integer;
      e:entryrec;
    Begin
      n:=getdatanum('change');
      If n=0 Then exit;
      Seek(efile,n-1);
      Read(efile,e);
      If notuseradded(e) Then exit;
      writelog(8,3,Copy(e.data,1,Pos(#1,e.data)-1));
      changeentryrec(e);
      Seek(efile,n-1);
      Write(efile,e);
    End;

  Procedure deletedata;
    Var n,cnt:Integer;
      e:entryrec;
      p:parsedentry;
    Begin
      n:=getdatanum('delete');
      If n=0 Then exit;
      Seek(efile,n-1);
      Read(efile,e);
      If notuseradded(e) Then exit;
      parseentry(e.data,p);
      writelog(8,6,p[1]);
      curbase.numents:=curbase.numents-1;
      writecurbase;
      For cnt:=n To curbase.numents Do Begin
        Seek(efile,cnt);
        Read(efile,e);
        Seek(efile,cnt-1);
        Write(efile,e)
      End;
      Seek(efile,curbase.numents);
      Truncate(efile)
    End;

  Procedure listbases;
    Var cnt:Integer;
      b:baserec;
    Begin
      writehdr('List of Databases');
      If break Then exit;
      For cnt:=1 To FileSize(ddfile) Do Begin
        Seek(ddfile,cnt-1);
        Read(ddfile,b);
        If hasaccess(b) Then WriteLn(cnt,'. ',b.basename);
        If break Then exit
      End
    End;

  Procedure selectdata;
    Var n:Integer;
      b:baserec;
    Begin
      If Length(Input)>1 Then Input:=Copy(Input,2,255) Else
        Repeat
          writestr('Database number [?=list]:');
          If Length(Input)=0 Then exit;
          If Input='?' Then Begin
            listbases;
            Input:=''
          End
        Until Length(Input)>0;
      n:=valu(Input);
      If (n<1) Or (n>FileSize(ddfile)) Then Begin
        WriteLn('No such database: '^S,n);
        If Not issysop Then exit;
        n:=FileSize(ddfile)+1;
        writestr('Create database #'+strr(n)+'? *');
        If yes Then Begin
          writecurbase;
          makenewbase;
          openefile
        End;
        exit
      End;
      Seek(ddfile,n-1);
      Read(ddfile,b);
      If Not hasaccess(b) Then Begin
        reqlevel(b.level);
        exit
      End;
      writecurbase;
      curbasenum:=n;
      openefile
    End;

  Procedure searchdata;
    Var cnt,f,en:Integer;
      e:entryrec;
      Pattern:anystr;
      p:parsedentry;
    Begin
      If noentries Then exit;
      writestr('Search pattern:');
      If Length(Input)=0 Then exit;
      Pattern:=Input;
      For cnt:=1 To Length(Pattern) Do Pattern[cnt]:=UpCase(Pattern[cnt]);
      For en:=1 To curbase.numents Do Begin
        Seek(efile,en-1);
        Read(efile,e);
        parseentry(e.data,p);
        For f:=1 To curbase.numcats Do Begin
          For cnt:=1 To Length(p[f]) Do p[f][cnt]:=UpCase(p[f][cnt]);
          If Pos(Pattern,p[f])<>0 Then showentrynum(e.data,en)
        End
      End;
      WriteLn(^M'Search complete')
    End;

  Const beenaborted:Boolean=False;

  Function aborted:Boolean;
    Begin
      If beenaborted Then Begin
        aborted:=True;
        exit
      End;
      aborted:=xpressed Or hungupon;
      If xpressed Then Begin
        beenaborted:=True;
        WriteLn(^B'Newscan aborted!')
      End
    End;

  Procedure newscan;
    Var first,cnt:Integer;
      nd:Boolean;
      e:entryrec;
    Begin
      beenaborted:=False;
      first:=curbase.numents;
      nd:=True;
      While (first>0) And nd Do Begin
        Seek(efile,first-1);
        Read(efile,e);
        nd:=e.when>laston;
        If nd Then first:=first-1
      End;
      For cnt:=first+1 To curbase.numents Do Begin
        Seek(efile,cnt-1);
        Read(efile,e);
        If aborted Then exit;
        showentrynum(e.data,cnt)
      End
    End;

  Procedure newscanall;
    Begin
      writehdr('New-scanning... Press [X] to abort.');
      curbasenum:=1;
      While curbasenum<=FileSize(ddfile) Do Begin
        If aborted Then exit;
        openefile;
        If hasaccess(curbase) Then Begin
          WriteLn(^B^M'Scanning ',curbase.basename,^M);
          newscan;
          If aborted Then exit
        End;
        curbasenum:=curbasenum+1
      End;
      curbasenum:=1;
      openefile;
      WriteLn(^B'Newscan complete!')
    End;

  Procedure killdatabase;
    Var b:baserec;
      cnt:Integer;
    Begin
      writestr('Kill database:  Are you sure? *');
      If Not yes Then exit;
      writecurbase;
      Close(efile);
      Erase(efile);
      For cnt:=curbasenum To FileSize(ddfile)-1 Do Begin
        Seek(ddfile,cnt);
        Read(ddfile,b);
        Seek(ddfile,cnt-1);
        Write(ddfile,b);
        Assign(efile,'Database.'+strr(cnt+1));
        Rename(efile,'Database.'+strr(cnt))
      End;
      Seek(ddfile,FileSize(ddfile)-1);
      Truncate(ddfile);
      writelog(8,5,'');
      If FileSize(ddfile)>0 Then Begin
        curbasenum:=1;
        openefile
      End
    End;

  Procedure reorderdata;
    Var numd,curd,newd:Integer;
      b1,b2:baserec;
      f1,f2:File;
      fn1,fn2:sstr;
    Label exit;
    Begin
      writecurbase;
      writehdr('Re-order databases');
      writelog(8,1,'');
      numd:=FileSize(ddfile);
      WriteLn('Number of database: ',numd);
      For curd:=0 To numd-2 Do Begin
        Repeat
          writestr('New database #'+strr(curd+1)+' [?=List, CR to quit]:');
          If Length(Input)=0 Then GoTo exit;
          If Input='?'
          Then
            Begin
              listbases;
              newd:=-1
            End
          Else
            Begin
              newd:=valu(Input)-1;
              If (newd<0) Or (newd>=numd) Then Begin
                WriteLn('Not found!  Please re-enter...');
                newd:=-1
              End
            End
        Until (newd>0);
        Seek(ddfile,curd);
        Read(ddfile,b1);
        Seek(ddfile,newd);
        Read(ddfile,b2);
        Seek(ddfile,curd);
        Write(ddfile,b2);
        Seek(ddfile,newd);
        Write(ddfile,b1);
        fn1:='Database.';
        fn2:=fn1+strr(newd+1);
        fn1:=fn1+strr(curd+1);
        Assign(f1,fn1);
        Assign(f2,fn2);
        Rename(f1,'Temp$$$$');
        Rename(f2,fn1);
        Rename(f1,fn2)
      End;
exit: 
      curbasenum:=1;
      openefile
    End;

  Procedure renamedata;
    Begin
      WriteLn('Current name: '^S,curbase.basename);
      writestr('Enter new name:');
      If Length(Input)>0 Then Begin
        curbase.basename:=Input;
        writecurbase;
        writelog(8,2,Input)
      End
    End;

  Procedure setlevel;
    Begin
      Writestr('New Access type :');
      If Not(Input='') Then curbase.area_type:=UpCase(Input[1]);
      if not (curbase.area_type in [ 'G' , 'B' , 'L'] ) then exit ;
      if curbase.area_type in ['G' , 'B' ] then
        begin
          Writeln ( 'Current Group file list '^S , curbase.file_list ) ;
          Writestr('NEW Group file List :');
          If Not(Input='') Then curbase.File_List:=Input;
        end
      else
        curbase.file_list := 'None' ;
      if curbase.area_type in ['L' , 'B' ] then
        begin
          WriteLn('Current level: '^S,curbase.level);
          writestr('Enter new level:');
          If Length(Input)<>0 Then
            curbase.level:=valu(Input);
        end
      else
        curbase.level := maxint ;
      Writestr ( 'Save changes [N,y]:' ) ;
      if length(input) = 0 then exit ;
      if upcase(input[1]) = 'Y' then
        begin
          writecurbase;
          writelog(8,4,strr(curbase.level))
        end ;
    End;

  Procedure sysopcommands;
    Var q:Integer;
    Begin
      writelog(7,1,curbase.basename);
      Repeat
        q:=menu('Database Sysop','DSYSOP','QCDEKOR');
        Case q Of
          2:changedata;
          3:deletedata;
          4:setlevel;
          5:killdatabase;
          6:reorderdata;
          7:renamedata
        End
      Until (q=1) Or hungupon Or (FileSize(ddfile)=0)
    End;

  Var q:Integer;
  Begin
    cursection:=databasesysop;
    openddfile;
    If FileSize(ddfile)=0 Then exit;
    curbasenum:=1;
    Seek(ddfile,0);
    Read(ddfile,curbase);
    If Not hasaccess(curbase) Then Begin
      reqlevel(curbase.level);
      Close(ddfile);
      exit
    End;
    openefile;

    Writehdr('The Database Section');
    Repeat
      WriteLn(^B^M'Current Database:  '^S,curbase.basename);
      WriteLn('# of records: '^S,curbase.numents);

      If (urec.emulation=0) And (Ansigraphics In urec.config) Then

        If WhereY>22 Then Begin ansigotoxy(1,24);WriteLn(^M^M);ansigotoxy(1,22);
        End;

      q:=menu('Database','DATA','QA*SLVNH%@CD');
      Case q Of
        2:adddata;
        3:selectdata;
        4:searchdata;
        5:listdata;
        6:newscan;
        7:newscanall;
        8:help('Database.hlp');
        9:sysopcommands;
        10:changedata;
        11:deletedata
      End
    Until hungupon Or (q=1) Or (FileSize(ddfile)=0);
    Close(ddfile);
    Close(efile)
  End;

Begin
End.
M   ANS           !zBo¼  