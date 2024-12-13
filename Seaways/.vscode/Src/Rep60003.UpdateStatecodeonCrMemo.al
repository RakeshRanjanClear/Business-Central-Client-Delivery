report 60003 "Update State code on Cr. Memo"
{
    Caption = 'Update State code on Cr. Memo';
    UsageCategory = Administration;
    ProcessingOnly = true;
    ApplicationArea = All;
    dataset
    {
        dataitem(SalesCrMemoHeader; "Sales Cr.Memo Header")
        {
            RequestFilterFields = "No.";
            trigger OnAfterGetRecord()
            var
                ClearTaxEInvoice: Codeunit ClearTaxEInvoice;
            begin
                If Confirm(StrSubstNo('Are you sure to change state Code %1 to OT for document No. %2', State, "No."), false) then begin
                    ClearTaxEInvoice.UpdateStateCodecrmemo("No.");
                    Message('Change of state is successful, Please create einvoice')
                end;


            end;
        }
    }
    requestpage
    {
        layout
        {
            area(content)
            {
                group(GroupName)
                {
                }
            }
        }
        actions
        {
            area(processing)
            {
            }
        }
    }
}
