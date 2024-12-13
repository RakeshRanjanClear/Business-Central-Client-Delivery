pageextension 60015 "Clear Bussiness Manager Ext" extends "Business Manager Role Center"
{
    actions
    {
        addafter("Bank Book")
        {
            group("E-Invoice")
            {
                Caption = 'E-Invoice';
                action("E-Invoice setup")
                {
                    ApplicationArea = all;
                    Caption = 'E-Invoice setup';
                    RunObject = page "ClearComp E-Invoice Setup";
                    RunPageMode = View;
                    ToolTip = 'E-Invoice configuration';
                }
                action("Generate E-Invoice")
                {
                    ApplicationArea = all;
                    Caption = 'Generate E-Invoice';
                    RunObject = report "ClearComp Generate IRN";
                    ToolTip = 'Generate E-Invoice with specified range';
                }
                action("E- Invoice logs")
                {
                    ApplicationArea = all;
                    Caption = 'Api logs';
                    RunObject = page "ClearComp E-Invoice Logs";
                    RunPageMode = View;
                    ToolTip = 'E-Invoice logs';
                }
                action("Api message logs")
                {
                    ApplicationArea = all;
                    Caption = 'Api message logs';
                    RunObject = page "ClearComp Interface Msg Log";
                    RunPageMode = View;
                    ToolTip = 'Api message logs';
                }
            }
        }
    }
}