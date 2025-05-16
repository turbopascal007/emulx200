overlay procedure showsystemstatus;
var totalused,totalidle,totalup,totaldown,totalmins,callsday,
    total_disk,total_free,file_sizes:real;
    total_files:integer;

  Procedure FileSZ;
  var cnt,cnt2,curarea:integer;
      ar,area:arearec;
      ud:udrec;
      Inscan,showit,fast:boolean;
      Drv:array[1..15] of boolean;

  procedure assignud;
  begin
    close (udfile);
    assign (udfile,'AREA'+strr(curarea))
  end;

  const beenaborted:boolean=false;

  function aborted:boolean;
  begin
    if beenaborted then begin
      aborted:=true;
      exit
    end;
    aborted:=xpressed or hungupon;
    if xpressed then begin
      beenaborted:=true;
      writeln (^B'File Calcuation aborted..')
    end
  end;

  procedure setarea (n:integer);
  begin
    curarea:=n;
    seek(afile,n-1);
    read (afile,area);
    assignud;
    close (udfile);
    reset (udfile);
    if ioresult<>0 then rewrite (udfile);
  end;

  Procedure CheckDrive(dv:char);
  var n:byte;
      Temp_Disk,Temp_Free:real;

    procedure WriteFreeSpace (dr:byte);
    var r:regs;
        csize:real;

      function unsigned (i:integer):real;
      begin
        if i>=0 then unsigned:=i else unsigned:=65536.0+i
      end;

    begin
      r.ah:=$36;
      r.dl:=dr;
      intr ($21,r);
      if r.ax=-1 then exit;
      csize:=unsigned(r.ax)*unsigned(r.cx);
      Temp_Free:=(csize*unsigned(r.bx))/1000;
      Temp_Disk:=(csize*unsigned(r.dx))/1000;
    end;

  begin
    if (ord(dv)<65) or (ord(dv)>79) then exit;
    n:=ord(dv)-64;
    writefreespace(n);
    if not Drv[n] then begin
      Drv[n]:=true;
      Total_Disk:=Total_Disk+Temp_Disk;
      Total_Free:=Total_Free+Temp_Free;
    end;
  end;

  function getfname (path:lstr; name:mstr):lstr;
  var l:lstr;
  begin
    l:=path;
    if length(l)<>0 then if not (upcase(l[length(l)]) in [':','\'])
      then l:=l+'\';
    l:=l+name;
    getfname:=l
  end;

  begin
    total_files:=0;
    file_sizes:=0;
    total_disk:=0;
    Total_Free:=0;
    for cnt:=1 to 15 do Drv[Cnt]:=false;
    assign (afile,'AreaDir');
    if exist ('Areadir') then begin
      reset (afile);
      if filesize (afile)<0 then exit
    end else rewrite (afile);
    cnt:=1;
    while (cnt<=filesize(afile)) do begin
      seek (afile,cnt-1);
      read (afile,ar);
      CheckDrive(upcase(ar.xmodemdir[1]));
      setarea (cnt);
      for cnt2:=filesize(udfile) downto 1 do begin
        Seek (udfile,cnt2-1);
        read (udfile,ud);
        CheckDrive(upcase(ud.path[1]));
        if aborted then begin
          Total_Files:=0;
          File_Sizes:=0;
          Total_Disk:=0;
          Total_Free:=0;
          exit;
        end;
        if exist(getfname(ud.path,ud.filename)) then begin
          Total_Files:=Total_Files+1;
          File_Sizes:=File_Sizes+ud.filesize;
        end;
      end;
      cnt:=cnt+1;
    end;
    File_Sizes:=File_Sizes/1000;
    write(usr,'Drives Online: ');
    for cnt:=1 to 15 do if Drv[cnt] then write (usr,chr(cnt+64),' ');
  end;

  procedure percent (prompt:mstr; top,bot:real);
  var p:real;
  begin
    write (prompt);
    if bot<1 then begin
      writeln (' Not Available');
      exit
    end;
    p:=round(10000*top/bot)/100;
    writeln (p:6:2,'%')
  end;

begin
  totalused:=numminsused.total+elapsedtime(numminsused);
  totalidle:=numminsidle.total;
  totalup:=totalidle+numminsused.total;
  totalmins:=1440.0*(numdaysup-1.0)+timer;
  totaldown:=totalmins-totalup;
  callsday:=round(10*numcallers/numdaysup)/10;
  writeln('Hold.. Calculating..');
  writeln;
  FileSZ;
  writehdr ('System Statistics...');
  writeln(^B^B^B);
  writeln ('Time & date:       '^S,timestr,', ',datestr,
       ^M^J'Calls today:       '^S,callstoday:7,
       ^M^J'Total callers:     '^S,numcallers:7:0,
       ^M^J'Total days up:     '^S,numdaysup:7,
       ^M^J'Calls per day:     '^S,callsday:7:1,
       ^M^J'Total mins in use: '^S,numminsused.total:7:0,
       ^M^J'Total mins idle:   '^S,totalidle:7:0,
       ^M^J'Mins file xfer:    '^S,numminsxfer.total:7:0,
       ^M^J'Total mins up:     '^S,totalup:7:0,
       ^M^J'Total mins down:   '^S,totaldown:7:0);
  percent ('Pct used:          '^S,totalused,totalmins);
  percent ('Pct dead:          '^S,totalidle,totalmins);
  percent ('Pct up:            '^S,totalup,totalmins);
  percent ('Pct down:          '^S,totaldown,totalmins);
  writeln( 'Files Online:      '^S,total_files:7,
       ^M^J'Files Storage:     '^S,File_Sizes/1000:7:3,' megs',
       ^M^J'Total Storage:     '^S,Total_Disk/1000:7:3,' megs',
       ^M^J'Upload Space:      '^S,Total_Free/1000:7:3,' megs');
  percent ('Pct Space Unused:  '^S,total_free,total_disk);
  percent ('Pct Space Used:    '^S,(total_disk-Total_Free),Total_disk);
  percent ('Pct Storage Online:'^S,file_sizes,total_disk);
end;
