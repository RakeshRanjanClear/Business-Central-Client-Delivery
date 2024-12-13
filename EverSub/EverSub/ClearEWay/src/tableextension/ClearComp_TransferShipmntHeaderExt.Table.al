tableextension 50202 "ClearComp Transf. Shpmt Ext." extends "Transfer Shipment Header"
{
    fields
    {
        field(50100; "E-Way Bill No."; Text[50])
        {
            DataClassification = ToBeClassified;
            Caption = 'E-Way Bill No.';
        }
    }
}