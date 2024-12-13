pageextension 60000 "Bussiness manager EXT" extends "Business Manager Role Center"
{
    actions
    {
        addbefore(Action39)
        {
            group(ClearTax)
            {
                Caption = 'Clear Tax';
                action(Anchor)
                {
                    Visible = false;
                    ApplicationArea = all;
                }
            }
        }
    }
}