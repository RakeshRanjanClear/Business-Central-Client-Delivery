page 50111 "ClearComp GST Setup"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "ClearComp GST Setup";
    Caption = 'Clear GST Setup';

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("GST Base Url"; Rec."GST Base Url")
                {
                    ApplicationArea = All;
                }
                field("Auth. Token"; Rec."Auth. Token")
                {
                    ApplicationArea = All;
                }
                field("Sync Invoices"; Rec."Sync Invoices")
                {
                    ApplicationArea = All;
                }
                field("Job Queue From Date"; Rec."Job Queue From Date")
                {
                    ApplicationArea = All;
                }
                field("Sync. Doc. with IRN"; Rec."Sync. Doc. with IRN")
                {
                    ApplicationArea = all;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("Message Logs")
            {
                ApplicationArea = All;
                Image = InteractionLog;

                trigger OnAction()
                var
                    InterfMessageLog: Page "ClearComp Interf. Message Log";
                begin
                    InterfMessageLog.Run();
                end;
            }
            action("Show Synced Transactions")
            {
                ApplicationArea = All;
                Image = Transactions;

                trigger OnAction()
                var
                    GSTTransHeader: Record "ClearComp GST Trans. Header";
                    PrevTransDataList: Page "ClearComp Prev. Trans. List";
                begin
                    GSTTransHeader.SetRange(Status, GSTTransHeader.Status::Synced);
                    if GSTTransHeader.FindSet() then begin
                        PrevTransDataList.SetTableView(GSTTransHeader);
                        PrevTransDataList.Caption(PageCaption);
                        PrevTransDataList.Editable(true);
                        PrevTransDataList.SetDeleteTransactionVisible();
                        PrevTransDataList.RunModal();
                    end else
                        Message(NoSyncedTrans);
                    GSTTransHeader.ModifyAll(Selected, FALSE);
                end;
            }
            action("Show UnSynced Transactions")
            {
                ApplicationArea = All;
                Image = Transactions;

                trigger OnAction()
                var
                    GSTTransHeader: Record "ClearComp GST Trans. Header";
                    PrevTransDataList: Page "ClearComp Prev. Trans. List";
                begin
                    GSTTransHeader.SetFilter(Status, '<>%1', GSTTransHeader.Status::Synced);
                    if GSTTransHeader.FindSet() then begin
                        PrevTransDataList.SetTableView(GSTTransHeader);
                        PrevTransDataList.Caption('Un-' + PageCaption);
                        PrevTransDataList.Editable(false);
                        PrevTransDataList.SetMessagevisible();
                        PrevTransDataList.RunModal();
                    end else
                        Message(NoSyncedTrans);
                    GSTTransHeader.ModifyAll(Selected, false);
                end;
            }
            action("Start Job Queue")
            {
                ApplicationArea = All;
                Image = Job;

                trigger OnAction()
                var
                    GSTMgmtUnit: Codeunit "ClearComp GST Management Unit";
                begin
                    GSTMgmtUnit.Run();
                end;
            }
        }
    }

    var
        NoSyncedTrans: Label 'No Synced Transactions exist!';
        PageCaption: Label 'Synced Transactions';
}