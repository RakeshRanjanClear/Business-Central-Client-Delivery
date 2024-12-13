tableextension 50110 "ClearComp Customer Ext." extends Customer
{
    fields
    {
        field(50110; "GSTIN Details from ClearTax"; Blob)
        {
            Caption = 'GSTIN Details from ClearTax';
            DataClassification = ToBeClassified;
        }
    }
}