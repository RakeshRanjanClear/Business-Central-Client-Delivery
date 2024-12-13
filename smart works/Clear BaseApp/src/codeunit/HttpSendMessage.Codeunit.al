/// <summary>
/// Codeunit Http Send Message (ID 50002) implements Interface ISend Message.
/// </summary>
codeunit 60000 "Clear Http Send Message" implements "Send Message"
{

    //   [NonDebuggable]
    procedure SendRequest(ServiceUrlP: Text; JObjectP: JsonObject): JsonObject
    var
        InStreamL: InStream;
        ContentsL: Text;
        JObjectL: JsonObject;
    begin
        JObjectP.WriteTo(ContentsL);
        SendRequestToUrl(ServiceUrlP, ContentsL, instreamL);
        if JObjectL.ReadFrom(InStreamL) then;
        exit(JObjectL);
    end;

    procedure SendRequest(ServiceUrlP: Text; TextP: Text): Text
    var
        RespText: Text;
        TempInt: Integer;
        InStreamL: InStream;
        JObjectL: JsonObject;
    begin
        SendRequestToUrl(ServiceUrlP, TextP, InStreamL);
        InStreamL.ReadText(RespText);
        exit(RespText);
    end;

    procedure SendRequest(ServiceUrlP: Text; TextP: Text; IsRespInStrmP: Boolean): InStream
    var
        RespText: Text;
        TempInt: Integer;
        JObjectL: JsonObject;
        InstreamL: InStream;
    begin
        SendRequestToUrl(ServiceUrlP, TextP, InstreamL);
        exit(InstreamL);
    end;

    procedure SetBasicAuthorization(UsernameP: Text; PasswordP: Text)
    var
        Base64ConvertL: Codeunit "Base64 Convert";
    begin
        AuthorizationG := StrSubstNo('Basic %1', Base64ConvertL.ToBase64(UsernameP + ':' + PasswordP));
    end;

    procedure SetMethod(MethodP: Text)
    begin
        case MethodP.ToLower() of
            'post':
                MethodG := MethodG::Post;
            'put':
                MethodG := MethodG::Put;
            'get':
                MethodG := MethodG::Get;
            'delete':
                MethodG := MethodG::Delete;
        end
    end;

    procedure SetBearerAuthorization(TokenP: Text)
    begin
        AuthorizationG := StrSubstNo('Bearer %1', TokenP);
    end;

    procedure SetContentType(ContentTypeP: Text)
    begin
        ContentTypeG := ContentTypeP;
    end;

    procedure AddBody(InstreamP: InStream)
    begin
        InstreamG := InstreamP;
    end;

    procedure AddUrl(URLP: Text)
    begin
        URLG := URLP;
    end;

    procedure SetReturnType(ReturnTypeP: Text)
    begin
        ReturnTypeG := ReturnTypeP;
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

    // [NonDebuggable]
    procedure SendRequest(var ResponseStream: InStream)
    var
        TempBlobL: Codeunit "Temp Blob";
        HttpContentL: HttpContent;
        HttpClientL: HttpClient;
        HttpResponseMessageL: HttpResponseMessage;
        HttptReqMsgL: HttpRequestMessage;
        HttpHeadersL: HttpHeaders;
        ReqHttpHeadersL: HttpHeaders;
        KeyL: Text;
        ResponseText: Text;
    begin
        if InitializeBody(HttpContentL) then;
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

        if ReturnTypeG > '' then begin
            if HttpHeadersL.Contains('Return-Type') then
                HttpHeadersL.Remove('Return-Type');
            HttpHeadersL.Add('Return-Type', ReturnTypeG);
        end;

        if AuthorizationG <> '' then begin
            if ReqHttpHeadersL.Contains('Authorization') then
                ReqHttpHeadersL.Remove('Authorization');
            ReqHttpHeadersL.Add('Authorization', AuthorizationG);
        end;
        case MethodG of
            MethodG::Post:
                HttpClientL.Post(UrlG, HttpContentL, HttpResponseMessageL);
            MethodG::Put:
                HttpClientL.Put(UrlG, HttpContentL, HttpResponseMessageL);
            MethodG::Get:
                HttpClientL.Get(UrlG, HttpResponseMessageL);
            MethodG::Delete:
                HttpClientL.Delete(UrlG, HttpResponseMessageL);
        end;
        ReasonG := HttpResponseMessageL.ReasonPhrase();
        StatusCodeG := HttpResponseMessageL.HttpStatusCode();
        IsSuccessG := HttpResponseMessageL.IsSuccessStatusCode();
        HttpResponseMessageL.Content.ReadAs(ResponseStream);
    end;

    [TryFunction]
    // [NonDebuggable]
    local procedure InitializeBody(var HttpContentP: HttpContent)
    begin
        HttpContentP.WriteFrom(InstreamG);
    end;

    local procedure SendRequestToUrl(UrlP: Text; ContentsP: Text; var instreamP: InStream)
    var
        TempBlobL: Codeunit "Temp Blob";
        HttpContentL: HttpContent;
        HttpClientL: HttpClient;
        HttpResponseMessageL: HttpResponseMessage;
        HttptReqMsgL: HttpRequestMessage;
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

        if ReturnTypeG > '' then begin
            if HttpHeadersL.Contains('Return-Type') then
                HttpHeadersL.Remove('Return-Type');
            HttpHeadersL.Add('Return-Type', ReturnTypeG);
        end;

        if AuthorizationG <> '' then begin
            if ReqHttpHeadersL.Contains('Authorization') then
                ReqHttpHeadersL.Remove('Authorization');
            ReqHttpHeadersL.Add('Authorization', AuthorizationG);
        end;

        case MethodG of
            MethodG::Post:
                HttpClientL.Post(UrlP, HttpContentL, HttpResponseMessageL);
            MethodG::Put:
                HttpClientL.Put(UrlP, HttpContentL, HttpResponseMessageL);
            MethodG::Get:
                HttpClientL.Get(UrlP, HttpResponseMessageL);
            MethodG::Delete:
                HttpClientL.Delete(UrlP, HttpResponseMessageL);
        end;

        ReasonG := HttpResponseMessageL.ReasonPhrase();
        StatusCodeG := HttpResponseMessageL.HttpStatusCode();
        IsSuccessG := HttpResponseMessageL.IsSuccessStatusCode();
        HttpResponseMessageL.Content.ReadAs(InstreamP);
    end;

    var

        URLG: Text;
        ReasonG: Text;
        StatusCodeG: Integer;
        IsSuccessG: Boolean;
        ContentTypeG: Text;
        RequestTextG: Text;
        InstreamG: InStream;
        ReturnTypeG: Text;
        AuthorizationG: Text;
        RequestHeadersG: Dictionary of [Text, Text];
        HttpHeadersG: Dictionary of [Text, Text];
        MethodG: Option " ",Post,Put,Get,Delete;
}
