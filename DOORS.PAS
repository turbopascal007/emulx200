  {$R-,S-,I-,D-,F+,V-,B-,N-,L+ ,O+}

  unit doors;

  Interface

  uses dos,gentypes,modem,configrt,statret,gensubs,subs1,subs2,
  userret,textret,overret1,mainr1,mainr2;

  Procedure doorsmenu;

  Implementation

Procedure doorsmenu;

  Function numdoors:Integer;
    Begin
      numdoors:=FileSize(dofile)
    End;

  Procedure seekdofile(n:Integer);
    Begin
      Seek(dofile,n-1)
    End;

  Procedure opendofile;
    Var i:Integer;
    Begin
      Assign(dofile,'Doors');
      Reset(dofile);
      If IOResult<>0 Then Begin
        Close(dofile);
        i:=IOResult;
        Rewrite(dofile)
      End
    End;

  Procedure maybemakebatch(fn:lstr);
    Var tf:Text;
      d:Boolean;
    Begin
      If Not issysop Then exit;
      writestr('Make new batch file '+fn+'? *');
      WriteLn(^M);
      If Not yes Then exit;
      Assign(tf,fn);
      Rewrite(tf);
      If IOResult<>0 Then Begin
        WriteLn('Couldn''t create file!');
        exit
      End;
      WriteLn('Enter text, blank line to end.'^M);
      Repeat
        writestr('=> &');
        d:=Length(Input)=0;
        If Not d Then WriteLn(tf,Input)
      Until d;
      textclose(tf);
      WriteLn(^M'Batch file created!');
      writelog(10,4,fn)
    End;

  Procedure getdoorinfo(Var d:doorrec);
    Var m:message;
    Begin
      WriteLn(^B^M'Enter information about this door:'^M);
      d.info:=editor(m,False,False)
    End;

  Function checkbatchname(Var qq):Boolean;
    Var i:lstr Absolute qq;
      p:Integer;
    Begin
      p:=Pos('.',i);
      If p<>0 Then i[0]:=Chr(p-1);
      i:=i+'.BAT';
      checkbatchname:=validfname(i)
    End;

  Procedure maybemakedoor;
    Var n:Integer;
      d:doorrec;
    Begin
      If Not issysop Then exit;
      n:=numdoors+1;
      writestr('Make new door #'+strr(n)+'? *');
      If Not yes Then exit;
      writestr(^M'Name:');
      If Length(Input)=0 Then exit;
      d.name:=Input;
      writestr('Access level:');
      If Length(Input)=0 Then exit;
      d.level:=valu(Input);
      writestr('Name/path of batch file:');
      If Length(Input)=0 Then exit;
      If Not checkbatchname(Input) Then Begin
        WriteLn('Invalid filename: '^S,Input);
        exit
      End;
      d.batchname:=doordir+Input;
      writestr('Ask user opening door for parameters? *');
      d.getparams:=yes;
      getdoorinfo(d);
      If d.info<0 Then exit;
      d.numused:=0;
      seekdofile(n);
      Write(dofile,d);
      If Not exist(d.batchname) Then Begin
        WriteLn(^B'Can''t open batch file ',d.batchname);
        maybemakebatch(d.batchname)
      End;
      WriteLn(^B^M'Door created!');
      writelog(10,3,d.name)
    End;

  Function haveaccess(n:Integer):Boolean;
    Var d:doorrec;
    Begin
      haveaccess:=False;
      seekdofile(n);
      Read(dofile,d);
      If ulvl>=d.level
      Then haveaccess:=True
      Else reqlevel(d.level)
    End;

  Procedure listdoors;
    Var d:doorrec;
      cnt:Integer;
    Begin
      writehdr('Doors available');
      seekdofile(1);
      WriteLn('Door Name                    Level Reqd  # of times used');
      For cnt:=1 To numdoors Do Begin
        Read(dofile,d);
        If ulvl>=d.level Then Begin
          Write(cnt:2,'. ');
          tab(d.name,30);
          WriteLn(d.level:3,d.numused:5);
          If break Then exit
        End
      End;
      WriteLn
    End;

  Function getdoornum(txt:mstr):Integer;
    Var g:Boolean;
      n:Integer;

    Begin
      getdoornum:=0;
      g:=False;
      Repeat
        listdoors;
        writestr('Door number to '+txt+' [?=list]:');
        WriteLn;
        If Input='?' Then listdoors Else g:=True
      Until g;
      If Length(Input)=0 Then exit;
      n:=valu(Input);
      If (n<1) Or (n>numdoors)
      Then WriteLn('Door number out of range!')
      Else If haveaccess(n)
        Then getdoornum:=n
    End;

  Procedure Pc_Board;
    Var a,b:lstr;
      FF:File Of lstr;
      Kool,cnt:Integer;
    Begin

      b:='QUICKDOR.exe';
      If Not exist(B) Then WriteLn(Usr,'** Get QUICKDOOR for PCBOARD doors!');
      a:='';
      a:=unam+',*,'+strr(baudrate)+',1,'+strr(timeleft)+',1';
      exec('QUICKDOR.EXE',a);

    End;

  Procedure opendoor;
    Var n,bd,p:Integer;
      d:doorrec;
      batchf,outf:Text;
      q:Boolean;
      tmp,params:lstr;
    Begin
      n:=getdoornum('open');
      If n=0 Then exit;
      seekdofile(n);
      Read(dofile,d);
      printtext(d.info);
      If d.getparams Then writestr('Parameters:') Else Input:='';
      params:=Input;
      p:=Pos('>',Input);
      If p=0 Then p:=Pos('>',Input);
      If p=0 Then p:=Pos('<',Input);
      If p=0 Then p:=Pos('|',Input);
      If p<>0 Then Begin
        writestr('You may not specify pipes in door parameters.');
        exit;
      End;
      Params:=strr(baudrate)+' '+Strr(timeleft)+' '+Strr(unum)+' '+Unam+' ';
      If ansigraphics In urec.config Then params:=params+'1 1' Else params:=params+'0 0';


      writestr(^M'Press [Space] to continue, or [X] to abort');
      If UpCase(waitforchar)='X' Then exit;
      WriteLn('Executing door: [',d.name,']');
      q:=True;
      Repeat
        Assign(batchf,d.batchname);
        Reset(batchf);
        If IOResult<>0 Then Begin
          q:=False;
          Close(batchf);
          iocode:=IOResult;
          If Not issysop
          Then
            Begin
              fileerror('Opendoor',d.batchname);
              exit
            End
          Else
            Begin
              maybemakebatch(d.batchname);
              If Not exist(d.batchname) Then exit
            End
        End
      Until q;
      Assign(outf,'DOOR.BAT');
      Rewrite(outf);
      WriteLn(outf,'TEMPDOOR ',params);
      textclose(outf);
      Assign(outf,'TEMPDOOR.BAT');
      Rewrite(outf);
      While Not EoF(batchf) Do Begin
        ReadLn(batchf,tmp);
        WriteLn(outf,tmp)
      End;
      If online Then bd:=baudrate Else bd:=0;
      GetDir(0,tmp);
      WriteLn(outf,'cd '+tmp);
      WriteLn(outf,'keepup ',unum,' ',bd,' ',Ord(parity),' D');
      textclose(batchf);
      textclose(outf);
      d.numused:=d.numused+1;
      seekdofile(n);
      Write(dofile,d);
      writelog(9,1,d.name);
      updateuserstats(False);
      writeurec;
      writestatus;
      ensureclosed;
      pc_board;
      Halt(e_door)
    End;

  Procedure getinfo;
    Var n:Integer;
      d:doorrec;
    Begin
      n:=getdoornum('get information on');
      If n=0 Then exit;
      seekdofile(n);
      Read(dofile,d);
      WriteLn;
      printtext(d.info)
    End;

  Procedure changedoor;
    Var n:Integer;
      d:doorrec;
    Begin
      n:=getdoornum('Change');
      If n=0 Then exit;
      seekdofile(n);
      Read(dofile,d);
      WriteLn('Name: ',d.name);
      writestr('New name:');
      If Length(Input)>0 Then d.name:=Input;
      WriteLn(^M'Level: ',d.level);
      writestr('New level:');
      If Length(Input)>0 Then d.level:=valu(Input);
      WriteLn(^M'Batch file name: ',d.batchname);
      writestr('New batch file name:');
      If Length(Input)>0 Then
        If checkbatchname(Input)
        Then d.batchname:=Input
        Else WriteLn('Invalid filename: '^S,Input);
      maybemakebatch(d.batchname);
      WriteLn;
      printtext(d.info);
      writestr(^M'Replace text [y/n]:');
      If yes Then
        Repeat
          deletetext(d.info);
          getdoorinfo(d);
          If d.info<0 Then WriteLn(^M'You must enter some information.')
        Until d.info>=0;
      seekdofile(n);
      Write(dofile,d);
      writelog(10,1,d.name)
    End;

  Procedure deletedoor;
    Var n,cnt:Integer;
      td,d:doorrec;
      f:File;
    Begin
      n:=getdoornum('delete');
      If n=0 Then exit;
      seekdofile(n);
      Read(dofile,d);
      writestr('Delete '+d.name+': Confirm:');
      If Not yes Then exit;
      WriteLn('Deleting...');
      seekdofile(n+1);
      For cnt:=n To FileSize(dofile)-1 Do Begin
        Read(dofile,td);
        seekdofile(cnt);
        Write(dofile,td)
      End;
      Seek(dofile,FileSize(dofile)-1);
      Truncate(dofile);
      deletetext(d.info);
      writestr(^M'Erase disk file '+d.batchname+'? *');
      If yes Then Begin
        Assign(f,d.batchname);
        Erase(f);
        If IOResult<>0 Then WriteLn('(File not found)')
      End;
      writelog(10,2,d.name)
    End;

  Procedure sysopdoors;
    Var q:Integer;
    Begin
      If (Not remotedoors) And carrier Then Begin
        writestr('Sorry, remote door maintenance is not allowed!');
        writestr('(Please re-configure to change this setting)');
        exit
      End;
      Repeat
        q:=menu('Sysop door','SDOORS','QCAD');
        Case q Of
          2:changedoor;
          3:maybemakedoor;
          4:deletedoor
        End
      Until hungupon Or (q=1) Or (FileSize(dofile)=0)
    End;

  Var q:Integer;
  Begin
    If Not allowdoors Then Begin
      writestr('No doors open! ');
      If issysop Then writestr('(Please re-configure to change this setting)');
      exit
    End;
    If fromdoor Then Begin
      fromdoor:=False;
      If returnto='D' Then writestr(^M^M^M'[System Return Successful]')
    End;

    cursection:=doorssysop;
    opendofile;
    If numdoors=0 Then Begin
      writestr('No doors exist!');
      maybemakedoor;
      If numdoors=0 Then Begin
        Close(dofile);
        exit
      End
    End;
    Writehdr('Doors open: '+strr(numdoors));
    Repeat
      q:=menu('Doors','DOORS','QLOIH%@G');
      Case q Of
        2:listdoors;
        3:opendoor;
        4:getinfo;
        5:help('Doors.hlp');
        6:sysopdoors;
        8:offtheforum;

      End
    Until hungupon Or (q=1) Or (FileSize(dofile)=0);
    Close(dofile)
  End;

Begin
End.
.  