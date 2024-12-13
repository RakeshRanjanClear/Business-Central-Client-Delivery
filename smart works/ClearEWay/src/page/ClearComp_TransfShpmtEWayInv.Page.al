page 60035 "ClearComp Transf. Shp E-WayInv"
{
    PageType = List;
    SourceTable = "Transfer Shipment Header";
    Caption = 'ClearComp Transfer Shipment E-Way Invoice';

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                }

                field("Transport Method"; Rec."Transport Method")
                {
                    ApplicationArea = All;
                }
                field("Shipping Agent Code"; Rec."Shipping Agent Code")
                {
                    ApplicationArea = All;
                }

                field("Vehicle No."; Rec."Vehicle No.")
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
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(Generate)
            {
                Caption = 'Generate E-Way Bill';
                Image = CreateDocument;
                ApplicationArea = All;

                trigger OnAction()
                var
                    EWayMngmtUnit: Codeunit "ClearComp E-Way Management";
                begin
                    EWayMngmtUnit.CreateJsonTranferShipment(Rec);
                end;
            }
            action(Print)
            {
                Caption = 'Print E-Way Bill';
                Image = Print;
                ApplicationArea = All;
                Visible = false;
                trigger OnAction()
                var
                    EWayMngmtUnit: Codeunit "ClearComp E-Way Management";
                begin
                    EWayMngmtUnit.GetEWayTransferShipmentforPrint(Rec);
                end;
            }
        }
    }
}