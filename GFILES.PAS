  {$R-,S-,I-,D-,F-,V-,B-,N-,L+,O+ }


  unit Gfiles;

  Interface

  uses dos,crt,gentypes,modem,configrt,statret,windows,gensubs
  ,subs1,subs2,mainr1,mainr2,protocol,userret;

  Procedure AboutThisBBS(AreaForward:lstr);

  Implementation




Procedure AboutThisbbs(areaForward:lstr);
  Var showit,itsotay:Boolean;

  Type GFileRec=Record
                  GFileDescr:String[73];
                  Points:Integer;
                  Sentby:String[28];
                  Path:String[50];
                  ArcName:sstr;
                  FName:lstr;
                  FileSize:longint;
                  date:longint;
                  Downloaded:Integer;
                  SpecialFile,NewFile:Boolean;
                End;

    GFileArea=Record
                Name:Lstr;
                GFileDir:String[49];
                Area_Type:sstr;
                File_List:lstr;
                Sponsor:mstr;
                Level:Integer;
                UpAble:Boolean;
              End;

  Var GFile:File Of GFileRec;
    GF:GFileRec;
    GFileA:File Of GFileArea;
    GFA:GFileArea;
    Curarea:Integer;
  Procedure uploadgfile;Forward;
  Function NumGFiles:Integer;
    Begin
      numgfiles:=FileSize(GFile)
    End;

  Function NumAreas:Integer;
    Begin
      numareas:=FileSize(GFileA)
    End;

  Procedure SeekGFile(n:Integer);
    Begin
      Seek(GFile,n-1)
    End;

  Procedure SeekGFileA(n:Integer);
    Begin
      Seek(GFileA,n-1)
    End;

  Function hasaccess:Boolean;
    Begin
      hasaccess:=False;
      If issysop Then hasaccess:=True;
      If (gfa.area_type[1] in [ 'L' , 'B']) Then
        If (Gfa.level<=urec.gflevel) Then hasaccess:=True;
      If (gfa.area_type[1] in [ 'G' , 'B']) Then
        If isinlist(gfa.File_List) Then hasaccess:=True;
    End;

  Procedure AssignGF(N:Integer);
    Begin
      Close(GFile);
      Assign(GFile,uploaddir+'GFILE'+strr(n));
    End;

  Function MakeArea:Boolean;
    Var num,n:Integer;
      GFATmp:GFileArea;
    Begin
      makearea:=False;
      writestr('Create area '+strr(numareas+1)+'? *');
      WriteLn;

      If yes Then Begin
        writestr('Area name: *');
        If Length(Input)=0 Then exit;
        GFATmp.Name:=Input;

        writestr('Co-Sysop ['+unam+']:');
        If Length(Input)=0 Then Input:=unam;
        GFATmp.Sponsor:=Input;

        writestr('Area Type [L]evel [G]roup or [B]oth [L]:');
        If Length(Input)=0 Then Input:='L';
        GFATmp.Area_Type:=UpCase(Input[1]);
        if not ( gfatmp.area_type[1] in ['G' , 'B' , 'L'] ) then
          gfatmp.area_type := 'L' ;
        if gfatmp.area_type[1] in [ 'G' , 'B' ] then
          begin
            writestr('Group Access File List [None]:');
            If Length(Input)=0 Then Input:='None';
            GFATmp.File_List:=Input;
          end
        else
          gfatmp.file_list := 'None' ;

        if gfatmp.area_type[1] in [ 'L' , 'B' ] then
          begin
            writestr('Gfile Access level: *');
            If Length(Input)=0 Then exit;
            GFATmp.Level:=valu(Input);
          end
        else
          gfatmp.level := maxint ;

        GFATmp.UpAble:=True;
        writestr('Able to Upload to area [Yes]: *');
        If Length(Input)=0 Then Input:='Y';
        If yes Then Else GFATmp.UpAble:=False;
        writestr('Upload Directory ['+uploaddir+']: *');
        If Length(Input)=0 Then Input:=uploaddir;
        GFATmp.GFileDir:=Input;
        SeekGFileA(numareas+1);
        Write(GFileA,GFATmp);
        GFA:=GFATmp;
        Curarea:=NumAreas+1;
        AssignGF(CurArea);
        Rewrite(GFile);
        WriteLn('Area created');
        makearea:=True;
        writelog (21,1,+GFATmp.Name+' ['+strr(num)+']');
      End;

    End;

  Procedure OpenGFile;
    Var n:Integer;
    Begin
      n:=IOResult;
      Assign(GFileA,uploaddir+'GFileDir');
      Reset(GFileA);
      If IOResult<>0 Then Begin
        Close(GFileA);
        n:=IOResult;
        if issysop then
          begin
            Rewrite(GFileA);
            itsotay:=makearea;
          end
        else
          itsotay := false ;
      End Else itsotay:=True;
    End;

  Function GetFName(path:lstr;name:mstr):lstr;
    Var l:lstr;
    Begin
      l:=path;
      If Length(l)<>0 Then
        If Not(UpCase(l[Length(l)]) In [':','\'])
        Then l:=l+'\';
      l:=l+name;
      getfname:=l;
    End;

  Function GetAPath:lstr;
    Var q,r:Integer;
      f:File;
      b:Boolean;
      p:lstr;
    Begin
      getapath:=GFA.GFileDir;
      Repeat
        writestr('Upload path [CR/'+GFA.GFileDir+']:');
        If hungupon Then exit;
        If Length(Input)=0 Then Input:=GFA.GFileDir;
        p:=Input;
        If Input[Length(p)]<>'\' Then p:=p+'\';
        b:=True;
        Assign(f,p+'CON');
        Reset(f);
        q:=IOResult;
        Close(f);
        r:=IOResult;
        If q<>0 Then Begin
          writestr('Make that path? *');
          b:=yes;
          If b Then Begin
            MkDir(Copy(p,1,Length(p)-1));
            q:=IOResult;
            b:=q=0;
            If b Then writestr('Directory created..')
            Else writestr('Unable to create directory..')
          End
        End
      Until b;
      getapath:=p;
    End;

  Procedure fastlistfile(n:Integer);
    Var q:sstr;
    Begin
      seekGFile(n);
      Read(GFile,GF);
      tab(strr(n)+'.',4);
      If gf.points<0 Then tab('NEW',5) Else Tab(strr(gf.points),5);
      If break Then exit;
      If (GF.ArcName='') Then
        If exist(GetFName(GF.Path,GF.FName)) Then
        tab(strr(GF.FileSize),9) Else Write('[OFFLINE]')
      Else Write('[ARCHIVE]');
      If break Then exit;
      WriteLn('  '+GF.GFileDescr);
      If break Then exit;
    End;

  Function NoFiles:Boolean;
    Begin
      If NumGFiles=0 Then Begin
        nofiles:=True;
        writestr(^M'No G-files exist! Upload some!')
      End Else nofiles:=False
    End;

  Procedure FastListGFiles;
    Var cnt,max,r1,r2,r3:Integer;
    Begin
      If nofiles Then exit;
      writehdr('File List');
      max:=NumGFiles;
      thereare(max,'G-File','G-Files');
      parserange(max,r1,r2);
      If r1=0 Then exit;
      tab('#.',4);
      tab('Cost',5);
      tab('Size',6);
      tab('Description',60);
      WriteLn;
      WriteLn;

      r3:=0;
      For cnt:=r1 To r2 Do Begin
        r3:=r3+2;
        FASTlistfile(cnt);
        If break Then exit
      End;
      WriteLn;
    End;

  Function GetGFileNum(t:mstr):Integer;
    Var n,s:Integer;

    Function SearchforFile(f:sstr):Integer;
      Var cnt:Integer;
      Begin
        For cnt:=1 To numgfiles Do Begin
          seekGFile(cnt);
          Read(GFile,GF);
          If match(GF.FName,f) Then Begin
            searchforfile:=cnt;
            exit
          End
        End;
        searchforfile:=0
      End;
    Begin
      getgfilenum:=0;
      If Length(Input)>1 Then Input:=Copy(Input,2,255) Else
        Repeat
          writestr('File # to '+t+' [?/List]:');
          If hungupon Or (Length(Input)=0) Then exit;
          If Input='?' Then Begin
            fastlistgfiles;
            Input:=''
          End
        Until Input<>'';
      Val(Input,n,s);
      If s<>0 Then Begin
        n:=searchforfile(Input);
        If n=0 Then Begin
          WriteLn('No such file..');
          exit
        End
      End;
      If (n<1) Or (n>numgfiles) Then WriteLn('Invalid number..')
      Else getgfilenum:=n
    End;

  Procedure AddFile(GF:GFileRec);
    Begin
      SeekGFile(NumGFiles+1);
      Write(GFile,GF)
    End;

  Function Getfsize(Filename:anystr):longint;
    Var df:File Of Byte;
    Begin
      GF.FileSize:=-1;
      Assign(df,Filename);
      Reset(df);
      If IOResult<>0 Then exit;
      GetFSize:=FileSize(df);
      Close(df)
    End;

  Const beenaborted:Boolean=False;

  Function Aborted:Boolean;
    Begin
      If beenaborted Then Begin
        aborted:=True;
        exit
      End;
      aborted:=xpressed Or hungupon;
      If xpressed Then Begin
        beenaborted:=True;
        WriteLn(^B'New-scan aborted..')
      End
    End;
  Procedure ShowGFile(n:Integer);
    Var f:File;
        dummy : integer ;
    Begin
      seekGFile(n);
      Read(GFile,GF);

      If ulvl<0 Then
        reqlevel(0);
      If ulvl<0 Then exit;
      If (issysop=False) And (gf.points=-1) Then WriteLn(^B'This file is NEW and must be validated first!');
      If (issysop=False) And (gf.points=-1) Then exit;
      If (issysop=False) And (urec.gpoints<gf.points) Then WriteLn(^B'This G-File costs ',gf.points,' points to download!');
      If (issysop=False) And (urec.gpoints<gf.points) Then exit;

      WriteLn;
      If GF.FName='users' Then Begin
        WriteLn('Files with that name can not be downloaded');
        WriteLog(15,6,' USERS');
        exit;
      end;
      If GF.ArcName<>'' Then Begin
        WriteLn;
        Write('This G-file is Archived.. Extracting');

        If exist(GF.FName) Then Begin
          WriteLn;
          WriteLn('Destination Already Exists! Cannot De-arc! Tell the Sysop!');
          exit;
        End;

        Exec('PKunzip.exe',GetFName(GF.Path,GF.ArcName)+' '+GF.FName);

        If Not exist(GF.FName) Then Begin
          WriteLn;
          WriteLn('Error Has Occurred.. Leave Sysop a comment..');
          exit;
        End;
      End;

      If (GF.ArcName='') And Not exist(GetFName(GF.Path,GF.Fname)) Then Begin
        WriteLn('File is offline! Please Request it!');
        WriteLn;
        exit;
      End;
      writestr('Ready to Send: Enter [X] to Abort or [RETURN] to Continue: *');
      If UpCase(Input[1])='X' Then exit;
      WriteLn(^M'Name:    '^S,GF.GFileDescr,
      ^M'Date:    '^S,datestr(GF.Date),
      ^M'Time:    ',TimeStr(GF.date),^M);
      WriteLn('Press [Ctrl-X] to abort or [Ctrl-S] to pause!'^M^M);
      If GF.ArcName='' Then printfile(GetFname(GF.Path,GF.Fname)) Else
        printfile(GF.FName);
      If GF.ArcName<>'' Then Begin
        Assign(f,GF.FName);
        Erase(f);
      End;
      urec.gpoints:=urec.gpoints-gf.points;
      urec.GDownloads:=urec.GDownloads+1;
      WriteLn(asciidownload);
      Writestr(^B'Press [Return] to Continue:');
    End;

  Procedure NewScan;
    Var cnt:Integer;
      first,n:Integer;
      done,newest:Boolean;
      kk:Char;
    Label notlater;
    Begin
      done:=False;
      newest:=False;
      beenaborted:=False;
      first:=0;
      For cnt:=FileSize(GFile) Downto 1 Do Begin
        SeekGFile(cnt);
        Read(GFile,GF);
        If GF.date>subs1.laston
        Then first:=cnt
        Else GoTo notlater
      End;
notlater: 
      If first<>0 Then Begin
        While done=False Do Begin
          ansicls;
          WriteLn(^M^T'G-File Area: ['^S,GFA.name+']');
          tab('#.',4);
          tab('Cost',5);
          tab('Size',6);
          tab(^M^M^M'Description',60);
          WriteLn;

          For cnt:=first To FileSize(GFile) Do Begin
            If aborted Then exit;
            fastlistfile(cnt);
          End;
          If aborted Then exit;

          Writestr(^B^M'Gfile Newscan [A]gain [D]ownload [U]pload [N]ext [N]:');
          If Input='' Then Input:='N';
          kk:=UpCase(Input[1]);

          If kk='D' Then Begin
            n:=GetGFileNum('download');
            If n>0 Then ShowGFile(n);
          End;
          If kk='U' Then uploadgfile;
          If kk='N' Then done:=True;
        End;
      End
    End;



  Procedure SetArea(n:Integer);
    Var otay:Boolean;
    Begin
      curarea:=n;
      otay:=False;
      If (n>numareas) Or (n<1) Then Begin
        WriteLn(^B'Invalid!');
        If issysop Then If makearea Then setarea(curarea)
        Else setarea(1)
      Else setarea(1);
        exit
      End;
      seekGFileA(n);
      Read(GFileA,GFA);

      otay:=hasaccess;
      If otay=False Then
        If curarea=1 Then error('Access level too low..','','')
        Else Begin
          reqlevel(GFA.level);
          setarea(1);
          exit
        End;

      AssignGF(n);
      Close(GFile);
      Reset(GFile);
      If IOResult<>0 Then Rewrite(GFile);
      If Not showit Then WriteLn(^B^M^M'G-File Area: ['^S,curarea,^R']  ['^S,GFA.name,^R']');
      urec.wheregfile:=curarea;
      writeurec;

      If showit=False Then WriteLn;
    End;

  Procedure newscanall;
    Var cnt:Integer;
      otay:Boolean;
    Begin
      urec.LastGFileArea:=curarea;
      writehdr('Newscanning, press [X] to abort.');
      If aborted Then exit;
      For cnt:=1 To FileSize(GFileA) Do Begin
        seekGFileA(cnt);
        Read(GFileA,GFA);
        otay:=False;
        If hasaccess Then otay:=True;
        If otay Then Begin
          If aborted Then exit;
          showit:=True;
          setarea(cnt);
          showit:=False;
          If aborted Then exit;
          newscan;
        End;
        If aborted Then exit
      End;
      setarea(urec.LastGFileArea);
    End;

  Procedure ListAreas;
    Var cnt,old:Integer;
      GFATmp:GFileArea;

    Begin
      writehdr('Gfile Area List');
      old:=curarea;
      seekGfileA(1);
      WriteLn(^M'Area   Level      Name');
      For cnt:=1 To NumAreas Do Begin
        Read(GFileA,GFATmp);
        If hasaccess Then Begin
          Write(cnt:5);
          Write(GFATmp.Level:7);
          WriteLn('   ',GFATmp.Name);
          If break Then Begin
            setarea(old);
            exit;
          End;
        End;
      End;
      WriteLn;
      setarea(old);
    End;

  Function GetAreaNum:Integer;
    Var areastr:sstr;
      areanum:Integer;
    Begin
      getareanum:=0;
      If Length(Input)>1 Then areastr:=Copy(Input,2,255) Else
        Repeat
          listareas;
          writestr(^M'Enter New Area [?]:');
          If Input='!' Then listareas Else areastr:=Input
        Until (Input<>'?') Or hungupon;
      If Length(areastr)=0 Then exit;
      areanum:=valu(areastr);
      If (areanum>0) And (areanum<=NumAreas) Then getareanum:=areanum
      Else Begin
        writestr('No such area..');
        If issysop Then If makearea Then getareanum:=numareas
      End;
      urec.LastGFileArea:=areanum;
    End;

  Procedure GetArea;
    Var areanum:Integer;
    Begin
      areanum:=getareanum;
      If areanum<>0 Then SetArea(areanum);
    End;

  Procedure YourGFStatus;
    Begin
      clearbreak;nobreak:=True;dontstop:=True;
      If ansigraphics In urec.config Then Begin
        ansiwindow(30,10,67,16);
        ansigotoxy(36,11);Write(^S'   [ Gfile status ]');
        ansigotoxy(36,12);Write(^R'GFile Section Level:  '^S,urec.GFlevel);
        ansigotoxy(36,13);Write(^R'Uploads:              '^S,urec.GUploads);
        ansigotoxy(36,14);Write(^R'Downloads:            '^S,urec.GDownloads);
        ansigotoxy(36,15);Write(^R'G-file points:        '^s,urec.Gpoints);
        ansigotoxy(1,18);
      End Else Begin

        WriteLn(^R'GFile Section Level:  '^S,urec.GFlevel);
        WriteLn('Uploads:              '^S,urec.GUploads);
        WriteLn('Downloads:            '^S,urec.GDownloads);
        WriteLn('G-file points:        '^s,urec.Gpoints);
      End;
    End;


  Procedure MakeGFile(FileName:anystr);
    Var t:Text;
      pin:anystr;
      b:Boolean;
      yo:Boolean;
      RM:Char;
    Begin
      yo:=False;
      Write('Upload using Xmodem [Default Ascii]? :');
      getstr;yo:=yes;

      If Not yo Then Begin
        Assign(t,Filename);
        Rewrite(t);
        WriteLn(^M'Begin Transmission! To Finish send [Ctrl-Z] '^M);

        pin:='';

        Repeat
          If charready Then Begin
            RM:=readchar;
            Write(rm);
            write(t,rm);
          End;

        Until (rm=^Z) Or hungupon;

        textclose(t);
        If match(pin,'/A') Then Erase(t);
      End Else Begin
        yo:=((protocolxfer(False,True,False,1,filename)=0));
        If yo Then WriteLn(^B'File Received.');
        If Not yo Then Begin
          Assign(t,filename);Erase(t);
          Writeln('File Transfer Aborted');
        End;

      End;
    End;

  Procedure UploadGFile;
    Var FN:anystr;
    Begin
      If gfa.upable=False Then exit;
      WriteLn;
      Repeat
        writestr('Enter Upload Filename: *');
        If Length(Input)=0 Then exit;
      Until validfname(Input);
      GF.FName:=Input;
      FN:=GetFName(GFA.GFileDir,GF.FName);
      If GF.FName='users' Then Begin
        WriteLn('Files with that name will not be accepted');
        WriteLog(15,5,' USERS');
        exit;
      End;
      If exist(FN) Then Begin
        WriteLn('Filename already exists!');
        WriteLn('Gfile Upload aborted!');
        exit;
      End;
      writestr('Description: *');
      If Input='' Then Input:='[ No Description ]';
      GF.GFileDescr:=Input;
      makeGFile(FN);
      WriteLn('Uploading? its about time!');
      gf.filesize:=getfsize(fn);
      GF.date:=now;
      GF.SentBy:=Unam;
      GF.Path:=gfa.gfiledir;
      GF.Downloaded:=0;
      GF.SpecialFile:=False;
      GF.NewFile:=True;
      GF.ArcName:='';
      gf.points:=-1;
      Urec.GUploads:=Urec.GUploads+1;
      seekGFile(numgfiles+1);
      Write(GFile,GF);
      WriteLn;
    End;

    Procedure getstr(prompt:mstr;Var ss;len:Integer);
      Var a:anystr Absolute ss;
      Begin
        WriteLn(^B^M'  Current ',prompt,' is: '^S,a);
        BufLen:=len;
        writestr('Enter new '+prompt+':');
        If Length(Input)>0 Then a:=Input;
      End;

    Procedure getint(prompt:mstr;Var i:Integer);
      Var q:sstr;
        n:Integer;
      Begin
        Str(i,q);
        getstr(prompt,q,5);
        n:=valu(q);
        If n<>0 Then i:=n
      End;

    Procedure getboo(t:lstr;Var b:Boolean);
      Var s:sstr;
      Begin
        s:=yesno(b);
        getstr(t,s,1);
        b:=UpCase(s[1])='Y'
      End;

    Procedure RemoveFile(n:Integer);
      Var cnt:Integer;
      Begin
        For cnt:=n To numgfiles-1 Do Begin
          seekGFile(cnt+1);
          Read(GFile,GF);
          seekGFile(cnt);
          Write(GFile,GF)
        End;
        seekGFile(numgfiles);
        Truncate(GFile)
      End;


    Procedure AddGFile;
      Var FN:Anystr;
      Begin
        writestr('Filename: *');
        If Length(Input)=0 Then exit;
        GF.FName:=Input;
        If POS('USERS',upstring(GF.FName))>0 Then Begin
          WriteLn('Files with that name can not be Added');
          WriteLog(15,7,' USERS');
          exit;
        end;
        
        Writestr('Path [CR/'+GFA.GFileDir+']: *');
        If Length(Input)=0 Then Input:=GFA.GFileDir;
                If (ulvl<sysoplevel) and (POS('EMULEX',upstring(GFa.GFILEDIR))>0 ) Then Begin
          WriteLn('Files with that pathname can not be Added');
          WriteLog(15,7,' \Emulex\Added violation');
          exit;
        end;

        GF.Path:=Input;
        WriteStr('Archive Filename [CR/None]: *');
        If Length(Input)=0 Then GF.ArcName:='' Else Begin
          GF.ArcName:=Input;
          writestr('You can check to see if file is in the Arc.. [Y] to continue: *');
          If Not yes Then GF.ArcName:='';
        End;
        If GF.ArcName='' Then Begin
          FN:=GetFName(GF.Path,GF.FName);
          If Not exist(FN) Then Begin
            writestr('File not found!  Type-in file now(ya right)? *');
            If yes Then makegfile(FN)
          End;
          If Not exist(FN) Then exit;
        End;
        Writestr('Points:');
        if input='' then gf.points:=0 else gf.points:=valu(input);
        writestr('Description:');
        If Length(Input)=0 Then exit;
        If GF.ArcName='' Then GF.FileSize:=GetFSize(FN) Else GF.FileSize:=0;
        GF.GFileDescr:=Input;
        GF.date:=now;
        GF.SentBy:=Unam;
        GF.Downloaded:=0;
        GF.SpecialFile:=False;
        GF.NewFile:=False;
        seekGFile(numgfiles+1);
        Write(GFile,GF);
        WriteLn;
      End;

    Procedure EditGFile;
      Var n:Integer;
        fn:anystr;
      Begin
        n:=getgfilenum('edit');
        If n=0 Then exit;
        seekGFile(n);
        Read(GFile,GF);
        if ulvl<sysoplevel then Writeln ('Only TRUE sysops can modify Filename/paths!');
    if ulvl>=sysoplevel then     getstr('filename',GF.FName,12);
    if ulvl>=sysoplevel then     getstr('path',GF.Path,50);
    if ulvl>=sysoplevel then     getstr('arc filename [make sure file is in arc!]',GF.ArcName,50);
        If GF.ArcName='' Then Begin
          FN:=GetFName(GF.Path,GF.FName);
          If Not exist(FN) Then Begin
            Write(^B^M,FN,' not found!');
            writestr(^M'Create new file '+FN+'? *');
            If yes Then makegfile(FN);
            If Not exist(FN) Then exit;
          End Else GF.FileSize:=GetFSize(FN);
        End Else GF.FileSize:=0;
        getstr('description',GF.GFileDescr,75);
        getstr('uploader',GF.SentBy,28);
        getint ('POINTS',GF.points);
        getboo('special file',GF.SpecialFile);
        getboo('new file',GF.NewFile);
        seekGFile(n);
        Write(GFile,GF);
      End;

    Procedure KillGArea;
      Var GFATmp:GFileArea;
        cnt,n:Integer;
        oldname,newname:sstr;
      Begin
        GFATmp:=GFA;
        writestr('Delete A'+strr(curarea)+' ['+GFATmp.Name+']: *');
        If Not yes Then exit;
        Close(GFile);
        oldname:=uploaddir+'GFile'+strr(curarea);
        Assign(GFile,oldname);
        Erase(GFile);
        For cnt:=curarea To NumAreas-1 Do Begin
          newname:=oldname;
          oldname:=uploaddir+'GFile'+strr(cnt+1);
          Assign(GFile,oldname);
          Rename(GFile,newname);
          n:=IOResult;
          SeekGFileA(cnt+1);
          Read(GFileA,GFATmp);
          seekGFileA(cnt);
          Write(GFileA,GFATmp);
        End;
        seekGFileA(numareas);
        Truncate(GFileA);
        setarea(1)
      End;

    Procedure ModGArea;
      Var GFATmp:GFileArea;
      Begin
        GFATmp:=GFA;
        getstr('area name',GFATmp.Name,80);

        getstr('sponsor',GFATmp.Sponsor,30);
        Getstr('AC.Type [L,G,B]',gfatmp.area_type,2);
        gfatmp.area_type := upcase(gfatmp.area_type[1]);
        If not ( gfatmp.area_type[1] in [ 'G' , 'L' , 'B' ] ) then
          exit ;
        if gfatmp.area_type[1] in [ 'G' , 'B' ] then
          Getstr('G.Ac.File_list',gfatmp.File_List,40)
        else
          gfatmp.file_list := 'None' ;
        if gfatmp.area_type[1] in [ 'L' , 'B' ] then
          getint('access level',GFATmp.Level)
        else
          gfatmp.Level := maxint ;
        getboo('"Able to upload here"',GFATmp.UpAble);
        getstr('upload dir',GFATmp.GFileDir,50);
        seekGFileA(curarea);
        Write(GFileA,GFATmp);
        GFA:=GFATmp;
      End;

    Procedure DeleteGFile;
      Var cnt,n:Integer;
        f:File;
      Begin
        n:=getgfilenum('delete');
        If n=0 Then exit;
        SeekGFile(n);
        Read(GFile,GF);
        writestr('Delete '+GF.GFileDescr+'? *');
        If Not yes Then exit;
        writestr('Erase disk file '+GF.FName+'? *');
        If yes Then Begin
          If GF.ArcName<>'' Then Begin
            WriteLn('File is in archive. You cannot delete it from here.');
            exit;
          End;
          Assign(f,GetFname(GF.Path,GF.FName));
          Erase(f);
          If IOResult<>0 Then writestr('Couldn''t erase file..')
        End;
        For cnt:=n+1 To numgfiles Do Begin
          seekGFile(cnt);
          Read(GFile,GF);
          seekGFile(cnt-1);
          Write(GFile,GF)
        End;
        seekGFile(numgfiles);
        Truncate(GFile);
        writestr(^M'Deleted.');
      End;

    Procedure UpdateGFile;
      Var n:Integer;
      Begin
        n:=GetGFileNum('update');
        If n=0 Then exit;
        seekGFile(n);
        Read(GFile,GF);
        GF.date:=now;
        If GF.ArcName='' Then GF.FileSize:=getFSize(getFName(GF.Path,GF.FName));
        seekGFile(n);
        Write(GFile,GF);
      End;

    Procedure SortGArea;
      Var temp,Mark,cnt,method:Integer;
        v1,v2:String[80];
        GFTmp:GFileRec;
      Begin
        writehdr('Sort G-Files');
        WriteLn;
        WriteLn('[0]: Quit');
        WriteLn('[1]: Description');
        WriteLn('[2]: Filename');
        WriteLn;
        writestr('Enter method: *');
        method:=valu(Input[1]);
        If method=0 Then exit;
        Mark:=numgfiles-1;
        Repeat
          If Mark<>0 Then Begin
            temp:=Mark;
            Mark:=0;
            For cnt:=1 To temp Do Begin
              seekGFile(cnt);
              Read(GFile,GF);
              Read(GFile,GFTmp);
              If method=1 Then Begin
                v1:=upstring(GF.GFileDescr);
                v2:=upstring(GFTmp.GFileDescr);
              End Else Begin
                v1:=upstring(GF.FName);
                v2:=upstring(GFTmp.FName);
              End;
              If v1>v2 Then Begin
                Mark:=cnt;
                seekGFile(cnt);
                Write(GFile,GFTmp);
                Write(GFile,GF)
              End
            End
          End
        Until Mark=0
      End;

    Procedure ReorderGAreas;
      Var cura,newa:Integer;
        GFATmp:GFileArea;
        f1,f2:File;
        fn1,fn2:sstr;
      Label exit;
      Begin
        writehdr('Reorder G-File Areas');
        WriteLn(^M'Number of G-File areas: ',numareas:1);
        For cura:=0 To numareas-2 Do Begin
          Repeat
            writestr(^M'New area #'+strr(cura+1)+' [?/List]:[CR/Quit]:');
            If Length(Input)=0 Then GoTo exit;
            If Input='?' Then Begin
              listareas;
              newa:=-1
            End Else Begin
              newa:=valu(Input)-1;
              If (newa<0) Or (newa>=numareas) Then Begin
                WriteLn('Not found!  Please re-enter...');
                newa:=-1
              End
            End
          Until (newa>0);
          Seek(GFileA,cura);
          Read(GFileA,GFA);
          Seek(GFileA,newa);
          Read(GFileA,GFATmp);
          Seek(GFileA,cura);
          Write(GFileA,GFATmp);
          Seek(GFileA,newa);
          Write(GFileA,GFA);
          fn1:=uploaddir+'GFile';
          fn2:=fn1+strr(newa+1);
          fn1:=fn1+strr(cura+1);
          Assign(f1,fn1);
          Assign(f2,fn2);
          Rename(f1,'Temp$$$$.XYZ');
          Rename(f2,fn1);
          Rename(f1,fn2)
        End;
exit:
        setarea(1)
      End;


    Procedure MoveGFile;
      Var an,fn,old:Integer;
        newfilesam,sambam,filesam,wangbang:anystr;
        darn:File;
        GFTmp:GFileRec;
      Begin
        fn:=GetGFileNum('move');
        old:=curarea;
        If fn=0 Then exit;
        Input:='';
        an:=GetAreaNum;
        If an=0 Then exit;
        SeekGFile(fn);
        Read(GFile,GFTmp);
        removefile(fn);
        If GFTmp.ArcName='' Then
        writestr('Literally move the file to correct area? *') Else
          Input:='N';
        Write('Moving...');
        filesam:=GetFName(GFTmp.Path,GFTmp.FName);
        sambam:=GFTmp.Path;
        setarea(an);
        If (sambam<>GFA.GFileDir) Then If yes Then Begin
          GFTmp.Path:=GFA.GFileDir;
          newfilesam:=GetFName(GFTmp.Path,GFTmp.FName);
          exec(getenv('comspec'),'/c Copy '+filesam+' '+newfilesam+' >temp');
          wangbang:=filesam;
          Assign(darn,wangbang);
          If exist(newfilesam) Then Erase(darn) Else Begin
            GFTmp.Path:=sambam;
            WriteLn('Uh oh... Bad error!');
          End;
        End;
        setarea(An);
        Addfile(GFTmp);
        setarea(old);
        WriteLn(^B'Done.')
      End;

    Procedure SysopNewScan;
      Var cnt,krad:Integer;
        first,p:Integer;
        newest:Boolean;
        un:Integer;
        u:userrec;
      Begin

        For krad:=1 To FileSize(GFileA) Do Begin
          seekGFileA(krad);
          Read(GFileA,GFA);
          setarea(krad);

          first:=0;
          WriteLn;
          WriteLn(^M^T'G-File Area: ['^S,GFA.name+']');
          If numgfiles>0 Then
            For cnt:=1 To FileSize(GFile) Do Begin
              seekGFile(cnt);
              Read(GFile,GF);
              If gf.newfile Then Begin
                WriteLn;
                Fastlistfile(cnt);
                Writestr(^M^M'New File Enter # of points or [S]kip [S] :');
                If Input='' Then Else
                  If (Input='0') Or (valu(Input)>0) Then Begin
                    gf.newfile:=False;
                    gf.points:=valu(Input);
                    seekgfile(cnt);
                    Write(gfile,gf);

                    p:=gf.points*uploadfactor;

                    If p>0 Then Begin
                      Writestr(^M'Actually give How many points ['+strr(p)+'] :');
                      If Input='' Then Else If (valu(Input)>0) Or (Input='0') Then p:=valu(Input);
                      un:=lookupuser(gf.sentby);
                      If un=0
                      Then WriteLn(gf.sentby,' has vanished!')
                      Else Begin
                        WriteLn('Giving ',gf.sentby,' ',p,' points.');
                        If un=unum Then writeurec;
                        Seek(ufile,un);
                        Read(ufile,u);
                        u.gpoints:=u.gpoints+p;
                        Seek(ufile,un);
                        Write(ufile,u);
                        Close(ufile);
                        If un=unum Then readurec
                      End;
                    End;
                  End;
            End;End;
        End;
      End;

  Procedure SysopCommands;
    Var q:Integer;
    Begin
      If Not issysop Then Begin
        reqlevel(sysoplevel);
        exit
      End;
      Repeat
        q:=menu('G-File Sysop','SGFILE','QACDUKRMSON');
        Case q Of

          2:AddGFile;
          3:EditGFile;
          4:DeleteGFile;
          5:UpdateGFile;
          6:KillGArea;
          7:ModGArea;
          8:MoveGFile;
          9:SortGArea;
          10:ReorderGAreas;
          11:sysopnewscan;
        End
      Until hungupon Or (q=1)
    End;

  Var prompt:lstr;
    n:Integer;
    k:Char;
    q,x1,x2,x3,i:Integer;
    y1,y2,y3:Real;
    q1:mstr;
    a:arearec;
    ms:Boolean;
    dammit:Boolean;
  Begin
    If ansigraphics In urec.config Then ansicls;

    dammit:=False;
    x1:=urec.nbu;
    x2:=urec.numon;
    If x1<1 Then x1:=1;
    If x2<1 Then x2:=1;
    y1:=Int(x1);
    y2:=Int(x2);
    y1:=y1;
    y2:=y2;

    y3:=y1/y2;
    Y3:=Y3*100;
    x3:=Trunc(y3);
    If ANSIgraphics In urec.config Then ANSICLS;
    If gfilepcrlist='' Then Else Begin
      If isinlist(gfilepcrlist) Then gfratio:=0;
    End;
    If GFRATIO>0 Then
      If (X3<GFRATIO) Then Begin
        dontstop:=True;
        nobreak:=True;
        WriteLn(^T'         [Post/G-File Xfer Ratio]');
        WriteLn('    You''ve posted #',urec.nbu,' messages');
        WriteLn('    And have called ',urec.numon,' times.');
        WriteLn('    You have a ',x3,'% ratio now.');
        WriteLn('    Minimum Ratio is ',GFRATIO,'%.');
      End;

    If (x3<gfratio) And Not ISSYSOP And (ULVL<RATLEVEL) Then Begin
      If exist(textfiledir+'LowGFRatio.bbs') Then printfile(textfiledir+'LowGFRatio.bbs') Else
        WriteLn(' Your Posts/G-File ratio is too low,Post a message or two!');
      dammit:=True;
    End;
    If dammit Then exit;

    WriteLn('Welcome to the General Files section');
    WriteLn;
    itsotay:=False;
    OpenGFile;
    If Not itsotay Then exit;
    SeekGFileA(1);
    Read(GFileA,GFA);
    If hasaccess=False Then Begin
      WriteLn(^M^M^M'You don''t have access to the gfiles section.'^M^M);
      Close(Gfilea);
      exit;
    End;
    YourGFStatus;
    If (urec.WhereGFile>0) Then setarea(urec.WhereGFile)
    Else Begin
      urec.WhereGfile:=1;
      setarea(1);
    End;
    Repeat
      prompt:='';
      If (urec.emulation=0) And (Ansigraphics In urec.config) Then

        If (WhereY>21) Then Begin ansigotoxy(1,24);WriteLn(^M^M^M^M);ansigotoxy(1,22);
        End;


      q:=menu('G-Files','GFILE','QU%FAYNVDL');
      Case q Of
        1:Begin
          End;
        2:If gfa.upable Then UploadGFile Else WriteLn('You can not upload here!');
        3:SysopCommands;
        4:FastListGFiles;
        5:GetArea;
        6:YourGFStatus;
        7:NewScanAll;
        8:NewScan;
        9:Begin
            n:=GetGFileNum('download');
            If n>0 Then ShowGFile(n);
          End;
        10:fastlistgfiles;
      End;
    Until hungupon Or (q=1);
    Close(gfile);
    Close(Gfilea);
  End;

Begin
End.
