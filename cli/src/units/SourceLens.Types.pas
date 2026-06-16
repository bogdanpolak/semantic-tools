unit SourceLens.Types;

interface

type
  TReportFormat = (
    rfText,
    rfMarkdown,
    rfJson,
    rfCsv
  );

  TMethodInfo = record
    UnitName: string;
    ClassName: string;
    MethodName: string;
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

