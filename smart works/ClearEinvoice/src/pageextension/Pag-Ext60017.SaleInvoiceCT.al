pageextension 60017 "Sale Invoice CT" extends "Sales Invoice"
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
