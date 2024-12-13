page 50112 "Clear Transactions"
{
    PageType = List;
    CardPageId = "Clear Transaction";
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Clear Trans Hdr";

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
                field("Posting date"; rec."Posting date")
                {
                    ApplicationArea = all;
                }
                field("Sync Status"; rec."Sync Status")
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
        }
    }
}