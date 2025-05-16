  { Revision History
    881026 - Cleaned up Group / Level access
           - Troglodyte
  }

  {$R-,S-,I-,D-,F+,O+,V-,B-,N-,L+ }

  unit voting;

  Interface

  uses gentypes,gensubs,subs1,subs2,userret,overret1;

  Procedure votingbooth(getmandatory:Boolean);

  Implementation

Procedure votingbooth(getmandatory:Boolean);
  Var curtopic:topicrec;
    curtopicnum:Integer;

  Function hasaccess:Boolean;
    Var cnt:Integer;
      a,b:anystr;
      c:Boolean;

    Begin
      c:=False;
      If curtopic.area_type in [ 'L', 'B'] Then Begin
        If ulvl>=curtopic.votelevel Then c:=True;End;

      If curtopic.area_type in [ 'G', 'B'] Then Begin
      If isinlist(curtopic.File_List) Then c:=True;End;

      HasAccess:=c;
    End;


  Function votefn(n:Integer):sstr;
    Begin
      votefn:='Votefile.'+strr(n)
    End;

  Procedure opentopicdir;
    Var n:Integer;
    Begin
      Assign(tofile,'VOTEDIR');
      Reset(tofile);
      If IOResult<>0 Then Begin
        Close(tofile);
        n:=IOResult;
        Rewrite(tofile)
      End
    End;

  Function numtopics:Integer;
    Begin
      numtopics:=FileSize(tofile)
    End;

  Procedure opentopic(n:Integer);
    Var q:Integer;
    Begin
      curtopicnum:=n;
      Close(chfile);
      Assign(chfile,votefn(n));
      Reset(chfile);
      If IOResult<>0 Then Begin
        Close(chfile);
        q:=IOResult;
        Rewrite(chfile)
      End;
      Seek(tofile,n-1);
      Read(tofile,curtopic)
    End;

  Function numchoices:Integer;
    Begin
      numchoices:=FileSize(chfile)
    End;

  Procedure writecurtopic;
    Begin
      Seek(tofile,curtopicnum-1);
      Write(tofile,curtopic)
    End;

  Procedure listchoices;
    Var ch:choicerec;
      cnt:Integer;
    Begin
      If Not hasaccess Then exit;
      writehdr('Voting Choices');
      Seek(chfile,0);
      For cnt:=1 To numchoices Do
        Begin
          Read(chfile,ch);
          WriteLn(cnt:2,'.  ',ch.choice);
          If break Then exit
        End
    End;

  Function addchoice:Integer;
    Var ch:choicerec;
    Begin
      addchoice:=0;
      BufLen:=70;
      writestr(^M'Enter new choice: &');
      If Length(Input)<2 Then exit;
      addchoice:=numchoices+1;
      ch.numvoted:=0;
      ch.choice:=Input;
      Seek(chfile,numchoices);
      Write(chfile,ch);
      writelog(20,2,ch.choice)
    End;

  Procedure getvote(mandatory:Boolean);
    Var cnt,chn:Integer;
      k:Char;
      ch:choicerec;
      tmp:lstr;
      a:Boolean;
    Begin
      If Not hasaccess Then exit;
      If urec.voted[curtopicnum]<>0 Then Begin
        WriteLn('Sorry, can''t vote twice!!');
        exit
      End;
      a:=ulvl>=curtopic.addlevel;
      tmp:='Select choice [?';
      If a Then tmp:=tmp+'/[A]dd';
      tmp:=tmp+']:';
      Repeat
        listchoices;
        writestr(tmp);
        If (Length(Input)=0) Or hungupon Then exit;
        chn:=valu(Input);
        If chn=0 Then Begin
          k:=UpCase(Input[1]);
          If k='?'
          Then listchoices
          Else If k='A'
            Then If a
              Then chn:=addchoice
              Else writestr('You may not add choices to this topic!')
        End
      Until chn<>0;
      If (chn>numchoices) Or (chn<0) Then Begin
        WriteLn('Choice number out of range!');
        exit
      End;
      curtopic.numvoted:=curtopic.numvoted+1;
      writecurtopic;
      Seek(chfile,chn-1);
      Read(chfile,ch);
      ch.numvoted:=ch.numvoted+1;
      Seek(chfile,chn-1);
      Write(chfile,ch);
      urec.voted[curtopicnum]:=chn;
      writeurec;
      WriteLn('Thanks for voting!')
    End;

  Procedure showresults;
    Var cnt,tpos,n:Integer;
      ch:choicerec;
      percent:Real;
    Begin

      If urec.voted[curtopicnum]=0 Then Begin
        WriteLn('Sorry, you must vote first!');
        exit
      End;
      Seek(chfile,0);
      tpos:=1;
      For cnt:=1 To FileSize(chfile) Do Begin
        Read(chfile,ch);
        n:=Length(ch.choice)+2;
        If n>tpos Then tpos:=n
      End;
      writehdr('Voting Booth results');
      Seek(chfile,0);
      For cnt:=1 To numchoices Do If Not break Then Begin
        Read(chfile,ch);
        tab(ch.choice,tpos);
        WriteLn(ch.numvoted)
      End;
      If numusers>0
      Then percent:=100.0*curtopic.numvoted/numusers
      Else percent:=0;
      WriteLn(^M,percent:0:0,'% of ',numusers,' have voted.')
    End;

  Procedure listtopics;
    Var t:topicrec;
      cnt:Integer;
    Begin
      writehdr('Voting Topics');
      Seek(tofile,0);
      For cnt:=1 To numtopics Do
        If Not break Then Begin
          Read(tofile,t);
          WriteLn(cnt:2,'.  ',t.topicname)
        End
    End;

  Procedure addtopic;
    Var t:topicrec;
      ch:choicerec;
      u:userrec;
      cnt,tpn:Integer;
    Begin
      If numtopics>=maxtopics Then
        Begin
          WriteLn('No more room to add a topic!');
          exit
        End;
      tpn:=numtopics+1;
      writestr('Topic name:');
      If Length(Input)=0 Then exit;
      t.topicname:=Input;
      t.numvoted:=0;
      writeurec;
      For cnt:=1 To numusers Do Begin
        Seek(ufile,cnt);
        Read(ufile,u);
        If u.voted[tpn]<>0
        Then
          Begin
            u.voted[tpn]:=0;
            Seek(ufile,cnt);
            Write(ufile,u)
          End
      End;
      readurec;
      writestr(^M'Make all users vote on this topic? *');
      t.mandatory:=yes;
      Writestr(^M'Access Type [G]roup, [L]evel or [B]oth [L] :');
      If Input='' Then Input:='L';
      T.area_type:=UpCase(Input[1]);
      if not (t.area_type in [ 'G' , 'B' , 'L' ] ) then
        t.area_type := 'L' ;
      if t.area_type in [ 'G' , 'B' ] then
        begin
          Writestr('Group file name [None] :');
          If Input='' Then Input:='None';
          t.File_list:=Input;
        end
      else
        t.file_list := 'None' ;
      if t.area_type in [ 'L' , 'B' ] then
        begin
          Writestr('User level to vote on this topic [1] :');
          If Input='' Then Input:='1';
          T.VoteLevel:=valu(Input);
        end
      else
        t.votelevel := maxint ;
      writestr('Allow users to add their own choices? *');
      If yes Then Begin
        writestr('Level required to add choices? *');
        t.addlevel:=valu(Input)
      End Else t.addlevel:=MaxInt;
      Seek(tofile,tpn-1);
      Write(tofile,t);
      opentopic(tpn);
      WriteLn(^M^B'Enter choices, blank line to end.');
      cnt:=1;
      Repeat
        BufLen:=70;
        writestr('Choice number '+strr(cnt)+': &');
        If Length(Input)>0 Then Begin
          cnt:=cnt+1;
          ch.numvoted:=0;
          ch.choice:=Input;
          Write(chfile,ch)
        End
      Until (Length(Input)=0) Or hungupon;
      WriteLn('Topic created!');
      writelog(20,3,strr(tpn)+' ('+t.topicname+')')
    End;

  Procedure maybeaddtopic;
    Begin
      writestr('Create new topic? *');
      If yes Then addtopic
    End;

  Procedure selecttopic;
    Var ch:Integer;
    Begin
      Input:=Copy(Input,2,255);
      If Input='' Then Input:=' ';
      Repeat
        If Length(Input)=0 Then exit;
        ch:=valu(Input);
        If ch>numtopics Then Begin
          ch:=numtopics+1;
          If issysop Then maybeaddtopic;
          If numtopics<>ch Then exit
        End;
        If (ch<1) Or (ch>numtopics) Then Begin
          listtopics;
          If Input='?' Then listtopics;
          writestr('Topic number [?=list]:');
          ch:=0
        End
      Until (ch>0) Or hungupon;
      opentopic(ch)
    End;

  Procedure deltopic;
    Var un,cnt:Integer;
      u:userrec;
      f:File;
      t:topicrec;
      tn:lstr;
    Begin
      tn:=' topic '+strr(curtopicnum)+' ('+curtopic.topicname+')';
      writestr('Delete topic '+tn+'? *');
      If Not yes Then exit;
      writelog(20,1,tn);
      Close(chfile);
      Erase(chfile);
      cnt:=IOResult;
      For cnt:=curtopicnum To numtopics-1 Do Begin
        Assign(f,votefn(cnt+1));
        Rename(f,votefn(cnt));
        un:=IOResult;
        Seek(tofile,cnt);
        Read(tofile,t);
        Seek(tofile,cnt-1);
        Write(tofile,t)
      End;
      Seek(tofile,numtopics-1);
      Truncate(tofile);
      If curtopicnum<numtopics Then Begin
        WriteLn('Adjusting user voting record...');
        writeurec;
        For un:=1 To numusers Do Begin
          Seek(ufile,un);
          Read(ufile,u);
          For cnt:=curtopicnum To numtopics Do
            u.voted[cnt]:=u.voted[cnt+1];
          Seek(ufile,un);
          Write(ufile,u)
        End;
        readurec
      End;
      If numtopics>0 Then opentopic(1)
    End;

  Procedure removechoice;
    Var n:Integer;
      delled,c:choicerec;
      cnt:Integer;
      u:userrec;
    Begin
      n:=valu(Copy(Input,2,255));
      If (n<1) Or (n>numchoices) Then n:=0;
      While n=0 Do Begin
        writestr(^M'Choice to delete [?=list]:');
        n:=valu(Input);
        If n=0
        Then If Input='?'
          Then listchoices
          Else exit
      End;
      If (n<1) Or (n>numchoices) Then exit;
      Seek(chfile,n-1);
      Read(chfile,delled);
      For cnt:=n To numchoices-1 Do Begin
        Seek(chfile,cnt);
        Read(chfile,c);
        Seek(chfile,cnt-1);
        Write(chfile,c)
      End;
      Seek(chfile,numchoices-1);
      Truncate(chfile);
      curtopic.numvoted:=curtopic.numvoted-delled.numvoted;
      writecurtopic;
      Write(^B^M'Choice deleted; updating user voting records...');
      writeurec;
      For cnt:=1 To numusers Do Begin
        Seek(ufile,cnt);
        Read(ufile,u);
        u.voted[curtopicnum]:=0;
        Seek(ufile,cnt);
        Write(ufile,u)
      End;
      readurec;
      WriteLn(^B'Done.')
    End;

  Procedure nexttopic;
    Begin
      If curtopicnum=numtopics
      Then WriteLn('No more topics!')
      Else opentopic(curtopicnum+1)
    End;

  Procedure voteonmandatory;
    Var n:Integer;
      t:topicrec;
    Begin
      For n:=1 To numtopics Do
        If urec.voted[n]=0 Then Begin
          Seek(tofile,n-1);
          Read(tofile,t);
          If t.mandatory Then Begin
            opentopic(n);
            clearbreak;
            nobreak:=True;
            If hasaccess Then
              WriteLn(^M'[Mandatory voting topic]: ',t.topicname,^M);
            {   listchoices;   }
            getvote(True);
            If urec.voted[curtopicnum]<>0 Then Begin
              writestr(^M'See results? *');
              If yes Then showresults
            End
          End
        End
    End;

  Procedure sysopvoting;
    Var q,dum:Integer;
    Begin
      writelog(19,1,curtopic.topicname);
      Repeat
        q:=menu('Voting sysop','VSYSOP','QACDR');
        If hungupon Then exit;
        Case q Of
          2:addtopic;
          3:dum:=addchoice;
          4:deltopic;
          5:removechoice;
        End
      Until (q=1) Or hungupon Or (numtopics=0)
    End;

  Var q:Integer;
  Label exit;
  Begin
    cursection:=votingsysop;
    opentopicdir;
    Repeat
      If numtopics=0 Then Begin
        If getmandatory Then GoTo exit;
        WriteLn('No voting topics right now!');
        If Not issysop
        Then GoTo exit
        Else
          Begin
            writestr('Make topic #1? *');
            If yes
            Then addtopic
            Else GoTo exit
          End
      End
    Until (numtopics>0) Or hungupon;
    If hungupon Then GoTo exit;
    If getmandatory Then Begin
      voteonmandatory;
      GoTo exit
    End;
    opentopic(1);
    writehdr('The Voting Booths');
    WriteLn('Number of voting booths today: ',numtopics);
    Repeat
      Write(^M'Active topic ['^s,curtopicnum,^r']');
      If hasaccess Then WriteLn(': ',^s,curtopic.topicname) Else
        WriteLn('[ CLASSIFIED ]');
      q:=menu('Voting','VOTING','QS_VLR#*H%@');
      If hungupon Then GoTo exit;
      If q<0
      Then
        Begin
          q:=-q;
          If q<=numtopics Then opentopic(q);
          q:=0
        End
      Else
        Case q Of
          2,8:selecttopic;
          3:nexttopic;
          4:getvote(False);
          5:listchoices;
          6:showresults;
          9:help('Voting.hlp');
          10:sysopvoting
        End
    Until (q=1) Or hungupon Or (numtopics=0);
    If numtopics=0 Then WriteLn(^B'No voting topics right now!');
exit:
    Close(tofile);
    Close(chfile)
  End;

Begin
End.

š  SPONSOR ANS           KyBq„  