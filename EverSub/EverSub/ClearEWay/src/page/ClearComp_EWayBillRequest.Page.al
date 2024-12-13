page 50200 "ClearComp E-Way Bill Requests"
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
            repeater(GroupName)
            {
                field("API Type"; Rec."API Type")
                {
                    ApplicationArea = All;
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = All;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                }
                field("E-Way Bill No."; Rec."E-Way Bill No.")
                {
                    ApplicationArea = All;
                }
                field("Document Date"; Rec."Document Date")
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
                field("New Vehicle No."; Rec."New Vehicle No.")
                {
                    ApplicationArea = All;
                }
                field("Vehicle No. Update Remark"; Rec."Vehicle No. Update Remark")
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
                field("E-Way URL"; Rec."E-Way URL")
                {
                    ApplicationArea = All;
                }
                field("User Id"; Rec."User Id")
                {
                    ApplicationArea = All;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                }
                field("Status Text"; Rec."Status Text")
                {
                    ApplicationArea = All;
                }
                field("Transaction Type"; Rec."Transaction Type")
                {
                    ApplicationArea = All;
                }
                field("E-WAY Response Text"; Rec."E-WAY Response Text")
                {
                    ApplicationArea = All;
                }
                field("E-Way Canceled Date"; Rec."E-Way Canceled Date")
                {
                    ApplicationArea = All;
                }
                field("Request JSON"; Rec."Request JSON")
                {
                    ApplicationArea = All;
                }
                field("Response JSON"; Rec."Response JSON")
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
            action(UpdateVehNo)
            {
                Caption = 'Update Vehicle No.';
                Image = UpdateXML;
                ApplicationArea = All;

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
    begin
        FileName := Format(CreateGuid());
        FileName := CopyStr(FileName, 2, StrLen(FileName) - 2);
        Rec.CalcFields("Request JSON", "Response JSON");
        if Request then begin
            FileName := 'Request' + FileName + '.txt';
            Rec."Request JSON".Export(TemporaryPath + FileName);
        end else begin
            FileName := 'Response' + FileName + '.txt';
            Rec."Response JSON".Export(TemporaryPath + FileName);
        end;
        FileMgmtUnit.DownloadTempFile('TEMP\' + FileName);
        Erase(TemporaryPath + FileName);
    end;
}