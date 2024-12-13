tableextension 60037 "ClearComp Purch. Cr. Hdr. Ext." extends "Purch. Cr. Memo Hdr."
{
    fields
    {
        field(60036; "LR/RR No."; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'LR/RR No.';
        }
        field(60037; "LR/RR Date"; Date)
        {
            DataClassification = ToBeClassified;
            Caption = 'LR/RR Date';
        }
    }
}