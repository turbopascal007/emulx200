  {$R-,S-,I-,D-,F+,V-,B-,N-,L+ }

  unit mailret;

  Interface

  uses gentypes,gensubs,subs1,configrt,statret,textret;

  Function searchmail(startpt,usernum:Integer):Integer;
  Procedure delmail(n:Integer);
  Procedure addmail(sentto:Integer;line:Integer;Var me:message);
    Function getnummail(un:Integer):Integer;

    Implementation

  Function searchmail(startpt,usernum:Integer):Integer;
    Var cnt:Integer;
      m:mailrec;
    Begin
      searchmail:=0;
      If startpt>=FileSize(mfile)-1 Then exit;
      startpt:=startpt+1;
      Seek(mfile,startpt);che;
      For cnt:=startpt To FileSize(mfile)-1 Do Begin
        Read(mfile,m);che;
        If m.sentto=usernum Then Begin
          searchmail:=cnt;
          exit
        End
      End
    End;

  Procedure delmail(n:Integer);
    Var m:mailrec;
      c:Integer;
    Begin
      Seek(mfile,n);
      Read(mfile,m);
      deletetext(m.line);
      For c:=n To FileSize(mfile)-2 Do Begin
        Seek(mfile,c+1);
        Read(mfile,m);
        Seek(mfile,c);
        Write(mfile,m)
      End;
      Seek(mfile,FileSize(mfile)-1);
      Truncate(mfile);
      If FileSize(mfile)=0 Then Begin
        m.sentto:=0;
        Seek(mfile,0);
        Write(mfile,m)
      End
    End;

  Procedure addmail(sentto:Integer;line:Integer;Var me:message);
    Var m:mailrec;
      u:userrec;
    Begin
      m.sentby:=unam;
      m.anon:=me.anon;
      m.when:=now;
      m.title:=me.title;
      m.line:=line;
      m.sentto:=sentto;
      m.read:=False;
      Seek(mfile,FileSize(mfile));
      Write(mfile,m);
      Seek(ufile,sentto);
      Read(ufile,u);
      If match(u.handle,sysopname) Then newmail:=newmail+1
    End;

  Function getnummail(un:Integer):Integer;
    Var cnt:Integer;
      m:mailrec;
      total:Integer;
    Begin
      total:=0;
      Seek(mfile,0);
      For cnt:=1 To FileSize(mfile) Do Begin
        Read(mfile,m);
        If m.sentto=un Then total:=total+1
      End;
      getnummail:=total
    End;


  Begin
  End.

        T�^m�  