{$R-,S-,I-,D-,F+,V-,B-,N-,O+ }

unit main;

interface

uses crt,overlay,
     gentypes,modem,gensubs,subs1,subs2,userret,overret1,mainr2,
     bulletin,configur,database,doors,email,filexfer,mycomman,voting,
     mainmenu,gfiles,trivia,configrt,viewansi;

procedure mainsysopcommands;
procedure mainmenuproc;
procedure breakout;

implementation

procedure mainsysopcommands;
var q:integer;
begin
  repeat
    q:=menu ('Sysop Commands','SYSOP','QTEANDUCIJSKVMFRZ');
    case q of
      2:editoldspecs;
      3:readerrlog;
      4:addnews;
      5:editnews;
      6:delerrlog;
      7:editusers;
      8:settime;
      9:infoformhunt;
      10:showallforms;
      11:viewsyslog;
      12:delsyslog;
      13:showallsysops;
      14:makeuser;
      15:readfeedback;
      16:removeallforms;
      17:zapspecifiedusers;
    end
  until (q=1) or hungupon
end;

procedure mainmenuproc;
var q:integer;
begin
  repeat
    if fromdoor and (returnto='D') then doorsmenu;
    cursection:=mainsysop;
   { gojoe;}
  if ulvl>=level_to_use_rumors then  listarumor;
    q:=menu ('Main','MAIN','ABCDETGHIJKLMNOPQRSFUVWXYZ+-!&$%@^#');
    writeln;
    case q of
      1:aboutthisbbs('');
      2:if ulvl>=level_to_use_bbslist then otherbbs;
      3:summonsysop;
      4:datamenu;
      5:emailmenu;
      6:feedback;
      7:offtheforum;
      8:mainhelp;
      9:infoform;
      10:if ulvl>=level_to_use_gambling then mycommand;

      11:writeln ('Keep America White and Beautiful!');

      12:if ulvl>=level_to_use_listusers then listusers;
      13:bulletinmenu;
      14:printnews;
      15:doorsmenu;
      16:if ulvl>=level_to_use_leechlist then make_leech_list;
      17:write (^M+'That command not available from this menu.'+^M);
      18:if ulvl>=level_to_use_rumors then rumors(0);
      19:showsystemstatus;
      20:udsection;
      21:configure;
      22:votingbooth (false);
      23:showlastcallers;
      24:transfername;
      25:yourstatus;
      26:setlastcall;
      27:;
      28:write (^M+'That command not available from this menu.'+^M);
      29:requestRaise;
      30:showad;
      31:donations;
      32:mainsysopcommands;
      -1:if ulvl>=level_to_use_timebank then put_time_bank;
      -2:get_time_bank;
      -3:if ulvl>=level_to_use_trivia then playtrivia;
      -4:viewansiscreens;

    end
  until hungupon
end;

procedure breakout;
begin
{closeallcoms;  }
  if (erroraddr=nil) and (exitcode=e_controlbreak) then begin
    textcolor (7);
    textbackground (0);
    updateuserstats (false);
    writeln (direct,' [ System Halt ]');
    writereturnbat;
    ensureclosed;
    window (1,1,80,25);
    gotoxy (1,25);
    clreol;
    if not carrier then dontanswer
  end;
  doneexitproc
end;

{$F-}

begin
  addexitproc (@breakout)
end.

