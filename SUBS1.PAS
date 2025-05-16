  {$R-,S-,I-,D-,F+,V-,B-,N-,L+ }

  unit subs1;

  Interface

  uses crt,dos,
  gensubs,gentypes,statret,configrt,modem;

  Var firstvariable:Byte;

    local,online,chatmode,disconnected:Boolean;

    unum,ulvl,baudrate:Integer;
    unam:mstr;
    baudstr:sstr;
    parity:Boolean;
    urec:userrec;

    logontime,logofftime,logonunum:Integer;
    laston:longint;

    dots,nochain,break,xpressed,
    requestchat,requestcom,requestbreak,reqspecial,forcehangup,
    modeminlock,modemoutlock,timelock,tempsysop,splitmode,
    fromdoor,texttrap,printerecho,uselinefeeds,usecapsonly,
    dontstop,nobreak,wordwrap,beginwithspacesok,sysnext,ingetstr:Boolean;
    regularlevel,numusers,curboardnum,lasty,
    linecount,curattrib,
    firstfree,lockedtime,iocode,BufLen:Integer;
    screenseg:word;
    cursection:configtype;
    curboardname:sstr;
    Input,chainstr:anystr;
    chatreason,lastprompt,errorparam,errorproc:lstr;
    curboard:boardrec;
    mes:message;
    syslogdat:Array[0..maxsyslogdat] Of syslogdatrec;
    numsyslogdat:Integer;
    returnto:Char;

    PCBMover:lstr;
    Double_check:boolean;
    lastvariable:Byte;
    Usr,direct,directin:Text;

  Const numsysfiles=20;
  Var tfile:File Of buffer;
    mapfile:File Of Integer;
    ufile:File Of userrec;
    uhfile:File Of mstr;
    mfile:File Of mailrec;
    udfile:File Of udrec;
    afile:File Of arearec;
    bfile:File Of bulrec;
    bdfile:File Of boardrec;
    bifile:File Of sstr;
    ffile:File Of filerec;
    tofile:File Of topicrec;
    chfile:File Of choicerec;
    ddfile:File Of baserec;
    efile:File Of entryrec;
    dofile:File Of doorrec;
    gfile:File Of grouprec;
    logfile:File Of logrec;
    usfile:File Of userspecsrec;
    sysfiles:Array[1..numsysfiles] Of File Absolute tfile;
        blfile:file of bbsrec;

    ttfile:Text;
 var sysfi:fib absolute logfile;

    Procedure writelog(m,s:Integer;prm:lstr);
    Procedure files30;
    Function ioerrorstr(num:Integer):lstr;
    Procedure error(errorstr,proc,param:lstr);
    Procedure fileerror(procname,filename:mstr);
    Procedure che;
    Function timeleft:Integer;
    Function timetillevent:Integer;
    Procedure settimeleft(tl:Integer);
    Procedure tab(n:anystr;np:Integer);
    Function yes:Boolean;
    Function yesno(b:Boolean):sstr;
    Function timeontoday:Integer;
    Function isopen(Var ff):Boolean;
    Procedure textclose(Var f:Text);
    Procedure Close(Var ff);
    Function withintime(t1,t2:sstr):Boolean;
    Function hungupon:Boolean;
    Function sysopisavail:Boolean;
    Function sysopavailstr:sstr;
    Function singularplural(n:Integer;m1,m2:mstr):mstr;
    Function s(n:Integer):sstr;
    Function numthings(n:Integer;m1,m2:mstr):lstr;
    Procedure thereisare(n:Integer);
    Procedure thereare(n:Integer;m1,m2:mstr);
    Procedure assignbdfile;
    Procedure openbdfile;
    Procedure formatbdfile;
    Procedure closebdfile;
    Procedure opentempbdfile;
    Procedure closetempbdfile;
    Function keyhit:Boolean;
    Function bioskey:Char;
    Procedure readline(Var xx);
    Procedure writereturnbat;
    Procedure ensureclosed;
    Procedure clearbreak;
    Procedure ansicolor(attrib:Integer);
    Procedure ansireset;
    Procedure specialmsg(q:anystr);
    Procedure writedataarea;
    Procedure readdataarea;
    procedure Wvt52(T:anystr);
    Implementation


  Procedure writelog(m,s:Integer;prm:lstr);
    Var n:Integer;
      l:logrec;
    Begin

      With l Do Begin
        menu:=m;
        subcommand:=s;
        when:=now;
        param:=Copy(prm,1,41)
      End;
      Seek(logfile,FileSize(logfile));
      Write(logfile,l);
    End;

  Procedure files30;
    Begin
      WriteLn(Usr,'You MUST put FILES=30 in your CONFIG.SYS!');
      Halt(4)
    End;

  Function ioerrorstr(num:Integer):lstr;
    Var tf:Text;
      tmp:lstr;
      n,s:Integer;
    Begin
      If num=243 Then files30;
      Assign(tf,'Ioerror.lst');
      Reset(tf);
      If IOResult<>0 Then Begin
        ioerrorstr:='* Can''t open IOERROR.LST *';
        exit
      End;
      While Not EoF(tf) Do Begin
        ReadLn(tf,tmp);
        Val(tmp,n,s);
        If n=num Then Begin
          ioerrorstr:=tmp;
          textclose(tf);
          exit
        End
      End;
      textClose(tf);
      ioerrorstr:='Unidentified I/O error '+strr(num)
    End;

  Procedure error(errorstr,proc,param:lstr);
    Var p,n:Integer;
      pk:Char;
      tf:Text;
    Begin
      n:=IOResult;
      Repeat
        p:=Pos('%',errorstr);
        If p<>0 Then Begin
          pk:=errorstr[p+1];
          Delete(errorstr,p,2);
          Case UpCase(pk) Of
            '1' :Insert(param,errorstr,p);
            'P' :Insert(proc,errorstr,p);
            'I' :Insert(ioerrorstr(iocode),errorstr,p)
          End
        End
      Until p=0;
      Assign(tf,'ErrLog');
      Append(tf);
      If IOResult<>0
      Then
        Begin
          textclose(tf);
          Rewrite(tf) ;
          n := ioresult ;
        End;
      WriteLn(tf,unam,' was on-line on ',datestr(now),' at ',timestr(now),' when:');
      WriteLn(tf,errorstr);
      WriteLn(tf);
      textClose(tf);
      n:=IOResult;
      writelog(0,4,errorstr);
      WriteLn(Usr,errorstr+^M^M)
    End;

  Procedure fileerror(procname,filename:mstr);
    Begin
      error('%I accessing %1 in %P',procname,filename)
    End;

  Procedure che;
    Var i:Integer;
    Begin
      i:=IOResult;
      Case i Of
        0:;
        4:files30;
      Else
        Begin
          iocode:=i;
          error('Unexpected I/O error %I','','')
        End
      End
    End;

  Function timeleft:Integer;
    Var timeon:Integer;
    Begin
      timeon:=timer-logontime;
      If timeon<0 Then timeon:=timeon+1440;
      timeleft:=urec.timetoday-timeon
    End;

  Function timetillevent:Integer;
    Var Krad,n:Longint;

    Begin
    krad:=timer;
      If (Length(eventtime)=0) or (timedeventdate=datestr(now))
      Then n:=1440
      Else n:=(timeval(eventtime))-krad;
      If n<0 Then n:=n+1440;
      timetillevent:=n
    End;

  Procedure settimeleft(tl:Integer);
    Begin
      urec.timetoday:=timer+tl-logontime
    End;

  Procedure tab(n:anystr;np:Integer);
    Var cnt:Integer;
    Begin
      Write(n);
      If (ansigraphics In urec.config) And ((np)-Length(n)>4) Then Begin

        cnt:=np-Length(n);
        Write(direct,#27'['+strr(cNt)+'C');
      End Else
        For cnt:=Length(n) To np-1 Do Write(' ')
    End;

  Function yes:Boolean;
    Begin
      If Length(Input)=0
      Then yes:=False
      Else yes:=UpCase(Input[1])='Y'
    End;

  Function yesno(b:Boolean):sstr;
    Begin
      If b
      Then yesno:='Yes'
      Else yesno:='No'
    End;

  Function timeontoday:Integer;
    Var timeon:Integer;
    Begin
      timeon:=timer-logontime;
      If timeon<0 Then timeon:=timeon+1440;
      timeontoday:=timeon
    End;

  Function isopen(Var ff):Boolean;
    Var fi:fib Absolute ff;
    Begin
      isopen:=fi.handle<>0
    End;

  Procedure textclose(Var f:Text);
    Var n:Integer;
      fi:fib Absolute f;
    Begin
      system.close(f);
      n:=IOResult
    End;

  Procedure Close(Var ff);
    Var f:File Absolute ff;
      fi:fib Absolute ff;
      n:Integer;
    Begin
       system.close(f);
       n:=IOResult
    End;

  Function withintime(t1,t2:sstr):Boolean;
    Var t,a,u:Integer;
    Begin
      t:=timer;
      a:=timeval(t1);
      u:=timeval(t2);
      If a<=u
      Then withintime:=(t>=a) And (t<=u)
      Else withintime:=(t>=a) Or (t<=u)
    End;

  Function hungupon:Boolean;
    Begin
      hungupon:=forcehangup Or
      (online And Not(carrier Or modeminlock Or modemoutlock))
    End;

  Function sysopisavail:Boolean;
    Begin
      Case sysopavail Of
        available:sysopisavail:=True;
        notavailable:sysopisavail:=False;
        bytime:sysopisavail:=withintime(availtime,unavailtime);
      End
    End;

  Function sysopavailstr:sstr;
    Const strs:Array[available..notavailable] Of String[9]=
      ('Yes','By time: ','No');
    Var tstr:sstr;
      tmp:availtype;
    Begin
      tstr:=strs[sysopavail];
      If sysopavail=bytime
      Then
        Begin
          If sysopisavail
          Then tmp:=available
          Else tmp:=notavailable;
          tstr:=tstr+strs[tmp]
        End;
      sysopavailstr:=tstr
    End;

  Function singularplural(n:Integer;m1,m2:mstr):mstr;
    Begin
      If n=1
      Then singularplural:=m1
      Else singularplural:=m2
    End;

  Function s(n:Integer):sstr;
    Begin
      s:=singularplural(n,'','s')
    End;

  Function numthings(n:Integer;m1,m2:mstr):lstr;
    Begin
      numthings:=strr(n)+' '+singularplural(n,m1,m2)
    End;

  Procedure thereisare(n:Integer);
    Begin
      Write('There ');
      If n=1
      Then Write('is 1 ')
      Else
        Begin
          Write('are ');
          If n=0
          Then Write('no ')
          Else Write(n,' ')
        End
    End;

  Procedure thereare(n:Integer;m1,m2:mstr);
    Begin
      thereisare(n);
      If n=1
      Then Write(m1)
      Else Write(m2);
      WriteLn('.')
    End;

  Procedure assignbdfile;
    Begin
      Assign(bdfile,boarddir+'boarddir');
      Assign(bifile,boarddir+'bdindex')
    End;

  Procedure openbdfile;
    Var i:Integer;
    Begin
      closebdfile;
      assignbdfile;
      Reset(bdfile);
      i:=IOResult;
      Reset(bifile);
      i:=i Or IOResult;
      If i<>0 Then formatbdfile
    End;

  Procedure formatbdfile;
    Begin
      Close(bdfile);
      Close(bifile);
      assignbdfile;
      Rewrite(bdfile);
      Rewrite(bifile)
    End;

  Procedure closebdfile;
    Begin
      Close(bdfile);
      Close(bifile)
    End;

  Var wasopen:Boolean;

  Procedure opentempbdfile;
    Begin
      wasopen:=isopen(bdfile);
      If Not wasopen Then openbdfile
    End;

  Procedure closetempbdfile;
    Begin
      If Not wasopen Then closebdfile
    End;

  Function keyhit:Boolean;
    Var r:registers;
    Begin
      r.ah:=1;
      Intr($16,r);
      keyhit:=(r.flags And 64)=0
    End;

  Function bioskey:Char;
    Var r:registers;
    Begin
      r.ah:=0;
      Intr($16,r);
      If r.al=0
      Then bioskey:=Chr(r.ah+128)
      Else bioskey:=Chr(r.al)
    End;

  Procedure readline(Var xx);
    Var a:anystr Absolute xx;
      l:Byte Absolute xx;
      k:Char;

    Procedure backspace;
      Begin
        If l>0 Then Begin
          Write(Usr,^H,' ',^H);
          l:=l-1
        End
      End;

    Procedure eraseall;
      Begin
        While l>0 Do backspace
      End;

    Procedure addchar(k:Char);
      Begin
        If l<BufLen Then Begin
          l:=l+1;
          a[l]:=k;
          Write(Usr,k)
        End
      End;

    Begin
      l:=0;
      Repeat
        k:=bioskey;
        Case k Of
          #8:backspace;
          #27:eraseall;
          #32..#126:addchar(k)
        End
      Until k=#13;
      WriteLn(Usr)
    End;

  Procedure writereturnbat;
    Var tf:Text;
      bd:Integer;
      tmp:lstr;
    Begin
      Assign(tf,'return.bat');
      Rewrite(tf);
      GetDir(0,tmp);
      WriteLn(tf,'cd '+tmp);
      If unum=0
      Then Begin
        WriteLn(tf,'PAUSE   ***  No one was logged in!');
        WriteLn(tf,'keepup')
      End Else Begin
        If online Then bd:=baudrate Else bd:=0;
        WriteLn(tf,'keepup ',unum,' ',bd,' ',Ord(parity),' M')
      End;
      textclose(tf);
    End;

  Procedure ensureclosed;
    Var cnt,i:Integer;
    Begin
      stoptimer(numminsidle);
      stoptimer(numminsused);
      writestatus;
      textclose(ttfile);
      i:=IOResult;
      For cnt:=1 To numsysfiles Do Begin
        Close(sysfiles[cnt]);
        i:=IOResult
      End
    End;

  Procedure clearbreak;
    Begin
      break:=False;
      xpressed:=False;
      dontstop:=False;
      nobreak:=False
    End;

  procedure WVT52(t:anystr);
  var cnt:integer;
  begin
  if modemoutlock then exit;
   if t[2]=#234 then delete (t,1,1);
   for cnt:=1 to length(t) do sendchar (t[cnt]);
  end;

  Procedure ansicolor(attrib:Integer);
    Var tc:Integer;
    Const colorid:Array[0..7] Of Byte=(30,34,32,36,31,35,33,37);
    Begin
      If attrib=0 Then attrib:=1;

      If attrib=0 Then Begin
        TextColor(7);
        textbackground(0)
      End Else Begin
        TextColor(attrib And $8f);
        textbackground((attrib Shr 4) And 7)
      End;

 {     curattrib:=attrib;        }

      if vt52 in urec.config then
      if attrib<>curattrib then wvt52(#234+#234+#07+chr(attrib));

      If (ansigraphics in urec.config) and (attrib<>curattrib) Then begin
        If Not(ansigraphics In urec.config) Then exit;

      Write(direct,#27'[0');
      tc:=attrib And 7;
      If tc<>7 Then Write(direct,';',colorid[tc]);
      tc:=(attrib Shr 4) And 7;
      If tc<>0 Then Write(direct,';',colorid[tc]+10);
      If (attrib And 8)=8 Then Write(direct,';1');
      If (attrib And 128)=128 Then Write(direct,';5');
      Write(direct,'m');
      curattrib:=attrib;
      end;
    End;

  Procedure ansireset;
    Begin
{      TextColor(7);
      textbackground(0);}
        ansicolor(urec.regularcolor);
    End;

  Procedure specialmsg(q:anystr);
    Begin
      TextColor(outlockcolor);
      textbackground(0);
      WriteLn(Usr,q);
      If Not modemoutlock Then TextColor(normbotcolor)
    End;

  Procedure readdataarea;
    Var f:File Of Byte;
    Begin
      Assign(f,'Emulex.dat');
      Reset(f);
      If IOResult<>0
      Then unum:=-1
      Else Begin
        dos.filerec(f).recsize:=Ofs(lastvariable)-Ofs(firstvariable);
        Read(f,firstvariable);
        Close(f)
      End
    End;

  Procedure writedataarea;
    Var f:File Of Byte;
    Begin
      Assign(f,'Emulex.dat');
      Rewrite(f);
      dos.filerec(f).recsize:=Ofs(lastvariable)-Ofs(firstvariable);
      Write(f,firstvariable);
      Close(f)
    End;


  Begin
    End.
