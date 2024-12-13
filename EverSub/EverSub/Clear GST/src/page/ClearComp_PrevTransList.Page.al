page 50114 "ClearComp Prev. Trans. List"
{
    PageType = List;
    SourceTable = "ClearComp GST Trans. Header";
    Caption = 'Preview Transaction Data List';
    CardPageId = "ClearComp Prev. Trans. Data";

    layout
    {
        area(Content)
        {
            group("Posting Date Filter")
            {
                Visible = false;
                field(FromDate; FromDate)
                {
                    ApplicationArea = All;
                }
                field(ToDate; ToDate)
                {
                    ApplicationArea = All;
                }
            }
            group("Transactions Type")
            {
                Visible = false;
                field(Transaction; Transaction)
                {
                    ApplicationArea = All;
                }
            }
            repeater(GroupName)
            {
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                }
                field(Selected; Rec.Selected)
                {
                    ApplicationArea = All;
                }
                field("Transaction Type"; Rec."Transaction Type")
                {
                    ApplicationArea = All;
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = All;
                }
                field("Is Bill of Supply"; Rec."Is Bill of Supply")
                {
                    ApplicationArea = All;
                }
                field("Is Advance"; Rec."Is Advance")
                {
                    ApplicationArea = All;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = All;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                }
                field("Place of Supply"; Rec."Place of Supply")
                {
                    ApplicationArea = All;
                }
                field("Seller Name"; Rec."Seller Name")
                {
                    ApplicationArea = All;
                }
                field("Buyer Name"; Rec."Buyer Name")
                {
                    ApplicationArea = All;
                }
                field("Matched Status"; Rec."Matched Status")
                {
                    ApplicationArea = All;
                }
                field("Match Status Description"; Rec."Match Status Description")
                {
                    ApplicationArea = All;
                }
                field("Matching at PAN/GSTIN"; Rec."Matching at PAN/GSTIN")
                {
                    ApplicationArea = All;
                }
                field("MisMatched Fields"; Rec."MisMatched Fields")
                {
                    ApplicationArea = All;
                }
                field("MisMatched Fields count"; Rec."MisMatched Fields count")
                {
                    ApplicationArea = All;
                }
            }
            grid(Message)
            {
                GridLayout = Columns;
                Editable = false;
                ShowCaption = false;
                Visible = MessageG;
                group("Request Message")
                {
                    Visible = MessageG;
                    usercontrol("Request"; "Microsoft.Dynamics.Nav.Client.WebPageViewer")
                    {
                        ApplicationArea = all;
                    }
                }
                group("Response Message")
                {
                    Visible = MessageG;
                    usercontrol("Response"; "Microsoft.Dynamics.Nav.Client.WebPageViewer")
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
            action("Send Data")
            {
                ApplicationArea = All;
                Image = SendTo;
                Visible = SendData;

                trigger OnAction()
                var
                    GSTMgmtUnit: Codeunit "ClearComp GST Management Unit";
                begin
                    GSTMgmtUnit.SetManualProcess();
                    GSTMgmtUnit.SendData(Rec);
                end;
            }
            action("Delete Trans. Data In ClearTax")
            {
                ApplicationArea = All;
                Image = DeleteRow;
                Visible = FilterVisible;

                trigger OnAction()
                var
                    GSTMgmtUnit: Codeunit "ClearComp GST Management Unit";
                    GSTTransHeader: Record "ClearComp GST Trans. Header";
                begin
                    GSTTransHeader.SetRange(Selected, TRUE);
                    if GSTTransHeader.IsEmpty() then
                        Error(NotSelectedErr);
                    GSTTransHeader.SetRange("Document Type", GSTTransHeader."Document Type"::Invoice);
                    GSTTransHeader.SetRange("Is Bill of Supply", FALSE);
                    GSTTransHeader.SetRange("Is Advance", false);
                    if GSTTransHeader.FindSet() then
                        repeat
                            GSTMgmtUnit.DeleteSelectedInvoices(GSTTransHeader."Document No.");
                        until GSTTransHeader.Next() = 0
                    else
                        Error(SelectionErr);
                end;
            }
            action("Import Reconcilation Result")
            {
                ApplicationArea = All;
                Image = Import;
                Visible = FilterVisible;

                trigger OnAction()
                var
                    GSTMgmtUnit: Codeunit "ClearComp GST Management Unit";
                begin
                    GSTMgmtUnit.ImportDataFromExcel();
                end;
            }
            action("Export Data To Excel")
            {
                ApplicationArea = All;
                Image = Export;
                Visible = SendData;

                trigger OnAction()
                var
                    GSTMgmtUnit: Codeunit "ClearComp GST Management Unit";
                begin
                    GSTMgmtUnit.ExportDataToExcel(Rec);
                end;
            }
            action("Return Filed")
            {
                ApplicationArea = All;
                Image = ReturnOrder;
                Visible = FilterVisible;

                trigger OnAction()
                var
                    GSTTransHeader: Record "ClearComp GST Trans. Header";
                begin
                    GSTTransHeader.SetRange(Selected, TRUE);
                    GSTTransHeader.SetRange(Status, GSTTransHeader.Status::Synced);
                    GSTTransHeader.ModifyAll("Return Filed", TRUE);
                end;
            }
            action(Unselect)
            {
                ApplicationArea = all;
                Image = Select;
                Caption = 'Unselect All';

                trigger OnAction()
                begin
                    Rec.ModifyAll(Selected, false);
                end;
            }
        }
    }
    trigger OnAfterGetCurrRecord()
    var
        instreamL: InStream;

    begin
        Rec.CalcFields(Response, Request);
        rec.Response.CreateInStream(InstreamL);
        InstreamL.ReadText(ResponseText);
        if CheckifJsonObject(ResponseText) then begin
            ResponseText := ResponseText.Replace('''', '');
            ResponseText := StrSubstNo('document.write(''<pre>'' + JSON.stringify(JSON.parse(''%1''), '''', 2) + ''</pre>'');', ResponseText);
            CurrPage.Response.SetContent('', ResponseText);
        end else
            CurrPage.Response.SetContent('<textarea rows="20" cols="100" style="border:none;">' + ResponseText + '</textarea>');

        Clear(InstreamL);

        Rec.Request.CreateInStream(InstreamL);
        InstreamL.ReadText(RequestText);
        if CheckifJsonObject(RequestText) then begin
            RequestText := RequestText.Replace('''', '');
            RequestText := StrSubstNo('document.write(''<pre>'' + JSON.stringify(JSON.parse(''%1''), '''', 2) + ''</pre>'');', RequestText);
            CurrPage.request.SetContent('', RequestText);
        end else
            CurrPage.Response.SetContent('<textarea rows="20" cols="100" style="border:none;">' + RequestText + '</textarea>');

    end;

    [TryFunction]
    local procedure CheckifJsonObject(inputText: Text)
    var
        Jarray: JsonObject;
    begin
        Jarray.ReadFrom(inputText);
    end;

    trigger OnClosePage()
    begin
        Rec.ModifyAll(Selected, false);
    end;

    procedure SetSendDataVisible()
    begin
        SendData := true;
    end;

    procedure SetMessagevisible()
    begin
        MessageG := true;
    end;

    procedure SetDeleteTransactionVisible()
    begin
        FilterVisible := true;
    end;

    var
        FromDate: Date;
        ToDate: Date;
        FilterVisible: Boolean;
        SendData: Boolean;
        Transaction: Option ,SALE,PURCHASE;
        SelectionErr: Label 'Only Transactions which are synced and Document Type "Invoice" and is  not "Bill of supply" can be Selected.';
        SyncedErr: Label 'Synced documents cannot be selected.';
        NotSelectedErr: Label 'Please Select a transaction to delete.';
        [InDataSet]
        MessageG: Boolean;
        [InDataSet]
        ResponseText: Text;
        [InDataSet]
        RequestText: Text;
}