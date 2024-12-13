table 60011 "ClearComp e-Invocie Setup"
{
    DataClassification = ToBeClassified;
    Caption = 'ClearComp e-Invocie Setup';

    fields
    {
        field(1; "Primary Code"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Primary Code';
        }
        field(21; "Integration Enabled"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Integration Enabled';
        }
        field(22; "Base URL"; Text[250])
        {
            DataClassification = ToBeClassified;
            Caption = 'Base URL';
        }
        field(23; "Auth Token"; Text[250])
        {
            DataClassification = ToBeClassified;
            Caption = 'Auth Token';
        }
        field(24; "URL IRN Generation"; Text[100])
        {
            DataClassification = ToBeClassified;
            Caption = 'URL IRN Generation';
        }
        field(25; "URL IRN Cancellation"; Text[100])
        {
            DataClassification = ToBeClassified;
            Caption = 'URL IRN Cancellation';
        }
        field(26; "Show Payload"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Show Payload';
        }
        field(27; "Request JSON Path"; Text[250])
        {
            DataClassification = ToBeClassified;
            Caption = 'Request JSON Path';
        }
        field(28; "Response JSON Path"; Text[250])
        {
            DataClassification = ToBeClassified;
            Caption = 'Response JSON Path';
        }
        field(29; "Integration Mode"; Option)
        {
            DataClassification = ToBeClassified;
            Caption = 'Integration Mode';
            OptionMembers = ClearTaxDemo,Live;
        }
        field(36; "URL E-Invoice PDF"; Text[250])
        {
            DataClassification = ToBeClassified;
            Caption = 'URL E-Invoice PDF';
        }
        field(37; "URL QR generation"; Text[250])
        {
            DataClassification = ToBeClassified;
            Caption = 'URL QR generation';
        }
        field(39; "DSC URL Links"; Text[250])
        {


            DataClassification = ToBeClassified;
            Caption = 'DSC URL Links';
        }


    }

    keys
    {
        key(Key1; "Primary Code")
        {
            Clustered = true;
        }
    }
}