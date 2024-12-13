tableextension 50200 "ClearComp e-Invoice Setup Ext." extends "ClearComp e-Invocie Setup"
{
    fields
    {
        field(50200; "URL E-Way Creation"; Text[250])
        {
            DataClassification = ToBeClassified;
            Caption = 'URL E-Way Creation';
        }
        field(50201; "URL E-Way Cancelation"; Text[250])
        {
            DataClassification = ToBeClassified;
            Caption = 'URL E-Way Cancelation';
        }
        field(50202; "URL E-Way Update"; Text[250])
        {
            DataClassification = ToBeClassified;
            Caption = 'URL E-Way Update';
        }
        field(50203; "Download Eway Pdf URL"; Text[250])
        {
            DataClassification = ToBeClassified;
            Caption = 'Download Eway Pdf URL';
        }
        field(50204; "Get Ewaybill Detail URL"; Text[250])
        {
            DataClassification = ToBeClassified;
            Caption = 'Get Ewaybill Detail URL';
        }
        field(50205; "URL Eway By IRN"; Text[250])
        {
            DataClassification = ToBeClassified;
            Caption = 'URL Eway By IRN';
        }
    }
}