 {$R-,S-,I-,D-,F+,V-,B-,N-,L+ }

  unit userret;

  Interface

  uses dos,
  gentypes,gensubs,subs1,configrt,mailret,textret;

  Procedure writeufile(Var u:userrec;n:Integer);
    Procedure writeurec;
    Procedure readurec;
    Function validuname(m:mstr):Boolean;
    Function lookupuname(n:Integer):mstr;
    Function lookupuser(Var uname:mstr):Integer;
    Function adduser(Var u:userrec):Integer;
    Procedure delallmail(n:Integer);
    Procedure deleteuser(n:Integer);
    Procedure updateuserstats(disconnecting:Boolean);
    Function postcallratio(Var u:userrec):Real;
    Function fitsspecs(Var u:userrec;Var us:userspecsrec):Boolean;

    Implementation

  Procedure writeufile(Var u:userrec;n:Integer);
    Begin
      Seek(ufile,n);
      Write(ufile,u);
      Seek(uhfile,n);
      Write(uhfile,u.handle)
    End;

  Procedure writeurec;
    Begin
      If unum<1 Then exit;
      urec.level:=ulvl;
      urec.handle:=unam;
      writeufile(urec,unum)
    End;

  Procedure readurec;
    Begin
      Seek(ufile,unum);
      Read(ufile,urec);
      ulvl:=urec.level;
      unam:=urec.handle
    End;

  Function validuname(m:mstr):Boolean;
    Var n:Integer;
    Begin
      If Length(m)>0
      Then If (m<>'?') And (m[1]<>'#') And (m[1]<>'/') And (m[Length(m)]<>'*')
        And (Not match(m,'new')) And (Not match(m,'q'))
        Then If valu(m)=0
          Then validuname:=True
          Else Begin
            validuname:=False;
            WriteLn(^B'Invalid user name!')
          End
    End;

  Function lookupuname(n:Integer):mstr;
    Var un:mstr;
    Begin
      If (n<1) Or (n>numusers) Then un:='* Unknown *' Else Begin
        Seek(uhfile,n);
        Read(uhfile,un);
        If Length(un)=0 Then un:='* User Disappeared *'
      End;
      lookupuname:=un
    End;

  Function lookupuser(Var uname:mstr):Integer;
    Var cnt,s:Integer;
      wildcarding:Boolean;
      k:Char;
      uh:mstr;
    Begin
      lookupuser:=0;
      If Length(uname)=0 Then exit;
      If uname[1]='/' Then exit;
      If uname[1]='#' Then Delete(uname,1,1);
       wildcarding:=false;
{      wildcarding:=uname[Length(uname)]='*';        }
{      If wildcarding Then uname[0]:=Pred(uname[0]); }
      If wildcarding Then exit;
      Val(uname,cnt,s);
      If (s=0) And (cnt>0) And (cnt<=numusers) Then Begin
        Seek(uhfile,cnt);
        Read(uhfile,uh);
        If Length(uh)>0 Then Begin
          lookupuser:=cnt;
          uname:=uh
        End;
        exit
      End;
      Seek(uhfile,1);
      For cnt:=1 To numusers Do
        Begin
          Read(uhfile,uh);
{          If wildcarding And (uh<>'')
          Then If match(Copy(uh,1,Length(uname)),uname)
            Then
              Begin
                Write(^B,uh,' (Y/N/X): ');
                Repeat
                  Read(k);
                  k:=UpCase(k)
                Until hungupon Or (k In ['Y','N','X']);
                WriteLn(k);
                Case UpCase(k) Of
                  'Y' :Begin
                         lookupuser:=cnt;
                         uname:=uh;
                         exit
                       End;
                  'X' :exit
                End
              End
            Else
          Else }

          If match(uh,uname)
            Then
              Begin
                lookupuser:=cnt;
                uname:=uh;
                exit
              End
        End
    End;

  Function adduser(Var u:userrec):Integer;
    Var un:userrec;
      num,cnt:Integer;
      level:Integer;
      handle:mstr;
      password:sstr;
    Label found;
    Begin
      num:=numusers+1;
      For cnt:=1 To numusers Do Begin
        Seek(ufile,cnt);
        Read(ufile,un);
        If Length(un.handle)=0 Then
          Begin
            num:=cnt;
            GoTo found
          End
      End;
      If num>maxusers Then Begin
        adduser:=-1;
        exit
      End;
      numusers:=num;
found:
      handle:=u.handle;
      level:=u.level;
      password:=u.password;
      FillChar(u,SizeOf(u),0);
      u.config:=[lowercase,eightycols,linefeeds,postprompts];
      u.udlevel:=defudlevel;
      u.udpoints:=defudpoints;
      u.emailannounce:=-1;
      u.infoform:=-1;
      u.displaylen:=25;
      u.handle:=handle;
      u.level:=level;
      u.password:=password;
      writeufile(u,num);
      adduser:=num
    End;

  Procedure delallmail(n:Integer);
    Var cnt,delled:Integer;
      m:mailrec;
      u:userrec;
    Begin
      cnt:=-1;
      delled:=0;
      Repeat
        cnt:=searchmail(cnt,n);
        If cnt>0 Then Begin
          delmail(cnt);
          cnt:=cnt-1;
          delled:=delled+1
        End
      Until cnt=0;
      If delled>0 Then WriteLn(^B'Mail deleted: ',delled);
      writeurec;
      Seek(ufile,n);
      Read(ufile,u);
      deletetext(u.infoform);
      deletetext(u.emailannounce);
      u.infoform:=-1;
      u.emailannounce:=-1;
      writeufile(u,n);
      readurec
    End;

  Procedure deleteuser(n:Integer);
    Var u:userrec;
    Begin
      delallmail(n);
      FillChar(u,SizeOf(u),0);
      u.infoform:=-1;
      u.emailannounce:=-1;
      writeufile(u,n)
    End;

  Procedure updateuserstats(disconnecting:Boolean);
    Var timeon:Integer;
    Begin
      With urec Do Begin
        timeon:=timeontoday;
        timetoday:=timetoday-timeon;
        If timetoday<0 Then timetoday:=0;
        totaltime:=totaltime+timeon;
        If tempsysop Then Begin
          ulvl:=regularlevel;
          WriteLn(Usr,'(Disabling temporary sysop powers)');
          writeurec
        End;
        If disconnecting And (numon=1) Then Begin
          If (ulvl=1) And (level2nd<>0) Then ulvl:=level2nd;
          If (udlevel=defudlevel) And (udlevel2nd<>0) Then udlevel:=udlevel2nd;
          If (udpoints=defudpoints) And (udpoints2nd<>0)
          Then udpoints:=udpoints2nd
        End;
        If Not disconnecting Then writedataarea
      End;
      writeurec
    End;

  Function postcallratio(Var u:userrec):Real;
    Begin
      If u.numon=0
      Then postcallratio:=0
      Else postcallratio:=u.nbu/u.numon
    End;

  Function fitsspecs(Var u:userrec;Var us:userspecsrec):Boolean;
    Var days:Integer;
      pcr:Real;
      thisyear,thismonth,thisday,t:word;
      lastcall:datetime;

    Function inrange(n,min,max:Integer):Boolean;
      Begin
        inrange:=(n>=min) And (n<=max)
      End;

    Begin
      unpacktime(u.laston,lastcall);
      getdate(thisyear,thismonth,thisday,t);
      days:=(thisyear-lastcall.year)*365+(thismonth-lastcall.month)*30+
      (thisday-lastcall.day);
      pcr:=postcallratio(u);
      fitsspecs:=inrange(u.level,us.minlevel,us.maxlevel) And
      inrange(days,us.minlaston,us.maxlaston) And
      (pcr>=us.minpcr) And (pcr<=us.maxpcr)
    End;

    End.
  