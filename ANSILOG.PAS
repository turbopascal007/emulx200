  {$R-,S-,I-,D-,F+,V-,B-,N-,L+,O+ }

  unit AnsiLog;

  Interface

 uses crt,
  gentypes,configrt,statret,gensubs,subs1,subs2,
  userret,textret,mainr1,mainr2,overret1,flags,editor;

  Procedure Ansi_Info_Box;

  Implementation

Var
  Date       : String[8];     (* These could just as easily be a record type *)
  FullName   : String[35];
  Address    : String[35];
  City       : String[30];
  State      : String[2];
  Zip        : String[5];
  Phone      : String[8];
  Purchase   : Real;

  Continue   : Char;          (* Stand-alone entry variables *)
  MenuSelect : LongInt;

(* This is a quick-and-dirty method of providing for a "Main Menu". It could
   just as easily be done using windowing techniques. *)

Procedure MainMenu;
var kool:integer;
Begin

for kool:=7 downto 3 do color2(yellow,blue,kool);
write(direct,#27+'[0;0;40m');
  Color(Yellow,Blue);     (* Set the menu colors and draw the menu *)
  ansigotoxy(20, 2); Write('ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿');
  ansigotoxy(20, 3); Write('³            Main Menu              ³');
  ansigotoxy(20, 4); Write('ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´');
  ansigotoxy(20, 5); Write('³  1. Entry Screen 1                ³');
  ansigotoxy(20, 6); Write('³  2. Not used                      ³');
  ansigotoxy(20, 7); Write('³  3. Not used                      ³');
  ansigotoxy(20, 8); Write('³  4. Not used                      ³');
  ansigotoxy(20, 9); Write('³  5. Exit Demo                     ³');
  ansigotoxy(20,10); Write('³                                   ³');
  ansigotoxy(20,11); Write('ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ');

    (* After displaying the menu, change the colors and display a single entry
       data selection block.  Note that it is a numeric (integer) entry and
       doesn't require the Enter key be pressed. *)

  Color(Yellow,Black);
  ansigotoxy(27,13); Write('Enter Selection:');
  EditInt(MenuSelect,1,44,13,15,0);
  ansicls;
End;

(* This procedure merely draws the data entry screen.  Note that a slightly
   different method is used from the menu procedure: the basic screen is
   drawn first with the field descriptions overlaid on the screen.  This
   allows easier "fine-tuning" of the field description placement. *)

Procedure EntryScr;
var coco:integer;
Begin
  Color2(Blue,Cyan,3);  (* Set the entry screen color *)
  ansigotoxy(1,1);
  Write('ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿');
  Write('³'+#27+'[78C³');
  Write('³'+#27+'[78C³');
  Write('³'+#27+'[78C³');
  Write('³'+#27+'[78C³');
  Write('³'+#27+'[78C³');
  Write('³'+#27+'[78C³');
  Write('³'+#27+'[78C³');
  Write('³'+#27+'[78C³');
  Write('³'+#27+'[78C³');
  Write('ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´');
  Write('³'+#27+'[78C³');
  Write('³'+#27+'[78C³');
  Write('ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ');
  Write('Colors: ');
  for coco:=1 to 17 do begin ansicolor(coco); write(direct,coco,' ');end;
  color(blue,cyan);

    (* Overlay the screen and field descriptions on the pre-drawn screen *)

  ansigotoxy(26, 1); Write('[ New User Information ]');
  ansigotoxy(32,11); Write('[ Instructions ]');
  ansigotoxy(57,14); Write('[ Emulex/2 ]');
 ansigotoxy(5 , 3);Write('Password  :');
  ansigotoxy(7 , 4); write('Colors  :');
  ansigotoxy(7 , 5); Write('Regular :');
  ansigotoxy(27 , 5); Write('Prompt  :');
  ansigotoxy(47 , 5); Write('Status  :');
  ansigotoxy(67 , 5); Write('Typing  :');
  ansigotoxy(7, 7); Write('Screen Length :');
  ansigotoxy(50, 7); Write('Default Colors Set # :');
  ansigotoxy(9 , 9); Write('Phone :    -   -');
End;

              (*  This is the actual input procedure  *)

Procedure NewInput;
var cc:integer;
phoney:mstr;
Begin
  FieldNo   := 1;        (* Begin with field 1.  This can be any number
                            between 1 and LastField and provides the
                            default "first" data field to be entered. *)
  LastField := 7;        (* This is the last field to be entered.  Once
                            the Enter key is pressed, data entry is
                            complete. *)
  Date      := '';       (* Initialize the entry variables. *)
  FullName  := '';
  Address   := '';
  City      := '';
  State     := '';
  Zip       := '';
  Phone     := '   -';   (* Note the "-" in the phone number field. *)
  Purchase  := 0.0;

  (* The "Repeat - Until" loop allows the data entry operator to skip around
     on the screen and enter or revise data at choice. *)

  Repeat
    Case FieldNo of
      1 : Begin
           Color(Red,Cyan);
           ansigotoxy(2,12); Write('':78);
           ansigotoxy(5,12); Write('Enter a new password');
           EditString(urec.password,14,17,3,Black,Cyan,'        ');
          End;
      2 : Begin
           Color(Red,Cyan);
           ansigotoxy(2,12); Write('':78);
           ansigotoxy(5,12); Write('Enter regular color #');
           address:=strr(urec.regularcolor);
           EditString(Address,2,17,5,Black,Cyan,'##');
           urec.regularcolor:=valu(address);
          End;
      3 : Begin
           Color(Red,Cyan);
           ansigotoxy(2,12); Write('':78);
           ansigotoxy(5,12); Write('Enter Prompt color #');
           address:=strr(urec.promptcolor);
           EditString(Address,2,37,5,Black,Cyan,'##');
           urec.promptcolor:=valu(address);
          End;
      4 : Begin
           Color(Red,Cyan);
           ansigotoxy(2,12); Write('':78);
           ansigotoxy(5,12); Write('Enter Status color #');
           address:=strr(urec.statcolor);
           EditString(Address,2,57,5,Black,Cyan,'##');
           urec.statcolor:=valu(address);
          End;
      5 : Begin
           Color(Red,Cyan);
           ansigotoxy(2,12); Write('':78);
           ansigotoxy(5,12); Write('Enter input color #');
           address:=strr(urec.inputcolor);
           EditString(Address,2,77,5,Black,Cyan,'##');
           urec.inputcolor:=valu(Address);
          End;
           6 : Begin
           Color(Red,Cyan);
           ansigotoxy(2,12); Write('':78);
           ansigotoxy(5,12); Write('Enter Display Length');
           address:=strr(urec.displaylen);
           EditString(Address,2,24,7,Black,Cyan,'##');
           urec.displaylen:=valu(address);
          End;

      7 : Begin
           Color(Red,Cyan);
           ansigotoxy(2,12); Write('':78);
           ansigotoxy(5,12); Write('Enter NUMERIC telephone number');
           EditString(urec.Phonenum,12,17,9,Black,Cyan,'##########');


          End;
    End; { Case }
  Until hungupon or (FieldNo > LastField);   (* If the Enter key is pressed on the last
                                  field, then we're done. *)
  ansigotoxy(2,12); Write('':78);  (* Clear the last instruction *)
  Color(14,0);                 (* Change the colors *)

    (* A stand-alone choice field *)

  ansigotoxy(20,17); Write('Is the Entry ok (Y/N)?');
  EditChoice(Continue,49,17,'Y','N',Yellow,Black);

    (* Clear the screen for rewrite, regardless of the choice *)

  ansicls;
End;

(* This is the mainline.  Note the nested loops could be separate procedures,
   but this is a little simpler. *)


procedure ansi_info_box;
Begin
  Color(14,0);                          (* Initialize the screen color *)
  ansicls;                               (* Clear the screen *)
  Repeat                                (* The first loop *)
    MenuSelect := 0;                    (* Re-initialize variable each time *)
          Repeat                     (* The data screen loop *)
               ansicls;
               EntryScr;
               NewInput;
             Until (Continue = 'Y') or (hungupon);      (* End data entry loop *)
  Until ( continue='Y') or hungupon;                 (* then the first loop *)
End;
begin
end.