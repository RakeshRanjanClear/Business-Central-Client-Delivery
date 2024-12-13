page 60034 "ClearComp Sales E-Way Invoice"
{
    PageType = List;
    SourceTable = "Sales Invoice Header";
    SourceTableView = sorting("Posting Date") order(descending);
    DeleteAllowed = false;
    Editable = true;
    ModifyAllowed = true;
    Permissions = tabledata "Sales Invoice Header" = rm;
    Caption = 'ClearComp Sales E-Way Invoice';
    UsageCategory = Lists;
    ApplicationArea = all;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("IRN Hash"; rec."IRN Hash")
                {
                    ApplicationArea = all;
                    Editable = false;
                }
                field("Shipping Agent Code"; Rec."Shipping Agent Code")
                {
                    ApplicationArea = All;
                }
                field("Transport Method"; Rec."Transport Method")
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
                    EWayMngmtUnit.CreateJsonSalesInvoice(Rec);
                end;
            }
            // action(PrintEway)
            // {
            //     Caption = 'Print E-Way Bill Basic';
            //     Image = Print;
            //     ApplicationArea = All;
            //     Visible = true;
            //     //Promoted = true;
            //     // PromotedCategory = Process;
            //     //PromotedIsBig = true;


            //     trigger OnAction()
            //     var
            //         EWayMngmtUnit: Codeunit "ClearComp E-Way Management";
            //     begin
            //         EWayMngmtUnit.GetEWayServiceShipForPrintCons(Rec);
            //     end;
            // }

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
                    EWayMngmtUnit.GetEWaySalesInvoiceForPrint(Rec);
                end;
            }

        }
    }
}