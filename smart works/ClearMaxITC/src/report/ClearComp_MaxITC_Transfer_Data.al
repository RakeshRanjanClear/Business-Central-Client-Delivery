report 60115 "ClearComp MaxITC Transfer Data"
{
    // version MaxITC

    Caption = 'Clear MaxITC send data';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = all;

    requestpage
    {

        layout
        {
            area(content)
            {
                field("From Date"; FromDate)
                {
                    ApplicationArea = all;
                }
                field("To Date"; ToDate)
                {
                    ApplicationArea = all;
                }
            }
        }

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        begin
            IF CloseAction = ACTION::OK THEN
                SyncTransactionData;
        end;
    }

    var
        FromDate: Date;
        ToDate: Date;
        InValidFilterErr: Label '"To Date" cannot be less than "From Date".';

    local procedure SyncTransactionData()
    var
        ClearCompMaxITCMgmt: Codeunit "ClearComp MaxITC Management";
    begin
        IF FromDate > ToDate THEN
            ERROR(InValidFilterErr)
        ELSE
            ClearCompMaxITCMgmt.SetPostingdateFilter(FromDate, ToDate);

        ClearCompMaxITCMgmt.RUN;
    end;
}

