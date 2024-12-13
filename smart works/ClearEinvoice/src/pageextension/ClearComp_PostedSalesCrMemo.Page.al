pageextension 60014 "ClearComp Pstd. Sales Cr. Memo" extends "Posted Sales Credit Memo"
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

        modify("Generate IRN")
        {
            Visible = false;
        }



        addafter("Generate E-Invoice")
        {
            action(GenerateIRN)
            {
                Caption = 'Generate IRN';
                ApplicationArea = All;
                Image = NewDocument;

                trigger OnAction()
                var
                    EInvoiceManagementUnit: Codeunit "ClearComp E-Invoice Management";
                    EInvoiceMgmt: Codeunit "e-Invoice Management";
                begin
                    //if not EInvoicemgmt.IsGSTApplicable(Rec."No.", Database::"Sales Cr.Memo Header") then
                    //  exit;
                    if Rec."GST Customer Type" in [Rec."GST Customer Type"::" ", Rec."GST Customer Type"::Unregistered] then
                        EInvoiceManagementUnit.GenerateB2CQRCodeCredit(rec)
                    else
                        EInvoiceManagementUnit.GenerateIRNSalesCreditmemo(Rec);
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
                    if not EInvoicemgmt.IsGSTApplicable(Rec."No.", Database::"Sales Cr.Memo Header") then
                        exit;
                    if Rec."IRN Hash" > '' then
                        EInvoiceManagementUnit.GetInvoicePDF(Rec."Location GST Reg. No.", Rec."Location Code", Rec."IRN Hash", Rec."No.");
                end;
            }
            */
        }
    }
}