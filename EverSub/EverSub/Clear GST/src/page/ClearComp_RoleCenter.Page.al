pageextension 50116 "ClearComp Role Center" extends "Job Project Manager RC"
{
    layout
    {
        addafter(ApprovalsActivities)
        {
            part(Cues; "ClearComp Cues")
            {
                ApplicationArea = All;
            }
        }
    }
}