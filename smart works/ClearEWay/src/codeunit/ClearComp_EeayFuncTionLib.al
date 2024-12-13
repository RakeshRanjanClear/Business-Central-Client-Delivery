codeunit 60032 "ClearComp E-Way Mangt Func Lib"
{
    Permissions = TableData "Sales Invoice Header" = rm,
                  TableData "Sales Cr.Memo Header" = rm,
                  TableData "Purch. Cr. Memo Hdr." = rm,
                  TableData "Transfer Shipment Header" = rm,
                  TableData "purch. inv. Header" = rm,
                  tabledata "Sales Shipment Header" = rm,
                  tabledata "Service Shipment HEader" = rm,
                  tabledata "Service invoice header" = rm;


    var

        DocType: Option " ",Invoice,CrMemo,TransferShpt,"Service Invoice","Service Credit Memo","Purch Cr. Memo Hdr","Sales Shipment","Service Shipment","Purch. Inv. Hdr";
        Cleareway: codeunit "ClearComp E-Way Management";
        docNo: code[20];


    procedure GetEWayServiceShipForPrint(SalesInvHeader: Record "Service shipment Header")
    var
        LocationL: Record Location;
        EInvoiceSetupL: Record "ClearComp e-Invocie Setup";
        EInvoiceEntryL: Record "ClearComp e-Invoice Entry";
        ResponseText: Text;
        RequestText: Text;
    begin

        EInvoiceSetupL.Get;
        EInvoiceEntryL.SetCurrentKey("Document Type", "Document No.", "E-Way Generated");
        EInvoiceEntryL.SetRange("Document Type", DocType::"Service Shipment");
        EInvoiceEntryL.SetRange("Document No.", SalesInvHeader."No.");
        EInvoiceEntryL.SetRange("API Type", EInvoiceEntryL."API Type"::"E-way");
        if EInvoiceEntryL.FindFirst() then begin
            EInvoiceEntryL.TestField("E-Way Bill No.");
            LocationL.Get(SalesInvHeader."Location Code");

            // JArray.Add(Format(EInvoiceEntryL."E-Way Bill No."));
            // JObject.Add('ewb_numbers', EInvoiceEntryL."E-Way Bill No.");
            // JObject.Add('print_type', 'DETAILED');
            // JArray.Add(JObject);
            // JArray.WriteTo(RequestText);

            RequestText := '{ "ewb_numbers": [' + Format(EInvoiceEntryL."E-Way Bill No.") + '], "print_type": "DETAILED"}';
            docNo := SalesInvHeader."No.";
            Cleareway.setDocNo(docNo);
            Cleareway.SendRequest('POST', RequestText, ResponseText, EInvoiceSetupL."Download Eway Pdf URL" + '?format=PDF', '', LocationL."GST Registration No.", true);
        end;
    end;



    procedure GetEWaySalesCrMemoForPrint(SalesCrMemo: Record "Sales Cr.Memo Header")
    var
        LocationL: Record Location;
        EInvoiceSetupL: Record "ClearComp e-Invocie Setup";
        EInvoiceEntryL: Record "ClearComp e-Invoice Entry";
        ResponseText: Text;
        RequestText: Text;
    begin

        EInvoiceSetupL.Get;
        EInvoiceEntryL.SetCurrentKey("Document Type", "Document No.", "E-Way Generated");
        EInvoiceEntryL.SetRange("Document Type", DocType::CrMemo);
        EInvoiceEntryL.SetRange("Document No.", SalesCrMemo."No.");
        EInvoiceEntryL.SetRange("API Type", EInvoiceEntryL."API Type"::"E-way");
        if EInvoiceEntryL.FindFirst() then begin
            EInvoiceEntryL.TestField("E-Way Bill No.");
            LocationL.Get(SalesCrMemo."Location Code");

            // JArray.Add(Format(EInvoiceEntryL."E-Way Bill No."));
            // JObject.Add('ewb_numbers', EInvoiceEntryL."E-Way Bill No.");
            // JObject.Add('print_type', 'DETAILED');
            // JArray.Add(JObject);
            // JArray.WriteTo(RequestText);

            RequestText := '{ "ewb_numbers": [' + Format(EInvoiceEntryL."E-Way Bill No.") + '], "print_type": "DETAILED"}';
            docNo := SalesCrMemo."No.";
            Cleareway.setDocNo(docNo);
            Cleareway.SendRequest('POST', RequestText, ResponseText, EInvoiceSetupL."Download Eway Pdf URL" + '?format=PDF', '', LocationL."GST Registration No.", true);
        end;
    end;

    procedure GetEWaySalesCrMemoForPrintCons(SalesCrMemo: Record "Sales Cr.Memo Header")
    var
        LocationL: Record Location;
        EInvoiceSetupL: Record "ClearComp e-Invocie Setup";
        EInvoiceEntryL: Record "ClearComp e-Invoice Entry";
        ResponseText: Text;
        RequestText: Text;
    begin

        EInvoiceSetupL.Get;
        EInvoiceEntryL.SetCurrentKey("Document Type", "Document No.", "E-Way Generated");
        EInvoiceEntryL.SetRange("Document Type", DocType::CrMemo);
        EInvoiceEntryL.SetRange("Document No.", SalesCrMemo."No.");
        EInvoiceEntryL.SetRange("API Type", EInvoiceEntryL."API Type"::"E-way");
        if EInvoiceEntryL.FindFirst() then begin
            EInvoiceEntryL.TestField("E-Way Bill No.");
            LocationL.Get(SalesCrMemo."Location Code");
            //JArray.Add(Format(EInvoiceEntryL."E-Way Bill No."));
            // JObject.Add('ewb_numbers', EInvoiceEntryL."E-Way Bill No.");
            // JObject.Add('print_type', 'BASIC');
            // JArray.Add(JObject);
            // JArray.WriteTo(RequestText);
            RequestText := '{ "ewb_numbers": [' + Format(EInvoiceEntryL."E-Way Bill No.") + '], "print_type": "BASIC"}';

            docNo := SalesCrMemo."No.";
            Cleareway.setDocNo(docNo);
            Cleareway.SendRequest('POST', RequestText, ResponseText, EInvoiceSetupL."Download Eway Pdf URL" + '?format=PDF', '', LocationL."GST Registration No.", true);
        end;
    end;



    procedure GetEWayServiceShipForPrintCons(SalesInvHeader: Record "Service Shipment Header")
    var
        LocationL: Record Location;
        EInvoiceSetupL: Record "ClearComp e-Invocie Setup";
        EInvoiceEntryL: Record "ClearComp e-Invoice Entry";
        ResponseText: Text;
        RequestText: Text;
    begin

        EInvoiceSetupL.Get;
        EInvoiceEntryL.SetCurrentKey("Document Type", "Document No.", "E-Way Generated");
        EInvoiceEntryL.SetRange("Document Type", DocType::"Service Shipment");
        EInvoiceEntryL.SetRange("Document No.", SalesInvHeader."No.");
        EInvoiceEntryL.SetRange("API Type", EInvoiceEntryL."API Type"::"E-way");
        if EInvoiceEntryL.FindFirst() then begin
            EInvoiceEntryL.TestField("E-Way Bill No.");
            LocationL.Get(SalesInvHeader."Location Code");
            //JArray.Add(Format(EInvoiceEntryL."E-Way Bill No."));
            // JObject.Add('ewb_numbers', EInvoiceEntryL."E-Way Bill No.");
            // JObject.Add('print_type', 'BASIC');
            // JArray.Add(JObject);
            // JArray.WriteTo(RequestText);
            RequestText := '{ "ewb_numbers": [' + Format(EInvoiceEntryL."E-Way Bill No.") + '], "print_type": "BASIC"}';

            docNo := SalesInvHeader."No.";
            Cleareway.SendRequest('POST', RequestText, ResponseText, EInvoiceSetupL."Download Eway Pdf URL" + '?format=PDF', '', LocationL."GST Registration No.", true);
        end;
    end;





}