Overlay Procedure Pnet_Send;
  var Ss:anystr;
  Chrr:char;
  Simplex:boolean;
  jo:integer;
  finished:boolean;

procedure getitall;
begin
{while numchars>0 do Write (getchar);}
end;

procedure send(xx:anystr);
var cnt:integer;
 begin
        for cnt:=1 to length(xx) do begin
             sendchar (xx[cnt]);write (usr,xx[cnt]);end;
 end;

PROCEDure send_The_file (xx:lstr);
var dummm:boolean;
jo:text;
begin
   Writeln (Usr,' þ Je fourre les filles! ');
   ymodem:=false;super:=false;wxmodem:=false;kermit:=false;zmodem:=false;
   delay (3000);
   clearitall;
   dummm:=false;
   repeat until (numchars>0) or hungupon or keypressed;

    dummm:=protocolxfer(true,true,uploaddir+xx);

    assign (jo,uploaddir+xx);

    if dummm then erase (jo);

    IF dummm then Writeln (USR,^M' þ EmuMail Transfer Successful!')
             ELSE Writeln (USR,^M' þ EmuMail Transfer Failed?!?!?');

    clearitall;
end;


procedure once_got_carrier;
begin
writeln (usr,' þ Ah Ben!, ici la Carriere! ');
online:=true;
delay (999);
send (^M^M^M^M^M^M^M^M^M'       ');
delay (6000);
send (^H^H^H^H^H);
Delay (200);
send ('PNET-FILE'+#13);
delay (500);
if carrier then send ('***************');
writeln (usr,' þ Donnez la lettre!');
end;

Function There_is_any_mail:boolean;
var zed,one,NEXTONE:anystr;
ct:integer;
joe:text;
finished:boolean;
   begin
   Writeln (USR,' þ Est-ce-qu''il y est les lettres pour aller?');
   There_Is_any_mail:=false;
   NEXTONE:='';
   ct:=0;
   repeat
           cT:=ct+1;
           zed:=strr(ct)+'.out';
           if exist(uploaddir+zed) then begin
           there_is_any_mail:=true;
           write (usr,zed+',');END;

       until (ct>30);

   end;


Function call (var number:anystr):boolean;
begin
Setparam(1,1200,FALSE);
Writeln (usr,^M' þ Je Telephone ',number,' Tapez une key a abortement!');

online:=false;
ss:=number;
if ss='' then exit;
if  keypressed then  read (kbd,Chrr);

doanswer;delay (200);
send ('      ');delay(500);
send ('ATDT'+extender+ss+#13);
jo:=0;
FINISHED:=FALSE;

repeat
     jo:=jo+1;
     delay(1);
     if keypressed then finished:=true;
     if carrier then finished:=true;
    until finished or (jo>18000);
send (^M);
call:=carrier;
end;

procedure SEND_THE_MAIL;
var zed,one,NEXTONE:anystr;
ct:integer;
joe:text;
Going:anystr;
finished:boolean;
   begin
writeln (usr,^M' þ Beginning Mail Search and Delivery routines.');

   finished:=false;
   NEXTONE:='';
   ct:=0;

   repeat
           cT:=ct+1;
           zed:=strr(ct)+'.out';
           if exist(uploaddir+zed) then begin
                      write (usr,zed+',');

                                        assign (joe,uploaddir+zed);
                                        reset (joe);
                                        readln (joe,Going);
                                        close (joe);

                    if Call (Going) then begin
                     once_got_Carrier;
                     Send_The_File (zed);
                     disconnect;
                     online:=false;
                     delay (500);send (^M'  ');
                     Writeln (usr,^M' þ SAMMY''Z est cool!');
                     end;
                 nextone:=zed;
                  end;
       until ct>30;
   end;


begin
modeminlock:=false;modemoutlock:=false;local:=false;
window (1,1,80,25);
clrscr;
gotoxy (1,1);WRite (USR,'EmuMail 1.01 (tm) Emulex BBS Software.');
window (1,2,80,25);gotoxy (1,1);
clrscr;
if there_is_any_mail then begin
             send ('     ');delay (500);send ('ATS0=0'^M);
             Send_The_Mail;
             if carrier then disconnect;
             Writeln (usr,' þ EmuMail est completement! Retournerez a la bbs!');
             send (^M^M^M'   ');
             delay (200);
             send ('ATS0=1'^M);
             Async_Close;
             Halt(0);

       end else begin
          Writeln (usr,^M' þ Rien de lettres!,je retournera a la bbs!');
          Async_Close;
          Halt(0);
          End;
end;
