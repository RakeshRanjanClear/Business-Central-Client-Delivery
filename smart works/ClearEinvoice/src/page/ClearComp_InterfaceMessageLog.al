page 60012 "ClearComp Interface Msg Log"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "ClearComp Interface Msg Log";
    Caption = 'Interface Message Log';
    SourceTableView = sorting("Entry No.") order(descending);

    layout
    {
        area(Content)
        {
            repeater("Message Log")
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }
                field("Request Type"; Rec."Request Type")
                {
                    ApplicationArea = All;
                }
                field("Response Code"; Rec."Response Code")
                {
                    ApplicationArea = All;
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = All;
                }
                field("Creation DateTime"; Rec."Creation DateTime")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("Download Request File")
            {
                ApplicationArea = All;
                Image = ViewDocumentLine;

                trigger OnAction();
                begin
                    if Rec.Request.HasValue() then
                        DownloadFile(true);
                end;
            }
            action("Download Response File")
            {
                ApplicationArea = All;
                Image = ViewDocumentLine;

                trigger OnAction();
                begin
                    if Rec.Response.HasValue() then
                        DownloadFile(false);
                end;
            }
        }
    }
    trigger OnOpenPage()
    begin
        if Rec.FindFirst() then;
    end;

    local procedure DownloadFile(Request: Boolean)
    var

        FileName: Text;
        FileMgmtUnit: Codeunit "File Management";
        InStrm: InStream;
        OutStrm: OutStream;
        TempBlobUnit: Codeunit "Temp Blob";
    begin
        FileName := Format(CreateGuid());
        FileName := CopyStr(FileName, 2, StrLen(FileName) - 2);
        Rec.CalcFields(Request, Response);
        if Request then begin
            FileName := 'Request' + FileName + '.txt';
            TempBlobUnit.FromRecord(Rec, Rec.FieldNo(Request));
            TempBlobUnit.CreateOutStream(OutStrm);
        end else begin
            FileName := 'Response' + FileName + '.txt';
            TempBlobUnit.FromRecord(Rec, Rec.FieldNo(Response));
            Rec.Response.CreateOutStream(OutStrm);
        end;
        FileMgmtUnit.BLOBExport(TempBlobUnit, FileName, true);
    end;
}