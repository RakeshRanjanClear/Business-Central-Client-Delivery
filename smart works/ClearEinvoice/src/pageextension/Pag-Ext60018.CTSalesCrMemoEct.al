pageextension 60018 "CT Sales Cr Memo Ect" extends "Sales Credit Memo"
{
    layout
    {
        addafter("Posting Date")
        {
            field("IRN Enable"; Rec."IRN Disable")
            {
                ApplicationArea = All;
            }

        }
    }
}
