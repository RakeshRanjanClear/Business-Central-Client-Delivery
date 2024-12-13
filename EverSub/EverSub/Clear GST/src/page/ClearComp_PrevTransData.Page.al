page 50113 "ClearComp Prev. Trans. Data"
{
    PageType = Card;
    SourceTable = "ClearComp GST Trans. Header";
    Caption = 'Preview Transaction Data';

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = All;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                }
                field("External Document no."; Rec."External Document no.")
                {
                    ApplicationArea = All;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = All;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                }
                field("Customer Type"; Rec."Customer Type")
                {
                    ApplicationArea = All;
                }
                field("Supplier Type"; Rec."Supplier Type")
                {
                    ApplicationArea = All;
                }
                field("Reverse Charge Applicable"; Rec."Reverse Charge Applicable")
                {
                    ApplicationArea = All;
                }
                field("Original Invoice No."; Rec."Original Invoice No.")
                {
                    ApplicationArea = All;
                }
                field("Original Invoice Date"; Rec."Original Invoice Date")
                {
                    ApplicationArea = All;
                }
                field("Reference Doc No."; Rec."Reference Doc No.")
                {
                    ApplicationArea = all;
                }
                field("CDN Type"; Rec."CDN Type")
                {
                    ApplicationArea = All;
                }
                field("Original Invoice Type"; Rec."Original Invoice Type")
                {
                    ApplicationArea = All;
                }
                field("Original Inv. Classification"; Rec."Original Inv. Classification")
                {
                    ApplicationArea = All;
                }
                field("Note Num"; Rec."Note Num")
                {
                    ApplicationArea = All;
                }
                field("Is Bill of Supply"; Rec."Is Bill of Supply")
                {
                    ApplicationArea = All;
                }
                field("Is Advance"; Rec."Is Advance")
                {
                    ApplicationArea = All;
                }
                field("Seller/Buyer Taxable entity"; Rec."Seller/Buyer Taxable entity")
                {
                    ApplicationArea = All;
                }
                field("Place of Supply"; Rec."Place of Supply")
                {
                    ApplicationArea = All;
                }
            }
            group("Seller Details")
            {
                field("Seller Name"; Rec."Seller Name")
                {
                    ApplicationArea = All;
                }
                field("Seller GSTIN"; Rec."Seller GSTIN")
                {
                    ApplicationArea = All;
                }
                field("Seller Address"; Rec."Seller Address")
                {
                    ApplicationArea = All;
                }
                field("Seller Zip Code"; Rec."Seller Zip Code")
                {
                    ApplicationArea = All;
                }
                field("Seller City"; Rec."Seller City")
                {
                    ApplicationArea = All;
                }
                field("Seller State"; Rec."Seller State")
                {
                    ApplicationArea = All;
                }
                field("Seller Country"; Rec."Seller Country")
                {
                    ApplicationArea = All;
                }
                field("Seller Phone No."; Rec."Seller Phone No.")
                {
                    ApplicationArea = All;
                }
            }
            group("Buyer Details")
            {
                field("Buyer Name"; Rec."Buyer Name")
                {
                    ApplicationArea = All;
                }
                field("Buyer GSTIN"; Rec."Buyer GSTIN")
                {
                    ApplicationArea = All;
                }
                field("Buyer Address"; Rec."Buyer Address")
                {
                    ApplicationArea = All;
                }
                field("Buyer Zip Code"; Rec."Buyer Zip Code")
                {
                    ApplicationArea = All;
                }
                field("Buyer City"; Rec."Buyer City")
                {
                    ApplicationArea = All;
                }
                field("Buyer State"; Rec."Buyer State")
                {
                    ApplicationArea = All;
                }
                field("Buyer Country"; Rec."Buyer Country")
                {
                    ApplicationArea = All;
                }
                field("Buyer Phone No."; Rec."Buyer Phone No.")
                {
                    ApplicationArea = All;
                }
            }
            group("Export Details")
            {
                field("Export Type"; Rec."Export Type")
                {
                    ApplicationArea = All;
                }
                field("Shipping Bill No."; Rec."Shipping Bill No.")
                {
                    ApplicationArea = All;
                }
                field("Shipping Port Code"; Rec."Shipping Port Code")
                {
                    ApplicationArea = All;
                }
                field("Shipping Bill Date"; Rec."Shipping Bill Date")
                {
                    ApplicationArea = All;
                }
            }
            group("Import Details")
            {
                field("Import Invoice Type"; Rec."Import Invoice Type")
                {
                    ApplicationArea = All;
                }
                field("Import Port Code"; Rec."Import Port Code")
                {
                    ApplicationArea = All;
                }
                field("Bill of Entry"; Rec."Bill of Entry")
                {
                    ApplicationArea = All;
                }
                field("Bill of Entry Value"; Rec."Bill of Entry Value")
                {
                    ApplicationArea = All;
                }
                field("Bill of Entry Date"; Rec."Bill of Entry Date")
                {
                    ApplicationArea = All;
                }
            }
            group("E-Commerce Details")
            {
                field("E-Commerce Name"; Rec."E-Commerce Name")
                {
                    ApplicationArea = All;
                }
                field("E-Commerce GSTIN"; Rec."E-Commerce GSTIN")
                {
                    ApplicationArea = All;
                }
                field("E-Commerce Address"; Rec."E-Commerce Address")
                {
                    ApplicationArea = All;
                }
                field("E-Commerce Zip Code"; Rec."E-Commerce Zip Code")
                {
                    ApplicationArea = All;
                }
                field("E-Commerce City"; Rec."E-Commerce City")
                {
                    ApplicationArea = All;
                }
                field("E-Commerce State"; Rec."E-Commerce State")
                {
                    ApplicationArea = All;
                }
                field("E-Commerce Country"; Rec."E-Commerce Country")
                {
                    ApplicationArea = All;
                }
                field("E-Commerce Phone No."; Rec."E-Commerce Phone No.")
                {
                    ApplicationArea = All;
                }
                field("E- Commerce Merchant ID"; Rec."E- Commerce Merchant ID")
                {
                    ApplicationArea = All;
                }
                field("TCS Applicable"; Rec."TCS Applicable")
                {
                    ApplicationArea = All;
                }
                field("TDS Applicable"; Rec."TDS Applicable")
                {
                    ApplicationArea = All;
                }
            }
            part("ClearComp Prev. Trans. Subform"; "ClearComp Prev. Trans. Subform")
            {
                ApplicationArea = All;
                Caption = 'Lines';
                SubPageLink = "Transaction Type" = field("Transaction Type"), "Document Type" = field("Document Type"), "Document No." = field("Document No.");
            }
        }

    }
    trigger OnOpenPage()
    begin
        IF Rec.Status = Rec.Status::Synced then begin
            CurrPage.Editable(false);
            Editable := false;
        end else
            Editable := true;
    end;

    var
        Editable: Boolean;
}