pageextension 60040 "SalesInvoice Ext CT" extends "Posted Sales Invoice"

{

    layout
    {
        modify("Mode of Transport")
        {
            Visible = false;
        }

        moveafter("Mode of Transport"; "Transport Method")



    }
    actions
    {


        addafter(CancelIRN)
        {

            group("E-way Bill")
            {

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
                        EWayMngmtUnit.CreateJsonSalesInvoice(Rec);
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
                    RunPageLink = "Document No." = field("No."), "Document Type" = filter('Invoice'), "API Type" = filter('E-Way');


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
                        EWayMngmtUnit.GetEWaySalesInvoiceForPrintCons(Rec);
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
                        EWayMngmtUnit.GetEWaySalesInvoiceForPrint(Rec);
                    end;
                }

            }



        }


    }

}

