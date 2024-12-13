tableextension 50105 "ClearComp Location Ext." extends Location
{
    fields
    {
        field(50105; "Taxable Entity"; Code[100])
        {
            Caption = 'Taxable Entity';
            DataClassification = ToBeClassified;
        }
        field(50106; "ClearTax Owner Id"; Text[250])
        {
            Caption = 'ClearTax Owner Id';
            DataClassification = ToBeClassified;
        }
    }
}