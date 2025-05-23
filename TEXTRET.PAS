  {$R-,S-,I-,D-,F+,V-,B-,N-,L+ }
  unit textret;

  Interface

  uses crt,gentypes,gensubs,subs1;

  Procedure reloadtext(sector:Integer;Var q:message);
    Procedure deletetext(sector:Integer);
    Function maketext(Var q:message):Integer;
    Function copytext(sector:Integer):Integer;
    Procedure printtext(sector:Integer);

    Implementation

  Procedure reloadtext(sector:Integer;Var q:message);
    Var k:Char;
      sectorptr,tmp,n:Integer;
      buff:buffer;
      x:Boolean;

    Procedure setbam(sector,Val:Integer);
      Begin
        Seek(mapfile,sector);
        Write(mapfile,Val)
      End;

    Procedure chk;
      Begin
        iocode:=IOResult;
        If iocode<>0 Then WriteLn(Usr,'(Error ',iocode,' reading message)')
      End;

    Begin
      sectorptr:=32767;
      n:=1;
      q.text[1]:='';
      Repeat
        If sectorptr>sectorsize Then Begin
          If sector<0 Then exit;
          if (sector>filesize(tfile)) or (sector>filesize(tfile) ) then
          Writeln ('** Seek past end of EOF ERROR');
          if sector>filesize(tfile) then exit;
          if sector>filesize(mapfile) then exit;
          Seek(tfile,sector);chk;
          Read(tfile,buff);chk;
          Seek(mapfile,sector);chk;
          Read(mapfile,tmp);chk;
          If tmp=-2 Then Begin
            tmp:=-1;
            Seek(mapfile,sector);chk;
            Write(mapfile,tmp);chk;
          End;
          sector:=tmp;
          sectorptr:=1
        End;
        k:=buff[sectorptr];
        Case k Of
          #0,#10:;
          #13:If n>=maxmessagesize
            Then k:=#0
            Else Begin
              n:=n+1;
              q.text[n]:=''
            End
          Else q.text[n]:=q.text[n]+k
        End;
        sectorptr:=sectorptr+1
      Until k=#0;
      q.numlines:=n;
      chk
    End;

  Procedure deletetext(sector:Integer);
    Var next:Integer;

    Procedure setbam(sector,Val:Integer);
      Begin
        Seek(mapfile,sector);
        Write(mapfile,Val)
      End;

    Begin
      While sector>=0 Do Begin
        Seek(mapfile,sector);
        Read(mapfile,next);
        setbam(sector,-2);
        sector:=next
      End
    End;

  Function maketext(Var q:message):Integer;
    Var line,Pos,sector,prev:Integer;
      bufptr:Integer;
      curline:anystr;
      k:Char;
      buff:buffer;

    Procedure setbam(sector,Val:Integer);
      Begin
        Seek(mapfile,sector);
        Write(mapfile,Val)
      End;

    Function nextblank(first:Integer;linkit:Boolean):Integer;
      Var cnt,i,blank:Integer;
      Begin
        nextblank:=-1;
        If first<-1 Then first:=-1;
        If first>=numsectors Then exit;
        Seek(mapfile,first+1);
        For cnt:=first+1 To numsectors Do Begin
          Read(mapfile,i);
          If i=-2 Then Begin
            blank:=cnt;
            If (first>=0) And linkit Then setbam(first,blank);
            nextblank:=blank;
            exit
          End
        End
      End;

    Function firstblank:Integer;
      Begin
        firstblank:=nextblank(-1,False)
      End;

    Procedure ensuretfilesize(sector:Integer);
      Var cnt:Integer;
        buff:buffer;
      Begin
        If sector<FileSize(tfile) Then exit;
        If (sector<0) Or (sector>numsectors) Then exit;
        FillChar(buff,SizeOf(buff),'*');
        Seek(tfile,FileSize(tfile));
        For cnt:=FileSize(tfile) To sector Do Write(tfile,buff);
        FillChar(buff,SizeOf(buff),'!')
      End;

    Procedure writesector(sector:Integer;Var q:buffer);
      Var n:Integer;
      Begin
        If (sector<0) Or (sector>numsectors) Then exit;
        Seek(mapfile,sector);
        Read(mapfile,n);
        If n<>-2 Then Begin
          error('Overwrite error sector=%1!','',strr(sector));
          exit
        End;
        ensuretfilesize(sector);
        Seek(tfile,sector);
        Write(tfile,q)
      End;

    Procedure flushbuf;
      Begin
        writesector(sector,buff);
        prev:=sector;
        sector:=nextblank(prev,True);
        bufptr:=1;
      End;

    Procedure outofroom;
      Begin
        WriteLn(^B'Sorry, out of room!');
        maketext:=-1
      End;

    Begin
      If q.numlines=0 Then Begin
        WriteLn(^B'Message blank!');
        maketext:=-1;
        exit
      End;
      If firstfree>=0 Then Begin
        sector:=firstfree;
        Seek(mapfile,sector);
        Read(mapfile,prev)
      End Else prev:=-1;
      If prev<>-2 Then Begin
        firstfree:=firstblank;
        sector:=firstfree
      End;
      maketext:=sector;
      If sector=-1 Then Begin
        outofroom;
        exit
      End;
      bufptr:=1;
      For line:=1 To q.numlines Do Begin
        curline:=q.text[line]+^M;
        If line=q.numlines Then curline:=curline+Chr(0);
        For Pos:=1 To Length(curline) Do Begin
          k:=curline[Pos];
          buff[bufptr]:=k;
          bufptr:=bufptr+1;
          If bufptr>sectorsize Then Begin
            flushbuf;
            If sector=-1 Then Begin
              outofroom;
              exit
            End
          End
        End
      End;
      If bufptr>1 Then flushbuf;
      setbam(prev,-1);
      firstfree:=nextblank(firstfree,False);
      If firstfree=-1 Then firstfree:=firstblank
    End;

  Function copytext(sector:Integer):Integer;
    Var me:message;
    Begin
      reloadtext(sector,me);
      copytext:=maketext(me)
    End;

    procedure  Print_RLE(Enter:anystr);
    var a,b:anystr;
        c,d,cnt,spaces:integer;
            color:sstr;


       procedure print_spaces;
        var SAM:integer;
            Thea:anystr;
            KKK:integer;
        begin
        kkk:=spaces;
        if (kkk>3) and (Vt52 in urec.config) then begin
        Wvt52(#234+#234+#30+' '+Chr(kkk));

        gotoxy (wherex+kkk,wherey);
        end else
        if (kkk>3) and (ansigraphics in urec.config) then
         write (#27,'[',strr(kkk),'C') else
                  for sam:=1 to kkk do write (' ');

          spaces:=0;

        end;


        begin
        spaces:=0;
        a:=enter;
        d:=length(a);
        cnt:=0;
   While length(a)>0 do begin

        if a[1]=' ' then
        begin
          inc(spaces);
          delete (a,1,1);
        end
        else begin
               if spaces>0 then print_spaces;

               if (a[1]='|') and (length(a)>3) then begin color:=a[2]+a[3]; ansicolor(valu(color));
                                      delete (a,1,3);end;

               write (a[1]); delete (a,1,1);
               end;
    end;
           writeln;

        end;

  Procedure printtext(sector:Integer);
    Var q:message;
      x,b:Boolean;
      n:Integer;
    Begin
      reloadtext(sector,q);
      WriteLn(^B);
      n:=1;
      Repeat
if ansigraphics in urec.config then         Print_Rle (q.text[n]) else
writeln (q.text[n]);
        n:=n+1
      Until break Or (n>q.numlines) Or hungupon;
      x:=xpressed;b:=break;
      WriteLn(^B^M);
      xpressed:=x;break:=b
    End;

  Begin
  End.
PU     