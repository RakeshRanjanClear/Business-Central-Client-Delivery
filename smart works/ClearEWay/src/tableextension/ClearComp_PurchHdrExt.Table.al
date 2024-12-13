tableextension 60033 "ClearComp Purchase Header Ext" extends "Purch. Inv. Header"
{
    fields
    {
        field(60034; "LR/RR No."; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'LR/RR No.';
        }
        field(60035; "LR/RR Date"; Date)
        {
            DataClassification = ToBeClassified;
            Caption = 'LR/RR Date';
        }
    }
}