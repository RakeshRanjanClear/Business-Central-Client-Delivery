pageextension 60002 "PostedSalesCrMemo" extends "Posted Sales Credit Memo"
{
    layout
    {
        addafter("Shipping and Billing")
        {
            // field("Cancel Reasons"; Rec."Cancel Reasons")
            // {
            //     ApplicationArea = all;
            // }
        }
        modify("Cancel Reason")
        {
            Visible = false;
        }
    }
    actions
    {
        modify("Generate E-Invoice")
        {
            Visible = false;
        }
        modify("Generate IRN")
        {
            Visible = false;
        }

        addafter("&Cr. Memo")
        {
            action("Generate E-invoice ClearTax")
            {
                ApplicationArea = all;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;

                trigger OnAction()
                var
                    SalesCrMemoHeader: Record "Sales Cr.Memo Header";
                    eInvoiceJsonHandler: Codeunit "e-Invoice Json Handler3";
                    eInvoiceManagement: Codeunit "e-Invoice Management";
                    SalesCredMemoLine: record "Sales Cr.Memo Line";
                    eInvoiceNonGSTTransactionErr: Label 'E-Invoicing is not applicable for Non-GST Transactions.';
                begin
                    if eInvoiceManagement.IsGSTApplicable(Rec."No.", Database::"Sales Cr.Memo Header") then begin
                        SalesCrMemoHeader.Reset();
                        SalesCrMemoHeader.SetRange("No.", Rec."No.");
                        if SalesCrMemoHeader.FindFirst() then begin
                            SalesCredMemoLine.Reset();
                            SalesCredMemoLine.SetRange("Document No.", Rec."No.");
                            SalesCredMemoLine.SetFilter("HSN/SAC Code", '<>%1', '');
                            if not SalesCredMemoLine.FindFirst() Then
                                Error(eInvoiceNonGSTTransactionErr);
                            Clear(eInvoiceJsonHandler);
                            SalesCrMemoHeader.Mark(true);
                            eInvoiceJsonHandler.SetCrMemoHeader(SalesCrMemoHeader);
                            eInvoiceJsonHandler.Run();
                        end;
                    end
                    else
                        Error(eInvoiceNonGSTTransactionErr);
                end;
            }
            action("Cancel Einvoice ClearTax")
            {
                ApplicationArea = all;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;

                trigger OnAction()
                var
                    SalesCrMemoHeader: Record "Sales Cr.Memo Header";
                    eInvoiceJsonHandler: Codeunit "e-Invoice Json Handler3";
                    eInvoiceManagement: Codeunit "e-Invoice Management";
                    eInvoiceNonGSTTransactionErr: Label 'E-Invoicing is not applicable for Non-GST Transactions.';
                    Var_SelectedValue: Integer;
                begin
                    Var_SelectedValue := STRMENU('Wrong entry,Duplicate,Data Entry Mistake,Order Canceled,Other', 1, 'Cancel Reason.');
                    IF Var_SelectedValue = 0 THEN EXIT;
                    if eInvoiceManagement.IsGSTApplicable(Rec."No.", Database::"Sales Cr.Memo Header") then begin
                        SalesCrMemoHeader.Reset();
                        SalesCrMemoHeader.SetRange("No.", Rec."No.");
                        if SalesCrMemoHeader.FindFirst() then begin
                            Clear(eInvoiceJsonHandler);
                            SalesCrMemoHeader.Mark(true);
                            eInvoiceJsonHandler.SetCrMemoHeader(SalesCrMemoHeader);
                            eInvoiceJsonHandler.GenerateCanceledInvoice(Var_SelectedValue);
                        end;
                    end
                    else
                        Error(eInvoiceNonGSTTransactionErr);
                end;
            }
            action("Export E-Invoice Clear Tax")
            {
                ApplicationArea = Basic, Suite;
                Image = ExportFile;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Specifies the function through which Json file will be generated.';

                trigger OnAction()
                var
                    SalesCrMemoHeader: Record "Sales Cr.Memo Header";
                    eInvoiceJsonHandler: Codeunit "Export e-Invoice Json";
                    eInvoiceManagement: Codeunit "e-Invoice Management";
                    eInvoiceNonGSTTransactionErr: Label 'E-Invoicing is not applicable for Non-GST Transactions.';
                begin
                    if eInvoiceManagement.IsGSTApplicable(Rec."No.", Database::"Sales Cr.Memo Header") then begin
                        SalesCrMemoHeader.Reset();
                        SalesCrMemoHeader.SetRange("No.", Rec."No.");
                        if SalesCrMemoHeader.FindFirst() then begin
                            Clear(eInvoiceJsonHandler);
                            SalesCrMemoHeader.Mark(true);
                            eInvoiceJsonHandler.SetCrMemoHeader(SalesCrMemoHeader);
                            eInvoiceJsonHandler.Run();
                        end;
                    end
                    else
                        Error(eInvoiceNonGSTTransactionErr);
                end;
            }
        }
    }
}
