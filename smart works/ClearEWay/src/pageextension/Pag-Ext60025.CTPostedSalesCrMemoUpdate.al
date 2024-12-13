pageextension 60035 "CT Posted Sales Cr.Memo Update" extends "Pstd. Sales Cr. Memo - Update"
{
    layout
    {

        addafter(General)
        {

            group("Eway/Einvoice")
            {
                Caption = 'Eway/Einvoice';
                field("Exit Point"; Rec."Exit Point")
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



                field("Vehicle No."; Rec."Vehicle No.")
                {
                    ApplicationArea = All;
                }
                field("Vehicle Type"; Rec."Vehicle Type")
                {
                    ApplicationArea = All;
                }
                field("LR/RR No."; Rec."LR/RR No.")
                {
                    ApplicationArea = All;
                }
                field("LR/RR Date"; Rec."LR/RR Date")
                {
                    ApplicationArea = All;
                }

                field("Shipment Method Code"; Rec."Shipment Method Code")
                {
                    ApplicationArea = All;
                }


            }

        }
    }
}

