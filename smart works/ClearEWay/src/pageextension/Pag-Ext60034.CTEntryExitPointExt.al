pageextension 60039 "CT-EntryExit Point Ext" extends "Entry/Exit Points"
{
    layout
    {
        addafter(Description)
        {
            field(Address; Rec.Address)
            {
                ApplicationArea = All;
            }
            field("Address 2"; Rec."Address 2")
            {
                ApplicationArea = All;
            }
            field(City; Rec.City)
            {
                ApplicationArea = All;
            }
            field("Post Code"; "Post Code")
            {
                ApplicationArea = all;
            }



            field(state; Rec."State Code")
            {
                ApplicationArea = all;
            }
        }
    }
}
