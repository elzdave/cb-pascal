{
  *************************************
  *    Crossing Bridge game engine    *
  *-----------------------------------*
  * Version     : 1.0                 *
  * Coder       : David Eleazar       *
  * Prog. Lang  : Pascal              *
  * Compiler    : Free Pascal 3.0.4   *
  * Date Added  : December 15th, 2019 *
  * Last Modif. : December 16th, 2019 *
  *************************************

  Definition :
  1.  People/person is the entity/ies who want to cross
      the river using designated bridge 
  2.  Source is the starting place a.k.a person initial
      standing point
  3.  Destination is the target place where the people
      want to cross with the bridge
  3.  Lamp is the lighting helper to cross the bridge
      in the night. The lamp has its own time-to-blown,
      so after several minutes, it will blew, render
      player to lose the game

  Changelog : 
  1.0 : Initial release
}

unit CBProcessor;

interface
  uses
    CRT, SysUtils;

  type
    TPerson = record
      timeCost: integer;
      isCrossed: boolean;
    end;
    TState = record
      data: array [0..4] of TPerson;
      lampPosition: char;   //lamp position in [S]ource or [D]estination
      timeLeft: integer;
    end;
    TVertex = record  //record untuk menyimpan data tiap simpul
      selfPosition, parentPosition, depthLevel: integer; //memuat posisi array parent, dirinya sendiri dan tingkatan turunan
      content: TState;  //isi state
      childPosition: array of integer;  //menyimpan posisi anak dalam generated list
      isVisited: boolean;  //penanda jika sudah dikunjungi
    end;
  
  var  //globar vars
  	errEnterBack: String = 'Tekan ENTER untuk kembali . . ';
	  strEnterContinue: String = 'Tekan ENTER untuk melanjutkan . . .';
    strAnyKeyExit: String = 'Tekan sembarang tombol untuk keluar . . .';
    generatedList: array of TVertex;  //array untuk menyimpan anakan hasil generate
    intInitState,intFinalState: TState;  //initial state dan final state
    solutionFound: boolean;  //jika solusi sudah ditemukan, maka bernilai TRUE
    solutionList: array of TState;  //menyimpan solusi pergerakan dari initial state dan final state, jika solusi ditemukan
    
  //begin of procedure's prototypes
  procedure initialState;
  procedure copyContent (var origin,target: TState);
  procedure viewState (state: TState);
  function isIdenticalState(x, y : TState): boolean;
  procedure stepTracker (var x : array of TState);
  procedure runGameSimulation(method: char; level:integer);
  procedure crossTheBridge(a,b: integer; var state: TState);
  procedure nodeGenerator (var node : TVertex);
  procedure cbBFS (numOfLevel : integer);
  procedure cbDFS (var node : TVertex; numOfLevel : integer);
  //end of procedure's protoypes

implementation
  procedure initialState;
  var
    tc: array [0..4] of integer = (1,3,6,8,12); //set person timing here
    lampRunningTime: integer = 30;              //set max running time
    i: integer;
  begin
    for i:=Low(tc) to High(tc) do begin
      intInitState.data[i].timeCost := tc[i];
      intInitState.data[i].isCrossed := FALSE;
      intFinalState.data[i].timeCost := tc[i];
      intFinalState.data[i].isCrossed := TRUE;
    end;
    intInitState.lampPosition := 'S';   //lamp at the source
    intInitState.timeLeft := lampRunningTime;
    intFinalState.lampPosition := 'D';  //lamp at the destination
    intFinalState.timeLeft := 0;        //for init only
  end;

  procedure copyContent (var origin,target: TState);
  var
    i: integer;
  begin
    for i:=Low(origin.data) to High(origin.data) do begin
      target.data[i].timeCost := origin.data[i].timeCost;
      target.data[i].isCrossed := origin.data[i].isCrossed;
    end;
    target.lampPosition := origin.lampPosition;
    target.timeLeft := origin.timeLeft;
  end;

  procedure viewState (state: TState);
  var
    i: integer;
    str: string = '';
    peopleTime: string = '';
  begin
    for i:=Low(state.data) to High(state.data) do begin
      peopleTime += IntToStr(state.data[i].timeCost);
      peopleTime += '  ';
      if state.data[i].isCrossed then str += '1  ' else str += '0  ';
    end;
    str += ': ';
    str += state.lampPosition;
    str += '    : ';
    str += IntToStr(state.timeLeft);
    //then print the state
    writeLn ('================================');
    writeLn ('=     People     : Lamp : Rem. =');
    writeLn ('= ' + peopleTime + '             =');
    writeLn ('= ' + str + '   =');
    writeLn ('================================');
  end;

  function isIdenticalState(x, y : TState): boolean;
  var
    i: integer;
  begin
    isIdenticalState := TRUE;
    for i:=Low(x.data) to High(x.data) do begin
      if (x.data[i].isCrossed <> y.data[i].isCrossed) then begin
        isIdenticalState:=FALSE;
        break;
      end;
    end;
    if (x.lampPosition <> y.lampPosition) then isIdenticalState:=FALSE;
  end;

  {
    prosedur stepTracker berguna untuk menarik garis dari posisi final state di array hasil generate hingga ke initial state dari program
  }
  procedure stepTracker (var x : array of TState);
  var
    i,locParent : integer;
  begin
    locParent:=generatedList[High(generatedList)].selfPosition;  //kopikan posisi diri sendiri terlebih dahulu
    for i:=High(x) downto Low(x) do begin
      copyContent(generatedList[locParent].content,x[i]);
      locParent:=generatedList[locParent].parentPosition;  //kemudian untuk tiap loop, ganti posisi parent
    end;
  end;

  procedure runGameSimulation(method: char; level:integer);   //method = [B]FS and [D]FS
  begin
    writeLn ('Initial state');
    viewState(intInitState);
    readln;
    SetLength(generatedList,1);  //siapkan tempat pertama untuk root parent
    copyContent(intInitState, generatedList[0].content);  //posisi 0 sebagai root parent
    //set root parent attributes
    generatedList[0].parentPosition := 0;
    generatedList[0].selfPosition := 0;
    generatedList[0].depthLevel := 0;
    generatedList[0].isVisited := FALSE;
    if (method='B') then begin
      cbBFS(level);
    end else begin
      cbDFS(generatedList[0], level);
    end;
    if not solutionFound then begin
      TextColor (12);
      writeln ('Mohon maaf, solusi tidak ditemukan');
      writeln (strAnyKeyExit);
      repeat
      until keypressed;  //menunggu hingga sebuah tombol ditekan
    end;
  end;

  procedure crossTheBridge(a,b: integer; var state: TState);
  var
    oldLampPosition: char;
    timeDecreaseFactor: integer = 0;
  begin
    oldLampPosition := state.lampPosition;
    //toggle lamp position
    if (oldLampPosition = 'S') then state.lampPosition := 'D'
      else state.lampPosition := 'S';
    //then toggle the person position
    if a >= 0 then state.data[a].isCrossed := not state.data[a].isCrossed;
    if b >= 0 then state.data[b].isCrossed := not state.data[b].isCrossed;
    //check time remaining by measuring maximum time from two people
    if ((a >= 0) and (b >= 0)) then begin
      if state.data[a].timeCost > state.data[b].timeCost then timeDecreaseFactor := state.data[a].timeCost
        else timeDecreaseFactor := state.data[b].timeCost;
    end else if ((a >= 0) and (b < 0)) then timeDecreaseFactor := state.data[a].timeCost
    else if ((a < 0) and (b >= 0)) then timeDecreaseFactor := state.data[b].timeCost;
    state.timeLeft -= timeDecreaseFactor;
  end;

  {
    prosedur nodeGenerator berfungsi untuk membangkitan child dari suatu node masukan,
    dan menyimpannya dalam variabel global bertipe array dinamis

    Defined rules in array
    0-4 : person #1..#5 can move
  }
  procedure nodeGenerator (var node : TVertex);
  var
    currentSide : char;
    allowedRule : array [0..4] of boolean;
    i,j,k,tmpNodeLevel : integer;
    tmpStateStorage : TState;
    isIdentic,reachedFinal : boolean; //cek kesamaan isi matriks dan finalisasi
  begin
    //init
    tmpNodeLevel := 0;
    isIdentic := FALSE;
    reachedFinal := FALSE;

    clrscr;  //bersihkan layar
    writeln ('Parent position : ',node.selfPosition);    
    currentSide := node.content.lampPosition;

    //begin ruler init
    for i:=0 to 4 do begin
      // if the person doesn't match current lamp position, then it cannot cross the river
      if ((node.content.data[i].isCrossed and (currentSide = 'S')) xor (not node.content.data[i].isCrossed and (currentSide = 'D')))
        then allowedRule[i] := FALSE else allowedRule[i] := TRUE;
    end;
    //end ruler init
    
    tmpNodeLevel := node.depthLevel;
    inc(tmpNodeLevel);
    for i:=Low(allowedRule) to High(allowedRule) do begin
      for j:=0 to i do begin
        copyContent(node.content, tmpStateStorage);   //kopi konten node ke temp
        if (i <> j) then begin
          if (allowedRule[i] and allowedRule[j]) then crossTheBridge(i, j, tmpStateStorage);    //move two people to the other side
        end else begin
          if (allowedRule[i]) then crossTheBridge(i, -1, tmpStateStorage);   //move only one people to the other side
        end;
        for k:=Low(generatedList) to High(generatedList) do begin
          isIdentic := isIdenticalState(tmpStateStorage, generatedList[k].content);
          if isIdentic then break;  //jika terdeteksi ada yang identik, hentikan looping
        end;
        if (not isIdentic and (allowedRule[i] or allowedRule[j]) and (tmpStateStorage.timeLeft >= 0)) then begin  //jika tidak ada yang identik, kopikan hasil generate ke generatedList
          SetLength(generatedList, length(generatedList)+1);  //siapkan tempat untuk generated matrix
          SetLength(node.childPosition, length(node.childPosition)+1);  //siapkan tempat untuk posisi child pada array
          node.childPosition[length(node.childPosition)-1] := length(generatedList)-1;  //masukkan posisi child pada array childPosition
          copyContent(tmpStateStorage,generatedList[length(generatedList)-1].content); //kopikan isi ke generated list
          generatedList[length(generatedList)-1].parentPosition := node.selfPosition; //posisi parent pada array
          generatedList[length(generatedList)-1].selfPosition := length(generatedList)-1;  //posisi node yang baru digenerate berada pada posisi terakhir array yang baru diset
          generatedList[length(generatedList)-1].depthLevel := tmpNodeLevel;  //kedalaman level = level node aktif + 1
          generatedList[length(generatedList)-1].isVisited := FALSE;  //set status node yang belum digenerate dengan FALSE
          reachedFinal := isIdenticalState(generatedList[length(generatedList)-1].content, intFinalState);
          if reachedFinal then begin  //jika sudah ketemu final state
            SetLength(solutionList, generatedList[length(generatedList)-1].depthLevel+1);  //menyiapkan array untuk menyimpan posisi langkah
            stepTracker(solutionList);  //panggil prosedur tracker 
            TextColor(14);
            clrscr;
            writeln ('Solusi ditemukan!');
            solutionFound:=TRUE;
          end;
          writeLn ('i : ' + IntToStr(i) + ', j : ' + IntToStr(j));
          writeln ('Current node position : ',node.childPosition[high(node.childPosition)]);
          writeln ('Child level : ',tmpNodeLevel);
          viewState(generatedList[length(generatedList)-1].content);   //tampilkan node yang baru digenerate
          if solutionFound then begin
            writeln ('Posisi final state berada pada array ke-',High(generatedList));
            writeln ('Langkah yang diperlukan dari initial state adalah ',generatedList[High(generatedList)].depthLevel,' langkah');
            writeln ('Langkah langkahnya adalah : ');
            writeln;
            TextColor (10);
            for k:=Low(solutionList) to High(solutionList) do begin
              if k=Low(solutionList) then writeln ('Initial State')
                else if k=High(solutionList) then writeln ('Final State')
                  else writeln ('Langkah ke-',k);
              viewState(solutionList[k]);
              readln;
            end;
            writeln ('Permainan selesai');
            writeln (strAnyKeyExit);
            repeat
            until keypressed;  //menunggu hingga sebuah tombol ditekan
            halt;  //keluar dari program
          end;
          writeln;
        end;
      end;
    end;
    node.isVisited := TRUE;  //tandai node yang sudah digenerate sebagai TRUE
    //delay(500);  //just for debugging
    //readln;  //just for debugging
  end;

  procedure cbBFS (numOfLevel : integer);
  var
    bfsPosition : integer;
  begin
    bfsPosition := 0;  //posisi awal BFS pada root parent
    while ((generatedList[bfsPosition].isVisited=FALSE) and (solutionFound=FALSE)) do begin
      if generatedList[bfsPosition].depthLevel<numOfLevel then begin
        nodeGenerator(generatedList[bfsPosition]);  //generate hasil
        inc(bfsPosition);  //generator akan bergerak secara mendatar
      end else exit;
    end;
  end;

  procedure cbDFS (var node : TVertex; numOfLevel : integer);
  var
    i : integer;
  begin
    if (node.isVisited=FALSE) then begin
      if node.depthLevel<numOfLevel then begin
        nodeGenerator(node);
        for i:=low(node.childPosition) to high(node.childPosition) do //generator akan melakukan pembangkitan anakan terlebih dahulu
          cbDFS(generatedList[node.childPosition[i]],numOfLevel);
      end;
    end else exit;
  end;

initialization
  initialState;
end.