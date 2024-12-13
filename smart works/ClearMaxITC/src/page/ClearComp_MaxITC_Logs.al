page 60115 "ClearComp MaxITC Logs"
{
    PageType = List;
    SourceTable = "ClearComp MaxITC Logs";
    SourceTableView = SORTING("Entry No.")
                      ORDER(Descending);
    Caption = 'Clear MAXITC logs';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = all;
                }
                field("Request Type"; Rec."Request Type")
                {
                    ApplicationArea = all;
                }
                field(Request; Rec.Request)
                {
                    ApplicationArea = all;
                }
                field("Response Code"; Rec."Response Code")
                {
                    ApplicationArea = all;
                }
                field(Response; Rec.Response)
                {
                    ApplicationArea = all;
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = all;
                }
                field(DateTime; Rec.DateTime)
                {
                    ApplicationArea = all;
                }
            }
        }
    }

    actions
    {
        area(creation)
        {
            action("Download Request file")
            {
                Image = ExportFile;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ApplicationArea = all;

                trigger OnAction()
                begin
                    DownloadFile(TRUE);
                end;
            }
            action("Download Response file")
            {
                Image = ExportFile;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ApplicationArea = all;
                trigger OnAction()
                begin
                    DownloadFile(FALSE);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        IF Rec.FINDFIRST THEN;
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

