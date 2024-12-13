pageextension 60019 "CT Posted Sales Inv. - Update" extends "Posted Sales Inv. - Update"

{
    layout
    {
        addafter(General)
        {

            group("Eway/Einvoice")
            {
                Caption = 'Eway/Einvoice';
                field("IRN Disable"; Rec."IRN Disable")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    ToolTip = 'Specifies ExitPoint record.';
                }
                field("Distance (Km)"; Rec."Distance (Km)")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    ToolTip = 'Specifies Distance record.';
                }


                // field("Transport Method"; Rec."Transport Method")

                // {
                //     ApplicationArea = Basic, Suite;
                //     Editable = true;
                //     ToolTip = 'Specifies Distance record.';
                // }
            }
        }
    }
}

