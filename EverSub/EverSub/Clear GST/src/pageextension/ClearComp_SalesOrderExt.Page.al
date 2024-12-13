pageextension 50113 "ClearComp Sales Order Ext." extends "Sales Order"
{
    layout
    {
        modify("External Document No.")
        {
            ShowMandatory = true;
        }
        modify("Posting Date")
        {
            ShowMandatory = true;
        }
    }
}