pageextension 50200 "" extends "ClearComp E-Invoice Setup"
{
    layout
    {
        addafter(General)
        {
            group("E-Way")
            {
                field("URL E-Way Creation"; Rec."URL E-Way Creation")
                {
                    ApplicationArea = All;
                }
                field("URL E-Way Cancelation"; Rec."URL E-Way Cancelation")
                {
                    ApplicationArea = All;
                }
                field("URL E-Way Update"; Rec."URL E-Way Update")
                {
                    ApplicationArea = All;
                }
                field("Download Eway Pdf URL"; Rec."Download Eway Pdf URL")
                {
                    ApplicationArea = All;
                }
                field("Get Ewaybill Detail URL"; Rec."Get Ewaybill Detail URL")
                {
                    ApplicationArea = All;
                }
                field("URL Eway By IRN"; Rec."URL Eway By IRN")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}