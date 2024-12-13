pageextension 60037 "Update Sales Invoices" extends "Posted Sales Inv. - Update"
{

    layout
    {
        addafter(General)
        {

            group("Shipment Details")
            {
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
                    ApplicationArea = all;

                }

                field("LR/RR Date"; Rec."LR/RR Date")
                {
                    ApplicationArea = all;

                }

                field("Shipment Method Code"; Rec."Shipment Method Code")
                {
                    ApplicationArea = all;
                }
                field("Mode of Transport"; Rec."Mode of Transport")
                {
                    ApplicationArea = all;
                }

            }
        }
    }
}
