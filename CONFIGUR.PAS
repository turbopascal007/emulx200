{ Revision History
  881026 - Change to look for EMULATE.BBS in textdir
         - Troglodyte
}

  {$R-,S-,I-,D-,F+,V-,B-,N-,L+,O+ }

  unit configur;

  Interface

  uses gentypes,userret,gensubs,subs1,subs2,flags,configrt;

  Procedure configure;

  Implementation

Procedure configure;

  Const colorstr:Array[0..7] Of String[7]=
    ('Black','Blue','Green','Cyan','Red','Magenta','Brown','White');

  Procedure changepwd;
    Var t:sstr;
    Begin
      WriteLn('   [ Password Change ]');
      dots:=True;
      BufLen:=15;
      Write('Enter new password: ');
      If getpassword
      Then Begin
        writeurec;
        writestr('Password changed.');
        writelog(1,1,'')
      End Else
        writestr('No change.')
    End;

  Procedure options(c:configtype;Var prompt,onstr,offstr:lstr);

    Procedure ret(x1,x2,x3:lstr);
      Begin
        prompt:=x1;
        onstr:=x2;
        offstr:=x3
      End;

    Begin
      Case c Of
        linefeeds:ret('Require line feeds','Yes','No');
        eightycols:ret('Screen width','80 columns','40 columns');
        postprompts:ret('Post prompts during newscan','Yes','No');
        moreprompts:ret('Pause every screen','Yes','No');
        asciigraphics:ret('Use IBM graphics characters','Yes','No');
        showtime:ret('Display time left at prompts','Yes','No');
        lowercase:ret('Upper/lower case','Upper or lower case','Upper case only');
        fseditor:ret('Use full-screen editor','Yes','No')
      End
    End;

  Function getattrib(fg,bk:Integer;Hi,bl:Boolean):Byte;
    Begin
      getattrib:=fg+(Byte(Hi) Shl 3)+(bk Shl 4)+(Byte(bl) Shl 7)
    End;

  Procedure getcolorvar(attr:Byte;Var fg,bk:Integer;Var Hi,bl:Boolean);
    Begin
      fg:=attr And 7;
      Hi:=(attr And 8)=8;
      bk:=(attr Shr 4) And 7;
      bl:=(attr And 128)=128
    End;

  Procedure getthing(c:configtype);
    Var n:Integer;
      name,onstr,offstr:lstr;
    Begin
      options(c,name,onstr,offstr);
      writehdr(name);
      Write('Current setting: '^S);
      If c In urec.config Then Write(onstr) Else Write(offstr);
      WriteLn(^B^M^M'Would you like:');
      WriteLn('  1. ',onstr);
      WriteLn('  2. ',offstr);
      writestr(^M'Your choice:');
      n:=valu(Input);
      If (n>0) And (n<3) Then Begin
        If n=2
        Then urec.config:=urec.config-[c]
        Else urec.config:=urec.config+[c];
        writeurec
      End
    End;

  Procedure writecolorstr(a:Byte);
    Var fg,bk:Integer;
      Hi,bl:Boolean;
    Begin
      getcolorvar(a,fg,bk,Hi,bl);
      ansicolor(a);
      If bl Then Write('Blinking ');
      If Hi Then Write('Highlighted ');
      Write(colorstr[fg]);
      If bk>0 Then Write(' on ',colorstr[bk])
    End;

  Function colorval(Str:mstr):Integer;
    Var cnt:Integer;
    Begin
      colorval:=-1;
      If match(Str,'None') Then Begin
        colorval:=0;
        exit
      End;
      For cnt:=0 To 7 Do
        If match(Str,colorstr[cnt]) Then Begin
          colorval:=cnt;
          exit
        End
    End;

  Procedure badcolor;
    Var cnt:Integer;
    Begin
      Write('Invalid color!  Valid colors are Black, ');
      For cnt:=1 To 7 Do Begin
        ansicolor(cnt);
        Write(colorstr[cnt]);
        If cnt=7
        Then WriteLn('.')
        Else Write(', ');
        If cnt=6
        Then Write(', and ');
      End;
      writestr('')
    End;

  Procedure getcolor(prompt:mstr;Var a:Byte);

    Procedure getacolor(Var q:Integer;prompt:mstr);
      Var n:Integer;
      Begin
        Repeat
          writestr('Enter new '+prompt+' color:');
          If hungupon Or (Length(Input)=0) Then exit;
          n:=colorval(Input);
          If n=-1
          Then badcolor
          Else q:=n
        Until n<>-1
      End;

    Var fg,bk:Integer;
      Hi,bl:Boolean;
    Begin
      If Not(ansigraphics In urec.config) Then Begin
        writestr('You must have ANSI emulation to see color.');
        exit
      End;
      getcolorvar(a,fg,bk,Hi,bl);
      Write('Current ',prompt,' color: ');
      writecolorstr(a);
      writestr(^M^M);
      getacolor(fg,'foreground');
      getacolor(bk,'background');
      writestr('Highlight the characters? *');
      Hi:=yes;
      writestr('Should the characters blink? *');
      bl:=yes;
      a:=getattrib(fg,bk,Hi,bl)
    End;

  Procedure emulation;
    Begin
      WriteLn(^B^M'Note:  ANSI is required for color.');
      WriteLn;
      WriteLn(^B'Please choose your terminal type.'^M^M,
      '   1. ANSI Color'^M,
      '   2. Emu-Term Emulation'^M,
      '   3. ASCII'^M);
      writestr('Emulation type:');
      If Length(Input)=0 Then exit;
      urec.config:=urec.config-[ansigraphics,vt52];
      Case valu(Input) Of
        1:urec.config:=urec.config+[ansigraphics];
        2:urec.config:=urec.config+[vt52]
      End
    End;

  Procedure getdisplaylen;
    Var v:Integer;
    Begin
      WriteLn('Current display length is: '^S,urec.displaylen);
      writestr(^M'Enter new display length:');
      If Length(Input)=0 Then exit;
      v:=valu(Input);
      If (v<21) Or (v>43)
      Then WriteLn('Invalid!')
      Else urec.displaylen:=v
    End;

  Procedure configurenewscan;
    Var bd:boardrec;
      bn:Integer;
      ac:accesstype;
    Begin
      opentempbdfile;
      Seek(bdfile,0);
      For bn:=0 To FileSize(bdfile)-1 Do Begin
        Read(bdfile,bd);
        ac:=getuseraccflag(urec,bn);
        If (ac=letin) Or ((ulvl>=bd.level) And (ac=bylevel)) Then Begin
          writestr('New scan area '+bd.boardname+' [Def: '+
          yesno(Not(bn In urec.newscanconfig))+']:');
          If Length(Input)<>0 Then
            If yes
            Then urec.newscanconfig:=urec.newscanconfig-[bn]
            Else urec.newscanconfig:=urec.newscanconfig+[bn]
        End
      End;
      closetempbdfile
    End;

  Procedure showit(s,v:lstr);
    Begin
      If break Then exit;
      tab(s+':',30);
      WriteLn(^S,v)
    End;

  Procedure showthing(CallIt:Char;c:configtype);
    Var n:Integer;
      name,onstr,offstr:lstr;
    Begin
      If break Then exit;
      options(c,name,onstr,offstr);
      tab(Callit+'> '+name+':',30);
      Write(^S);
      If c In urec.config
      Then Write(^S,onstr)
      Else Write(^S,offstr);
      WriteLn
    End;

  Procedure showemulation;
    Var q:lstr;
    Begin
      If ansigraphics In urec.config
      Then q:='ANSI Color'
      Else q:='Ascii Standard';
      showit('E> Terminal type',q)
    End;

  Procedure showdisplaylen;
    Begin
      showit('D> Display length',strr(urec.displaylen))
    End;

  Procedure showcolor(prompt:mstr;attr:Byte);
    Begin
      If break Then exit;
      tab('  '+prompt+' color:',30);
      writecolorstr(attr);
      WriteLn
    End;

  Procedure yourstatus;
    Begin
      writehdr('Current Setup');
      WriteLn(^B'Name : ',unam);

      showthing('L',linefeeds);
      showemulation;
      showdisplaylen;
{      WriteLn(^B'B> BBS Emulation # :',urec.emulation);}
      WriteLn('!> Password        : [Classified]');
        Write('C> Color mode      : ');
        if urec.highgraph=255 then writeln (^S'High Density') else
                              writeln (^S'Low Density');

      If ansigraphics In urec.config Then Begin
        showcolor('P> Prompt',urec.promptcolor);
        showcolor('I> Input',urec.inputcolor);
        showcolor('R> Regular',urec.regularcolor);
        showcolor('S> Statistic',urec.statcolor);

      End;

      Writeln ('Macro:',urec.macro);
    End;
  Procedure Get_Color_density;
    Var a,b:Integer;
      c,d:anystr;
    Begin
      Writehdr('Color Density');
      Writeln ('1. Regular Color Density');
      Writeln ('2. High Color density (KRAD)');
      Writestr('Enter New color density :');
      If Input='' Then exit;
      b:=valu(input);
      If (b>2) Or (b<1) Then exit;
      if b=2 then b:=255;
      Urec.highgraph:=b;
      writeurec;

    End;
    procedure Get_Macro;
    var a,b:anystr;
    begin
    Writehdr ('Macro Setting');
    Writeln ('Current Macro setting:');
    Writeln (Urec.macro);
    Writeln ('New setting:');
    Getstr;
    if input<>'' then urec.macro:=input;
    writeurec;
    end;

  Var q:Integer;
  Begin
    Repeat
      If ansigraphics In urec.config Then ansicls;
      yourstatus;


      q:=menu('Configuration','CONFIG','QLCOMGTUEDPIRSN!');
      Case q Of
        5:get_Macro;
        3:Get_Color_Density;
        2:getthing(linefeeds);
        9:emulation;
        10:getdisplaylen;
        11:getcolor('prompt',urec.promptcolor);
        12:getcolor('input',urec.inputcolor);
        13:getcolor('regular',urec.regularcolor);
        14:getcolor('statistic',urec.statcolor);
        15:configurenewscan;
        16:changepwd;
      End;
      writeurec
    Until (q=1) Or hungupon
  End;

Begin
End.
