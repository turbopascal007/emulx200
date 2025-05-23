  {$R-,S-,I-,D-,F+,V-,B-,N-,L+ }

  unit statret;

  Interface

  uses gentypes,dos;

  Type systemstatus=Array[1..511] Of Byte;

  Var numcallers:Real;
    tonext:Integer;
    sysopavail:availtype;
    lastdayup:sstr;
    numdaysup,callstoday:Integer;
    numminsidle,numminsused,numminsxfer:minuterec;
    timedeventdate:sstr;
    newfeedback,newuploads,newcalls,newposts,newmail:Integer;
    TotalPosts,TotalFiles,TotalGfiles,TotalDatabase:longint;
    dummyfiller:Array[1..500] Of Byte;

    Function timer:Integer;
    Procedure starttimer(Var m:minuterec);
    Function elapsedtime(Var m:minuterec):Integer;
    Procedure stoptimer(Var m:minuterec);
    Procedure writestatus;
    Procedure readstatus;

    Implementation

  Function timer:Integer;
    Var r:registers;
    Begin
      r.ax:=$2c00;
      Intr($21,r);
      timer:=(r.cx Shr 8)*60+(r.cx And 255)
    End;

  Procedure starttimer(Var m:minuterec);
    Begin
      If m.started Then exit;
      m.startedat:=timer;
      m.started:=True
    End;

  Function elapsedtime(Var m:minuterec):Integer;
    Var n:Integer;
    Begin
      If Not m.started Then Begin
        elapsedtime:=0;
        m.startedat:=timer;
        exit
      End;
      n:=timer-m.startedat;
      If n<0 Then n:=n+1440;
      elapsedtime:=n
    End;

  Procedure stoptimer(Var m:minuterec);
    Begin
      If Not m.started Then Begin
        m.startedat:=0;
        exit
      End;
      m.startedat:=elapsedtime(m);
      m.total:=m.total+m.startedat;
      m.started:=False
    End;

  Procedure writestatus;
    Const numtimers=3;
    Type timerset=Array[1..numtimers] Of minuterec;
    Var realt:timerset Absolute numminsidle;
      t:timerset;
      cnt:Integer;
      ss:systemstatus Absolute numcallers;
      f:File Of systemstatus;
    Begin
      Assign(f,'Status');
      Rewrite(f);
      t:=realt;
      For cnt:=1 To numtimers Do
        If realt[cnt].started
        Then stoptimer(realt[cnt]);
      Write(f,ss);
      realt:=t;
      Close(f)
    End;

  Procedure readstatus;
    Var f:File Of systemstatus;
      ss:systemstatus Absolute numcallers;
    Begin
      Assign(f,'Status');
      Reset(f);
      If IOResult<>0 Then Begin
        FillChar(numcallers,511,0);
        tonext:=-1;
        sysopavail:=bytime;
        writestatus;
        exit
      End;
      Read(f,ss);
      Close(f);

    End;

  Begin
  stoptimer(numminsidle);
  stoptimer(numminsused);
  stoptimer(numminsxfer);

  End.

 �^v�  GFILEM  ANS           T�^m�  