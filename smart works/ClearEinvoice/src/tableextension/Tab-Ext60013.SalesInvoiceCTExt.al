tableextension 60013 "Sales Invoice CT Ext" extends "Sales Invoice Header"
{
    fields
    {
        field(60011; "IRN Disable"; Boolean)
        {
            Caption = 'IRN Disable';
            DataClassification = ToBeClassified;
        }
    }
}
