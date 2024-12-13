pageextension 60001 "PostedSalesInvoice" extends "Posted Sales Invoice"
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

        addafter("&Invoice")
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
                    SalesInvHeader: Record "Sales Invoice Header";
                    eInvoiceJsonHandler: Codeunit "e-Invoice Json Handler3";
                    eInvoiceManagement: Codeunit "e-Invoice Management";
                    salesinvoiceLine: Record "Sales Invoice Line";
                    eInvoiceNonGSTTransactionErr: Label 'E-Invoicing is not applicable for Non-GST Transactions.';
                begin
                    //  if eInvoiceManagement.IsGSTApplicable(Rec."No.", Database::"Sales Invoice Header")then begin
                    if not (Rec."GST Customer Type" in [Rec."GST Customer Type"::"Unregistered", rec."GST Customer Type"::" "]) then begin


                        SalesInvHeader.Reset();
                        SalesInvHeader.SetRange("No.", Rec."No.");
                        if SalesInvHeader.FindFirst() then begin
                            salesinvoiceLine.Reset();
                            salesinvoiceLine.SetRange("Document No.", Rec."No.");
                            salesinvoiceLine.SetFilter("HSN/SAC Code", '<>%1', '');
                            if not salesinvoiceLine.FindFirst() Then
                                Error(eInvoiceNonGSTTransactionErr);

                            Clear(eInvoiceJsonHandler);
                            SalesInvHeader.Mark(true);
                            eInvoiceJsonHandler.SetSalesInvHeader(SalesInvHeader);
                            eInvoiceJsonHandler.Run();
                        end;
                    end
                    else
                        Error(eInvoiceNonGSTTransactionErr);
                end;
            }
            action("Cancel E-invoice ClearTax")
            {
                ApplicationArea = all;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;

                trigger OnAction()
                var
                    Var_SelectedValue: Integer;
                    SalesInvHeader: Record "Sales Invoice Header";
                    eInvoiceJsonHandler: Codeunit "e-Invoice Json Handler3";
                    eInvoiceManagement: Codeunit "e-Invoice Management";
                    eInvoiceNonGSTTransactionErr: Label 'E-Invoicing is not applicable for Non-GST Transactions.';
                begin
                    Var_SelectedValue := STRMENU('Wrong entry,Duplicate,Data Entry Mistake,Order Canceled,Other', 1, 'Cancel Reason.');
                    IF Var_SelectedValue = 0 THEN EXIT;
                    if eInvoiceManagement.IsGSTApplicable(Rec."No.", Database::"Sales Invoice Header") then begin
                        SalesInvHeader.Reset();
                        SalesInvHeader.SetRange("No.", Rec."No.");
                        if SalesInvHeader.FindFirst() then begin
                            Clear(eInvoiceJsonHandler);
                            SalesInvHeader.Mark(true);
                            eInvoiceJsonHandler.SetSalesInvHeader(SalesInvHeader);
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
                    SalesInvHeader: Record "Sales Invoice Header";
                    eInvoiceJsonHandler: Codeunit "Export E-Invoice Json";
                    eInvoiceManagement: Codeunit "e-Invoice Management";
                    eInvoiceNonGSTTransactionErr: Label 'E-Invoicing is not applicable for Non-GST Transactions.';
                begin
                    if eInvoiceManagement.IsGSTApplicable(Rec."No.", Database::"Sales Invoice Header") then begin
                        SalesInvHeader.Reset();
                        SalesInvHeader.SetRange("No.", Rec."No.");
                        if SalesInvHeader.FindFirst() then begin
                            Clear(eInvoiceJsonHandler);
                            SalesInvHeader.Mark(true);
                            eInvoiceJsonHandler.SetSalesInvHeader(SalesInvHeader);
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
