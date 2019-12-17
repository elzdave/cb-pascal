program main;

uses
  CRT, SysUtils, CBProcessor;

var
	globalInpChar, mode: char;
  level: integer = 0;
  modeStr: string; 

begin
  clrScr;
  repeat
		TextColor (11);
		writeLn ('Selamat datang !');
    writeLn ('Silakan pilih menu');
    writeLn ('1. Breadth-first Search (BFS)');
    writeLn ('2. Depth-first Search (DFS)');
		write ('Masukkan angka pilihan : ');
		globalInpChar := readkey;
	until ((globalInpChar='1') or (globalInpChar='2'));
  writeLn;
  write ('Masukkan level kedalaman : ');
  readLn (level);
  if (globalInpChar = '1') then begin
    mode := 'B';
    modeStr := 'Breadth-first Search';
  end else if (globalInpChar = '2') then begin
    mode := 'D';
    modeStr := 'Depth-first Search';
  end;
  writeLn ('Anda memilih ' + modeStr + ' dengan ' +IntToStr(level)+ ' level kedalaman pencarian');
  write(strEnterContinue);
  clrScr;
  runGameSimulation (mode, level);
end.