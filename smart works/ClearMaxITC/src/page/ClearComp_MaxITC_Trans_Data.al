page 60119 "Clearcomp MaxITC Trans. Data"
{
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "ClearComp MaxITC Trans. Header";
    Caption = 'Clear MAXITC transaction';

    layout
    {
        area(content)
        {

            group(General)
            {

                field("Document Type"; Rec."Document Type")
                {

                    ApplicationArea = all;
                }
                field(TCS; Rec.TCS)
                {

                    ApplicationArea = all;
                }
                field("Total Transaction Value"; Rec."Total Transaction Value")
                {

                    ApplicationArea = all;
                }
                field(Delete; Rec.Delete)
                {

                    ApplicationArea = all;
                }
                field("Is document Cancelled"; Rec."Is document Cancelled")
                {
                    ApplicationArea = all;
                }
                field("Is Supplier a Comp. dealer"; Rec."Is Supplier a Comp. dealer")
                {
                    ApplicationArea = all;
                }
                field("Return filing Month"; Rec."Return filing Month")
                {
                    ApplicationArea = all;
                }
                field("Return filing quarter"; Rec."Return filing quarter")
                {
                    ApplicationArea = all;
                }
                field("My GSTIN"; Rec."My GSTIN")
                {
                    ApplicationArea = all;
                }
                field("Place of supply"; Rec."Place of supply")
                {
                    ApplicationArea = all;
                }
                field("Is Bill of Supply"; Rec."Is Bill of Supply")
                {
                    ApplicationArea = all;
                }
                field("Invoice Type"; Rec."Invoice Type")
                {
                    ApplicationArea = all;
                }
                field("RCM applicable"; Rec."RCM applicable")
                {
                    ApplicationArea = all;
                }
                field("Is Advance"; Rec."Is Advance")
                {
                    ApplicationArea = all;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = all;
                }
                field("Posting date"; Rec."Posting date")
                {
                    ApplicationArea = all;
                }
            }
            group("Supplier Details")
            {

                field("Supplier Name"; Rec."Supplier Name")
                {
                    ApplicationArea = all;
                }
                field("Supplier GSTIN"; Rec."Supplier GSTIN")
                {
                    ApplicationArea = all;
                }
                field("Supplier Address"; Rec."Supplier Address")
                {
                    ApplicationArea = all;
                }
                field("Supplier Zip Code"; Rec."Supplier Zip Code")
                {
                    ApplicationArea = all;
                }
                field("Supplier City"; Rec."Supplier City")
                {
                    ApplicationArea = all;
                }
                field("Supplier State"; Rec."Supplier State")
                {
                    ApplicationArea = all;
                }
                field("Supplier Country"; Rec."Supplier Country")
                {
                    ApplicationArea = all;
                }
                field("Supplier Phone No."; Rec."Supplier Phone No.")
                {
                    ApplicationArea = all;
                }
            }
            group("Credit/Debit Note Details")
            {

                field("Credit/Debit Note No."; Rec."Credit/Debit Note No.")
                {
                    ApplicationArea = all;
                }
                field("Credit/Debit Note date"; Rec."Credit/Debit Note date")
                {
                    ApplicationArea = all;
                }
                field("Credit/Debit Note Type"; Rec."Credit/Debit Note Type")
                {
                    ApplicationArea = all;
                }
                field("Reason for Issuing CDN"; Rec."Reason for Issuing CDN")
                {
                    ApplicationArea = all;
                }
            }
            group("Import Details")
            {

                field("Type of Import"; Rec."Type of Import")
                {
                    ApplicationArea = all;
                }
                field("Bill of Entry No."; Rec."Bill of Entry No.")
                {
                    ApplicationArea = all;
                }
                field("Bill of Entry Port Code"; Rec."Bill of Entry Port Code")
                {
                    ApplicationArea = all;
                }
                field("Bill of Entry Date"; Rec."Bill of Entry Date")
                {
                    ApplicationArea = all;
                }
            }
            group("Advance details")
            {

                field("Advance payment no."; Rec."Advance payment no.")
                {
                    ApplicationArea = all;
                }
                field("Advance payment date"; Rec."Advance payment date")
                {
                    ApplicationArea = all;
                }
                field("Advance payment amount"; Rec."Advance payment amount")
                {
                    ApplicationArea = all;
                }
            }
            group("Goods receipt details")
            {

                field("Goods receipt No."; Rec."Goods receipt No.")
                {
                    ApplicationArea = all;
                }
                field("Goods receipt date"; Rec."Goods receipt date")
                {
                    ApplicationArea = all;
                }
                field("Goods receipt quantity"; Rec."Goods receipt quantity")
                {
                    ApplicationArea = all;
                }
                field("Goods receipt amount"; Rec."Goods receipt amount")
                {
                    ApplicationArea = all;
                }
                field("Payment due date"; Rec."Payment due date")
                {
                    ApplicationArea = all;
                }
                field("Vendor Code"; Rec."Vendor Code")
                {
                    ApplicationArea = all;
                }
            }
            group("Custom Details")
            {
                field("Voucher Number"; Rec."Voucher Number")
                {
                    ApplicationArea = all;
                }
                field("Voucher Date"; Rec."Voucher Date")
                {
                    ApplicationArea = all;
                }
            }
            part(Lines; "ClearComp MaxITC Trans.Subform")
            {
                ApplicationArea = all;
                SubPageLink = "Document Type" = FIELD("Document Type"),
                              "Document No." = FIELD("Document No.");
                UpdatePropagation = Both;
            }
        }
    }

    trigger OnOpenPage()
    begin
        IF Rec.Uploaded THEN BEGIN
            CurrPage.EDITABLE(FALSE);
            CurrPage.Lines.PAGE.EDITABLE(FALSE);
        END;
    end;
}

