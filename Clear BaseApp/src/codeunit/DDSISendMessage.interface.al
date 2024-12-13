interface "ISend Message"
{
    procedure SendRequest(var ResponseStream: InStream)
    procedure SendRequest(ServiceUrlP: Text; JObjectP: JsonObject): JsonObject;

    procedure SendRequest(ServiceUrlP: Text; TextP: Text): Text;
    procedure SendRequest(ServiceUrlP: Text; TextP: Text; IsRespInStrmP: Boolean): InStream;
    procedure StatusCode(): Integer;

    procedure IsSuccess(): Boolean;

    procedure Reason(): Text;

    procedure SetMethod(MethodP: Text);

    Procedure AddBody(InstreamP: InStream);

    procedure SetBasicAuthorization(UsernameP: Text; PasswordP: Text);

    procedure SetBearerAuthorization(TokenP: Text);

    procedure SetContentType(ContentTypeP: Text);

    procedure SetHttpHeader(HeaderP: Text; ValueP: Text);

    procedure SetRequestHttpHeader(HeaderP: Text; ValueP: Text);
}
