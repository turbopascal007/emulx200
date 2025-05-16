{$R-,S-,I-,D-,F+,V-,B-,N-,L+,O+ }

unit trivia;

interface

uses crt,dos,
     gentypes,configrt,modem,statret,gensubs,subs1,windows,subs2,textret,
     mailret,userret,flags,mainr1,ansiedit,lineedit,chatstuf,
     mainr2,overret1;

procedure playtrivia;

implementation

procedure playtrivia;

type namestr=string[28];
type string255=string[255];

const isopened=true;
const isclosed=false;
type filetype=record
               thefile:file;
               open:boolean
              end;
var well:anystr;
    atrivia_answers:longint;

function fileposit (var filevar:filetype):longint;
begin
 fileposit:=filepos(filevar.thefile)
end;

function bigfilesize (var filevar:filetype):longint;
begin
 bigfilesize:=filesize(filevar.thefile)
end;
function eofile (var filevar:filetype):boolean;
begin
 eofile:=eof(filevar.thefile)
end;

procedure openfile(var filevar:filetype;filename:string255;
                   var error:boolean;recsize:longint);
begin
  assign(filevar.thefile,filename);
  if exist(filename) then
    reset(filevar.thefile,recsize)
  else
    rewrite(filevar.thefile,recsize);
  error:=(ioresult<>0);
  if not error then filevar.open:=isopened;
end;

procedure writerec(var filevar:filetype;var error:boolean;var readrec);
var therecord:array [0..1000] of integer absolute readrec;

begin
 blockwrite(filevar.thefile,therecord,1);
 error:=(ioresult<>0)
end;

procedure readrec(var filevar:filetype;var error:boolean;var readrec);
var therecord:array [0..1000] of integer absolute readrec;

begin
  blockread(filevar.thefile,therecord,1);
  error:=(ioresult<>0)
end;

procedure seekwrite(var filevar:filetype;number:longint;
                  var error:boolean;var readrec);

var therecord:array [0..1000] of integer absolute readrec;

begin
  seek(filevar.thefile,number);
  error:=(ioresult<>0);
  if not error then
  begin
    blockwrite(filevar.thefile,therecord,1);
    error:=(ioresult<>0)
  end
end;

procedure seekrec(var filevar:filetype;number:longint;
                  var error:boolean;var readrec);

var therecord:array [0..1000] of integer absolute readrec;

begin
  seek(filevar.thefile,number);
  error:=(ioresult<>0);
  if not error then
  begin
    blockread(filevar.thefile,therecord,1);
    error:=(ioresult<>0)
  end
end;

procedure closefile(var filevar:filetype;var error:boolean);
begin
  close(filevar.thefile);
  error:=ioresult<>0;
  filevar.open:=isclosed
end;

type triviacategory = record
                       winner     : namestr;
                       catname    : string[20];
                       date,
                       time       : sstr;
                       numanswers : integer;
                       correct,
                       check      : boolean;
                       question   : string255;
                       answer     : array[1..3] of string[40];
                      end;
awardrecord = record
               name  : string[28];
               award : integer;
              end;

var trec    : triviacategory;
    afile,
    tfile   : filetype;
    arec    : awardrecord;
    error   : boolean;
    maxcat  : integer;
    select  : char;
    answernum,
    catnum  : integer;
    i       : integer;
    temp,
    scrapstr: string255;

    procedure createcategory;
    var ii:longint;
    begin
      writestr(^M'Create Category #'+strr(maxcat+1)+' [y/n]? *');
      if not yes then exit;
      writestr(^M'Category Name: *');
      buflen:=20;
      trec.catname:=input;
      trec.question:='';
      for ii := 1 to 3 do trec.answer[ii]:='-';
      trec.numanswers:=0;
      trec.check:=false;
      seekwrite(tfile,bigfilesize(tfile),error,trec);
      seekrec(tfile,0,error,trec);
      trec.numanswers:=trec.numanswers+1;
      maxcat:=maxcat+1;
      seekwrite(tfile,0,error,trec);
    end;

    procedure categorystatus;
    var x   : byte;
        ans : boolean;
    begin
      i:=1;
      ansicolor (urec.regularcolor);
      writeln('[Category]         [Ans.] [Date Entered]          [Online Check]');
      while (i<=maxcat) {and not (cancelled) }
      do
        begin
          writeln;
          ansicolor(urec.statcolor);
          seekrec(tfile,i,error,trec);
          tab(strr(i)+': '+trec.catname,20);
          tab(strr(trec.numanswers),7);
          tab(trec.date+' at '+trec.time,23);
          if 0=0 then begin
            if trec.check then
            begin
              writeln('Online Check');
              ansicolor(urec.regularcolor);
              begin
                ans:=false;
                writeln(' Current Question/answer and winner[if there is one]:');
                writeln(' Q: '+trec.question);
                if  trec.winner <> 'No one' then begin
                 write(' A: ');
                 for x:=1 to 3 do if trec.answer[x]<>'-' then
                 begin
                  if not ans then write(trec.answer[x])
                  else write(', '+trec.answer[x]);
                  ans:=true;
                 end;
                 writeln('   Winner: '+trec.winner);
                end;
               end;
              ansicolor(urec.statcolor);
            end else writeln('No');
          end else Write(' ');
          i:=i+1;
        end;
      ansireset;
    end;


    procedure answerquestion;
    var ansfile : text;
        correct : boolean;
        cmd     : char;
    begin
      repeat
        writestr ('Category [1-'+strr(maxcat)+',Q,?]:');
        cmd:=input[1];
        if cmd='?' then
        begin
          writeln('?');
          categorystatus;
        end;
        if upcase(cmd) in [#13,'Q','A'] then
        begin
          writeln(cmd);
          exit;
        end;
      until ord(cmd)-48 in [1..maxcat];
      catnum:=ord(cmd)-48;
      if (catnum>0) and (catnum<=maxcat) then
        begin
          writeln(strr(catnum));

          seekrec(tfile,catnum,error,trec);
          if trec.correct then
          begin
            writeln(trec.winner+' answered this question correctly already!');
            exit;
          end;

          writeln('This will be this questions attempt #'+strr(trec.numanswers+1));
          write('This question will be ');

          if trec.check then writeln('Checked by the BBS!')
          else writeln('Checked by the Trivia Sysop!');
          writeln;
          writeln ('The Trivia Question is :');
          writeln(trec.question);
          buflen:=40;
          writestr ('Enter your Guess/Answer: &');
          temp:=input;
          if length(temp)=0 then exit;
          if trec.check then begin
           i:=0;
           correct:=false;
           repeat
             i:=i+1;
             if match(temp,trec.answer[i]) then correct:=true;
           until (i=3) or (trec.answer[i]='-') or (correct);
           trec.numanswers:=trec.numanswers+1;
           seekwrite(tfile,catnum,error,trec);
             if correct then begin
             trec.correct:=true;
             trec.winner:=urec.handle;
             seekwrite(tfile,catnum,error,trec);
             writeln('Congratulations, you answered it correctly!');
             writeln('This question took '+strr(trec.numanswers-1)+' tries!');
             urec.udpoints:=urec.udpoints+3;
             writeln('You won'^S' 3 '^R' File pts. for a total of '^S+strr(urec.udpoints)+^R'.');
             end else writeln('Too bad, that''s wrong!')
          end else
          begin
          end;
          atrivia_answers:=atrivia_answers+1
        end
      else writeln ('Invalid category!');
    end;

    procedure recentwinners;
    begin
      i:=1;
     if (ansigraphics in urec.config) then write (#27+'[2J');
      writeln (^R'[Category]         [Winner]');
      ansicolor(urec.statcolor);
      while (i<=maxcat)  do
        begin
          seekrec(tfile,i,error,trec);
          tab(strr(i)+': '+trec.catname,20);
          i:=i+1;
          writeln(trec.winner);
        end;
      ansireset;
      if (asciigraphics in urec.config) then
      writeln ('컴컴컴컴컴컴컴컴컴컴컴컴컴�') else
      writeln ('---------------------------');
    end;

    procedure triviahelp;
    begin
      writeln(^B^M^S'Trivia Commands:'^M);
      writeln(^S'[A]:'^R'Answer a trivia question  '^S'[R]:'^R'See Recent winners');
      writeln(^S'[S]:'^R'Trivia Question status ');
      writeln(^S'[Q]:'^R'Quit                      '^S'[?]:'^R'Help');
      writeln;
    end;

    procedure triviasysop;
    var choice:anystr;
        erasefile:text;

      procedure enterquestion;
      begin
        repeat
          writestr('Question Category [1-'+strr(maxcat)+']:');
          if length(input)>0 then catnum:=valu(input);
        until (catnum>0) and (catnum<=maxcat);
        seekrec(tfile,catnum,error,trec);
        writeln('Category: '+trec.catname);
        Writestr('Enter New Category [CR/no change]: *');
        if length(input)>0 then trec.catname:=input;
        writeln('Question: '+trec.question);
        writestr('Change Question [y/n]? *');
        if yes then
        begin
          writeln('Enter the new Question:');
          writestr(':');
          if length(input)=0 then else
           trec.question:=input;
          writestr('Check Answer On-line [y/n]? *');
          if yes then
          begin
            trec.check:=true;
            writeln('Possible Answers [Max 3 / CR=No more Answers]');
            answernum:=0;
            repeat
              answernum:=answernum+1;
              writestr ('Answer #'+strr(answernum)+' :');
              trec.answer[answernum]:=input;
              if trec.answer[answernum]='' then trec.answer[answernum]:='-'
            until (trec.answer[answernum]='-') or (answernum=3);
          end else trec.check:=false;
          trec.numanswers:=0;
          trec.correct:=false;
          trec.date:=datestr(now);
            Well:=timestr(now);
          trec.time:=well;
          trec.winner:='No one';
          seekwrite(tfile,catnum,error,trec);
         end;
       end;


       procedure tm_editor_help;
       begin
         if exist('Tmeditor.Hlp') then
           printfile('Tmeditor.Hlp') else
           begin
           if (ansigraphics in urec.config) then write (#27+'[2J');
             writeln(^B^M^S'Trivia Editor:'^M);
             writeln(^S'[E]:'^R'Enter a question '^S'[L]:'^R'List answers');
             writeln(^S'[D]:'^R'Delete Question');
             writeln(^S'[Q]:'^R'Quit             '^S'[C]:'^R'Create a category ');
             writeln;
           end;
       end;

    begin
      repeat
        writestr (^B'Trivia Sysop Command [?/Help]: *');
        if hungupon then exit;
        choice:=upcase(input[1]);
        if (choice='E') then
         if maxcat>0 then enterquestion;
        if (choice='D') then
         begin
          if exist('Answers') then begin
           writestr('Delete ANSWERS File [y/n]? *');
           if yes then begin
            assign(erasefile,'Answers');
            erase(erasefile);
            writeln('ANSWERS file no longer exist.');
           end;
          end else writeln('ANSWERS file does not exist yet!');
         end;
         if (choice='L') then
          printfile('Answers');
         if (choice='C') then
          if maxcat<8 then createcategory else
           writeln('You can not create anymore, maximum is 8 categories.');
         if (choice='?') then
          tm_editor_help;
         if (upcase(choice[1])='Q') then exit;
      until (choice='Q');
    end;

begin
  openfile (tfile,'Records',error,sizeof(trec));
  if bigfilesize (tfile)=0 then begin
    trec.numanswers:=0;
    maxcat:=0;
    writerec(tfile,error,trec)
  end else begin
    seekrec (tfile,0,error,trec);
    maxcat:=trec.numanswers;
  end;
  writehdr ('The Trivia Section');
  writeln;
  writeln (^R'Number of Trivia questions: '^S+strr(maxcat)+^R);
  writeln;
  repeat
    writestr (^B'Trivia menu [?]: *');
    if hungupon then exit;
   if ((input[1]='A') or (input[1]='a')) then
    answerquestion;
   if ((input[1]='R') or (input[1]='r')) then
    recentwinners;
   if ((input[1]='S') or (input[1]='s')) then
    categorystatus;
   if (input[1]='%') then
    if (urec.level>=sysoplevel)
     then triviasysop;
   if (input[1]='?') then
    if exist(textfiledir+'Trivia.Hlp') then
     printfile(textfiledir+'Trivia.Hlp')
      else triviahelp;
  until ((input[1]='Q') or (input[1]='q'));
  closefile(tfile,error);
end;

begin
end.
