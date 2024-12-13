tableextension 50111 "ClearComp Vendor Ext." extends Vendor
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