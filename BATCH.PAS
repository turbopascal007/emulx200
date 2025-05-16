  {$R-,S-,I-,D-,F+,V-,B-,N-,L+ }


  unit batch;

  Interface

  uses dos,crt,
  gentypes,modem,configrt,statret,windows,gensubs,subs1,subs2,userret,init;

  Function batch_download(Protocol,AllTheFiles:Integer;batchdown:batchlist):Integer;

  Implementation
Function batch_download(Protocol,AllTheFiles:Integer;batchdown:batchlist):Integer;
  Var Count:longint;

  Procedure find_and_charge(The:lstr);
    Var completebytes,kool,aa,bb,cc,cnt:Longint;
      a,b,c:anystr;
      Dood:file of byte;
      lastInLine:boolean;
    Begin
    cc:=0;
    kool:=0; if protocol=6 then kool:=4096;
    lastinline:=false;
      For cnt:=1 To AllTheFiles Do Begin
      bottomline;
        c:=batchdown[cnt].wholefilename;
        if cnt=allthefiles then lastinline:=true;
       { if Zmodem_send (c,Lastinline,kool,1)=true then } begin
        inc(cc);
       count:= count+batchdown[cnt].points;
       Writeln (usr,'Transfer Succeeded! ',c);
       Writelog (15,1,' Batch download '+c);
       assign (dood,c);reset(dood);
       completebytes:=filesize(dood);close(dood);
                 urec.kdownloaded:=urec.kdownloaded+(completebytes div 1024);
          writeurec;

       end
       {else begin
         Writeln (usr,'Transfer failed!! ',c);
         Writelog (15,1,' Batch Failed '+C);
       end;}
           End;
      batch_download:=count;
      delay(2000);
      Writeln (^M^M'Files successfully downloaded -> ',cc,' out of ',allthefiles);


    End;
  Procedure findetcharge(The:lstr);
    Var aa,bb,cc,cnt:Integer;
      a,b,c:anystr;
    Begin
      For cnt:=1 To AllTheFiles Do Begin
        c:=batchdown[cnt].wholefilename;
        If match(the,c) Then count:=count+batchdown[cnt].points Else
          If match(c,the) Then count:=count+batchdown[cnt].points;
      End;
    End;


  Procedure Then_Charge;
    Var a,b:String[255];
      cnt:Integer;
      krad:sstr;
      c,d:String[80];
      Trans:Char;
      FN,sn:String[80];
      FF:Text;
      CompleteBytes:longint;
      Junk:integer;
    Begin
      batch_download:=0;
      If Not exist('kermie') Then exit;
      batch_download:=0;

      d:='Kermie';
      Assign(ff,d);
      Reset(ff);

      Repeat
        If Not EoF(ff) Then Begin
          fn:='';
          ReadLn(ff,c);
          Trans:=c[1];
          krad:=copy (c,3,6);
          while (length(krad)>0) and (krad[1]=' ') do delete (krad,1,1);
          val (Krad,completebytes,junk);
          Delete(c,1,50);
          While (c[1]<>' ') Do Begin
          fn:=fn+c[1];Delete(c,1,1);End;While (c[1]=' ') Do Delete(c,1,1);
          sn:=c;
          WriteLn(Usr,'Code-> ',trans,' Filename -> ',fn,' Sn# -> ',sn);
          trans:=UpCase(trans);
          Writelog (15,1,' Code:'+trans+' FN:'+fn);
          If (trans='Q') or (trans='R') Or (TRans='Z') Or (Trans='S') Then findetCharge(fn);

        End;
      Until EoF(ff);textclose(ff);
      batch_download:=count;
    End;


  Procedure ExecDsz;
    Var a,b:anystr;
      qq:File;
      cnt:Integer;
    Begin
    if protocol=5 then b:='sk4.log' else b:='Kermie';
      Assign(qq,b);
      If exist(b) Then Erase(qq);
     if protocol=5 then begin
     a:='p'+strr(usecom)+' s'+strr(baudrate)+' ssb f ';


     end else begin

      a:='port '+strr(usecom)+'  s';
      If protocol=1 Then a:=a+'b -k ';
      If protocol=2 Then a:=a+'z  ';
      If protocol=3 Then a:=a+'b -g ';
      If protocol=4 Then a:=a+'z -w ';
      if protocol=6 then a:=a+'z ';
      end;
      a:=a+'@'+textfiledir+'filelist';

      Writelog (15,1,'DSZ>Began Batch');
      if protocol=5 then begin
      closeport;
      exec('superk.com',a);
      setparam(usecom,baudrate,false);

      end else execute('dsz.com',a);
      Writelog (15,2,'DSZ>DSZ returned');
      GoToXY(1,23);WriteLn(Usr,^M^M^M);
    End;

  Procedure make_list;
    Var tf:Text;
      cnt,a:Integer;
      d,e:anystr;
    Begin
      d:=textfiledir;
      d:=d+'FILELIST.';
      Assign(tf,d);
      Rewrite(tf);

      WriteLn(Usr,'All files=>',allthefiles);

      For cnt:=1 To AllTheFiles Do Begin
        d:=batchdown[cnt].wholefilename;
        WriteLn(tf,d);
        WriteLn(Usr,'Going =>',d);
      End;
      textclose(tf);
    End;

  Begin
  starttimer(numminsxfer);

    count:=0;
    batch_download:=0;

{if (externalZmodem=false) and ((protocol=6) or (protocol=4) or (protocol=2)) then  Find_And_charge('') else }
begin
    make_list;
    execdsz;
    then_charge;
end;
  stoptimer(numminsxfer);
  End;


Begin
End.



