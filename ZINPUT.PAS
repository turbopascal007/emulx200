procedure ZInput;

label
	100;


var
	Checkchars,
	ValidChars : string;


	xx,
	x,
	ptr,
	Currentfield : integer;

	FillChar     : string[1];

	temp,
	tempr		: string;

begin

	ValidChars := '';
	for x := 33 to 126 do
		ValidChars := ValidChars + char(x);
	ptr := 1;
	CurrentField := 1;

{$IFDEF ZINFIELD}

	if Zinfield <> 0 then
		begin
		CurrentField := Zinfield;
		Zinfield := 0;
		end;
{$ENDIF}

	for x := 1 to ZINumOfFields do
		ZWrite ( ZICol[x], ZIRow [x], ZIData[x]);

100:

	ZCsrSize(5,7);
	gotoxy(ZICol[CurrentField] + ptr - 1, ZIRow[CurrentField]);


	ZIKeyPressed := ReadKey;
	if ZIKeyPressed = #0 then ZIKeyPressed := ZIKeyPressed + ReadKey;


	if (ZIKeyPressed = #9) or
	   (ZIKeyPressed = #0 + #80) then
	   begin
	   CurrentField := CurrentField + 1;
	   ptr := 1;
	   if CurrentField > ZINumOfFields then CurrentField := 1;
	   goto 100;
	end;

	if (ZIKeyPressed = #0 + #15) or
	   (ZIKeyPressed = #0 + #72) then
	   begin

	   if CurrentField = 1 then
		CurrentField := ZINumOfFields
	   else
		CurrentField := CurrentField - 1;

	   ptr := 1;

	   goto 100;
	   end;


	if (ZIKeyPressed = #0 + #117) then
		begin
		ZIData[CurrentField] := '';
		ptr := 1;
		gotoxy (ZICol[CurrentField], ZIRow[CurrentField]);
		write (Zstring(' ', ZILen[CurrentField]));
		goto 100;
		end;


	if (ZIKeyPressed = #0 + #73) then
		begin
		CurrentField := 1;
		ptr := 1;
		goto 100;
		end;

	if (ZIKeyPressed = #0 + #81) then
		begin
		CurrentField := ZINumOfFields;
		ptr := 1;
		goto 100;
		end;

	if (ZIKeyPressed = #13) and
	   (CurrentField = ZINumOfFields) then
	   exit;


	if (ZIKeyPressed = #9) or
	   (ZIKeyPressed = #0 + #80) or
	   (ZIKeyPressed = #13) then
	   begin
	   CurrentField := CurrentField + 1;
	   ptr := 1;
	   if CurrentField > ZINumOfFields then CurrentField := 1;
	   goto 100;
	   end;

	if ZIKeyPressed = #0 + #71 then
	   begin
	   ptr := 1;
	   goto 100;
	   end;

	if ZIKeyPressed = #0 + #79 then
	   begin
	   ptr := length(ZIData[CurrentField]) + 1;
	   goto 100;
	   end;

	if ZIKeyPressed = #0 + #82 then
	   begin

	   if length(ZIData[CurrentField]) >= ZILen[CurrentField] then
		begin
		ZBeep(1);
		goto 100;
		end;

	   if ptr > length(ZIData[CurrentField]) then
		begin
		ZBeep(1);
		goto 100;
		end;


	   if ZIInvalid[CurrentField] = '' then
		Fillchar := ' '
	   else
		Fillchar := copy(ZIInvalid[CurrentField], 1, 1);


	   if ptr <> 1 then
		begin

		temp := copy(ZIData[Currentfield], 1, ptr - 1);
		tempr := ZRight(ZIData[CurrentField], length (ZIData[currentfield]) - ptr + 1);
		ZIData[CurrentField] := Temp + Fillchar + Tempr;
		end
	   else
		ZIData[currentfield] := Fillchar + ZIData[currentfield];


	   gotoxy (ZICol[currentfield], ZIRow[currentfield]);
	   Write (ZIData[currentfield]);
	   goto 100;


	   end;



	if ZIKeyPressed = #0 + #83 then
		begin

		if ptr > length(ZIData[currentfield]) then
			begin
			Zbeep(1);
			goto 100;
			end;

		delete(ZIData[currentfield],ptr,1);
		gotoxy (ZICol[currentfield], ZIRow[currentfield]);
		Write (ZIData[currentfield],' ');
		goto 100;
		end;


	if ZIKeyPressed = #8 then
		begin

		if ptr = 1 then
			begin
			Zbeep(1);
			goto 100;
			end;

		delete(ZIData[currentfield],ptr-1,1);
		gotoxy (ZICol[currentfield], ZIRow[currentfield]);
		Write (ZIData[currentfield],' ');
		ptr := ptr - 1;
		goto 100;
		end;

	if ZIKeyPressed = #0 + #75 then
		if ptr = 1 then
			begin
			Zbeep(1);
			goto 100;
			end
		else
			begin
			ptr := ptr - 1;
			goto 100;
			end;


	if ZIKeypressed = #0 + #77 then
		if ptr > length(ZIData[currentfield]) then
			begin
			Zbeep(1);
			goto 100;
			end
		else
			begin
			ptr := ptr + 1;
			goto 100;
			end;


	if copy(ZIKeypressed,1,1) = #0 then exit;
	if ZIKeyPressed = #27 then exit;


	if ZIInvalid[currentfield] = '' then Checkchars := Validchars
					else Checkchars := ZIInvalid[currentfield];


	if pos(ZIKeyPressed, Checkchars) = 0 then
		begin
		ZBeep(1);
		goto 100;
		end;


	if length(ZIData[currentfield]) >= ZILen[currentfield] then
		if ptr > ZILen[currentfield] then
		    begin
		    ZBeep(1);
		    goto 100;
		    end;


	if ptr > length(ZIData[currentfield]) then
		begin
		ZIData[currentfield] := ZIData[currentfield] + ZIKeyPressed;
		ptr := ptr + 1;
		write(ZIKeyPressed);
		goto 100;
		end
	else
		begin
		delete (ZIKeyPressed, ptr, 1);
		insert (ZIKeypressed, ZIData[currentfield], ptr);
		write (ZIKeyPressed);
		ptr := ptr + 1;
		end;



end;
