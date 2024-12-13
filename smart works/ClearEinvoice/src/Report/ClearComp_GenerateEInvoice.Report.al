report 60011 "ClearComp Generate IRN"
{
    UsageCategory = Administration;
    ApplicationArea = All;
    Caption = 'Generate E-Invoice';
    UseRequestPage = true;
    ProcessingOnly = true;
    requestpage
    {
        layout
        {
            area(Content)
            {
                group("Filter on Posting Date")
                {
                    field(FromDate; FromDate)
                    {
                        ApplicationArea = All;
                        trigger OnValidate()
                        begin
                            Clear(DocNo);
                        end;
                    }
                    field(ToDate; ToDate)
                    {
                        ApplicationArea = All;
                        trigger OnValidate()
                        begin
                            Clear(DocNo);
                        end;
                    }
                }
                group("Filter on Document Number")
                {
                    field(DocNo; DocNo)
                    {
                        ApplicationArea = all;
                        trigger OnValidate()
                        begin
                            Clear(FromDate);
                            Clear(ToDate);
                        end;
                    }
                }
            }
        }
        trigger OnQueryClosePage(CloseAction: Action): Boolean
        begin
            if CloseAction = Action::OK then
                SyncTransactionData()
        end;
    }
    local procedure SyncTransactionData()
    var
        EInvMgmt: Codeunit "ClearComp E-Invoice Management";
        SalesInvHdr: Record "Sales Invoice Header";
        SalesCrHdr: Record "Sales Cr.Memo Header";
        EInvoiceMgmt: Codeunit "e-Invoice Management";
    begin
        if ((FromDate = 0D) and (ToDate <> 0D)) or ((ToDate = 0D) and (FromDate <> 0D)) then
            Error(NoFilter);
        if FromDate > ToDate then
            Error(InvalidDateFilter)
        else begin
            if (FromDate <> 0D) and (ToDate <> 0D) then begin
                SalesInvHdr.SetRange("Posting Date", FromDate, ToDate);
                SalesCrHdr.SetRange("Posting Date", FromDate, ToDate);
            end else
                if DocNo <> '' then begin
                    SalesInvHdr.SetRange("No.", DocNo);
                    SalesCrHdr.SetRange("No.", DocNo);
                end;
            if SalesInvHdr.FindSet() then
                repeat
                    if EInvoiceMgmt.IsGSTApplicable(SalesInvHdr."No.", Database::"Sales Invoice Header") then
                        EInvMgmt.GenerateIRNSalesInvoice(SalesInvHdr);
                until SalesInvHdr.Next() = 0;
            if SalesCrHdr.FindSet() then
                repeat
                    if EInvoiceMgmt.IsGSTApplicable(SalesCrHdr."No.", Database::"Sales Cr.Memo Header") then
                        EInvMgmt.GenerateIRNSalesCreditmemo(SalesCrHdr);
                until SalesCrHdr.Next() = 0;
        end;


    end;

    var
        DocNo: Text;
        FromDate: Date;
        ToDate: Date;
        InvalidDateFilter: Label 'ToDate cannot be less than FromDate';
        NoFilter: Label 'please provide the proper Filter range or clear the filters';
}