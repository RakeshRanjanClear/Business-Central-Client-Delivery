pageextension 50202 "ClearComp Purch. Cr. Memo Ext " extends "Purchase Credit Memo"
{
    layout
    {
        addafter("Pay-to Contact")
        {
            field("LR/RR No."; Rec."LR/RR No.")
            {
                ApplicationArea = All;
            }
            field("LR/RR Date"; Rec."LR/RR Date")
            {
                ApplicationArea = All;
            }
        }
    }
}