codeunit 50106 "Clear General functions"
{

    procedure IsReverseChargeApplicable(DocumentNoP: Code[20]; DocumentTypeP: Enum "GST Document Type"): Boolean
    var
        DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
    begin
        DetailedGSTLedgerEntry.SetRange("Document Type", DocumentTypeP);
        DetailedGSTLedgerEntry.SetRange("Document No.", DocumentNoP);
        DetailedGSTLedgerEntry.SetFilter("GST Component Code", '%1|%2|%3', 'CGST', 'SGST', 'IGST');
        DetailedGSTLedgerEntry.SetRange("Reverse Charge", true);
        if DetailedGSTLedgerEntry.FindFirst() then
            exit(true);
    end;

    procedure GetCustomertype(CustomerNoP: Code[20]): Enum "Clear Customer TaxPayer Type";
    var
        customer: Record Customer;
    begin
        if customer.get(CustomerNoP) then
            if customer."GST Registration Type" = Enum::"GST Registration Type"::UID then
                exit(Enum::"Clear Customer TaxPayer Type"::UIN)
            else
                exit(Enum::"Clear Customer TaxPayer Type"::None);
    end;

    procedure getExternalDocumentNumber(doc: Code[20]): Text
    var
        DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
    begin
        DetailedGSTLedgerEntry.SetRange("Entry Type", DetailedGSTLedgerEntry."Entry Type"::"Initial Entry");
        DetailedGSTLedgerEntry.SetRange("Document No.", doc);
        if DetailedGSTLedgerEntry.FindFirst() then
            exit(DetailedGSTLedgerEntry."External Document No.");
    end;

    procedure GetGSTCompRate(var TransLine: Record "Clear Trans line")
    var
        DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
    begin
        DetailedGSTLedgerEntry.SetRange("Entry Type", DetailedGSTLedgerEntry."Entry Type"::"Initial Entry");
        DetailedGSTLedgerEntry.SetRange("Document No.", TransLine."Document No.");
        DetailedGSTLedgerEntry.SetRange("Document Line No.", TransLine."Line num");
        DetailedGSTLedgerEntry.SetRange("GST Component Code", 'CGST');
        if DetailedGSTLedgerEntry.FindSet() then begin
            TransLine."Taxable amount" := DetailedGSTLedgerEntry."GST Base Amount";
            UpadateITCClaim(TransLine, DetailedGSTLedgerEntry);
            TransLine."CGST Rate" := DetailedGSTLedgerEntry."GST %";
            repeat
                TransLine."CGST amt" += Abs(DetailedGSTLedgerEntry."GST Amount");
            until DetailedGSTLedgerEntry.Next() = 0;
            if not (TransLine."ITC claim type" in [TransLine."ITC claim type"::NONE, TransLine."ITC claim type"::INELIGIBLE]) then
                TransLine."ITC CGST amt" := TransLine."CGST amt";
        end;

        DetailedGSTLedgerEntry.SetRange("GST Component Code", 'SGST');
        if DetailedGSTLedgerEntry.FindSet() then begin
            TransLine."SGST Rate" := DetailedGSTLedgerEntry."GST %";
            UpadateITCClaim(TransLine, DetailedGSTLedgerEntry);
            repeat
                TransLine."SGST amt" += Abs(DetailedGSTLedgerEntry."GST Amount");
            until DetailedGSTLedgerEntry.Next() = 0;
            if not (TransLine."ITC claim type" in [TransLine."ITC claim type"::NONE, TransLine."ITC claim type"::INELIGIBLE]) then
                TransLine."ITC SGST amt" := TransLine."SGST amt";
        end;

        DetailedGSTLedgerEntry.SetRange("GST Component Code", 'IGST');
        if DetailedGSTLedgerEntry.FindSet() then begin
            TransLine."Taxable amount" := DetailedGSTLedgerEntry."GST Base Amount";
            UpadateITCClaim(TransLine, DetailedGSTLedgerEntry);
            TransLine."IGST Rate" := DetailedGSTLedgerEntry."GST %";
            repeat
                TransLine."IGST amt" += Abs(DetailedGSTLedgerEntry."GST Amount");
            until DetailedGSTLedgerEntry.Next() = 0;
            if not (TransLine."ITC claim type" in [TransLine."ITC claim type"::NONE, TransLine."ITC claim type"::INELIGIBLE]) then
                TransLine."ITC IGST amt" := TransLine."IGST amt";
        end;

        DetailedGSTLedgerEntry.SetRange("GST Component Code", 'CESS');
        if DetailedGSTLedgerEntry.FindSet() then begin
            TransLine."Taxable amount" := DetailedGSTLedgerEntry."GST Base Amount";
            UpadateITCClaim(TransLine, DetailedGSTLedgerEntry);
            TransLine."Cess Rate" := DetailedGSTLedgerEntry."GST %";
            repeat
                if (DetailedGSTLedgerEntry."GST %" > 0) then
                    TransLine."Cess amt" += Abs(DetailedGSTLedgerEntry."GST Amount");
            until DetailedGSTLedgerEntry.Next() = 0;
            if not (TransLine."ITC claim type" in [TransLine."ITC claim type"::NONE, TransLine."ITC claim type"::INELIGIBLE]) then
                TransLine."ITC CESS amt" := TransLine."ITC CESS amt";
        end;
    end;

    local procedure UpadateITCClaim(var TransLine: Record "Clear Trans line"; DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry")
    begin
        case DetailedGSTLedgerEntry."Eligibility for ITC" of
            DetailedGSTLedgerEntry."Eligibility for ITC"::Inputs:
                TransLine."ITC claim type" := TransLine."ITC claim type"::INPUT;
            DetailedGSTLedgerEntry."Eligibility for ITC"::"Input Services":
                TransLine."ITC claim type" := TransLine."ITC claim type"::"INPUT SERVICES";
            DetailedGSTLedgerEntry."Eligibility for ITC"::"Capital goods":
                TransLine."ITC claim type" := TransLine."ITC claim type"::"CAPITAL GOODS";
            DetailedGSTLedgerEntry."Eligibility for ITC"::Ineligible:
                TransLine."ITC claim type" := TransLine."ITC claim type"::INELIGIBLE;
        end;
    end;

    procedure UpdateStagingData()
    var
        TransHdr: Record "Clear Trans Hdr";
        SalesInvHdr: Record "Sales Invoice Header";
        SalesCrMemoHdr: Record "Sales Cr.Memo Header";
        PurchInvHdr: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        GenerateSales: Codeunit "Clear Generate Sales Inv data";
        GenerateSalesCrMemo: Codeunit "Clear Generate Sales Cr. memo";
        GeneratePurchInv: Codeunit "clear Generate Purch Inv data";
        GeneratePurchCrMemo: Codeunit "Clear Generate Purch Cr. memo";
    begin
        if TransHdr.FindSet() then
            repeat
                if SalesInvHdr.get(TransHdr."Document No.") then
                    GenerateSales.ReadDetails(SalesInvHdr)
                else
                    if SalesCrMemoHdr.Get(TransHdr."Document No.") then
                        GenerateSalesCrMemo.ReadDetails(SalesCrMemoHdr)
                    else
                        if PurchInvHdr.Get(TransHdr."Document No.") then
                            GeneratePurchInv.ReadDetails(PurchInvHdr)
                        else
                            if PurchCrMemoHdr.Get(TransHdr."Document No.") then
                                GeneratePurchCrMemo.ReadDetails(PurchCrMemoHdr);
            until TransHdr.Next() = 0;
    end;

    procedure IsGSTApplicable(DocumentNo: Code[20]; TableID: Integer): Boolean
    var
        GSTSetup: Record "GST Setup";
    begin
        if not GSTSetup.Get() then
            exit;

        GSTSetup.TestField("GST Tax Type");
        case TableID of
            Database::"Sales Invoice Header":
                exit(CheckSalesInvoiceLine(DocumentNo, GSTSetup."GST Tax Type"));
            Database::"Sales Cr.Memo Header":
                exit(CheckSalesCrMemoLine(DocumentNo, GSTSetup."GST Tax Type"));
            Database::"Purch. Inv. Header":
                exit(checkPurchInvoiceLine(DocumentNo, GSTSetup."GST Tax Type"));
            Database::"Purch. Cr. Memo Hdr.":
                exit(CheckPurchCrMemoLine(DocumentNo, GSTSetup."GST Tax Type"));
        end;
    end;

    procedure GetTransLineNo(TransType: Enum "Clear Transaction type"; DocType: Enum "Clear Document Type"; DocNo: Code[20]): Integer
    var
        TransLine: Record "Clear Trans line";
    begin
        TransLine.SetRange("Transaction Type", TransType);
        TransLine.SetRange("Document Type", DocType);
        TransLine.SetRange("Document No.", DocNo);
        if TransLine.FindLast() then
            exit(TransLine."Line num" + 1000);
        exit(1000);
    end;

    procedure CreateExcelBuffer(var ExcelBufferP: Record "Excel Buffer"; RowNoP: Integer; RowLabelP: Text; ColumnNoP: Integer; ColumnLabelP: Text; CellValueP: Text)
    begin
        ExcelBufferP.INIT;
        ExcelBufferP."Row No." := RowNoP;
        ExcelBufferP.xlRowID := RowLabelP;
        ExcelBufferP."Column No." := ColumnNoP;
        ExcelBufferP.xlColID := ColumnLabelP;
        ExcelBufferP."Cell Value as Text" := CellValueP;
        ExcelBufferP.Insert();
    end;

    local procedure CheckSalesInvoiceLine(DocumentNo: Code[20]; TaxType: Code[20]): Boolean
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        Found: Boolean;
    begin
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.SetFilter("No.", '<>%1', '');
        if SalesInvoiceLine.FindSet() then
            repeat
                Found := TransactionValueExist(SalesInvoiceLine.RecordId, TaxType);
            until (SalesInvoiceLine.Next() = 0) or Found;

        exit(Found);
    end;

    local procedure checkPurchInvoiceLine(DocumentNo: Code[20]; TaxType: Code[20]): Boolean
    var
        PurchInvoiceLine: Record "Purch. Inv. Line";
        found: Boolean;
    begin
        PurchInvoiceLine.SetRange("Document No.", DocumentNo);
        PurchInvoiceLine.SetFilter("No.", '<>%1', '');
        if PurchInvoiceLine.FindSet() then
            repeat
                found := TransactionValueExist(PurchInvoiceLine.RecordId, TaxType);
            until (PurchInvoiceLine.Next() = 0) or found;
        exit(found);
    end;


    local procedure CheckSalesCrMemoLine(DocumentNo: Code[20]; TaxType: Code[20]): Boolean
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        Found: Boolean;
    begin
        SalesCrMemoLine.SetRange("Document No.", DocumentNo);
        SalesCrMemoLine.SetFilter("No.", '<>%1', '');
        if SalesCrMemoLine.FindSet() then
            repeat
                Found := TransactionValueExist(SalesCrMemoLine.RecordId, TaxType);
            until (SalesCrMemoLine.Next() = 0) or Found;

        exit(Found);
    end;

    local procedure CheckPurchCrMemoLine(DocumentNo: Code[20]; TaxType: Code[20]): Boolean
    var
        PurchCrmemoLine: Record "Purch. Cr. Memo Line";
        Found: Boolean;
    begin
        PurchCrmemoLine.SetRange("Document No.", DocumentNo);
        PurchCrmemoLine.SetFilter("No.", '<>%1', '');
        if PurchCrmemoLine.FindSet() then
            repeat
                Found := TransactionValueExist(PurchCrmemoLine.RecordId, TaxType);
            until (PurchCrmemoLine.Next() = 0) or Found;
        exit(Found);
    end;

    local procedure TransactionValueExist(RecID: RecordID; TaxType: Code[20]): Boolean
    var
        TaxTransactionValue: Record "Tax Transaction Value";
    begin
        TaxTransactionValue.SetRange("Tax Type", TaxType);
        TaxTransactionValue.SetRange("Tax Record ID", RecId);
        Exit(not TaxTransactionValue.IsEmpty());
    end;

}