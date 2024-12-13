page 60118 "ClearComp MaxITC setup"
{
    PageType = Card;
    SourceTable = "ClearComp MaxITC Setup";
    UsageCategory = Administration;
    ApplicationArea = all;
    Caption = 'Clear MAXITC setup';
    layout
    {
        area(content)
        {
            group(General)
            {
                field("Base URL"; Rec."Base URL")
                {

                }
                field("configuration URL"; Rec."configuration URL")
                {

                }
                field("Pre-Signed URL"; Rec."Pre-Signed URL")
                {
                }
                field("Trigger URL"; Rec."Trigger URL")
                {
                }
                field("Check status URL"; Rec."Check status URL")
                {
                }
                field("Org Unit"; Rec."Org Unit")
                {
                }
                field("Auth Token"; Rec."Auth Token")
                {
                }
                group("Payment blocking")
                {
                    field("Payment blocking Account type"; Rec."Payment blocking Account type")
                    {
                    }
                    field("Payment blocking Account No."; Rec."Payment blocking Account No.")
                    {
                    }
                }
            }
            group(Configuration)
            {
                field(Active; Rec.Active)
                {
                }
                field("Created By"; Rec."Created By")
                {
                }
                field("Created At"; Rec."Created At")
                {
                }
                field("Updated By"; Rec."Updated By")
                {
                }
                field("Updated At"; Rec."Updated At")
                {
                }
                field("User Email"; Rec."User Email")
                {
                }
                field("User External ID"; Rec."User External ID")
                {
                }
                field("Custom Template ID"; Rec."Custom Template ID")
                {
                }
                field("Recon Type"; Rec."Recon Type")
                {
                }
                field("Section Names"; Rec."Section Names")
                {
                }
                field("Storage Proxy enabled"; Rec."Storage Proxy enabled")
                {
                }
                field("Pull return period start"; Rec."Pull return period start")
                {
                }
                field("Pull return period end"; Rec."Pull return period end")
                {
                }
                field("Recon return period start"; Rec."Recon return period start")
                {
                }
                field("Recon return period end"; Rec."Recon return period end")
                {
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("Get Configuration")
            {
                PromotedIsBig = true;
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                ApplicationArea = all;
                trigger OnAction()
                var
                    ClearCompMaxITCMgmt: Codeunit "ClearComp MaxITC Management";
                begin
                    ClearCompMaxITCMgmt.GetConfiguration();
                end;
            }
            action(Logs)
            {
                Promoted = true;
                PromotedOnly = true;
                PromotedIsBig = true;
                PromotedCategory = Process;
                ApplicationArea = all;
                trigger OnAction()
                var
                    MessageLogs: Page "ClearComp MaxITC Logs";
                begin
                    MessageLogs.RUN;
                end;
            }
            action("Uploaded Transactions")
            {
                Promoted = true;
                PromotedOnly = true;
                PromotedIsBig = true;
                PromotedCategory = Process;
                ApplicationArea = all;
                trigger OnAction()
                var
                    ClearCompMaxITCMgmt: Codeunit "ClearComp MaxITC Management";
                begin
                    ClearCompMaxITCMgmt.ShowUploadedTransactions();
                end;
            }
            action("Payment Blocking Transactions")
            {
                RunObject = Page "ClearComp MaxITC Payment block";
                RunPageMode = View;
                Promoted = true;
                PromotedOnly = true;
                PromotedIsBig = true;
                PromotedCategory = Process;
                ApplicationArea = all;
            }
        }
    }
}

