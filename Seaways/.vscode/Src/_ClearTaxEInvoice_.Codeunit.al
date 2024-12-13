codeunit 70000 "ClearTaxEInvoice"
{
    Permissions = tabledata "Sales Invoice Header" = rm,
        tabledata "Sales Cr.Memo Header" = rm;


    // [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterValidateEvent', 'State', True, true)]
    // local procedure OnAfterValidateEventState(var Rec: Record "Sales Header"; var xRec: Record "Sales header"; CurrFieldNo: Integer)
    // begin
    //     rec.validate("GST Bill-to State Code", Rec.state);
    // end;
    /// <summary>
    /// UpdateStateCode. Update State Code to OT for Shiping bill.
    /// </summary>
    /// <param name="DocumentNo">code[20].</param>
    procedure UpdateStateCode(DocumentNo: code[20])
    var
        SalesInvoiceHearder: Record "Sales Invoice Header";
    begin
        SalesInvoiceHearder.get(DocumentNo);
        SalesInvoiceHearder.State := 'OT';
        SalesInvoiceHearder.Modify();
        Commit();

    end;


    procedure UpdateStateCodecrmemo(DocumentNo: code[20])
    var
        SalesInvoiceHearder: Record "Sales Cr.Memo Header";
    begin
        SalesInvoiceHearder.get(DocumentNo);
        SalesInvoiceHearder.State := 'OT';
        SalesInvoiceHearder.Modify();
        Commit();

    end;

    procedure SalesEinvoicePUT(DocumentNo: Code[20]; JsonText: Text)
    var
        client: HttpClient;
        contentHeaders: HttpHeaders;
        content: HttpContent;
        response: HttpResponseMessage;
        request: HttpRequestMessage;
        api_url: text;
        JToken: JsonToken;
        JTokenNew: JsonToken;
        JObject: JsonObject;
        JobjectNew: JsonObject;
        JTokenNew1: JsonToken;
        JTokenNew2: JsonToken;
        JTokenNew3: JsonToken;
        JTokenNew4: JsonToken;
        JObject1: JsonObject;
        JobjectNew1: JsonObject;
        JobjectNew2: JsonObject;
        JobjectNew3: JsonObject;
        JText: Text;
        JText1: Text;
        JText2: Text;
        JText3: Text;
        responseText: Text;
        // TCSEInvSetup: Record "TCS E-Invoice Setup";
        AuthBearer: Text;
        SaleInvHeader: Record "Sales Invoice Header";
        EinvBase: Codeunit "e-Invoice Json Handler3";
        RecRef: RecordRef;
        TempDateTime: DateTime;
        AcknowledgementDateTimeText: Text;
        AcknowledgementDate: Date;
        AcknowledgementTime: Time;
        JSONManagement: Codeunit "JSON Management";
        QRGenerator: Codeunit "QR Generator";
        TempBlob: Codeunit "Temp Blob";
        AcknowledgementDateTxt: Label 'AckDt', Locked = true;
        JobjectStatus: JsonObject;
        JArrayStatus: JsonArray;
        JTokenStatus: JsonToken;
        SalesInvHdr: Record "Sales Invoice Header";
        ClearTaxSetups: Record "ClearTax Setups";
        i: Integer;
        einvoicefunctionLibraryL: Codeunit "e-invoice function Library";
        AckDateTextL: DateTime;
        EwbDtL: DateTime;
        EwbValidTillL: DateTime;
        RequestTextL: Text;
        AckNumberL: Text;
        IRNNoL: Text;
        SingedInvL: Text;
        SingedQRL: Text;
        JtokenL: JsonToken;
        SuccessMsgL: Variant;
        WasRequestSuccessfulL: Boolean;
        IsTransferL: Boolean;
        JresponseL: JsonObject;
        Jresponse2L: JsonObject;
        OStreamL: OutStream;
        QRGeneratorL: Codeunit "qr generator";
        recordrefL: recordref;
        FieldRefL: FieldRef;
        EwbNoL: Text;
        TempBlobL: Codeunit "Temp Blob";
    begin
        SalesInvHdr.Reset();
        SalesInvHdr.SetRange("No.", DocumentNo);
        IF SalesInvHdr.FindFirst() then begin
            ClearTaxSetups.Get(SalesInvHdr."Location GST Reg. No.");
            api_url := ClearTaxSetups."Host Name" + ClearTaxSetups."Genrate IRN";
            content.clear;
            content.WriteFrom(JsonText);
            content.GetHeaders(contentHeaders);
            contentHeaders.Clear();
            contentHeaders.Add('Content-Type', 'application/json');
            contentHeaders.Add('x-cleartax-auth-token', ClearTaxSetups.Token);
            contentHeaders.Add('x-cleartax-product', 'EInvoice');
            contentHeaders.Add('owner_id', ClearTaxSetups."Owner ID");
            contentHeaders.Add('gstin', ClearTaxSetups."GST Regitration No.");
            request.Content := content;
            request.SetRequestUri(api_url);
            request.Method('PUT');
            client.Send(request, response);
            response.Content().ReadAs(responseText);
            Message('%1', responseText);
            JArrayStatus.ReadFrom(responseText);

            FOR i := 0 TO JArrayStatus.Count - 1 DO BEGIN
                JArrayStatus.Get(i, JToken);
                //JobjectNew.Get('document_status', JToken);
                commit;
                IF JToken.IsObject then begin
                    JToken.WriteTo(JText2);
                    JobjectNew2.ReadFrom(JText2);
                    JobjectNew2.Get('document_status', JTokenNew);
                    IF JTokenNew.AsValue().AsText() = 'IRN_GENERATED' then begin
                        SaleInvHeader.Reset();
                        SaleInvHeader.SetRange("No.", DocumentNo);
                        SaleInvHeader.FindFirst();
                        SaleInvHeader.Mark(true);
                        JobjectNew2.Get('govt_response', JTokenNew);
                        JobjectNew2 := JTokenNew.AsObject();
                        IF einvoicefunctionLibraryL.GetValueFromJsonObject(JobjectNew2, 'Success').AsText().ToUpper() = 'Y' then begin
                            AckNumberL := einvoicefunctionLibraryL.GetValueFromJsonObject(JobjectNew2, 'AckNo').AsText(); // ('AckNo')

                            AckDateTextL := GetDateTimeFromText(einvoicefunctionLibraryL.GetValueFromJsonObject(JobjectNew2, 'AckDt').AsText()); //AckDt

                            IRNNoL := einvoicefunctionLibraryL.GetValueFromJsonObject(JobjectNew2, 'Irn').AsText();//Irn

                            SingedInvL := einvoicefunctionLibraryL.GetValueFromJsonObject(JobjectNew2, 'SignedInvoice').AsText();//SignedInvoice

                            SingedQRL := einvoicefunctionLibraryL.GetValueFromJsonObject(JobjectNew2, 'SignedQRCode').AsText();//SignedQRCode

                            //  EwbNoL := einvoicefunctionLibraryL.GetValueFromJsonObject(JobjectNew2, 'EwbNo').AsText();

                            // EwbDtL := GetDateTimeFromText(einvoicefunctionLibraryL.GetValueFromJsonObject(JobjectNew2, 'EwbDt').AsText());

                            // EwbValidTillL := GetDateTimeFromText(einvoicefunctionLibraryL.GetValueFromJsonObject(JobjectNew2, 'EwbValidTill').AsText());


                            QRGeneratorL.GenerateQRCodeImage(SingedQRL, TempBlobL);
                            clear(recordrefL);
                            recordrefL.GetTable(SaleInvHeader);
                            TempBlobL.ToRecordRef(recordrefL, SaleInvHeader.FieldNo(SaleInvHeader."QR Code"));
                            //  recordrefL.Modify();




                            FieldRefL := recordrefL.Field(SaleInvHeader.FieldNo("irn hash"));
                            fieldrefL.Value := IRNNoL;
                            FieldRefL := recordrefL.Field(SaleInvHeader.FieldNo("Acknowledgement No."));
                            fieldrefL.Value := AckNumberL;
                            FieldRefL := recordrefL.Field(SaleInvHeader.FieldNo("Acknowledgement date"));
                            fieldrefL.Value := AckDateTextL;
                            FieldRefL := recordrefL.Field(SaleInvHeader.FieldNo("E-Way Bill No."));
                            fieldrefL.Value := EwbNoL;
                            //FieldRefL := recordrefL.Field(SaleInvHeader.FieldNo(e-wa));
                            // fieldrefL.Value := AckDateTextL;

                            recordrefL.Modify();
                            commit;
                            MESSAGE('E-Invoice Genrated Successfully');
                        end;
                    end
                    else
                        Error('%1', responseText);
                end;
            END;
        end;
    end;

    local procedure GetDateTimeFromText(DateTimeValue: Text[30]): DateTime
    var
        YYYYText: Text[4];
        MMText: Text[2];
        DDText: Text[2];
        YYYY: Integer;
        MM: Integer;
        DD: Integer;
        TimeText: Text[15];
        TimeValue: Time;
    begin
        IF DateTimeValue = '' THEN
            EXIT(0DT);

        YYYYText := COPYSTR(DateTimeValue, 1, 4);
        MMText := COPYSTR(DateTimeValue, 6, 2);
        DDText := COPYSTR(DateTimeValue, 9, 2);
        IF STRLEN(DateTimeValue) > 10 THEN
            TimeText := COPYSTR(DateTimeValue, 12, 8);

        IF NOT EVALUATE(YYYY, YYYYText) THEN
            EXIT(0DT);

        IF NOT EVALUATE(MM, MMText) THEN
            EXIT(0DT);

        IF NOT EVALUATE(DD, DDText) THEN
            EXIT(0DT);

        IF NOT EVALUATE(TimeValue, TimeText) THEN
            TimeValue := 0T;

        EXIT(CREATEDATETIME(DMY2DATE(DD, MM, YYYY), TimeValue));
    end;

    procedure SalesCrEinvoicePUT(DocumentNo: Code[20];
    JsonText: Text) //JsonText
    var
        client: HttpClient;
        contentHeaders: HttpHeaders;
        content: HttpContent;
        response: HttpResponseMessage;
        request: HttpRequestMessage;
        api_url: text;
        JToken: JsonToken;
        JTokenNew: JsonToken;
        JObject: JsonObject;
        JobjectNew: JsonObject;
        JTokenNew1: JsonToken;
        JTokenNew2: JsonToken;
        JTokenNew3: JsonToken;
        JTokenNew4: JsonToken;
        JObject1: JsonObject;
        JobjectNew1: JsonObject;
        JobjectNew2: JsonObject;
        JobjectNew3: JsonObject;
        JText: Text;
        JText1: Text;
        JText2: Text;
        JText3: Text;
        responseText: Text;
        // TCSEInvSetup: Record "TCS E-Invoice Setup";
        AuthBearer: Text;
        SaleCrHeader: Record "Sales Cr.Memo Header";
        EinvBase: Codeunit "e-Invoice Json Handler3";
        RecRef: RecordRef;
        TempDateTime: DateTime;
        AcknowledgementDateTimeText: Text;
        AcknowledgementDate: Date;
        AcknowledgementTime: Time;
        JSONManagement: Codeunit "JSON Management";
        QRGenerator: Codeunit "QR Generator";
        TempBlob: Codeunit "Temp Blob";
        AcknowledgementDateTxt: Label 'AckDt', Locked = true;
        JobjectStatus: JsonObject;
        JTokenStatus: JsonToken;
        SalesCrHdr: Record "Sales Cr.Memo Header";
        ClearTaxSetups: Record "ClearTax Setups";
        JArrayStatus: JsonArray;
        i: Integer;

        einvoicefunctionLibraryL: Codeunit "e-invoice function Library";
        AckDateTextL: DateTime;
        EwbDtL: DateTime;
        EwbValidTillL: DateTime;
        RequestTextL: Text;
        AckNumberL: Text;
        IRNNoL: Text;
        SingedInvL: Text;
        SingedQRL: Text;
        JtokenL: JsonToken;
        SuccessMsgL: Variant;
        WasRequestSuccessfulL: Boolean;
        IsTransferL: Boolean;
        JresponseL: JsonObject;
        Jresponse2L: JsonObject;
        OStreamL: OutStream;
        QRGeneratorL: Codeunit "qr generator";
        recordrefL: recordref;
        FieldRefL: FieldRef;
        EwbNoL: Text;
        TempBlobL: Codeunit "Temp Blob";
    begin
        SalesCrHdr.Reset();
        SalesCrHdr.SetRange("No.", DocumentNo);
        IF SalesCrHdr.FindFirst() then begin
            ClearTaxSetups.Get(SalesCrHdr."Location GST Reg. No.");
            api_url := ClearTaxSetups."Host Name" + ClearTaxSetups."Genrate IRN";
            content.clear;
            content.WriteFrom(JsonText);
            content.GetHeaders(contentHeaders);
            contentHeaders.Clear();
            contentHeaders.Add('Content-Type', 'application/json');
            contentHeaders.Add('x-cleartax-auth-token', ClearTaxSetups.Token);
            contentHeaders.Add('x-cleartax-product', 'EInvoice');
            contentHeaders.Add('owner_id', ClearTaxSetups."Owner ID");
            contentHeaders.Add('gstin', ClearTaxSetups."GST Regitration No.");
            request.Content := content;
            request.SetRequestUri(api_url);
            request.Method('PUT');
            client.Send(request, response);
            response.Content().ReadAs(responseText);
            Message('%1', responseText);
            JArrayStatus.ReadFrom(responseText);

            FOR i := 0 TO JArrayStatus.Count - 1 DO BEGIN
                JArrayStatus.Get(i, JToken);
                //JobjectNew.Get('document_status', JToken);
                commit;
                IF JToken.IsObject then begin
                    JToken.WriteTo(JText2);
                    JobjectNew2.ReadFrom(JText2);
                    JobjectNew2.Get('document_status', JTokenNew);
                    IF JTokenNew.AsValue().AsText() = 'IRN_GENERATED' then begin
                        SalesCrHdr.Reset();
                        SalesCrHdr.SetRange("No.", DocumentNo);
                        SalesCrHdr.FindFirst();
                        SalesCrHdr.Mark(true);
                        JobjectNew2.Get('govt_response', JTokenNew);
                        JobjectNew2 := JTokenNew.AsObject();
                        IF einvoicefunctionLibraryL.GetValueFromJsonObject(JobjectNew2, 'Success').AsText().ToUpper() = 'Y' then begin
                            AckNumberL := einvoicefunctionLibraryL.GetValueFromJsonObject(JobjectNew2, 'AckNo').AsText(); // ('AckNo')

                            AckDateTextL := GetDateTimeFromText(einvoicefunctionLibraryL.GetValueFromJsonObject(JobjectNew2, 'AckDt').AsText()); //AckDt

                            IRNNoL := einvoicefunctionLibraryL.GetValueFromJsonObject(JobjectNew2, 'Irn').AsText();//Irn

                            SingedInvL := einvoicefunctionLibraryL.GetValueFromJsonObject(JobjectNew2, 'SignedInvoice').AsText();//SignedInvoice

                            SingedQRL := einvoicefunctionLibraryL.GetValueFromJsonObject(JobjectNew2, 'SignedQRCode').AsText();//SignedQRCode

                            //  EwbNoL := einvoicefunctionLibraryL.GetValueFromJsonObject(JobjectNew2, 'EwbNo').AsText();

                            // EwbDtL := GetDateTimeFromText(einvoicefunctionLibraryL.GetValueFromJsonObject(JobjectNew2, 'EwbDt').AsText());

                            // EwbValidTillL := GetDateTimeFromText(einvoicefunctionLibraryL.GetValueFromJsonObject(JobjectNew2, 'EwbValidTill').AsText());


                            QRGeneratorL.GenerateQRCodeImage(SingedQRL, TempBlobL);
                            clear(recordrefL);
                            recordrefL.GetTable(SalesCrHdr);
                            TempBlobL.ToRecordRef(recordrefL, SalesCrHdr.FieldNo(SalesCrHdr."QR Code"));
                            //  recordrefL.Modify();




                            FieldRefL := recordrefL.Field(SalesCrHdr.FieldNo("irn hash"));
                            fieldrefL.Value := IRNNoL;
                            FieldRefL := recordrefL.Field(SalesCrHdr.FieldNo("Acknowledgement No."));
                            fieldrefL.Value := AckNumberL;
                            FieldRefL := recordrefL.Field(SalesCrHdr.FieldNo("Acknowledgement date"));
                            fieldrefL.Value := AckDateTextL;
                            FieldRefL := recordrefL.Field(SalesCrHdr.FieldNo("E-Way Bill No."));
                            fieldrefL.Value := EwbNoL;
                            //FieldRefL := recordrefL.Field(SaleInvHeader.FieldNo(e-wa));
                            // fieldrefL.Value := AckDateTextL;

                            recordrefL.Modify();
                            commit;
                            MESSAGE('E-Invoice Genrated Successfully');
                        end;
                    end else
                        Error('%1', responseText);
                end;
            end;
        end;
    end;

    procedure CancelInvoice(JsonText: Text;
    DocNo: Code[20];
    GSTIN: Code[15])
    var
        ClearTaxSetups: Record "ClearTax Setups";
        client: HttpClient;
        contentHeaders: HttpHeaders;
        content: HttpContent;
        response: HttpResponseMessage;
        request: HttpRequestMessage;
        api_url: text;
        JToken: JsonToken;
        JTokenNew: JsonToken;
        JObject: JsonObject;
        JobjectNew: JsonObject;
        JTokenNew1: JsonToken;
        JTokenNew2: JsonToken;
        JTokenNew3: JsonToken;
        JTokenNew4: JsonToken;
        JObject1: JsonObject;
        JobjectNew1: JsonObject;
        JobjectNew2: JsonObject;
        JobjectNew3: JsonObject;
        JText: Text;
        JText1: Text;
        JText2: Text;
        JText3: Text;
        responseText: Text;
        // TCSEInvSetup: Record "TCS E-Invoice Setup";
        AuthBearer: Text;
        SaleInvHeader: Record "Sales Invoice Header";
        EinvBase: Codeunit "e-Invoice Json Handler3";
        RecRef: RecordRef;
        TempDateTime: DateTime;
        AcknowledgementDateTimeText: Text;
        AcknowledgementDate: Date;
        AcknowledgementTime: Time;
        JSONManagement: Codeunit "JSON Management";
        QRGenerator: Codeunit "QR Generator";
        TempBlob: Codeunit "Temp Blob";
        AcknowledgementDateTxt: Label 'CancelDate', Locked = true;
        JobjectStatus: JsonObject;
        JArrayStatus: JsonArray;
        JTokenStatus: JsonToken;
        SalesInvHdr: Record "Sales Invoice Header";
        i: Integer;
        SaleCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        ClearTaxSetups.Get(GSTIN);
        api_url := ClearTaxSetups."Host Name" + ClearTaxSetups."Cancel IRN";
        content.clear;
        content.WriteFrom(JsonText);
        content.GetHeaders(contentHeaders);
        contentHeaders.Clear();
        contentHeaders.Add('Content-Type', 'application/json');
        contentHeaders.Add('x-cleartax-auth-token', ClearTaxSetups.Token);
        contentHeaders.Add('x-cleartax-product', 'EInvoice');
        contentHeaders.Add('owner_id', ClearTaxSetups."Owner ID");
        contentHeaders.Add('gstin', ClearTaxSetups."GST Regitration No.");
        request.Content := content;
        request.SetRequestUri(api_url);
        request.Method('PUT');
        client.Send(request, response);
        response.Content().ReadAs(responseText);
        Message('%1', responseText);
        JArrayStatus.ReadFrom(responseText);
        FOR i := 0 TO JArrayStatus.Count - 1 DO BEGIN
            JArrayStatus.Get(i, JToken);
            IF JToken.IsObject then begin
                JToken.WriteTo(JText2);
                JobjectNew2.ReadFrom(JText2);
                JobjectNew2.Get('document_status', JTokenNew);
                IF JTokenNew.AsValue().AsText() = 'IRN_CANCELLED' then begin
                    SaleInvHeader.Reset();
                    SaleInvHeader.SetRange("No.", DocNo);
                    IF SaleInvHeader.FindFirst() then begin
                        SaleInvHeader.Mark(true);
                        JobjectNew2.Get('govt_response', JTokenNew);
                        IF JTokenNew.IsObject then begin
                            JTokenNew.WriteTo(JText3);
                            JobjectNew1.ReadFrom(JText3);
                            JobjectNew1.Get('CancelDate', JTokenNew2);
                            AcknowledgementDateTimeText := JTokenNew2.AsValue().AsText();
                            Evaluate(AcknowledgementDate, CopyStr(AcknowledgementDateTimeText, 1, 10));
                            Evaluate(AcknowledgementTime, CopyStr(AcknowledgementDateTimeText, 11, 8));
                            TempDateTime := CreateDateTime(AcknowledgementDate, AcknowledgementTime);
                            SaleInvHeader."E-Inv. Cancelled Date" := TempDateTime;
                            SaleInvHeader.Modify();
                            MESSAGE('E-Invoice Cancelled Successfully');
                        end;
                    end;
                    SaleCrMemoHeader.Reset();
                    SaleCrMemoHeader.SetRange("No.", DocNo);
                    IF SaleCrMemoHeader.FindFirst() then begin
                        SaleCrMemoHeader.Mark(true);
                        JobjectNew2.Get('govt_response', JTokenNew);
                        IF JTokenNew.IsObject then begin
                            JTokenNew.WriteTo(JText3);
                            JobjectNew1.ReadFrom(JText3);
                            JobjectNew1.Get('CancelDate', JTokenNew2);
                            AcknowledgementDateTimeText := JTokenNew2.AsValue().AsText();
                            Evaluate(AcknowledgementDate, CopyStr(AcknowledgementDateTimeText, 1, 10));
                            Evaluate(AcknowledgementTime, CopyStr(AcknowledgementDateTimeText, 11, 8));
                            TempDateTime := CreateDateTime(AcknowledgementDate, AcknowledgementTime);
                            SaleCrMemoHeader."E-Inv. Cancelled Date" := TempDateTime;
                            SaleCrMemoHeader.Modify();
                            MESSAGE('E-Invoice Cancelled Successfully');
                        end;
                    end;
                end
                else
                    Error('%1', responseText);
            end;
        END;
    end;

    procedure GetValueAsText(JToken: JsonToken;
    ParamString: Text): Text
    var
        JObject: JsonObject;
    begin
        JObject := JToken.AsObject();
        exit(SelectJsonToken(JObject, ParamString));
    end;

    procedure SelectJsonToken(JObject: JsonObject;
    Path: Text): Text
    var
        JToken: JsonToken;
    begin
        if JObject.SelectToken(Path, JToken) then if NOT JToken.AsValue().IsNull() then exit(JToken.AsValue().AsText());
    end;

    var
        AuthTokenExpirationTime: DateTime;
}
