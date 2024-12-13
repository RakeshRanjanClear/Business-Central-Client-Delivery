page 60006 "Clear Transactions"
{
    PageType = List;
    CardPageId = "Clear Transaction";
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Clear Trans Hdr";
    Caption = 'Clear GST Transactions';
    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Transaction Type"; rec."Transaction Type")
                {
                    ApplicationArea = All;
                }
                field("Document Type"; rec."Document Type")
                {
                    ApplicationArea = all;
                }
                field("Document No."; rec."Document No.")
                {
                    ApplicationArea = all;
                }
                field("Sync Status"; rec."Sync Status")
                {
                    ApplicationArea = all;
                }
                field("Process Manually"; rec."Process Manually")
                {
                    ApplicationArea = all;
                }
                field("Supplier Name"; rec."Supplier Name")
                {
                    ApplicationArea = all;
                }
                field("Supplier GSTIN"; rec."Supplier GSTIN")
                {
                    ApplicationArea = all;
                }
                field("Receiver Name"; rec."Receiver Name")
                {
                    ApplicationArea = all;
                }
                field("Receiver GSTIN"; rec."Receiver GSTIN")
                {
                    ApplicationArea = all;
                }
                field("Place of Supply"; rec."Place of Supply")
                {
                    ApplicationArea = all;
                }
                field("Is bill of supply"; rec."Is bill of supply")
                {
                    ApplicationArea = all;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("API Log")
            {
                ApplicationArea = All;
                RunObject = page "Clear API Log";
                RunPageLink = "Transaction type" = field("Transaction Type"), "Document type" = field("Document Type"), "Document No" = field("Document No.");
                RunPageMode = View;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
            }

            action("Sales XL")
            {
                ApplicationArea = all;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Visible = false;
                trigger OnAction()
                var
                    GenerateXL: Codeunit "Clear Generate Sales XL";
                begin
                    GenerateXL.CreateandOpenXL(Rec);
                end;
            }
            action("Purchase XL")
            {
                ApplicationArea = all;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Visible = false;
                trigger OnAction()
                var
                    GenerateXL: Codeunit "Clear Generate Purch XL";
                begin
                    GenerateXL.CreateAndOpenXL(Rec);
                end;
            }
        }
    }
}