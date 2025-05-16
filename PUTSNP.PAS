program putsnp;
{$M 65500,2000,2000}
uses dos,crt;
type any=string[213];
     fag=string[201];
     FUCK=record
       Position:longint;
       Change:byte;
       end;


var f1:file of any;
    f2:file of byte;
    f3:file of FAG;

Struct:any;
cnt:integer;

procedure first;

var wher,cnt:longint;

A,b:any;
    fo:boolean;
    B1,b2:longint;

begin
reset(f1);
writeln ('    o Checking for serial # spot');
for cnt:=1 to 10 do begin
seek(f1,cnt-1);
read(f1,a);

b1:=pos(#0+#0+#0+#0+#0,a);
{if b1>0 then a[b1-1]:=#$6b;}
if b1>0 then a[b1+0]:=#69;
if b1>0 then a[b1+1]:=#$00;
if b1>0 then a[b1+2]:=#$00;
if b1>0 then a[b1+3]:=#$00;
{if b1>0 then a[b1+4]:=#$07;
if b1>0 then a[b1+5]:=#$CD;
if b1>0 then a[b1+6]:=#$FF;}
if b1>0 then seek(f1,cnt-1);
if b1>0 then write(f1,a);
if b1>0 then writeln ('     -I found the serial # spot!');
if b1>0 then close(f1);
if b1>0 then exit;
end;
close(f1);
end;




procedure Twofirst;
var wher,cnt:longint;
A,b:fag;
    fo:boolean;
    B1,b2:longint;
begin
reset(F3);
for cnt:=1 to filesize(f3) do begin
seek(f3,cnt-1);
read(f3,a);b1:=0;
b1:=pos('Omen Tec',a);
if b1>0 then  a[b1]:='b';
if b1>0 then  a[b1+1]:='y';
if b1>0 then  a[b1+2]:=' ';
if b1>0 then  a[b1+3]:='R';
if b1>0 then  a[b1+4]:='i';
if b1>0 then  a[b1+5]:='g';
if b1>0 then  a[b1+6]:='o';
if b1>0 then  a[b1+7]:='r';
if b1>0 then  a[b1+8]:=' ';
if b1>0 then  a[b1+9]:='M';
if b1>0 then a[b1+10]:='o';
if b1>0 then a[b1+11]:='r';
if b1>0 then a[b1+12]:='t';
if b1>0 then a[b1+13]:='i';
if b1>0 then a[b1+14]:='s';
if b1>0 then a[b1+15]:='!';
if b1>0 then a[b1+16]:='!';
if b1>0 then a[b1+17]:=' ';
if b1>0 then seek(f3,cnt-1);
if b1>0 then write(f3,a);
if b1>0 then writeln ('     -I found the title a1 # spot!');
if b1>0 then close(f3);
if b1>0 then exit;
end;
close(f3);
end;



procedure first2;
var wher,cnt:longint;
A,b:any;
    fo:boolean;
    B1,b2:longint;
begin
reset(F1);
for cnt:=1 to filesize(f1) do begin
seek(f1,cnt-1);
read(f1,a);
b1:=pos('DSZ (TurboC)',a);
if b1>0 then  a[b1]:='D';
if b1>0 then  a[b1+1]:='e';
if b1>0 then  a[b1+2]:='e';
if b1>0 then  a[b1+3]:='E';
if b1>0 then  a[b1+4]:='s';
if b1>0 then  a[b1+5]:='s';
if b1>0 then  a[b1+6]:='Z';
if b1>0 then  a[b1+7]:='e';
if b1>0 then  a[b1+8]:='e';
if b1>0 then  a[b1+9]:='e';
if b1>0 then a[b1+10]:='e';
if b1>0 then a[b1+11]:='h';
if b1>0 then seek(f1,cnt-1);
if b1>0 then write(f1,a);
if b1>0 then writeln ('     -I found the title 2 # spot!');
if b1>0 then close(f1);
if b1>0 then exit;
end;
close(f1);
end;

procedure forfirst;
var wher,cnt:longint;
A,b:any;
    fo:boolean;
    B1,b2:longint;
begin
exit;
reset(F1);
for cnt:=1 to filesize(f1) do begin
seek(f1,cnt-1);
read(f1,a);
b1:=pos(#$83+#$3e+#$84+#$d8+#$00,a);
if b1>0 then a[b1]:=#$c3;
if b1>0 then a[b1+1]:='y';
if b1>0 then a[b1+2]:=' ';
if b1>0 then a[b1+3]:='S';
if b1>0 then a[b1+4]:='a';
if b1>0 then a[b1+5]:='m';


if b1>0 then seek(f1,cnt-1);
if b1>0 then write(f1,a);
if b1>0 then writeln ('     -I found the reg  # spot!');
if b1>0 then close(f1);
if b1>0 then exit;
end;
end;


procedure Threefirst;
var wher,cnt:longint;
A,b:any;
    fo:boolean;
    B1,b2:longint;
begin
reset(F1);
for cnt:=1 to filesize(f1) do begin
seek(f1,cnt-1);
read(f1,a);
b1:=pos('"The High Reliability',a);
if b1>0 then    a[b1]:='"';
if b1>0 then  a[b1+1]:='T';
if b1>0 then  a[b1+2]:='h';
if b1>0 then  a[b1+3]:='e';
if b1>0 then  a[b1+4]:=' ';
if b1>0 then  a[b1+5]:='E';
if b1>0 then  a[b1+6]:='m';
if b1>0 then  a[b1+7]:='u';
if b1>0 then  a[b1+8]:='l';
if b1>0 then  a[b1+9]:='e';
if b1>0 then a[b1+10]:='x';
if b1>0 then a[b1+11]:='/';
if b1>0 then a[b1+12]:='2';
if b1>0 then a[b1+13]:=' ';
if b1>0 then a[b1+14]:='P';
if b1>0 then a[b1+15]:='i';
if b1>0 then a[b1+16]:='r';
if b1>0 then a[b1+17]:='a';
if b1>0 then a[b1+18]:='t';
if b1>0 then a[b1+19]:='e';
if b1>0 then a[b1+20]:='s';
if b1>0 then seek(f1,cnt-1);
if b1>0 then write(f1,a);
if b1>0 then writeln ('     -I found the title 1.5 # spot!');
if b1>0 then close(f1);
if b1>0 then exit;
end;
close(f1);
end;
{
procedure second;
var wher,cnt:longint;
A,b:any;
    fo:boolean;
    B1,b2:longint;
    c2,c3,c4,c5:byte;
begin
assign(f2,'dsz.com');
reset(f2);
b2:=0;
for cnt:=30100 to 34000 do begin
seek(f2,cnt-1);
read(f2,c2);
seek(f2,cnt);
read(f2,c3);
seek(f2,cnt+1);
read(f2,c4);
seek(f2,cnt+2);
read(f2,c5);
b1:=0; b2:=0;
if c2=$b8 then if c3=$1a then if c4=0 then if c5=$50 then b1:=1 else b1:=0;
if b1>0 then writeln ('     -I found the Serial Check spot at ',(cnt),',',c2,c3,c4,c5 );
if b1>0 then inc(b2);
if b2=1 then begin
seek(f2,cnt-1);
c5:=$90;
write(f2,c5);
seek(f2,cnt);
write(f2,c5);
seek(f2,cnt+1);
write(f2,c5);
seek(f2,cnt+2);
write(f2,c5);
seek(f2,cnt+3);
write(f2,c5);
seek(f2,cnt+4);
write(f2,c5);
seek(f2,cnt+5);
write(f2,c5);
seek(f2,cnt+6);
write(f2,c5);
end;
end;
end;}

procedure fuckyou;
var wher,cnt:longint;
A,b:any;
    fo:boolean;
    B1,b2:longint;
    c2,c3,c4,c5,c6,c7,c8,c9:byte;
begin
assign(f2,'dsz.com');
reset(f2);
b2:=0;b1:=0;

for cnt:=580 to 1500 do begin
seek(f2,cnt);
read(f2,c3);
seek(f2,cnt+1);
read(f2,c4);
seek(f2,cnt+2);
read(f2,c5);
seek(f2,cnt+3);
read(f2,c6);
seek(f2,cnt+4);
read(f2,c7);
seek(f2,cnt+5);
read(f2,c8);
seek(f2,cnt+6);
read(f2,c9);
if b1=1 then b1:=2;
if (c3=$55) and (c4=$8b) and (c5=$ec) and (c6=$8b) and (c7=$46) and (c8=$04) and (c9=$8b)  then inc(b1);
if b1=1 then writeln ('     -I found the Serial Check spot at ',(cnt),',',c2,c3,c4,c5 );
if b1=1 then inc(b2);
if (b1=1) and ( b2=1) then begin
c5:=$c3;
seek(f2,cnt);
write(f2,c5);
end;
end;
end;

{cedure secondteen;
var wher,cnt:longint;
A,b:any;
    fo:boolean;
    B1,b2:longint;
    c2,c3,c4,c5:byte;
begin
b2:=0;
for cnt:=33000 to $8500 do begin
seek(f2,cnt-1);
read(f2,c2);
seek(f2,cnt);
read(f2,c3);
seek(f2,cnt+1);
read(f2,c4);
seek(f2,cnt+2);
read(f2,c5);
b1:=0; b2:=0;
if c2=$b8 then if c3=$15 then if c4=0 then if c5=$50 then b1:=1 else b1:=0;
if b1>0 then writeln ('     -I found the Serial Check spot #2 at ',(cnt),',',c2,c3,c4,c5 );
if b1>0 then inc(b2);
if b2=1 then begin
seek(f2,cnt-1);
c5:=$c3;
write(f2,c5);
seek(f2,cnt);
write(f2,c5);
seek(f2,cnt+1);
write(f2,c5);
seek(f2,cnt+2);
write(f2,c5);
seek(f2,cnt+3);
write(f2,c5);
seek(f2,cnt+4);
write(f2,c5);
seek(f2,cnt+5);
write(f2,c5);
seek(f2,cnt+6);
write(f2,c5);
end;
end;
end;

procedure Thirdteen;
var wher,cnt:longint;
A,b:any;
    fo:boolean;
    B1,b2:longint;
    c2,c3,c4,c5:byte;
begin
b2:=0;
for cnt:=34000 to 40000 do begin
seek(f2,cnt-1);
read(f2,c2);
seek(f2,cnt);
read(f2,c3);
seek(f2,cnt+1);
read(f2,c4);
seek(f2,cnt+2);
read(f2,c5);
b1:=0; b2:=0;
if c2=$b8 then if c3=$1a then if c4=0 then if c5=$50 then b1:=1 else b1:=0;
if b1>0 then writeln ('     -I found the Serial Check spot at ',(cnt),',',c2,c3,c4,c5 );
if b1>0 then inc(b2);
if b2=1 then begin
seek(f2,cnt-1);
c5:=$90;
write(f2,c5);
seek(f2,cnt);
write(f2,c5);
seek(f2,cnt+1);
write(f2,c5);
seek(f2,cnt+2);
write(f2,c5);
seek(f2,cnt+3);
write(f2,c5);
seek(f2,cnt+4);
write(f2,c5);
seek(f2,cnt+5);
write(f2,c5);
seek(f2,cnt+6);
write(f2,c5);
seek(f2,cnt+7);
Write(f2,c5);
end;
end;
end;

procedure Twosecond;
var wher,cnt:longint;
A,b:any;
    fo:boolean;
    B1,b2:longint;
    c2,c3,c4,c5:byte;
begin
assign(f2,'dsz.com');
reset(f2);
b2:=0;

for cnt:=32000 to 34901 do begin
seek(f2,cnt-1);
read(f2,c2);
seek(f2,cnt);
read(f2,c3);
seek(f2,cnt+1);
read(f2,c4);
seek(f2,cnt+2);
read(f2,c5);
b1:=0; b2:=0;
if c2=$83 then if c3=$3e then if c4=$84 then if c5=$d8 then b1:=1 else b1:=0;
if b1>0 then writeln ('     -I found the Serial Check spot 2 at ',(cnt),',',c2,c3,c4,c5 );
if b1>0 then inc(b2);
if b2=1 then begin
cnt:=cnt+5;
seek(f2,cnt-1);
c5:=$C3;
write(f2,c5);
seek(f2,cnt);
write(f2,c5);
seek(f2,cnt+1);
write(f2,c5);
seek(f2,cnt+2);
write(f2,c5);
seek(f2,cnt+3);
write(f2,c5);
seek(f2,cnt+4);
write(f2,c5);
seek(f2,cnt+5);
write(f2,c5);
seek(f2,cnt+6);
write(f2,c5);
end;
end;
end;
 }
begin
clrscr;
Writeln ('[__P_U_T_S_N_P_-_F_R_E_E_______Register_your_dsz.com!_____________]');
wRITELN;wRITELN;
Writeln ('[            Revised [05-25-89] for Dsz [04 24 and up!]           ]');
Writeln ('[  This program will allows you to review the "registered" DSZ    ]');
Writeln ('[  features and is meant to help you decide whether you want to   ]');
writeln ('[  spend the money for registration. In no way do you encourage   ]');
Writeln ('[  use of DSZs registered features without paying . You reserve   ]');
Writeln ('[  the Legal right to modify DSZ.com for sole personal purposes   ]') ;
writeln ('[  only. Once you see the benefits of the registered DSZ, we      ]');
writeln ('[  feel sure that you will send in your check to Chuck Foresborg  ]');
Writeln ('[                                       Mr. Matt Krad             ]');

assign (f1,'dsz.com');
{reset(f1);}

first;threefirst;
first2;
twofirst;

{writeln(^M'   o Modifying Serial # ');}
{first2;}

{writeln(^M'   o Pass [1] removing serial # verification routines');
second;
writeln(^M'   o pass [2] removing serial # verification routines');
secondteen;}
FUCKYOU;
Writeln(^M'   o Complete! [disregard runtime error->]');
close(f2);
end.