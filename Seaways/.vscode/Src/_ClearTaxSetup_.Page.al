page 70000 "ClearTaxSetup"
{
    ApplicationArea = All;
    Caption = 'Clear Tax Setup';
    PageType = List;
    SourceTable = "ClearTax Setups";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("GST Regitration No."; Rec."GST Regitration No.")
                {
                    ToolTip = 'Specifies the value of the GST Regitration No. field.';
                    ApplicationArea = All;
                }
                field(Token; Rec.Token)
                {
                    ToolTip = 'Specifies the value of the Token field.';
                    ApplicationArea = All;
                }
                field("Owner ID"; Rec."Owner ID")
                {
                    ToolTip = 'Specifies the value of the Owner ID field.';
                    ApplicationArea = All;
                }
                field("Host Name"; Rec."Host Name")
                {
                    ToolTip = 'Specifies the value of the Host Name field.';
                    ApplicationArea = All;
                }
                field("Genrate IRN"; Rec."Genrate IRN")
                {
                    ToolTip = 'Specifies the value of the Genrate IRN field.';
                    ApplicationArea = All;
                }
                field("Cancel IRN"; Rec."Cancel IRN")
                {
                    ToolTip = 'Specifies the value of the Cancel IRN field.';
                    ApplicationArea = All;
                }
                field("Get IRN"; Rec."Get IRN")
                {
                    ToolTip = 'Specifies the value of the Get IRN field.';
                    ApplicationArea = All;
                }
                field("Genrate E-Way Bill"; Rec."Genrate E-Way Bill")
                {
                    ToolTip = 'Specifies the value of the Genrate E-Way Bill field.';
                    ApplicationArea = All;
                }
                field("Cancel E-Way Bill"; Rec."Cancel E-Way Bill")
                {
                    ToolTip = 'Specifies the value of the Cancel E-Way Bill field.';
                    ApplicationArea = All;
                }
                field("Way Bill"; Rec."Way Bill")
                {
                    ToolTip = 'Specifies the value of the Way Bill field.';
                    ApplicationArea = All;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action("Update state code")
            {
                ApplicationArea = All;
                Caption = 'Update state code', comment = 'NLB="YourLanguageCaption"';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Image = Image;

                trigger OnAction()
                var
                    UpdatePostedSalesInvoice: Report "Update Posted SalesInvoice";
                begin
                    UpdatePostedSalesInvoice.Run();
                end;
            }
            action("Update state code cr. Memo")
            {
                ApplicationArea = All;
                Caption = 'Update state code Cr. Memo', comment = 'NLB="YourLanguageCaption"';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Image = Accounts;

                trigger OnAction()
                var
                    UpdatePostedSalesInvoice: Report "Update State code on Cr. Memo";
                begin
                    UpdatePostedSalesInvoice.Run();
                end;
            }
        }
    }
}
