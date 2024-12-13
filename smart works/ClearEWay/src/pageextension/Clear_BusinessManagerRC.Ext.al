pageextension 60030 "Clear Bussiness Manager Eway" extends "Business Manager Role Center"
{
    actions
    {
        addafter(Anchor)
        {
            group("E-Way")
            {
                Caption = 'E-Way';
                action("Sales Invoice E-Way")
                {
                    Caption = 'Sales Invoice E-Way';
                    ApplicationArea = all;
                    RunObject = page "ClearComp Sales E-Way Invoice";
                    RunPageMode = View;
                    ToolTip = 'Generate E-Way sales Invoice';
                }
                action("Sales Cr. Memo E-Way")
                {
                    Caption = 'Sales Cr. Memo E-Way';
                    ApplicationArea = all;
                    RunObject = page "ClearComp Sales E-Way CR.memo";
                    RunPageMode = View;
                    ToolTip = 'Generate E-Way sales Cr. Memo';
                }
                action("Purchase Return E-Way")
                {
                    Caption = 'Purch. return E-Way';
                    ApplicationArea = all;
                    RunObject = page "ClearComp Purch. Ret E-WayInv";
                    RunPageMode = View;
                    ToolTip = 'Generate E-Way Purch. return';
                }
                action("Transfer Shipment E-Way")
                {
                    Caption = 'Transfer Shipment E-Way';
                    ApplicationArea = all;
                    RunObject = page "ClearComp Transf. Shp E-WayInv";
                    RunPageMode = View;
                    ToolTip = 'Generate E-Way Transfer shipment';
                }

                action("EWay bill requests")
                {
                    Caption = 'E-Way bill requests';
                    ApplicationArea = all;
                    RunObject = page "ClearComp E-Way Bill Requests";
                    RunPageMode = View;
                    ToolTip = 'View E-Way bill requests';
                }

            }
        }
    }
}