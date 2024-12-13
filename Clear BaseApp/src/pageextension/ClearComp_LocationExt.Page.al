pageextension 50105 "ClearComp Location Card Ext." extends "Location Card"
{
    layout
    {
        addafter(General)
        {
            field("Taxable Entity"; Rec."Taxable Entity")
            {
                ApplicationArea = All;
            }
            field("ClearTax Owner Id"; Rec."ClearTax Owner Id")
            {
                ApplicationArea = All;
            }
        }
    }

}