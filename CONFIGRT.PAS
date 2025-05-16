
unit configrt;

interface

uses gentypes;

var versioncode:byte;
    qr:longint;
    longname,shortname,sysopname,forumdir,textdir,uploaddir,boarddir,
    overlaypath,asciidownload,textfiledir,doordir,
    modemsetupstr,modemhangupstr,modemdialprefix,modemdialsuffix,appear,
    disappear:lstr;
    defbaudrate,usecom,anonymouslevel,numwelcomes,mintimeout,
    sysoplevel,defudlevel,defudpoints,
    normbotcolor,normtopcolor,outlockcolor,splitcolor,statlinecolor,
    uploadfactor,lvltoloan,timerestlvl,howmuchtime,maxloan,maxdebt:integer;
    private,autologin,useconmode,escinmsgs,bkspinmsgs,requireforms,
    allowloan,usematrix,newusermatrix,echoit:boolean;
    dotchar:char;
    supportedrates,downloadrates:baudset;
    availtime,unavailtime,xmodemopentime,xmodemclosetime,timereststart,
    timerestend:sstr;
    usertime:array [1..100] of integer;
    level2nd,udlevel2nd,udpoints2nd,postlevel,msgnextlvl:integer;
    anonymousstr,systempassword,system2password,system3password,telenumber:mstr;
    remotedoors,allowdoors,useqr,usecliche:boolean;
    eventtime,eventbatch:sstr;
    dszport,qrlimit,qrmultifactor,ultimefactor,ulpercent:integer;
    dszlog,sklog,newusernote,dszfn,dsz2fn,jmodemfn,lynxfn,jbatchfn,
    super8kfn:mstr;
    availstr,notavailstr,cliche:lstr;
    directvideomode,checksnowmode,hashayes,hangnewusers,discunvalid:boolean;
    qrexempt,mutation1,mutation2,mutation3:integer;
    pkarc,pkarc2,pak,pkzip,titlestr,sendstr:lstr;
    sysopmacro1,sysopmacro2,sysopmacro3,sysopmacro4,sysopmacro5,
    sysopmacro6,sysopmacro7,sysopmacro8,sysopmacro9,sysopmacro10:lstr;
    xlaston,matrixtype,readanonlvl,listuserlvl:integer;
    checkautologin,usetrivia,atmenu:boolean;
    notitle,emailing,ems,periods,datascrambling,scrambled,slash,matrixfback,
    matrixreqchat,noscramble,nosendprompt,screenoutput,leechzmodem,
    userumor,filepw:boolean;
    scr,mnplevel,xferpcr,gfpcr,doorpcr,triviapcr,pcrexempt,bnum,
    bkscrollmax:integer;
    {emu}
    tonextuserlevel,minimumleveltolistusers:integer;
    security,timeexempt,pcr,gfratio,ratlevel:integer;
    extender,dream:lstr;
    discon:boolean;
    timestart,timestop:sstr;
    pcpaccount,pcpnode,OffHookLine,bimodemdir,netfiledir,xferpcrlist,gfilepcrlist:mstr;
    timepercentback, leveltouseemumail:integer;

    returning:mstr;
    Level_To_use_rumors,Level_to_use_bbslist,Level_to_use_Listusers,level_to_use_gambling,
    level_To_use_leechlist,level_to_use_timebank,Level_to_use_trivia:integer;
    MatrixFeedback:Boolean;
    editor,codekey,commandcom:lstr;
    RTS_handle,CTS_handle:boolean;
    filler:array [1..2500] of byte;
    area:arearec;
    versioncode2:byte;

type configsettype=array [1..5272] of char;  {orig:2048}
var configset:configsettype absolute versioncode;
type protoconfigsettype=array [1..(1)] of char;
var protoconfigset:protoconfigsettype absolute versioncode2;
var validprotos:set of char;

procedure readconfig;
procedure readprotoconfig;

implementation

procedure readconfig;
var q:file of configsettype;
    i:integer;
begin
  assign (q,'Emulex.bbs');
  reset (q);
  i:=ioresult;
  if i=0
    then read (q,configset)
    else
      begin
        writeln ('Emulex Config!  Loading Config Program..');
        halt (67)
      end;
  system.close (q);

end;

procedure readprotoconfig;
var q:file of protoconfigsettype;
    i:integer;
begin
end;

end.


