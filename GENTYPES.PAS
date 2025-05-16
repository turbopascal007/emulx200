 {$R-,S-,I-,D-,F+,V-,B-,N-,L+ }

  unit gentypes;

  Interface

  uses dos;

  var isnew:boolean;

  Const versionnum='Emulex/2 1.67 - Aug. 10 1989';
    thisversioncode=1;
    maxusers=30000;
    maxmessagesize=100;
    maxlastcallers=20;
    maxtopics=10;
    maxcats=10;
    sectorsize=512;
    numsectors=10000;
    maxcatalogsize=50;
    maxgroupsize=50;
    maxsyslogdat=295;
    maxsyslogsize=1000;
    e_door=3;
    e_controlbreak=9;
    e_badconfig=100;
    e_fatalfileerror=90;
    e_files30=50;
    e_nomodemdrv=2;
    breakoutchar=0;{Control-Break}
    chatchar=59;{F1}
    sysopcomchar=60;{F2}
    fschatchar=61;
    sysnextchar=65;{F7}
    timelockchar=66;{F8}
    inlockchar=67;{F9}
    outlockchar=68;{F10}
    printerechochar=114;{Ctrl-PrtSc}
    availtogglechar=30;{Alt-A}
    bottomchar=48;{Alt-B}
    texttrapchar=18;{Alt-E}
    sysophelpchar=35;{Alt-H}
    notimechar=37;{Alt-K}
    lesstimechar=38;{Alt-L}
    moretimechar=50;{Alt-M}
    tempsysopchar=20;{Alt-T}
    viewstatchar=47;{Alt-S}

  Type anystr=String[255];
    lstr=String[80];
    mstr=String[30];
    sstr=String[15];
    accesstype=(bylevel,keepout,letin,invalid);
    availtype=(available,bytime,notavailable);
    configtype=(lowercase,eightycols,linefeeds,postprompts,moreprompts,
    asciigraphics,ansigraphics,udsysop,bulletinsysop,votingsysop,
    emailsysop,doorssysop,mainsysop,databasesysop,wanted,
    showtime,vt52,fseditor);
    groupclass=(publicgroup,privategroup,personalgroup);
    voteset=Array[1..maxtopics] Of Byte;
    boardorder=Array[0..255] Of Byte;
    MNPBLOCK=array[1..64] of char;
  Type userrec=Record
                 handle:mstr;
                 password:sstr;
                 phonenum:String[10];
                 laston:longint;
                 numon,timetoday,nup,ndn,nbu,uploads,downloads:Integer;
                 totaltime:Real;
                 voted:voteset;
                 udlevel,udpoints,level,emailannounce,beepedpwd,infoform:Integer;
                 regularcolor,promptcolor,statcolor,inputcolor,displaylen:Byte;
                 config:Set Of configtype;
                 newscanconfig,access1,access2:Set Of Byte;
                 Lastposts,Lastfiles:Integer;
                 MoreInfoForms:Array[1..10] Of Integer;
                 Messages_Waiting:Integer;
                 Emulation:Byte;
                 Guploads,Gdownloads,LastGfileArea,Gflevel:Integer;
                 GPoints,lastDataBase,LastGfiles:Integer;
                 WhereBase:sstr;
                 WhereFile,WhereGfile:Integer;
                 KDownloaded,KUploaded:longint;
                 REVISION:integer;
                 Macro:lstr;
                 Messages_read:integer;
                 Timebank:integer;
                 Notes:mstr;
                 LastCalls:integer;
                 lastbaud,hackattempts:integer;
                 TodayCalls:byte;
                 Highgraph:byte;
                 any:Array[0..62] Of Byte;
                 lastread:Array[0..255] Of word
               End;


    userspecsrec=Record
                   name:mstr;
                   minlevel,maxlevel,minlaston,maxlaston:Integer;
                   minpcr,maxpcr:Real
                 End;

    boardrec=Record
                boardname,sponsor:mstr;
                level,autodel:Integer;
                EmuMail_type:string[24];
                Ranon,Received:Byte;
                ToNum,FromNum:Integer;
                Area_type:sstr;
                File_list:lstr;
                shortname:sstr
             End;

    bulrec=Record

             title,leftby:mstr;
             sentto:mstr;
             Reply:Integer;
             Ranon,received:Byte;
             ToNum,Fromnum:Integer;


             noused:String[21];
             Rawmode:byte;
             when:longint;
             anon:Boolean;
             line,plevel:Integer;
             id:word;
           End;
           type     Rumorrec=record
       Data:string[78];
       Sentby:mstr;
       dateby:sstr;
       title:sstr;
       extra:lstr;
     end;

    NetRec=Record
             Boardname:mstr;
             Location:mstr;
             Number:mstr;
             CityCode:string[28];
             CallBaud:integer;
           End;
     bbsrec=record
       name:string[48];
       number:string[12];
       maxbaud:string[4];
       ware:string[4];
       extdesc:string[76];
       leftby:mstr;
     end;

    filerec=Record
              descrip,fname:lstr;
              sentby:mstr;
              when:longint;
              downloaded:Integer;
              unused:mstr;
            End;

    mailrec=Record
              title,sentby:mstr;
              when:longint;
              anon,Read:Boolean;
              sentto,line,fileindex:Integer
            End;
    LastMsg=Record
              tonext:Integer;
              From:mstr;
            End;

    Newsrec=Record
              Location:Integer;
              Level:Integer;
              From:mstr;
              When:longint;
              Title:String[28];
              MaxLevel:Integer;
            End;

    abrec=Record
            title,fname:lstr;
            level:Integer;
            when:longint
          End;

    catalogrec=Record
                 nummail,additional:Integer;
                 mail:Array[1..maxcatalogsize] Of mailrec
               End;

    grouprec=Record
               name:mstr;
               class:groupclass;
               creator,nummembers:Integer;
               members:Array[1..maxgroupsize] Of Integer
             End;

    message=Record
              Text:Array[1..maxmessagesize] Of lstr;
              title:mstr;
              sentto:mstr;
              anon:Boolean;
              numlines:Integer
            End;

    topicrec=Record
               topicname:lstr;
               numvoted,addlevel:Integer;
               VoteLevel:Integer;
               File_List:lstr;
               Area_Type:Char;
               mandatory:Boolean
             End;

    choicerec=Record
                choice:lstr;
                numvoted:Integer
              End;

    lastrec=Record
              name:mstr;
              callnum:longint;
              when:longint
            End;

    buffer=Array[1..sectorsize] Of Char;

    baserec=Record
              numcats,numents,level:Integer;
              Area_Type:Char;
              File_List:lstr;
              basename:mstr;
              catnames:anystr
            End;

    entryrec=Record
               data:anystr;
               when:longint;
               addedby:Integer
             End;

    parsedentry=Array[1..maxcats] Of anystr;

    udrec=Record
            sentby:mstr;
            when,whenrated:longint;
            filename:sstr;
            path:String[50];
            points:Integer;
            FileSize:longint;
            descrip:lstr;
            downloaded:Integer;
            unused:mstr;
            newfile,specialfile:Boolean
          End;
    batchrec=Record
               filename:sstr;
               path:String[50];
               points:Integer;
               mins:Integer;
               wholefilename:lstr;
             End;
    Batchlist=Array[1..25] Of batchrec;

    arearec=Record
              name,xmodemdir:lstr;
              sponsor:mstr;
              Password:sstr;
              UploadHere,downloadhere:char;
              unused:string[62];
              File_List:lstr;
              Area_Type:Char;
              level:Integer
            End;

    windowrec=Record
                x1,y1,x2,y2,
                cx,cy,color:Byte
              End;

    fib=textrec;

    doorrec=Record
              name:mstr;
              File_List:lstr;
              Area_Type:Char;
              level,numused,info:Integer;
              batchname:lstr;
              getparams:Boolean;
            End;

    minuterec=Record
                started:Boolean;
                startedat:Integer;
                total:Real
              End;

    logrec=Record
             menu,subcommand:Integer;
             param:String[41];
             when:longint
           End;

    syslogdatrec=Record
                   menu,subcommand:Integer;
                   Text:mstr
                 End;

    baudratetype=(b110,b300,b450,b600,b1200,b2400,b4800,b9600,b19200);
    baudset=Set Of baudratetype;

  Const baudarray:Array[b110..b19200] Of Integer=
    (110,300,450,600,1200,2400,4800,9600,19200);
    versioncodes:Array[1..thisversioncode] Of String[4]=
    ('1.00');

  Const firstbaud=b110;
    lastbaud=b19200;

    Implementation

  Begin
  End.
