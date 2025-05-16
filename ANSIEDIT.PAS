
      unit ansiedit;

      Interface

      uses crt,
      gentypes,modem,configrt,windows,gensubs,subs1,subs2;

      Function ansireedit(Var m:message;gettitle:Boolean):Boolean;

      Implementation

    Function ansireedit(Var m:message;gettitle:Boolean):Boolean;


      Var topline,curline,cx,cy,cols,scrnsize,lines,
        rightmargin,savedx,savedy,topscrn:Integer;
        insertmode,msgdone,ansimode:Boolean;

      Function curx:Integer;
        Begin
          curx:=WhereX
        End;

      Function cury:Integer;
        Begin
          cury:=WhereY-topscrn+1
        End;

      Procedure writevt52(q:lstr);
        Var cnt:Integer;
        Begin
          If Not carrier Then exit;
          For cnt:=1 To Length(q) Do sendchar(q[cnt])
        End;

      Procedure moveto(x,y:Integer);
        Begin
          y:=y+topscrn-1;
          If ansimode Then Begin
            Write(direct,#27'[');
            If y<>1 Then Write(direct,strr(y));
            If x<>1 Then Write(direct,';',strr(x));
            Write('H')
          End Else Begin
            GoToXY(x,y);
            writevt52(#234+#234+#01+Chr(y)+Chr(x))
          End
        End;

      Procedure clearscr;
        Begin
          If ansimode
          Then Write(direct,#27'[2J')
          Else Begin
            writevt52(#234+#234+#4);
            ClrScr
          End
        End;

      Procedure cleareol;
        Begin
          If ansimode
          Then Write(direct,#27'[K')
          Else Begin
            writevt52(#234+#234+#27);
            ClrEol
          End
        End;

      Procedure savecsr;
        Begin
          If ansimode
          Then Write(direct,#27'[s')
          Else Begin
            savedx:=curx;
            savedy:=cury
          End
        End;

      Procedure restorecsr;
        Begin
          If ansimode
          Then Write(direct,#27'[u')
          Else moveto(savedx,savedy)
        End;

      Procedure cmove(k:Char;n,dx,dy:Integer);
        Var cnt:Integer;
        Begin
          If n<1 Then exit;
          If ansimode Then Begin
            Write(direct,#27'[');
            If n<>1 Then Write(direct,strr(n));
            Write(direct,k)
          End Else
            {For cnt:=1 To n Do Begin
              writevt52(#27+k);}

              GoToXY(WhereX+dx,WhereY+dy);
              ansigotoxy (wherex,wherey);
        End;

      Procedure cup(n:Integer);
        Begin
          cmove('A',n,0,-1)
        End;

      Procedure cdn(n:Integer);
        Begin
          cmove('B',n,0,1)
        End;

      Procedure clf(n:Integer);
        Var cnt:Integer;
        Begin
          cmove('D',n,-1,0)
        End;

      Procedure crg(n:Integer);
        Begin
          cmove('C',n,1,0)
        End;

      Procedure checkspaces;
        Var q:^lstr;
        Begin
          q:=Addr(m.text[curline]);
          While q^[Length(q^)]=' ' Do q^[0]:=Pred(q^[0])
        End;

      Procedure checkcx;
        Var n:Integer;
        Begin
          n:=Length(m.text[curline])+1;
          If cx>n Then cx:=n
        End;

      Procedure computecy;
        Begin
          cy:=curline-topline+1
        End;

      Procedure updatecpos;
        Begin
          computecy;
          moveto(cx,cy)
        End;

      Procedure insertabove;
        Var cnt:Integer;
        Begin
          If m.numlines=maxmessagesize Then exit;
          For cnt:=m.numlines Downto curline Do m.text[cnt+1]:=m.text[cnt];
          m.text[curline]:='';
          m.numlines:=m.numlines+1
        End;

      Procedure deletethis;
        Var cnt:Integer;
        Begin
          If m.numlines=1 Then Begin
            m.text[1]:='';
            exit
          End;
          For cnt:=curline+1 To m.numlines Do m.text[cnt-1]:=m.text[cnt];
          m.text[m.numlines]:='';
          m.numlines:=m.numlines-1;
          checkcx
        End;

      Procedure fullrefresh;
        Var cnt,n:Integer;
        Begin
          clearscr;
          If topline<1 Then topline:=1;
          computecy;
          moveto(1,1);
          For cnt:=1 To lines Do Begin
            n:=cnt+topline-1;
            If n<=m.numlines Then Begin
              Write(m.text[n]);
              If cnt<>lines Then WriteLn
            End
          End;
          updatecpos
        End;

      Procedure repos(dorefresh:Boolean);
        Var cl,tl:Integer;
        Begin
          checkspaces;
          cl:=curline;
          tl:=topline;
          If curline<1 Then curline:=1;
          If curline>m.numlines Then curline:=m.numlines;
          If topline>curline Then topline:=curline;
          If topline+lines<curline Then topline:=curline-lines;
          If topline<1 Then topline:=1;
          checkcx;
          computecy;
          If (cl=curline) And (tl=topline) And (Not dorefresh)
          Then updatecpos
          Else fullrefresh
        End;

      Procedure partrefresh;{ Refreshes from CY }
        Var cnt,n:Integer;
        Begin
          If topline<1 Then repos(True) Else Begin
            moveto(1,cy);
            For cnt:=cy To lines Do Begin
              n:=cnt+topline-1;
              If n<=m.numlines Then Write(m.text[n]);
              cleareol;
              If cnt<>lines Then WriteLn
            End;
            updatecpos
          End
        End;

      Procedure pageup;
        Begin
          checkspaces;
          If curline=1 Then exit;
          curline:=curline-lines+4;
          topline:=topline-lines+4;
          repos(True)
        End;

      Procedure pagedn;
        Begin
          checkspaces;
          If curline=m.numlines Then exit;
          curline:=curline+lines-4;
          topline:=topline+lines-4;
          repos(True)
        End;

      Procedure toggleins;
        Begin
          insertmode:=Not insertmode
        End;

      Procedure scrolldown;
        Begin
          topline:=curline-lines+2;
          repos(True)
        End;

      Procedure scrollup;
        Begin
          If topline<1 Then Begin
            topline:=topline+1;
            moveto(1,lines);
            computecy;
            WriteLn
          End Else Begin
            topline:=curline-1;
            repos(True)
          End
        End;

      Procedure topofmsg;
        Begin
          checkspaces;
          cx:=1;
          cy:=1;
          curline:=1;
          If topline=1
          Then updatecpos
          Else
            Begin
              topline:=1;
              fullrefresh
            End
        End;

      Procedure updatetoeol;
        Var cnt:Integer;
        Begin
          savecsr;
          Write(Copy(m.text[curline],cx,255));
          cleareol;
          restorecsr
        End;

      Procedure letterkey(k:Char);
        Var l:^lstr;
          w:lstr;
          n,ox:Integer;
          q:Char;
          inserted,refr:Boolean;

        Procedure scrollwwrap;
          Begin
            If topline>0 Then Begin
              scrollup;
              exit
            End;
            cy:=cy-1;
            moveto(Length(m.text[curline-1])+1,cy);
            cleareol;
            WriteLn;
            Write(m.text[curline]);
            topline:=topline+1;
            cx:=curx
          End;

        Begin
          l:=Addr(m.text[curline]);
          If Length(l^)>=rightmargin Then Begin
            If curline=maxmessagesize Then exit;
            If cx<=Length(l^) Then exit;
            l^:=l^+k;
            w:='';
            cx:=Length(l^);
            Repeat
              q:=l^[cx];
              If q<>' ' Then Insert(q,w,1);
              cx:=cx-1
            Until (q=' ') Or (cx<1);
            If cx<1 Then Begin
              cx:=Length(l^)-1;
              w:=k
            End;
            l^[0]:=Chr(cx);
            checkspaces;
            curline:=curline+1;
            If curline>m.numlines Then m.numlines:=curline;
            inserted:=m.text[curline]<>'';
            If inserted Then insertabove;
            m.text[curline]:=w;
            cy:=cy+1;
            ox:=cx;
            cx:=Length(w)+1;
            refr:=cy>lines;
            If refr
            Then scrollwwrap
            Else Begin
              If Length(w)>0 Then Begin
                moveto(ox+1,cy-1);
                For n:=1 To Length(w) Do Write(' ')
              End;
              If inserted And (m.numlines>curline)
              Then partrefresh
              Else Begin
                moveto(1,cy);
                Write(m.text[curline]);
              End
            End;
            exit
          End;
          If insertmode
          Then Insert(k,l^,cx)
          Else Begin
            While Length(l^)<cx Do l^:=l^+' ';
            l^[cx]:=k
          End;
          Write(k);
          cx:=cx+1;
          If insertmode And (cx<=Length(l^)) Then updatetoeol
        End;

      Procedure Back;
        Begin
          If cx=1 Then Begin
            If curline=1 Then exit;
            checkspaces;
            curline:=curline-1;
            cy:=cy-1;
            cx:=Length(m.text[curline])+1;
            If cy<1 Then scrolldown Else updatecpos;
          End Else Begin
            cx:=cx-1;
            clf(1)
          End
        End;

      Procedure fowrd;
        Begin
          If cx>Length(m.text[curline]) Then Begin
            If curline=maxmessagesize Then exit;
            checkspaces;
            curline:=curline+1;
            If curline>m.numlines Then m.numlines:=curline;
            cy:=cy+1;
            cx:=1;
            If cy>lines Then scrollup Else updatecpos
          End Else Begin
            cx:=cx+1;
            crg(1)
          End
        End;

      Procedure del;
        Begin
          If Length(m.text[curline])=0 Then Begin
            deletethis;
            partrefresh;
            exit
          End;
          Delete(m.text[curline],cx,1);
          If cx>Length(m.text[curline])
          Then Write(' '^H)
          Else updatetoeol
        End;

      Procedure bkspace;
        Begin
          If Length(m.text[curline])=0 Then Begin
            If curline=1 Then exit;
            deletethis;
            checkspaces;
            curline:=curline-1;
            cy:=cy-1;
            cx:=Length(m.text[curline])+1;
            If cy<1
            Then scrolldown
            Else partrefresh;
            exit
          End;
          If cx=1 Then exit;
          cx:=cx-1;
          Write(^H);
          del
        End;

      Procedure beginline;
        Begin
          If cx=1 Then exit;
          cx:=1;
          updatecpos
        End;

      Procedure endline;
        Var dx:Integer;
        Begin
          dx:=Length(m.text[curline])+1;
          If cx=dx Then exit;
          cx:=dx;
          updatecpos
        End;

      Procedure upline;
        Var chx:Boolean;
          l:Integer;
        Begin
          checkspaces;
          If curline=1 Then exit;
          curline:=curline-1;
          l:=Length(m.text[curline]);
          chx:=cx>l;
          If chx Then cx:=l+1;
          cy:=cy-1;
          If cy>0
          Then If chx
            Then updatecpos
            Else cup(1)
          Else scrolldown
        End;

      Procedure downline;
        Var chx:Boolean;
          l:Integer;
        Begin
          checkspaces;
          If curline=maxmessagesize Then exit;
          curline:=curline+1;
          If curline>m.numlines Then m.numlines:=curline;
          l:=Length(m.text[curline]);
          chx:=cx>l;
          If chx Then cx:=l+1;
          cy:=cy+1;
          If cy<=lines
          Then If chx
            Then updatecpos
            Else cdn(1)
          Else scrollup
        End;

      Procedure crlf;
        Var k:Char;
        Begin
          If (Length(m.text[curline])=2) And (m.text[curline][1]='/') Then Begin
            k:=UpCase(m.text[curline][2]);
            Case k Of
              'S' :Begin
                     deletethis;
                     msgdone:=True;
                     ansireedit:=True;
                     exit
                   End
            End
          End;
          beginline;
          downline
        End;

      Function conword:Boolean;
        Var l:^lstr;
        Begin
          l:=Addr(m.text[curline]);
          conword:=False;
          If (cx>Length(l^)) Or (cx=0) Then exit;
          conword:=True;
          If cx=1 Then exit;
          If (l^[cx-1]=' ') And (l^[cx]<>' ') Then exit;
          conword:=False
        End;

      Procedure wordleft;
        Begin
          Repeat
            cx:=cx-1;
            If cx<1 Then Begin
              If curline=1 Then Begin
                cx:=1;
                repos(False);
                exit
              End;
              checkspaces;
              curline:=curline-1;
              cy:=cy-1;
              cx:=Length(m.text[curline])
            End;
          Until conword;
          If cx=0 Then cx:=1;
          If cy<1
          Then repos(True)
          Else updatecpos
        End;

      Procedure wordright;
        Begin
          Repeat
            cx:=cx+1;
            If cx>Length(m.text[curline]) Then Begin
              If curline=m.numlines Then Begin
                repos(False);
                exit
              End;
              checkspaces;
              curline:=curline+1;
              cy:=cy+1;
              cx:=1
            End;
          Until conword;
          If cy>lines
          Then repos(True)
          Else updatecpos
        End;

      Procedure worddel;
        Var l:^lstr;
          b:Byte;
          s,n:Integer;
        Begin
          l:=Addr(m.text[curline]);
          b:=Length(l^);
          If cx>b Then exit;
          s:=cx;
          Repeat
            cx:=cx+1
          Until conword Or (cx>b);
          n:=cx-s;
          Delete(l^,s,n);
          cx:=s;
          updatetoeol
        End;

      Procedure deleteline;
        Begin
          deletethis;
          partrefresh
        End;

      Procedure insertline;
        Begin
          If m.numlines>=maxmessagesize Then exit;
          insertabove;
          checkcx;
          partrefresh
        End;

      Procedure help;
        Var k:Char;
        Begin
          clearscr;
          printfile(textfiledir+'Edithelp.ANS');
          Write(^B^M'Press any key...');
          k:=waitforchar;
          fullrefresh
        End;

      Procedure breakline;
        Begin
          If (m.numlines>=maxmessagesize) Or (cy=lines) Or
          (cx=1) Or (cx>Length(m.text[curline])) Then exit;
          insertabove;
          m.text[curline]:=Copy(m.text[curline+1],1,cx-1);
          Delete(m.text[curline+1],1,cx-1);
          partrefresh
        End;

      Procedure joinlines;
        Var n:Integer;
        Begin
          If curline=m.numlines Then exit;
          If Length(m.text[curline])+Length(m.text[curline+1])>rightmargin Then exit;
          m.text[curline]:=m.text[curline]+m.text[curline+1];
          n:=cx;
          curline:=curline+1;
          deletethis;
          curline:=curline-1;
          cx:=n;
          partrefresh
        End;

      Procedure userescape;
        Var k:Char;
        Begin
          Repeat
            k:=waitforchar;
            Case k Of
              'A' :upline;
              'B' :downline;
              'C' :fowrd;
              'D' :Back
            End
          Until (k<>'[') Or hungupon
        End;

      Procedure deleteeol;
        Begin
          cleareol;
          m.text[curline][0]:=Chr(cx-1)
        End;

      Procedure tab;
        Var nx,n,cnt:Integer;
        Begin
          nx:=((cx+8) And 248)+1;
          n:=nx-cx;
          If (n+Length(m.text[curline])>=cols) Or (nx>=cols) Then exit;
          For cnt:=1 To n Do Insert(' ',m.text[curline],cx);
          updatetoeol;
          cx:=cx+n;
          updatecpos
        End;

      Procedure commands;

        Function youaresure:Boolean;
          Var q:String[1];
          Begin
            youaresure:=False;
            moveto(1,0);
            Write('Are you sure? ');
            BufLen:=1;
            getstr;
            cup(1);
            Write('               ');
            youaresure:=yes;
            clearbreak;
            nobreak:=True
          End;

        Procedure savemes;
          Begin
            msgdone:=True;
            ansireedit:=True
          End;

        Procedure abortmes;
          Begin
            If youaresure Then Begin
              m.numlines:=0;
              msgdone:=True
            End
          End;

        Procedure formattext;
          Var ol,il,c:Integer;
            oln,wd,iln:lstr;
            k:Char;

          Procedure putword;
            Var cnt:Integer;
              b:Boolean;
            Begin
              b:=True;
              For cnt:=1 To Length(wd) Do If wd[cnt]<>' ' Then b:=False;
              If b Then exit;
              While wd[Length(wd)]=' ' Do wd[0]:=Pred(wd[0]);
              If Length(wd)=0 Then exit;
              If Length(wd)+Length(oln)>rightmargin Then Begin
                m.text[ol]:=oln;
                ol:=ol+1;
                While (wd[1]=' ') And (Length(wd)>0) Do Delete(wd,1,1);
                oln:=wd
              End Else oln:=oln+wd;
              If wd[Length(wd)] In ['.','?','!']
              Then wd:='  '
              Else wd:=' '
            End;

          Begin
            il:=curline;
            ol:=il;
            c:=1;
            oln:='';
            wd:='';
            iln:=m.text[il];
            Repeat
              If Length(iln)=0 Then Begin
                putword;
                m.text[ol]:=oln;
                partrefresh;
                checkcx;
                updatecpos;
                exit
              End;
              If c>Length(iln) Then Begin
                il:=il+1;
                If il>m.numlines
                Then iln:=''
                Else Begin
                  iln:=m.text[il];
                  m.text[il]:=''
                End;
                c:=0;
                k:=' '
              End Else k:=iln[c];
              c:=c+1;
              If k=' '
              Then putword
              Else wd:=wd+k
            Until 0=1
          End;

        Var cmd:String[1];
          k:Char;
        Begin
          clearbreak;
          nobreak:=True;
          moveto(1,0);
          Write('Save Command: ');
          BufLen:=1;
          getstr;
          clearbreak;
          nobreak:=True;
          cup(1);
          Write('                ');
          If Length(Input)=0 Then Begin
            updatecpos;
            exit
          End;
          k:=UpCase(Input[1]);
          Case k Of
            'S' :savemes;
            'D' :savemes;
            'A' :abortmes;
            'F' :formattext;
            '?' :help
          End;
          updatecpos
        End;

        procedure macro_in;
        var cnt,d:integer;
            a,b,g,h:char;
            c:anystr;
        begin
        c:=urec.macro;
        while length(c)>1 do begin

      {  if length(c)>1 then begin
             g:=c[1];
             h:=c[2];
             if g='^&' then begin delay(1000);delete(c,1,2);end;
             if g='^*' then begin letterkey(^G);delete(c,1,2);end;
             if g='^(' then begin letterkey(#27);delete(c,1,2);end;
             end;   }

        if length(c)>1 then begin
             b:=c[1];letterkey(b);delete(c,1,1); {1 at a time}
             end else begin Letterkey(c[1]);c:='';end;


         end;

        end;
      Procedure processkey;
        Var k:Char;
        Begin
          clearbreak;
          nobreak:=True;
          k:=waitforchar;
          Case k Of
            ' '..#250 :letterkey(k);
            #251:begin delay(100);clearreceivebuffer;k:=#0;end;
            #252..#254 :letterkey(k);
            ^S:Back;
            ^D:fowrd;
            ^H:bkspace;
            ^M:crlf;
            ^V:toggleins;
            ^E:upline;
            ^X:downline;
            ^U:help;
            ^K:commands;
            ^R:pageup;
            ^C:pagedn;
            ^G:del;
            ^A:wordleft;
            ^F:wordright;
            ^T:worddel;
            ^Q:beginline;
            ^W:endline;
            ^L:fullrefresh;
            ^Y:deleteline;
            ^N:insertline;
            ^I:tab;
            ^B:breakline;
            ^P:deleteeol;
            ^J:joinlines;
            ^Z:macro_in;
            #27:userescape
          End
        End;

      Var cnt:Integer;
        mp:Boolean;
      Begin
        clearbreak;
        nobreak:=True;
        ansireedit:=False;

        For cnt:=m.numlines+1 To maxmessagesize Do m.text[cnt]:='';
        scrnsize:=urec.displaylen;
        winds[0].y2:=scrnsize;
        unsplit;
        wholescreen;
        GoToXY(1,25);
        ClrEol;
        If eightycols In urec.config
        Then cols:=80
        Else cols:=40;
        ansimode:=ansigraphics In urec.config;
        mp:=moreprompts In urec.config;
        If mp Then urec.config:=urec.config-[moreprompts];
        lines:=21;
        topscrn:=scrnsize-lines+1;
        insertmode:=False;
        rightmargin:=cols-1;
        msgdone:=False;
        cx:=1;
        curline:=1;
        topline:=2-lines;
        computecy;
        updatecpos;
        fullrefresh;
        If m.numlines>0
        Then fullrefresh
        Else
          Begin
            ansigotoxy(1,1);
            WriteLn('   [Emulex/2 Full Screen Editor]   [Ctrl-U for help] '^M^M);
            m.numlines:=1;updatecpos;
          End;
        Repeat
          processkey
        Until msgdone Or hungupon;
        moveto(1,lines);
        cleareol;
        WriteLn(^M+'[Saving Message]'+^M^M^M^M);
        If mp Then urec.config:=urec.config+[moreprompts];
        winds[0].y2:=25;
        bottom;
        bottomline
      End;


      {$ifdef testansieditor}
      {*}
    {*}Procedure termmode;
      {*}Var k:Char;
      {*}Begin
        {*}setparam(1,1200,False);
        {*}WriteLn('Press ^D when connected.');
        {*}Repeat
          {*}If KeyPressed Then Begin
            {*}Read(Kbd,k);
            {*}If k=#4 Then exit;
            {*}If k=#3 Then Halt;
            {*}sendchar(k)
          {*}End;
          {*}While numchars>0 Do Write(getchar)
        {*}Until 0=1
      {*}End;
      {*}
    {*}Var m:message;
      {*}cnt:Integer;
    {*}Begin
      {*}checkbreak:=False;
      {*}urec.displaylen:=22;
      {*}urec.config:=[eightycols];{ ,ansigraphics]; }
      {*}If Not driverpresent Then Begin
        {*}WriteLn('You fool.');
        {*}Halt
      {*}End;
      {*}termmode;
      {*}ConInptr:=Ofs(readchar);
      {*}ConOutPtr:=Ofs(writechar);
      {*}m.numlines:=0;
      {*}For cnt:=1 To 100 Do m.text[cnt]:='Hello line '+Chr(cnt+64);
      {*}WriteLn(ansireedit(m,False))
      {*}
      {$endif}

    End.


