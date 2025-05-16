


Procedure AppendBimodem(dirr:char; sendp,getdir:lstr);

var BISEX:file of birec;
    HOMO,FAG:birec;
    DUDE:nigger absolute homo;
    MR,krad,cnt:integer;
    new:boolean;

begin
    FillChar(homo,sizeof(homo),0);
    FillChar(dude,sizeof(dude),' ');
writehdr ('Adding a Bimodem file');
assign (bisex,'sam.pth');
new:=exist('sam.pth');
if not new then rewrite(bisex) else reset(bisex);
cnt:=filesize(bisex);
writeln ('Filesize=',cnt);
     homo.cmdstr:=dirr;
  for cnt:=1 to length(sendp) do    homo.sourcepath[cnt]:=sendp[cnt];
  for cnt:=1 to length(getdir) do   homo.destpath[cnt]:=getdir[cnt];
  homo.REFRESH:='N';
  homo.REPLACE:='N';
  homo.VERIFY:='N';
  homo.DELETE:='N';
  homo.DELETEABORT:='N';
  homo.DIROVERRIDE:='N';
  homo.INCLUDEDIRO:='N';
mr:=bpos+1;bpos:=mr; {Bpos=# of records in file bisex..it is an integer on mine!}
seek (bisex,bpos);
write (bisex,homo);

close(bisex);
end;

 procedure killbimodem;
  var bisex:file of birec;
  begin
   assign (bisex,'sam.pth');
   if exist('sam.pth') then erase(bisex);
   bpos:=-1;
  end;


  Function batchupload(Protocol:Integer):Integer;
    Var Count:longint;

    Procedure find_and_charge(The:lstr);
      Var aa,bb,cc,cnt:Integer;
        a,b,c:anystr;
      Begin
        inc(filesinbatch);
        cnt:=filesinbatch;
        batchdown[cnt].wholefilename:=the;
        batchdown[cnt].points:=0;
        batchdown[cnt].mins:=0;
      End;

    Procedure Then_Charge;
      Var a,b:String[255];
        cnt:Integer;
        c,d:String[80];
        Trans:Char;
        FN,sn:String[80];
        FF,qq:Text;
        krad:sstr;
        Completebytes:longint;
        Junk:integer;
      Begin
        filesinbatch:=0;

        batchupload:=0;
        if protocol=5 then d:='Sk4.log' else d:='kermie';

        If Not exist(d) Then exit;
        batchupload:=0;

        Assign(ff,d);
        Reset(ff);

        Repeat
          If Not EoF(ff) Then Begin
            fn:='';
            ReadLn(ff,c);
            Trans:=c[1];
            krad:=copy(c,3,6);
            while (length(krad)>0) and (krad[1]=' ')  do delete (krad,1,1);
            val (krad,completebytes,junk);

            Delete(c,1,50);
            While (c[1]<>' ') Do Begin
	    if c[1]='/' then c[1]:='\';
            fn:=fn+c[1];Delete(c,1,1);End;While (c[1]=' ') Do Delete(c,1,1);
            sn:=c;
            WriteLn(Usr,'Code-> ',trans,' Filename -> ',fn,' Sn# -> ',sn);
            trans:=UpCase(trans);
            if (trans='Z') or (trans='R') or (Trans='S') then urec.kuploaded:=urec.kuploaded+(completebytes div 1024);
            writeurec;
            Writelog(15,2,'Code:'+trans+' fN:'+fn);
            If (trans='R') Or (TRans='Z') Or (Trans='S') Then find_and_Charge(fn) Else
              If exist(fn) Then Begin
              Assign(qq,fn);Erase(qq);End;
          End;
        Until EoF(ff);textclose(ff);
        batchupload:=1;
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
        a:='p'+strr(usecom)+' s'+strr(baudrate)+' rsb f @';
        end else begin

        a:='port '+Strr(usecom)+' r';
        If protocol=1 Then a:=a+'b -k ';
        If protocol=2 Then a:=a+'z ';
        If protocol=3 Then a:=a+'b -g ';
        If protocol=4 Then a:=a+'z -w ';
 end;
        b:=area.xmodemdir;
        cnt:=Length(b);Delete(b,cnt,1);
        b[3]:='\';

        a:=a+b;
        starttimer(numminsxfer);

     if protocol=5 then
     begin
        closeport;

     Exec('superk.com',a);
        setparam(usecom,baudrate,parity);

     end else begin
     execute('dsz.com',a);end;
        stoptimer(numminsxfer);
        GoToXY(1,23);WriteLn(Usr,^M^M^M);
      End;


    Begin
      count:=0;
      filesinbatch:=0;
      execdsz;
      batchupload:=0;
        Then_Charge;
    End;

Function BICHARGE(allthefiles:integer;batchdown:batchlist):Integer;
  Var Count:longint;

  Procedure findetcharge(The:lstr);
    Var aa,bb,cc,cnt:Integer;
         a, b, c    :anystr;
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
      bicharge:=0;
      If Not exist('bimodem.log') Then exit;
      bicharge:=0;
      d:='bimodem.log';
      Assign(ff,d);
      Reset(ff);

      Repeat
        If Not EoF(ff) Then Begin
          fn:='';
          ReadLn(ff,c);
          Trans:=c[12];
          krad:=copy (c,3,6);

          fn:=copy (c,43,length(c));
          while ( ((pos(c,'/')>0) or (pos(c,':')>0 ))) do delete (fn,1,1);
          Writeln (' Code:'+trans+' FN:'+fn);

          If (Trans='S') Then findetCharge(fn);

        End;

      Until EoF(ff);
      textclose(ff);
      bicharge:=count;
    End;


  Begin

    count:=0;
    bicharge:=0;
    then_charge;
  End;

  Procedure beepbeep(ok:Integer);
    Begin
      Delay(500);
      Write(^B^M);
      Case ok Of
        0:Write('Done');
        1:Write('Error Recovery');
        2:Write('Aborted')
      End;
      WriteLn('!'^G^G^M)
    End;

  Function unsigned(i:Integer):Real;
    Begin
      If i>=0
      Then unsigned:=i
      Else unsigned:=65536.0+i
    End;

  Procedure writefreespace(path:lstr);
    Var drive:Byte;
      r:registers;
      csize,free,total:Real;
    Begin
      r.ah:=$36;
      r.dl:=Ord(UpCase(path[1]))-64;
      Intr($21,r);
      If r.ax=-1 Then Begin
        WriteLn('Invalid drive');
        exit
      End;
      csize:=unsigned(r.ax)*unsigned(r.cx);
      free:=csize*unsigned(r.bx);
      total:=csize*unsigned(r.dx);
      if free < 1024*1024 then
         Write (^S, free/1024:0:0 , ^R'KB out of ' )
      else
         Write (^S, free/(1024*1024):0:0 , ^R'MB out of ' ) ;
      if total < 1024*1024 then
         WriteLn (^S, total/1024:0:0 ,^R+'KB' )
      else
         WriteLn (^S, total/(1024*1024):0:0 , ^R'MB' ) ;
      If free/1024<100.0 Then WriteLn(^G^S'*** Danger! Limited file space left!');
    End;

  Procedure seekafile(n:Integer);
    Begin
      Seek(afile,n-1)
    End;

  Function numareas:Integer;
    Begin
      numareas:=FileSize(afile)
    End;

  Procedure seekudfile(n:Integer);
    Begin
      Seek(udfile,n-1)
    End;

  Function numuds:Integer;
    Begin
      numuds:=FileSize(udfile)
    End;

  Procedure assignud;
    Begin
      Close(udfile);
      Assign(udfile,'AREA'+strr(curarea))
    End;

  Function sponsoron:Boolean;
    Begin
      sponsoron:=match(area.sponsor,unam) Or issysop
    End;

  Function PCRatio:Boolean;
    Var cnt,a,b,c:Longint;
      SlarvDodE:Boolean;
    Begin
      pcratio:=False;
      slarvdode:=False;
      If PCR=0 Then slarvdode:=True;

      If slarvdode=True Then Else slarvdode:=False;

      If urec.numon>0 Then cnt:=(urec.nbu*100) Div urec.numon;

      If (urec.numon<2) And (cnt<pcr) Then slarvdode:=True;

      If ((vt52 in urec.config) or   (ansigraphics In urec.config)) And (urec.emulation=0) Then Begin
        clearbreak;dontstop:=True;nobreak:=True;
        Ansiwindow(5,5,25,12);
        ansigotoxy(10,5);Write(^R'[PCR Ratio]');
        Ansigotoxy(7,7);Write(^R'# of Posts :'^S,urec.nbu);
        ansigotoxy(7,8);Write(^R'# of Calls :'^S,urec.numon);
        Ansigotoxy(7,9);Write(^R'PCR Ratio  :'^S,cnt,'%');
      End Else Begin
        ansigotoxy(10,5);WriteLn('[PCR Ratio]');
        WriteLn('# of Posts :',urec.nbu);
        WriteLn('# of Calls :',urec.numon);
        WriteLn('PCR Ratio  :',cnt,'%'^M^M);

      End;

      If cnt<PCR Then Begin
        If sponsoron Or (ulvl>=PCRExempt) Then Begin
          Ansigotoxy(7,10);Write(^S'Exempt from PCR');slarvdode:=True;
        End Else Begin
          Ansigotoxy(7,10);Write(^S'PCR Ratio TOO LOW!');
        End;

      End Else Begin
        Ansigotoxy(7,10);slarvdode:=True;
        Write(^R'Min. PCR   :'^S,PCR,'%');
      End;
      Ansigotoxy(1,17);

      pcratio:=slarvdode;
    End;
