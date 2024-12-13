page 60014 "SaleCr Memo Line Update"
{
    ApplicationArea = All;
    Caption = 'SaleCr Memo Line Update';
    PageType = List;
    SourceTable = "Sales Cr.Memo Line";
    UsageCategory = Administration;
    Permissions = tabledata "Sales Cr.Memo Line" = rm;
    layout
    {
        area(Content)
        {
            repeater(General)
            {
                // field("Document No."; Rec."Document No.")
                // {
                //     ApplicationArea = all;
                // }
                // field("Line No."; Rec."Line No.")
                // {
                //     ApplicationArea = all;
                // }
                // field(Type; Rec.Type)
                // {
                //     ApplicationArea = all;
                // }
                // field("No."; Rec."No.")
                // {
                //     ApplicationArea = all;
                // }
                // field(Description; Rec.Description)
                // {
                //     ApplicationArea = all;
                // }
                // field("GST Group Code"; Rec."GST Group Code")
                // {
                //     ApplicationArea = all;
                // }
                // field("HSN/SAC Code"; Rec."HSN/SAC Code")
                // {
                //     ApplicationArea = all;
                // }

            }
        }
    }

}
