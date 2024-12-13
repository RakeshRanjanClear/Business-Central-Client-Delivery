tableextension 60034 "ClearComp Sale Cr. Hdr. Ext." extends "Sales Cr.Memo Header"
{
    fields
    {
        field(60032; "LR/RR No."; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'LR/RR No.';
        }
        field(60033; "LR/RR Date"; Date)
        {
            DataClassification = ToBeClassified;
            Caption = 'LR/RR Date';
        }
    }
}