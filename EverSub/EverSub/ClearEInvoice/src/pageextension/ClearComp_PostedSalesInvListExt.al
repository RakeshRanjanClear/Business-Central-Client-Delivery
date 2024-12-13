pageextension 50103 "Posted Sales Inv. List Ext" extends "Posted Sales Invoices"
{
    layout
    {
        addafter("No.")
        {
            field(IRN; rec."IRN Hash")
            {
                ApplicationArea = all;
            }
            field("QR Code"; Rec."QR Code")
            {
                ApplicationArea = all;
            }
        }
    }
    trigger OnAfterGetCurrRecord()
    begin
        Rec.CalcFields("QR Code");
    end;
}