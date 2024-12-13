tableextension 60015 "Slaes Credit Memo Ext" extends "Sales Cr.Memo Header"
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
