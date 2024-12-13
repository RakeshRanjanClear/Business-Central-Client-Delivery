pageextension 50100 "ClearComp Pstd. Sales Cr. Memo" extends "Posted Sales Credit Memo"
{
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
                    if not EInvoicemgmt.IsGSTApplicable(Rec."No.", Database::"Sales Cr.Memo Header") then
                        exit;
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