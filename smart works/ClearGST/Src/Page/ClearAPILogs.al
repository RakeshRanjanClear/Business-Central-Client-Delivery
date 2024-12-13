page 60001 "Clear API logs"
{
    PageType = List;
    ApplicationArea = All;
    CardPageId = "Clear API Log";
    UsageCategory = Administration;
    SourceTable = "Clear API Logs";
    Caption = 'Clear GST API logs';
    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Transaction type"; rec."Transaction type")
                {
                    ApplicationArea = All;
                }
                field("Document type"; rec."Document type")
                {
                    ApplicationArea = all;
                }
                field("Document No"; rec."Document No")
                {
                    ApplicationArea = all;
                }
                field(URL; rec.URL)
                {
                    ApplicationArea = all;
                }
                field(Status; rec.Status)
                {
                    ApplicationArea = all;
                }
                field("Created Date time"; rec."Created Date time")
                {
                    ApplicationArea = all;
                }
                field("User ID"; rec."User ID")
                {
                    ApplicationArea = all;
                }
            }
            grid(Message)
            {
                GridLayout = Columns;
                Editable = false;
                ShowCaption = false;

                group("Request message")
                {
                    usercontrol(Request; "Microsoft.Dynamics.Nav.Client.WebPageViewer")
                    {
                        ApplicationArea = all;
                    }
                }
                group("Response message")
                {
                    usercontrol(Response; "Microsoft.Dynamics.Nav.Client.WebPageViewer")
                    {
                        ApplicationArea = all;
                    }
                }
            }
        }
    }

    var
        ResponseText: Text;
        requestText: Text;

    trigger OnAfterGetCurrRecord()
    var
        instreamL: InStream;
    begin
        Rec.CalcFields(Response, Request);
        rec.Response.CreateInStream(InstreamL);
        InstreamL.ReadText(ResponseText);
        if CheckifJsonObject(ResponseText) then begin
            ResponseText := ResponseText.Replace('''', '');
            ResponseText := StrSubstNo('document.write(''<pre>'' + JSON.stringify(JSON.parse(''%1''), '''', 2) + ''</pre>'');', ResponseText);
            CurrPage.Response.SetContent('', ResponseText);
        end else
            CurrPage.Response.SetContent('<textarea rows="20" cols="100" style="border:none;">' + ResponseText + '</textarea>');

        Clear(InstreamL);

        Rec.Request.CreateInStream(InstreamL);
        InstreamL.ReadText(RequestText);
        if CheckifJsonObject(RequestText) then begin
            RequestText := RequestText.Replace('''', '');
            RequestText := StrSubstNo('document.write(''<pre>'' + JSON.stringify(JSON.parse(''%1''), '''', 2) + ''</pre>'');', RequestText);
            CurrPage.request.SetContent('', RequestText);
        end else
            CurrPage.Response.SetContent('<textarea rows="20" cols="100" style="border:none;">' + RequestText + '</textarea>');
    end;

    [TryFunction]
    local procedure CheckifJsonObject(inputText: Text)
    var
        JObject: JsonObject;
    begin
        JObject.ReadFrom(inputText);
    end;
}