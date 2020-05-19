program REC32;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  Forms,
  Classes,
  ZConnection,
  ZDataSet,
  ConsoleB in 'ConsoleB.pas';



var
  Path    : String;
  SR      : TSearchRec;
  DirList : TStrings;
  i       : Integer;
  Arq     : TextFile;
  S       : String;
  winY    : Integer;
  CNAE    : String;
  dbCon   : TZConnection;
  dbQry   : TZQuery;
  Last    : String;
  DeleteDB: String;
  Progress: Integer;
  PrgsStep: Integer;
  ExprtCSV: String;
  CSVFile : TextFile;
  ClrMail : String;
begin
   If Not DirectoryExists(ExtractFilePath(Application.ExeName)+'DADOS/') Then
   Begin
    MkDir(ExtractFilePath(Application.ExeName)+'DADOS/');
    WriteLn('Falta arquivos de dados, baixe no site da receita na pasta "'+ExtractFilePath(Application.ExeName)+'DADOS\"');
    WriteLn('Site para download: http://bit.ly/arquivos-cnpj');
    ReadLn(ClrMail);
    Exit;
   End;
   ClrScr;
   If FileExists(ExtractFilePath(Application.ExeName)+'DB.db') Then
   Begin
     Write('Deseja apagar a base de dados atual? [s/N]:');
     GoToXY(45,1);
     ReadLn(DeleteDB);
     If Lowercase(DeleteDB) = 's' Then
     Begin
      DeleteFile(ExtractFilePath(Application.ExeName)+'DB.db');
     End;
   End;
   ClrScr;
   GoToXY(1,1);
   Write('Digite o codigo CNAE para listar:');
   GoToXY(35,1);
   ReadLn(CNAE);
   //--
   dbCon:= TZConnection.Create(Nil);
   dbCon.Protocol:='sqlite-3';
   dbCon.Database:=ExtractFilePath(Application.ExeName)+'DB.db';
   dbCon.Connect;
   dbQry:= TZQuery.Create(Nil);
   dbQry.Connection:=dbCon;
   //--
   If CNAE <> EmptyStr Then
   Begin
      winY:=1;
      Path:= ExtractFilePath(Application.ExeName)+'DADOS\';
      ClrScr;
      GoToXY(1,winY);Inc(winY);
      Write('Buscando arquivos de dados da RFB em'+#32+Path);
      DirList:=TStringList.Create;
      If FindFirst(Path + '*.*.*.*', faArchive, SR) = 0 Then
      Begin
		    Repeat
			    DirList.Add(Path+SR.Name); //Fill the list
		    Until FindNext(SR) <> 0;
  	    FindClose(SR);
      End;
      //--
      If Lowercase(DeleteDB) = 's' Then
      Begin
        dbQry.SQL.Text:='CREATE TABLE [empresas] ([CNPJ] VARCHAR(15)  PRIMARY KEY, [RAZAOSOCIAL] VARCHAR(150), [NOMEFANTASIA] VARCHAR(55), [TELEFONE1] VARCHAR(12), [TELEFONE2] VARCHAR(12), [EMAIL] VARCHAR(115))';
        dbQry.ExecSQL;
      End;
      //--
      If DirList.Count = 0 Then
      Begin
        MkDir(ExtractFilePath(Application.ExeName)+'DADOS/');
        WriteLn('Falta arquivos de dados, baixe no site da receita na pasta "'+ExtractFilePath(Application.ExeName)+'DADOS\"');
        WriteLn('Site para download: http://bit.ly/arquivos-cnpj');
        ReadLn(ClrMail);
        Exit;
      End;
      //--
      For i:=0 To DirList.Count-1 Do
      Begin
          GoToXY(1,winY);Inc(winY);
          Write('Processando arquivo'+#32+DirList[i]);
          GoToXY(1,winY);
          Write('['+StringOfChar(#32,78)+']');
          Try
            AssignFile(Arq,DirList[i]);
            Reset(Arq);
            Progress:=0;
            PrgsStep:=0;
            While (not SeekEof(Arq)) Do
            Begin
              ReadLn(Arq, S);
              //--
              If (PrgsStep = 500) Then
              Begin
                Inc(Progress);
                PrgsStep:=0;
              End;
              If Progress=0 Then
              Begin
                GoToXY(1,winY);
                Write('['+StringOfChar(#32,Progress)+']');
              End
              Else
              Begin
                GoToXY(1,winY);
                Write('['+Copy(StringOfChar(#35,Progress),0,80)+Copy(StringOfChar(#32,80),0,(80-Progress))+']');
                If Progress = 80 Then
                Progress:=0;
              End;
              Inc(PrgsStep);
              //--
              If Copy(S,1,1) = '1' Then
              Begin
                If Trim(Copy(S,376,7)) = CNAE Then
                Begin
                  dbQry.SQL.Text:='REPLACE INTO [empresas] '+
                                  '('+
                                  '   [CNPJ],'+
                                  '   [RAZAOSOCIAL],'+
                                  '   [NOMEFANTASIA],'+
                                  '   [TELEFONE1],'+
                                  '   [TELEFONE2],'+
                                  '   [EMAIL]'+
                                  ') VALUES ('+
                                  AnsiQuotedStr(Trim(Copy(S,4,14)),#34)+','+
                                  AnsiQuotedStr(Trim(Copy(S,19,150)),#34)+','+
                                  AnsiQuotedStr(Trim(Copy(S,169,55)),#34)+','+
                                  AnsiQuotedStr(Trim(Copy(S,739,12)),#34)+','+
                                  AnsiQuotedStr(Trim(Copy(S,751,12)),#34)+','+
                                  AnsiQuotedStr(Trim(Copy(S,775,115)),#34)+
                                  ')';
                  dbQry.ExecSQL;
                End
                Else
                Begin
                  Last:=S;
                End;
              End;
              If Copy(S,1,1) = '6' Then
              Begin
                If Trim(Copy(S,18,7)) = CNAE Then
                Begin
                  If Trim(Copy(S,4,14)) = Trim(Copy(Last,4,14)) Then
                  Begin
                    dbQry.SQL.Text:='REPLACE INTO [empresas] '+
                                    '('+
                                    '   [CNPJ],'+
                                    '   [RAZAOSOCIAL],'+
                                    '   [NOMEFANTASIA],'+
                                    '   [TELEFONE1],'+
                                    '   [TELEFONE2],'+
                                    '   [EMAIL]'+
                                    ') VALUES ('+
                                    AnsiQuotedStr(Trim(Copy(Last,4,14)),#34)+','+
                                    AnsiQuotedStr(Trim(Copy(Last,19,150)),#34)+','+
                                    AnsiQuotedStr(Trim(Copy(Last,169,55)),#34)+','+
                                    AnsiQuotedStr(Trim(Copy(Last,739,12)),#34)+','+
                                    AnsiQuotedStr(Trim(Copy(Last,751,12)),#34)+','+
                                    AnsiQuotedStr(Trim(Copy(Last,775,115)),#34)+
                                    ')';
                    dbQry.ExecSQL;
                  End;
                End;
              End;
            End;
          Finally
            CloseFile(Arq);
          End;
      End;
   End; //end CNAE <> EmptyStr

   ClrScr;
   GoToXY(1,1);
   Write('Script finalizado!');
   GoToXY(1,2);
   Write('Deseja exportar os resultados para CSV agora? [s/N]');
   GoToXY(53,2);
   ReadLn(ExprtCSV);
   GotoXY(1,3);
   Write('Deseja limpar e-mails nulos e da contabilidade *cont* ? [s/N]');
   GotoXY(63,3);
   ReadLn(ClrMail);
   If Lowercase(ExprtCSV) = 's' Then
   Begin
    dbQry.SQL.Text:='SELECT * FROM [empresas]';
    dbQry.Open;
    AssignFile(CSVFile,ExtractFilePath(Application.ExeName)+'RESULTADO.csv');
    Rewrite(CSVFile);
    dbQry.First;
    While Not dbQry.Eof Do
    Begin
      If (
            (Lowercase(ClrMail)<>'s')
            Or (
              (Lowercase(ClrMail)='s')
              And (
                (Pos('cont',LowerCase(dbQry.FieldByName('EMAIL').AsString)) <= 0)
                And
                (Trim(dbQry.FieldByName('EMAIL').AsString) <> EmptyStr)
              )
            )
      ) Then
      Begin
        WriteLn(CSVFile,
          AnsiQuotedStr(dbQry.FieldByName('CNPJ').AsString,#34)+#44+
          AnsiQuotedStr(dbQry.FieldByName('RAZAOSOCIAL').AsString,#34)+#44+
          AnsiQuotedStr(dbQry.FieldByName('NOMEFANTASIA').AsString,#34)+#44+
          AnsiQuotedStr(dbQry.FieldByName('TELEFONE1').AsString,#34)+#44+
          AnsiQuotedStr(dbQry.FieldByName('TELEFONE2').AsString,#34)+#44+
          AnsiQuotedStr(Lowercase(dbQry.FieldByName('EMAIL').AsString),#34)
        );
      End;
      dbQry.Next;
    End;
    CloseFile(CSVFile);
    dbQry.Close;
   End;

   dbQry.Close;
   dbQry.Free;
   dbCon.Disconnect;
   dbCon.Free;

end.
