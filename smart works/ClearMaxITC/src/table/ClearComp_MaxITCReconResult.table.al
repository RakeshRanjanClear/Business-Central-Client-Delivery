table 60118 "ClearComp MaxITC ReconResult"
{
    Caption = 'Clear MaxITC recon result';
    fields
    {
        field(1; DocumentID; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(2; MatchingTaskID; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(3; UserName; Text[50])
        {
            DataClassification = ToBeClassified;
        }
        field(4; ResponseFrom; Option)
        {
            DataClassification = ToBeClassified;
            OptionCaption = ' ,PR,Govt';
            OptionMembers = " ",PR,Govt;
        }
        field(5; WorkFlowID; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(20; DocumentReferenceNo; Text[50])
        {
            DataClassification = ToBeClassified;
        }
        field(21; CpGSTIN; Text[15])
        {
            DataClassification = ToBeClassified;
        }
        field(22; CpName; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(23; CpPAN; Text[10])
        {
            DataClassification = ToBeClassified;
        }
        field(24; CpTradeName; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(25; CpFillingFrequency; Text[50])
        {
            DataClassification = ToBeClassified;
        }
        field(26; CpGSTINStatus; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(27; DocDate; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(28; Pos; Text[50])
        {
            DataClassification = ToBeClassified;
        }
        field(29; IGST; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(30; CGST; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(31; SGST; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(32; CESS; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(33; DocumentID1; Text[150])
        {
            DataClassification = ToBeClassified;
        }
        field(34; TaxableValue; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(35; TaxValue; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(36; TotalValue; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(37; SectionName; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(38; DocumentType; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(39; ReturnPeriod; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(40; FiscalYear; Integer)
        {
            DataClassification = ToBeClassified;
        }
        field(41; Source; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(42; OriginalDocNo; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(43; OriginalDocDate; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(44; CPGSTINCancelDate; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(45; ReverseChargeApplicable; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(46; MyGSTIN; Text[15])
        {
            DataClassification = ToBeClassified;
        }
        field(47; CustomFields; Text[250])
        {
            DataClassification = ToBeClassified;
        }
        field(48; DueDate; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(49; VendorCode; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(50; VoucherNo; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(51; VoucherDate; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(52; ITCClaimEligibility; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(53; ITCEligibile; Text[5])
        {
            DataClassification = ToBeClassified;
        }
        field(54; PaymentAction; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(55; CounterPartFillingStatus; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(56; CpFillingStatus3B; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(57; G1FillingDate; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(58; G1FillingRP; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(59; IRN; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(60; IRNGenerationDate; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(61; Reason; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(62; GenerationSource; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(63; DocumentSource; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(170; ResultITCAction; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(171; ResultGST3BClaimMonth; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(172; ResultIGSTITC; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(173; ResultCGSTITC; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(174; ResultSGSTITC; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(175; ResultCESSITC; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(176; ResultTotalITC; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(177; ResultTaxableValue; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(178; ResultSupplierGSTIN; Text[15])
        {
            DataClassification = ToBeClassified;
        }
        field(179; ResultSupplierName; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(180; ResultDocumentType; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(181; ResultMatchingRequestType; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(182; ResultSupplierFillingStatus; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(183; ResultMisMatchFields; Text[250])
        {
            DataClassification = ToBeClassified;
        }
        field(184; Resultremark; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(185; ResultTaxDifference; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(186; ResultMatchType; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(187; ResultMatchScope; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(188; ResultMyGSTIN; Text[15])
        {
            DataClassification = ToBeClassified;
        }
        field(189; ResultMyPAN; Text[10])
        {
            DataClassification = ToBeClassified;
        }
        field(190; ResultCpPAN; Text[10])
        {
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        key(Key1; DocumentID)
        {
        }
    }

    fieldgroups
    {
    }
}

