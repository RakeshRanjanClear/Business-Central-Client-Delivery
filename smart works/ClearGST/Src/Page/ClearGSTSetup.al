page 60002 "Clear GST Setup"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Clear GST Setup";


    layout
    {
        area(Content)
        {
            group("General")
            {
                field("Base URL"; rec."Base URL")
                {
                    ApplicationArea = all;
                }
                field("Sales URL"; rec."Sales URL")
                {
                    ApplicationArea = all;
                }
                field("Purchase URL"; rec."Purchase URL")
                {
                    ApplicationArea = all;
                }
                field("Auth token"; rec."Auth token")
                {
                    ApplicationArea = all;
                }
            }
            group("User Settings")
            {
                field("Sales template ID"; rec."Sales template ID")
                {
                    ApplicationArea = all;
                }
                field("Purchase template ID"; rec."Purchase template ID")
                {
                    ApplicationArea = all;
                }
                field("Ignore HSN validation"; rec."Ignore HSN validation")
                {
                    ApplicationArea = all;
                }
                field("Integration start date"; rec."Integration start date")
                {
                    ApplicationArea = all;
                }
            }
            group("Dummy details for testing")
            {
                field("Use Test GSTIN"; rec."Use Test GSTIN")
                {
                    ApplicationArea = all;
                }
                field(GSTIN1; rec.GSTIN1)
                {
                    ApplicationArea = all;
                }
                field(GSTIN2; rec.GSTIN2)
                {
                    ApplicationArea = all;
                }
                field(GSTIN3; rec.GSTIN3)
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
            action("API Logs")
            {
                ApplicationArea = All;
                Caption = 'API logs';
                RunObject = page "Clear API logs";
                RunPageMode = View;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
            }
            action("Synced Transactions")
            {
                ApplicationArea = all;
                Caption = 'Synced Transactions';
                RunObject = page "Clear Synced Transactions";
                RunPageMode = View;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
            }
            action("Send Request")
            {
                ApplicationArea = all;
                Caption = 'Send request';
                RunObject = codeunit "Clear Send request";
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
            }
        }
    }
}