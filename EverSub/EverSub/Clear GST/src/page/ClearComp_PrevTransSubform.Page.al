page 50115 "ClearComp Prev. Trans. Subform"
{
    PageType = ListPart;
    SourceTable = "ClearComp GST Trans. Line";
    Caption = 'Preview Transaction Subform';

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = All;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                }
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = All;
                }
                field(UOM; Rec.UOM)
                {
                    ApplicationArea = All;
                }
                field("Total Value"; Rec."Total Value")
                {
                    ApplicationArea = All;
                }
                field("Taxable Value"; Rec."Taxable Value")
                {
                    ApplicationArea = all;
                }
                field("SGST Rate"; Rec."SGST Rate")
                {
                    ApplicationArea = All;
                }
                field("SGST Value"; Rec."SGST Value")
                {
                    ApplicationArea = All;
                }
                field("Cess Rate"; Rec."Cess Rate")
                {
                    ApplicationArea = All;
                }
                field("Cess Value"; Rec."Cess Value")
                {
                    ApplicationArea = All;
                }
                field("CGST Rate"; Rec."CGST Rate")
                {
                    ApplicationArea = All;
                }
                field("CGST Value"; Rec."CGST Value")
                {
                    ApplicationArea = All;
                }
                field("IGST Rate"; Rec."IGST Rate")
                {
                    ApplicationArea = All;
                }
                field("IGST Value"; Rec."IGST Value")
                {
                    ApplicationArea = All;
                }
                field("GST Type"; Rec."GST Type")
                {
                    ApplicationArea = All;
                }
                field("GST Code"; Rec."GST Code")
                {
                    ApplicationArea = All;
                }
                field(Discount; Rec.Discount)
                {
                    ApplicationArea = All;
                }
                field("ITC Type"; Rec."ITC Type")
                {
                    ApplicationArea = All;
                }
                field("ITC Claim Percentage"; Rec."ITC Claim Percentage")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}