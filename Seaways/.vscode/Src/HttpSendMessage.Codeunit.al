/// <summary>
/// Codeunit Http Send Message (ID 50002) implements Interface ISend Message.
/// </summary>
codeunit 50002 "Http Send Message"
{

    [NonDebuggable]
    procedure SendRequest(ServiceUrlP: Text; JObjectP: JsonObject): JsonObject
    var
        InStreamL: InStream;
        ContentsL: Text;
        JObjectL: JsonObject;
    begin
        JObjectP.WriteTo(ContentsL);
        InStreamL := SendRequestToUrl(ServiceUrlP, ContentsL);
        if JObjectL.ReadFrom(InStreamL) then
            ;
        exit(JObjectL);
    end;

    [NonDebuggable]
    procedure SendRequest(ServiceUrlP: Text; TextP: Text): JsonObject
    var
        InStreamL: InStream;
        JObjectL: JsonObject;
    begin
        InStreamL := SendRequestToUrl(ServiceUrlP, TextP);
        if JObjectL.ReadFrom(InStreamL) then
            ;
        exit(JObjectL);
    end;

    procedure SetBasicAuthorization(UsernameP: Text; PasswordP: Text)
    var
        Base64ConvertL: Codeunit "Base64 Convert";
    begin
        AuthorizationG := StrSubstNo('Basic %1', Base64ConvertL.ToBase64(UsernameP + ':' + PasswordP));
    end;

    procedure SetMethod(MethodP: Text)
    begin
        if MethodP.ToLower() = 'post' then
            MethodG := MethodG::Post
        else
            MethodG := MethodG::Get;
    end;

    procedure SetBearerAuthorization(TokenP: Text)
    begin
        AuthorizationG := StrSubstNo('Bearer %1', TokenP);
    end;

    procedure SetContentType(ContentTypeP: Text)
    begin
        ContentTypeG := ContentTypeP;
    end;

    procedure SetHttpHeader(HeaderP: Text; ValueP: Text)
    begin
        HttpHeadersG.Remove(HeaderP);
        HttpHeadersG.Add(HeaderP, ValueP);
    end;

    procedure SetRequestHttpHeader(HeaderP: Text; ValueP: Text)
    begin
        RequestHeadersG.Remove(HeaderP);
        RequestHeadersG.Add(HeaderP, ValueP);
    end;

    procedure StatusCode(): Integer
    begin
        exit(StatusCodeG);
    end;

    procedure IsSuccess(): Boolean
    begin
        exit(IsSuccessG);
    end;

    procedure Reason(): Text
    begin
        exit(ReasonG);
    end;

    [NonDebuggable]
    local procedure SendRequestToUrl(UrlP: Text; ContentsP: Text) ResultR: InStream
    var
        TempBlobL: Codeunit "Temp Blob";
        HttpContentL: HttpContent;
        HttpClientL: HttpClient;
        HttpResponseMessageL: HttpResponseMessage;
        HttpHeadersL: HttpHeaders;
        ReqHttpHeadersL: HttpHeaders;
        KeyL: Text;
    begin
        HttpContentL.WriteFrom(ContentsP);
        HttpContentL.GetHeaders(HttpHeadersL);
        ReqHttpHeadersL := HttpClientL.DefaultRequestHeaders();
        foreach KeyL in RequestHeadersG.Keys do begin
            if ReqHttpHeadersL.Contains(KeyL) then
                ReqHttpHeadersL.Remove(KeyL);
            ReqHttpHeadersL.Add(KeyL, RequestHeadersG.Get(KeyL));
        end;

        foreach KeyL in HttpHeadersG.Keys do begin
            if HttpHeadersL.Contains(KeyL) then
                HttpHeadersL.Remove(KeyL);
            HttpHeadersL.Add(KeyL, HttpHeadersG.Get(KeyL));
        end;

        if ContentTypeG <> '' then begin
            if HttpHeadersL.Contains('Content-Type') then
                HttpHeadersL.Remove('Content-Type');
            HttpHeadersL.Add('Content-Type', ContentTypeG);
        end;

        if AuthorizationG <> '' then begin
            if ReqHttpHeadersL.Contains('Authorization') then
                ReqHttpHeadersL.Remove('Authorization');
            ReqHttpHeadersL.Add('Authorization', AuthorizationG);
        end;

        if MethodG in [MethodG::" ", MethodG::Post] then
            HttpClientL.Post(UrlP, HttpContentL, HttpResponseMessageL)
        else
            HttpClientL.Get(UrlP, HttpResponseMessageL);


        ReasonG := HttpResponseMessageL.ReasonPhrase();
        StatusCodeG := HttpResponseMessageL.HttpStatusCode();
        IsSuccessG := HttpResponseMessageL.IsSuccessStatusCode();

        TempBlobL.CreateInStream(ResultR);
        HttpResponseMessageL.Content.ReadAs(ResultR);
    end;

    var
        ReasonG: Text;
        StatusCodeG: Integer;
        IsSuccessG: Boolean;
        ContentTypeG: Text;
        AuthorizationG: Text;
        RequestHeadersG: Dictionary of [Text, Text];
        HttpHeadersG: Dictionary of [Text, Text];
        MethodG: Option " ",Post,Get;

}
