overlay function protocolxfer (send,crcmode:boolean; fn:lstr):boolean;

  Function FindLine(comp,abt:lstr):boolean;
  var tfile:text;
      b:anystr;
      done,i:boolean;
  begin
    findline:=false;
    if exist ('complete') then begin
      Assign(tfile,'complete');
      Reset(tfile);
      While not EOF(tfile) and (Not I) and (not Done) do
      Begin
        ReadLn(tfile,B);
        if (Pos(upcase(abt),upcase(B))>0) and (abt<>'') then begin
          done:=true;
          i:=false;
        end;
        If (Pos(upcase(comp), upcase(B))>0) and (comp<>'') then begin
          i:= True;
          done:=true;
        end;
        FindLine:=i;
      End;
      textclose (tfile);
    end;
  end;

  procedure SetupXFer(prot:mstr; CmdLine:lstr; Send:boolean);
  var fil:file;
  begin
    writeln(usr,' -- ',prot,' Invoked ');
    write(prot);
    if send then write(' Send ') else write(' Receive ');
    writeln('Invoked.');
    starttimer(numminsxfer);
    assign(fil,'kermie');
    if exist('kermie') then erase(fil);
    if Zmodem and not send then begin
      clearitall;
      delay(2000);
      clearitall;
      repeat until hungupon or (numchars>0);
    end;
    uninit;
    dos_shell(CmdLine);
    if hungupon then exit;
    setparam(usecom,baudrate,parity);
  end;

  Function SendKermit:boolean;
  var Haleh:anystr;
  begin
    starttimer(numminsxfer);
    haleh:='kermit send '+fn+' >complete';
    SetupXfer('Super Kermit',haleh,true);
    SendKermit:=FindLine('100%','Failed');
    stoptimer (numminsxfer);
  end;

  Function ReceiveKermit:boolean;
  var Haleh:anystr;
  begin
    starttimer(numminsxfer);
    haleh:='kermit receive '+fn+' >complete';
    SetupXfer('Super Kermit',haleh,false);
    ReceiveKermit:=FindLine('100%','Failed');
    stoptimer (numminsxfer);
  end;

  Function SendXYModem(ymdm:boolean):boolean;
  var Haleh:anystr;
      Chksum:anystr;
  begin
    starttimer(numminsxfer);
    haleh:='zmodem sx ';
    if ymdm then haleh:=haleh+'-k ';
    haleh:=haleh+fn;
    if ymdm then ChkSum:='YModem-CRC' else Chksum:='XModem-';
    if crcmode and not ymdm then
      Chksum:=Chksum+'CRC' else Chksum:=Chksum+'Checksum';
    SetupXfer(Chksum,haleh,true);
    SendXYModem:=Exist('Complete');
    stoptimer (numminsxfer);
  end;

  Function ReceiveXYModem:boolean;
  var Haleh:anystr;
  begin
    starttimer(numminsxfer);
    haleh:='zmodem rx ';
    if crcmode then haleh:=haleh+'-c ';
    haleh:=haleh+fn;
    SetupXfer('X/YModem Receive',haleh,false);
    ReceiveXYModem:=Exist('Complete');
    stoptimer (numminsxfer);
  end;

  Function SendZmodem:boolean;
  var Haleh:anystr;
  begin
    starttimer(numminsxfer);
    haleh:='zmodem sz '+fn;
    SetupXfer('Zmodem',haleh,true);
    SendZmodem:=exist('Complete');
    stoptimer (numminsxfer);
  end;

  function ReceiveZmodem:boolean;
  var Haleh:anystr;
  begin
    starttimer(numminsxfer);
    haleh:='zmodem rz '+fn;
    SetupXfer('Zmodem',haleh,false);
    ReceiveZmodem:=Exist('Complete');
    stoptimer (numminsxfer);
  end;

  function SendWxmodem:boolean;
  var Haleh:anystr;
  begin
    starttimer(numminsxfer);
    haleh:='wxterm S '+fn+' '+strr(baudrate);
    SetupXfer('WXModem',haleh,true);
    stoptimer (numminsxfer);
  end;

  Function ReceiveWxmodem :boolean;
  var Haleh:anystr;
  begin
    starttimer(numminsxfer);
    haleh:='wxterm R '+fn+' '+strr(baudrate);
    SetupXfer('WXModem',haleh,false);
    if exist ('complete') then ReceiveWxmodem:=true;
    stoptimer (numminsxfer);
  end;

begin

  If Wxmodem then if Send then protocolxfer:=SendWxmodem else
    protocolxfer:=ReceiveWxmodem;

{  If YmodemG then if Send then protocolxfer:=SendXYModem(true) else
    protocolxfer:=ReceiveXYModem(true); }

  If Zmodem then if Send then protocolxfer:=SendZmodem else
    protocolxfer:=ReceiveZmodem;

  if Kermit then if Send then protocolxfer:=SendKermit else
    protocolxfer:=ReceiveKermit;

  if not Kermit and not Wxmodem and not Zmodem then
    if Send then protocolxfer:=SendXYModem(ymodem)
      else protocolxfer:=ReceiveXYModem;

  Ymodem:=false;
  Zmodem:=false;
  Wxmodem:=false;
  Kermit:=false;
  CLink:=false;
  YModemG:=false;

end;
                              