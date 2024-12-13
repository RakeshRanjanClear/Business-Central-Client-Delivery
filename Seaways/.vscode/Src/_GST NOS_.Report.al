report 70000 "GST NOS"
{
    ProcessingOnly = true;
    ApplicationArea = all;
    UsageCategory = Administration;

    dataset
    {
    }
    requestpage
    {
        layout
        {
        }
        actions
        {
        }
    }
    labels
    {
    }
    trigger OnPreReport()begin
        GSTRegistrationNos.INIT;
        GSTRegistrationNos.Code:='29AAFCD5862R000';
        GSTRegistrationNos."State Code":='KA';
        GSTRegistrationNos.INSERT;
    end;
    var GSTRegistrationNos: Record "GST Registration Nos.";
}
