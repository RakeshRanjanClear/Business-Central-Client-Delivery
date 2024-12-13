pageextension 60016 "Sales Order CT Ext" extends "Sales Order"
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
