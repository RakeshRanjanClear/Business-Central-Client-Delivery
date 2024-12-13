tableextension 60031 "ClearComp e-Invoice Setup Ext." extends "ClearComp e-Invocie Setup"
{
    fields
    {
        field(60038; "URL E-Way Creation"; Text[250])
        {
            DataClassification = ToBeClassified;
            Caption = 'URL E-Way Creation';
        }
        field(60039; "URL E-Way Cancelation"; Text[250])
        {
            DataClassification = ToBeClassified;
            Caption = 'URL E-Way Cancelation';
        }
        field(60040; "URL E-Way Update"; Text[250])
        {
            DataClassification = ToBeClassified;
            Caption = 'URL E-Way Update';
        }
        field(60041; "Download Eway Pdf URL"; Text[250])
        {
            DataClassification = ToBeClassified;
            Caption = 'Download Eway Pdf URL';
        }
        field(60042; "Get Ewaybill Detail URL"; Text[250])
        {
            DataClassification = ToBeClassified;
            Caption = 'Get Ewaybill Detail URL';
        }
        field(60043; "URL Eway By IRN"; Text[250])
        {
            DataClassification = ToBeClassified;
            Caption = 'URL Eway By IRN';
        }
        field(60044; "URL Multi Vehicle Eway"; Text[250])
        {
            DataClassification = ToBeClassified;
            Caption = 'URL Multi Vehicle Eway';
        }

        field(60046; "URL Extend E-way Bill Validity"; Text[250])
        {
            DataClassification = ToBeClassified;
            Caption = 'URL Extend E-way Bill Validity';
        }

        field(60045; "Create Message Log"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
    }
}