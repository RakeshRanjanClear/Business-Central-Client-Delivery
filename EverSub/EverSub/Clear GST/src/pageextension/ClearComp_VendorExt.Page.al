pageextension 50114 "ClearComp Vendor Card Ext." extends "Vendor Card"
{
    layout
    {
        addafter(GST)
        {
            group("GST Registration No. Details")
            {
                field(Status; Arr[1])
                {
                    ApplicationArea = All;
                    Caption = 'Status';
                    Editable = false;
                }
                field("Legal Name"; Arr[2])
                {
                    ApplicationArea = All;
                    Caption = 'Legal Name';
                    Editable = false;
                    Visible = ArrayVisible;
                }
                field("Trade Name"; Arr[3])
                {
                    ApplicationArea = All;
                    Caption = 'Trade Name';
                    Editable = false;
                    Visible = ArrayVisible;
                }
                field("Addrs"; Arr[4])
                {
                    ApplicationArea = All;
                    Caption = 'Address';
                    Editable = false;
                    Visible = ArrayVisible;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        GSTMgmtUnit: Codeunit "ClearComp GST Management Unit";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        GSTMgmtUnit.GetGSTINDetails(Arr, RecRef, ArrayVisible);
    end;

    var
        ArrayVisible: Boolean;
        Arr: array[5] of Text;
}