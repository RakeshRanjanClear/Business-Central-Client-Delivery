pageextension 60038 "CT GST Registration No." extends "GST Registration Nos."
{
    layout
    {
        addafter(code)
        {
            field("Einv Demo GST REgistration No."; Rec."Einv Demo GST REgistration No.")
            {
                ApplicationArea = All;
            }

        }
    }
}
