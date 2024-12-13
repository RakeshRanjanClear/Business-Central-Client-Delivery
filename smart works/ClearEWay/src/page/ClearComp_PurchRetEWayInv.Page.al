page 60032 "ClearComp Purch. Ret E-WayInv"
{
    PageType = List;
    SourceTable = "Purch. Cr. Memo Hdr.";
    ModifyAllowed = true;
    Editable = true;
    Permissions = tabledata "Purch. Cr. Memo Hdr." = rm;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
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
                field("LR/RR No."; Rec."LR/RR No.")
                {
                    ApplicationArea = All;
                }
                field("LR/RR Date"; Rec."LR/RR Date")
                {
                    ApplicationArea = All;
                }
                field("Vehicle No."; Rec."Vehicle No.")
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
                    EWayMngmtUnit.CreateJsonPurchaseReturn(Rec);
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
                    EWayMngmtUnit.GetEWayPurchaseReturnforPrint(Rec);
                end;
            }
        }
    }
}