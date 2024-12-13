enum 60007 "Clear Sync status"
{
    Extensible = true;

    value(0; none)
    {
        Caption = 'none';
    }
    value(1; error)
    {
        Caption = 'Error';
    }
    value(2; ExportedToXL)
    {
        Caption = 'Exported to XL';
    }
    value(3; "ExportedToXL(Error)")
    {
        Caption = 'Exported to XL(Error)';
    }
    value(4; Success)
    {
        Caption = 'Success';
    }
}