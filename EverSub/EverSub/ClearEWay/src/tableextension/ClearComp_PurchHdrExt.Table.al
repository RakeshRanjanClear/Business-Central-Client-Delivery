tableextension 50205 "ClearComp Purchase Header Ext" extends "Purchase Header"
{
    fields
    {
        field(50001; "LR/RR No."; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'LR/RR No.';
        }
        field(50002; "LR/RR Date"; Date)
        {
            DataClassification = ToBeClassified;
            Caption = 'LR/RR Date';
        }
    }
}