report 60002 "Update Posted SalesInvoice"
{
    ApplicationArea = All;
    Caption = 'Update Posted Sales Invoice';
    UsageCategory = Administration;
    ProcessingOnly = true;

    dataset
    {
        dataitem(SalesInvoiceHeader; "Sales Invoice Header")
        {
            RequestFilterFields = "No.";
            trigger OnAfterGetRecord()
            var
                ClearTaxEInvoice: Codeunit ClearTaxEInvoice;
            begin
                If Confirm(StrSubstNo('Are you sure to change state Code %1 to OT for document No. %2', State, "No."), false) then begin
                    ClearTaxEInvoice.UpdateStateCode("No.");
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
                group(General)
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
