codeunit 60009 "Clear Send request"
{
    var
        TransHdr: Record "Clear Trans Hdr";
        ClearGSTSetup: Record "Clear GST Setup";

    trigger OnRun()
    var
        JsonCreation: Codeunit "Clear Json Creation";
        Payload: Text;
        url: Text;
        GSTIN: Text;
        Response: Text;
        status: Integer;
        IsSuccess: Boolean;
        TransHdrSynced: Record "Clear Trans Hdr Synced";
        Processed: Boolean;
    begin
        ClearGSTSetup.Get();
        Clear(TransHdr);
        TransHdr.SetRange("Process Manually", false);
        if TransHdr.FindSet(true) then
            repeat
                Clear(Payload);
                clear(url);
                Payload := JsonCreation.CreatePayload(TransHdr);
                if TransHdr."Transaction Type" = TransHdr."Transaction Type"::sale then begin
                    url := ClearGSTSetup."Base URL" + ClearGSTSetup."Sales URL";
                    GSTIN := TransHdr."Supplier GSTIN";
                end else begin
                    url := ClearGSTSetup."Base URL" + ClearGSTSetup."Purchase URL";
                    GSTIN := TransHdr."Receiver GSTIN";
                end;
                if SendHttpRequest(Payload, url, GSTIN, Response, status, IsSuccess) then begin
                    if IsSuccess then
                        if ProcessResponse(Response) then begin
                            TransHdrSynced.TransferFields(TransHdr);
                            TransHdrSynced."Sync Status" := "Clear Sync status"::Success;
                            TransHdrSynced.Insert();
                            TransHdr.Delete(true);
                        end else begin
                            TransHdr."Sync Status" := TransHdr."Sync Status"::error;
                            TransHdr.Modify();
                        end;
                end else
                    Response := GetLastErrorText();
                if not IsSuccess then begin
                    TransHdr."Sync Status" := TransHdr."Sync Status"::error;
                    TransHdr.Modify();
                end;

                CreateAPILog(Payload, Response, url, status);
            until TransHdr.Next() = 0;

    end;

    [TryFunction]
    local procedure SendHttpRequest(Payload: Text; URL: Text; GSTIN: Text; var Response: text; var status: Integer; var IsSuccess: Boolean)
    var
        httpClientL: HttpClient;
        httpContentL: HttpContent;
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        RequestHeadersL: HttpHeaders;

    begin
        httpContentL.WriteFrom(Payload);
        httpContentL.GetHeaders(RequestHeadersL);
        RequestHeadersL.Add('x-cleartax-auth-token', ClearGSTSetup."Auth token");
        RequestHeadersL.Add('x-cleartax-gstin', GSTIN);
        if RequestHeadersL.Contains('Content-Type') then
            RequestHeadersL.Remove('Content-Type');
        RequestHeadersL.Add('Content-Type', 'application/json');
        if httpClientL.Post(URL, httpContentL, ResponseMessage) then begin
            ResponseMessage.Content.ReadAs(Response);
        end else begin
            Response := ResponseMessage.ReasonPhrase();
        end;
        status := ResponseMessage.HttpStatusCode();
        IsSuccess := ResponseMessage.IsSuccessStatusCode();
    end;

    local procedure CreateAPILog(Payload: Text; Response: Text; URL: Text; status: Integer)
    var
        APILog: Record "Clear API Logs";
        OutstreamL: OutStream;
        countL: Integer;
    begin
        if APILog.Get(TransHdr."Transaction Type", TransHdr."Document Type", TransHdr."Document No.") then begin
            countL := APILog."Retry count";
            APILog.Delete();
        end;

        Clear(APILog);
        APILog."Transaction type" := TransHdr."Transaction Type";
        APILog."Document type" := TransHdr."Document Type";
        APILog."Document No" := TransHdr."Document No.";
        APILog.URL := URL;
        APILog.Status := status;
        APILog.Request.CreateOutStream(OutstreamL);
        OutstreamL.WriteText(Payload);
        Clear(OutstreamL);
        APILog.Response.CreateOutStream(OutstreamL);
        OutstreamL.WriteText(Response);
        APILog."Created Date time" := CurrentDateTime;
        APILog."User ID" := UserId;
        APILog."Retry count" := countL + 1;
        APILog.Insert();
        if (APILog."Retry count" > 3) and (TransHdr."Sync Status" = TransHdr."Sync Status"::error) then begin
            TransHdr."Process Manually" := true;
            TransHdr.Modify();
        end;
    end;

    local procedure ProcessResponse(response: Text): Boolean
    var
        Jobject: JsonObject;
        JToken: JsonToken;
        JArray: JsonArray;
    begin
        if CheckifJsonObject(Jobject, response) then
            if Jobject.Contains('gstinStats') then begin
                Jobject.Get('gstinStats', JToken);
                JArray := JToken.AsArray();
                foreach JToken in Jarray do begin
                    Jobject := JToken.AsObject();
                    if Jobject.Contains('invalidRows') then
                        if GetValueFromJsonObject(Jobject, 'invalidRows').AsInteger() = 0 then
                            exit(true);
                end;
            end;
        exit(false);
    end;


    local procedure GetValueFromJsonObject(JObjectP: JsonObject; PropertyNameP: Text) JValueR: JsonValue
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

    [TryFunction]
    local procedure CheckifJsonObject(var JObjectP: JsonObject; response: Text)
    begin
        JObjectP.ReadFrom(response);
    end;
}