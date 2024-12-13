table 70000 "ClearTax Setups"
{
    fields
    {
        field(1;"GST Regitration No.";Code[15])
        {
            DataClassification = ToBeClassified;
        }
        field(2;Token;Text[250])
        {
            DataClassification = ToBeClassified;
        }
        field(3;"Owner ID";Text[250])
        {
            DataClassification = ToBeClassified;
        }
        field(4;"Host Name";Text[250])
        {
            DataClassification = ToBeClassified;
        }
        field(5;"Genrate IRN";Text[50])
        {
            DataClassification = ToBeClassified;
        }
        field(6;"Cancel IRN";Text[50])
        {
            DataClassification = ToBeClassified;
        }
        field(7;"Get IRN";Text[50])
        {
            DataClassification = ToBeClassified;
        }
        field(8;"Genrate E-Way Bill";Text[50])
        {
            DataClassification = ToBeClassified;
        }
        field(9;"Cancel E-Way Bill";Text[50])
        {
            DataClassification = ToBeClassified;
        }
        field(10;"Way Bill";Text[50])
        {
            DataClassification = ToBeClassified;
        }
    }
    keys
    {
        key(Key1;"GST Regitration No.")
        {
            Clustered = true;
        }
    }
    fieldgroups
    {
    }
}
