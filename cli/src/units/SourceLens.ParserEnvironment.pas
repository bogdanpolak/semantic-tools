unit SourceLens.ParserEnvironment;

interface

uses
  System.Classes,
  DelphiAST,
  DelphiAST.Classes;

type
  ISourceFileProvider = interface
    ['{A41FF9F3-3FE0-4B59-BE61-C88B7F2A8466}']
    function OpenRead(const AFileName: string): TStream;
  end;

  IDelphiParserEnvironment = interface
    ['{3C8E5FEC-880A-4A13-8B9A-0C08D62FEE71}']
    function ParseFile(
      const AFileName: string;
      const ASourceFileProvider: ISourceFileProvider
      ): TSyntaxNode;
  end;

function CreateFileSourceFileProvider: ISourceFileProvider;
function CreateDelphiParserEnvironment: IDelphiParserEnvironment;

implementation

uses
  System.IOUtils,
  System.SysUtils,
  SimpleParser.Lexer,
  SimpleParser.Lexer.Types;

type
  TFileSourceFileProvider = class(TInterfacedObject, ISourceFileProvider)
  public
    function OpenRead(const AFileName: string): TStream;
  end;

  TDelphiAstIncludeHandler = class(TInterfacedObject, IIncludeHandler)
  private
    FSourceFileProvider: ISourceFileProvider;
    function LoadContent(const AFileName: string): string;
    function ResolveIncludeFileName(
      const AParentFileName: string;
      const AIncludeName: string
      ): string;
  public
    constructor Create(const ASourceFileProvider: ISourceFileProvider);
    function GetIncludeFileContent(
      const ParentFileName: string;
      const IncludeName: string;
      out Content: string;
      out FileName: string
      ): Boolean;
  end;

  TDelphiParserEnvironment = class(TInterfacedObject, IDelphiParserEnvironment)
  public
    function ParseFile(
      const AFileName: string;
      const ASourceFileProvider: ISourceFileProvider
      ): TSyntaxNode;
  end;

function CreateFileSourceFileProvider: ISourceFileProvider;
begin
  Result := TFileSourceFileProvider.Create;
end;

function CreateDelphiParserEnvironment: IDelphiParserEnvironment;
begin
  Result := TDelphiParserEnvironment.Create;
end;

{ TFileSourceFileProvider }

function TFileSourceFileProvider.OpenRead(const AFileName: string): TStream;
begin
  Result := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
end;

{ TDelphiAstIncludeHandler }

constructor TDelphiAstIncludeHandler.Create(
  const ASourceFileProvider: ISourceFileProvider);
begin
  inherited Create;
  FSourceFileProvider := ASourceFileProvider;
end;

function TDelphiAstIncludeHandler.GetIncludeFileContent(
  const ParentFileName: string;
  const IncludeName: string;
  out Content: string;
  out FileName: string
  ): Boolean;
begin
  FileName := ResolveIncludeFileName(ParentFileName, IncludeName);
  Content := LoadContent(FileName);
  Result := True;
end;

function TDelphiAstIncludeHandler.LoadContent(const AFileName: string): string;
var
  Stream: TStream;
  StringStream: TStringStream;
begin
  Stream := FSourceFileProvider.OpenRead(AFileName);
  try
    Stream.Position := 0;
    StringStream := TStringStream.Create;
    try
      StringStream.LoadFromStream(Stream);
      Result := StringStream.DataString;
    finally
      StringStream.Free;
    end;
  finally
    Stream.Free;
  end;
end;

function TDelphiAstIncludeHandler.ResolveIncludeFileName(
  const AParentFileName: string;
  const AIncludeName: string
  ): string;
var
  ParentFolder: string;
begin
  if TPath.IsPathRooted(AIncludeName) then
    Exit(TPath.GetFullPath(AIncludeName));

  ParentFolder := TPath.GetDirectoryName(AParentFileName);
  if ParentFolder = '' then
    Exit(TPath.GetFullPath(AIncludeName));

  Result := TPath.GetFullPath(TPath.Combine(ParentFolder, AIncludeName));
end;

{ TDelphiParserEnvironment }

function TDelphiParserEnvironment.ParseFile(
  const AFileName: string;
  const ASourceFileProvider: ISourceFileProvider
  ): TSyntaxNode;
var
  Builder: TPasSyntaxTreeBuilder;
  Stream: TStream;
begin
  Stream := ASourceFileProvider.OpenRead(AFileName);
  try
    Stream.Position := 0;

    Builder := TPasSyntaxTreeBuilder.Create;
    try
      Builder.InitDefinesDefinedByCompiler;
      Builder.IncludeHandler := TDelphiAstIncludeHandler.Create(ASourceFileProvider);
      Builder.Lexer.Lexer.Buffer.FileName := TPath.GetFullPath(AFileName);
      Result := Builder.Run(Stream);
    finally
      Builder.Free;
    end;
  finally
    Stream.Free;
  end;
end;

end.