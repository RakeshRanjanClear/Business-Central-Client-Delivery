tableextension 50100 "ClearComp Entry/Exit Pnt. Ext." extends "Entry/Exit Point"
{
    fields
    {
        field(50100; "State Code"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'State Code';
        }
        field(50101; "Post Code"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Post Code';
        }
    }
}