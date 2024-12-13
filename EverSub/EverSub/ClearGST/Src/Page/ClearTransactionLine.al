page 50111 "Clear Transaction lines"
{
    PageType = ListPart;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Clear Trans line";

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("Item no"; rec."Item no")
                {
                    ApplicationArea = all;
                }
                field("Item description"; rec."Item description")
                {
                    ApplicationArea = all;
                }
                field("Item category"; rec."Item category")
                {
                    ApplicationArea = all;
                }
                field("Item quantity"; rec."Item quantity")
                {
                    ApplicationArea = all;
                }
                field("Unit Price"; rec."Unit Price")
                {
                    ApplicationArea = all;
                }
                field(Discount; rec.Discount)
                {
                    ApplicationArea = all;
                }
                field(UOM; rec.UOM)
                {
                    ApplicationArea = all;
                }
                field("Zero tax category"; rec."Zero tax category")
                {
                    ApplicationArea = all;
                }
                field("HSNSAC Code"; rec."HSNSAC Code")
                {
                    ApplicationArea = all;
                }
                field("CGST rate"; rec."CGST rate")
                {
                    ApplicationArea = all;
                }
                field("CGST amt"; rec."CGST amt")
                {
                    ApplicationArea = all;
                }
                field("SGST rate"; rec."SGST rate")
                {
                    ApplicationArea = all;
                }
                field("SGST amt"; rec."SGST amt")
                {
                    ApplicationArea = all;
                }
                field("IGST rate"; rec."IGST rate")
                {
                    ApplicationArea = all;
                }
                field("IGST amt"; rec."IGST amt")
                {
                    ApplicationArea = all;
                }
                field("Cess rate"; rec."Cess rate")
                {
                    ApplicationArea = all;
                }
                field("Cess amt"; rec."Cess amt")
                {
                    ApplicationArea = all;
                }

            }
        }
    }
}