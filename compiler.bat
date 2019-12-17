@echo off
title Crossing Bridge Game Compiler
color 02
goto Compiler

:Compiler
  set runGame=N
  fpc main.pas
  echo Compiled successfully!
  set /p runGame=Run the game? (Y/[N]) : 
  if /I "%runGame%"=="y" (
    main.exe
    exit /B
  ) else (
    color 1f
    echo Exiting. Press any key to continue . . .
    pause>nul
    exit /B
  )
  