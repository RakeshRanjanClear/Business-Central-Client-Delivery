pageextension 60013 "ClearComp UOM Ext" extends "Units of Measure"
{
    layout
    {
        addafter(Code)
        {
            field("GST UQC Values"; rec."GST UQC Values")
            {
                ApplicationArea = all;
            }
        }
    }
}