pageextension 60044 "CT Posted Purchase Invoice" extends "Posted Purchase Invoice"
{
    layout
    {
        addafter("Pay-to Contact")
        {
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
    actions
    {
        addafter("&Navigate")
        {

            group("E-way Bill")
            {


                // action("E-Way")
                // {
                //     ApplicationArea = All;
                //     Caption = 'E-Way Entries', comment = 'ENU="E-Way Entries"';
                //     Promoted = true;
                //     PromotedCategory = Process;
                //     PromotedIsBig = true;
                //     Image = ElectronicDoc;
                //     RunObject = page "ClearComp Sales E-Way Invoice";
                //     RunPageLink = "No." = field("No.");

                // }
                action(Generate)
                {
                    Caption = 'Generate E-Way Bill';
                    Image = CreateDocument;
                    ApplicationArea = All;
                    // PromotedCategory = Category6;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;


                    trigger OnAction()
                    var
                        EWayMngmtUnit: Codeunit "ClearComp E-Way Management";
                    begin
                        EWayMngmtUnit.CreateJsonPurchaseInv(Rec);
                    end;
                }
                action("Update E-Way")
                {
                    ApplicationArea = All;
                    Caption = 'Update E-Way Bill', comment = 'ENU="Update E-Way Bill"';
                    // Promoted = true;
                    // PromotedCategory = Process;
                    // PromotedIsBig = true;
                    Image = ElectronicDoc;
                    RunObject = page "CT Eway Card";
                    RunPageLink = "Document No." = field("No."), "Document Type" = filter("Purch. Inv. Hdr"), "API Type" = filter('E-Way');


                }
                action(PrintEway)
                {
                    Caption = 'Print E-Way Bill Basic';
                    Image = Print;
                    ApplicationArea = All;
                    Visible = true;
                    //Promoted = true;
                    // PromotedCategory = Process;
                    //PromotedIsBig = true;


                    trigger OnAction()
                    var
                        EWayMngmtUnit: Codeunit "ClearComp E-Way Management";
                    begin
                        EWayMngmtUnit.GetEWayPurchaseInvForPrintCons(Rec);
                    end;
                }

                action(PrintEwayDetail)
                {
                    Caption = 'Print E-Way Bill Detail';
                    Image = Print;
                    ApplicationArea = All;
                    Visible = true;
                    // Promoted = true;
                    // PromotedCategory = Process;
                    // PromotedIsBig = true;


                    trigger OnAction()
                    var
                        EWayMngmtUnit: Codeunit "ClearComp E-Way Management";
                    begin
                        EWayMngmtUnit.GetEWayPurchInvDetailForPrint(Rec);
                    end;
                }

            }

        }
    }


}

