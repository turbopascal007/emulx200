
  Procedure Zipfile;
    Var cnt:Integer;
      a:arearec;
cn,      start_area : integer ;
      bang:text;
      wang:lstr;

      u:udrec;
      first:Boolean;
      done:Boolean;
      T:Char;
  Procedure listfileb(n:Integer;extended:Boolean);
    Var ud:udrec;
      q:sstr;
     path, Filez:anystr; _Name:namestr; _Ext: Extstr;
      Sze:longint;
     Any:lstr;
    Begin
      seekudfile(n);
      Read(udfile,ud);
      any:=strr(n)+'.';
      write(bang,any:4);

        FSplit(ud.filename,path,_name,_ext);
      path:=upcase(_name[1]);
      _name[1]:=path[1];
      write (bang,_Name:8); Write (bang,upstring(_ext):4,'  ');
      If ud.newfile
      Then Write(bang,' New   ')
      Else If ud.specialfile
        Then Write(bang,' Ask   ')
        Else If ud.points>0
          Then Write(bang,ud.points:4 , '   ')
          Else Write(bang,'       ');
      Filez:=getfname(ud.path,ud.filename);
      If Not(exist(filez)) Then write(bang,'[Offline]':10) Else begin
       sze:=ud.filesize; if sze<1024 then
               write(bang,sze:10) else begin
                 any:=strlong(sze div 1024)+'k ';
               Write(bang,any:9);
               end;


      end;
      WriteLn(bang,' ',copy(ud.descrip,1,40));
    End;


    Begin
      Writehdr('Complete File List');
      assign (Bang,'AllList.Zip');
      if exist('allList.zip') then erase(Bang);
      assign  (bang,'AllList.Emx');

      if exist('AllList.EMX') then erase(bang);
      rewrite(bang);
          beenaborted:=False;
      start_area := curarea ;
      For cn:=1 To FileSize(afile) Do Begin
        seekafile(cn);
        Read(afile,a);
        If Allowed_in_Area(a) Then Begin
          setarea(cn);
              Begin
      done:=False;

      Repeat

        first:=False;
        beenaborted:=False;

        For cnt:=1 To FileSize(udfile) Do Begin
          seekudfile(cnt);
          Read(udfile,u);

           Begin

            If Not first Then Begin
              WriteLn(bang,'[File Section] [',area.name,'] [',curarea,']');

            first:=True;End;


            listfileb(cnt,False);


        End;

           done:=True;
        End;
        If Not first Then done:=True;
      Until done;
    End;

        End;
      End ;
      textclose(bang);
      Writehdr('List Compilation done!');
      exec ('PKZIP.EXE','-ex AllList.zip alllist.emx');
      erase(bang);
      Writestr ('[D]ownload Now or [+] Add to Batch list [D] :');
      if input='+' then Add_to_batch (0,'Alllist.zip',0) else
      download (0,'Alllist.zip',0);
{      setarea(start_area);}

    End;

  Procedure UnZipAfile;
    Var cnt:Integer;
     FS,Fs1,FSUM:LOngint;
     FF:File;
      a:arearec;
      cn,start_area : integer ;
      bang:text;
      wang:lstr;
      u:udrec;
      first:Boolean;
      done:Boolean;
      T:Char;
  Var totaltime:sstr;
      proto,num,fsize,mins:Integer;
      ud:udrec;
      zmodem,fname:lstr;
      ymodem:Boolean;
      Too,Too1:mstr;
      b:Integer;
      f:File;
      Begin
      Writehdr('Extract a file from a zip');
      assign  (bang,'ZIPFILE.ZIP');
      if exist('Zipfile.zip') then erase(bang);


    if area.downloadhere<>'Y' then exit;

      If nofiles Then exit;
       num:=getfilenum('Zip to use');
      If num=0 Then exit;
      WriteLn;
      seekudfile(num);
      Read(udfile,ud);

      If (Not sponsoron) And (((ud.points)>urec.udpoints)) Then Begin
        WriteLn('You do not have sufficient points to Slarv this file!');
        exit
      End;

      If  (ud.newfile) And (Not sponsoron) Then Begin
        WriteLn('New file and must be validated.');
        exit
      End;
      If  (ud.specialfile) And (Not sponsoron) Then Begin
        WriteLn('Downloading that file requires special permission.');
        exit
      End;
      If tempsysop Then Begin
        ulvl:=regularlevel;
        tempsysop:=False;
        writeurec;
        bottomline
      End;
   fname:=getfname(ud.path,ud.filename);
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
      If (((mins)>timeleft) And (Not sponsoron)) Then Begin
        writestr('Insufficient time to add this file.');
        exit
      End;
      If (mins-5>timetillevent) Then Begin
        writestr('No can do, net-mail is happenin in a few mins.');
        exit
      End;

      fsplit (fname,ud.path,too,too1);
      ud.filename:=too+too1;

      Writestr ('Enter the File you wish to extract :');
      if pos('-',input)>0 then input:='SORRY';
      Wang:=upstring(input);

      if not validfname (wang) then exit;
      if not validfname (wang) then wang:='sorry';
      if exist(wang) then writeln ('Cannot Extract. File already exists!');
      if exist(wang) then exit;
      exec ('PKunzip.exe',fname+' '+wang);

      if exist(wang) then begin

      Writehdr('Zipping that file!');
      exec ('PKZIP.EXE','-ex ZipFile.zip '+Wang);
            assign (ff,fname);reset(ff);
      Fs:=filesize(ff); close(ff);
      assign (ff,'ZIPFILE.ZIP'); reset(ff);{determine file sizes}
      fs1:=(filesize(ff)*100);close(ff);
     if fs=0 then fs:=1; if fs1=0 then fs1:=1;
      fsum:=fs1 div fs;
     Writeln (^M^M'FS1:',fs1,' fs:',fs,' Fsum:',fsum,^M^M);
      fs:=(fsum*ud.points) div 100;
      if fs<1 then fs:=1;
      Writeln (^B'Charge for this file ---> ',fs);

      assign (bang,wang);
      erase(bang);

      Writestr ('[D]ownload Now or [+] Add to Batch list [D] :');
      if input='+' then Add_to_batch (0,'ZIPFILE.zip',fs) else
      download (0,'ZipFile.zip',fs);
      end;
end;