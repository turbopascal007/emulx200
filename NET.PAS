Overlay Procedure Net_Overlay;
  var Ss:anystr;
  Chrr:char;
  Simplex:boolean;

function nextone:anystr;
var zed,one:anystr;
ct:integer;
finished:boolean;
   begin
   finished:=false;
   NEXTONE:='';
   ct:=0;
   while not finished and (ct<99) do begin
           cT:=ct+1;
                            zed:=strr(ct)+'.in';
                if not exist(UPLOADDIR+zed) then      begin
                 nextone:=zed;finished:=true;end;
                            end;
   end;


begin
modeminlock:=false;modemoutlock:=false;local:=false;
clrscr;
writeln (^M' EmuleXmodem Transfer System -- Emulex System Linkup--'^M);
ymodem:=false;super:=false;smodem:=false;kermit:=false;

repeat

repeat until (numchars>0) or (not carrier);
  chrr:=waitchar;


  if chrr='*' then begin
     clearitall;

     simplex:=protocolxfer (False,true,uploaddir+NEXTONE);
     CLEARITALL;
     if simplex then writelog (' Emulex Mail Linkup, Message Received Xmodem ')
     ELSE            writelog ('Emulex  Mail Linkup, Message Received aborted ');
                   end;


until (not carrier);

end;
