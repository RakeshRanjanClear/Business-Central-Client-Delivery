pageextension 60001 "Clear business manager Ext" extends "Business Manager Role Center"
{

    actions
    {
        addbefore(Anchor)
        {
            group("Clear GST")
            {
                Caption = 'Clear GST';
                action("GST Setup")
                {
                    ApplicationArea = all;
                    Caption = 'GST Setup';
                    RunObject = page "Clear GST Setup";
                    RunPageMode = View;
                    ToolTip = 'GST configuration';
                }
                action("Generate GST Data")
                {
                    ApplicationArea = all;
                    Caption = 'Generate data';
                    RunObject = report "Clear Generate data";
                    ToolTip = 'Generate GST data to Staging';
                }
                action("Ingest data to GST portal")
                {
                    ApplicationArea = all;
                    Caption = 'Ingest data to Portal';
                    RunObject = codeunit "Clear Send request";
                    ToolTip = 'Sends data from Staging to GST portal';
                }
                action("Un-Synced Transactions")
                {
                    ApplicationArea = all;
                    Caption = 'Un-Synced transactions';
                    RunObject = page "Clear Transactions";
                    RunPageMode = View;
                    ToolTip = 'Shows transactions which are not synced with GST portal';
                }
                action("Synced Transactions")
                {
                    ApplicationArea = all;
                    Caption = 'Synced transactions';
                    RunObject = page "Clear Synced Transactions";
                    RunPageMode = View;
                    ToolTip = 'Show transactions synced with GST portal';
                }
                action("API logs")
                {
                    ApplicationArea = all;
                    Caption = 'API logs';
                    RunObject = page "Clear API logs";
                    RunPageMode = View;
                    ToolTip = 'Displays incoming/outgoing api messages';
                }
            }
        }
    }
}