page 60030 "ClearComp E-Way Bill Requests"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "ClearComp e-Invoice Entry";
    Caption = 'ClearComp E-Way Bill Requests';

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = All;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                }

                field(IRN; rec.IRN)
                {
                    ApplicationArea = all;
                    Editable = false;
                }
                field("E-Way Bill No."; Rec."E-Way Bill No.")
                {
                    ApplicationArea = All;
                }

                field("E-Way Bill Date"; Rec."E-Way Bill Date")
                {
                    ApplicationArea = All;
                }
                field("E-Way Bill Validity"; Rec."E-Way Bill Validity")
                {
                    ApplicationArea = All;
                }
                field("E-Way Generated"; Rec."E-Way Generated")
                {
                    ApplicationArea = All;
                }
                field("E-Way Canceled"; Rec."E-Way Canceled")
                {
                    ApplicationArea = All;
                }
                field("Reason of Cancel"; Rec."Reason of Cancel")
                {
                    ApplicationArea = All;
                }
                field("Transportation Distance"; Rec."Transportation Distance")
                {
                    ApplicationArea = All;
                }
                field("E-Way Canceled Date"; Rec."E-Way Canceled Date")
                {
                    ApplicationArea = All;
                }
                field("Status Text"; Rec."Status Text")
                {
                    ApplicationArea = All;
                }
                field("User Id"; Rec."User Id")
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
            action(Generate)
            {
                Caption = 'Generate E-Way Bill';
                Image = CreateDocument;
                ApplicationArea = All;
                Visible = false;

                trigger OnAction()
                var
                    EWayMngmtUnit: Codeunit "ClearComp E-Way Management";
                    salesInvoiceHdr: Record "Sales Invoice Header";
                begin
                    if salesInvoiceHdr.get(Rec."Document No.") then
                        EWayMngmtUnit.CreateJsonSalesInvoice(salesInvoiceHdr);
                end;
            }
            action(UpdateVehNo)
            {
                Caption = 'Update Vehicle No.';
                Image = UpdateXML;
                ApplicationArea = All;
                Visible = false;
                trigger OnAction()
                var
                    EWayMngmtUnit: Codeunit "ClearComp E-Way Management";
                begin
                    EWayMngmtUnit.UpdateVehicleNo(Rec);
                end;
            }
            action(Cancel)
            {
                Caption = 'Cancel E-Way';
                Image = Cancel;
                ApplicationArea = All;

                trigger OnAction()
                var
                    EWayMngmtUnit: Codeunit "ClearComp E-Way Management";
                begin
                    EWayMngmtUnit.CancelEWay(Rec);
                end;
            }
            action(DownlaodReq)
            {
                Caption = 'Download Request File';
                Image = Download;
                ApplicationArea = All;

                trigger OnAction()
                begin
                    if Rec."Request JSON".HasValue() then
                        DownloadFile(true);
                end;
            }
            action(DownloadResp)
            {
                Caption = 'Download Response File';
                Image = Download;
                ApplicationArea = All;

                trigger OnAction()
                begin
                    if Rec."Response JSON".HasValue() then
                        DownloadFile(false);
                end;
            }
        }
    }
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
        Rec.CalcFields("Request JSON", "Response JSON");
        if Request then begin
            FileName := 'Request' + FileName + '.txt';
            TempBlobUnit.FromRecord(Rec, Rec.FieldNo("Request JSON"));
            TempBlobUnit.CreateOutStream(OutStrm);
        end else begin
            FileName := 'Response' + FileName + '.txt';
            TempBlobUnit.FromRecord(Rec, Rec.FieldNo("Response JSON"));
            Rec."Response JSON".CreateOutStream(OutStrm);
        end;
        FileMgmtUnit.BLOBExport(TempBlobUnit, FileName, true);
    end;
}