page 50100 "ClearComp E-Invoice Setup"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "ClearComp e-Invocie Setup";
    Caption = 'E-Invoice Setup';

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Integration Enabled"; Rec."Integration Enabled")
                {
                    ApplicationArea = All;
                }
                field("Base URL"; Rec."Base URL")
                {
                    ApplicationArea = All;
                }
                field("Auth Token"; Rec."Auth Token")
                {
                    ApplicationArea = All;
                }
                field("URL IRN Generation"; Rec."URL IRN Generation")
                {
                    ApplicationArea = All;
                }
                field("URL IRN Cancellation"; Rec."URL IRN Cancellation")
                {
                    ApplicationArea = All;
                }
                field("Show Payload"; Rec."Show Payload")
                {
                    ApplicationArea = All;
                }
                field("Integration Mode"; Rec."Integration Mode")
                {
                    ApplicationArea = All;
                }
                // field("URL E-Way Creation"; Rec."URL E-Way Creation")
                // {
                //     ApplicationArea = All;
                // }
                // field("URL E-Way Cancelation"; Rec."URL E-Way Cancelation")
                // {
                //     ApplicationArea = All;
                // }
                // field("URL E-Way Update"; Rec."URL E-Way Update")
                // {
                //     ApplicationArea = All;
                // }
                // field("Download Eway Pdf URL"; Rec."Download Eway Pdf URL")
                // {
                //     ApplicationArea = All;
                // }
                // field("Get Ewaybill Detail URL"; Rec."Get Ewaybill Detail URL")
                // {
                //     ApplicationArea = All;
                // }
                // field("URL Eway By IRN"; Rec."URL Eway By IRN")
                // {
                //     ApplicationArea = All;
                // }
                //   field("URL E-Invoice PDF"; Rec."URL E-Invoice PDF")
                //  {
                //     ApplicationArea = All;
                // }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ActionName)
            {
                ApplicationArea = All;
                Caption = 'e-Invoice Logs';
                Image = Log;

                trigger OnAction()
                var
                    EInvoiceLogs: Page "ClearComp E-Invoice Logs";
                begin
                    EInvoiceLogs.Run();
                end;
            }
            action("Message Logs")
            {
                ApplicationArea = All;
                Image = InteractionLog;
                Caption = 'API message Logs';

                trigger OnAction()
                var
                    InterfMessageLog: Page "ClearComp Interface Msg Log";
                begin
                    InterfMessageLog.Run();
                end;
            }
        }
    }
}
