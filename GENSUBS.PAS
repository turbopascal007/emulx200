  {$R-,S-,I-,D-,F+,V-,B-,N-,L+ }
  unit gensubs;

  Interface

  uses dos,gentypes;

  Function strr(n:Integer):mstr;
  Function streal(r:Real):mstr;
  Function strlong(l:longint):mstr;
  Function valu(q:mstr):Integer;
  Function addrstr(p:pointer):sstr;
  Procedure parse3(s:lstr;Var a,b,c:word);
    Function packtime(Var dt:datetime):longint;
    { Replaces Turbo's procedural version }
    Function now:longint;
    Function timestr(time:longint):sstr;
    Function timeval(q:sstr):longint;
    Function timepart(time:longint):longint;
    Function datestr(time:longint):sstr;
    Function dateval(q:sstr):longint;
    Function datepart(time:longint):longint;
    Function upstring(s:anystr):anystr;
    Function match(s1,s2:anystr):Boolean;
    Function devicename(name:lstr):Boolean;
    Function exist(n:lstr):Boolean;
    Function exist2(n:lstr):Boolean;

    Procedure appendfile(name:lstr;Var q:Text);
    Procedure addexitproc(p:pointer);
    Procedure doneexitproc;

    Implementation

  Const maxexitprocs=25;

  Var exitstack:Array[1..maxexitprocs] Of pointer;
    exitstackptr:Integer;

  Type packedtimerec=Record
                       date,time:word
                     End;

  Function strr(n:Integer):mstr;
    Var q:mstr;
    Begin
      Str(n,q);
      strr:=q
    End;

  Function streal(r:Real):mstr;
    Var q:mstr;
    Begin
      Str(r:0:0,q);
      streal:=q
    End;

  Function strlong(l:longint):mstr;
    Var q:mstr;
    Begin
      Str(l,q);
      strlong:=q
    End;

  Function valu(q:mstr):Integer;
    Var i,s,pu:Integer;
      r:Real;
    Begin
      valu:=0;
      If Length(q)=0 Then exit;
      If Not(q[1] In ['0'..'9','-']) Then exit;
      If Length(q)>5 Then exit;
      Val(q,r,s);
      If s<>0 Then exit;
      If (r<=32767.0) And (r>=-32767.0)
      Then valu:=Round(r)
    End;

  Function addrstr(p:pointer):sstr;

    Function hexstr(n:Integer):sstr;

      Function hexbytestr(b:Byte):sstr;
        Const hexchars:Array[0..15] Of Char='0123456789ABCDEF';
        Begin
          hexbytestr:=hexchars[b Shr 4]+hexchars[b And 15]
        End;

      Begin
        hexstr:=hexbytestr(Hi(n))+hexbytestr(Lo(n))
      End;

    Begin
      addrstr:=hexstr(Seg(p^))+':'+hexstr(Ofs(p^))
    End;

  Procedure parse3(s:lstr;Var a,b,c:word);
    Var p:Integer;

    Procedure parse1(Var n:word);
      Var ns:lstr;
      Begin
        ns[0]:=#0;
        While (p<=Length(s)) And (s[p] In ['0'..'9']) Do Begin
          ns:=ns+s[p];
          p:=p+1
        End;
        If Length(ns)=0
        Then n:=0
        Else n:=valu(ns);
        If p<Length(s) Then p:=p+1
      End;

    Begin
      p:=1;
      parse1(a);
      parse1(b);
      parse1(c)
    End;

  Function packtime(Var dt:datetime):longint;
    Var l:longint;
    Begin
      dos.packtime(dt,l);
      packtime:=l
    End;

  Function now:longint;
    Var dt:datetime;
      t:word;
      l:longint;
    Begin
      gettime(dt.hour,dt.min,dt.sec,t);
      getdate(dt.year,dt.month,dt.day,t);
      l:=packtime(dt);
      now:=l
    End;

  Function timestr(time:longint):sstr;
    Var h1:Integer;
      ms:sstr;
      dt:datetime;
    Const ampmstr:Array[false..true] Of String[2]=('am','pm');
    Begin
      unpacktime(time,dt);
      h1:=dt.hour;
      If h1=0
      Then h1:=12
      Else If h1>12
        Then h1:=h1-12;
      ms:=strr(dt.min);
      If dt.min<10 Then ms:='0'+ms;
      timestr:=strr(h1)+':'+ms+' '+ampmstr[dt.hour>11]
    End;

  Function datestr(time:longint):sstr;
    Var dt:datetime;
    Begin
      unpacktime(time,dt);
      datestr:=strr(dt.month)+'/'+strr(dt.day)+'/'+strr(dt.year-1900)
    End;

  Function timepart(time:longint):longint;
    Begin
      timepart:=time And $0000ffff;
    End;

  Function datepart(time:longint):longint;
    Begin
      datepart:=time And $ffff0000;
    End;

  Procedure cleardatetime(Var dt:datetime);
    Begin
      unpacktime(0,dt)
    End;

  Function timeval(q:sstr):longint;
    Var h1,t:word;
      k:Char;
      dt:datetime;
    Begin
      cleardatetime(dt);
      parse3(q,h1,dt.min,t);
      k:=UpCase(q[Length(q)-1]);
      If h1 In [1..11]
      Then
        Begin
          dt.hour:=h1;
          If k='P' Then dt.hour:=dt.hour+12
        End
      Else
        If k='P'
        Then dt.hour:=12
        Else dt.hour:=0;
      timeval:=(dt.hour*60)+(dt.min) ;
       {      (timepart(packtime(dt)))}
    End;

  Function dateval(q:sstr):longint;
    Var dt:datetime;
    Begin
      cleardatetime(dt);
      parse3(q,dt.month,dt.day,dt.year);
      If dt.year<100 Then dt.year:=dt.year+1900;
      dateval:=datepart(packtime(dt))
    End;

  Function upstring(s:anystr):anystr;
    Var cnt:Integer;
    Begin
      For cnt:=1 To Length(s) Do s[cnt]:=UpCase(s[cnt]);
      upstring:=s
    End;

  Function match(s1,s2:anystr):Boolean;
    Var cnt:Integer;
    Begin
      match:=False;
      If Length(s1)<>Length(s2) Then exit;
      For cnt:=1 To Length(s1) Do
        If UpCase(s1[cnt])<>UpCase(s2[cnt])
        Then exit;
      match:=True
    End;

  Function devicename(name:lstr):Boolean;
    Var f:File;
      n:Integer Absolute f;
      r:registers;
    Begin
      devicename:=False;
      Assign(f,name);
      Reset(f);
      If IOResult<>0 Then exit;
      r.bx:=n;
      r.ax:=$4400;
      Intr($21,r);
      devicename:=(r.dx And 128)=128;
      Close(f)
    End;

  Function exist(n:lstr):Boolean;

var aa,bb:file;
    cc,dd:string[79];
    ee,ff:longint;
    ss:searchrec;
    gg:pathstr;

    begin

   gg:='';
   dd:='';
   gg:= fsearch(n,dd);
   exist:=gg=n;

    End;

    function exist2(n:lstr):boolean;
    var f:file;
    i:integer;
    begin
          Assign(f,n);
      Reset(f);
      i:=IOResult;
      exist2:=i=0;
      Close(f);
      i:=IOResult

    end;
  Procedure appendfile(name:lstr;Var q:Text);
    Var n:Integer;
      b:Boolean;
      f:File Of Char;
    Begin
      Close(q);
      n:=IOResult;
      Assign(q,name);
      Assign(f,name);
      Reset(f);
      b:=(IOResult<>0) Or (FileSize(f)=0);
      Close(f);
      n:=IOResult;
      If b
      Then Rewrite(q)
      Else Append(q)
    End;

  Procedure addexitproc(p:pointer);
    Begin
      inc(exitstackptr);
      If exitstackptr>maxexitprocs Then Begin
        WriteLn('Too many exit procedures');
        Halt(255)
      End Else Begin
        exitstack[exitstackptr]:=exitproc;
        exitproc:=p
      End
    End;

  Procedure doneexitproc;
    Begin
      exitproc:=exitstack[exitstackptr];
      dec(exitstackptr)
    End;

  Begin
    exitstackptr:=0
  End.
