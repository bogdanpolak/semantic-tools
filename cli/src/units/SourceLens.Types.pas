unit SourceLens.Types;

interface

type
  TMethodInfo = record
    UnitName: string;
    ClassName: string;
    MethodName: string;
    IsPublic: boolean;
    BodyLines: integer;
    MaxIndentationLevel: integer;
  end;

  TParseFailure = record
    FileName: string;
    Message: string;
  end;

  TAnalysisResult = record
    MethodInfos: TArray<TMethodInfo>;
    ParseFailures: TArray<TParseFailure>;
  end;

implementation

end.

