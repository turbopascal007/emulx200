
  {$R-,S-,I-,D-,F+,V-,B-,N-,L+ }

  unit chatstuf;

  Interface

  uses dos,crt,
  gentypes,gensubs,subs1,userret,flags,mainr1,modem,windows,statret,configrt;

  Function specialcommand:Boolean;
  Procedure specialseries;
  Procedure chat(gotospecial:Boolean);
  procedure splitscreenchat(gotospecial:boolean);

  Implementation

Function specialcommand:Boolean;

  Procedure getnewtime;
    Var q:sstr;
      n:Integer;
    Begin
      n:=timeleft;
      WriteLn(Usr,'The user has ',n,' minutes left.');
      Write(Usr,'New time left for today? ');
      readline(q);
      If Length(q)>0 Then Begin
        urec.timetoday:=urec.timetoday+(valu(q)-n);
        writeurec;
        {      writeln ('You have been granted ',timeleft,' minutes for today.')
      }End
    End;

  Procedure getnewlevel;
    Var q:sstr;
      n:Integer;
    Begin
      WriteLn(Usr,'Current level: ',ulvl);
      Write(Usr,'New level [-1 to trash]: ');
      readline(q);
      If Length(q)>0 Then Begin
        n:=valu(q);
        ulvl:=n;
        urec.level:=n;
        writeurec;
        {    writeln ('You have been granted level ',n,' access.');
        if n=-1 then writeln ('That means you''ve been thrown off this system.')
      }End
    End;


  Procedure gfilez;
    Var q:sstr;
      n:Integer;
    Begin

      WriteLn(Usr,'Current Gfile level: ',urec.gflevel);
      Write(Usr,'New level : ');
      readline(q);
      If Length(q)>0 Then Begin
        n:=valu(q);
        urec.gflevel:=n;
        writeurec;
      End;

      WriteLn(Usr,'Current Gfile Points: ',urec.gpoints);
      Write(Usr,'New level : ');
      readline(q);
      If Length(q)>0 Then Begin
        n:=valu(q);
        urec.gpoints:=n;
        writeurec;
      End;

    End;


  Procedure hangupyn;
    Var q:sstr;
    Begin
      Write(Usr,'Hang up on him (Y/N)? ');
      readline(q);
      If Length(q)>0 Then If UpCase(q[1])='Y' Then
        Begin
          WriteLn('*** System going down ***    '^M^M);
          hangup;
          forcehangup:=True;
          specialcommand:=True
        End
    End;

  Procedure getnewname;
    Var m:mstr;
      n:Integer;
      t:String[1];
    Begin
      WriteLn(Usr,'Current name: ',unam);
      Write(Usr,'New name: ');
      readline(m);
      If Length(m)<>0 Then Begin
        If Not validuname(m) Then Begin
          WriteLn(Usr,'Invalid name!');
          exit
        End;
        n:=lookupuser(m);
        If n<>0 Then Begin
          Write(Usr,'Name already exists!  Are you sure? ');
          BufLen:=1;
          readline(t);
          If UpCase(t[1])<>'Y' Then exit
        End;
        unam:=m;
        urec.handle:=m;
        writeurec;
    End;End;

  Procedure getnewpassword;
    Var m:mstr;
    Begin
      WriteLn(Usr,'Current password: ',urec.password);
      Write(Usr,'New password: ');
      readline(m);
      If Length(m)<>0 Then Begin
        urec.password:=m;
        writeurec;
      End
    End;

  Procedure getnewudlvl;
    Var m:mstr;
       i:integer;
    Begin
      WriteLn(Usr,'Current upload L)evel:  ',urec.udlevel);
      write (usr,'New level:');
      readline(m);
      If Length(m)>0 Then Begin
      i:=valu(m);
      urec.udlevel:=i;
      writeurec;

      End
    End;

  Procedure getnewudpts;
    Var m:mstr;
       i:integer;
    Begin
      WriteLn(Usr,'Current upload Points:  ',urec.udpoints);
      write (usr,'New points:');
      readline(m);
      If Length(m)>0 Then Begin
      i:=valu(m);
      urec.udpoints:=i;
      writeurec;

      End
    End;

  Procedure snoopmode;
    Begin
      WriteLn(Usr,'All I/O to the modem is locked.');
      modeminlock:=True;
      setoutlock(True)
    End;

  Procedure unsnoop;
    Begin
      WriteLn(Usr,'I/O to the modem is re-enabled.');
      modeminlock:=False;
      setoutlock(False)
    End;

  Procedure gotodos;
    Begin
      WriteLn(Usr,^M^M'Type ''Exit'' to return from dos!');
      exec(getenv('COMSPEC'),'');
    End;

  Procedure getsysopaccess;
    Const sysopstr:Array[false..true] Of String[6]=('Normal','Sysop');
      sectionnames:Array[udsysop..databasesysop] Of String[20]=
      ('File transfer','Bulletin section','Voting booths',
      'E-mail section','Doors','Main menu','Databases');
    Var cnt:configtype;
      x:String[10];
      n,mx:Integer;
      v:Boolean;
    Begin
      Repeat
        ClrScr;
        mx:=1;
        For cnt:=udsysop To databasesysop Do Begin
          Write(Usr,mx:3,'. ',sectionnames[cnt]);
          mx:=mx+1;
          GoToXY(25,WhereY);
          WriteLn(Usr,sysopstr[cnt In urec.config])
        End;
        Write(Usr,^M^J'Number to toggle [CR to exit]: ');
        BufLen:=1;
        readline(x);
        n:=valu(x);
        v:=(n>0) And (n<mx);
        If v Then Begin
          cnt:=configtype(Ord(udsysop)+n-1);
          If cnt In urec.config
          Then
            Begin
              urec.config:=urec.config-[cnt];
              x:='denied'
            End
          Else
            Begin
              urec.config:=urec.config+[cnt];
              x:='granted'
            End;
          {      writeln ('You have been ',x,' sysop priveleges for the ',
          sectionnames[cnt],'.')
        }End
      Until Not v;
      writeurec
    End;

  Procedure Fuck_you;
    Var q:sstr;
    Begin
      Write(Usr,'Give ''em the finger [y/N/Killem]? ');
      readline(q);
      If Length(q)>0 Then If (UpCase(q[1])='Y') or (upcase(q[1])='K') Then
        Begin
        if vt52 in urec.config then wvt52 (#234+#234+#13) else begin

          dontstop:=True;
          WriteLn('                  ÛÛ               ');
          WriteLn('                 ÛฐฐÛ              ');
          WriteLn('                 ÛฐฐÛ              ');
          WriteLn('                 ÛฐฐÛ              ');
          WriteLn('                 ÛฐฐÛ              ');
          WriteLn('          ÛÛ  ÛÛ ÛฐฐÛ ÛÛ           ');
          WriteLn('         ÛฑฑÛÛฑฑÛÛฐฐÛÛฑฑÛ          ');
          WriteLn('         ÛฑฑÛฑฑฑÛÛฐฐÛฑฑฑÛ          ');
          WriteLn('        Û ÛÛ ÛÛÛ ÛฐฐÛÛฑฑÛ    ÛÛÛ   ');
          WriteLn('        Ûฒฒฒฒ ฒฒฒ ฒฒ ฒÛÛ    ÛฑฑฑÛ  ');
          WriteLn('        Û ฒฒฒฒ ฒฒ ฒฒ ฒฒ ÛÛÛÛฑฑฑฑÛ  ');
          WriteLn('        Û                   ฑฑฑÛ   ');
          WriteLn('         Û                    Û    ');
          WriteLn('         Û                    Û    ');
          WriteLn('          Û                   Û    ');
          WriteLn('           Û                Û      ');
          WriteLn('             Û             Û       ');
          WriteLn('             Û             Û       ');
          WriteLn('             Û             Û       ');
          WriteLn('                             (tm) Emulex/2 Productions Inc.');
          end;
       if upcase(q[1])='K' then begin
               ulvl:=-1;
               urec.level:=-1;
              end;
          writeurec;delay(5000);
          hangup;
          forcehangup:=True;
          specialcommand:=True
        End
    End;
procedure Pulldownmenu;

procedure cursor (csize : byte);
var regs : registers;
var c:char;
    x,y,z,a:integer;
    dir:string[127];

begin
exit;
   case (csize) of
      1 : if mem[0:$449] = 7 then regs.cx := $0c0d  { underline  = 1 }
          else regs.cx := $0607;
      2 : if mem[0:$449] = 7 then regs.cx := $060d  { full Block = 2 }
          else regs.cx := $0007;
      3 : regs.cx := $2000;                         { no Cursor  = 3 }
   end;
   regs.ax := $0100;
{   intr($10,regs);}
end;

procedure ahigh (x:integer);
var c:char;
    y,z,a:integer;
    dir:string[127];

begin
    case x of
      1:begin
            gotoxy (2,3);
            textbackground (4);
            textcolor (15);
            write (usr,' Root Directory ');
            textbackground (15);
            textcolor (4);
        end;
      2:begin
            gotoxy (2,4);
            textbackground (4);
            textcolor (15);
            write (usr,' Other Dir...   ');
            textbackground (15);
            textcolor (4);
        end;
    end;
end;


procedure high (x:integer);
begin
     case x of
      1:begin
            gotoxy (2,1);
            textbackground (4);
            textcolor (15);
            write (usr,' User1 ');
        end;
      2:begin
            gotoxy (10,1);
            textbackground (4);
            textcolor (15);
            write (usr,' User2 ');
        end;
      3:begin
            gotoxy (18,1);
            textbackground (4);
            textcolor (15);
            write (usr,' Dos   ');
        end;
      4:begin
            gotoxy (26,1);
            textbackground (4);
            textcolor (15);
            write (usr,' finger  ');
        end;
      5:begin
            gotoxy (36,1);
            textbackground (4);
            textcolor (15);
            write (usr,' hangup ');
        end;
      6:begin
            gotoxy (45,1);
            textbackground (4);
            textcolor (15);
            write (usr,' time   ');
        end;
      7:begin
            gotoxy (51,1);
            textbackground (4);
            textcolor (15);
            write (usr,' Help ');
        end;
      8:begin
            gotoxy (58,1);
            textbackground (4);
            textcolor (15);
            write (usr,' Quit ');
        end;
     end;
end;

procedure dohelp;
begin
     gotoxy (50,10);
     textbackground (3);
     textcolor (14);
     writeln (usr,'ษออออออออออออออออออออออป');
     gotoxy (50,11);
     write (usr,'บ  ');
     textcolor (15);
     write (#27#26#25#24+' - Move Bar');
     textcolor (14);
     writeln (usr,'     บ');
     gotoxy (50,12);
     write (usr,'บ ');
     textcolor (15);
     write (usr,' [Return] - Select');
     textcolor (14);
     writeln (usr,'   บ');
     gotoxy (50,13);
     write (usr,'บ ');
     textcolor (15);
     write (usr,' ESC - Quits to Main ');
     textcolor (14);
     writeln (usr,'บ');
     gotoxy (50,14);
     writeln (usr,'ศออออออออออออออออออออออผ');
     repeat
     until keypressed;
end;


procedure changedir2;
var c:char;
    x,y,z,a:integer;
    dir:string[127];

begin
     gotoxy (6,10);
     textbackground (4);
     textcolor (15);
     writeln (usr,'ษอออ Enter Directory ออออออออออออออป');
     gotoxy (6,11);
     writeln (usr,'บ                                  บ');
     gotoxy (6,12);
     writeln (usr,'ศออออออออออออออออออออออออออออออออออผ');
     gotoxy (8,11);
     textcolor (14);
     cursor (2);
     readln (dir);
     if doserror <> 0 then begin
       gotoxy (1,14);
       textcolor (15);
       textbackground (0);
       cursor (3);
       writeln (usr,'Invalid Directory!');
       exit;
     end;
     chdir (dir);
     cursor (3);
     textbackground (0);
     gotoxy (6,10);
     clreol;
     gotoxy (6,11);
     clreol;
     gotoxy (6,12);
     clreol;
end;

procedure changedir;
var c:char;
    x,y,z,a:integer;
    dir:string[127];

begin
     textbackground (15);
     textcolor (4);
     ahigh (y);
     gotoxy (1,2);
     writeln (usr,'ษออออออออออออออออป');
     writeln (usr,'บ Root Directory บ');
     writeln (usr,'บ Other Dir...   บ');
     writeln (usr,'ศออออออออออออออออผ');
     textbackground (15);
     textcolor (4);
     gotoxy (2,1);
     ahigh (y);
     repeat
       c:=readkey;
       c:=upcase (c);
     until c in [#77,#75,#72,#80,#27,#13];
     if (c=#77) or (c=#80) then y:=y+1;
     if (c=#75) or (c=#72) then y:=y-1;
     if y=3 then y:=1;
     if y=0 then y:=2;
     if c=#27 then exit;
     if c=#13 then begin;
       case y of
        1:chdir('\');
        2:changedir2;
       end;
     end;
    changedir
end;

procedure makedir;
var c:char;
    x,y,z,a:integer;
    dir:string[127];

begin
     gotoxy (6,10);
     textbackground (4);
     textcolor (15);
     writeln (usr,'ษอออ Enter Directory ออออออออออออออป');
     gotoxy (6,11);
     writeln (usr,'บ                                  บ');
     gotoxy (6,12);
     writeln (usr,'ศออออออออออออออออออออออออออออออออออผ');
     gotoxy (8,11);
     textcolor (14);
     cursor (2);
     readln (dir);
     if doserror <> 0 then begin
      writeln (usr,'Invalid Directory Name!');
      cursor (3);
      exit;
     end;
     mkdir (dir);
     cursor (3);
     textbackground (0);
     gotoxy (6,10);
     clreol;
     gotoxy (6,11);
     clreol;
     gotoxy (6,12);
     clreol;
end;

procedure copyproc;
var c:char;
    x,y,z,a:integer;
    dir:string[127];

var cf,ct:string;
begin
     gotoxy (1,8);
     textcolor (14);
     textbackground (1);
     writeln (usr,'ษออ Copy อออออออออออออออออออออออออออออออออออออออออออป');
     writeln (usr,'บ                                                   บ');
     writeln (usr,'ศอออออออออออออออออออออออออออออออออออออออออออออออออออผ');
     cursor (2);
     gotoxy (3,9);
     textcolor (15);
     readln (cf);
     if doserror <> 0 then begin
       writeln (usr,'Invalid Filename or File doesn''t Exist!');
       exit;
     end;
     gotoxy (1,12);
     textcolor (14);
     writeln (usr,'ษออ To อออออออออออออออออออออออออออออออออออออออออออออป');
     writeln (usr,'บ                                                   บ');
     writeln (usr,'ศอออออออออออออออออออออออออออออออออออออออออออออออออออผ');
     gotoxy (3,13);
     textcolor (15);
     readln (ct);
     if length(ct)=0 then begin
       writeln (usr,'Invalid Directory or Filename!');
       exit;
     end;
     gotoxy (1,17);
     textcolor (11);
     textbackground (0);
     write (usr,'Copying ');
     textcolor (15);
     write (cf);
     textcolor (11);
     write (usr,' to ');
     textcolor (15);
     write (ct);
     textcolor (11);
     write (usr,'.');
     exec(getenv('COMSPEC'),'/C copy '+cf+' '+ct);
     gotoxy (1,8);
     for a:=8 to 18 do begin
      gotoxy (1,a);
      clreol;
     end;
     cursor (3);
     delay (1000);
end;

procedure moveproc;
var mf,mt:string;
var c:char;
    x,y,z,a:integer;
    dir:string[127];

begin
     gotoxy (1,8);
     textcolor (14);
     textbackground (1);
     writeln (usr,'ษออ Move อออออออออออออออออออออออออออออออออออออออออออป');
     writeln (usr,'บ                                                   บ');
     writeln (usr,'ศอออออออออออออออออออออออออออออออออออออออออออออออออออผ');
     cursor (2);
     gotoxy (3,9);
     textcolor (15);
     readln (mf);
     if length(mf)=0 then begin
       writeln (usr,'Invalid Filename!');
       exit;
     end;
     gotoxy (1,12);
     textcolor (14);
     writeln (usr,'ษออ To อออออออออออออออออออออออออออออออออออออออออออออป');
     writeln (usr,'บ                                                   บ');
     writeln (usr,'ศอออออออออออออออออออออออออออออออออออออออออออออออออออผ');
     gotoxy (3,13);
     textcolor (15);
     readln (mt);
     if length(mt)=0 then begin
       writeln (usr,'Invalid Directory or Filename!');
       exit;
     end;
     gotoxy (1,16);
     textcolor (11);
     write (usr,'Moving ');
     textcolor (15);
     write (mf);
     textcolor (11);
     write (usr,'to ');
     textcolor (15);
     write (mt);
     textcolor (11);
     write (usr,'.   ');
     exec(getenv('COMSPEC'),'/C MOVE '+MF+' '+MT);
     if doserror <> 0 then writeln (usr,'MOVE.COM not found!');
     textbackground (0);
     for a:=8 to 25 do begin
      gotoxy (1,a);
      clreol;
     end;
     cursor (3);
     delay (1000);
end;
procedure bhigh (x:integer);
var c:char;
    y,z,a:integer;
    dir:string[127];

begin
     case x of
       1:begin
             gotoxy (27,3);
             textcolor (15);
             textbackground (4);
             write (usr,' Name     ' );
         end;
       2:begin
             gotoxy (27,4);
             textcolor (15);
             textbackground (4);
             write (usr,' Password  ');
         end;
       3:begin
             gotoxy (27,5);
             textcolor (15);
             textbackground (4);
             write (usr,' Level    ');
         end;
       4:begin
             gotoxy (27,6);
             textcolor (15);
             textbackground (4);
             write (usr,' File Level');
         end;
       5:begin
             gotoxy (27,7);
             textcolor (15);
             textbackground (4);
             write (usr,' Gfile Lvl');
         end;
       6:begin
             gotoxy (27,8);
             textcolor (15);
             textbackground (4);
             write (usr,' File Point');
         end;

     end;
end;

procedure execcmds;
var c:char;
    x,y,z,a:integer;
    dir:string[127];
    DD:boolean;
begin
z:=0;          dd:=false;
repeat
     gotoxy (26,2);
     textbackground (0);
     textcolor (4);
     writeln (usr,'ษอออออออออออป');
     gotoxy (26,3);
     writeln (usr,'บ Name      บ');
     gotoxy (26,4);
     writeln (usr,'บ Password  บ');
     gotoxy (26,5);
     writeln (usr,'บ Level     บ');
     gotoxy (26,6);
     writeln (usr,'บ File Levelบ');
     gotoxy (26,7);
     writeln (usr,'บ GFle Levelบ');
     gotoxy (26,8);
     writeln (usr,'บ File Pointบ');
     gotoxy (26,9);
     writeln (usr,'ศอออออออออออผ');
     textbackground (15);
     textcolor (4);
     bhigh (z);
     repeat
       c:=readkey;
       c:=upcase(c);
     until c in [#77,#75,#72,#80,#27,#13,#3];
     if (c=#77) or (c=#80) then z:=z+1;
     if (c=#75) or (c=#72) then z:=z-1;
     if z=0 then z:=7;
     if z=8 then z:=1;
     if c=#27 then dd:=true;
{     if c=#3 then halt(0);}
     if c=#13 then begin
     gotoxy(1,13);
      case z of
        1:getnewname;
        2:getnewpassword;
        3:getnewlevel;
        4:getnewudlvl;
        5:gfilez;
        6:getnewudpts;
       end;
     end;
     until dd=true;
end;
procedure firstbar;
var c:char;
    x,y,z,a:integer;
    dir:string[127];
    done:boolean;

begin
done:=false;x:=1;y:=1;z:=1;
     repeat

     textbackground(0);
     clrscr;
     textbackground (15);
     textcolor (4);
     writeln (usr,' User1   User2    Dos     Finger    Hangup   Time  Help   Quit                  ');
     high (x);
     repeat until keypressed;
     repeat
       c:=readkey;
       c:=upcase(c);
     until c in [#77,#75,#13,#3,#27];
     if c=#27 then done:=true;
     if c=#77 then x:=x+1;
     if c=#75 then x:=x-1;
     if x=9 then x:=1;
     if x=0 then x:=8;
     if c=#13 then begin
      case x of
       1:execcmds;
 {      2:makedir;}
       3:gotodos;
       4:fuck_you;
       5:hangupyn;
       6:getnewtime;
{       7:dohelp;}
       8:done:=true;
      end;
     end;
until done;
end;

    begin
     clrscr;
     firstbar;
    end; {pulldownmenu}

  Var scom:sstr;
    k:Char;
  Begin

    {splitscreen(12);
    top;
    ClrScr;
    specialcommand:=False;
    WriteLn(Usr,'[N]ame  [P]assword  [L]evel [T]ime   [H]ang up [G]files');
    WriteLn(Usr,'[Y]CoSysop access   [D]OS   [F]inger [Q]uit [U]files [E]xternal Edit');
    Write(Usr,'Command: ');
    readline(scom);
    clearbreak;
    k:=' ';
    If Length(scom)>0 Then Begin
      k:=UpCase(scom[1]);

      Case k Of
        'F' :Fuck_you;
        'L' :getnewlevel;
        'H' :hangupyn;
        'N' :getnewname;
        'P' :getnewpassword;
        'L' :getnewlevel;
        'T' :getnewtime;
        'U' :getnewud;
        'S' :snoopmode;
        'Z' :unsnoop;
        'Y' :getsysopaccess;
        'D' :gotodos;
        'G' :gfilez;
        'E' : begin
              Writeurec;
              exec ('USEREDIT.COM','');
              clrscr;
              Readurec;
              end;
      End
    End;
    bottomline;
    specialcommand:=k In ['Q','S','Z'];
    unsplit}

    Pulldownmenu;
    specialcommand:=true;
  End;

Procedure specialseries;
  Begin
    WriteLn(^B^M'[ Please Wait ]');

    Repeat Until specialcommand
  End;

Procedure chat(gotospecial:Boolean);
  Var k:Char;
    cnt,displaywid:Integer;
    quit,carrierloss,fromkbd:Boolean;
    linebuffer:lstr;
    l:Byte Absolute linebuffer;
    curcolor:Byte;

  Procedure instruct;
    Begin
      splitscreen(3);
      top;
      ClrScr;
      Write(Usr,'Chat mode! [F1] to end chat, or [F2] for commands.');
      bottom
    End;

  Procedure wordwrap;
    Var cnt,wl:Integer;
      ww:lstr;
    Begin
      ww:='';
      cnt:=displaywid;
      While (cnt>0) And (linebuffer[cnt]<>' ') Do cnt:=cnt-1;
      If cnt=0 Then ww:=k Else Begin
        ww:=Copy(linebuffer,cnt+1,255);
        wl:=Length(ww)-1;
        If wl>0 Then Begin
          For cnt:=1 To wl Do Write(^H);
          For cnt:=1 To wl Do Write(' ')
        End
      End;
      WriteLn;
      ansicolor(curcolor);
      Write(ww);
      linebuffer:=ww
    End;

  Procedure typedchar(k:Char);
    Var ec:Byte;
    Begin
      l:=l+1;
      linebuffer[l]:=k;
      If fromkbd Then ec:=urec.regularcolor Else ec:=urec.inputcolor;
      If curcolor<>ec Then Begin
        curcolor:=ec;
        ansicolor(curcolor)
      End;
      If l=displaywid Then wordwrap Else Write(k)
    End;

  Begin
    carrierloss:=False;
    chatmode:=False;
    WriteLn(^B^M);
    If wanted In urec.config Then Begin
      specialmsg('(No longer wanted)');
      urec.config:=urec.config-[wanted];
      writeurec;
    End;
    If eightycols In urec.config Then displaywid:=80 Else displaywid:=40;
    If Length(chatreason)>0 Then specialmsg('>>>Chat reason: '+chatreason+')');
    chatreason:='';
    If gotospecial Then Begin
      specialseries;
      exit
    End;
    clearbreak;
    nobreak:=True;
    if vt52 in urec.config then wvt52 (#234+#234+#15);
    double_check:=false;

    WriteLn(^M^M,sysopname,' wants to chat.'^M);
    instruct;
    quit:=False;
    l:=0;
    curcolor:=urec.regularcolor;
    Repeat
      linecount:=0;
      If (Not carrierloss) And (Not carrier) Then Begin
        carrierloss:=True;
        WriteLn(^M' shit! No one''s here to chat with!'^M)
      End;
      Repeat Until keyhit Or (carrier And (numchars>0));
      fromkbd:=keyhit;
      ingetstr:=True;
      Read(directin,k);
      If k=#127 Then k:=#8;
      If requestchat
      Then If requestcom
        Then
          Begin
            quit:=specialcommand;
            If Not quit Then instruct;
            clearbreak;
            nobreak:=True;
            l:=0
          End
        Else
          Begin
            unsplit;
            quit:=True
          End;
          if (vt52 in urec.config) and (fromkbd=false) then modemoutlock:=true;
      Case Ord(k) Of
        8:If l>0 Then Begin
            Write(k+' '+k);
            l:=l-1
          End;
        0:;
        13:Begin
             WriteLn;
             bottomline;
             l:=0
           End;
        32..126:typedchar(k);
        1..31:If fromkbd And carrier Then sendchar(k)
      End;
      if vt52 in urec.config then modemoutlock:=false;
    Until quit;
    if vt52 in urec.config then wvt52 (#234+#234+#16);
    if vt52 in urec.config then double_check:=true;
    clearbreak;
  End;
Procedure Splitscreenchat(gotospecial:Boolean);
  Var k:Char;
    cnt,displaywid:Integer;
    quit,carrierloss,fromkbd:Boolean;
    linebuffer:lstr;
    l:Byte Absolute linebuffer;
    curcolor:Byte;
    USRLASTX,USRLASTY,SYSLASTX,SYSLASTY:byte;
    SlineA,Slineb,Ulinea,Ulineb:lstr;


      Procedure AnsiGotoxy(x,y:Integer);
    Begin


      Write(direct,#27'[');
      If y<>1 Then Write(direct,strr(y));
      If x<>1 Then Write(direct,';',strr(x));
      Write('H');
    End;

      Procedure cleareol;
    Begin
      Write(direct,#27'[K')
    End;

  Procedure instruct;
    Begin
{      splitscreen(3);
      top;}
      window (1,1,80,25);
      ClrScr;
     { Write(Usr,'Split Screen Chat! [F1] to end, or [F2] for commands.');
      bottom;}
    End;

    procedure BlankLine(y1,y2:byte);
    var cnt:integer;

    begin
      for cnt:=y1 to y2 do begin
      ansigotoxy (1,cnt);
      cleareol;
     end;

    end;

    procedure Writea(xx:anystr);
    begin
    if fromkbd then begin
    if ((wherex<>syslastx) or (wherey<>syslasty)) then ansigotoxy (syslastx,syslasty);

    write(xx);
    if wherey<5 then begin slinea:=''; slineb:=''; end;
    if wherey=11 then slinea:=slinea+xx else
    if wherey=12 then slineb:=slineb+xx;

    if fromkbd then begin syslastx:=wherex; syslasty:=wherey; end;

        if fromkbd and (wherey>12) then begin
      blankline (1,12);syslastx:=1;syslasty:=4;ansigotoxy (1,1);
      write (slinea);writeln(slineb);
      end;

    end else begin

     if ((wherex<>usrlastx) or (wherey<>usrlasty)) then ansigotoxy(usrlastx,usrlasty);
        write (xx);
    if wherey<18 then begin ulinea:=''; ulineb:=''; end;
    if wherey=21 then ulinea:=ulinea+xx else
    if wherey=22 then ulineb:=ulineb+xx;

    if not fromkbd then begin usrlastx:=wherex; usrlasty:=wherey; end;

      if (not fromkbd) and (wherey>22) then begin
      blankline (14,23); usrlastx:=1; usrlasty:=17; ansigotoxy (1,14);
      write(ulinea);writeln(ulineb);
      end;

      end;
    end;


  Procedure wordwrap;
    Var cnt,wl:Integer;
      ww:lstr;
    Begin
      ww:='';
      cnt:=displaywid;
      While (cnt>0) And (linebuffer[cnt]<>' ') Do cnt:=cnt-1;
      If cnt=0 Then ww:=k Else Begin
        ww:=Copy(linebuffer,cnt+1,255);
        wl:=Length(ww)-1;
        If wl>0 Then Begin
          For cnt:=1 To wl Do Write(^H);
          For cnt:=1 To wl Do Write(' ')
        End
      End;
      WriteLn;
      ansicolor(curcolor);
      Write(ww);
      linebuffer:=ww
    End;

  Procedure typedchar(k:Char);
    Var ec:Byte;
    Begin
{      l:=l+1;}
{      linebuffer[l]:=k;}

      If fromkbd Then ec:=urec.regularcolor Else ec:=urec.inputcolor;
      If curcolor<>ec Then Begin
        curcolor:=ec;
        ansicolor(curcolor);
      End;

      Writea(k);
    End;

    Procedure ansicls;
    Begin
     Write(direct,#27'[2J')
    End;


  Begin
      instruct;

  ansicls;
  syslastx:=1; syslasty:=1;
  usrlastx:=1; usrlasty:=14;
{  blankline(1,2);}
  fromkbd:=false;Writea (' ');
    carrierloss:=False;
    chatmode:=False;
{    WriteLn(^B^M);  }

    displaywid:=80;
    If Length(chatreason)>0 Then specialmsg('>>>Chat reason: '+chatreason+')');
{      blankline(14,22);}

    chatreason:='';
    If gotospecial Then Begin
      specialseries;
      exit
    End;
    clearbreak;
    nobreak:=True;
    double_check:=false;
    fromkbd:=true;
    Writea(sysopname+' wants to chat.'+^M);
    ansigotoxy(syslastx,syslasty);
         ansigotoxy (1,13);
write (direct,'[_________________________Emulex/2 2-Way Chat______________________________]');

    quit:=False;
    l:=0;
    curcolor:=urec.regularcolor;
    Repeat
      linecount:=0;
      If (Not carrierloss) And (Not carrier) Then Begin
        carrierloss:=True;
        Writea(^M' shit! No one''s here to chat with!'^M)
      End;
      Repeat Until keyhit Or (carrier And (numchars>0));
      fromkbd:=keyhit;
      ingetstr:=True;
      if (not fromkbd) then      k:=getchar else

      read(directin,k);

      if k='^' then fromkbd:=false;
      if k='~' then begin fromkbd:=false; k:=#13; end;
      If k=#127 Then k:=#8;
      If requestchat
      Then If requestcom
        Then
          Begin
            quit:=specialcommand;
            If Not quit Then instruct;
            clearbreak;
            nobreak:=True;
            l:=0
          End
        Else
          Begin
            unsplit;
            quit:=True
          End;
      Case Ord(k) Of
        8:if wherex>0 Then Begin
            Writea(k+' '+k);
          End;
        0:;
        13:Begin
          if fromkbd then   if (wherey<5) then begin slinea:=''; slineb:=''; end;
          if (not fromkbd) then if (wherey<18) then begin ulinea:=''; ulineb:='';end;
             typedchar(^M);
             bottomline;
             l:=0
           End;
        32..126:typedchar(k);
        1..31:If fromkbd And carrier Then sendchar(k)
      End;
    Until quit;
    clearbreak;
  End;

Begin
End.
