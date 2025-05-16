unit ZRoutine;

INTERFACE
uses crt,dos;

{$IFNDEF NOZINPUT}
const
	ZIEsc = #27;
	ZIF1  = #0 + #59;
	ZIF2  = #0 + #60;
	ZIF3  = #0 + #61;
	ZIF4  = #0 + #62;
	ZIF5  = #0 + #63;
	ZIF6  = #0 + #64;
	ZIF7  = #0 + #65;
	ZIF8  = #0 + #66;
	ZIF9  = #0 + #67;
	ZIF10 = #0 + #68;

{$ENDIF}



var
           ZCmd          :  String;   (* Command Buffer *)
	   ZSilent : Boolean;   (* Prevents beeping *)
	   ZDelay  : integer;   (* for growing windows *)
	   ZIOErr  : Boolean;   (* set by ZIOREsult *)

{$IFNDEF NOZINPUT}
	   ZINumOfFields : integer; (* number of fields being passed *)

	   ZILen,
	   ZICol,
	   ZIRow	: array[1..25] of integer;
	   ZIData	: array[1..25] of string[80];
	   ZIInValid    : array[1..25] of string;
	   ZIKeyPressed : string[2];

{$ENDIF}

Function  ZCmdPos (The_Pos  : Word  ) : string;
Function  ZCmdStr (A_String : String) : string;
Function  ZUCase  (A_String : String) : string;
Function  ZRight(A_String : string; A_Word : Word) : string;
Procedure ZBeep(Number_Of_Times : integer);
Procedure ZPress_any_Key_to_Continue ;
Function  ZLpadint(TheVal : integer; NumOfBytes:Integer) : string;

(* - new in version 1.1 *)
Function  ZCmdKeyWord (TheKeyWord : string) : boolean;
Function  ZCmdInt     (A_String: String) : Integer;
Function  ZString (A_String : String; NumOfTimes:Integer) : string;
Procedure ZColor (x,y:integer);
Function  ZPad(A_String, PadString : string; Totlen: integer) : string;
Procedure  ZWrite(x,y: integer;A_String:string);
Procedure ZMakeWindow (Left_Column,   Top_Row,
                            Right_Column,  Bottom_Row: integer;
                            F_Color,        B_Color       : byte;
                            WindowType : Integer                            );

procedure ZCsrSize(x,y:integer);
procedure ZCsrNone;
procedure ZCsrBlock;
procedure ZCsrNormal;
procedure ZCsrHalf;
procedure ZShell(TheCommand : string);
procedure ZLTrimp(var A_String : string);
Function  ZLtrim(A_String : string) : string;
procedure ZmakeWindowg (lcol,trow,rcol,brow,fcolor,bcolor,border:integer);

Procedure ZIOResult (var An_integer : integer; var The_Message : string);
Function  ZIOCheck  : boolean;
Procedure ZIOVerify;

{$IFNDEF NOZINPUT}
Procedure ZInput;
{$ENDIF}

Function ZStr (A_number : integer) : string;

IMPLEMENTATION

Function Zstr (A_number : integer) : string;

var
	tempstr : string;

begin
	Str(A_Number, Tempstr);
	ZStr := Tempstr;
end;



{$IFNDEF NOZINPUT}
{$I ZINPUT.PAS}
{$ENDIF}

Procedure ZIOVerify;
var
	xx : integer;
	yy : string;

begin
	ZIOResult (xx,yy);
	if ZIOErr then	begin
			Writeln;
			Writeln('An unexpected I/O error has occurred');
			Writeln(yy);
			Writeln('IO code of ', xx, ' was returned');
			zbeep (3);
			halt(1);
			end;
end;

Function ZIOCheck : boolean;
var
	xx : integer;
	yy : string;
begin
	ZIOResult (xx, yy);
	ZIOCheck := ZIOErr;
end;

Procedure ZIOResult (var An_Integer : integer; var The_Message : String);
var
	ZIOCode : integer;

begin
	ZIOCode := IoResult;
	ZIOErr := (ZIOCode <> 0 );
	An_Integer := 0;
	The_Message := '';

	if ZIOErr then begin

		An_integer := ZIOCode;

		case ZIOCode of

		$02 :	The_Message := 'File not found';
		$03 :	The_Message := 'Path not found';
		$04 :	The_message := 'File not Open';
		$10 :	The_message := 'Error in numeric format';
		$20 :	The_message := 'Operation not allowed in logical device';
		$21 :	The_message := 'Not allowed in direct mode';
		$22 :   The_message := 'Assign to standard files not allowed';
		$90 :	The_message := 'Record length mismatch';
		$91 :	The_message := 'Seek beyond end-of-file';
		$99 :	The_message := 'Unexpected end of file';
		$f0 :	The_message := 'Disk Write Error!';
		$f1 :	The_message := 'Directory is full';
		$f2 :	The_message := 'File Size overflow';
		$f3 :	The_message := 'Too many open files';
		$ff :	The_message := 'File disappeared';
		else
			The_message := 'Unknowm I/O Error!';
		end
	end;
end;

procedure ZmakeWindowg (lcol,trow,rcol,brow,fcolor,bcolor,border:integer);

var tempx, tempy, tempz, tempa, tempb: integer;
	slcol, srcol, strow, sbrow : integer;

begin

		tempx := rcol - lcol;
		tempy := brow - trow;


		slcol := tempx div 2 + lcol - 1;
		srcol := rcol - tempx div 2 + 1;

		strow := tempy div 2 + trow - 1;
		sbrow := brow - tempy div 2 + 1;
		tempa := tempx div tempy;

		if not DirectVideo then
			if (tempx > 12) or (tempy > 4) then
				tempa := tempa * 4;

		repeat

			slcol := slcol - tempa;
			strow := strow - 1;
			srcol := srcol + tempa;
			sbrow := sbrow + 1;

			if slcol < lcol then slcol := lcol;
			if srcol > rcol then srcol := rcol;
			if strow < trow then strow := trow;
			if sbrow > brow then sbrow := brow;

			zmakewindow(slcol, strow, srcol, sbrow, fcolor, bcolor, border);
			delay(ZDelay);



		until (slcol = lcol) and (strow = trow);
		ZMakeWindow (lcol, trow, rcol, brow, fcolor, bcolor, border);
end;





Function  ZLTrim(A_String : string) : string;
begin

	ZLTrimp(A_String);
	ZLTrim := A_String;

end;



Procedure ZLTrimp(var A_String : string);

begin
	if length(A_String) < 1 then exit;

	while A_String[1] = ' ' do
		delete(A_String,1,1);
end;



procedure ZShell(TheCommand : string);
VAR
  Regs : Registers;

    Begin;
      SwapVectors;
	 Exec(FSearch('COMMAND.COM',GetEnv('PATH')),TheCommand);
      SwapVectors;
    End;




Procedure ZWrite (x,y:integer; A_String:string);
begin
        gotoxy(x,y);
        Write(A_String);
end;


Function  ZPad(A_String, PadString : string; Totlen: integer) : string;
var
        Zint: integer;

begin
        if length(A_String) >= Totlen then
                begin
                ZPad := copy(A_String, 1, TotLen);
                exit;
                end;

        ZPad := A_String + ZString(PadString, Totlen);
end;



Procedure ZColor (x,y:integer);
begin
        textcolor (x);
        Textbackground(y);
end;

Function  ZString (A_String : String; NumOfTimes:Integer) : string;

var tempstr : string;

begin
        ZString := ''; TempStr := '';
        if NumOfTimes > 255 then NumOfTimes := 255;
        While NumOfTimes > 0 do
                begin
                tempstr := tempstr + A_String;
                Dec(NumOfTimes);
                end;
        ZString := TempStr;
end;




Function ZCmdInt      (A_String: String) : integer;

var
        Zint, Return_code: integer;

begin

        val  ( ZCmdStr(A_String), Zint, Return_code);
        if Return_code = 0 then
                ZCmdInt := Zint
        else
                ZCmdInt := 0;


end;


Function  ZCmdKeyWord (TheKeyWord : string) : boolean;
var
        Zint    : integer ;
begin;
        for Zint := 1 to ParamCount do
                if ZUcase(ParamStr(Zint)) = ZUCase(TheKeyWord) then
                        begin
                        ZCmdKeyword := true;
                        exit;
                        end;
        ZCmdKeyWord := False;
end;


Function ZCmdStr (A_String : String) : string;
var
        Zint : integer;
        Zok  : Boolean;
        Ztemp: string;

begin;
        ZCmdStr := '';
        if (Length(ZCmd) = 0) or  (Length (A_String) = 0) then exit;

        Zint := Pos(ZUCase(A_String), ZUCase(ZCmd)) ;
        If Zint = 0 then exit;
        if (Zint + length(A_String)) > Length(ZCmd) then exit;

        Zint := Zint + length(A_String); Zok := True; ZTemp := '';
        while Zok do
                begin
                        case ZCmd[Zint] of
                                ' ', '/'        :       Zok := False;
                        else
                                Ztemp := Ztemp + ZCmd[Zint];
                        end;

                Zint := Zint + 1;
                if Zint > Length(ZCmd) then Zok := False;

                end;

        ZCmdStr := Ztemp;

end;


Function ZUCase  (A_String : String) : string;
var
        ZIndex: Integer;

begin

        for ZIndex := 1 to length(A_String) do
                A_String[ZIndex] := upcase(A_String[ZIndex]);
                ZUcase := A_String;
end; { ZUcase }

Function ZCmdPos (The_Pos: Word) : string;

var ZInt, ZCount : integer;
        ZTemp : string;

begin;
        ZCount := 0;
        ZCmdPos := '';
        For Zint := 1 to ParamCount do
                begin

                ZTemp := ParamStr(Zint);
                if ZTemp[1] = '/' then else
                        ZCount := ZCount + 1;

                if ZCount = The_Pos then
                        begin
                        ZCmdPos := ParamStr(Zint);
                        exit
                        end;
                end;
end;


function ZRight(A_String : string; A_Word : Word) : string;

begin

        if A_Word >= Length(A_String) then
                begin
                ZRight := A_String;
                exit;
                end;

        ZRight := copy(A_String, Length(A_String) - A_Word + 1, A_Word);
end;


procedure ZBeep (Number_Of_Times : integer );

begin
           If ZSilent then exit;
        if Number_Of_Times < 1 then Number_Of_Times := 1;

        repeat
                sound (900);
                delay (250);
                nosound;
                Number_Of_Times := Number_Of_Times - 1;

        until Number_Of_Times < 1;
end;


procedure ZPress_any_key_to_continue;

var
	throw_away : string[1];
	x,y 	   : integer;
begin

	while keypressed do throw_away := ReadKey;
	x := Wherex;
	y := wherey;

        Write('Press any key to continue...');
           ZBeep (2);

        throw_away := '';

        while throw_away = '' do
                Throw_Away := ReadKey;

	gotoXY (x,y);
	Write(ZString(' ',28));

	if throw_away = #27 then
		begin
		ZCsrNormal;
		halt(0);
		end;
end;


function ZLpadint(TheVal : integer; NumOfBytes:Integer) : string;

var
        TempStr : string;

begin

        STR(TheVal : NumOfBytes, TempStr);
        while pos(' ', TempStr) > 0 do
                TempStr[Pos(' ', TempStr)] := '0';

        ZLPadint := TempStr;
end;



procedure ZCsrNone;
begin
        ZCsrSize(32,0);
end;

procedure ZCsrBlock;
begin
        ZCsrSize(0,7);
end;

procedure ZCsrNormal;
begin
        ZCsrSize(6,7);
end;

procedure ZCsrHalf;
begin
        ZCsrSize(4,7);
end;



Procedure ZMakeWindow (Left_Column,   Top_Row,
                            Right_Column,  Bottom_Row: integer;
                            F_Color,        B_Color       : byte;
                            WindowType : Integer                            );


var
        Themid: string[77];
        ZWLeftUpper, ZWAcross, ZWRightUpper, ZWLeft, ZWRightBottom, ZWLeftBottom : char;


begin
        Case WindowType of
                2:      begin
                        ZWLeftUpper     := #213;
                        ZwAcross       := #205;
                        ZwRightUpper    := #184;
                        ZwLeft          := #179;
                        Zwrightbottom   := #190;
                        ZWleftBottom    := #212;
                        end;

                else begin;
                        ZWLeftUpper     := #201;
                        ZwAcross       := #205;
                        ZwRightUpper    := #187;
                        ZwLeft          := #186;
                        Zwrightbottom   := #188;
                        ZWleftBottom    := #200;
                        end;
                end;




        gotoxy (Left_Column, Top_Row);
        Textcolor(F_Color); TextBackground(B_Color);

        Write(' ',ZWLeftUpper, Zstring(ZWAcross, Right_Column - Left_Column - 3), ZWRightUpper,' ');
        Inc(Top_Row);

        TheMid := ZString(' ', Right_Column - Left_Column - 3);

        While Top_Row < Bottom_Row do
                begin
                gotoxy(Left_Column, Top_Row);
                Write(' ',ZWLeft, TheMid, ZWLeft,' ');
                Top_Row := Top_Row + 1;
                end;
                gotoxy(Left_Column, Top_Row);

        Write(' ',ZWLeftBottom, Zstring(ZWAcross, Right_Column - Left_Column - 3), ZWRightBottom,' ');




end;


procedure ZCsrSize(x,y:integer);
var r: registers;
begin;
        r.ah :=1;
        r.ch :=x;
        r.cl :=y;
        intr ($10,r);
end;


{-------------------------------------------------------------------
  this code is executed every program using this unit...
  it builds the ZCMD variable for all other functions...}


var Zint : integer;

begin
		ZCmd := '';                               { init the command buffer }
		ZSilent := False;                                    { Sound defaults on }
		ZDelay :=50;

        for Zint := 1 to ParamCount do
                ZCmd := ZCmd + ParamStr(Zint) + ' ';

	DirectVideo := not ZCmdKeyWord('BIOS');

end.
