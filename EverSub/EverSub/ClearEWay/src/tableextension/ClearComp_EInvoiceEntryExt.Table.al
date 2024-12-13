tableextension 50201 "ClearComp e-Invoice Entry Ext." extends "ClearComp e-Invoice Entry"
{
    fields
    {
        field(50200; "E-Way Bill No."; Text[30])
        {
            DataClassification = ToBeClassified;
            Caption = 'E-Way Bill No.';
        }
        field(50201; "E-Way Bill Date"; Text[30])
        {
            DataClassification = ToBeClassified;
            Caption = 'E-Way Bill Date';
        }
        field(50202; "E-Way Bill Validity"; Text[30])
        {
            DataClassification = ToBeClassified;
            Caption = 'E-Way Bill Validity';
        }
        field(50203; "E-Way Generated"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'E-Way Generated';
        }
        field(50204; "E-Way Canceled"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'E-Way Canceled';
        }
        field(50205; "E-Way URL"; Text[200])
        {
            DataClassification = ToBeClassified;
            Caption = 'E-Way URL';
        }
        field(50206; "E-WAY Response Text"; Text[250])
        {
            DataClassification = ToBeClassified;
            Caption = 'E-WAY Response Text';
        }
        field(50207; "E-Way Canceled Date"; Text[250])
        {
            DataClassification = ToBeClassified;
            Caption = 'E-Way Canceled Date';
        }
    }
}