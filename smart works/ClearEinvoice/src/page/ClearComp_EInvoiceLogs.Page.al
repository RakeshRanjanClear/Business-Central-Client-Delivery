page 60011 "ClearComp E-Invoice Logs"
{
    PageType = List;
    SourceTable = "ClearComp e-Invoice Entry";
    Caption = 'ClearComp E-Invoice Logs';
    SourceTableView = order(descending);

    layout
    {
        area(Content)
        {
            repeater(General)
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
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                }
                field("Resp. Status Code"; Rec."Resp. Status Code")
                {
                    ApplicationArea = All;
                }
                field("Status Text"; rec."Status Text")
                {
                    ApplicationArea = all;
                    Visible = false;
                }
                field("Acknowledgment No."; Rec."Acknowledgment No.")
                {
                    ApplicationArea = All;
                }
                field("Acknowledgment Date"; Rec."Acknowledgment Date")
                {
                    ApplicationArea = All;
                }
                field(IRN; Rec.IRN)
                {
                    ApplicationArea = All;
                }
                field("Signed Invoice"; Rec."Signed Invoice")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Signed QR Code"; Rec."Signed QR Code")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("IRN Generated Date"; Rec."IRN Generated Date")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Created By"; Rec."Created By")
                {
                    ApplicationArea = All;
                }
                field("Created Date Time"; Rec."Created Date Time")
                {
                    ApplicationArea = All;
                }
                field("QR Code"; Rec."QR Code")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("QR Code Image"; Rec."QR Code Image")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("IRN Status"; Rec."IRN Status")
                {
                    ApplicationArea = All;
                }
                field("Cancel Date"; Rec."Cancel Date")
                {
                    ApplicationArea = All;
                }
                field("Cancellation Error Message"; Rec."Cancellation Error Message")
                {
                    ApplicationArea = All;
                }
                field("Cancelled By"; Rec."Cancelled By")
                {
                    ApplicationArea = All;
                }
                field("Owner ID"; Rec."Owner ID")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("GST No."; Rec."GST No.")
                {
                    ApplicationArea = All;
                }
            }
            grid("Message")
            {
                GridLayout = Columns;
                ShowCaption = false;
                Editable = false;

                group("Response Message")
                {

                    Caption = 'Response message';
                    Editable = false;
                    usercontrol("Response"; "Microsoft.Dynamics.Nav.Client.WebPageViewer")
                    {

                        ApplicationArea = all;
                    }
                }
                group("Request Message")
                {
                    Editable = false;
                    usercontrol("Request"; "Microsoft.Dynamics.Nav.Client.WebPageViewer")
                    {
                        ApplicationArea = all;
                    }
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("Cancel IRN")
            {
                Caption = 'Cancel IRN';
                ApplicationArea = All;

                trigger OnAction()
                var
                    ClearCompEInvoiceMgmt: Codeunit "ClearComp E-Invoice Management";
                    EInvoiceSetup: Record "ClearComp e-Invocie Setup";
                begin
                    if Confirm(CancelIRNTxt, false) then begin
                        Rec.TestField(IRN);
                        Rec.TestField(Status, Rec.Status::Generated);
                        ClearCompEInvoiceMgmt.CancelIRN(Rec.IRN, Rec."GST No.");
                    end;
                end;
            }

        }
    }
    trigger OnAfterGetCurrRecord()
    var
        InstreamL: InStream;
    begin
        Rec.CalcFields("Response JSON", "Request JSON", "Signed QR Code");
        rec."Response JSON".CreateInStream(InstreamL);
        InstreamL.ReadText(ResponseText);
        if CheckifJsonArray(ResponseText) then begin
            ResponseText := ResponseText.Replace('''', '');
            ResponseText := StrSubstNo('document.write(''<pre>'' + JSON.stringify(JSON.parse(''%1''), '''', 2) + ''</pre>'');', ResponseText);
            CurrPage.Response.SetContent('', ResponseText);
        end else
            CurrPage.Response.SetContent('<textarea rows="20" cols="100" style="border:none;">' + ResponseText + '</textarea>');

        Clear(InstreamL);

        Rec."Request JSON".CreateInStream(InstreamL);
        InstreamL.ReadText(RequestText);
        if CheckifJsonArray(RequestText) then begin
            RequestText := RequestText.Replace('''', '');
            RequestText := StrSubstNo('document.write(''<pre>'' + JSON.stringify(JSON.parse(''%1''), '''', 2) + ''</pre>'');', RequestText);
            CurrPage.request.SetContent('', RequestText);
        end else
            CurrPage.Response.SetContent('<textarea rows="20" cols="100" style="border:none;">' + RequestText + '</textarea>');

    end;

    [TryFunction]
    local procedure CheckifJsonArray(inputText: Text)
    var
        Jarray: JsonArray;
    begin
        Jarray.ReadFrom(inputText);
    end;

    trigger OnOpenPage()
    begin
        if rec.FindFirst() then;
    end;

    var
        CancelIRNTxt: Label 'Do you really want to cancel IRN?';

        [InDataSet]
        ResponseText: Text;

        [InDataSet]
        RequestText: Text;


}