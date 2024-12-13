codeunit 60012 "Clear DSC Wizard"
{

    procedure SignPDFReport(ReportID: Integer; recordrefL: RecordRef)
    var
        tempblob: Codeunit "Temp Blob";
        outStreamL: OutStream;
        base64String: text;
        instreamL: InStream;
        base64: Codeunit "Base64 Convert";
        jsonObject: JsonObject;
        ReqHttpHeadersL: HttpHeaders;
        HttpContentL: HttpContent;
        HttpHeadersL: HttpHeaders;
        HttpResponseMessageL: HttpResponseMessage;
        httpClientl: HttpClient;
        StatusCodeG: Integer;
        IsSuccessG: Boolean;
        ResultR: InStream;
        fileNameL: Text;
        fileManagment: Codeunit "File Management";
        salesInvoiceHeader: record "Sales Invoice Header";
        HttpSendMessage: Codeunit "Clear Http Send Message";
        ResponseText: text;
        ErrorText: text;
        RequestStream: InStream;
        ResponseStream: InStream;
        FileManagementL: Codeunit "File Management";
        // RecordRefL: RecordRef;
        EinvoiceSetup: Record "ClearComp e-Invocie Setup";
        GSTIN: Code[16];
        Location: Record Location;
        SalesCrMemo: Record "Sales Cr.Memo Header";
        transShipHeader: Record "Transfer Shipment Header";
        PurchHeader: Record "Purchase Header";
        serviceInvHeader: record "Service Invoice Header";
        serviceShipHeader: Record "Service Shipment Header";
        serviceCrMemoHeader: Record "Service Cr.Memo Header";
        SalesHeader: Record "Sales Header";
        userSetup: Record "User Setup";


    begin
        userSetup.get(UserId);

        EinvoiceSetup.get;
        tempblob.CreateOutStream(outStreamL);
        if RecordRefL.RecordId.TableNo = database::"Sales Invoice Header" then begin
            recordrefL.SetTable(salesInvoiceHeader);
            salesInvoiceHeader.SetRange("No.", salesInvoiceHeader."No.");
            RecordRefL.GetTable(salesInvoiceHeader);
            GSTIN := salesInvoiceHeader."Location GST Reg. No.";
        end;

        if RecordRefL.RecordId.TableNo = database::"Sales Cr.Memo Header" then begin
            recordrefL.SetTable(SalesCrMemo);
            SalesCrMemo.SetRange("No.", SalesCrMemo."No.");
            RecordRefL.GetTable(SalesCrMemo);
            GSTIN := SalesCrMemo."Location GST Reg. No.";
        end;
        if RecordRefL.RecordId.TableNo = database::"Transfer Shipment Header" then begin
            recordrefL.SetTable(transShipHeader);
            transShipHeader.SetRange("No.", transShipHeader."No.");
            RecordRefL.GetTable(transShipHeader);
            Location.get(transShipHeader."Transfer-from Code");
            GSTIN := Location."GST Registration No.";
        end;

        if RecordRefL.RecordId.TableNo = database::"Purchase Header" then begin
            recordrefL.SetTable(PurchHeader);
            PurchHeader.SetRange("No.", PurchHeader."No.");
            RecordRefL.GetTable(PurchHeader);
            Location.get(PurchHeader."Location Code");
            GSTIN := Location."GST Registration No.";
        end;
        if RecordRefL.RecordId.TableNo = database::"Service invoice Header" then begin
            recordrefL.SetTable(serviceInvHeader);
            serviceInvHeader.SetRange("No.", serviceInvHeader."No.");
            RecordRefL.GetTable(serviceInvHeader);
            Location.get(serviceInvHeader."Location Code");
            GSTIN := Location."GST Registration No.";
        end;
        if RecordRefL.RecordId.TableNo = database::"Service Shipment Header" then begin
            recordrefL.SetTable(serviceShipHeader);
            serviceShipHeader.SetRange("No.", serviceShipHeader."No.");
            RecordRefL.GetTable(serviceShipHeader);
            Location.get(serviceShipHeader."Location Code");
            GSTIN := Location."GST Registration No.";
        end;
        if RecordRefL.RecordId.TableNo = database::"Service Cr.Memo Header" then begin
            recordrefL.SetTable(serviceCrMemoHeader);
            serviceCrMemoHeader.SetRange("No.", serviceCrMemoHeader."No.");
            RecordRefL.GetTable(serviceCrMemoHeader);
            Location.get(serviceCrMemoHeader."Location Code");
            GSTIN := Location."GST Registration No.";
        end;

        if RecordRefL.RecordId.TableNo = database::"Sales Header" then begin
            recordrefL.SetTable(SalesHeader);
            SalesHeader.SetRange("No.", SalesHeader."No.");
            RecordRefL.GetTable(SalesHeader);

            Location.get(SalesHeader."Location Code");
            GSTIN := Location."GST Registration No.";
        end;


        if GSTIN = '' then begin
            Location.FindFirst();
            GSTIN := Location."GST Registration No.";
        end;

        report.SaveAs(ReportID, '', ReportFormat::Pdf, outStreamL, RecordRefL);
        tempblob.CreateInStream(instreamL);
        base64String := base64.ToBase64(instreamL);
        jsonObject.Add('base64String', base64String);
        jsonObject.WriteTo(base64String);
        Clear(HttpSendMessage);
        Clear(ResponseText);
        Clear(ErrorText);

        HttpSendMessage.SetHttpHeader('X-ClearTax-AUTH-TOKEN', EinvoiceSetup."Auth Token");
        HttpSendMessage.SetMethod('POST');
        HttpSendMessage.SetContentType('application/json');

        HttpSendMessage.SetHttpHeader('gstin', GSTIN);

        HttpSendMessage.SetHttpHeader('x-cleartax-product', 'Einvoice');
        HttpSendMessage.AddUrl(EinvoiceSetup."DSC URL Links");
        if (base64String > '') then begin
            TempBlob.CreateOutStream(OutstreamL);
            OutstreamL.WriteText(base64String);
            TempBlob.CreateInStream(RequestStream);
            HttpSendMessage.AddBody(RequestStream);
        end;

        HttpSendMessage.SendRequest(ResponseStream);
        if HttpSendMessage.IsSuccess() then begin
            //  if ForPDF then begin
            Clear(TempBlob);
            TempBlob.CreateOutStream(OutstreamL);
            CopyStream(OutstreamL, ResponseStream);
            FileManagementL.BLOBExport(TempBlob, Format(recordrefL.RecordId) + '.pdf', true);

        end else begin
            ErrorText := HttpSendMessage.Reason();
            if ErrorText > '' then begin
                Commit();
                Message('DSC report generation Failed with following error:' + ErrorText);
            end;
        end;



    end;


}
