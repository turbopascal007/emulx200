uses dos,crt,gentypes,modem,subs1,subs2,gensubs;
var cnt:integer;
shit:string[95];
f:text;
Turnon:boolean;
sam:anystr;
parm:anystr;
baud:anystr;
crlf:anystr;
procedure getline;
var got:char;
begin
crlf:=^M^J;
sam:=' ';
repeat
if numchars>0 then begin
got:=getchar; got:=chr((ord (got)) and $7f);
write(got); sam:=sam+upcase(got);end;
until keypressed or (got=#13) or (got=#10);
end;

var ot:char;

procedure respond;
begin

shit:='';
if (pos ('[MR.',sam)>0) then else
if turnon then begin
if (pos('HOW',sam)>0) and (pos('ARE',sam)>0) and (pos('YOU',sam)>0) then shit:='Fine!how bout you?'+crlf;
if (pos ('FINE',sam)>0) then shit:='Great!!!'+crlf;
if  (pos ('BURP',sam)>0) then shit:='You Pig!'+crlf;
if  (pos ('BRB',sam)>0) then shit:='Hurry Back!'+crlf;
if  (pos ('HEY',sam)>0) then shit:='Hey, do I know you ?'+crlf;
if  (pos ('HOWDY',sam)>0) then shit:='Howdy Dudez!'+crlf;
if  (pos ('QUIET',sam)>0) then shit:='No, I won''t be quite!'+crlf;
if  (pos ('HI',sam)>0) then shit:='Hi!!'+crlf;
if  (pos ('SAM',sam)>0) then shit:='Krad!!'+crlf;
if  (pos ('KRAD',sam)>0) then shit:='Krad!!'+crlf;
if  (pos ('BYE',sam)>0) then shit:='Byez!!!'+crlf;
if  (pos ('HM',sam)>0) then shit:='Hmm...'+crlf;
if  (pos ('HELLO',sam)>0) then shit:='Hello there!'+crlf;
if  (pos ('SAM BROWN',sam)>0) then shit:='Sam Brown is GOD!'+crlf;
if  (pos ('SEX',sam)>0) then shit:='Well theres always Oral Sex!'+crlf;
if  (pos ('HUG',sam)>0) then shit:='*Hugs*'+crlf;
if  (pos ('LOOLOO',sam)>0) then shit:='Rigor Mortis lives!'+crlf;
if  (pos ('FUCK',sam)>0) then shit:='Stop fucking swearing!!'+crlf;
if  (pos ('HAHA',sam)>0) then shit:='Haha!'+crlf;
if  (pos ('HEHE',sam)>0) then shit:='Hehe!'+crlf;
if  (pos ('HEH',sam)>0) then shit:='Heh Heh!'+crlf;
if  (pos ('NO.',sam)>0) then shit:='Why No?'+crlf;

if length(shit)>0 then begin

for cnt:=1 to length(shit) do begin

write (shit[cnt]);
sendchar (shit[cnt]);end;delay (900);while numchars>0 do ot:=getchar;
sam:=' ';

end;end; end;

begin
clrscr;
turnon:=false;
writeln ('         ---->  HI.PAS <----');
Writeln;
Writeln ('   [1] 1200 Com1:   [2] 2400 Com1: ');
Writeln ('   [3] 1200 Com2:   [4] 2400 Com2: ');
Write   ('   Please Select Baud rate: ');
readln  (baud);
initializeAsync;
if (pos ('1',baud)>0) then setparam (1,1200,false);
if (pos ('3',baud)>0) then setparam (2,1200,false);
if (pos ('2',baud)>0) then setparam (1,2400,false);
if (pos ('4',baud)>0) then setparam (2,2400,false);
      {  comparams (1,1200,7,'E',1);}

Writeln;
Writeln ('You are now OnLine. Press [Ctrl-Break] To Exit.');
turnon:=false;
repeat
 getline;
if turnon then respond;
while keypressed do begin
{repeat}
ot:=readkey;
if ot='*' then turnon:=true;
if ot='(' then turnon:=false;
sendchar (ot);
delay (60);
{until ot=#27;}  { <-- might work? }
end;

until 0=1;
end.