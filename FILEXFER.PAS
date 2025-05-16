
  {$R-,S-,I-,D-,F+,V-,B-,N-,L+,O+ }
  unit filexfer;

  Interface

  uses crt,dos,
  subs3,gentypes,configrt,modem,statret,gensubs,subs1,subs2,windows,
  userret,mainr1,mainr2,overret1,protocol,batch,init;

  Procedure udsection;

  Implementation


Procedure udsection;
  Procedure download(autoselect:Integer;FILE_Override:Lstr;Point_Override:integer );Forward;
  Procedure add_to_batch(autoselect:Integer;File_Override:lstr; Point_Override:integer);Forward;

  Var ud:udrec;
    area:arearec;
    curarea:Integer;

    Batchdown:batchlist;
    filesinbatch:Integer;
    BPOS:integer;

type BIREC=record

  CMDSTR:char;
  REFRESH:char;
  REPLACE:char;
  VERIFY:CHAR;
  DELETE:CHAR;
  DELETEABORT:CHAR;
  DIROVERRIDE:char;
  INCLUDEDIRO:char;
  SOURCEPATH:array [1..80] of char;
  Destpath  :array [1..80] of char;
  Description:array [1..80] of char;
end;

type nigger=record
     shit: array [1..298] of char;
     end;

{$I bimodem.inc}

  Function getapath:lstr;
    Var q,r:Integer;
      f:File;
      b:Boolean;
      p:lstr;
    Begin
      getapath:=area.xmodemdir;
      If ulvl<sysoplevel Then exit;
      Repeat
        writestr('Upload path [CR for '+^S+area.xmodemdir+^P+']:');
        If hungupon Then exit;
        If Length(Input)=0 Then Input:=area.xmodemdir;
        p:=Input;
        If Input[Length(p)]<>'\' Then p:=p+'\';
        b:=True;
        Assign(f,p+'CON');
        Reset(f);
        q:=IOResult;
        Close(f);
        r:=IOResult;
        If q<>0 Then Begin
          writestr('  Path doesn''t exist!  Create it? *');
          b:=yes;
          If b Then Begin
            MkDir(Copy(p,1,Length(p)-1));
            q:=IOResult;
            b:=q=0;
            If b
            Then writestr('Directory created')
            Else writestr('Unable to create directory')
          End
        End
      Until b;
      getapath:=p
    End;

  Function makearea:Boolean;
    Var num,n:Integer;
      a:arearec;
    Begin
      makearea:=False;
      num:=numareas+1;
      n:=numareas;
      writestr('Create area '+^S+strr(num)+^P+' [y/N]? *');
      If yes Then Begin
        writestr('Area name:');
        If Length(Input)=0 Then exit;
        a.name:=Input;
         writestr('[G]roup or [L]evel or [B]oth access [L]:');
          If Length(Input)=0 Then Input:='L';
          a.ARea_type:=UpCase(Input[1]);
         if not (a.area_type in [ 'L' ,'B' , 'G' ] ) then
           A.Area_Type := 'L' ;
         if (a.area_type in ['G' , 'B'] )Then
          Begin
        writestr('Group List name name [none]:');
        If Length(Input)=0 Then Input:='None';
        a.File_List:=Input;
          End
         Else
           A.File_List:='None' ;
         if (a.area_type in ['L' , 'B'] )Then
          Begin
            writestr('Access level:');
            If Length(Input)=0 Then exit;
            a.level:=valu(Input);
          End
        Else
          a.level := 0 ;
                writestr('Upload Here? [Y]:');
        if yes then a.uploadhere:='Y' else a.uploadhere:='N';
        writestr('Download here? [Y]:');
        if yes then a.downloadhere:='Y' else a.downloadhere:='N';
        writestr('Entry Password [N=NONE] :');
        if input='N' then input:='';
        If Length(Input)=0 Then Input:='' else input:=upstring(input);
        a.password:=input;

        writestr('CoSysop ['+^V+unam+^W+']:');
        If Length(Input)=0 Then Input:=unam;

        a.sponsor:=Input;
        a.xmodemdir:=getapath;
        seekafile(num);
        Write(afile,a);
        area:=a;
        curarea:=num;
        assignud;
        Rewrite(udfile);
        WriteLn('Area created');
        makearea:=True;
        writelog(15,4,a.name)
      End
    End;

  Function allowed_in_area(where:arearec):Boolean;
    Var c:Boolean;
    Begin
      c:=False;
      If sponsoron Then Begin c:=True;
      End Else Begin

        If (where.area_type in [ 'L' , 'B' ]) Then
          If (where.level<=urec.udlevel) Then
          c:=True;
        If (where.area_type in [ 'G' , 'B' ]) Then
          If (isinlist(where.File_List)) Then c:=True;
      End;

      Allowed_In_Area:=c;

    End;

  Procedure setarea(n:Integer);
    Var c:Boolean;
    Procedure nosucharea;
      Begin
        WriteLn(^B'No such area: ',n,'!')
      End;

    Begin

      curarea:=n;
      If (n>numareas) Or (n<1) Then Begin
        nosucharea;
        If issysop
        Then If makearea
          Then setarea(curarea)
          Else setarea(1)
        Else setarea(1);
        exit
      End;
      seekafile(n);
      Read(afile,area);
      If Not(allowed_in_area(area))
      Then If curarea=1
        Then error('User can''t access first area','','')
        Else
          Begin
            nosucharea;
            setarea(1);
            exit
          End;
      assignud;
      Close(udfile);
      Reset(udfile);
      If IOResult<>0 Then Rewrite(udfile);
        if (Area.Uploadhere='Y') or (Area.Uploadhere='N') then else begin
         area.password:='';area.uploadhere:='Y';
         writeln (usr,'** Adaptive Upgrade 1-23-89');
         area.Downloadhere:='Y';
         seekafile(curarea);
         Write(afile,area);

  end;

  if ulvl>=sysoplevel then else
     if (curarea>1) and (area.password<>'') then begin
        Writestr ('Entry Password:');
        if match (area.password,input)=false then setarea(1);
     end;
      WriteLn(^B^R'Current Area  ['^S,curarea:2,^r'] '^S,area.name,^R);
      urec.wherefile:=curarea;writeurec;
      WriteLn
    End;

  Procedure listareas;
    Var a:arearec;
      cnt:Integer;
    Begin
      writehdr('Area List');
      seekafile(1);
      For cnt:=1 To numareas Do Begin
        Read(afile,a);
        If allowed_in_area(a)
        Then
          WriteLn('['^S,cnt:2,^R'.] ['^S,a.level:3,^R']    '^S,a.name);
        If break Then exit
      End
    End;

  Function getareanum:Integer;
    Var areastr:sstr;
      areanum:Integer;
    Begin
      getareanum:=0;
      If Length(Input)>1
      Then areastr:=Copy(Input,2,255)
      Else
        Repeat
          listareas;
          writestr(^M'Area # [?]:');
          If Input='?' Then listareas Else areastr:=Input
        Until (Input<>'?') Or hungupon;
      If Length(areastr)=0 Then exit;
      areanum:=valu(areastr);
      If (areanum>0) And (areanum<=numareas)
      Then getareanum:=areanum
      Else Begin
        writestr('No such area!');
        If issysop Then If makearea Then getareanum:=numareas
      End
    End;

  Procedure getarea;
    Var areanum:Integer;
    Begin
      areanum:=getareanum;
      If areanum<>0 Then setarea(areanum)
    End;

  Function getfname(path:lstr;name:mstr):lstr;
    Var l:lstr;
    Begin
      l:=path;
      If Length(l)<>0 Then
        If Not(l[Length(l)] In [':','\']) Then
          l:=l+'\';
      l:=l+name;
  getfname:=l
    End;

  Procedure getpathname(fname:lstr;Var path:lstr;Var name:sstr);
    Var
        _Name: NameStr;
        _Ext : ExtStr ;
    Begin
      FSplit(fname,path,_name,_ext);
      name := _name + _ext ;
    End;

 function candownload(Fsz:longint;pts:integer ):boolean;
 Var t1,t2:longint;
     Dl:boolean;
  begin
  dl:=false;
  if issysop then candownload:=true;
  if issysop then exit;
  if baudrate=0 then t1:=(2400*timeleft*6) else  t1:=(baudrate*timeleft*6);
  if (t1>=fsz) or (urec.udpoints>=pts)  then dl:=true;
  candownload:=dl;
  end;




  Procedure listfile(n:Integer;extended:Boolean);
    Var ud:udrec;
      q:sstr;
     path, Filez:anystr; _Name:namestr; _Ext: Extstr;
      Sze:longint;
      ofline:boolean;



    Begin

      seekudfile(n);
      Read(udfile,ud);


        Filez:=getfname(ud.path,ud.filename);
        ofline:=(exist(filez))=false;
        if ofline then write(' ') else if candownload(ud.filesize,ud.points) then write('+') else write(' ');
        FSplit(ud.filename,path,_name,_ext);
        tab(strr(n)+'.',4);

      path:=upcase(_name[1]);
      _name[1]:=path[1];
      tab(_Name,8); Write (upstring(_ext):4,'  ');
      If ud.newfile
      Then Write(' New   ')
      Else If ud.specialfile
        Then Write(' Ask   ')
        Else If ud.points>0
          Then Write(ud.points:4 , '   ')
          Else Write('       ');


     if ofline then tab('[Offline]',10) Else begin
       sze:=ud.filesize; if sze<1024 then
               tab(strlong(sze),10) else
               Write(strlong(sze div 1024)+'k':9,' ');


      end;
      WriteLn(' ',copy(ud.descrip,1,39));
      If break Or (Not extended) Then exit;
      Write('    ');
      tab(datestr(ud.when),19);
      tab(strlong(ud.downloaded),10);
      WriteLn(ud.sentby)
    End;


  Function nofiles:Boolean;
    Begin
      If numuds=0 Then Begin
        nofiles:=True;
        writestr(^M'[No Files exist]')
      End Else nofiles:=False
    End;

  Procedure listfiles(extended:Boolean);
    Var cnt,max,r1,r2:Integer;
    Const extendedstr:Array[false..true] Of String[9]=('','');
    Begin
      If nofiles Then exit;
      writehdr(extendedstr[extended]+'File List');
      max:=numuds;
      thereare(max,'file','files');
      parserange(max,r1,r2);
      If r1=0 Then exit;
      Write(^S);

if not (ansigraphics in urec.config) then begin
      tab('#.',4);
      tab('Filename',14);
      tab('Cost',7);
      tab('Filesize',10);

      WriteLn(' Description'^M^M); end else
begin
Writeln(^B'⁄¬[0;37;40m¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬ø');
Write('[1m√[36;43m¥#');
Write('[37m≥[36m[37m≥[36mFilename     [37m≥[36mCost[37m≥[36m [37m≥[36mFilesize[37m≥[36m    ');
writeln('[37m≥[36mDescription[37m≥[36m'+
'                       √[0;37;40m¥[1m');
Write('¿¡[0;37;40m¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡');
writeln('¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡Ÿ');
end;



      For cnt:=r1 To r2 Do Begin
        listfile(cnt,extended);
        If break Then exit
      End
    End;

  Function searchforfile(f:sstr):Integer;
    Var ud:udrec;
      cnt:Integer;
    Begin
      For cnt:=1 To numuds Do Begin
        seekudfile(cnt);
        Read(udfile,ud);
        If match(ud.filename,f) Then Begin
          searchforfile:=cnt;
          exit
        End
      End;
      searchforfile:=0
    End;

  Function getfilenum(t:mstr):Integer;
    Var n,s:Integer;
    Begin
      getfilenum:=0;
      If Length(Input)>1 Then Input:=Copy(Input,2,255) Else
        Repeat
          writestr(^R'File name/number to '+^S+t+^R' [?=List]:');
          If hungupon Or (Length(Input)=0) Then exit;
          If Input='?' Then Begin
            listfiles(False);
            Input:=''
          End
        Until Input<>'';
      Val(Input,n,s);
      If s<>0 Then Begin
        n:=searchforfile(Input);
        If n=0 Then Begin
          WriteLn(^S'File not found.');
          exit
        End
      End;
      If (n<1) Or (n>numuds)
      Then WriteLn(^P'File number out of range!')
      Else getfilenum:=n
    End;

   Function allowxfer:Boolean;
    Var cnt:baudratetype;
      k:Char;
    Begin
      allowxfer:=False;

      If Not carrier Then Begin
        WriteLn(^S'You may only transfer from remote!');
        exit
      End;
      For cnt:=firstbaud To lastbaud Do
        If baudrate=baudarray[cnt]
        Then If Not(cnt In downloadrates)
          Then Begin
            WriteLn(^S'You may not transfer at '^R,baudrate,^S' baud.');
            exit
          End;

      allowxfer:=True
    End;

  Procedure addfile(ud:udrec);
    Begin
      seekudfile(numuds+1);
      Write(udfile,ud)
    End;

  Procedure getfsize(Var ud:udrec);
    Var df:File Of Byte;
    Begin
      ud.filesize:=-1;
      Assign(df,getfname(ud.path,ud.filename));
      Reset(df);
      If IOResult<>0 Then exit;
      ud.filesize:=FileSize(df);
      Close(df)
    End;

  Function wildcardmatch(w,f:sstr):Boolean;
    Var a,b:sstr;

    Procedure transform(t:sstr;Var q:sstr);
      Var p:Integer;

      Procedure filluntil(k:Char;n:Integer);
        Begin
          While Length(q)<n Do q:=q+k
        End;

      Procedure dopart(mx:Integer);
        Var k:Char;
        Begin
          Repeat
            If p>Length(t)
            Then k:='.'
            Else k:=t[p];
            p:=p+1;
            Case k Of
              '.' :Begin
                     filluntil(' ',mx);
                     exit
                   End;
              '*' :filluntil('?',mx);
            Else If Length(q)<mx Then q:=q+k
            End
          Until 0=1
        End;

      Begin
        p:=1;
        q:='';
        dopart(8);
        dopart(11)
      End;

    Function theymatch:Boolean;
      Var cnt:Integer;
      Begin
        theymatch:=False;
        For cnt:=1 To 11 Do
          If (a[cnt]<>'?') And (b[cnt]<>'?') And
          (UpCase(a[cnt])<>UpCase(b[cnt])) Then exit;
        theymatch:=True
      End;

    Begin
      transform(w,a);
      transform(f,b);
      wildcardmatch:=theymatch
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
        WriteLn(^B'Newscan abort')
      End
    End;

  Procedure listarchive;
    Var n:Integer;
      ud:udrec;
      f:File Of Byte;
      fname:lstr;
      b:Byte;
      sg:Boolean;
      size:longint;

    Function getsize:longint;
      Var x:longint;
        b:Array[1..4] Of Byte Absolute x;
        cnt:Integer;
      Begin
        For cnt:=1 To 4 Do Read(f,b[cnt]);
        getsize:=x
      End;

    Procedure badarchive;
      Begin
        WriteLn(^M^S'That file isn''t an archive!');
        Close(f);
        exit
      End;

    Begin
      If nofiles Then exit;
      n:=getfilenum('list');
      If n=0 Then exit;
      seekudfile(n);
      Read(udfile,ud);
      fname:=getfname(ud.path,ud.filename);
      Assign(f,fname);
      Reset(f);
      iocode:=IOResult;
      If iocode<>0 Then Begin
        fileerror('LISTARCHIVE',fname);
        exit
      End;
      If FileSize(f)<32 Then Begin
        badarchive;
        exit
      End;
      Close(f);
      Assign(f,'Kermie');
      If exist('Kermie') Then Erase(F);
      fname:=upstring(fname);
      if pos ('.ZIP', fname)>0 then zipview(fname);
      if pos ('.PAK',fname)>0 then PakView(fname);
      if pos ('.ARC',fname)>0 then Arcview(fname);


      Writestr (^B^M^P'Press [Return] to continue *');
    End;

  {$I filexf2.inc}
  Procedure newscan;
    Var cnt:Integer;
      u:udrec;
      first:Boolean;
      done:Boolean;
      T:Char;
    Begin
      done:=False;

      Repeat

        first:=False;
        beenaborted:=False;
        For cnt:=1 To FileSize(udfile) Do Begin
          If aborted Then exit;
          seekudfile(cnt);
          Read(udfile,u);

          If (u.whenrated>laston) Or (u.when>laston)
          Then Begin

            If Not first Then Begin
              If (vt52 in urec.config) or (ansigraphics In urec.config) Then ansicls;
              WriteLn(^B'[File Section] ['^S,area.name,^r'] [',curarea,']');
              write(^S);


if not (ansigraphics in urec.config) then begin
      tab('#.',4);
      tab('Filename',14);
      tab('Cost',7);
      tab('Filesize',10);

      WriteLn(' Description'^M^M); end else
begin
Writeln(^B'⁄¬[0;37;40m¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬ø');
Write('[1m√[36;43m¥#');
Write('[37m≥[36m[37m≥[36mFilename     [37m≥[36mCost[37m≥[36m [37m≥[36mFilesize[37m≥[36m    ');
writeln('[37m≥[36mDescription[37m≥[36m'+
'                       √[0;37;40m¥[1m');
Write('¿¡[0;37;40m¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡');
writeln('¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡¡Ÿ');
end;

            first:=True;End;


            listfile(cnt,False);

          End;

        End;

        If first Then Begin
          Writestr(^M'[File Newscan] [A]gain [+]Add to Batch [D]ownload [V]iew [N]ext :');
          If Input='' Then Input:='N';
          t:=UpCase(Input[1]);
          If (t='V') or (t='A') Or (t='D') Or (t='+') Then Begin
            If t='A' Then done:=False;
            If t='+' Then add_to_batch(0,'',0);
            If t='D' Then download(0,'',0);
            if t='Q' then begin
            beenaborteD:=true;
            done:=true;
            end;

            If t='V' Then listarchive;

          End Else done:=True;
        End;
        If Not first Then done:=True;
      Until done;
    End;


  Procedure getstring(t:lstr;Var m);
    Var q:lstr Absolute m;
      mm:lstr;
    Begin
      WriteLn('Old '^S,t,^R': ',q);
      writestr('Enter new '+^S+t+^P+' [CR for no change]:');
      mm:=Input;
      If Length(mm)<>0 Then q:=mm;
      WriteLn
    End;

  Procedure getint(t:lstr;Var i:Integer);
    Var s:sstr;
    Begin
      s:=strr(i);
      getstring(t,s);
      i:=valu(s)
    End;

  Procedure getboo(t:lstr;Var b:Boolean);
    Var s:sstr;
    Begin
      s:=yesno(b);
      getstring(t,s);
      b:=UpCase(s[1])='Y'
    End;

  Procedure removefile(n:Integer);
    Var cnt:Integer;
    Begin
      For cnt:=n To numuds-1 Do Begin
        seekudfile(cnt+1);
        Read(udfile,ud);
        seekudfile(cnt);
        Write(udfile,ud)
      End;
      seekudfile(numuds);
      Truncate(udfile)
    End;

  Procedure displayfile(Var ffinfo:searchrec);
    Var a:Integer;
    Begin
      a:=ffinfo.attr;
      If (a And 8)=8 Then exit;
      tab(ffinfo.name,13);
      If (a And 16)=16
      Then Write('Directory')
      Else Write(ffinfo.size);
      If (a And 1)=1 Then Write(' [read-only]');
      If (a And 2)=2 Then Write(' [hidden]');
      If (a And 4)=4 Then Write(' [system]');
      WriteLn
    End;

  Function defaultdrive:Byte;
    Var r:registers;
    Begin
      r.ah:=$19;
      Intr($21,r);
      defaultdrive:=r.al+1
    End;

  Procedure directory;
    Var r:registers;
      ffinfo:searchrec;
      tpath:anystr;
      b:Byte;
      cnt:Integer;
    Begin
      tpath:=area.xmodemdir;
      If tpath[Length(tpath)]<>'\' Then tpath:=tpath+'\';
      tpath:=tpath+'*.*';
      writestr('Path/wildcard [CR for '+^S+tpath+^P+']:');
      WriteLn(^M);
      If Length(Input)<>0 Then tpath:=Input;
      writelog(16,10,tpath);
      findfirst(Chr(defaultdrive+64)+':\*.*',8,ffinfo);
      If doserror<>0
      Then WriteLn('No volume label'^M)
      Else WriteLn('Volume label: ',ffinfo.name,^M);
      findfirst(tpath,$17,ffinfo);
      If doserror<>0 Then WriteLn('No files found.') Else Begin
        cnt:=0;
        While doserror=0 Do Begin
          cnt:=cnt+1;
          If Not break Then displayfile(ffinfo);
          findnext(ffinfo)
        End;
        WriteLn(^B^M'Total files: ',cnt)
      End;
      Write('Free disk space: ');
      writefreespace(tpath)
    End;



    Procedure download(autoselect:Integer;FILE_Override:Lstr;Point_Override:integer );

    Var totaltime:sstr;
      fsize:longint;
      proto,num,mins:Integer;
      ud:udrec;
      shit:integer;
      joe:longint;
      zmodem,fname:lstr;
      ymodem:Boolean;
      b:Integer;
      f:File;
    Begin

      if (file_override='') and (area.downloadhere<>'Y') then writehdr ('You can not download in this area!');
      if (File_Override='') and (area.downloadhere<>'Y') then exit;

if file_override='' then begin
      If Not allowxfer Then exit;
      If nofiles Then exit;
      If autoselect=0
      Then num:=getfilenum('download')
      Else num:=autoselect;
      If num=0 Then exit;
      WriteLn;
      seekudfile(num);
      Read(udfile,ud);
      end else ud.points:=point_override;

      If (Not sponsoron) And (ud.points>urec.udpoints) Then Begin
        WriteLn(^P'You are too poor! That file requires '^S,ud.points,^P' points.');
        exit
      End;

      If (File_override='') and (ud.newfile) And (Not sponsoron) Then Begin
        WriteLn(^S'New file and must be validated.');
        exit
      End;

      If (File_Override='') and (ud.specialfile) And (Not sponsoron) Then Begin
        WriteLn('Downloading that file requires special permission.');
        exit
      End;
      If tempsysop Then Begin
        ulvl:=regularlevel;
        tempsysop:=False;
        writeurec;
        bottomline
      End;
      ymodem:=False;
      WriteLn(^M^M);
      Writehdr('Emulex Protocols');
      Writeln('   ');
      WriteLn('[X]modem              [1]k Xmodem ');
      WriteLn('[Y]modem (True)       [Z]modem');
      WriteLn('[G] Ymodem-g (MNP)    [O]verthrust Xmodem');
      WriteLn('[2] Overthrust Ymodem [P]cp Zmodem ');
      WriteLn('[R] ZModem Recovery   [S]uper 8k');
      Writeln('[4]K Zmodem           [9]k Xmodem');
      Writeln('[W]xmodem             [J]modem'^M^M);
      writestr('Select a Protocol ['+^V+'Z'+^P+']: *');

      If Input='' Then Input:='z';
      zmodem:=UpCase(Input[1]);
      if zmodem='Q' then exit;
      shit:=0;
      shit:=pos (zmodem,'X1YZGO2PSR49WJ');

      case shit of
      1: proto:=1;
      2: proto:=2;
      3: proto:=3;
      4: proto:=4;
      5: proto:=5;
      6: proto:=6;
      7: proto:=7;
      8: proto:=8;
      9: proto:=9;
     10: proto:=10;
     11: proto:=11;
     12: proto:=12;
     13: proto:=13;
     14: proto:=14;
      end;

   if file_override='' then    fname:=getfname(ud.path,ud.filename)
                       else    fname:=File_override;
      Assign(f,fname);
      Reset(f);
      iocode:=IOResult;
      If iocode<>0 Then
        Begin
          fileerror('DOWNLOAD',fname);
          exit
        End;

      fsize:=FileSize(f);
      Close(f);
      totaltime:=minstr(fsize);
      mins:=valu(Copy(totaltime,1,Pos(':',totaltime)-1));
      If ((mins>timeleft) And (Not sponsoron)) Then Begin
        writestr(^S'Insufficient time for transfer!');
        exit
      End;
      If (mins-5>timetillevent) Then Begin
        writestr(^S'No can do, net-mail is happenin in a few mins.');
        exit
      End;
      If (vt52 in urec.config) or (ansigraphics In urec.config) Then Begin
      ansicls;ansigotoxy(1,4);End;
      bottomline;
      Writehdr('File Download');

      if file_override='' then begin
      WriteLn(^B'Filename:         '^S,ud.filename);
      WriteLn('Uploaded by:      '^S,ud.sentby);
      WriteLn('Times downloaded: '^S,ud.downloaded);
      If ymodem Then fsize:=(fsize+7) Div 8;
      WriteLn('Cost (pts.):      '^S,ud.points);
      joe:=fsize*128;
      WriteLn('Bytes to send :   '^S,strlong(joe));

      WriteLn('Approx. Time :    '^S,totaltime);
      WriteLn('Current Time Left:'^S,timeleft);
      end; {FO}
      WriteLn(^M^M^S'Press [Ctrl-X] many times to abort'^B);
      Delay(1000);

      b:=protocolxfer(True,False,ymodem,proto,fname);
      beepbeep(b);
      If (b=0) Or (b=1) Then Begin
        writelog(15,1,fname);
        urec.downloads:=urec.downloads+1;

        if file_override='' then begin
        ud.downloaded:=ud.downloaded+1;
        seekudfile(num);
        Write(udfile,ud);
        end;

        delay(2000);nosound;
  if file_override='' then else      ud.points:=Point_override;
        If (ud.points>0) Then Begin
          WriteLn(^B'Your File Points --> '^S,urec.udpoints);
          WriteLn(^B'File Xfer Charge --> '^S,ud.points);
          WriteLn(^B^P'                     -----');
if sponsoron then
          Writeln(^B^S'No Charge for Sysop>');
       if not sponsoron then urec.udpoints:=urec.udpoints-ud.points;
          WriteLn(^B'Your new total ----> '^s,urec.udpoints);
        End;
        writeurec;
      End
    End;

  Procedure upload;
    Var ud:udrec;
      ok,crcmode,ymodem:Boolean;
      proto,b:Integer;
      zmodem,fn:lstr;
      start_time : integer ;
    Begin
          if area.uploadhere<>'Y' then writeln (^S'You can not upload to this area!');
      if area.uploadhere<>'Y' then exit;

      If Not allowxfer Then exit;
      If timetillevent<30 Then Begin
        writestr(
        'Uploads are not allowed within 30 minutes of EmuMail!');
        exit
      End;
      ok:=False;
      Write(^P'Current Free Space: ');
      writefreespace(area.xmodemdir);
      WriteLn;
      Repeat
        writestr('Upload filename:');
        If Length(Input)=0 Then exit;
        If Not validfname(Input) Then Begin
          WriteLn(^S'Invalid filename!');
          exit
        End;
        ud.filename:=Input;
        ud.path:=area.xmodemdir;
        fn:=getfname(ud.path,ud.filename);
        If hungupon Then exit;
        If exist(fn)
        Then WriteLn(^S'Filename already exists! Try Again!')
        Else ok:=True
      Until ok;
      ymodem:=False;

      BufLen:=40;
      writestr('Description of file: &');
      ud.descrip:=Input;


      WriteLn(^M^M);
      writehdr('[Protocols Available]');
      WriteLn(^M'[X]modem              [1]k Xmodem ');
      WriteLn('[Y]modem (True)       [Z]modem');
      WriteLn('[G] Ymodem-g (MNP)    [O]verthrust Xmodem');
      WriteLn('[2] Overthrust Ymodem [P]cp Zmodem ');
      WriteLn('[S]uper 8k            [4]k Zmodem [pB4096 sz]');
      writeln('[9]kxmodem            [W]xmodem');
      Writeln('[J]modem '^M^M);
      writestr(^M^M'Select a Protocol ['+^V+'Z'+^P+']: *');
      if input='' then input:='Z';
      zmodem:=UpCase(Input[1]);
      If zmodem='X' Then proto:=1;
      If zmodem='1' Then proto:=2;
      If zmodem='Y' Then proto:=3;
      If zmodem='Z' Then proto:=4;
      If zmodem='G' Then proto:=5;
      If zmodem='O' Then proto:=6;
      If zmodem='2' Then proto:=7;
      If zmodem='P' Then proto:=8;
      If zmodem='S' Then proto:=9;
      if zmodem='4' then proto:=11;
      if zmodem='9' then proto:=12;
      if zmodem='W' then proto:=13;
      if zmodem='J' then proto:=14;

      If (vt52 in urec.config) or (ansigraphics In urec.config) Then ansicls;
      bottomline;
      Writehdr(Ud.filename+' Upload');
      WriteLn(^S'Receive ready.'^R' Press [Ctrl-X] many times to Abort!');
      if vt52 in urec.config then wvt52 (#234+#6) else Delay(2000);
      if vt52 in urec.config then repeat until (transmitbufferused=0) or (hungupon);
      If tempsysop Then Begin
        ulvl:=regularlevel;
        tempsysop:=False;
        writeurec;
        bottomline
      End;
      start_time := timeleft ;
      b:=protocolxfer(False,crcmode,ymodem,proto,fn);
      beepbeep(b);
      If b=0 Then Begin
        settimeleft ( start_time +( ((start_time-timeleft)*Timepercentback) div 100) ) ;
        writelog(15,2,ud.filename);
        ud.sentby:=unam;
        ud.when:=now;
        ud.whenrated:=now;
        ud.points:=0;
        ud.downloaded:=0;
        ud.newfile:=True;
        ud.specialfile:=False;
        ud.downloaded:=0;

          WriteLn('Thanks for the upload');
        getfsize(ud);
        addfile(ud);
        urec.uploads:=urec.uploads+1;
        newuploads:=newuploads+1;
        inc(totalfiles);If totalfiles>32000 Then totalfiles:=0;
      End;
    End;

  Procedure clear_batchdown;
    Var cnt:Integer;
    Begin
      filesinbatch:=0;

      For cnt:=1 To 25 Do Begin
        batchdown[cnt].filename:='';
        batchdown[cnt].path:='';
        batchdown[cnt].points:=0;
        batchdown[cnt].mins:=0;
        batchdown[cnt].WHOLEFILENAME:='';
      End;
    End;

  Function batchtotaltime:longint;
    Var cnt:Integer;
      Time:Integer;
    Begin
      time:=0;
      If filesinbatch>0 Then Begin
        For cnt:=1 To filesinbatch Do Begin
          time:=time+batchdown[cnt].mins;
        End;
        batchtotaltime:=time;
      End Else batchtotaltime:=0;
    End;

  Function totalpoints:longint;
    Var cnt:Integer;
      points:Integer;
    Begin
      points:=0;
      If filesinbatch>0 Then Begin
        For cnt:=1 To filesinbatch Do Begin
          points:=points+batchdown[cnt].points;
        End;
        totalpoints:=points;
      End Else totalpoints:=0;
    End;

  Procedure listbatch;
    Var cnt,a,b:Integer;
      Z:sstr;
      Justy:Integer;
    Begin
      If filesinbatch<1 Then WriteLn(^S'Stupid! no files in batch!');
      If filesinbatch<1 Then exit;
      Writehdr('Batch Xfer List');
      WriteLn(^M);

      tab('Filename',20);WriteLn('Points # of mins.');
    Writeln('______________________________________');
      For cnt:=1 To filesinbatch Do Begin
        z:=batchdown[cnt].filename;tab(z,24);
        b:=batchdown[cnt].points;tab(strr(b),10);
        b:=batchdown[cnt].mins;WriteLn(strr(b));
      End;
      justy:=totalpoints;
  WriteLn(^M^B'Accumulated File points --> '^S,justy);
      Justy:=batchtotaltime;
      WriteLn('Accumulated Mins for Xfer > '^S,justy);
     End;

    Procedure add_to_batch(autoselect:Integer;File_Override:lstr; Point_Override:integer);

    Var totaltime:sstr;
      proto,num,fsize,mins:Integer;
      ud:udrec;
      zmodem,fname:lstr;
      ymodem:Boolean;
      Too,Too1:mstr;
      b:Integer;
      f:File;
    Begin
    if filesinbatch>25 then writeln ('* Too Many files in batch, Dom!');
    if filesinbatch>25 then exit;
    if file_override='' then begin

    if area.downloadhere<>'Y' then exit;
      If nofiles Then exit;
      If autoselect=0
      Then num:=getfilenum('add to batch')
      Else num:=autoselect;
      If num=0 Then exit;
      WriteLn;
      seekudfile(num);
      Read(udfile,ud);
      end else ud.points:=point_override;

      If (Not sponsoron) And (((Totalpoints)+(ud.points))>urec.udpoints) Then Begin
        WriteLn(^S'You do not have sufficient points to add this file!');
        exit
      End;

      If (File_override='') and (ud.newfile) And (Not sponsoron) Then Begin
        WriteLn(^S'New file and must be validated.');
        exit
      End;
      If (File_Override='') and (ud.specialfile) And (Not sponsoron) Then Begin
        WriteLn(^S'Downloading that file requires special permission.');
        exit
      End;
      If tempsysop Then Begin
        ulvl:=regularlevel;
        tempsysop:=False;
        writeurec;
        bottomline
      End;
if file_override='' then   fname:=getfname(ud.path,ud.filename) else
                           fname:=file_override;
      Assign(f,fname);
      Reset(f);
      iocode:=IOResult;
      If iocode<>0 Then
        Begin
          fileerror('DOWNLOAD',fname);
          exit
        End;
      fsize:=FileSize(f);
      Close(f);
      totaltime:=minstr(fsize);
      mins:=valu(Copy(totaltime,1,Pos(':',totaltime)-1));
      If (((mins+batchtotaltime)>timeleft) And (Not sponsoron)) Then Begin
        writestr(^S'Insufficient time to add this file to batch!');
        exit
      End;
      If (mins-5>timetillevent) Then Begin
        writestr(^S'Sorry, net-mail is happening in a few minutes.');
        exit
      End;
      b:=filesinbatch;
      inc(b);filesinbatch:=b;
      batchdown[b].wholefilename:=fname;
      batchdown[b].mins:=mins;
      batchdown[b].points:=ud.points;

      fsplit (fname,ud.path,too,too1);
      ud.filename:=too+too1;
      batchdown[b].filename:=ud.filename;
      batchdown[b].path:=ud.path;
      Appendbimodem ('U',fname,' ');


      WriteLn(^B^P'This file has been added to your Batch-list!');
      listbatch;
    End;

      Procedure BIMODEMupload;
    Var ud:udrec;
      ok,crcmode,ymodem:Boolean;
      proto,b:Integer;
      YF,zmodem,fn:lstr;
      start_time : integer ;
    Begin

      ok:=False;
     writehdr ('ADD BIMODEM UPLOAD');
      WriteLn;
      writeln ('You Must specify the file your going to upload');
      writeln ('including the drive/direct on Your computer.');
      writeln ('Then specify the filename <no dirs> you want the bbs to name it.'^M);
      Repeat
        writestr('Full Filename on YOUR computer:');
        If Length(Input)=0 Then exit;
         yf:=input;
        Writestr('Filename for the bbs:');
        if length(input)=0 then exit;
        If Not validfname(Input) Then Begin
          WriteLn(^S'Invalid filename!');
          exit
        End;
        ud.filename:=Input;
        ud.path:=area.xmodemdir;
        fn:=getfname(ud.path,ud.filename);
        If hungupon Then exit;
        If exist(fn)
        Then WriteLn(^S'Filename already exists! Try Again!')
        Else ok:=True
      Until ok;

      APPENDBIMODEM ('D',yf,fn);
      Writeln (^S'File added!');
    end;

  Procedure Do_batch_download;
    Var zmodem:Char;
      proto:Integer;
      b:Integer;

    Begin
    if filesinbatch<1 then exit;
      If (vt52 in urec.config) or (ansigraphics In urec.config) Then ansicls;
      WriteLn(^M^M);
      Writehdr('Batch Protocols');
      WriteLn('[Y]modem-Batch        [Z]modem');
      WriteLn('[G] Ymodem-G          [P]cp Zmodem   ');
      WRiteln('[S]uper 8k            [4]k Zmodem [pB4096 rz]'^M^M);

      writestr(^M'Select a Protocol ['+^V+'Z'+^P'] : *');
      If Input='' Then Input:='Z';
      zmodem:=UpCase(Input[1]);
      if zmodem='Q' then exit;
      If zmodem='Y' Then proto:=1;
      If zmodem='Z' Then proto:=2;
      If zmodem='G' Then proto:=3;
      If zmodem='P' Then proto:=4;
      if zmodem='S' then proto:=5;
      if zmodem='4' then proto:=6;
      ansicls;
      WriteLn(^P'Proceed to receive now!');
      if vt52 in urec.config then Wvt52 (#234+#234+#5) else Delay(2000);
      if vt52 in urec.config then repeat until (hungupon) or (transmitbufferused=0) or keypressed;

      b:=0;

      B:=Batch_Download(Proto,filesinbatch,Batchdown);
      If b>0 Then Begin

        urec.downloads:=urec.downloads+1;
        If (b>0) And (Not sponsoron) Then Begin
          WriteLn(^B'Your File Points --> '^S,urec.udpoints);
          WriteLn(^B'Batch Xfer Total --> '^S,b);
          WriteLn(^B^P'                     -----');
          urec.udpoints:=urec.udpoints-b;
          WriteLn(^B'Your new total ----> '^s,urec.udpoints);
        End;
        writeurec;
      End

    End;

procedure DOBIXFER;
    var a:text;
    Such:integer;
    b:anystr;
    BIdir,BBsdir:lstr;

Procedure process_uploads;

var BISEX:file of birec;
    HOMO,FAG:birec;
    krad,cnt:integer;
    zmodem:lstr;
    ud:udrec;
    
begin
if not exist('sam.pth') then begin Writeln (overlaypath+'sam.pth is missing!');exit;

                             end;
writehdr ('Checking your uploads');
assign (bisex,'sam.pth');
reset(bisex);

for cnt:=1 to filesize(bisex) do begin
seek (bisex,cnt-1);
read(bisex,homo);

if ( (homo.cmdstr='R') or (homo.cmdstr='D') ) and (exist(homo.destpath)) then begin
        Zmodem:=homo.destpath;
        getpathname(Zmodem,ud.path,ud.filename);
        If Not hungupon Then Begin
          BufLen:=40;
          Writestr(^B^P'Description for '^S+Ud.filename+^P' :');
          If Input='' Then Input:=^S+'[No Description!]';
          ud.descrip:=Input;
        End Else ud.descrip:=^S+'[No Description!]';

        writelog(15,2,ud.filename);
        ud.sentby:=unam;
        ud.when:=now;
        ud.whenrated:=now;
        ud.points:=0;
        ud.downloaded:=0;
        ud.newfile:=True;
        ud.specialfile:=False;
        ud.downloaded:=0;
        getfsize(ud);
        addfile(ud);
        Inc(urec.uploads);
        inc(newuploads);
        Inc(totalfiles);
      End; { add }


end;
close(bisex);
end;{procedure}

    begin
    Writehdr('Executing BiModem');
    assign (a,'bimodem.log');
    if exist('bimodem.log') then erase(A);
    bidir:=bimodemdir;
    bidir[(length(bidir))]:=' ';
    chdir (bidir);
    Writeln (Usr,'* Changing to Bimodem dir: ',bimodemdir);
    execute ('bimodem.com','');
    Writeln (Usr,'* Change to Emulex Dir   : ',overlaypath);
    BBSDIR:=overlaypath;
    bbsdir [(length(bbsdir))]:=' ';
    chdir (bbsdir);
    delay(2000);
    Writestr ('Press [Return] to Continue :');
    if filesinbatch>0 then begin
      such:=BIcharge(filesinbatch,Batchdown);

      If such>0 Then Begin
        urec.downloads:=urec.downloads+1;
        If (such>0) And (Not sponsoron) Then Begin
          WriteLn(^B'Your File Points --> '^S,urec.udpoints);
          WriteLn(^B'Batch Xfer Total --> '^S,such);
          WriteLn(^B^P'                     -----');
          urec.udpoints:=urec.udpoints-such;
          WriteLn(^B'Your new total ----> '^s,urec.udpoints);
        End;
        writeurec;

      end;
    end;
    Process_Uploads;
    killbimodem;clear_batchdown;
    Writeln (^b'Thank you for using Bimodem!');
    end;

  Procedure Batch_upload;
    Var ud:udrec;
      ok,crcmode,ymodem:Boolean;
      cnt,proto,b:Integer;
      zmodem,fn:lstr;
      BITCH:batchlist;
      start_time : integer ;
    Begin
      If timetillevent<30 Then Begin
        writestr(
        'Uploads are not allowed within 30 minutes of EmuMail!');
        exit
      End;
      ok:=False;
      Write(^P'Make sure there is enough Disk Space!: ');
      writefreespace(area.xmodemdir);
      WriteLn;
      ymodem:=False;
      WriteLn(^M^M);
      writehdr('Batch Protocols');
      WriteLn('[Y]modem (True)       [Z]modem');
      WriteLn('[G] Ymodem-G          [P]cp Zmodem');
      Writeln('[S]uper 8k            [Q]uit'^M);
      Writeln('Use "X" from the batch menu for Bimodem'^M^M);

      writestr(^B'Select a Protocol ['+^V+'Z'+^W']: *');
      If Input = '' Then Input := 'Z' ;
      zmodem:=UpCase(Input[1]);

      if zmodem='Q' then exit;
      If zmodem='Y' Then proto:=1;
      If zmodem='Z' Then proto:=2;
      If zmodem='G' Then proto:=3;
      If zmodem='P' Then proto:=4;
      if zmodem='S' then proto:=5;


      WriteLn(^S'Batch Receive ready. Press [Ctrl-X] many times to Abort!');
      If tempsysop Then Begin
        ulvl:=regularlevel;
        tempsysop:=False;
        writeurec;
        bottomline
      End;
      clear_batchdown;

      cnt:=0;
      start_time := timeleft ;

      B:=BatchUpload(Proto);
      delay(2000);Writestr(^B'Press [Return] to continue:');
      WriteLn(^B^M'Total Files received -> ',filesinbatch);
      If filesinbatch=0 Then exit;
      settimeleft ( start_time + (((start_time-timeleft)*timepercentback) div 100)) ;
      For cnt:=1 To filesinbatch Do Begin
        Zmodem:=batchdown[cnt].wholefilename;
        getpathname(Zmodem,ud.path,ud.filename);
        If Not hungupon Then Begin
          BufLen:=40;
          Writestr(^B'Description for '^S+Ud.filename+^P' :');
          If Input='' Then Input:='[No Description!]';
          ud.descrip:=Input;
        End Else ud.descrip:='[No Description!]';

        writelog(15,2,ud.filename);
        ud.sentby:=unam;
        ud.when:=now;
        ud.whenrated:=now;
        ud.points:=0;
        ud.downloaded:=0;
        ud.newfile:=True;
        ud.specialfile:=False;
        ud.downloaded:=0;
        getfsize(ud);
        addfile(ud);
        Inc(urec.uploads);
        inc(newuploads);
        Inc(totalfiles);
      End;

      WriteLn(^B^M'Thank you for Batch Uploading!');

    End;


  Procedure searchfile;
    Var cnt:Integer;
      searchall:Boolean;
      wildcard:sstr;
      a:arearec;

    Procedure searcharea;
      Var cnt:Integer;
        u:udrec;
        krad1,krad2,krad3:anystr;
      Begin
        For cnt:=1 To numuds Do Begin
          seekudfile(cnt);
          Read(udfile,u);
          krad1:=upstring(wildcard);
          Krad2:=upstring(U.filename);
          krad3:=upstring(u.descrip);
          If ((Pos(krad1,krad2)>0) Or (Pos(krad1,krad3)>0)) Then listfile(cnt,False);
          If xpressed Then exit
        End
      End;

    Begin
     Writehdr('File Search');
      writestr('Search all areas [y/N]? *');
      searchall:=yes;
      Writeln ('Wildcards are not Necessary.');
      writestr('String to search for :');
      If Length(Input)=0 Then exit;
      wildcard:=Input;
      If Not searchall Then Begin
        searcharea;
        exit
      End;
      For cnt:=1 To numareas Do Begin
        seekafile(cnt);
        Read(afile,a);
        If allowed_in_Area(a) Then
          Begin
            setarea(cnt);
            searcharea;
            If xpressed Then exit
          End
      End
    End;

  Procedure yourudstatus;
    Begin
      clearbreak;dontstop:=True;nobreak:=True;
      If (vt52 in urec.config) or (ansigraphics In urec.config) Then Begin
        ansiwindow(30,4,55,11);ansigotoxy(33,4);Write(^R'[File Section]');
        ansigotoxy(32,6);
        Write(^R'Access level:    '^S,urec.udlevel);
        ansigotoxy(32,7);
        Write(^R'Transfer points: '^S,urec.udpoints);
        ansigotoxy(32,8);
        Write(^R'# of Uploads:    '^S,urec.uploads);
        ansigotoxy(32,9);
        Write(^R'# of Downloads:  '^S,urec.downloads);
        ansigotoxy(1,19);
      End Else Begin
        WriteLn(^B^M'Access level:    ',urec.udlevel,
        ^M'Transfer points: ',urec.udpoints,
        ^M'Uploads:         ',urec.uploads,
        ^M'Downloads:       ',urec.downloads);
      End;

    End;

  Procedure newscanall;
    Var cnt:Integer;
      a:arearec;
      start_area : integer ;
    Begin
      WriteLn(^R'[File Newscan]'^S'   Press [Ctrl-X] to abort.');
      beenaborted:=False;
      If aborted Then exit;
      start_area := curarea ;
      For cnt:=1 To FileSize(afile) Do Begin
        seekafile(cnt);
        Read(afile,a);
        If Allowed_in_Area(a) Then Begin
             If aborted Then begin
             setarea(start_area);
             exit;
             end ;
          setarea(cnt);
          If aborted Then begin
             setarea(start_area);
             exit;
             end ;
          newscan   ;
                    If aborted Then begin
             setarea(start_area);
             exit;
             end ;

        End;
        If aborted Then exit
      End ;
      setarea(start_area);
    End;

  Procedure addresidentfile(fname:lstr);
    Var ud:udrec;
    Two,Times:lstr;
    Begin
      getpathname(fname,ud.path,ud.filename);
      Two:=upstring(ud.path);
      Times:='EMULEX';
      if (match('USERS',ud.filename) ) or (match('USERS.',ud.filename)) then exit;
      if (ulvl<sysoplevel) and (pos(times,two)>0) and online then writeln ('Sorry Cannot add EMULEX related Dirs ON-LINE!');
      if (ulvl<sysoplevel) and (pos(times,two)>0) and online then exit;

      getfsize(ud);
      If ud.filesize=-1 Then Begin
        WriteLn('File can''t be opened!');
        Writestr('Add as [OFFLINE] [y/N] ? :');
        If yes Then Else exit
      End;
      writestr('Point value:');
      If Length(Input)=0 Then Input:='0';
      ud.points:=valu(Input);
      writestr('Sent by [CR='+^S+unam+^P+']:');
      If Length(Input)=0 Then Input:=unam;
      ud.sentby:=Input;
      ud.when:=now;
      ud.whenrated:=now;
      ud.downloaded:=0;
      writestr('Description: &');
      ud.descrip:=Input;
      writestr('Special request only? *');
      ud.specialfile:=yes;
      ud.newfile:=False;
      addfile(ud);
      writelog(16,8,fname)
    End;

  Procedure sysopadd;
    Var fn:lstr;
        path,name:lstr;
    Begin
      If ulvl<sysoplevel Then Begin
        WriteLn
        ('Only sysops can add files online!');
        exit
      End;
      writehdr('Add File');
      writestr('Name+path of file ['+^S+area.xmodemdir+^P+']:');
      getpathname(Input,path,name);
      if path = '' then
        fn := area.xmodemdir + name
      else
        fn := path + name ;

      If exist(fn) Then Begin
        writestr('Confirm: '+^S+fn+^P+' [y/N]:');
        If yes Then addresidentfile(fn)
        End
      Else Begin
        WriteLn('Disk File can''t be opened!');
        Writestr('Still Add File [y/N] ? :');
        If yes Then addresidentfile(fn);
        End
    End;

  Procedure addmultiplefiles;
    Var spath,pathpart:lstr;
      dummy:sstr;
      f:File;
      ffinfo:searchrec;
    Begin
      If ulvl<sysoplevel Then Begin
        WriteLn('Only True SYSOPS can add files,manerd!');
        exit
      End;
      writehdr('Add Multiple Files By Wildcard');
      writestr('Search path/wildcard:');
      If Length(Input)=0 Then exit;
      spath:=Input;

      If spath[Length(spath)]='\' Then dec(spath[0]);
      Assign(f,spath+'\con');
      Reset(f);
      If IOResult=0 Then Begin
        Close(f);
        spath:=spath+'\*.*'
      End;
      getpathname(spath,pathpart,dummy);
      findfirst(spath,$17,ffinfo);
      If doserror<>0
      Then WriteLn('No files found!')
      Else
        While doserror=0 Do Begin
          WriteLn;
          displayfile(ffinfo);
          writestr('Add file [Y/n/x]? *');
          If yes
          Then addresidentfile(getfname(pathpart,ffinfo.name))
          Else If (Length(Input)>0) And (UpCase(Input[1])='X')
            Then exit;
          findnext(ffinfo)
        End
    End;

  Procedure changef;
    Var n,q:Integer;
      ud:udrec;

    Procedure showudrec(Var ud:udrec);
      Begin
        With ud Do
          WriteLn(^M^J'[Filename   ]: '^S,ud.filename,
          ^M^J'[subdir Path]: '^S,ud.path,
          ^M^J'[Bytes long ]: '^S,ud.filesize,
          ^M^J'[point Value]: '^S,ud.points,
          ^M^J'[Description]: '^S,ud.descrip,
          ^M^J'[times dload]: '^S,ud.downloaded,
          ^M^J'[New rating ]: '^S,yesno(ud.newfile),
          ^M^J'[Special ask]: '^S,yesno(ud.specialfile),
          ^M^J'[Uploaded by]: '^S,sentby,
          ^M^J'[date recvd ]: '^S,datestr(when),
          ^M^J'[time recvd ]: '^S,timestr(when),^M^J);
      End;

    Begin
      n:=getfilenum('Change');
      If n=0 Then exit;
      seekudfile(n);
      Read(udfile,ud);
      writelog(16,4,ud.filename);
      showudrec(ud);
      Repeat
        q:=menu('File change','FCHANGE','QUDSNFPVB');
        Case q Of
          2:getstring('uploader',ud.sentby);
          3:Begin
              nochain:=True;
              getstring('description',ud.descrip)
            End;
          4:getboo('special request only',ud.specialfile);
          5:getboo('new file (unrated)',ud.newfile);
          6:if Ulvl>=sysoplevel then getstring('filename',ud.filename);
          7:if Ulvl>=sysoplevel then getstring('path',ud.path);
          8:getint('point value',ud.points);
          9:Begin
              Writestr('Change File to [OFFLINE] (y/N)? :');
              If yes Then Begin
                ud.filesize:=-1;
                end
              else
                getfsize(ud);
                If ud.filesize=-1 Then writestr('Notice! This file is [OFFLINE]');
            End;
        End
      Until (q=1);
      seekudfile(n);
      Write(udfile,ud)
    End;

  Procedure deletef;
    Var n,cnt:Integer;
      fn:lstr;
      ud:udrec;
      f:File;
    Begin
      n:=getfilenum('delete');
      If n=0 Then exit;
      seekudfile(n);
      Read(udfile,ud);
      fn:=getfname(ud.path,ud.filename);
      writelog(16,7,fn);
      writestr('Confirm: File '+^S+fn+^P+' ('+^V+ud.descrip+^W+') ? *');
      If Not yes Then exit;
      removefile(n);
      writestr('Erase disk file '+^S+fn+^P+'? *');
      If Not yes Then exit;
      Assign(f,fn);
      Erase(f)
    End;

  Procedure killarea;
    Var a:arearec;
      cnt,n:Integer;
      oldname,newname:sstr;
    Begin
      writestr('Delete area #'+^S+strr(curarea)+^P+' ('+^V+area.name+^W+')? *');
      If Not yes Then exit;
      writelog(16,2,'');
      Close(udfile);
      oldname:='Area'+strr(curarea);
      Assign(udfile,oldname);
      Erase(udfile);
      For cnt:=curarea To numareas-1 Do Begin
        newname:=oldname;
        oldname:='Area'+strr(cnt+1);
        Assign(udfile,oldname);
        Rename(udfile,newname);
        n:=IOResult;
        seekafile(cnt+1);
        Read(afile,a);
        seekafile(cnt);
        Write(afile,a)
      End;
      seekafile(numareas);
      Truncate(afile);
      setarea(1)
    End;

  Procedure modarea;
    Var a:arearec;
      Tmp:sstr;
    Begin
      a:=area;
      getstring('area name',a.name);
      writelog(16,3,a.name);
      getstring('sponsor',a.sponsor);
      tmp:=a.uploadhere;getstring('upload here',tmp);
      a.uploadhere:=upcase(tmp[1]);
      tmp:=a.downloadhere;getstring('d/load here',tmp);
      a.downloadhere:=upcase(tmp[1]);

      Getstring ('Password [N=NONE]',a.password);

                  if a.password='N' then a.password:='';
      getstring('Group File List',a.file_list);
      tmp:=a.area_type;getstring('Level Type [L,G,B]',tmp);
      a.area_type:=UpCase(tmp[1]);
      if not (a.area_type in [ 'G' , 'L' , 'B' ] ) then exit ;
      if a.area_type in [ 'L' , 'B' ] then
        getint('access level',a.level)
      else
        a.level := maxint ;
      writelog(16,11,strr(a.level));
      writelog(16,12,a.sponsor);
      If issysop Then Begin
        a.xmodemdir:=getapath;
        writelog(16,13,a.xmodemdir)
      End;
      seekafile(curarea);
      Write(afile,a);
      area:=a
    End;

  Procedure sortarea;
    Var temp,Mark,cnt:Integer;
      u1,u2:udrec;
    Begin
      writehdr('Sort Area');
      writestr('Confirm [y/N]:');
      If Not yes Then exit;
      writelog(16,6,'');
      Mark:=numuds-1;
      Repeat
        If Mark<>0 Then Begin
          temp:=Mark;
          Mark:=0;
          For cnt:=1 To temp Do Begin
            seekudfile(cnt);
            Read(udfile,u1);
            Read(udfile,u2);
            If upstring(u1.filename)>upstring(u2.filename) Then Begin
              Mark:=cnt;
              seekudfile(cnt);
              Write(udfile,u2);
              Write(udfile,u1)
            End
          End
        End
      Until Mark=0
    End;

  Procedure movefile;
    Var an,fn,oldn:Integer;
        newfilesam,sambam,filesam,wangbang:anystr;
        darn:File;
      ud:udrec;
    Begin
      oldn:=curarea;
      fn:=getfilenum('move');
      If fn=0 Then exit;
       Input:='';
      an:=getareanum;
     If an=0 Then exit;
      WriteLn('Moving...');
     seekudfile(fn);
     Read(udfile,ud);
      writelog(16,5,ud.filename);
     removefile(fn);
     filesam:=GetFName(ud.Path,ud.FileName);
     sambam:=ud.Path;
     setarea(an);
     Write('Current Free Space: ');
     writefreespace(area.xmodemdir);
     writestr('Physically move the file to correct area? *') ;
     If (sambam<>area.xmodemdir) Then If yes Then Begin
       ud.Path:=area.xmodemdir;
       newfilesam:=GetFName(ud.Path,ud.FileName);
       exec(getenv('comspec'),'/c Copy '+filesam+' '+newfilesam+' > nul' );
       wangbang:=filesam;
       Assign(darn,wangbang);
       If exist(newfilesam) Then Erase(darn) Else Begin
         ud.Path:=sambam;
         WriteLn('Uh oh... Bad error!');
       End;
     End;
      addfile(ud);
      setarea(oldn);
      WriteLn(^B'Done.')
    End;

  Procedure renamefile;
    Var fn:Integer;
      ud:udrec;
      f:File;
    Begin
      fn:=getfilenum('rename');
      If fn=0 Then exit;
      seekudfile(fn);
      Read(udfile,ud);
      writestr('Enter new filename:');
      If match(Input,ud.filename)
      Then
        ud.filename:=Input
      Else If Length(Input)>0
        Then If validfname(Input)
          Then If exist(getfname(ud.path,Input))
            Then
              WriteLn('Name already in use!')
            Else
              Begin
                Assign(f,getfname(ud.path,ud.filename));
                Rename(f,getfname(ud.path,Input));
                If IOResult=0 Then Begin
                  ud.filename:=Input;
                  WriteLn(^B^M'File renamed.')
                End Else WriteLn(^B^M'Unable to rename file!')
              End
          Else WriteLn('Invalid filename!');
      seekudfile(fn);
      Write(udfile,ud)
    End;

  Procedure listxmodem;
    Var cnt:Integer;
      u:userrec;
    Begin
      Seek(ufile,1);
      WriteLn('Name                          Lvl Pts'^M);
      For cnt:=1 To numusers Do Begin
        Read(ufile,u);
        If u.handle<>'' Then
          If u.udlevel>0 Then Begin
            tab(u.handle,30);
            tab(strr(u.udlevel),4);
            WriteLn(u.udpoints);
            If break Then exit
          End
      End
    End;

  Procedure reorderareas;
    Var numa,cura,newa:Integer;
      a1,a2:arearec;
      f1,f2:File;
      fn1,fn2:sstr;
    Label exit;
    Begin
      writelog(16,9,'');
      writehdr('Re-order Areas');
      numa:=FileSize(afile);
      WriteLn('Number of areas: ',numa);
      For cura:=0 To numa-2 Do Begin
        Repeat
          writestr('New area #'+^V+strr(cura+1)+^P+' [?=List, CR to quit]:');
          If Length(Input)=0 Then GoTo exit;
          If Input='?'
          Then
            Begin
              listareas;
              newa:=-1
            End
          Else
            Begin
              newa:=valu(Input)-1;
              If (newa<0) Or (newa>numa) Then Begin
                WriteLn('Not found!  Please re-enter...');
                newa:=-1
              End
            End
        Until (newa>=0);
        Seek(afile,cura);
        Read(afile,a1);
        Seek(afile,newa);
        Read(afile,a2);
        Seek(afile,cura);
        Write(afile,a2);
        Seek(afile,newa);
        Write(afile,a1);
        fn1:='Area';
        fn2:=fn1+strr(newa+1);
        fn1:=fn1+strr(cura+1);
        Assign(f1,fn1);
        Assign(f2,fn2);
        Rename(f1,'Temp$$$$');
        Rename(f2,fn1);
        Rename(f1,fn2)
      End;
exit: 
      setarea(1)
    End;

  Procedure newfiles;
    Var a,fn,un:Integer;
      ud:udrec;
      u:userrec;
      krad:lstr;
      flag,aborted:Boolean;

    Procedure writeudrec;
      Begin
        seekudfile(fn);
        Write(udfile,ud)
      End;

    Procedure ratefile(p:Integer);
      Begin
        ud.points:=p;
        ud.newfile:=False;
        ud.whenrated:=now;
        writeudrec;
        p:=p*uploadfactor;
        If p>0 Then Begin
          Writestr('Actually give user How many pts? ['+^V+strr(p)+^P+'] :');
          If Input='' Then Else If (valu(Input)>0) Or (Input='0') Then p:=valu(Input);
          un:=lookupuser(ud.sentby);
          If un=0
          Then WriteLn(ud.sentby,' has vanished!')
          Else Begin
            WriteLn('Giving ',ud.sentby,' ',p,' points.');
            If un=unum Then writeurec;
            Seek(ufile,un);
            Read(ufile,u);
            u.udpoints:=u.udpoints+p;
            Seek(ufile,un);
            Write(ufile,u);
            If un=unum Then readurec
          End
        End
      End;

    Procedure doarea;
      Var i,advance:Integer;
        done:Boolean;
      Begin
        fn:=1;
        advance:=0;
        While fn+advance<=numuds Do Begin
          fn:=fn+advance;
          advance:=1;
          seekudfile(fn);
          Read(udfile,ud);
          If ud.newfile Then Begin
            flag:=False;
            done:=False;
            ansicls;
            Repeat
              ansigotoxy(1,1);
              WriteLn(^B^M'[Filename   ]:',ud.filename,
              ^M'[SubDir Path]:',ud.path,
              ^M'[Uploaded by]:',ud.sentby,
              ^M'[File Size  ]:',ud.filesize,
              ^M'[Description]:',ud.descrip);
              i:=menu('Newscan','NEWSCAN','Q#_CEDRM0V');
              Input:=' '+strr(fn);
              If i<0
              Then
                Begin
                  ratefile(-i);
                  done:=True
                End
              Else
                Case i Of
                  1:Begin
                      aborted:=True;
                      exit
                    End;
                  3:done:=True;
                  4:Begin
                      writestr('Enter new description:');
                      If Length(Input)>0 Then ud.descrip:=Input;
                      writeudrec
                    End;
                  5:Begin
                      renamefile;
                      advance:=0
                    End;
                  6:Begin
                      deletef;
                      advance:=0
                    End;
                  7:listarchive;
                  8:Begin
                      movefile;
                      advance:=0
                    End;
                  9:Begin
                      ratefile(0);
                      done:=True
                    End
                End
            Until done Or (advance=0)
          End
        End
      End;

    Begin
      flag:=True;
      writelog(16,1,'');
      If issysop Then Begin
        writestr('Newscan all areas? *');
        If yes Then Begin
          For a:=1 To numareas Do Begin
            setarea(a);
            aborted:=False;
            doarea;
            If aborted Then exit
          End
        End Else doarea
      End Else doarea;
      If flag Then WriteLn(^B'No new files.')
    End;

  Procedure sysopcommands;
    Var i:Integer;
    Begin
      If Not sponsoron Then Begin
        reqlevel(sysoplevel);
        exit
      End;
      writelog(15,3,area.name);
      Repeat
        i:=menu('File sponsor','FSYSOP','A@CDF@G@KRNSMLO@QEW*@');
        Case i Of
          1:sysopadd;
          2:changef;
          3:deletef;
          4:directory;
          6:killarea;
          7:modarea;
          8:newfiles;
          9:sortarea;
          10:movefile;
          11:listxmodem;
          12:reorderareas;
          14:renamefile;
          15:addmultiplefiles;
          16:getarea;
        End
      Until hungupon Or (i=13)
    End;

  Procedure batch_menu;
    Var i:Integer;
    Begin
      Writehdr('Batch Transfer Menu');
      Repeat
        i:=menu('Batch Xfer','FBATCH','CLDUQAX');
        Case i Of
          1:clear_Batchdown;
          2:listbatch;
          3:do_batch_download;
          4:if area.uploadhere='Y' then Batch_Upload;
          6:bimodemupload;
          7:DOBIXFER;
        End
      Until hungupon Or (i=5)
    End;

  Var i:Integer;
    a:arearec;
    ms:Boolean;



  Label ok,exit;
  Begin
  killbimodem;
    clear_batchdown;
    cursection:=udsysop;
    ms:=False;
     ansicls;
     writehdr('The File Transfer Section');
    WriteLn;WriteLn;
    If isinlist(xferpcrlist) Then Else
      If Not PCRatio Then GoTo exit;Write(^R);

    Input:='';
    Assign(afile,'areadir');
    If exist('Areadir')
    Then
      Begin
        Reset(afile);
        If FileSize(afile)>0 Then GoTo ok
      End
    Else Rewrite(afile);
    WriteLn('No File areas Exist!!');
    area.xmodemdir:=forumdir+'XMODEM\';
    If issysop
    Then If makearea
      Then GoTo ok;
    GoTo exit;
ok:
    seekafile(1);
    Read(afile,a);
    If Not(Allowed_in_Area(a)) Then Begin
      WriteLn(^S'You do not have access to the file section!');
      GoTo exit
    End;
    yourudstatus;

    If urec.whereFile>0 Then setarea(urec.wherefile) Else setarea(1);

      Repeat
        If withintime(xmodemclosetime,xmodemopentime) Then
          If Not issysop Then Begin
            writestr(^M^M'File section is closed at this time!');
            WriteLn('The time is now   : '^S,timestr(now));
            WriteLn('File area opens at: '^S,xmodemopentime);
            GoTo exit
          End Else If Not ms Then Begin
            WriteLn('[HEY! The File area is closed until ',xmodemopentime,']');
            ms:=True
          End;

        If (urec.emulation=0) And ((vt52 in urec.config) or (ansigraphics In urec.config)) Then Begin
          If WhereY>21 Then Begin Ansigotoxy(1,24);WriteLn(^B^M^M);End;
          ansigotoxy(1,22);
        Write(^B^S,area.name,^R' ['^S,curarea,^R']') End Else
          WriteLn(^B^M^M^S,area.name,^R' ['^S,curarea,^R']');
        if urec.emulation=0 then
          i:=menu('File','FILE','UDLFYA!SQ%NVHRWXT+BG*IZ');

        If hungupon Then GoTo exit;
        Case i Of
          1:upload;
          2:download(0,'',0);
          3:listfiles(False);
          5:yourudstatus;
          21,6:getarea;
          8:searchfile;
          7:listallwithaccess(0,0,area.level,area.File_list);
          10:sysopcommands;
          11:newscanall;
          12:newscan;
          13:help('Filexfer.hlp');
          14:listarchive;
          15:printfile('Wantlist.bbs');
          16:listfiles(True);
          18:add_to_batch(0,'',0);
          19:batch_menu;
          20:offtheforum;
          22:zipfile;
          23:unzipafile;
        End

      Until hungupon Or (i=9);
exit:
    Close(afile);
    Close(udfile);
    i:=IOResult;
  End;
  begin
  end.