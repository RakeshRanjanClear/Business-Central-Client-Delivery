pageextension 50112 "ClearComp Sales Cr. Memo Ext." extends "Sales Credit Memo"
{
    layout
    {
        modify("External Document No.")
        {
            ShowMandatory = true;
        }
        modify("Reference Invoice No.")
        {
            ShowMandatory = true;
        }
        modify("Nature of Supply")
        {
            ShowMandatory = true;
        }
    }
}