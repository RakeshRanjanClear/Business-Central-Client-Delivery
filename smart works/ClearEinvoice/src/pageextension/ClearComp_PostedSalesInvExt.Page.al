pageextension 60011 "ClearComp Posted Sales Inv." extends "Posted Sales Invoice"
{
    layout
    {
        addafter("Posting Date")
        {
            field("IRN Enable"; "IRN Disable")
            {
                ApplicationArea = all;
            }
        }
    }
    actions
    {
        modify("Cancel E-Invoice")
        {
            Visible = false;
        }
        modify("Generate IRN")
        {
            Visible = false;
        }
        modify("Generate QR Code")
        {
            Visible = false;
        }
        addafter("Generate E-Invoice")
        {
            action(GenerateIRN)
            {
                ApplicationArea = All;
                Caption = 'Generate IRN';
                Image = Invoice;

                trigger OnAction()
                var
                    EInvoiceManagementUnit: Codeunit "ClearComp E-Invoice Management";
                    EInvoiceMgmt: Codeunit "e-Invoice Management";
                begin
                    if not EInvoicemgmt.IsGSTApplicable(Rec."No.", Database::"Sales Invoice Header") then
                        exit;
                    if Rec."GST Customer Type" in [Rec."GST Customer Type"::" ", Rec."GST Customer Type"::Unregistered] then
                        EInvoiceManagementUnit.GenerateB2CQRCodeSales(rec)
                    else
                        EInvoiceManagementUnit.GenerateIRNSalesInvoice(Rec);
                end;
            }
            action(CancelIRN)
            {
                ApplicationArea = All;
                Caption = 'Cancel IRN';
                Image = CancelApprovalRequest;

                trigger OnAction()
                var
                    EInvoiceLog: Record "ClearComp e-Invoice Entry";
                    Location: Record Location;
                    EInvoiceManagementUnit: Codeunit "ClearComp E-Invoice Management";
                    EInvoicemgmt: Codeunit "e-Invoice Management";
                begin
                    // GST Management CU is not available in BC what to do?
                    //if GSTManagementUnit.IsGSTApplicable(Structure) then begin
                    if not EInvoicemgmt.IsGSTApplicable(Rec."No.", Database::"Sales Invoice Header") then
                        exit;
                    EInvoiceLog.Reset();
                    EInvoiceLog.SetRange(IRN, Rec."IRN Hash");
                    if EInvoiceLog.FindFirst() and (EInvoiceLog.Status = EInvoiceLog.Status::Cancelled) then
                        Error(IRNCanErr);
                    Location.GET(Rec."Location Code");
                    EInvoiceManagementUnit.CancelIRN(Rec."IRN Hash", Location."GST Registration No.");
                    //Error(eInvoiceErr);
                end;
            }
            /*
            action(PrintPDF)
            {
                Caption = 'Print Invoice PDF';
                ApplicationArea = All;
                Image = Print;

                trigger OnAction()
                var
                    EInvoiceManagementUnit: Codeunit "ClearComp E-Invoice Management";
                    EInvoicemgmt: Codeunit "e-Invoice Management";
                begin
                    //GST Management CU is not available to validate isGSTApplicable
                    if not EInvoicemgmt.IsGSTApplicable(Rec."No.", Database::"Sales Invoice Header") then
                        exit;
                    if Rec."IRN Hash" > '' then
                        EInvoiceManagementUnit.GetInvoicePDF(Rec."Location GST Reg. No.", Rec."Location Code", Rec."IRN Hash", Rec."No.");
                end;
            }
            */
            /*
            action(GenerateQR)
            {
                ApplicationArea = All;
                Caption = 'Generate QR Code B2C';
                Image = BarCode;

                trigger OnAction()
                var
                    EInvoiceManagementUnit: Codeunit "ClearComp E-Invoice Management";
                begin
                    EInvoiceManagementUnit.GenerateQRCodeB2C(Rec);
                end;
            }
            */
        }
    }
    trigger OnAfterGetCurrRecord()
    begin
        Rec.CalcFields("QR Code");

    end;

    var
        eInvoiceErr: Label 'E-Invoicing is not applicable for Non-GST Transactions';
        IRNCanErr: Label 'IRN Already Cancelled';
}