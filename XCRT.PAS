{Saved as: XCRT.PAS - eXtended CRT unit for TP 4.0
Pat Anderson, 3/27/88}

UNIT xcrt;

INTERFACE
USES crt, dos;
  TYPE
    Str1 = string[1];
    Str2 = string[2];
    Str15 = string[15];
    Str30 = string[30];
    Str79 = string[79];

  VAR
    Regs : Registers;         {predefined in dos unit}
    ScreenBase : word;        { Set to $b000 for mono,
                                $b800 for color}
    Monochrome : boolean;     {True if monochrome, false
                               if color}
    InsertFlag : boolean;     {used by EditLine procedure}

  FUNCTION GetKey : Str2;
   {Function that waits for a key press, no echo to
   screen, returns a string of type Str2, logical length
   of 1 or 2.  If length is 1, element [1] contains
   the normal ASCII code of the key pressed.  If the
   length is 2, element [2] contains the extended
   (scan) code of the key pressed}

  PROCEDURE AdaptorType;
  {Procedure that sets global variables ScreenBase
  to correct segment for mono or color adaptor, and
  Boolean variable Monochrome to True or False}

  PROCEDURE CursorOff;
  {Procedure turns the cursor off}

  PROCEDURE NormCursorOn;
  {Procedure that turns underscore cursor on}

  PROCEDURE BlockCursorOn;
  {Procedure that turns block cursor on}

  PROCEDURE ReverseVideo;
  {procedure that turns on reverse video}

  PROCEDURE BlinkOn;
  {procedure that turns on blinking}

  PROCEDURE Pad (VAR LineToPad : str79; PadLength : byte);

  PROCEDURE Strip (VAR LineToStrip :  str79);

  PROCEDURE EditLine (VAR line : str79; VAR cursor : byte;
                      col, row, fieldlength : byte;
                      VAR exit_key : str2);

IMPLEMENTATION

  FUNCTION GetKey;
    VAR ch : char;
        t  : Str2;
  BEGIN
    ch := ReadKey;
    t  := ch;
    IF (ch = chr(0)) AND KeyPressed THEN
      BEGIN
        ch := ReadKey;
        t  := t + ch;
       END;
    GetKey := t
  END; {of GetKey function}

  PROCEDURE AdaptorType;
    BEGIN
      INTR (17,Regs);
      IF (Regs.AX AND $0030) = $30 THEN
        BEGIN
          ScreenBase := $b000;
          Monochrome := TRUE
        END
      ELSE
        BEGIN
          ScreenBase := $b800;
          Monochrome := FALSE
        END
    END; {of AdaptorType procedure}

  PROCEDURE CursorOff;
    BEGIN
      Regs.AX := $0100;
      Regs.CX := $2000;
      INTR (16,Regs);
    END; {of CursorOff procedure}

  PROCEDURE NormCursorOn;
    BEGIN
      Regs.AX := $0100;   {AH = 1, set cursor size}
      IF Monochrome THEN
        Regs.CX := $0A0B
      ELSE
        Regs.CX := $0607;
      INTR (16,Regs)
    END; {of NormCursorOn procedure}

  PROCEDURE BlockCursorOn;
    BEGIN
      Regs.AX := $0100;   {AH = 1, set cursor size}
      IF Monochrome THEN
        Regs.CX := $020B
      ELSE
        Regs.CX := $0207;
      INTR (16,Regs)
    END; {of BlockCursorOn procedure}

  PROCEDURE ReverseVideo;
    BEGIN
      TextColor (0);
      TextBackground (7);
    END; {of ReverseVideo procedure}

  PROCEDURE BlinkOn;
    BEGIN
      TextAttr := TextAttr + Blink;
    END;

  PROCEDURE Pad;
    BEGIN
      WHILE Length (LineToPad) < PadLength DO
        LineToPad := LineToPad + ' ';
    END; {of Pad procedure}

  PROCEDURE Strip;
    VAR index : byte;
    BEGIN
      index := Length (LineToStrip);
      WHILE LineToStrip[index] = ' ' DO
        BEGIN
          Delete (LineToStrip,index,1);
          Dec (index)
        END
    END; {of Strip procedure}

{***************************************************************}
PROCEDURE EditLine;
  VAR
    ExitFlag : boolean;
    key : str2;

  PROCEDURE CursorRight;        {nested in Editline procedure}
    BEGIN
      Inc (cursor)
    END; {of CursorRight procedure}

  PROCEDURE CursorLeft;         {nested in EditLine procedure}
    BEGIN
      Dec (cursor)
    END; {of CursorLeft procedure}

  PROCEDURE CursorFront;        {nested in EditLine procedure}
    BEGIN
      cursor := col;
    END; {of CursorFront procedure}

  PROCEDURE CursorEnd;          {nested in EditLine procedure}
    VAR
      position : byte;
    BEGIN
      position := Length (line);
      WHILE line[position] = ' ' DO
        Dec (position);
      cursor := col + position
    END; {of CursorEnd procedure}

  PROCEDURE WordRight;          {nested in EditLine procedure}
    VAR position : byte;
    BEGIN
      position := cursor - col + 1;
      WHILE line[position] <> ' ' DO
        BEGIN
          Inc (position);
          IF position = fieldlength THEN Exit;
        END;
      Inc (position);
      cursor := col + position - 1
    END; {of WordRight procedure}

  PROCEDURE WordLeft;           {nested in Editline procedure}
    VAR position : byte;
    BEGIN
      position := cursor - col + 1;
      WHILE (line[position] <> ' ') AND (position >= 1) DO
        Dec (position);
      WHILE (line[position] = ' ') AND (position >= 1) DO
        Dec (position);
      WHILE (line[position] <> ' ') AND (position >= 1) DO
          Dec (position);
      cursor := col + position - 1;
      IF cursor > col THEN Inc (cursor)
    END; {of WordLeft procedure}

  PROCEDURE BackSpace;          {nested in EditLine procedure}
    VAR
      position : byte;
    BEGIN
      position := cursor - col + 1;
      Delete (line, position - 1, 1);
      CursorLeft;
      line := line + ' '
    END; {of BackSpace procedure}

  PROCEDURE DeleteChar;         {nested in EditLine procedure}
    VAR
      position : byte;
    BEGIN
      position := cursor - col + 1;
      Delete (line, position, 1);
      line := line + ' '
    END; {of DeleteChar procedure}

  PROCEDURE DeleteWord;         {nested in EditLine procedure}
    VAR
      position : byte;
    BEGIN
      position := cursor - col + 1;
      REPEAT
        DeleteChar
      UNTIL (COPY(line, position, 1) = ' ');
      DeleteChar
    END; {of DeleteWord procedure}

  PROCEDURE DeleteEOL;          {nested in EditLine procedure}
    VAR
      count, position : byte;
    BEGIN
      position := cursor - col + 1;
      count := FieldLength - position + 1;
      Delete (line, position, count);
      Pad (line, FieldLength)
    END; {of DeleteEOL procedure}

  PROCEDURE ToggleInsert;       {nested in EditLine procedure}
    BEGIN
      IF InsertFlag = TRUE THEN InsertFlag := FALSE
        ELSE IF InsertFlag = FALSE THEN InsertFlag := TRUE
    END; {of ToggleInsert procedure}

  PROCEDURE InsertChar;         {nested in EditLine procedure}
    VAR
      character : str1;
      position : byte;
    BEGIN
      position := cursor - col + 1;
      Delete (line, fieldlength,1);
      character := key[1];
      Insert (character, line, position);
      CursorRight
    END; {of InsertChar procedure}

  PROCEDURE ReplaceChar;        {nested in EditLine procedure}
    VAR
      position : byte;
    BEGIN
      position := cursor - col + 1;
      line[position] := key[1];
      CursorRight;
    END; {of ReplaceChar procedure}

  PROCEDURE PositionCursor;     {nested in Editline procedure}
    BEGIN
      IF cursor < col THEN cursor := col;
      IF cursor > col + fieldlength - 1 THEN cursor:=col;
      Gotoxy (cursor, row);
      IF InsertFlag = TRUE THEN
        BlockCursorOn
      ELSE
        NormCursorOn;
    END; {of PositionCursor procedure}

  PROCEDURE ExtendedCodes;      {nested in EditLine procedure}
    BEGIN
      CASE key[2] OF
        #75:  CursorLeft; {left arrow}
        #77:  CursorRight; {right arrow}
        #71:  CursorFront; {Home}
        #83:  DeleteChar; {Del}
        #79:  CursorEnd; {End}
        #82:  ToggleInsert; {Ins}
        #115: WordLeft; {Ctrl-left arrow}
        #116: WordRight; {Ctrl-right arrow}
      ELSE
        ExitFlag := TRUE
      END; {of CASE statement}
    END; {of ExtendedCodes procedure}

  PROCEDURE ControlCodes;       {nested in EditLine procedure}
    BEGIN
      CASE key[1] OF
        #8:   BackSpace; {Backspace}
        #5:   DeleteEOL;  {Ctrl-E}
        #23:  DeleteWord; {Ctrl-W}
      ELSE
        ExitFlag := TRUE
      END; {of CASE statement}
    END; {of ControlCodes procedure}

  PROCEDURE ActOnKeypress;            {nested in EditLine procedure}
    BEGIN
      IF Length (key) = 2 THEN Extendedcodes
        ELSE
          BEGIN
            IF key[1] IN [#0..#31] THEN ControlCodes;
            IF key[1] IN [#32..#126] THEN
              BEGIN
                IF InsertFlag = TRUE THEN InsertChar
                  ELSE ReplaceChar
              END
          END;
    END; {of ActOnKeypress procedure}

  PROCEDURE GetKeypress;        {nested in EditLine procedure}
    BEGIN
      key := GetKey
    END; {of GetKeypress procedure}

  PROCEDURE DisplayLine;        {nested in EditLine procedure}
    BEGIN
      CursorOff;
      if col>48 then col:=48;
      GotoXY (col, row);
      Write (line)
    END; {of DisplayLine procedure}

  BEGIN {MAIN of EditLine procedure}
    ExitFlag := FALSE;
    Pad (line, FieldLength);
    WHILE ExitFlag = FALSE DO
      BEGIN
        DisplayLine;
        PositionCursor;
        GetKeypress;
        ActOnKeypress;
      END;
    Strip (line);
    exit_key := key
  END; {of EditLine procedure}

{Unit initialization - set ScreenBase, Monochrome variables}
BEGIN
  AdaptorType;
END.
