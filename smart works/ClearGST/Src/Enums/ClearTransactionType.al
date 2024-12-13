enum 60008 "Clear Transaction type"
{
    Extensible = true;

    value(0; None)
    {
        Caption = 'None';
    }
    value(1; sale)
    {
        Caption = 'Sale';
    }
    value(2; Purchase)
    {
        Caption = 'Purchase';
    }
}