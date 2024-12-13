report 50110 "ClearComp Trans. Data To CT"
{
    UsageCategory = Administration;
    ApplicationArea = All;
    Caption = 'Transfer Data To ClearTax';
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
        GSTManagementUnit: Codeunit "ClearComp GST Management Unit";
    begin
        if FromDate > ToDate then
            Error(InvalidDateFilter)
        else
            GSTManagementUnit.SetPostingDateFilter(FromDate, ToDate, DocNo);
        GSTManagementUnit.Run();
    end;

    var
        DocNo: Text;
        FromDate: Date;
        ToDate: Date;
        InvalidDateFilter: Label 'ToDate cannot be less than FromDate';
}