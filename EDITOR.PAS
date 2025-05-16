  {$R-,S-,I-,D-,F+,V-,B-,N-,L+,O+ }

  unit editor;

  Interface

 uses crt,
  gentypes,configrt,statret,gensubs,subs1,subs2,
  userret,textret,mainr1,mainr2,overret1,flags;


Type
  InpDate    = String[8];
  InpString  = String[80];
  InpInteger = String[10];
  InpReal    = String[28];
  Str80      = String[80];

Var
  FieldNo    : LongInt;
  LastField  : LongInt;
  Procedure ansicolor2(attrib:Integer;defback:integer);

Procedure Color(Foreground,Background : Byte);
Procedure Color2(Foreground,Background,def : Byte);
Procedure Beep;
Procedure EditDate(Var DS    : InpDate;
                   X,Y,FG,BG : Byte);
Procedure EditString(Var S       : InpString;
                     L,X,Y,FG,BG : Byte;
                     Picture     : Str80);
Procedure EditInt(Var I       : LongInt;
                  L,X,Y,FG,BG : Byte);
Procedure EditReal(Var I : Real;
                   L,X,Y,DecPl,FG,BG : Byte);
Procedure EditChoice(Var C            : Char;
                     X,Y              : Byte;
                     Choice1,Choice2  : Char;
                     FG,BG            : Byte);

Implementation

  Procedure ansicolor2(attrib:Integer;defback:integer);
    Var tc:Integer;
    Const colorid:Array[0..7] Of Byte=(30,34,32,36,31,35,33,37);
    Begin
      If attrib=0 Then attrib:=1;

      If attrib=0 Then Begin
        TextColor(7);
        textbackground(0)
      End Else Begin
        TextColor(attrib And $8f);
        textbackground((attrib Shr 4) And 7)
      End;

 {     curattrib:=attrib;        }

      if vt52 in urec.config then
      if attrib<>curattrib then wvt52(#234+#234+#07+chr(attrib));

      If (ansigraphics in urec.config) and (attrib<>curattrib) Then begin
        If Not(ansigraphics In urec.config) Then exit;

      Write(direct,#27'[0');
      tc:=attrib And 7;
      Write(direct,';',colorid[tc]);
      tc:=(attrib Shr 4) And 7;
      Write(direct,';',colorid[tc]+10);
      if defback>0 then write(direct,';4'+strr(defback)) else begin
      If (attrib And 8)=8 Then Write(direct,';1');
      If (attrib And 128)=128 Then Write(direct,';5');
      end;
      Write(direct,'m');
      curattrib:=attrib;
      end;
    End;

Procedure Color(Foreground,Background : Byte);
var kr,kr1:integer;
Begin
  kr:=foreground + (background shl 4);
  ansicolor2(kr,0);
{  TextColor(Foreground);
  TextBackground(Background);}
End;

Procedure Color2(Foreground,Background,def : Byte);
var kr,kr1:integer;
Begin
  kr:=foreground + (background shl 4);
  ansicolor2(kr,def);ansicls;
{  TextColor(Foreground);
  TextBackground(Background);}
End;

Procedure InverseColor(Foreground,Background : Byte);
var kr:integer;
Begin
  If Foreground < 8 then Foreground := Foreground + 8;
  If Background > 8 then Background := Background - 8;
    kr:=foreground + (background shl 4);
  ansicolor2(kr,0);

{  TextColor(Background);
  TextBackground(Foreground);}
End;

Procedure Beep;
Begin
{write(^G);}
End;

Procedure EditDate(Var DS    : InpDate;
                   X,Y,FG,BG : Byte);
Var
  Mo,Da,Yr  : String[2];
  Done      : Boolean;
  Ch        : Char;
  Postn       : Byte;
Begin
  ansigotoxy(X,Y);
  InverseColor(FG,BG);
  If DS = '' then
  Begin
    DS := '  /  /  ';
    Write(DS);
  End else Write(DS);
  ansigotoxy(X,Y); Postn := X;
  Done := False;
  Repeat
  Ch := waitforchar;
    Case Ch of
      '0'..'9' : Begin
                   Write(Ch);
                   DS[(Postn+1)-X] := Ch;
                   Postn := Postn + 1;
                   If (Postn = X+2) or (Postn = X+5) then Postn := Postn + 1;
                   ansigotoxy(Postn,Y);
                   If Postn >= X + 8 then
                   Begin
                     Done := True;
                     Inc(FieldNo);
                   End;
                 End;
           #13 : Begin
                   Done := True;
                   Inc(FieldNo);
                 End;

           ^R : Begin
                                            Done := True;
                                 FieldNo := 1;
                               End;
                         ^C : Begin
                                 Done := True;
                                 FieldNo := LastField;
                               End;


            #0 : Begin
                 if keypressed then   Ch := Readkey else ch:=waitforchar;
                   Case Ch of
                         #71 : Begin               { Home }
                                 Postn := X;
                                 ansigotoxy(Postn,Y);
                               End;
                         #72 : Begin               { Up Arrow }
                                 Done := True;
                                 Dec(FieldNo);
                                 If FieldNo < 1 then FieldNo := 1;
                               End;
                         #80 : Begin               { Down Arrow }
                                 Done := True;
                                 Inc(FieldNo);
                                 If FieldNo > LastField then
                                   FieldNo := LastField;
                               End;
                         #73 : Begin               { PgUp }
                                 Done := True;
                                 FieldNo := 1;
                               End;
                         #81 : Begin               { PgUp }
                                 Done := True;
                                 FieldNo := LastField;
                               End;
                         #75 : Begin               { Left arrow }
                                 Postn := Postn - 1;
                                 If (Postn = X+2) or (Postn = X+5) then
                                   Postn := Postn - 1;
                                 ansigotoxy(Postn,Y);
                                 If Postn < X  then Postn := X;
                               End;
                         #77 : Begin               { Right arrow }
                                 Postn := Postn + 1;
                                 If (Postn = X+2) or (Postn = X+5) then
                                   Postn := Postn + 1;
                                 ansigotoxy(Postn,Y);
                                 If Postn >= X + 6  then Postn := X + 6;
                               End;
                   End; { Case }
                 End; { Ch = #0 }

          #27 :  Begin
                   Repeat
            ch:=waitforchar;
            Case ch Of
              'A' :;
              'B' :;
              'C' :;
              'D' :;
            End
          Until (ch<>'[') Or hungupon;

                   Case Ch of
                         'A' : Begin               { Up Arrow }
                                 Done := True;
                                 Dec(FieldNo);
                                 If FieldNo < 1 then FieldNo := 1;
                               End;
                         'B' : Begin               { Down Arrow }
                                 Done := True;
                                 Inc(FieldNo);
                                 If FieldNo > LastField then
                                   FieldNo := LastField;
                               End;
                         'D': Begin               { Left arrow }
                                 Postn := Postn - 1;
                                 If (Postn = X+2) or (Postn = X+5) then
                                   Postn := Postn - 1;
                                 ansigotoxy(Postn,Y);
                                 If Postn < X  then Postn := X;
                               End;
                         'C': Begin               { Right arrow }
                                 Postn := Postn + 1;
                                 If (Postn = X+2) or (Postn = X+5) then
                                   Postn := Postn + 1;
                                 ansigotoxy(Postn,Y);
                                 If Postn >= X + 6  then Postn := X + 6;
                               End;
                   End; { Case }
                 End; { Ch = #0 }


    End; { Case }
  Until Done or hungupon;
  Color(FG,BG);
  ansigotoxy(X,Y); Write(DS);
End;

Procedure EditString(Var S       : InpString;
                     L,X,Y,FG,BG : Byte;
                     Picture     : Str80);
Var
  InsFlag,
  Done    : Boolean;
  Postn     : Byte;
  Ch      : Char;
Begin
  Done := False;
  InsFlag := False;
  ansigotoxy(X,Y);
  InverseColor(FG,BG);
  While Length(S) < L do S := S + ' ';
  ansigotoxy(X,Y);
  Write(S);
  ansigotoxy(X,Y);
  Postn := X;
  Repeat
    Ch := waitforchar;
    Case Ch of
      #32..#126 : Begin
                    If InsFlag then
                    Begin
                      If Picture[Postn+1-X] = 'U' then Ch := Upcase(Ch);
                      Write(Ch);
                      Insert(Ch,S,(Postn+1)-X);
                      S[0] := Chr(L);
                      ansigotoxy(X,Y); Write(S);
                    End else
                    Begin
                      If Picture[Postn+1-X] = 'U' then Ch := Upcase(Ch);
                      Write(Ch);
                      S[(Postn+1)-X] := Ch;
                    End;
                    Inc(Postn);
                    If (Picture[Postn-X] = '#') and not (Ch in['0'..'9']) then
                    Begin
                      Dec(Postn);
                      Delete(S,Postn+1-X,1);
                      S := S + ' ';
                      ansigotoxy(X,Y); Write(S);
                      Beep;
                    End;
                    If Picture[Postn+1-X] = '*' then Inc(Postn);
                    ansigotoxy(Postn,Y);
                    If Postn >= X + L then
                    Begin
                      Done := True;
                      Inc(FieldNo);
                    End;
                  End;
            #13 : Begin
                    Done := True;
                    Inc(FieldNo);
                  End;
             #8 : Begin                        { Destructive Backspace }
                    If Pos('-',Picture) = 0 then
                    Begin
                      Dec(Postn);
                      If Postn < X then Postn := X;
                      Delete(S,(Postn+1)-X,1);
                      S := S + ' ';
                      ansigotoxy(X,Y); Write(S);
                      ansigotoxy(Postn,Y);
                    End;
                  End;
             #0 : Begin
                    Ch := readchar;
                    Case Ch of
                      #71 : Begin          { Home }
                              Postn := X;
                              ansigotoxy(Postn,Y);
                            End;
                      #72 : Begin               { Up Arrow }
                              Done := True;
                              Dec(FieldNo);
                              If FieldNo < 1 then FieldNo := 1;
                            End;
                      #80 : Begin               { Down Arrow }
                              Done := True;
                              Inc(FieldNo);
                              If FieldNo > LastField then
                                FieldNo := LastField;
                            End;
                      #73 : Begin               { PgUp }
                              Done := True;
                              FieldNo := 1;
                            End;
                      #81 : Begin               { PgUp }
                              Done := True;
                              FieldNo := LastField;
                            End;
                      #75 : Begin          { Left arrow }
                              Dec(Postn);
                              If Picture[Postn+1-X] = '*' then Dec(Postn);
                              ansigotoxy(Postn,Y);
                              If Postn < X  then Postn := X;
                            End;
                      #77 : Begin          { Right arrow }
                              Inc(Postn);
                              If Picture[Postn+1-X] = '*' then Inc(Postn);
                              ansigotoxy(Postn,Y);
                              If Postn >= X + L-2  then Postn := X + L-2;
                            End;
                      #82 : Begin          { Toggle Insert }
                              If Pos('*',Picture) = 0 then
                              If not InsFlag then InsFlag := True
                                else InsFlag := False;
                            End;
                      #83 : Begin          { Del }
                              If Pos('*',Picture) = 0 then
                              Begin
                                Delete(S,(Postn+1)-X,1);
                                S := S + ' ';
                                ansigotoxy(X,Y); Write(S);
                                ansigotoxy(Postn,Y);
                              End;
                            End;
                    End; { Case }
                  End; { Ch = #0 }
    End; { Case }
  Until Done or hungupon;
  Color(FG,BG);
  ansigotoxy(X,Y); Write(S);
  While S[Length(S)] = ' ' do Delete(S,Length(S),1)
End;

Function IntToStr(I : LongInt; Len : Byte) : InpInteger;
Var
  IntString : InpInteger;
Begin
  Str(I:Len,IntString);
  IntToStr := IntString;
End;

Function StrToInt(IStr : InpInteger) : LongInt;
Var
  Code      : Integer;
  StringInt : LongInt;
Begin
  While IStr[1] = ' ' do Delete(IStr,1,1);
  Val(IStr,StringInt,Code);
  StrToInt := StringInt;
End;

Procedure EditInt(Var I       : LongInt;
                  L,X,Y,FG,BG : Byte);
Var
  Done    : Boolean;
  Postn     : Byte;
  Ch      : Char;
  IInt    : InpInteger;
Begin
  Done := False;
  ansigotoxy(X,Y);
  InverseColor(FG,BG);
  IInt := IntToStr(I,L);
  Write(IInt);
  ansigotoxy(X,Y);
  Postn := X + L;
  ansigotoxy(Postn-1,Y);
  Repeat
    Ch := waitforchar;
    Case Ch of
     '-','0'..'9' : Begin
                      IInt := IInt + Ch;
                      While (IInt[1] = ' ') or (IInt[1] = '0')
                        do Delete(IInt,1,1);
                      If Length(IInt) = L then
                      Begin
                        Done := True;
                        Inc(FieldNo);
                      End;
                      While Length(IInt) < L do IInt := ' ' + IInt;
                      ansigotoxy(X,Y); Write(IInt);
                      ansigotoxy(Postn-1,Y);
                    End;
              #13 : Begin
                      Done := True;
                      Inc(FieldNo);
                    End;
               #8 : Begin
                      Delete(IInt,Length(IInt),1);
                      While Length(IInt) < L do IInt := ' ' + IInt;
                      ansigotoxy(X,Y); Write(IInt);
                      ansigotoxy(Postn-1,Y);
                    End;
               #0 : Begin
                      Ch := waitforchar;
                      Case Ch of
                        #83 : Begin
                                Delete(IInt,Length(IInt),1);
                                While Length(IInt) < L do IInt := ' ' + IInt;
                                ansigotoxy(X,Y); Write(IInt);
                                ansigotoxy(Postn-1,Y);
                              End;
                        #72 : Begin               { Up Arrow }
                                Done := True;
                                Dec(FieldNo);
                                If FieldNo < 1 then FieldNo := 1;
                              End;
                        #80 : Begin               { Down Arrow }
                                Done := True;
                                Inc(FieldNo);
                                If FieldNo > LastField then
                                  FieldNo := LastField;
                              End;
                        #73 : Begin               { PgUp }
                                Done := True;
                                FieldNo := 1;
                              End;
                        #81 : Begin               { PgUp }
                                Done := True;
                                FieldNo := LastField;
                              End;
                      End; { Case }
                    End;
    End; { Case }
  Until Done or hungupon;
  Color(FG,BG);
  ansigotoxy(X,Y); Write(IInt);
  I := StrToInt(IInt);
End;

Function RealToStr(I : Real; L,DecPl : Byte) : InpReal;
Var
  StringReal : InpReal;
Begin
  Str(I:L:DecPl,StringReal);
  RealToStr := StringReal;
End;

Function StrToReal(RealStr : InpReal) : Real;
Var
  Code : Integer;
  RealString : Real;
Begin
  While RealStr[1] = ' ' do Delete(RealStr,1,1);
  Val(RealStr,RealString,Code);
  StrToReal := RealString;
End;

Procedure EditReal(Var I : Real;
                   L,X,Y,DecPl,FG,BG : Byte);
Var
  DecFlag,
  Done     : Boolean;
  Postn,Loc  : Byte;
  Ch       : Char;
  IntPart  : InpInteger;
  DecPart  : InpReal;
  IReal    : InpReal;
Begin
  Done := False;
  DecFlag := False;
  IReal := RealToStr(I,L,DecPl);
  IntPart := Copy(IReal,1,L-(DecPl+1));
  DecPart := Copy(IReal,L-DecPl+1,DecPl);
  InverseColor(FG,BG);
  ansigotoxy(X,Y); Write(IReal);
  Postn := (X+L) - (DecPl+2);
  ansigotoxy(Postn,Y);
  Repeat
    Ch := waitforchar;
    Case Ch of
              #46 : Begin
                      If DecFlag then
                      Begin
                        DecFlag := False;
                        Postn := (X+L) - (DecPl+2);
                        ansigotoxy(Postn,Y);
                      End;
                      If not DecFlag then
                      Begin
                        DecFlag := True;
                        Loc := 1;
                        Postn := (X+L) - (DecPl);
                        ansigotoxy(Postn,Y);
                      End;
                    End;
     '-','0'..'9' : Begin
                      If not DecFlag then
                      Begin
                        IntPart := IntPart + Ch;
                        While (IntPart[1] = ' ') or (IntPart[1] = '0')
                          do Delete(IntPart,1,1);
                        If Length(IntPart) = L - (DecPl+1) then
                        Begin
                          DecFlag := True;
                          Loc := 1;
                          Postn := (X+L) - (DecPl);
                          ansigotoxy(Postn,Y);
                        End;
                        While Length(IntPart) < L - (DecPl+1)
                          do IntPart := ' ' + IntPart;
                        ansigotoxy(X,Y); Write(IntPart);
                        ansigotoxy(Postn,Y);
                      End else
                      Begin
                        DecPart[Loc] := Ch;
                        ansigotoxy(Postn,Y); Write(Copy(DecPart,1,DecPl));
                        ansigotoxy(Postn,Y);
                        Inc(Loc);
                        If DecPart[DecPl] > '0' then
                        Begin
                          Done := True;
                          Inc(FieldNo);
                        End;
                      End;
                    End;
              #13 : Begin
                      Done := True;
                      Inc(FieldNo);
                    End;
               #8 : Begin
                      If not DecFlag then
                      Begin
                        Delete(IntPart,Length(IntPart),1);
                        While Length(IntPart) < L-DecPl-1
                          do IntPart := ' ' + IntPart;
                        ansigotoxy(X,Y); Write(IntPart);
                        ansigotoxy(Postn,Y);
                      End else
                      Begin
                        Delete(DecPart,1,1);
                        DecPart := DecPart + '0';
                        ansigotoxy(X+L-DecPl,Y);
                        Write(DecPart);
                        ansigotoxy(Postn,Y);
                      End;
                    End;
               #0 : Begin
                      Ch := waitforchar;
                      Case Ch of
                        #83 : Begin
                                If not DecFlag then
                                Begin
                                  Delete(IntPart,Length(IntPart),1);
                                  While Length(IntPart) < L-DecPl-1
                                    do IntPart := ' ' + IntPart;
                                  ansigotoxy(X,Y); Write(IntPart);
                                  ansigotoxy(Postn,Y);
                                End else
                                Begin
                                  Delete(DecPart,1,1);
                                  DecPart := DecPart + '0';
                                  ansigotoxy(X+L-DecPl,Y);
                                  Write(DecPart);
                                  ansigotoxy(Postn,Y);
                                End;
                              End;
                        #72 : Begin               { Up Arrow }
                                Done := True;
                                Dec(FieldNo);
                                If FieldNo < 1 then FieldNo := 1;
                              End;
                        #80 : Begin               { Down Arrow }
                                Done := True;
                                Inc(FieldNo);
                                If FieldNo > LastField then
                                  FieldNo := LastField;
                              End;
                        #73 : Begin               { PgUp }
                                Done := True;
                                FieldNo := 1;
                              End;
                        #81 : Begin               { PgUp }
                                Done := True;
                                FieldNo := LastField;
                              End;
                      End; { Case }
                    End;
    End; { Case }
  Until Done or hungupon;
  Color(FG,BG);
  IReal := IntPart + '.' + DecPart;
  ansigotoxy(X,Y); Write(IReal);
  I := StrToReal(IReal);
End;

Procedure EditChoice(Var C            : Char;
                     X,Y              : Byte;
                     Choice1,Choice2  : Char;
                     FG,BG            : Byte);
Var
  Done : Boolean;
  Ch   : Char;
Begin
  Done := False;
  ansigotoxy(X,Y);
  InverseColor(FG,BG);
  Repeat
    Ch := Upcase(waitforchar);
    If Ch in[Choice1,Choice2] then
    Begin
      Done := True;
      Inc(FieldNo);
    End else
    Begin
      Case Ch of
        #0 : Begin
               Ch := waitforchar;
               Case Ch of
                 #72 : Begin               { Up Arrow }
                         Done := True;
                         Dec(FieldNo);
                         If FieldNo < 1 then FieldNo := 1;
                       End;
                 #80 : Begin               { Down Arrow }
                         Done := True;
                         Inc(FieldNo);
                         If FieldNo > LastField then
                           FieldNo := LastField;
                       End;
                 #73 : Begin               { PgUp }
                         Done := True;
                         FieldNo := 1;
                       End;
                 #81 : Begin               { PgUp }
                         Done := True;
                         FieldNo := LastField;
                       End;
               End; { Case }
             End; { Ch = #0 }
      End; { Case }
    End;
    If not Done then Beep;
  Until Done or hungupon;
  C := Ch;
  Color(FG,BG);
  ansigotoxy(X,Y); Write(C);
End;

End.
