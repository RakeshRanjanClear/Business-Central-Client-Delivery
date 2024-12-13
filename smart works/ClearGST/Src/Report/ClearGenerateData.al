report 60000 "Clear Generate data"
{
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    ProcessingOnly = true;
    Caption = 'Clear GST Generate data';

    requestpage
    {
        layout
        {
            area(Content)
            {
                group("Posting date filter")
                {
                    field("From Date"; FromDate)
                    {
                        ApplicationArea = All;
                    }
                    field("To Date"; ToDate)
                    {
                        ApplicationArea = all;
                    }
                }
                group("Document No. filter")
                {
                    field(DocNo; DocNo)
                    {
                        Caption = 'Document no.';
                        ApplicationArea = all;
                    }
                }
            }
        }
        trigger OnQueryClosePage(CloseAction: Action): Boolean
        begin
            if CloseAction = Action::OK then
                SyncTransactionData();
        end;
    }

    trigger OnPostReport()
    begin
        SyncTransactionData();
    end;

    local procedure SyncTransactionData()
    var
        GeneralFunctions: Codeunit "Clear General functions";
        PurchInv: Codeunit "clear Generate Purch Inv data";
        PurchCrMemo: Codeunit "Clear Generate Purch Cr. memo";
        SalesInv: Codeunit "Clear Generate Sales Inv data";
        SalesCrMemo: Codeunit "Clear Generate Sales Cr. memo";
        TransHdrSynced: Record "Clear Trans Hdr Synced";
        SalesInvHdr: Record "Sales Invoice Header";
        SalesCrMemoHdr: Record "Sales Cr.Memo Header";
        PurchInvHdr: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        GSTSetup: Record "Clear GST Setup";
    begin
        GSTSetup.Get();
        if (FromDate > ToDate) then
            Error(InvalidDateErr);
        if ((FromDate = 0D) and (ToDate = 0D) and (DocNo = '')) then begin
            GeneralFunctions.UpdateStagingData();
            if GuiAllowed then
                exit;
        end;

        if DocNo <> '' then begin
            SalesInvHdr.SetRange("No.", DocNo);
            SalesCrMemoHdr.SetRange("No.", DocNo);
            PurchInvHdr.SetRange("No.", DocNo);
            PurchCrMemoHdr.SetRange("No.", DocNo);
        end else begin
            if ((FromDate = 0D) and (ToDate = 0D)) then begin
                FromDate := GSTSetup."Integration start date";
                ToDate := Today;
            end;
            SalesInvHdr.SetRange("Posting Date", FromDate, ToDate);
            SalesCrMemoHdr.SetRange("Posting Date", FromDate, ToDate);
            PurchInvHdr.SetRange("Posting Date", FromDate, ToDate);
            PurchCrMemoHdr.SetRange("Posting Date", FromDate, ToDate);
        end;
        if SalesInvHdr.FindSet() then begin
            repeat
                if (not TransHdrSynced.Get(Enum::"Clear Transaction type"::sale, Enum::"Clear Document Type"::Invoice, SalesInvHdr."No.")) then
                    SalesInv.ReadDetails(SalesInvHdr);
            until SalesInvHdr.Next() = 0;
        end;

        if SalesCrMemoHdr.FindSet() then begin
            repeat
                if (not TransHdrSynced.Get(Enum::"Clear Transaction type"::sale, Enum::"Clear Document Type"::Credit, SalesCrMemoHdr."No.")) then
                    SalesCrMemo.ReadDetails(SalesCrMemoHdr);
            until SalesCrMemoHdr.Next() = 0;
        end;

        if PurchInvHdr.FindSet() then begin
            repeat
                if (not TransHdrSynced.Get(Enum::"Clear Transaction type"::Purchase, Enum::"Clear Document Type"::Invoice, PurchInvHdr."No.")) then
                    PurchInv.ReadDetails(PurchInvHdr);
            until PurchInvHdr.Next() = 0;
        end;

        if PurchCrMemoHdr.FindSet() then begin
            repeat
                if (not TransHdrSynced.Get(Enum::"Clear Transaction type"::Purchase, Enum::"Clear Document Type"::Debit, PurchCrMemoHdr."No.")) then
                    PurchCrMemo.ReadDetails(PurchCrMemoHdr);
            until PurchCrMemoHdr.Next() = 0;
        end;
        if not GuiAllowed then begin
            GSTSetup."Integration start date" := ToDate;
            GSTSetup.Modify();
        end;
    end;

    var
        FromDate: Date;
        ToDate: Date;
        InvalidDateErr: Label 'From date cannot be greater then To date';
        DocNo: Code[20];
}