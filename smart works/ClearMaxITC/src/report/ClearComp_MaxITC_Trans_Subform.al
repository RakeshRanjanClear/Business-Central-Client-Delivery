page 60121 "ClearComp MaxITC Trans.Subform"
{
    // version MaxITC
    Caption = 'Clear MAXITC trans. lines';
    InsertAllowed = false;
    PageType = ListPart;
    SourceTable = "ClearComp MaxITC Trans. Line";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = all;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = all;
                }
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = all;
                }
                field("Item Type"; Rec."Item Type")
                {
                    ApplicationArea = all;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = all;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = all;
                }
                field(UOM; Rec.UOM)
                {
                    ApplicationArea = all;
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = all;
                }
                field(Discount; Rec.Discount)
                {
                    ApplicationArea = all;
                }
                field("Taxable Value"; Rec."Taxable Value")
                {
                    ApplicationArea = all;
                }
                field("HSN/SAC code"; Rec."HSN/SAC code")
                {
                    ApplicationArea = all;
                }
                field("CGST Rate"; Rec."CGST Rate")
                {
                    ApplicationArea = all;
                }
                field("CGST Value"; Rec."CGST Value")
                {
                    ApplicationArea = all;
                }
                field("SGST Rate"; Rec."SGST Rate")
                {
                    ApplicationArea = all;
                }
                field("SGST Value"; Rec."SGST Value")
                {
                    ApplicationArea = all;
                }
                field("IGST Rate"; Rec."IGST Rate")
                {
                    ApplicationArea = all;
                }
                field("IGST Value"; Rec."IGST Value")
                {
                    ApplicationArea = all;
                }
                field("CESS Rate"; Rec."CESS Rate")
                {
                    ApplicationArea = all;
                }
                field("CESS Value"; Rec."CESS Value")
                {
                    ApplicationArea = all;
                }
                field("ITC Claim Type"; Rec."ITC Claim Type")
                {
                    ApplicationArea = all;
                }
                field("CGST ITC Claim amt."; Rec."CGST ITC Claim amt.")
                {
                    ApplicationArea = all;
                }
                field("SGST ITC claim amt."; Rec."SGST ITC claim amt.")
                {
                    ApplicationArea = all;
                }
                field("IGST ITC claim amt."; Rec."IGST ITC claim amt.")
                {
                    ApplicationArea = all;
                }
                field("CESS ITC claim amt."; Rec."CESS ITC claim amt.")
                {
                    ApplicationArea = all;
                }
            }
        }
    }
}

