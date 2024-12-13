codeunit 60001 "e-Invoice Json Handler3"
{
    Permissions = tabledata "Sales Invoice Header" = rm,
        tabledata "Sales Cr.Memo Header" = rm;

    trigger OnRun()
    begin
        Initialize();
        if IsInvoice then
            RunSalesInvoice()
        else
            RunSalesCrMemo();
        if DocumentNo <> '' then
            ExportAsJson(DocumentNo)
        else
            Error(DocumentNoBlankErr);
        if IsInvoice then
            Codeunit70000.SalesEinvoicePUT(DocumentNo, JsonText)
        else
            Codeunit70000.SalesCrEinvoicePUT(DocumentNo, JsonText);
    end;

    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        JObject: JsonObject;
        JsonArrayData: JsonArray;
        JsonText: Text;
        DocumentNo: Text[20];
        IsInvoice: Boolean;
        eInvoiceNotApplicableCustErr: Label 'E-Invoicing is not applicable for Unregistered Customer.';
        DocumentNoBlankErr: Label 'E-Invoicing is not supported if document number is blank in the current document.';
        SalesLinesMaxCountLimitErr: Label 'E-Invoice allowes only 100 lines per Invoice. Current transaction is having %1 lines.', Comment = '%1 = Sales Lines count';
        IRNTxt: Label 'Irn', Locked = true;
        AcknowledgementNoTxt: Label 'AckNo', Locked = true;
        AcknowledgementDateTxt: Label 'AckDt', Locked = true;
        IRNHashErr: Label 'No matched IRN Hash %1 found to update.', Comment = '%1 = IRN Hash';
        SignedQRCodeTxt: Label 'SignedQRCode', Locked = true;
        CGSTLbl: Label 'CGST', Locked = true;
        SGSTLbl: label 'SGST', Locked = true;
        IGSTLbl: Label 'IGST', Locked = true;
        CESSLbl: Label 'CESS', Locked = true;

    procedure SetSalesInvHeader(SalesInvoiceHeaderBuff: Record "Sales Invoice Header")
    begin
        SalesInvoiceHeader := SalesInvoiceHeaderBuff;
        SalesInvoiceHeader.COPY(SalesInvoiceHeaderBuff);
        GSTRegNo := SalesInvoiceHeader."Location GST Reg. No.";
        DocumentNo := SalesInvoiceHeader."No.";
        IsInvoice := true;
    end;

    procedure SetCrMemoHeader(SalesCrMemoHeaderBuff: Record "Sales Cr.Memo Header")
    begin
        SalesCrMemoHeader := SalesCrMemoHeaderBuff;
        SalesCrMemoHeader.COPY(SalesCrMemoHeaderBuff);
        GSTRegNo := SalesCrMemoHeader."Location GST Reg. No.";
        DocumentNo := SalesCrMemoHeader."No.";
        IsInvoice := false;
    end;

    procedure GenerateCanceledInvoice(Var_CancelledReason: Option ,"Wrong entry",Duplicate,"Data Entry Mistake","Order Canceled",Other)
    begin
        Initialize();
        if IsInvoice then begin
            DocumentNo := SalesInvoiceHeader."No.";
            WriteCancellationJSON(SalesInvoiceHeader."IRN Hash", Var_CancelledReason, Format(Var_CancelledReason))
        end
        else begin
            DocumentNo := SalesCrMemoHeader."No.";
            WriteCancellationJSON(SalesCrMemoHeader."IRN Hash", Var_CancelledReason, Format(Var_CancelledReason));
        end;
        if DocumentNo <> '' then ExportAsJson(DocumentNo);
        if IsInvoice then
            Codeunit70000.CancelInvoice(JsonText, DocumentNo, SalesInvoiceHeader."Location GST Reg. No.")
        else
            Codeunit70000.CancelInvoice(JsonText, DocumentNo, SalesCrMemoHeader."Location GST Reg. No.");
    end;

    procedure GetEInvoiceResponse(var RecRef: RecordRef)
    var
        JSONManagement: Codeunit "JSON Management";
        QRGenerator: Codeunit "QR Generator";
        TempBlob: Codeunit "Temp Blob";
        FieldRef: FieldRef;
        JsonString: Text;
        TempIRNTxt: Text;
        TempDateTime: DateTime;
        AcknowledgementDateTimeText: Text;
        AcknowledgementDate: Date;
        AcknowledgementTime: Time;
    begin
        JsonString := GetResponseText();
        if (JsonString = '') or (JsonString = '[]') then exit;
        JSONManagement.InitializeObject(JsonString);
        FieldRef := RecRef.Field(SalesInvoiceHeader.FieldNo("IRN Hash"));
        TempIRNTxt := FieldRef.Value;
        if TempIRNTxt = JSONManagement.GetValue(IRNTxt) then begin
            FieldRef := RecRef.Field(SalesInvoiceHeader.FieldNo("Acknowledgement No."));
            FieldRef.Value := JSONManagement.GetValue(AcknowledgementNoTxt);
            AcknowledgementDateTimeText := JSONManagement.GetValue(AcknowledgementDateTxt);
            Evaluate(AcknowledgementDate, CopyStr(AcknowledgementDateTimeText, 1, 10));
            Evaluate(AcknowledgementTime, CopyStr(AcknowledgementDateTimeText, 11, 8));
            TempDateTime := CreateDateTime(AcknowledgementDate, AcknowledgementTime);
            FieldRef := RecRef.Field(SalesInvoiceHeader.FieldNo("Acknowledgement Date"));
            FieldRef.Value := TempDateTime;
            FieldRef := RecRef.Field(SalesInvoiceHeader.FieldNo(IsJSONImported));
            FieldRef.Value := true;
            QRGenerator.GenerateQRCodeImage(JSONManagement.GetValue(SignedQRCodeTxt), TempBlob);
            FieldRef := RecRef.Field(SalesInvoiceHeader.FieldNo("QR Code"));
            TempBlob.ToRecordRef(RecRef, SalesInvoiceHeader.FieldNo("QR Code"));
            RecRef.Modify();
        end
        else
            Error(IRNHashErr, TempIRNTxt);
    end;

    local procedure GetResponseText() ResponseText: Text
    var
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        FileText: Text;
    begin
        TempBlob.CreateInStream(InStream);
        UploadIntoStream('', '', '', FileText, InStream);
        if FileText = '' then exit;
        InStream.ReadText(ResponseText);
    end;

    local procedure WriteCancelJsonFileHeader()
    begin
        JObject.Add('Version', '1.1');
        JsonArrayData.Add(JObject);
    end;

    local procedure WriteCancellationJSON(IRNHash: Text[64];
    CancelReason: Option;
    CancelRemark: Text[100])
    var
        CancelJsonObject: JsonObject;
    begin
        // WriteCancelJsonFileHeader();
        // CancelJsonObject.Add('Canceldtls', '');
        // CancelJsonObject.Add('IRN', IRNHash);
        // CancelJsonObject.Add('CnlRsn', Format(CancelReason));
        // CancelJsonObject.Add('CnlRem', CancelRemark);
        // JsonArrayData.Add(CancelJsonObject);
        // JObject.Add('ExpDtls', JsonArrayData);
        CancelJsonObject.Add('irn', IRNHash);
        CancelJsonObject.Add('CnlRsn', Format(CancelReason));
        CancelJsonObject.Add('CnlRem', CancelRemark);
        TcsJsonArray.Add(CancelJsonObject);
    end;

    local procedure RunSalesInvoice()
    begin
        if not IsInvoice then exit;
        if SalesInvoiceHeader."GST Customer Type" in [SalesInvoiceHeader."GST Customer Type"::Unregistered, SalesInvoiceHeader."GST Customer Type"::" "] then Error(eInvoiceNotApplicableCustErr);
        DocumentNo := SalesInvoiceHeader."No.";
        if SalesInvoiceHeader."Currency Factor" <> 0 then
            CurrRate := 1 / SalesInvoiceHeader."Currency Factor"
        else
            CurrRate := 1;
        WriteJsonFileHeader();
        ReadTransactionDetails(SalesInvoiceHeader."GST Customer Type", SalesInvoiceHeader."Ship-to Code");
        ReadDocumentHeaderDetails();
        ReadDocumentSellerDetails();
        ReadDocumentBuyerDetails();
        ReadDocumentShippingDetails();
        ReadDocumentItemList();
        ReadDocumentTotalDetails();
        ReadExportDetails();
    end;

    local procedure RunSalesCrMemo()
    begin
        if IsInvoice then exit;
        if SalesCrMemoHeader."GST Customer Type" in [SalesCrMemoHeader."GST Customer Type"::Unregistered, SalesCrMemoHeader."GST Customer Type"::" "] then Error(eInvoiceNotApplicableCustErr);
        DocumentNo := SalesCrMemoHeader."No.";
        if SalesCrMemoHeader."Currency Factor" <> 0 then
            CurrRate := 1 / SalesCrMemoHeader."Currency Factor"
        else
            CurrRate := 1;
        WriteJsonFileHeader();
        ReadTransactionDetails(SalesCrMemoHeader."GST Customer Type", SalesCrMemoHeader."Ship-to Code");
        ReadDocumentHeaderDetails();
        ReadDocumentSellerDetails();
        ReadDocumentBuyerDetails();
        ReadDocumentShippingDetails();
        ReadDocumentItemList();
        ReadDocumentTotalDetails();
        ReadExportDetails();
    end;

    local procedure Initialize()
    begin
        Clear(JObject);
        Clear(JsonArrayData);
        Clear(JsonText);
        Clear(TcsJsonArray);
        Clear(TcsObject);
    end;

    local procedure WriteJsonFileHeader()
    var
        JTransaction: JsonObject;
    begin
        //ANIKET
        JObject.Add('Version', '1.1');
        // JObject.Add('Version', '1.1');
        // JObject.Add('Irn', '');
        // JsonArrayData.Add(JObject);
        // JTransaction.Add('Version', '1.1');
        // JObject.Add('transaction', JTransaction);
    end;

    local procedure ReadTransactionDetails(GSTCustType: Enum "GST Customer Type";
    ShipToCode: Code[12])
    begin
        Clear(JsonArrayData);
        if IsInvoice then
            ReadInvoiceTransactionDetails(GSTCustType, ShipToCode)
        else
            ReadCreditMemoTransactionDetails(GSTCustType, ShipToCode);
    end;

    local procedure ReadCreditMemoTransactionDetails(GSTCustType: Enum "GST Customer Type";
    ShipToCode: Code[12])
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        NatureOfSupply: Text[3];
        SupplyType: Text[10];
        catg: Text[10];
        IgstOnIntra: Text[1];
    begin
        // if IsInvoice then
        //     exit;
        // if GSTCustType in [
        //     SalesCrMemoHeader."GST Customer Type"::Registered,
        //     SalesCrMemoHeader."GST Customer Type"::Exempted]
        // then
        //     NatureOfSupply := 'B2B'
        // else
        //     NatureOfSupply := 'EXP';
        // if ShipToCode <> '' then begin
        //     SalesCrMemoLine.SetRange("Document No.", DocumentNo);
        //     if SalesCrMemoLine.FindSet() then
        //         repeat
        //             if SalesCrMemoLine."GST Place of Supply" = SalesCrMemoLine."GST Place of Supply"::"Ship-to Address" then
        //                 SupplyType := 'REG'
        //             else
        //                 SupplyType := 'SHP';
        //         until SalesCrMemoLine.Next() = 0;
        // end else
        //     SupplyType := 'REG';
        IgstOnIntra := 'N';
        // IF IsInvoice THEN BEGIN
        CASE GSTCustType OF
            SalesCrMemoHeader."GST Customer Type"::Registered, SalesCrMemoHeader."GST Customer Type"::Exempted:
                catg := 'B2B';
            SalesCrMemoHeader."GST Customer Type"::Export:
                IF SalesCrMemoHeader."GST Without Payment of Duty" THEN
                    catg := 'EXPWOP'
                ELSE
                    catg := 'EXPWP';
            SalesCrMemoHeader."GST Customer Type"::"Deemed Export":
                catg := 'DEXP';
            SalesCrMemoHeader."GST Customer Type"::"SEZ Development", SalesCrMemoHeader."GST Customer Type"::"SEZ Unit":
                IF SalesCrMemoHeader."GST Without Payment of Duty" THEN
                    catg := 'SEZWOP'
                ELSE
                    catg := 'SEZWP'
        END;
        IF SalesCrMemoHeader."POS Out Of India" THEN IgstOnIntra := 'Y';
        // END;
        WriteTransactionDetails(NatureOfSupply, 'RG', catg, 'false', 'Y', '', IgstOnIntra);
    end;

    local procedure ReadInvoiceTransactionDetails(GSTCustType: Enum "GST Customer Type";
    ShipToCode: Code[12])
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        NatureOfSupplyCategory: Text[3];
        SupplyType: Text[10];
        catg: Text[10];
        IgstOnIntra: Text[1];
    begin
        // if not IsInvoice then
        //     exit;
        // if GSTCustType in [
        //     SalesInvoiceHeader."GST Customer Type"::Registered,
        //     SalesInvoiceHeader."GST Customer Type"::Exempted]
        // then
        //     NatureOfSupplyCategory := 'B2B'
        // else
        //     NatureOfSupplyCategory := 'EXP';
        // if ShipToCode <> '' then begin
        //     SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        //     if SalesInvoiceLine.FindSet() then
        //         repeat
        //             if SalesInvoiceLine."GST Place of Supply" <> SalesInvoiceLine."GST Place of Supply"::"Ship-to Address" then
        //                 SupplyType := 'SHP'
        //             else
        //                 SupplyType := 'REG';
        //         until SalesInvoiceLine.Next() = 0;
        // end else
        //     SupplyType := 'REG';
        IgstOnIntra := 'N';
        IF IsInvoice THEN BEGIN
            CASE GSTCustType OF
                SalesInvoiceHeader."GST Customer Type"::Registered, SalesInvoiceHeader."GST Customer Type"::Exempted:
                    catg := 'B2B';
                SalesInvoiceHeader."GST Customer Type"::Export:
                    BEGIN
                        IF SalesInvoiceHeader."GST Without Payment of Duty" THEN
                            catg := 'EXPWOP'
                        ELSE
                            catg := 'EXPWP'
                    END;
                SalesInvoiceHeader."GST Customer Type"::"Deemed Export":
                    catg := 'DEXP';
                SalesInvoiceHeader."GST Customer Type"::"SEZ Development", SalesInvoiceHeader."GST Customer Type"::"SEZ Unit":
                    BEGIN
                        IF SalesInvoiceHeader."GST Without Payment of Duty" THEN
                            catg := 'SEZWOP'
                        ELSE
                            catg := 'SEZWP'
                    END;
            END;
            IF SalesInvoiceHeader."POS Out Of India" THEN IgstOnIntra := 'Y';
        END;
        WriteTransactionDetails(NatureOfSupplyCategory, 'RG', catg, 'false', 'Y', '', IgstOnIntra);
    end;

    local procedure WriteTransactionDetails(SupplyCategory: Text[3];
    RegRev: Text[2];
    SupplyType: Text[10];
    EcmTrnSel: Text[5];
    EcmTrn: Text[1];
    EcmGstin: Text[15];
    IgstOnIntra: Text[1])
    var
        JTranDetails: JsonObject;
    begin
        // JTranDetails.Add('Catg', SupplyCategory);
        // JTranDetails.Add('RegRev', RegRev);
        // JTranDetails.Add('Typ', SupplyType);
        // JTranDetails.Add('EcmTrnSel', EcmTrnSel);
        // JTranDetails.Add('EcmTrn', EcmTrn);
        // JTranDetails.Add('EcmGstin', EcmGstin);
        //JsonArrayData.Add(JTranDetails);
        // JObject.Add('TranDtls', JsonArrayData);
        //JTranDetails.Add('TranDtls', JTranDetails);
        jt.AsValue().SetValueToNull();
        JTranDetails.Add('TaxSch', 'GST');
        JTranDetails.Add('SupTyp', SupplyType);
        JTranDetails.Add('RegRev', 'N');
        JTranDetails.Add('EcmGstin', jt);
        JTranDetails.Add('IgstOnIntra', IgstOnIntra);
        JObject.Add('TranDtls', JTranDetails);
        //  "TaxSch": "GST",
        // "SupTyp": "B2B",
        // "RegRev": "N",
        // "EcmGstin": null,
        // "IgstOnIntra": "N"
    end;

    local procedure ReadDocumentHeaderDetails()
    var
        InvoiceType: Text[3];
        PostingDate: Text[10];
        OriginalInvoiceNo: Text[16];
    begin
        Clear(JsonArrayData);
        if IsInvoice then begin
            if (SalesInvoiceHeader."Invoice Type" = SalesInvoiceHeader."Invoice Type"::"Debit Note") or (SalesInvoiceHeader."Invoice Type" = SalesInvoiceHeader."Invoice Type"::Supplementary) then
                InvoiceType := 'DBN'
            else
                InvoiceType := 'INV';
            PostingDate := Format(SalesInvoiceHeader."Posting Date", 0, '<Day,2>/<Month,2>/<Year4>');
        end
        else begin
            InvoiceType := 'CRN';
            PostingDate := Format(SalesCrMemoHeader."Posting Date", 0, '<Day,2>/<Month,2>/<Year4>');
        end;
        OriginalInvoiceNo := CopyStr(GetReferenceInvoiceNo(DocumentNo), 1, 16);
        WriteDocumentHeaderDetails(InvoiceType, CopyStr(DocumentNo, 1, 16), PostingDate, OriginalInvoiceNo);
    end;

    local procedure WriteDocumentHeaderDetails(InvoiceType: Text[3];
    DocumentNo: Text[16];
    PostingDate: Text[10];
    OriginalInvoiceNo: Text[16])
    var
        JDocumentHeaderDetails: JsonObject;
    begin
        JDocumentHeaderDetails.Add('Typ', InvoiceType);
        JDocumentHeaderDetails.Add('No', DocumentNo);
        JDocumentHeaderDetails.Add('Dt', PostingDate);
        //JDocumentHeaderDetails.Add('OrgInvNo', OriginalInvoiceNo);
        //ANIKET
        //JsonArrayData.Add(JDocumentHeaderDetails);
        //JObject.Add('DocDtls', JsonArrayData);
        JObject.Add('DocDtls', JDocumentHeaderDetails);
    end;

    local procedure ReadExportDetails()
    begin
        Clear(JsonArrayData);
        if IsInvoice then
            ReadInvoiceExportDetails()
        else
            ReadCrMemoExportDetails();
    end;

    local procedure ReadCrMemoExportDetails()
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        ExportCategory: Text[3];
        WithPayOfDuty: Text[1];
        ShipmentBillNo: Text[16];
        ShipmentBillDate: Text[10];
        ExitPort: Text[10];
        DocumentAmount: Decimal;
        DocumentAmount1: Decimal;
        CurrencyCode: Text[3];
        CountryCode: Text[2];
        GSTLedgerEntry: Record "GST Ledger Entry";
        IGSTAmount1: Decimal;
        SGSTAmount1: Decimal;
        CGSTAmount1: Decimal;
    begin
        if IsInvoice then exit;
        GSTLedgerEntry.SetRange("Document No.", DocumentNo);
        GSTLedgerEntry.SetRange("GST Component Code", CGSTLbl);
        if GSTLedgerEntry.FindSet() then
            repeat
                CGSTAmount1 += Abs(GSTLedgerEntry."GST Amount");
            until GSTLedgerEntry.Next() = 0
        else
            CGSTAmount1 := 0;
        GSTLedgerEntry.SetRange("GST Component Code", SGSTLbl);
        if GSTLedgerEntry.FindSet() then
            repeat SGSTAmount1 += Abs(GSTLedgerEntry."GST Amount") until GSTLedgerEntry.Next() = 0
        else
            SGSTAmount1 := 0;
        GSTLedgerEntry.SetRange("GST Component Code", IGSTLbl);
        if GSTLedgerEntry.FindSet() then
            repeat IGSTAmount1 += Abs(GSTLedgerEntry."GST Amount") until GSTLedgerEntry.Next() = 0
        else
            IGSTAmount1 := 0;
        if not (SalesCrMemoHeader."GST Customer Type" in [SalesCrMemoHeader."GST Customer Type"::Export, SalesCrMemoHeader."GST Customer Type"::"Deemed Export", SalesCrMemoHeader."GST Customer Type"::"SEZ Unit", SalesCrMemoHeader."GST Customer Type"::"SEZ Development"]) then exit;
        case SalesCrMemoHeader."GST Customer Type" of
            SalesCrMemoHeader."GST Customer Type"::Export:
                ExportCategory := 'DIR';
            SalesCrMemoHeader."GST Customer Type"::"Deemed Export":
                ExportCategory := 'DEM';
            SalesCrMemoHeader."GST Customer Type"::"SEZ Unit":
                ExportCategory := 'SEZ';
            "GST Customer Type"::"SEZ Development":
                ExportCategory := 'SED';
        end;
        if SalesCrMemoHeader."GST Without Payment of Duty" then
            WithPayOfDuty := 'N'
        else
            WithPayOfDuty := 'Y';
        ShipmentBillNo := CopyStr(SalesCrMemoHeader."Bill Of Export No.", 1, 16);
        ShipmentBillDate := Format(SalesCrMemoHeader."Bill Of Export Date", 0, '<Year4>-<Month,2>-<Day,2>');
        ExitPort := SalesCrMemoHeader."Exit Point";
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        if SalesCrMemoLine.FindSet() then
            repeat
                DocumentAmount := DocumentAmount + SalesCrMemoLine.Amount;
            until SalesCrMemoLine.Next() = 0;
        DocumentAmount1 := DocumentAmount + +IGSTAmount1 + CGSTAmount1 + SGSTAmount1;
        CurrencyCode := CopyStr(SalesCrMemoHeader."Currency Code", 1, 3);
        CountryCode := CopyStr(SalesCrMemoHeader."Bill-to Country/Region Code", 1, 2);
        WriteExportDetails(ExportCategory, WithPayOfDuty, ShipmentBillNo, ShipmentBillDate, ExitPort, DocumentAmount1, CurrencyCode, CountryCode);
    end;

    local procedure ReadInvoiceExportDetails()
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        ExportCategory: Text[3];
        WithPayOfDuty: Text[1];
        ShipmentBillNo: Text[16];
        ShipmentBillDate: Text[10];
        ExitPort: Text[10];
        DocumentAmount: Decimal;
        DocumentAmount1: Decimal;
        CurrencyCode: Text[3];
        CountryCode: Text[2];
        GSTLedgerEntry: Record "GST Ledger Entry";
        IGSTAmount1: Decimal;
        SGSTAmount1: Decimal;
        CGSTAmount1: Decimal;
    begin
        if not IsInvoice then exit;
        GSTLedgerEntry.SetRange("Document No.", DocumentNo);
        GSTLedgerEntry.SetRange("GST Component Code", CGSTLbl);
        if GSTLedgerEntry.FindSet() then
            repeat
                CGSTAmount1 += Abs(GSTLedgerEntry."GST Amount");
            until GSTLedgerEntry.Next() = 0
        else
            CGSTAmount1 := 0;
        GSTLedgerEntry.SetRange("GST Component Code", SGSTLbl);
        if GSTLedgerEntry.FindSet() then
            repeat SGSTAmount1 += Abs(GSTLedgerEntry."GST Amount") until GSTLedgerEntry.Next() = 0
        else
            SGSTAmount1 := 0;
        GSTLedgerEntry.SetRange("GST Component Code", IGSTLbl);
        if GSTLedgerEntry.FindSet() then
            repeat IGSTAmount1 += Abs(GSTLedgerEntry."GST Amount") until GSTLedgerEntry.Next() = 0
        else
            IGSTAmount1 := 0;
        if not (SalesInvoiceHeader."GST Customer Type" in [SalesInvoiceHeader."GST Customer Type"::Export, SalesInvoiceHeader."GST Customer Type"::"Deemed Export", SalesInvoiceHeader."GST Customer Type"::"SEZ Unit", SalesInvoiceHeader."GST Customer Type"::"SEZ Development"]) then exit;
        case SalesInvoiceHeader."GST Customer Type" of
            SalesInvoiceHeader."GST Customer Type"::Export:
                ExportCategory := 'DIR';
            SalesInvoiceHeader."GST Customer Type"::"Deemed Export":
                ExportCategory := 'DEM';
            SalesInvoiceHeader."GST Customer Type"::"SEZ Unit":
                ExportCategory := 'SEZ';
            SalesInvoiceHeader."GST Customer Type"::"SEZ Development":
                ExportCategory := 'SED';
        end;
        if SalesInvoiceHeader."GST Without Payment of Duty" then
            WithPayOfDuty := 'N'
        else
            WithPayOfDuty := 'Y';
        ShipmentBillNo := CopyStr(SalesInvoiceHeader."Bill Of Export No.", 1, 16);
        ShipmentBillDate := Format(SalesInvoiceHeader."Bill Of Export Date", 0, '<Year4>-<Month,2>-<Day,2>');
        ExitPort := SalesInvoiceHeader."Exit Point";
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        if SalesInvoiceLine.FindSet() then
            repeat
                DocumentAmount := DocumentAmount + SalesInvoiceLine.Amount + IGSTAmount1 + CGSTAmount1 + SGSTAmount1;
            until SalesInvoiceLine.Next() = 0;
        DocumentAmount1 := DocumentAmount + +IGSTAmount1 + CGSTAmount1 + SGSTAmount1;
        CurrencyCode := CopyStr(SalesInvoiceHeader."Currency Code", 1, 3);
        CountryCode := CopyStr(SalesInvoiceHeader."Bill-to Country/Region Code", 1, 2);
        WriteExportDetails(ExportCategory, WithPayOfDuty, ShipmentBillNo, ShipmentBillDate, ExitPort, DocumentAmount1, CurrencyCode, CountryCode);
    end;

    local procedure WriteExportDetails(ExportCategory: Text[3];
    WithPayOfDuty: Text[1];
    ShipmentBillNo: Text[16];
    ShipmentBillDate: Text[10];
    ExitPort: Text[10];
    DocumentAmount: Decimal;
    CurrencyCode: Text[3];
    CountryCode: Text[2])
    var
        JExpDetails: JsonObject;
    begin
        JExpDetails.Add('ExpCat', ExportCategory);
        JExpDetails.Add('WithPay', WithPayOfDuty);
        JExpDetails.Add('ShipBNo', ShipmentBillNo);
        JExpDetails.Add('ShipBDt', ShipmentBillDate);
        JExpDetails.Add('Port', ExitPort);
        JExpDetails.Add('InvForCur', DocumentAmount);
        JExpDetails.Add('ForCur', CurrencyCode);
        JExpDetails.Add('CntCode', CountryCode);
        // JsonArrayData.Add(JExpDetails);
        // JObject.Add('ExpDtls', JsonArrayData);
        JObject.Add('ExpDtls', JExpDetails);
    end;

    local procedure ReadDocumentSellerDetails()
    var
        CompanyInformationBuff: Record "Company Information";
        LocationBuff: Record "Location";
        StateBuff: Record "State";
        GSTRegistrationNo: Text[20];
        CompanyName: Text[100];
        Address: Text[100];
        Address2: Text[100];
        Flno: Text[60];
        Loc: Text[60];
        City: Text[60];
        PostCode: Text[6];
        StateCode: Text[10];
        PhoneNumber: Text[10];
        Email: Text[50];
        Pin: Integer;
    begin
        Clear(JsonArrayData);
        if IsInvoice then begin
            GSTRegistrationNo := SalesInvoiceHeader."Location GST Reg. No.";
            LocationBuff.Get(SalesInvoiceHeader."Location Code");
            IF NOT EVALUATE(Pin, COPYSTR(LocationBuff."Post Code", 1, 6)) THEN ERROR(PinCodeErr, SalesInvoiceHeader."No.", LocationBuff."Post Code");
        end
        else begin
            GSTRegistrationNo := SalesCrMemoHeader."Location GST Reg. No.";
            LocationBuff.Get(SalesCrMemoHeader."Location Code");
            IF NOT EVALUATE(Pin, COPYSTR(LocationBuff."Post Code", 1, 6)) THEN ERROR(PinCodeErr, SalesCrMemoHeader."No.", LocationBuff."Post Code");
        end;
        CompanyInformationBuff.Get();
        CompanyName := CompanyInformationBuff.Name;
        Address := LocationBuff.Address;
        Address2 := LocationBuff."Address 2";
        Flno := LocationBuff."Address 2";
        Loc := LocationBuff.City;
        City := LocationBuff.City;
        //PostCode := CopyStr(LocationBuff."Post Code", 1, 6);
        StateBuff.Get(LocationBuff."State Code");
        StateCode := StateBuff."State Code (GST Reg. No.)";
        PhoneNumber := CopyStr(LocationBuff."Phone No.", 1, 10);
        Email := CopyStr(LocationBuff."E-Mail", 1, 50);
        WriteSellerDetails(GSTRegistrationNo, CompanyName, Address, Address2, Flno, Loc, City, PostCode, StateCode, PhoneNumber, Email, Pin);
    end;

    local procedure WriteSellerDetails(GSTRegistrationNo: Text[20];
    CompanyName: Text[100];
    Address: Text[100];
    Address2: Text[100];
    Flno: Text[60];
    Loc: Text[60];
    City: Text[60];
    PostCode: Text[6];
    StateCode: Text[10];
    PhoneNumber: Text[10];
    Email: Text[50];
    Pin: Integer)
    var
        JSellerDetails: JsonObject;
    begin
        // JSellerDetails.Add('Gstin', GSTRegistrationNo);
        // JSellerDetails.Add('TrdNm', CompanyName);
        // JSellerDetails.Add('Bno', Address);
        // JSellerDetails.Add('Bnm', Address2);
        // JSellerDetails.Add('Flno', Flno);
        // JSellerDetails.Add('Loc', Loc);
        // JSellerDetails.Add('Dst', City);
        // JSellerDetails.Add('Pin', PostCode);
        // JSellerDetails.Add('Stcd', StateCode);
        // JSellerDetails.Add('Ph', PhoneNumber);
        // JSellerDetails.Add('Em', Email);
        // JsonArrayData.Add(JSellerDetails);
        // JObject.Add('SellerDtls', JsonArrayData);
        // JObject.Add('SellerDtls', JSellerDetails);
        JSellerDetails.Add('Gstin', GSTRegistrationNo);
        JSellerDetails.Add('LglNm', CompanyName);
        JSellerDetails.Add('TrdNm', CompanyName);
        JSellerDetails.Add('Addr1', Address);
        JSellerDetails.Add('Addr2', Address2);
        JSellerDetails.Add('Loc', Loc);
        JSellerDetails.Add('Pin', Pin);
        JSellerDetails.Add('Stcd', StateCode);
        JObject.Add('SellerDtls', JSellerDetails);
        //    "Gstin": "05AAFCD5862R012",
        //     "LglNm": "Clear Tax Data",
        //     "TrdNm": "CRONUS India Ltd.",
        //     "Addr1": "A202 Gali No 4",
        //     "Addr2": "Street Road Belgavi",
        //     "Loc": "Dehradun",
        //     "Pin": 248001,
        //     "Stcd": "05"
    end;

    local procedure ReadDocumentBuyerDetails()
    begin
        Clear(JsonArrayData);
        if IsInvoice then
            ReadInvoiceBuyerDetails()
        else
            ReadCrMemoBuyerDetails();
    end;

    local procedure ReadInvoiceBuyerDetails()
    var
        Contact: Record Contact;
        SalesInvoiceLine: Record "Sales Invoice Line";
        ShiptoAddress: Record "Ship-to Address";
        StateBuff: Record State;
        GSTRegistrationNumber: Text[20];
        CompanyName: Text[100];
        Address: Text[100];
        Address2: Text[100];
        Floor: Text[100];
        AddressLocation: Text[100];
        City: Text[100];
        PostCode: Text[6];
        StateCode: Text[10];
        PhoneNumber: Text[10];
        Email: Text[50];
        LocationBuff: Record Location;
        Pos: Text[2];
        Pin: Integer;
        CountryCodeOfExport: Text[3];
        POSForExportTxt: Label '96';
    begin
        IF SalesInvoiceHeader."GST Customer Type" IN ["GST Customer Type"::Unregistered, "GST Customer Type"::Export] THEN
            GSTRegistrationNumber := 'URP'
        ELSE
            GSTRegistrationNumber := SalesInvoiceHeader."Customer GST Reg. No.";
        CompanyName := SalesInvoiceHeader."Bill-to Name";
        Address := SalesInvoiceHeader."Bill-to Address";
        Address2 := SalesInvoiceHeader."Bill-to Address 2";
        Floor := '';
        AddressLocation := SalesInvoiceHeader."Bill-to City";
        City := SalesInvoiceHeader."Bill-to City";
        //PostCode := CopyStr(SalesInvoiceHeader."Bill-to Post Code", 1, 6);
        IF SalesInvoiceHeader."GST Customer Type" = "GST Customer Type"::Export THEN
            CountryCodeOfExport := COPYSTR(SalesInvoiceHeader."Bill-to Country/Region Code", 1, 3)
        ELSE
            IF NOT EVALUATE(Pin, COPYSTR(SalesInvoiceHeader."Bill-to Post Code", 1, 6)) THEN
                ERROR(PinCodeErr, SalesInvoiceHeader."No.", SalesInvoiceHeader."Bill-to Post Code");
        IF SalesInvoiceHeader."GST Customer Type" = "GST Customer Type"::Export THEN
            Pin := 999999;
        // IF NOT EVALUATE(Pin, COPYSTR(LocationBuff."Post Code", 1, 6)) THEN
        //     ERROR(PinCodeErr, SalesInvoiceHeader."No.", LocationBuff."Post Code");
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.Setfilter("No.", '<>%1', '');
        if SalesInvoiceLine.FindFirst() then
            case SalesInvoiceLine."GST Place of Supply" of
                SalesInvoiceLine."GST Place of Supply"::"Bill-to Address":
                    begin
                        if not (SalesInvoiceHeader."GST Customer Type" = SalesInvoiceHeader."GST Customer Type"::Export) then begin
                            StateBuff.Get(SalesInvoiceHeader."GST Bill-to State Code");
                            StateCode := StateBuff."State Code (GST Reg. No.)";
                            Pos := StateBuff."State Code (GST Reg. No.)";
                        end
                        else begin
                            StateCode := '96';
                            POS := POSForExportTxt
                        end;
                        if Contact.Get(SalesInvoiceHeader."Bill-to Contact No.") then begin
                            PhoneNumber := CopyStr(Contact."Phone No.", 1, 10);
                            Email := CopyStr(Contact."E-Mail", 1, 50);
                        end
                        else begin
                            PhoneNumber := '';
                            Email := '';
                        end;
                    end;
                SalesInvoiceLine."GST Place of Supply"::"Ship-to Address":
                    begin
                        if not (SalesInvoiceHeader."GST Customer Type" = SalesInvoiceHeader."GST Customer Type"::Export) then begin
                            StateBuff.Get(SalesInvoiceHeader."GST Ship-to State Code");
                            StateCode := StateBuff."State Code (GST Reg. No.)";
                            POS := FORMAT(StateBuff."State Code (GST Reg. No.)");
                        end
                        else begin
                            StateCode := '96';
                            POS := POSForExportTxt
                        end;
                        if ShiptoAddress.Get(SalesInvoiceHeader."Sell-to Customer No.", SalesInvoiceHeader."Ship-to Code") then begin
                            PhoneNumber := CopyStr(ShiptoAddress."Phone No.", 1, 10);
                            Email := CopyStr(ShiptoAddress."E-Mail", 1, 50);
                        end
                        else begin
                            PhoneNumber := '';
                            Email := '';
                        end;
                    end;
                SalesInvoiceLine."GST Place of Supply"::"Location Address":
                    begin
                        if not (SalesInvoiceHeader."GST Customer Type" = SalesInvoiceHeader."GST Customer Type"::Export) then begin
                            if SalesInvoiceHeader."Ship-to Code" = '' then begin
                                StateBuff.Get(SalesInvoiceHeader."GST Bill-to State Code");
                                StateCode := StateBuff."State Code (GST Reg. No.)";
                                LocationBuff.Get(SalesInvoiceHeader."Location Code");
                                StateBuff.get(LocationBuff."State Code");
                                Pos := StateBuff."State Code (GST Reg. No.)";
                            end;
                            if SalesInvoiceHeader."Ship-to Code" <> '' then begin
                                StateBuff.Get(SalesInvoiceHeader."GST Ship-to State Code");
                                StateCode := StateBuff."State Code (GST Reg. No.)";
                                LocationBuff.Get(SalesInvoiceHeader."Location Code");
                                StateBuff.get(LocationBuff."State Code");
                                Pos := StateBuff."State Code (GST Reg. No.)";
                            end;
                        end
                        else
                            StateCode := '';
                    end;
                else begin
                    StateCode := '';
                    PhoneNumber := '';
                    Email := '';
                end;
            end;
        if AddressLocation = '' Then
            AddressLocation := Address;
        if (SalesInvoiceHeader."No." = 'SS11SCI2223/0400') or (SalesInvoiceHeader."No." = 'SS11SCI2223/0433') then begin
            commit;
            SalesInvoiceHeader.State := 'OT';
            SalesInvoiceHeader.Modify();


        end;
        IF SalesInvoiceHeader.State = 'OT' then begin
            StateBuff.Get(SalesInvoiceHeader.State);
            Pos := StateBuff."State Code (GST Reg. No.)";
        end;


        WriteBuyerDetails(GSTRegistrationNumber, CompanyName, Address, Address2, Floor, AddressLocation, City, PostCode, StateCode, PhoneNumber, Email, pos, pin);
    end;

    local procedure ReadCrMemoBuyerDetails()
    var
        Contact: Record Contact;
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        ShiptoAddress: Record "Ship-to Address";
        StateBuff: Record State;
        GSTRegistrationNumber: Text[20];
        CompanyName: Text[100];
        Address: Text[100];
        Address2: Text[100];
        Floor: Text[60];
        AddressLocation: Text[100];
        City: Text[60];
        PostCode: Text[6];
        StateCode: Text[10];
        PhoneNumber: Text[10];
        Email: Text[50];
        Pos: Code[2];
        LocationBuff: Record Location;
        pin: Integer;
        CountryCodeOfExport: Text[3];
        POSForExportTxt: Label '96';
    begin
        IF SalesCrMemoHeader."GST Customer Type" IN ["GST Customer Type"::Unregistered, "GST Customer Type"::Export] THEN
            GSTRegistrationNumber := 'URP'
        ELSE
            GSTRegistrationNumber := SalesCrMemoHeader."Customer GST Reg. No.";
        CompanyName := SalesCrMemoHeader."Bill-to Name";
        Address := SalesCrMemoHeader."Bill-to Address";
        Address2 := SalesCrMemoHeader."Bill-to Address 2";
        Floor := '';
        AddressLocation := SalesCrMemoHeader."Bill-to City";
        City := SalesCrMemoHeader."Bill-to City";
        //PostCode := CopyStr(SalesCrMemoHeader."Bill-to Post Code", 1, 6);
        IF SalesCrMemoHeader."GST Customer Type" = "GST Customer Type"::Export THEN
            CountryCodeOfExport := COPYSTR(SalesCrMemoHeader."Bill-to Country/Region Code", 1, 3)
        ELSE
            IF NOT EVALUATE(Pin, COPYSTR(SalesCrMemoHeader."Bill-to Post Code", 1, 6)) THEN ERROR(PinCodeErr, SalesCrMemoHeader."No.", SalesCrMemoHeader."Bill-to Post Code");
        // IF NOT EVALUATE(Pin, COPYSTR(LocationBuff."Post Code", 1, 6)) THEN
        //     ERROR(PinCodeErr, SalesCrMemoHeader."No.", LocationBuff."Post Code");
        IF SalesCrMemoHeader."GST Customer Type" = "GST Customer Type"::Export THEN
            Pin := 999999;
        StateCode := '';
        PhoneNumber := '';
        Email := '';
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        SalesCrMemoLine.Setfilter("No.", '<>%1', '');
        if SalesCrMemoLine.FindFirst() then
            case SalesCrMemoLine."GST Place of Supply" of
                SalesCrMemoLine."GST Place of Supply"::"Bill-to Address":
                    begin
                        if not (SalesCrMemoHeader."GST Customer Type" = SalesCrMemoHeader."GST Customer Type"::Export) then begin
                            StateBuff.Get(SalesCrMemoHeader."GST Bill-to State Code");
                            // StateCode := StateBuff."State Code (GST Reg. No.)";
                            StateCode := StateBuff."State Code (GST Reg. No.)";
                            POS := FORMAT(StateBuff."State Code (GST Reg. No.)");
                        end
                        else begin
                            POS := POSForExportTxt;
                            StateCode := '96';
                        end;
                        if Contact.Get(SalesCrMemoHeader."Bill-to Contact No.") then begin
                            PhoneNumber := CopyStr(Contact."Phone No.", 1, 10);
                            Email := CopyStr(Contact."E-Mail", 1, 50);
                        end;
                    end;
                SalesCrMemoLine."GST Place of Supply"::"Ship-to Address":
                    begin
                        if not (SalesCrMemoHeader."GST Customer Type" = SalesCrMemoHeader."GST Customer Type"::Export) then begin
                            StateBuff.Get(SalesCrMemoHeader."GST Ship-to State Code");
                            //StateCode := StateBuff."State Code (GST Reg. No.)";
                            StateCode := StateBuff."State Code (GST Reg. No.)";
                            POS := FORMAT(StateBuff."State Code (GST Reg. No.)");
                        end
                        else begin
                            POS := POSForExportTxt;
                            StateCode := '96';



                        end;
                        if ShiptoAddress.Get(SalesCrMemoHeader."Sell-to Customer No.", SalesCrMemoHeader."Ship-to Code") then begin
                            PhoneNumber := CopyStr(ShiptoAddress."Phone No.", 1, 10);
                            Email := CopyStr(ShiptoAddress."E-Mail", 1, 50);
                            IF SalesCrMemoHeader."GST Customer Type" = "GST Customer Type"::Export THEN CountryCodeOfExport := COPYSTR(ShipToAddress."Country/Region Code", 1, 3);
                        end;
                    end;
                SalesCrMemoLine."GST Place of Supply"::"Location Address":
                    begin
                        if not (SalesCrMemoHeader."GST Customer Type" = SalesCrMemoHeader."GST Customer Type"::Export) then begin
                            if SalesCrMemoHeader."Ship-to Code" = '' then begin
                                StateBuff.Get(SalesCrMemoHeader."GST Bill-to State Code");
                                StateCode := StateBuff."State Code (GST Reg. No.)";
                                LocationBuff.Get(SalesCrMemoHeader."Location Code");
                                StateBuff.get(LocationBuff."State Code");
                                Pos := StateBuff."State Code (GST Reg. No.)";
                            end;
                            if SalesCrMemoHeader."Ship-to Code" <> '' then begin
                                StateBuff.Get(SalesCrMemoHeader."GST Ship-to State Code");
                                StateCode := StateBuff."State Code (GST Reg. No.)";
                                LocationBuff.Get(SalesCrMemoHeader."Location Code");
                                StateBuff.get(LocationBuff."State Code");
                                Pos := StateBuff."State Code (GST Reg. No.)";
                            end;
                        end;
                        if Contact.Get(SalesCrMemoHeader."Bill-to Contact No.") then begin
                            PhoneNumber := CopyStr(Contact."Phone No.", 1, 10);
                            Email := CopyStr(Contact."E-Mail", 1, 50);
                        end;
                    end;
            end;
        if AddressLocation = '' Then
            AddressLocation := Address;

        IF SalesCrMemoHeader.State = 'OT' then begin
            StateBuff.Get(SalesCrMemoHeader.State);
            Pos := StateBuff."State Code (GST Reg. No.)";
        end;

        WriteBuyerDetails(GSTRegistrationNumber, CompanyName, Address, Address2, Floor, AddressLocation, City, PostCode, StateCode, PhoneNumber, Email, Pos, pin);
    end;

    local procedure WriteBuyerDetails(GSTRegistrationNumber: Text[20];
    CompanyName: Text[100];
    Address: Text[100];
    Address2: Text[100];
    Floor: Text[60];
    AddressLocation: Text[100];
    City: Text[60];
    PostCode: Text[6];
    StateCode: Text[10];
    PhoneNumber: Text[10];
    EmailID: Text[50];
    Pos: Code[2];
    pin: integer)
    var
        JBuyerDetails: JsonObject;
    begin
        // JBuyerDetails.Add('Gstin', GSTRegistrationNumber);
        // JBuyerDetails.Add('TrdNm', CompanyName);
        // JBuyerDetails.Add('Bno', Address);
        // JBuyerDetails.Add('Bnm', Address2);
        // JBuyerDetails.Add('Flno', Floor);
        // JBuyerDetails.Add('Loc', AddressLocation);
        // JBuyerDetails.Add('Dst', City);
        // JBuyerDetails.Add('Pin', PostCode);
        // JBuyerDetails.Add('Stcd', StateCode);
        // JBuyerDetails.Add('Ph', PhoneNumber);
        // JBuyerDetails.Add('Em', EmailID);
        // // JsonArrayData.Add(JBuyerDetails);
        // // JObject.Add('BuyerDtls', JsonArrayData);
        // JObject.Add('BuyerDtls', JBuyerDetails);
        jt.AsValue().SetValueToNull();
        JBuyerDetails.Add('Gstin', GSTRegistrationNumber);
        JBuyerDetails.Add('LglNm', CompanyName);
        JBuyerDetails.Add('TrdNm', CompanyName);
        JBuyerDetails.Add('Pos', Pos);
        JBuyerDetails.Add('Addr1', Address);
        JBuyerDetails.Add('Addr2', Address2);
        JBuyerDetails.Add('Loc', AddressLocation);
        JBuyerDetails.Add('Pin', pin);
        IF StateCode <> '' then
            JBuyerDetails.Add('Stcd', StateCode)
        else
            JBuyerDetails.Add('Stcd', jt);
        IF PhoneNumber <> '' then
            JBuyerDetails.Add('Ph', PhoneNumber)
        else
            JBuyerDetails.Add('Ph', jt);
        IF EmailID <> '' then
            JBuyerDetails.Add('Em', EmailID)
        else
            JBuyerDetails.Add('Em', Jt);
        JObject.Add('BuyerDtls', JBuyerDetails);
        //    "Gstin": "29AWGPV7107B1Z1",
        //     "LglNm": "Xyz Pvt Ltd",
        //     "TrdNm": "Xyz Pvt Ltd",
        //     "Pos": "29",
        //     "Addr1": "7th block, kuvempu layout",
        //     "Addr2": "kuvempu layout",
        //     "Loc": "GandhiNagar",
        //     "Pin": 562160,
        //     "Stcd": "29",
        //     "Ph": null,
        //     "Em": null
    end;

    local procedure ReadDocumentShippingDetails()
    var
        ShiptoAddress: Record "Ship-to Address";
        StateBuff: Record State;
        GSTRegistrationNumber: Text[20];
        CompanyName: Text[100];
        Address: Text[100];
        Address2: Text[100];
        Floor: Text[60];
        AddressLocation: Text[60];
        City: Text[60];
        PostCode: Text[6];
        StateCode: Text[10];
        PhoneNumber: Text[10];
        EmailID: Text[50];
        LglNm: Text[100];
    begin
        Clear(JsonArrayData);
        if IsInvoice and (SalesInvoiceHeader."Ship-to Code" <> '') then begin
            ShiptoAddress.Get(SalesInvoiceHeader."Sell-to Customer No.", SalesInvoiceHeader."Ship-to Code");
            if SalesInvoiceHeader."GST Customer Type" in [SalesInvoiceHeader."GST Customer Type"::Export, SalesInvoiceHeader."GST Customer Type"::"Deemed Export"] then begin
                StateCode := '96';
                PostCode := '999999';
                GSTRegistrationNumber := 'URP';

            end else begin
                GSTRegistrationNumber := ShiptoAddress."GST Registration No.";
                StateBuff.Get(SalesInvoiceHeader."GST Ship-to State Code");
                StateCode := StateBuff."State Code (GST Reg. No.)";
                PostCode := CopyStr(SalesInvoiceHeader."Ship-to Post Code", 1, 6);
            end;

            CompanyName := SalesInvoiceHeader."Ship-to Name";
            Address := SalesInvoiceHeader."Ship-to Address";
            Address2 := SalesInvoiceHeader."Ship-to Address 2";
            City := SalesInvoiceHeader."Ship-to City";


            Floor := '';
            AddressLocation := City;

            PhoneNumber := CopyStr(ShiptoAddress."Phone No.", 1, 10);
            EmailID := CopyStr(ShiptoAddress."E-Mail", 1, 50);
            LglNm := SalesInvoiceHeader."Ship-to Name";
            WriteShippingDetails(GSTRegistrationNumber, CompanyName, Address, Address2, Floor, AddressLocation, City, PostCode, StateCode, PhoneNumber, EmailID, LglNm);
        end
        else
            if SalesCrMemoHeader."Ship-to Code" <> '' then begin
                ShiptoAddress.Get(SalesCrMemoHeader."Sell-to Customer No.", SalesCrMemoHeader."Ship-to Code");
                StateBuff.Get(SalesCrMemoHeader."GST Ship-to State Code");
                CompanyName := SalesCrMemoHeader."Ship-to Name";
                Address := SalesCrMemoHeader."Ship-to Address";
                Address2 := SalesCrMemoHeader."Ship-to Address 2";
                City := SalesCrMemoHeader."Ship-to City";
                PostCode := CopyStr(SalesCrMemoHeader."Ship-to Post Code", 1, 6);
                GSTRegistrationNumber := ShiptoAddress."GST Registration No.";
                Floor := '';
                AddressLocation := '';
                StateCode := StateBuff."State Code (GST Reg. No.)";
                PhoneNumber := CopyStr(ShiptoAddress."Phone No.", 1, 10);
                EmailID := CopyStr(ShiptoAddress."E-Mail", 1, 50);
                LglNm := SalesCrMemoHeader."Ship-to Name";
                WriteShippingDetails(GSTRegistrationNumber, CompanyName, Address, Address2, Floor, AddressLocation, City, PostCode, StateCode, PhoneNumber, EmailID, LglNm);
            end;
        // GSTRegistrationNumber := ShiptoAddress."GST Registration No.";
        // Floor := '';
        // AddressLocation := '';
        // StateCode := StateBuff."State Code (GST Reg. No.)";
        // PhoneNumber := CopyStr(ShiptoAddress."Phone No.", 1, 10);
        // EmailID := CopyStr(ShiptoAddress."E-Mail", 1, 50);
        // WriteShippingDetails(GSTRegistrationNumber, CompanyName, Address, Address2, Floor, AddressLocation, City, PostCode, StateCode, PhoneNumber, EmailID);
    end;

    local procedure WriteShippingDetails(GSTRegistrationNumber: Text[20];
    CompanyName: Text[100];
    Address: Text[100];
    Address2: Text[100];
    Floor: Text[60];
    AddressLocation: Text[60];
    City: Text[60];
    PostCode: Text[6];
    StateCode: Text[10];
    PhoneNumber: Text[10];
    EmailID: Text[50];
    LglNm: Text[100])
    var
        JShippingDetails: JsonObject;
    begin
        JShippingDetails.Add('Gstin', GSTRegistrationNumber);
        JShippingDetails.Add('LglNm', LglNm);
        JShippingDetails.Add('TrdNm', CompanyName);
        JShippingDetails.Add('Addr1', Address);
        JShippingDetails.Add('Addr2', Address2);
        JShippingDetails.Add('Loc', AddressLocation);
        JShippingDetails.Add('Pin', PostCode);
        JShippingDetails.Add('Stcd', StateCode);
        // JsonArrayData.Add(JShippingDetails);
        // JObject.Add('ShipDtls', JsonArrayData);
        JObject.Add('ShipDtls', JShippingDetails);
    end;

    local procedure ReadDocumentTotalDetails()
    var
        AssessableAmount: Decimal;
        CGSTAmount: Decimal;
        SGSTAmount: Decimal;
        IGSTAmount: Decimal;
        CessAmount: Decimal;
        StateCessAmount: Decimal;
        CESSNonAvailmentAmount: Decimal;
        DiscountAmount: Decimal;
        OtherCharges: Decimal;
        TotalInvoiceValue: Decimal;
    begin
        Clear(JsonArrayData);
        GetGSTValue(AssessableAmount, CGSTAmount, SGSTAmount, IGSTAmount, CessAmount, StateCessAmount, CESSNonAvailmentAmount, DiscountAmount, OtherCharges, TotalInvoiceValue);
        WriteDocumentTotalDetails(AssessableAmount, CGSTAmount, SGSTAmount, IGSTAmount, CessAmount, StateCessAmount, CESSNonAvailmentAmount, DiscountAmount, OtherCharges, TotalInvoiceValue);
    end;

    local procedure WriteDocumentTotalDetails(AssessableAmount: Decimal;
    CGSTAmount: Decimal;
    SGSTAmount: Decimal;
    IGSTAmount: Decimal;
    CessAmount: Decimal;
    StateCessAmount: Decimal;
    CessNonAdvanceVal: Decimal;
    DiscountAmount: Decimal;
    OtherCharges: Decimal;
    TotalInvoiceAmount: Decimal)
    var
        JDocTotalDetails: JsonObject;
    begin
        // JDocTotalDetails.Add('Assval', AssessableAmount);
        // JDocTotalDetails.Add('CgstVal', CGSTAmount);
        // JDocTotalDetails.Add('SgstVAl', SGSTAmount);
        // JDocTotalDetails.Add('IgstVal', IGSTAmount);
        // JDocTotalDetails.Add('CesVal', CessAmount);
        // JDocTotalDetails.Add('StCesVal', StateCessAmount);
        // JDocTotalDetails.Add('CesNonAdVal', CessNonAdvanceVal);
        // JDocTotalDetails.Add('Disc', DiscountAmount);
        // JDocTotalDetails.Add('OthChrg', OtherCharges);
        // JDocTotalDetails.Add('TotInvVal', TotalInvoiceAmount);
        // // JsonArrayData.Add(JDocTotalDetails);
        // // JObject.Add('ValDtls', JsonArrayData);
        JDocTotalDetails.Add('AssVal', AssessableAmount);
        JDocTotalDetails.Add('CgstVal', CGSTAmount);
        JDocTotalDetails.Add('SgstVal', SGSTAmount);
        JDocTotalDetails.Add('IgstVal', IGSTAmount);
        JDocTotalDetails.Add('CesVal', CessAmount);
        JDocTotalDetails.Add('StCesVal', 0);
        JDocTotalDetails.Add('Discount', DiscountAmount);
        JDocTotalDetails.Add('RndOffAmt', 0.0);
        JDocTotalDetails.Add('TotInvVal', AssessableAmount + CGSTAmount + IGSTAmount + SGSTAmount + CessAmount - DiscountAmount);
        // JDocTotalDetails.Add('TotInvVal', TotalInvoiceAmount);
        JDocTotalDetails.Add('TotiInvValFc', TotalInvoiceAmount);
        JObject.Add('ValDtls', JDocTotalDetails);
        TcsObject.add('transaction', JObject);
        TcsJsonArray.Add(TcsObject);
        // "AssVal": 4900.0,
        // "CgstVal": 0.0,
        // "SgstVal": 0.0,
        // "IgstVal": 1372.0,
        // "CesVal": 0.0,
        // "StCesVal": 0.0,
        // "Discount": 0.0,
        // "RndOffAmt": 0.0,
        // "TotInvVal": 6272.0,
        // "TotiInvValFc": 6272.0
    end;

    local procedure ReadDocumentItemList()
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        AssessableAmount: Decimal;
        CGSTRate: Decimal;
        SGSTRate: Decimal;
        IGSTRate: Decimal;
        CessRate: Decimal;
        CesNonAdval: Decimal;
        StateCess: Decimal;
        FreeQuantity: Decimal;
        CGSTValue: Decimal;
        SGSTValue: Decimal;
        IGSTValue: Decimal;
        SlNo: Integer;
        IsServc: Text[1];
    begin
        Clear(JsonArrayData);
        CLEAR(SlNo);
        if IsInvoice then begin
            SalesInvoiceLine.SetRange("Document No.", DocumentNo);
            SalesInvoiceLine.SETRANGE("Non-GST Line", FALSE);
            SalesInvoiceLine.SETFILTER("GST Group Code", '<>%1', '');
            SalesInvoiceLine.SETFILTER("HSN/SAC Code", '<>%1', '');
            SalesInvoiceLine.SETFILTER(Quantity, '<>%1', 0);
            if SalesInvoiceLine.FindSet() then begin
                if SalesInvoiceLine.Count > 100 then Error(SalesLinesMaxCountLimitErr, SalesInvoiceLine.Count);
                repeat
                    SlNo += 1;
                    if SalesInvoiceLine."GST Assessable Value (LCY)" <> 0 then
                        AssessableAmount := SalesInvoiceLine."GST Assessable Value (LCY)"
                    else
                        AssessableAmount := SalesInvoiceLine.Amount;
                    FreeQuantity := 0;
                    GetGSTComponentRate(SalesInvoiceLine."Document No.", SalesInvoiceLine."Line No.", CGSTRate, SGSTRate, IGSTRate, CessRate, CesNonAdval, StateCess);
                    IF SalesInvoiceLine."GST Group Type" = SalesInvoiceLine."GST Group Type"::Service THEN
                        IsServc := 'Y'
                    ELSE
                        IsServc := 'N';
                    GetGSTValueForLine(SalesInvoiceLine."Line No.", CGSTValue, SGSTValue, IGSTValue);
                    WriteItem(SalesInvoiceLine.Description + SalesInvoiceLine."Description 2", '', SalesInvoiceLine."HSN/SAC Code", '', SalesInvoiceLine.Quantity, FreeQuantity, CopyStr(SalesInvoiceLine."Unit of Measure Code", 1, 3), SalesInvoiceLine."Unit Price", SalesInvoiceLine."Line Amount" + SalesInvoiceLine."Line Discount Amount", SalesInvoiceLine."Line Discount Amount", 0, AssessableAmount, CGSTRate, SGSTRate, IGSTRate, CessRate, CesNonAdval, StateCess, AssessableAmount, CGSTValue, SGSTValue, IGSTValue, SlNo, IsServc);
                until SalesInvoiceLine.Next() = 0;
            end;
            JObject.Add('ItemList', JsonArrayData);
        end
        else begin
            SalesCrMemoLine.SetRange("Document No.", DocumentNo);
            SalesCrMemoLine.SETRANGE("Non-GST Line", FALSE);
            SalesCrMemoLine.SETFILTER("GST Group Code", '<>%1', '');
            SalesCrMemoLine.SETFILTER("HSN/SAC Code", '<>%1', '');
            SalesCrMemoLine.SETFILTER(Quantity, '<>%1', 0);
            if SalesCrMemoLine.FindSet() then begin
                if SalesCrMemoLine.Count > 100 then Error(SalesLinesMaxCountLimitErr, SalesCrMemoLine.Count);
                repeat
                    SlNo += 1;
                    if SalesCrMemoLine."GST Assessable Value (LCY)" <> 0 then
                        AssessableAmount := SalesCrMemoLine."GST Assessable Value (LCY)"
                    else
                        AssessableAmount := SalesCrMemoLine.Amount;
                    FreeQuantity := 0;
                    GetGSTComponentRate(SalesCrMemoLine."Document No.", SalesCrMemoLine."Line No.", CGSTRate, SGSTRate, IGSTRate, CessRate, CesNonAdval, StateCess);
                    IF SalesCrMemoLine."GST Group Type" = SalesCrMemoLine."GST Group Type"::Service THEN
                        IsServc := 'Y'
                    ELSE
                        IsServc := 'N';
                    GetGSTValueForLine(SalesCrMemoLine."Line No.", CGSTValue, SGSTValue, IGSTValue);
                    WriteItem(SalesCrMemoLine.Description + SalesCrMemoLine."Description 2", '', SalesCrMemoLine."HSN/SAC Code", '', SalesCrMemoLine.Quantity, FreeQuantity, CopyStr(SalesCrMemoLine."Unit of Measure Code", 1, 3), SalesCrMemoLine."Unit Price", SalesCrMemoLine."Line Amount" + SalesCrMemoLine."Line Discount Amount", SalesCrMemoLine."Line Discount Amount", 0, AssessableAmount, CGSTRate, SGSTRate, IGSTRate, CessRate, CesNonAdval, StateCess, AssessableAmount, CGSTValue, SGSTValue, IGSTValue, SlNo, IsServc);
                until SalesCrMemoLine.Next() = 0;
            end;
            JObject.Add('ItemList', JsonArrayData);
        end;
    end;

    local procedure WriteItem(ProductName: Text;
    ProductDescription: Text;
    HSNCode: Text[10];
    BarCode: Text[30];
    Quantity: Decimal;
    FreeQuantity: Decimal;
    Unit: Text[3];
    UnitPrice: Decimal;
    TotAmount: Decimal;
    Discount: Decimal;
    OtherCharges: Decimal;
    AssessableAmount: Decimal;
    CGSTRate: Decimal;
    SGSTRate: Decimal;
    IGSTRate: Decimal;
    CESSRate: Decimal;
    CessNonAdvanceAmount: Decimal;
    StateCess: Decimal;
    TotalItemValue: Decimal;
    CGSTValue: Decimal;
    SGSTValue: Decimal;
    IGSTValue: Decimal;
    SlNo: Integer;
    IsServc: Text[1])
    var
        JItem: JsonObject;
    begin
        jt.AsValue().SetValueToNull();
        // JItem.Add('PrdNm', ProductName);
        // JItem.Add('PrdDesc', ProductDescription);
        // JItem.Add('HsnCd', HSNCode);
        // JItem.Add('Barcde', BarCode);
        // JItem.Add('Qty', Quantity);
        // JItem.Add('FreeQty', FreeQuantity);
        // JItem.Add('Unit', Unit);
        // JItem.Add('UnitPrice', UnitPrice);
        // JItem.Add('TotAmt', TotAmount);
        // JItem.Add('Discount', Discount);
        // JItem.Add('OthChrg', OtherCharges);
        // JItem.Add('AssAmt', AssessableAmount);
        // JItem.Add('CgstRt', CGSTRate);
        // JItem.Add('SgstRt', SGSTRate);
        // JItem.Add('IgstRt', IGSTRate);
        // JItem.Add('CesRt', CESSRate);
        // JItem.Add('CesNonAdval', CessNonAdvanceAmount);
        // JItem.Add('StateCes', StateCess);
        // JItem.Add('TotItemVal', TotalItemValue);
        // JsonArrayData.Add(JItem);
        JItem.Add('SlNo', SlNo);
        JItem.Add('PrdDesc', ProductName);
        JItem.Add('IsServc', IsServc);
        JItem.Add('HsnCd', HSNCode);
        JItem.Add('Barcde', jt);
        JItem.Add('Qty', Quantity);
        JItem.Add('FreeQty', FreeQuantity);
        JItem.Add('Unit', Unit);
        JItem.Add('UnitPrice', round(UnitPrice * CurrRate, 0.01, '='));
        JItem.Add('TotAmt', round(TotAmount * CurrRate, 0.01, '='));
        JItem.Add('Discount', round(Discount * CurrRate, 0.01, '='));
        JItem.Add('PreTaxVal', 0);
        JItem.Add('AssAmt', round(AssessableAmount * CurrRate, 0.01, '='));
        JItem.Add('GstRt', CGSTRate + SGSTRate + IGSTRate);
        JItem.Add('IgstAmt', IGSTValue);
        JItem.Add('CgstAmt', CGSTValue);
        JItem.Add('SgstAmt', SGSTValue);
        JItem.Add('CesRt', CESSRate);
        JItem.Add('CesAmt', CessNonAdvanceAmount);
        JItem.Add('CesNonAdval', CessNonAdvanceAmount);
        JItem.Add('StateCesRt', StateCess);
        JItem.Add('StateCes', StateCess);
        JItem.Add('StateCesNonAdvlAmt', StateCess);
        JItem.Add('OthChrg', OtherCharges);
        JItem.Add('TotItemVal', round(TotalItemValue * CurrRate, 0.01, '=') + (IGSTValue + CGSTValue + SGSTValue));
        JItem.Add('OrdLineRef', jt);
        JItem.Add('OrgCntry', jt);
        JItem.Add('PrdSlNo', jt);
        JsonArrayData.Add(JItem);
        //  "SlNo": "1",
        //   "PrdDesc": "Bicycle",
        //   "IsServc": "N",
        //   "HsnCd": "8707",
        //   "Barcde": null,
        //   "Qty": 1.0,
        //   "FreeQty": 0.0,
        //   "Unit": "PCS",
        //   "UnitPrice": 5000.0,
        //   "TotAmt": 5000.0,
        //   "Discount": 100.0,
        //   "PreTaxVal": 0.0,
        //   "AssAmt": 4900.0,
        //   "GstRt": 28.0,
        //   "IgstAmt": 1372.0,
        //   "CgstAmt": 0.0,
        //   "SgstAmt": 0.0,
        //   "CesRt": 0.0,
        //   "CesAmt": 0.0,
        //   "CesNonAdvlAmt": 0.0,
        //   "StateCesRt": 0.0,
        //   "StateCesAmt": 0.0,
        //   "StateCesNonAdvlAmt": 0.0,
        //   "OthChrg": 0,
        //   "TotItemVal": 6272.0,
        //   "OrdLineRef": null,
        //   "OrgCntry": null,
        //   "PrdSlNo": null
    end;

    local procedure ExportAsJson(FileName: Text[20])
    var
        TempBlob: Codeunit "Temp Blob";
        ToFile: Variant;
        InStream: InStream;
        OutStream: OutStream;
    begin
        // JObject.Add('transaction', JObject);
        //  JObject.WriteTo(JsonText);
        TcsJsonArray.WriteTo(JsonText);
        TempBlob.CreateOutStream(OutStream);
        OutStream.WriteText(JsonText);
        ToFile := FileName + '.json';
        TempBlob.CreateInStream(InStream);
        DownloadFromStream(InStream, 'e-Invoice', '', '', ToFile);
    end;

    local procedure GetReferenceInvoiceNo(DocNo: Code[20]) RefInvNo: Code[20]
    var
        ReferenceInvoiceNo: Record "Reference Invoice No.";
    begin
        ReferenceInvoiceNo.SetRange("Document No.", DocNo);
        if ReferenceInvoiceNo.FindFirst() then
            RefInvNo := ReferenceInvoiceNo."Reference Invoice Nos."
        else
            RefInvNo := '';
    end;

    local procedure GetGSTComponentRate(DocumentNo: Code[20];
    LineNo: Integer;
    var CGSTRate: Decimal;
    var SGSTRate: Decimal;
    var IGSTRate: Decimal;
    var CessRate: Decimal;
    var CessNonAdvanceAmount: Decimal;
    var StateCess: Decimal)
    var
        DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
    begin
        DetailedGSTLedgerEntry.SetRange("Document No.", DocumentNo);
        DetailedGSTLedgerEntry.SetRange("Document Line No.", LineNo);
        DetailedGSTLedgerEntry.SetRange("GST Component Code", CGSTLbl);
        if DetailedGSTLedgerEntry.FindFirst() then
            CGSTRate := DetailedGSTLedgerEntry."GST %"
        else
            CGSTRate := 0;
        DetailedGSTLedgerEntry.SetRange("GST Component Code", SGSTLbl);
        if DetailedGSTLedgerEntry.FindFirst() then
            SGSTRate := DetailedGSTLedgerEntry."GST %"
        else
            SGSTRate := 0;
        DetailedGSTLedgerEntry.SetRange("GST Component Code", IGSTLbl);
        if DetailedGSTLedgerEntry.FindFirst() then
            IGSTRate := DetailedGSTLedgerEntry."GST %"
        else
            IGSTRate := 0;
        CessRate := 0;
        CessNonAdvanceAmount := 0;
        DetailedGSTLedgerEntry.SetRange("GST Component Code", CESSLbl);
        if DetailedGSTLedgerEntry.FindFirst() then
            if DetailedGSTLedgerEntry."GST %" > 0 then
                CessRate := DetailedGSTLedgerEntry."GST %"
            else
                CessNonAdvanceAmount := Abs(DetailedGSTLedgerEntry."GST Amount");
        StateCess := 0;
        DetailedGSTLedgerEntry.SetRange("GST Component Code");
        if DetailedGSTLedgerEntry.FindSet() then
            repeat
                if not (DetailedGSTLedgerEntry."GST Component Code" in [CGSTLbl, SGSTLbl, IGSTLbl, CESSLbl]) then StateCess := DetailedGSTLedgerEntry."GST %";
            until DetailedGSTLedgerEntry.Next() = 0;
    end;

    local procedure GetGSTValue(var AssessableAmount: Decimal;
    var CGSTAmount: Decimal;
    var SGSTAmount: Decimal;
    var IGSTAmount: Decimal;
    var CessAmount: Decimal;
    var StateCessValue: Decimal;
    var CessNonAdvanceAmount: Decimal;
    var DiscountAmount: Decimal;
    var OtherCharges: Decimal;
    var TotalInvoiceValue: Decimal)
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        GSTLedgerEntry: Record "GST Ledger Entry";
        DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TotGSTAmt: Decimal;
        Customers: Record Customer;
    begin
        GSTLedgerEntry.SetRange("Document No.", DocumentNo);
        GSTLedgerEntry.SetRange("GST Component Code", CGSTLbl);
        if GSTLedgerEntry.FindSet() then
            repeat
                CGSTAmount += Abs(GSTLedgerEntry."GST Amount");
            until GSTLedgerEntry.Next() = 0
        else
            CGSTAmount := 0;
        GSTLedgerEntry.SetRange("GST Component Code", SGSTLbl);
        if GSTLedgerEntry.FindSet() then
            repeat SGSTAmount += Abs(GSTLedgerEntry."GST Amount") until GSTLedgerEntry.Next() = 0
        else
            SGSTAmount := 0;
        GSTLedgerEntry.SetRange("GST Component Code", IGSTLbl);
        if GSTLedgerEntry.FindSet() then
            repeat IGSTAmount += Abs(GSTLedgerEntry."GST Amount") until GSTLedgerEntry.Next() = 0
        else
            IGSTAmount := 0;
        CessAmount := 0;
        CessNonAdvanceAmount := 0;
        DetailedGSTLedgerEntry.SetRange("Document No.", DocumentNo);
        DetailedGSTLedgerEntry.SetRange("GST Component Code", CESSLbl);
        if DetailedGSTLedgerEntry.FindFirst() then
            repeat
                if DetailedGSTLedgerEntry."GST %" > 0 then
                    CessAmount += Abs(DetailedGSTLedgerEntry."GST Amount")
                else
                    CessNonAdvanceAmount += Abs(DetailedGSTLedgerEntry."GST Amount");
            until DetailedGSTLedgerEntry.Next() = 0;
        // GSTLedgerEntry.SetFilter("GST Component Code", '<>CGST|<>SGST|<>IGST|<>CESS');
        // if GSTLedgerEntry.FindSet() then
        //     repeat
        //         StateCessValue += Abs(GSTLedgerEntry."GST Amount");
        //     until GSTLedgerEntry.Next() = 0;
        if IsInvoice then begin
            SalesInvoiceLine.SetRange("Document No.", DocumentNo);
            if SalesInvoiceLine.FindSet() then
                repeat
                    AssessableAmount += SalesInvoiceLine.Amount;
                    DiscountAmount += SalesInvoiceLine."Inv. Discount Amount";
                until SalesInvoiceLine.Next() = 0;
            TotGSTAmt := CGSTAmount + SGSTAmount + IGSTAmount + CessAmount + CessNonAdvanceAmount + StateCessValue;
            AssessableAmount := Round(CurrencyExchangeRate.ExchangeAmtFCYToLCY(WorkDate(), SalesInvoiceHeader."Currency Code", AssessableAmount, SalesInvoiceHeader."Currency Factor"), 0.01, '=');
            // TotGSTAmt := Round(
            //     CurrencyExchangeRate.ExchangeAmtFCYToLCY(
            //       WorkDate(), SalesInvoiceHeader."Currency Code", TotGSTAmt, SalesInvoiceHeader."Currency Factor"), 0.01, '=');
            DiscountAmount := Round(CurrencyExchangeRate.ExchangeAmtFCYToLCY(WorkDate(), SalesInvoiceHeader."Currency Code", DiscountAmount, SalesInvoiceHeader."Currency Factor"), 0.01, '=');
            TotalInvoiceValue := AssessableAmount + TotGSTAmt + OtherCharges - DiscountAmount;
        end
        else begin
            SalesCrMemoLine.SetRange("Document No.", DocumentNo);
            if SalesCrMemoLine.FindSet() then begin
                repeat
                    AssessableAmount += SalesCrMemoLine.Amount;
                    DiscountAmount += SalesCrMemoLine."Inv. Discount Amount";
                until SalesCrMemoLine.Next() = 0;
                TotGSTAmt := CGSTAmount + SGSTAmount + IGSTAmount + CessAmount + CessNonAdvanceAmount + StateCessValue;
            end;
            AssessableAmount := Round(CurrencyExchangeRate.ExchangeAmtFCYToLCY(WorkDate(), SalesCrMemoHeader."Currency Code", AssessableAmount, SalesCrMemoHeader."Currency Factor"), 0.01, '=');
            TotGSTAmt := Round(CurrencyExchangeRate.ExchangeAmtFCYToLCY(WorkDate(), SalesCrMemoHeader."Currency Code", TotGSTAmt, SalesCrMemoHeader."Currency Factor"), 0.01, '=');
            DiscountAmount := Round(CurrencyExchangeRate.ExchangeAmtFCYToLCY(WorkDate(), SalesCrMemoHeader."Currency Code", DiscountAmount, SalesCrMemoHeader."Currency Factor"), 0.01, '=');
            TotalInvoiceValue := AssessableAmount + TotGSTAmt + OtherCharges - DiscountAmount;
        end;
        CustLedgerEntry.SetCurrentKey("Document No.");
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        if IsInvoice then begin
            CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
            CustLedgerEntry.SetRange("Customer No.", SalesInvoiceHeader."Bill-to Customer No.");
        end
        else begin
            CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::"Credit Memo");
            CustLedgerEntry.SetRange("Customer No.", SalesCrMemoHeader."Bill-to Customer No.");
        end;
        if CustLedgerEntry.FindFirst() then begin
            CustLedgerEntry.CalcFields("Amount (LCY)");
            Customers.get(CustLedgerEntry."Customer No.");
            if Customers."GST Customer Type" = Customers."GST Customer Type"::Export then begin
                if not IsInvoice then
                    TotalInvoiceValue := Abs(CustLedgerEntry."Amount (LCY)") + TotGSTAmt;
            end else
                TotalInvoiceValue := Abs(CustLedgerEntry."Amount (LCY)");
        end;
        OtherCharges := 0;
    end;

    local procedure GetGSTValueForLine(DocumentLineNo: Integer;
    var CGSTLineAmount: Decimal;
    var SGSTLineAmount: Decimal;
    var IGSTLineAmount: Decimal)
    var
        DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
    begin
        CGSTLineAmount := 0;
        SGSTLineAmount := 0;
        IGSTLineAmount := 0;
        DetailedGSTLedgerEntry.SetRange("Document No.", DocumentNo);
        DetailedGSTLedgerEntry.SetRange("Document Line No.", DocumentLineNo);
        DetailedGSTLedgerEntry.SetRange("GST Component Code", CGSTLbl);
        if DetailedGSTLedgerEntry.FindSet() then
            repeat
                CGSTLineAmount += Abs(DetailedGSTLedgerEntry."GST Amount");
            until DetailedGSTLedgerEntry.Next() = 0;
        DetailedGSTLedgerEntry.SetRange("GST Component Code", SGSTLbl);
        if DetailedGSTLedgerEntry.FindSet() then repeat SGSTLineAmount += Abs(DetailedGSTLedgerEntry."GST Amount") until DetailedGSTLedgerEntry.Next() = 0;
        DetailedGSTLedgerEntry.SetRange("GST Component Code", IGSTLbl);
        if DetailedGSTLedgerEntry.FindSet() then repeat IGSTLineAmount += Abs(DetailedGSTLedgerEntry."GST Amount") until DetailedGSTLedgerEntry.Next() = 0;
    end;

    procedure GenerateIRN(input: Text): Text
    var
        CryptographyManagement: Codeunit "Cryptography Management";
        HashAlgorithmType: Option MD5,SHA1,SHA256,SHA384,SHA512;
    begin
        exit(CryptographyManagement.GenerateHash(input, HashAlgorithmType::SHA256));
    end;

    var
        CurrRate: Decimal;
        GSTRegNo: Code[15];
        jt: JsonToken;
        TcsJsonArray: JsonArray;
        TcsObject: JsonObject;
        Codeunit70000: Codeunit ClearTaxEInvoice;
        PinCodeErr: Label 'Value in Pincode should be in Integer, incorrect value in %1 record, Value = %2.';
}
