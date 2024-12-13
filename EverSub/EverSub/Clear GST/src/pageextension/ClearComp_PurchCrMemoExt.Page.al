pageextension 50111 "ClearComp PurchCrMemo Ext." extends "Purchase Credit Memo"
{
    layout
    {
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