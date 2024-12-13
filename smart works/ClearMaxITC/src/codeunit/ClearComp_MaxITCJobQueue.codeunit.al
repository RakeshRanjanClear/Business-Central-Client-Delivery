codeunit 60116 "ClearComp MaxITC Job Queue"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        ClearCompMaxITCMgmt: Codeunit "ClearComp MaxITC Management";
    begin
        if ClearCompMaxITCMgmt.CheckStatus(Rec."Parameter String") then
            ProcessReconFile(Rec."Parameter String")
        else
            Rec.Restart();
    end;

    var
        xPaymentAction: Code[20];

    local procedure ProcessReconFile(WorkFlowIDP: Text[250])
    var
        TransHeader: Record "ClearComp MaxITC Trans. Header";
        ReconData: Record "ClearComp MaxITC ReconResult";
        PaymentBlocking: Record "ClearComp MaxITC Payment block";
        ReconResults: Record "ClearComp ReconResults Blobs";
        InputText: BigText;
        I: Integer;
        InstreamL: InStream;
        JArray: JsonArray;
        JObject: JsonObject;
        JSubObject: JsonObject;
        JSubObject2: JsonObject;
        JToken: JsonToken;
        JToken2: JsonToken;
    begin
        TransHeader.SetRange(WorkFlowID, WorkFlowIDP);
        if TransHeader.FindFirst() then
            if ReconResults.Get(TransHeader."Document Type", TransHeader."Document No.") then begin
                ReconResults.CalcFields(ReconResults);
                ReconResults.ReconResults.CreateInStream(InstreamL);
                InputText.Read(InstreamL);

                if JArray.ReadFrom(Format(InputText)) then begin
                    for I := 0 to JArray.Count - 1 do begin
                        JArray.Get(I, JToken);
                        JObject := JToken.AsObject();
                        ReconData.Init();
                        if JObject.Contains('documentId') then
                            ReconData.DocumentID := GetValueFromJsonObject(JObject, 'documentId').AsText();
                        ReconData.WorkFlowID := WorkFlowIDP;
                        if JObject.Contains('matchingTaskId') then
                            ReconData.MatchingTaskID := GetValueFromJsonObject(JObject, 'matchingTaskId').AsText();
                        if JObject.Contains('username') then
                            ReconData.UserName := GetValueFromJsonObject(JObject, 'username').AsText();
                        //JSubObject := JSubObject.JObject;
                        if JObject.Get('pr', JToken) then begin
                            JSubObject := JToken.AsObject();
                            if GetValueFromJsonObject(JSubObject, 'documentReferenceNumber').IsNull then begin
                                Clear(JToken);
                                Clear(JSubObject);
                                if JObject.Get('govt', JToken) then begin
                                    JSubObject := JToken.AsObject();
                                    if JSubObject.Contains('documentReferenceNumber') then
                                        ReconData.ResponseFrom := ReconData.ResponseFrom::Govt;
                                end;
                            end;
                        end else
                            ReconData.ResponseFrom := ReconData.ResponseFrom::PR;
                        if JSubObject.Contains('documentReferenceNumber') then
                            ReconData.DocumentReferenceNo := GetValueFromJsonObject(JSubObject, 'documentReferenceNumber').AsText();
                        if JSubObject.Contains('cpGstin') then
                            ReconData.CpGSTIN := GetValueFromJsonObject(JSubObject, 'cpGstin').AsText();
                        if JSubObject.Contains('cpName') then
                            ReconData.CpName := GetValueFromJsonObject(JSubObject, 'cpName').AsText();
                        if JSubObject.Contains('cpPan') then
                            ReconData.CpPAN := GetValueFromJsonObject(JSubObject, 'cpPan').AsText();
                        if JSubObject.Contains('cpTradeName') then
                            ReconData.CpTradeName := GetValueFromJsonObject(JSubObject, 'cpTradeName').AsText();
                        if JSubObject.Contains('cpFilingFrequency') then
                            ReconData.CpFillingFrequency := GetValueFromJsonObject(JSubObject, 'cpFilingFrequency').AsText();
                        if JSubObject.Contains('cpGstinStatus') then
                            ReconData.CpGSTINStatus := GetValueFromJsonObject(JSubObject, 'cpGstinStatus').AsText();
                        if JSubObject.Contains('docDate') then
                            ReconData.DocDate := GetValueFromJsonObject(JSubObject, 'docDate').AsText();
                        if JSubObject.Contains('pos') then
                            ReconData.Pos := GetValueFromJsonObject(JSubObject, 'pos').AsText();
                        if JSubObject.Contains('igst') then
                            EVALUATE(ReconData.IGST, GetValueFromJsonObject(JSubObject, 'igst').AsText());
                        if JSubObject.Contains('cgst') then
                            EVALUATE(ReconData.CGST, GetValueFromJsonObject(JSubObject, 'cgst').AsText());
                        if JSubObject.Contains('sgst') then
                            EVALUATE(ReconData.SGST, GetValueFromJsonObject(JSubObject, 'sgst').AsText());
                        if JSubObject.Contains('cess') then
                            EVALUATE(ReconData.CESS, GetValueFromJsonObject(JSubObject, 'cess').AsText());
                        if JSubObject.Contains('documentId') then
                            ReconData.MatchingTaskID := GetValueFromJsonObject(JSubObject, 'documentId').AsText();
                        if JSubObject.Contains('taxableValue') then
                            EVALUATE(ReconData.TaxableValue, GetValueFromJsonObject(JSubObject, 'taxableValue').AsText());
                        if JSubObject.Contains('taxValue') then
                            EVALUATE(ReconData.TaxValue, GetValueFromJsonObject(JSubObject, 'taxValue').AsText());
                        if JSubObject.Contains('totalValue') then
                            EVALUATE(ReconData.TotalValue, GetValueFromJsonObject(JSubObject, 'totalValue').AsText());
                        if JSubObject.Contains('sectionName') then
                            ReconData.SectionName := GetValueFromJsonObject(JSubObject, 'sectionName').AsText();
                        if JSubObject.Contains('documentType') then
                            ReconData.DocumentType := GetValueFromJsonObject(JSubObject, 'documentType').AsText();
                        if JSubObject.Contains('returnPeriod') then
                            ReconData.ReturnPeriod := GetValueFromJsonObject(JSubObject, 'returnPeriod').AsText();
                        if JSubObject.Contains('fiscalYear') then
                            EVALUATE(ReconData.FiscalYear, GetValueFromJsonObject(JSubObject, 'fiscalYear').AsText());
                        if JSubObject.Contains('source') then
                            ReconData.Source := GetValueFromJsonObject(JSubObject, 'source').AsText();
                        if JSubObject.Contains('originalDocNumber') then
                            ReconData.OriginalDocNo := GetValueFromJsonObject(JSubObject, 'originalDocNumber').AsText();
                        if JSubObject.Contains('originalDocDate') then
                            ReconData.OriginalDocDate := GetValueFromJsonObject(JSubObject, 'originalDocDate').AsText();
                        if JSubObject.Contains('cpGstinCancellationDate') then
                            ReconData.CPGSTINCancelDate := GetValueFromJsonObject(JSubObject, 'cpGstinCancellationDate').AsText();
                        if JSubObject.Contains('reverseChargeApplicable') then
                            EVALUATE(ReconData.ReverseChargeApplicable, GetValueFromJsonObject(JSubObject, 'reverseChargeApplicable').AsText());
                        if JSubObject.Contains('myGstin') then
                            ReconData.MyGSTIN := GetValueFromJsonObject(JSubObject, 'myGstin').AsText();
                        if JSubObject.Contains('customFields') then
                            ReconData.CustomFields := GetValueFromJsonObject(JSubObject, 'customFields').AsText();
                        if JSubObject.Contains('dueDate') then
                            ReconData.DueDate := GetValueFromJsonObject(JSubObject, 'dueDate').AsText();
                        if JSubObject.Contains('vendorCode') then
                            ReconData.VendorCode := GetValueFromJsonObject(JSubObject, 'vendorCode').AsText();
                        if JSubObject.Contains('voucherNo') then
                            ReconData.VoucherNo := GetValueFromJsonObject(JSubObject, 'voucherNo').AsText();
                        if JSubObject.Contains('voucherDate') then
                            ReconData.VoucherDate := GetValueFromJsonObject(JSubObject, 'voucherDate').AsText();
                        if JSubObject.Contains('itcClaimEligibility') then
                            ReconData.ITCClaimEligibility := GetValueFromJsonObject(JSubObject, 'itcClaimEligibility').AsText();
                        if JSubObject.Contains('itcEligible') then
                            ReconData.ITCEligibile := GetValueFromJsonObject(JSubObject, 'itcEligible').AsText();
                        if JSubObject.Contains('paymentAction') then
                            ReconData.PaymentAction := GetValueFromJsonObject(JSubObject, 'paymentAction').AsText();
                        if JSubObject.Contains('counterpartFilingStatus') then
                            ReconData.CounterPartFillingStatus := GetValueFromJsonObject(JSubObject, 'counterpartFilingStatus').AsText();
                        if JSubObject.Contains('cpFilingStatus3b') then
                            ReconData.CpFillingStatus3B := GetValueFromJsonObject(JSubObject, 'cpFilingStatus3b').AsText();
                        if JSubObject.Contains('g1FilingDate') then
                            ReconData.G1FillingDate := GetValueFromJsonObject(JSubObject, 'g1FilingDate').AsText();
                        if JSubObject.Contains('g1FilingRp') then
                            ReconData.G1FillingRP := GetValueFromJsonObject(JSubObject, 'g1FilingRp').AsText();
                        if JSubObject.Contains('irn') then
                            ReconData.IRN := GetValueFromJsonObject(JSubObject, 'irn').AsText();
                        if JSubObject.Contains('irnGenerationDate') then
                            ReconData.IRNGenerationDate := GetValueFromJsonObject(JSubObject, 'irnGenerationDate').AsText();
                        if JSubObject.Contains('reason') then
                            ReconData.Reason := GetValueFromJsonObject(JSubObject, 'reason').AsText();
                        if JSubObject.Contains('generationSource') then
                            ReconData.GenerationSource := GetValueFromJsonObject(JSubObject, 'generationSource').AsText();
                        if JSubObject.Contains('documentSource') then
                            ReconData.DocumentSource := GetValueFromJsonObject(JSubObject, 'documentSource').AsText();
                        if JObject.Get('result', JToken2) then begin
                            JSubObject2 := JToken2.AsObject();
                            if JSubObject2.Contains('itcAction') then
                                ReconData.ResultITCAction := GetValueFromJsonObject(JSubObject2, 'itcAction').AsText();
                            if JSubObject2.Contains('gst3BClaimMonth') then
                                ReconData.ResultGST3BClaimMonth := GetValueFromJsonObject(JSubObject2, 'gst3BClaimMonth').AsText();
                            if JSubObject2.Contains('igstItc') and (GetValueFromJsonObject(JSubObject2, 'igstItc').AsText() > '') then
                                EVALUATE(ReconData.ResultIGSTITC, GetValueFromJsonObject(JSubObject2, 'igstItc').AsText());
                            if JSubObject2.Contains('cgstItc') and (GetValueFromJsonObject(JSubObject2, 'cgstItc').AsText() > '') then
                                EVALUATE(ReconData.ResultCGSTITC, GetValueFromJsonObject(JSubObject2, 'cgstItc').AsText());
                            if JSubObject2.Contains('sgstItc') and (GetValueFromJsonObject(JSubObject2, 'sgstItc').AsText() > '') then
                                EVALUATE(ReconData.ResultSGSTITC, GetValueFromJsonObject(JSubObject2, 'sgstItc').AsText());
                            if JSubObject2.Contains('cessItc') and (GetValueFromJsonObject(JSubObject2, 'cessItc').AsText() > '') then
                                EVALUATE(ReconData.ResultCESSITC, GetValueFromJsonObject(JSubObject2, 'cessItc').AsText());
                            if JSubObject2.Contains('totalItc') and (GetValueFromJsonObject(JSubObject2, 'totalItc').AsText() > '') then
                                EVALUATE(ReconData.ResultTotalITC, GetValueFromJsonObject(JSubObject2, 'totalItc').AsText());
                            if JSubObject2.Contains('taxableValue') and (GetValueFromJsonObject(JSubObject2, 'taxableValue').AsText() > '') then
                                EVALUATE(ReconData.ResultTaxableValue, GetValueFromJsonObject(JSubObject2, 'taxableValue').AsText());
                            if JSubObject2.Contains('supplierGstin') and (GetValueFromJsonObject(JSubObject2, 'supplierGstin').AsText() > '') then
                                ReconData.ResultSupplierGSTIN := GetValueFromJsonObject(JSubObject2, 'supplierGstin').AsText();
                            if JSubObject2.Contains('supplierName') and (GetValueFromJsonObject(JSubObject2, 'supplierName').AsText() > '') then
                                ReconData.ResultSupplierName := GetValueFromJsonObject(JSubObject2, 'supplierName').AsText();
                            if JSubObject2.Contains('documentType') and (GetValueFromJsonObject(JSubObject2, 'documentType').AsText() > '') then
                                ReconData.ResultDocumentType := GetValueFromJsonObject(JSubObject2, 'documentType').AsText();
                            if JSubObject2.Contains('matchingRequestType') and (GetValueFromJsonObject(JSubObject2, 'matchingRequestType').AsText() > '') then
                                ReconData.ResultMatchingRequestType := GetValueFromJsonObject(JSubObject2, 'matchingRequestType').AsText();
                            if JSubObject2.Contains('supplierFilingStatus') and (GetValueFromJsonObject(JSubObject2, 'supplierFilingStatus').AsText() > '') then
                                ReconData.ResultSupplierFillingStatus := GetValueFromJsonObject(JSubObject2, 'supplierFilingStatus').AsText();
                            if JSubObject2.Contains('misMatchFields') and (GetValueFromJsonObject(JSubObject2, 'misMatchFields').AsText() > '') then
                                ReconData.ResultMisMatchFields := CopyStr(GetValueFromJsonObject(JSubObject2, 'misMatchFields').AsText(), 1, MaxStrLen(ReconData.ResultMisMatchFields));
                            if JSubObject2.Contains('remark') and (GetValueFromJsonObject(JSubObject2, 'remark').AsText() > '') then
                                ReconData.Resultremark := GetValueFromJsonObject(JSubObject2, 'remark').AsText();
                            if JSubObject2.Contains('taxDifference') and (GetValueFromJsonObject(JSubObject2, 'taxDifference').AsText() > '') then
                                EVALUATE(ReconData.ResultTaxDifference, GetValueFromJsonObject(JSubObject2, 'taxDifference').AsText());
                            if JSubObject2.Contains('matchType') and (GetValueFromJsonObject(JSubObject2, 'matchType').AsText() > '') then
                                ReconData.ResultMatchType := GetValueFromJsonObject(JSubObject2, 'matchType').AsText();
                            if JSubObject2.Contains('matchScope') and (GetValueFromJsonObject(JSubObject2, 'matchScope').AsText() > '') then
                                ReconData.ResultMatchScope := GetValueFromJsonObject(JSubObject2, 'matchScope').AsText();
                            if JSubObject2.Contains('myGstin') and (GetValueFromJsonObject(JSubObject2, 'myGstin').AsText() > '') then
                                ReconData.ResultMyGSTIN := GetValueFromJsonObject(JSubObject2, 'myGstin').AsText();
                            if JSubObject2.Contains('myPan') and (GetValueFromJsonObject(JSubObject2, 'myPan').AsText() > '') then
                                ReconData.ResultMyPAN := GetValueFromJsonObject(JSubObject2, 'myPan').AsText();
                            if JSubObject2.Contains('cpPan') and (GetValueFromJsonObject(JSubObject2, 'cpPan').AsText() > '') then
                                ReconData.ResultCpPAN := GetValueFromJsonObject(JSubObject2, 'cpPan').AsText();
                            if not ReconData.INSERT then
                                ReconData.Modify();
                        end;
                    end;
                    ReconData.SetRange(WorkFlowID, WorkFlowIDP);
                    ReconData.SetFilter(PaymentAction, '=%1|=%2', 'HOLD_GST_AMOUNT', 'HOLD FULL AMOUNT');
                    if ReconData.FINDSET then
                        REPEAT
                            PaymentBlocking.DocumentID := ReconData.DocumentID;
                            PaymentBlocking.DocumentReferenceNo := ReconData.DocumentReferenceNo;
                            xPaymentAction := PaymentBlocking.PaymentAction;
                            PaymentBlocking.PaymentAction := ReconData.PaymentAction;
                            if PaymentBlocking.INSERT then
                                PaymentBlocking."Created Date time" := CURRENTDATETIME;
                            ReconData.Modify;
                            if PaymentBlocking.PaymentAction <> xPaymentAction then
                                PostGeneralJournal(PaymentBlocking);
                        // EXIT; //To be removed.
                        UNTIL ReconData.Next() = 0;
                end;
            end;
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
    local procedure PostGeneralJournal(var PaymentBlocking: Record "ClearComp MaxITC Payment block")
    var
        MaxITCSetup: Record "ClearComp MaxITC Setup";
        GenJnlLine: Record "Gen. Journal Line";
        ReconData: Record "ClearComp MaxITC ReconResult";
        PurhInvHdr: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        SourceCodeSetup: Record "Source Code Setup";
        VendorLederEntries: Record "Vendor Ledger Entry";
        PaymentBlockLog: Record "ClearComp MaxITC Payment Log";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        AccountNo: Code[20];
    begin
        if ReconData.Get(PaymentBlocking.DocumentID) then begin
            MaxITCSetup.Get();
            SourceCodeSetup.Get();
            GenJnlLine.Init();
            GenJnlLine.Validate("Source Code", SourceCodeSetup."General Journal");
            GenJnlLine.Validate("Posting Date", TODAY);
            GenJnlLine.Validate("Document Date", TODAY);
            GenJnlLine.Validate("Document No.", 'MaxITC');
            //xPaymentAction := 'HOLD_GST_AMOUNT';
            //ReconData.PaymentAction := 'PAY FULL AMOUNT';
            if PurhInvHdr.Get(ReconData.DocumentReferenceNo) then
                AccountNo := PurhInvHdr."Buy-from Vendor No."
            else
                if PurchCrMemoHdr.Get(ReconData.DocumentReferenceNo) then
                    AccountNo := PurchCrMemoHdr."Buy-from Vendor No.";

            if ReconData.PaymentAction IN ['HOLD_GST_AMOUNT', 'HOLD FULL AMOUNT'] then begin
                GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::Vendor);
                GenJnlLine.Validate("Bal. Account Type", GenJnlLine."Bal. Account Type"::"G/L Account");
                if AccountNo <> '' then
                    GenJnlLine.Validate("Account No.", AccountNo)
                else
                    GenJnlLine.Validate("Account No.", '27833998');
                GenJnlLine.Validate("Bal. Account No.", MaxITCSetup."Payment blocking Account No.");
            end else
                if ReconData.PaymentAction = 'PAY FULL AMOUNT' then begin
                    GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::"G/L Account");
                    GenJnlLine.Validate("Bal. Account Type", GenJnlLine."Bal. Account Type"::Vendor);
                    GenJnlLine.Validate("Account No.", MaxITCSetup."Payment blocking Account No.");
                    if AccountNo <> '' then
                        GenJnlLine.Validate("Bal. Account No.", AccountNo)
                    else
                        GenJnlLine.Validate("Bal. Account No.", '27833998');

                end;

            GenJnlLine.Validate("Allow Application", TRUE);
            if AccountNo <> '' then
                VendorLederEntries.SetRange("Vendor No.", AccountNo)
            else
                VendorLederEntries.SetRange("Vendor No.", '27833998');
            VendorLederEntries.SetRange("Document No.", '108045');
            if VendorLederEntries.FindFirst() then begin
                GenJnlLine.Validate("Applies-to Doc. Type", GenJnlLine."Applies-to Doc. Type"::" ");
                GenJnlLine.Validate("Applies-to Doc. No.", 'I0006');  //Add document reference no.
            end;
            case ReconData.PaymentAction OF
                'HOLD_GST_AMOUNT':
                    GenJnlLine.Validate(Amount, ReconData.TaxValue);
                'HOLD FULL AMOUNT':
                    GenJnlLine.Validate(Amount, ReconData.TotalValue);
                'PAY FULL AMOUNT':
                    if xPaymentAction = 'HOLD_GST_AMOUNT' then
                        GenJnlLine.Validate(Amount, ReconData.TaxValue)
                    else
                        if xPaymentAction = 'HOLD FULL AMOUNT' then
                            GenJnlLine.Validate(Amount, ReconData.TotalValue);
            end;
            PaymentBlockLog.Init();
            PaymentBlockLog.DocumentID := PaymentBlocking.DocumentID;
            PaymentBlockLog."Document reference No" := PaymentBlocking.DocumentReferenceNo;
            PaymentBlockLog."Payment Action" := PaymentBlocking.PaymentAction;
            PaymentBlockLog."G/L Entry No." := GenJnlPostLine.RunWithCheck(GenJnlLine);
            PaymentBlockLog."Creation DateTime" := CURRENTDATETIME;
            PaymentBlockLog.Insert();
        end;
    end;
}

