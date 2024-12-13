page 50110 "Clear Transaction"
{
    PageType = Card;
    SourceTable = "Clear Trans Hdr";

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Transaction Type"; rec."Transaction Type")
                {
                    ApplicationArea = All;
                }
                field("Document Type"; rec."Document Type")
                {
                    ApplicationArea = All;
                }
                field("Document No."; rec."Document No.")
                {
                    ApplicationArea = all;
                }
                field("Sync Status"; rec."Sync Status")
                {
                    ApplicationArea = all;
                }
                field("Posting date"; rec."Posting date")
                {
                    ApplicationArea = all;
                }
                field("Is bill of supply"; rec."Is bill of supply")
                {
                    ApplicationArea = all;
                }
                field("Is document cancelled"; rec."Is document cancelled")
                {
                    ApplicationArea = all;
                }
                field("Is TDS deducted"; rec."Is TDS deducted")
                {
                    ApplicationArea = all;
                }
                field("Linked advance document no."; rec."Linked advance document no.")
                {
                    ApplicationArea = all;
                }
                field("Linked advance document date"; rec."Linked advance document date")
                {
                    ApplicationArea = all;
                }
                field("Linked invoice no."; rec."Linked invoice no.")
                {
                    ApplicationArea = all;
                }
                field("Linked invoice date"; rec."Linked invoice date")
                {
                    ApplicationArea = all;
                }
                field("Ecommerce GSTIN"; rec."Ecommerce GSTIN")
                {
                    ApplicationArea = all;
                }
            }
            group("Supplier details")
            {
                field("Supplier Name"; rec."Supplier Name")
                {
                    ApplicationArea = all;
                }
                field("Supplier GSTIN"; rec."Supplier GSTIN")
                {
                    ApplicationArea = all;
                }
                field("Supplier Address"; rec."Supplier Address")
                {
                    ApplicationArea = all;
                }
                field("Supplier State"; rec."Supplier State")
                {
                    ApplicationArea = all;
                }
            }
            group("Receiver details")
            {
                field("Receiver Name"; rec."Receiver Name")
                {
                    ApplicationArea = all;
                }
                field("Receiver GSTIN"; rec."Receiver GSTIN")
                {
                    ApplicationArea = all;
                }
                field("Receiver address"; rec."Receiver address")
                {
                    ApplicationArea = all;
                }
                field("Receiver State"; rec."Receiver State")
                {
                    ApplicationArea = all;
                }
                field("Place of Supply"; rec."Place of Supply")
                {
                    ApplicationArea = all;
                }
            }
            group("Import details")
            {
                field("Import type"; rec."Import type")
                {
                    ApplicationArea = all;
                }
                field("Import bill no"; rec."Import bill no")
                {
                    ApplicationArea = all;
                }
                field("Import bill date"; rec."Import bill date")
                {
                    ApplicationArea = all;
                }
                field("Import port code"; rec."Import port code")
                {
                    ApplicationArea = all;
                }
            }
            group("Export details")
            {
                field("Export type"; rec."Export type")
                {
                    ApplicationArea = all;
                }
                field("Export bill no."; rec."Export bill no.")
                {
                    ApplicationArea = all;
                }
                field("Export bill date"; rec."Export bill date")
                {
                    ApplicationArea = all;
                }
                field("Export Port Code"; rec."Export Port Code")
                {
                    ApplicationArea = all;
                }
            }

            part("Transaction lines"; "Clear Transaction lines")
            {
                ApplicationArea = all;
                SubPageLink = "Transaction Type" = field("Transaction Type"), "Document Type" = field("Document Type"), "Document No." = field("Document No.");
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

    var
        myInt: Integer;
}