page 50201 "ClearComp Purch. Ret E-WayInv"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Purch. Cr. Memo Hdr.";

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
                field("Buy-from Vendor No."; Rec."Buy-from Vendor No.")
                {
                    ApplicationArea = All;
                }
                field("Pay-to Name"; Rec."Pay-to Name")
                {
                    ApplicationArea = All;
                }
                field("Posting Date"; Rec."Posting Date")
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
                field("Shipping Agent Code"; Rec."Shipping Agent Code")
                {
                    ApplicationArea = All;
                }
                field("Transport Method"; Rec."Transport Method")
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