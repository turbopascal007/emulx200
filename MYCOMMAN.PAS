
  unit mycomman;

  Interface

  uses crt,dos,
  gentypes,configrt,modem,statret,gensubs,subs1,windows,subs2,textret,
  mailret,userret,flags,mainr1,ansiedit,lineedit,chatstuf,
  mainr2,overret1;{ that's everything! }


  Procedure mycommand;

  Implementation


  procedure mycommand;

var point,winlose,points,money,bet,die1,die2,dice,q:integer;
 quit:boolean;

procedure rolldice;
begin
 die1:=random(6)+1;
 die2:=random(6)+1;
 dice:=die1+die2;
end;

procedure cash;
begin
 writeln;
 writeln ('You now have ',money,' dollars.');
end;

procedure getbet;
begin
quit:=false;
 repeat
  repeat
   write (^P'What is your stake for this round [0=end] ? ');
   getstr;
   bet:=valu(input);
   if bet=0 then quit:=true;
   if bet=0 then bet:=money;
  until (bet<money+1) or (bet=0);
 until (bet>0) or quit;
 if quit then writeln (^P'Had enough I guess...') else
  writeln (^R'OK, you just bet '^R,bet,^S' dollars!');
end;

procedure craps;
begin
 writeln (^S'Craps! You lose sucker...');
 money:=money-bet;
end;

procedure win;
begin
 writeln (^P'We have a winner!');
 money:=money+bet;
end;

procedure intro;
begin
 writehdr ('Welcome to Online Craps.');
{ writestr ('Do you wish instructions? *');
 if yes then printfile ('crapsins');}
end;

procedure pointstomoney;
begin
 repeat
  writeln (^R'You have '^S,urec.udpoints,^R' file points.');
  writeln (^P'How much would you like to convert to Cash?');
  getstr;
  points:=valu(input);
 until (points<=urec.udpoints) or (points=0) or hungupon;

 if points>3 then writeln (^B^S' Maximum stake is 3 points! ');
 if points>3 then exit;
 if money>150 then writeln (^B^S' Maximum Cash stake is 150');
 if money>150 then exit;
 if points>0 then money:=money+(points*50);
 if points>0 then urec.udpoints:=urec.udpoints-points;
   writeln (^R'You now have '^S,urec.udpoints,^R' file points.');

end;

procedure moneytopoints;
begin
 writehdr ('CASH to points!');
 Writeln (^R'You have '^S,money,^R' Money!. ');
 urec.udpoints:=urec.udpoints+money div 50;
 Writeln (^R'You now have '^S,urec.udpoints,^R' Points');
 money:=0;
end;

procedure convertmenu;
begin
 writehdr ('The Gambling Bank');
 writeln ('[P] Points to money ');
 writeln ('[C] Change money to points ');
 writeln ('[Q] Quit');

end;
procedure convert;
begin
 repeat
 convertmenu;
  q:=menu ('Bank','BANK','QPC');
  writeln;
   case q of
    1:;
    2:pointstomoney;
    3:moneytopoints;
   end
  until (q=1) or hungupon;
end;

procedure crapsgame;
var winlose:integer;
begin
 intro;
 quit:=false;
 if money>0 then
 begin
  repeat
   cash;
   bet:=0;
   getbet;
   if not quit then
   begin
   ansicls;
    write (^R'Now rolling :'^S);
    rolldice;
    writeln (^P'It''s a:'^S,dice);
    winlose:=0;
    if dice=7 then winlose:=2;
    if dice=11 then winlose:=2;
    if winlose=2 then win else begin
     point:=dice;
     writeln (^R'OK, you''ve made it this far, now try and get another '^S,dice,^S' to win!');
      begin
       repeat
        winlose:=0;
        rolldice;
        writeln (^R'You rolled a '^S,dice);
        if dice=7 then winlose:=1;
        if dice=11 then winlose:=1;
        if dice=point then winlose:=2;
       until (winlose>0) or hungupon;
      end;
      if winlose=2 then win;
      if winlose=1 then craps;
     end;
   end;
  if money<1 then quit:=true;
  until quit or hungupon;
 end;
 if money<1 then writeln (^R'That''s too bad, you''re out of cash! Try going to the bank!');
 writeln ('Thanks for playing Craps. I hope you lost money!');
end;


begin
 money:=0;
 repeat
   writehdr('Gambling section!');
 writeln ('[C] Play Craps! ');
 writeln ('[B] Go to the BANK. ');
 writeln ('[Q] Quit');

  q:=menu ('Game','GAME','CBQ');
  writeln;
  case q of
   1:crapsgame;
   2:convert;
   3:;
  end
 until (q=3) OR HUNGUPON;
 moneytopoints;
end;

begin
End.
          ϸd
(  SETPAR  ASM           ��d
�  