  {$R-,S-,I-,D-,F+,V-,B-,N-,L+ }


  unit protocol;

  Interface

  uses dos,crt,
  gentypes,modem,configrt,statret,windows,gensubs,subs1,subs2,userret,init;

  Function protocolxfer(send,crcmode,ymodem:Boolean;Protocol:Integer;fn:lstr):Integer;

  { Return codes:  0=OK, 1=Cancelled within last three blocks, 2=Aborted }

  Implementation

Function protocolxfer(send,crcmode,ymodem:Boolean;Protocol:Integer;fn:lstr):Integer;
   var TimeAtXfer:longint;


  Procedure Then_Charge;
    Var a,b:String[255];
      cnt:Integer;
      c,d:String[80];
      Trans:Char;
      FN1,sn:String[80];
      CPS:sstr;
      CompleteBytes:sstr;
      junk:integer;
      num3,Num1,num2:longint;
      Errors:sstr;
      FF:Text;
      F2f:file of byte;
      Tr1,tr2:longint;
    Begin

      protocolxfer:=2;
      if (not exist('kermie')) and (not exist('sk4.log')) then exit;
      protocolxfer:=0;

    if (protocol=9) or (protocol=12) or (protocol=13) or (protocol=14)
     then d:='sk4.log' else  d:='Kermie';

    if not exist(d) then exit;
      Assign(ff,d);
      Reset(ff);
      If Not EoF(ff) Then Begin
        fn1:='';
        ReadLn(ff,c);
        Trans:=c[1];
        CompleteBytes:=copy (c,3,6);
        CPS:=copy (c,21,3);
        Errors:=copy (c,29,3);
        textclose(ff);
        Delete(c,1,50);

        While (c[1]<>' ') Do Begin
        fn1:=fn1+c[1];Delete(c,1,1);End;While (c[1]=' ') Do Delete(c,1,1);
        sn:=c;
        Writeln (usr,'DSZ>'+trans+' '+Fn1+' Bytesent->'+completeBytes);
        Writeln (usr,'DSZ>XferSecs:'+strlong(timeatXfer)+' cps:'+cps);
        {if timeatxfer>30 then timeatxfer:=timeatxfer-10;}
        tr1:=1;
        if baudrate<>0 then tr1:=(baudrate div 10);
        Tr2:=TimeAtXfer*tr1;
        Writelog (15,1,'dsz>'+trans+' File:'+fn1+' CPS:'+cps );
        Writeln ('dsz>Estimate Sent:'+strlong(tr2));

        WriteLn('Code-> ',trans,' Filename -> ',fn1,' Sn# -> ',sn);
        trans:=UpCase(trans);
        If (trans='E') Or (trans='L') Then protocolxfer:=2;

         begin
         assign (f2f,fn);
       if exist (fn) then begin
          reset(f2f);
           num2:=filesize(f2f);close(f2f); end else num2:=1;

{          if num2=0 then num2:=1;
           while (length(CompleteBytes)>0) and (completebytes[1]=' ') do
                 delete (completebytes,1,1);
           val(completebytes,num1,Junk);
           num1:=num1*100;
           if num1=0 then num1:=1;
           num3:=num1 div num2;
           Writelog (15,1,'DSZ>% complete='+strlong(num3));
           Writeln ('Percent complete=',strlong(num3));
           if num3>93 then protocolxfer:=0;}
           end;
            val(completebytes,num1,Junk);

           if send then urec.kdownloaded:=urec.kdownloaded+(num1 div 1024);
                        writeurec;


        If Not send Then If (trans='E') Or (Trans='L') Then
          If exist(fn) Then Begin
            Assign(Ff,fn);
            Erase(Ff);
          End;
          if (send=false) and (exist(fn)) then urec.kuploaded:=urec.kuploaded+(num1 div 1024);
                                               writeurec;
      End;

    End;


  Procedure ExecDsz;
    Var a,b:anystr;
      ff:File;
      cnt:Integer;
      Tota,X,Y,Z:longint;
    Begin
    if (protocol=9) or (protocol=12) or (protocol=13) or (protocol=14)
      then b:='Sk4.log' else  b:='Kermie';
        Assign(ff,b);
        If exist(b) Then Erase(ff);

{p9}
       If (protocol=9) or (protocol=12) or (protocol=13) or (protocol=14) then begin
       a:=' p'+strr(usecom)+' s'+strr(baudrate)+' ';

   if protocol=9  then    if send then a:=a+'ss f ' else a:=a+'rs f ';
   if protocol=12 then    if send then a:=a+'sk f ' else a:=a+'rk f ';
   if protocol=13 then    if send then a:=a+'sw f ' else a:=a+'rw f ';
   if protocol=14 then    if send then a:=a+'sj f ' else a:=a+'rj f ';
       a:=a+fn;



{P9}       end

else begin

      a:=' port '+strr(usecom)+'   ';
      If send Then a:=a+'s' Else a:=a+'r';
      If protocol=1 Then a:=a+'x -c ';
      If protocol=2 Then a:=a+'x -ck ';
      If protocol=3 Then a:=a+'b -k ';
      If protocol=4 Then a:=a+'z ';
      If protocol=5 Then a:=a+'b -g ';

      If protocol=6 Then a:=a+'o ';
      If protocol=7 Then a:=a+'b -ok ';
      If protocol=8 Then A:=a+'z -w ';
      If protocol=10 Then A:=a+'z -r ';
      if protocol=11 then a:=a+'z ';
      a:=a+fn;
       end;
      x:=timepart(now);

      if (protocol=9) or (protocol=12) or (protocol=13) or (protocol=14)
           then
           begin

      closeport;

           exec ('Superk.com',a) ;
           setparam(usecom,baudrate,parity);

 end else execute('dsz.com',a);

      y:=timepart(now);
      z:=y-x;if z<0 then z:=z+65535;
      TimeAtXfer:=z;
      GoToXY(1,23);WriteLn(Usr,^M^M^M);
    End;

  Procedure Proto9;
    Var a,b:anystr;
      ff:File;
      cnt:Integer;
    Begin
      b:='Kermie';
      Assign(ff,b);
      If exist(b) Then Erase(ff);

      a:=' ';      a:=a+' /B '+strr(baudrate)+' /L '+strr(usecom);

      If send Then a:=a+' /U '+fn Else a:=a+' /D '+fn;
      closeport;
      WriteLn(Usr,'Bimodem.com ',a);
{      cnt := ExecWindow('bimodem',a,1,10,80,20,TextAttr);}
      If cnt=0 Then protocolxfer:=0 Else Protocolxfer:=2;
      Assign(ff,fn);
      If send=False Then ;
       {If cnt=1 Then If exist(fn) Then Erase(ff);}

      setparam(usecom,baudrate,parity);
      GoToXY(1,23);WriteLn(Usr,^M^M^M);
    End;

var nothing:integer;
  Begin
protocolxfer:=2;
  starttimer(numminsxfer);
nothing:=0;
{if  (externalzmodem=false) and ( (send and (protocol=4)) or (protocol=11) or (protocol=8) or (protocol=10))  then begin
     closeport;
     if protocol=11 then nothing:=4096;
     transmitsize:=(5*1024);
     setparam (usecom,baudrate,parity);
     if send then if Zmodem_send (Fn,true,nothing,1)=true then protocolxfer:=0;
     if send=false then if Zmodem_Receive (fn,fn,nothing,1) then protocolxfer:=0;
     closeport;
     transmitsize:=tbuffer;
     setparam(usecom,baudrate,parity);
     end else begin}

     execdsz;
      protocolxfer:=2;
        Then_Charge;
{end}
   stoptimer(numminsxfer);

  End;


 begin
  End.



