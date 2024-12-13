pageextension 60002 "Clear UQC Values" extends "Units of Measure"
{
    layout
    {
        addafter(Code)
        {
            field("Clear UQC values"; rec."Clear UQC values")
            {
                ApplicationArea = all;
            }
        }
    }

}