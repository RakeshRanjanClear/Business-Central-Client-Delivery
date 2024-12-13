codeunit 60003 "e-Invoice Function Library"
{
    procedure GetValueFromJsonObject(JObjectP: JsonObject; PropertyNameP: Text) JValueR: JsonValue
    var
        JTokenL: JsonToken;
    begin
        JObjectP.Get(PropertyNameP, JTokenL);
        JValueR := JTokenL.AsValue();
        if not JValueR.IsNull then
            exit(JValueR)
        else
            JValueR.SetValue('');
    end;

    procedure GetJObjectValueAsDecimal(JObjectP: JsonObject; PropertyNameP: Text) JValueR: JsonValue
    var
        JTokenL: JsonToken;
    begin
        JObjectP.Get(PropertyNameP, JTokenL);
        JValueR := JTokenL.AsValue();
        if not JValueR.IsNull then
            exit(JValueR)
        else
            JValueR.SetValue(0);
    end;
}
