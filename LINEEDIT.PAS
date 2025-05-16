  {$R-,S-,I-,D-,F+,V-,B-,N-,L+ }

  unit lineedit;

  Interface

  uses gentypes,configrt,gensubs,subs1,subs2;

  Function linereedit(Var m:message;gettitle:Boolean):Boolean;

    Implementation

  Function linereedit(Var m:message;gettitle:Boolean):Boolean;
    Var done,editmode:Boolean;
      curline,r1,r2,cols:Integer;

    Procedure init;
      Begin
        If eightycols In urec.config
        Then cols:=79
        Else cols:=39;
        linereedit:=False;
        done:=False;
        editmode:=False;
        curline:=1;
        If m.numlines=0
        Then WriteLn(^B^M'Enter your message now! ')
        Else Begin
          WriteLn(^B^M'Re-editing message.');
          WriteLn('Current size: '^S,m.numlines);
          WriteLn('Note: Inserting before line 1.');
          WriteLn('/A will abort changes.'^M)
        End;
        WriteLn('[Text Editor]: [/S] to save [/] for command prompt'^B^M)
      End;

    Procedure setbreak;
      Begin
        clearbreak;
        nobreak:=True;
        dontstop:=True;
        wordwrap:=True;
        linecount:=0
      End;

    Function msgisblank:Boolean;
      Begin
        If m.numlines>0 Then msgisblank:=False Else Begin
          writestr('Sorry, message blank!');
          msgisblank:=True
        End
      End;

    Function getrange:Boolean;
      Begin
        parserange(m.numlines,r1,r2);
        getrange:=r1<>0
      End;

    Function getlinenum(txt:mstr):Boolean;
      Begin
        writestr('Line number to '+txt+':');
        r1:=valu(Input);
        r2:=r1;
        If (r1>=1) And (r1<=m.numlines)
        Then getlinenum:=True
        Else Begin
          getlinenum:=False;
          WriteLn(^R'Invalid line!')
        End
      End;

    Procedure inslines(r1,r2:Integer);
      Var n,cnt:Integer;
      Begin
        n:=r2-r1+1;
        m.numlines:=m.numlines+n;
        For cnt:=m.numlines Downto r2+1 Do m.text[cnt]:=m.text[cnt-n]
      End;

    Procedure dellines(r1,r2:Integer);
      Var n,cnt:Integer;
      Begin
        n:=r2-r1+1;
        m.numlines:=m.numlines-n;
        For cnt:=r1 To m.numlines Do m.text[cnt]:=m.text[cnt+n]
      End;

    Procedure insertline;
      Var cnt:Integer;
      Begin
        If m.numlines=maxmessagesize Then exit;
        inslines(curline,curline);
        m.text[curline]:=Input;
        curline:=curline+1
      End;

    Function iseditcommand:Boolean;
      Begin
        iseditcommand:=(Input[1]='/') And (Length(Input)>0)
      End;

    Function userissure:Boolean;
      Begin
        writestr('Warning!  Message will be erased!');
        writestr('Confirm [y/n]:');
        userissure:=yes
      End;

    Procedure topofmsg;
      Begin
        WriteLn(^R'**Top of msg**')
      End;

    Procedure abortmes;
      Begin
        done:=userissure
      End;

    Procedure backline;
      Begin
        If m.numlines<1 Then Begin
          topofmsg;
          exit
        End;
        WriteLn(^R'<Correct previous line>');
        curline:=curline-1;
        dellines(curline,curline)
      End;

    Procedure continuemes;
      Begin
        WriteLn(^B^R^M'Continue your message...');
        curline:=m.numlines+1;
        editmode:=False
      End;

    Procedure deletelines;
      Begin
        If Not getrange Then exit;
        If (r1=1) And (r2=m.numlines) Then Begin
          writestr('Delete whole message? *');
          If Not yes Then exit
        End;
        dellines(r1,r2)
      End;

    Procedure seteditmode;
      Begin
        If editmode
        Then writestr('You are already in edit mode!')
        Else editmode:=True
      End;

    Procedure fixline;
      Var tmp:lstr;
      Begin
        If Not getlinenum('fix') Then exit;
        setbreak;
        WriteLn('Line currently reads:');
        WriteLn(m.text[r1],^M);
        wordwrap:=False;
        BufLen:=cols;
        beginwithspacesok:=True;
        writestr('Enter new line:'^M'*');
        If Length(Input)<>0 Then m.text[r1]:=Input;
        continuemes
      End;

    Procedure insertlines;
      Begin
        If Not getlinenum('insert before') Then continuemes;
        curline:=r1
      End;

    Procedure listmes;
      Var cnt,r1,r2:Integer;
        linenum:Boolean;
      Begin
        If msgisblank Then exit;
        parserange(m.numlines,r1,r2);
        If r1=0 Then exit;
        writestr('Line numbers? *');
        linenum:=yes;
        Write(^R);
        For cnt:=r1 To r2 Do Begin
          If linenum Then WriteLn(cnt,':');
          WriteLn(m.text[cnt]);
          If break Then exit
        End
      End;

    Procedure centerline;
      Var spaces:lstr;
      Begin
        FillChar(spaces[1],80,32);
        If editmode Then Begin
          setbreak;
          BufLen:=cols;
          wordwrap:=False;
          writestr('Enter line to center:'^M'*')
        End Else Delete(Input,1,1);
        While (Length(Input)>0) And (Input[1]=' ') Do Delete(Input,1,1);
        If Length(Input)=0 Then exit;
        spaces[0]:=Chr((cols-Length(Input)) Div 2);
        Input:=spaces+Input;
        insertline
      End;

    Procedure clearmes;
      Begin
        If userissure Then Begin
          writestr('Starting message over...');
          m.numlines:=0;
          curline:=1
        End
      End;

    Procedure searchandreplace;
      Var sfor,repw:lstr;
        l:^lstr;
        ask:Boolean;
        cl,cp,sl,max:Integer;

      Procedure replace;
        Var New,old:lstr;
        Begin
          old:=Copy(l^,cp,sl);
          New:=repw;
          If Length(New)>0 Then
            If old[1] In ['A'..'Z']
            Then New[1]:=UpCase(New[1]);
          Delete(l^,cp,sl);
          While Length(l^)+Length(New)>cols Do l^[0]:=Pred(l^[0]);
          Insert(New,l^,cp);
          cp:=cp+Length(New)-1
        End;

      Procedure maybereplace;
        Var cnt:Integer;
        Begin
          If ask Then Begin
            WriteLn(^B^M,cl,':'^M,l^);
            For cnt:=1 To cp-1 Do Write(' ');
            For cnt:=1 To sl Do Write('^');
            WriteLn;
            writestr('Replace [Y/N]:');
            If Not yes Then exit
          End;
          replace
        End;

      Begin
        If msgisblank Then exit;
        writestr('Search for:');
        If Length(Input)=0 Then exit;
        sfor:=upstring(Input);
        sl:=Length(Input);
        writestr('Replace with:');

        repw:=Input;
        if length(input)>50 then exit;
        writestr('Ask each time? *');
        ask:=yes;
        max:=Length(l^)-sl+1;
        For cl:=1 To m.numlines Do Begin
          l:=Addr(m.text[cl]);
          max:=Length(l^)-sl+1;
          cp:=0;
          While cp<max Do Begin
            cp:=cp+1;
            If match(sfor,Copy(l^,cp,sl)) Then maybereplace;
            max:=Length(l^)-sl+1
          End
        End;
        WriteLn(^B^M'Search and replace complete')
      End;

    Procedure savemes;
      Begin
        done:=True;
        If m.numlines=0
        Then writestr('Message blank!')
        Else Begin
          writestr('Saving..');
          linereedit:=True
        End
      End;

    Procedure retitle;
      Begin
        If gettitle Then Begin
          WriteLn(^R'Title is: '^S+m.title);
          writestr('Enter new title: &');
          If Length(Input)>0 Then m.title:=Input
        End Else writestr('This message can''t have a title.')
      End;

    Procedure edithelp;
      Begin
        printfile(textfiledir+'Edithelp.');
        editmode:=True
      End;

    Procedure editcommand;
      Var k:Char;
      Begin
        While iseditcommand And (Length(Input)>0) Do Delete(Input,1,1);
        If Length(Input)=0 Then Begin
          editmode:=True;
          exit
        End;
        k:=UpCase(Input[1]);
        Case k Of
          'A' :abortmes;
          'B' :backline;
          'C' :continuemes;
          'D' :deletelines;
          'E' :seteditmode;
          'F' :fixline;
          'I' :insertlines;
          'L' :listmes;
          'M' :centerline;
          'N' :clearmes;
          'R' :searchandreplace;
          'S' :savemes;
          'T' :retitle
          Else edithelp
        End
      End;

    Procedure editcommands;
      Begin
        editcommand;
        While editmode And Not done Do Begin
          writestr(^M'Edit command [?=help]:');
          If hungupon Then done:=True Else editcommand
        End
      End;

    Procedure getline;
      Begin
        setbreak;
        Input:='/E';
        If m.numlines=maxmessagesize Then Begin
          WriteLn('Sorry, message is full!');
          exit
        End;
        If hungupon Then exit;
        If m.numlines=maxmessagesize-3 Then WriteLn('3 lines left!');
        If curline>m.numlines+1 Then curline:=m.numlines+1;
        lastprompt:='Continue your message...'^M;
        BufLen:=cols;
        getstr;
        If Input=^H
        Then If curline>1
          Then
            Begin
              WriteLn('--Back--');
              curline:=curline-1;
              chainstr:=m.text[curline];
              dellines(curline,curline)
            End
          Else topofmsg
        Else If Not iseditcommand Then insertline
      End;

    Procedure getlines;
      Begin
        Repeat
          getline
        Until hungupon Or iseditcommand Or (m.numlines=maxmessagesize);
        If Not iseditcommand Then Input:='/'
      End;

    Begin
      init;
      Repeat
        getlines;
        editcommands
      Until done;
      WriteLn(^B^M^M)
    End;

  Begin
  End.

