  {$R-,S-,I-,D-,F+,V-,B-,N-,L+ }

  unit flags;

  Interface

  uses gentypes,subs1;

  Const accessstr:Array[accesstype] Of String[8]=
    ('By level','Keep out','Let in','');

    Procedure setuseraccflag(Var u:userrec;bn:Integer;ac:accesstype);
    Function getuseraccflag(Var u:userrec;bn:Integer):accesstype;
    Procedure setallflags(bn:Integer;ac:accesstype);
    Procedure setalluserflags(Var u:userrec;ac:accesstype);

    Implementation

  Procedure setuseraccflag(Var u:userrec;bn:Integer;ac:accesstype);
    Begin
      If (Ord(ac) And 1)=1
      Then u.access1:=u.access1+[bn]
      Else u.access1:=u.access1-[bn];
      If (Ord(ac) And 2)=2
      Then u.access2:=u.access2+[bn]
      Else u.access2:=u.access2-[bn]
    End;

  Function getuseraccflag(Var u:userrec;bn:Integer):accesstype;
    Var ac:accesstype;
    Begin
      getuseraccflag:=accesstype(Ord(bn In u.access1) Or
      (Ord(bn In u.access2) Shl 1))
    End;

  Procedure setallflags(bn:Integer;ac:accesstype);
    Var cnt:Integer;
      u:userrec;
    Begin
      For cnt:=1 To FileSize(ufile)-1 Do Begin
        Seek(ufile,cnt);
        Read(ufile,u);
        setuseraccflag(u,bn,ac);
        Seek(ufile,cnt);
        Write(ufile,u)
      End
    End;

  Procedure setalluserflags(Var u:userrec;ac:accesstype);
    Var b1,b2:Byte;
    Begin
      b1:=(Ord(ac) And 1)*255;
      b2:=((Ord(ac) And 2) Shr 1)*255;
      FillChar(u.access1,32,b1);
      FillChar(u.access2,32,b2)
    End;

  Begin
  End.
M ANS           �^v�  GFILEM  ANS           T�^m�  