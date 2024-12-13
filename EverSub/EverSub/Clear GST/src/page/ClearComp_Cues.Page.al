page 50110 "ClearComp Cues"
{
    PageType = CardPart;
    Caption = 'GST Document Information';

    layout
    {
        area(Content)
        {
            cuegroup(Grp1)
            {
                Caption = 'Document Status';
                field(NoOfPostedSalesOrder; NoOfPostedSalesOrder)
                {
                    Caption = 'No. Of Posted Sales Order';
                    ApplicationArea = All;
                    StyleExpr = 'Favorable';

                    trigger OnDrillDown()
                    var
                        GSTTransHeader: Record "ClearComp GST Trans. Header";
                        PrevTransDataList: Page "ClearComp Prev. Trans. List";
                    begin
                        GSTTransHeader.SetRange(Status, GSTTransHeader.Status::Synced);
                        GSTTransHeader.SetRange("Transaction Type", GSTTransHeader."Transaction Type"::SALE);
                        if GSTTransHeader.FindSet() then begin
                            PrevTransDataList.SetTableView(GSTTransHeader);
                            PrevTransDataList.Editable(false);
                            PrevTransDataList.Caption('Sent Purchase Order');
                            PrevTransDataList.RunModal();
                        end;
                    end;
                }
                field(NoOfPostedPurchOrder; NoOfPostedPurchOrder)
                {
                    Caption = 'No. Of Posted Purch. Order';
                    ApplicationArea = All;
                    StyleExpr = 'Favorable';

                    trigger OnDrillDown()
                    var
                        GSTTransHeader: Record "ClearComp GST Trans. Header";
                        PrevTransDataList: Page "ClearComp Prev. Trans. List";
                    begin
                        GSTTransHeader.SetRange(Status, GSTTransHeader.Status::Synced);
                        GSTTransHeader.SetRange("Transaction Type", GSTTransHeader."Transaction Type"::PURCHASE);
                        if GSTTransHeader.FindSet() then begin
                            PrevTransDataList.SetTableView(GSTTransHeader);
                            PrevTransDataList.Editable(false);
                            PrevTransDataList.Caption('Sent Purchase Order');
                            PrevTransDataList.RunModal();
                        end;
                    end;
                }
                field(PendingDocuments; PendingDocuments)
                {
                    Caption = 'Pending Documents to Sync';
                    ApplicationArea = All;
                    StyleExpr = 'Favorable';
                    Image = Folder;

                    trigger OnDrillDown()
                    var
                        GSTTransHeader: Record "ClearComp GST Trans. Header";
                        PrevTransDataList: Page "ClearComp Prev. Trans. List";
                    begin
                        GSTTransHeader.SetRange(Status, GSTTransHeader.Status::Open);
                        if GSTTransHeader.FindSet() then begin
                            PrevTransDataList.SetTableView(GSTTransHeader);
                            PrevTransDataList.Editable(false);
                            PrevTransDataList.Caption('Pending Documents To Sync');
                            PrevTransDataList.RunModal();
                        end;
                    end;
                }
                field(DocWithError; DocWithError)
                {
                    Caption = 'Documents with Error';
                    ApplicationArea = All;
                    StyleExpr = 'Favorable';

                    trigger OnDrillDown()
                    var
                        GSTTransHeader: Record "ClearComp GST Trans. Header";
                        PrevTransDataList: Page "ClearComp Prev. Trans. List";
                    begin
                        GSTTransHeader.SetRange(Status, GSTTransHeader.Status::Error);
                        if GSTTransHeader.FindSet() then begin
                            PrevTransDataList.SetTableView(GSTTransHeader);
                            PrevTransDataList.Editable(false);
                            PrevTransDataList.Caption('Pending Documents To Sync');
                            PrevTransDataList.RunModal();
                        end;
                    end;
                }
            }
        }
    }
    trigger OnOpenPage()
    var
        GSTTransHeader: Record "ClearComp GST Trans. Header";
    begin
        GSTTransHeader.SetRange(Status, GSTTransHeader.Status::Synced);
        GSTTransHeader.SetRange("Transaction Type", GSTTransHeader."Transaction Type"::PURCHASE);
        NoOfPostedPurchOrder := GSTTransHeader.Count;

        GSTTransHeader.SetRange("Transaction Type");
        GSTTransHeader.SetRange("Transaction Type", GSTTransHeader."Transaction Type"::SALE);
        NoOfPostedSalesOrder := GSTTransHeader.Count;

        GSTTransHeader.SetRange(Status);
        GSTTransHeader.SetRange("Transaction Type");
        GSTTransHeader.SetRange(Status, GSTTransHeader.Status::Open);
        PendingDocuments := GSTTransHeader.Count;

        GSTTransHeader.SetRange(Status);
        GSTTransHeader.SetRange(Status, GSTTransHeader.Status::Error);
        DocWithError := GSTTransHeader.Count;
    end;

    var
        NoOfPostedPurchOrder: Integer;
        NoOfPostedSalesOrder: Integer;
        PendingDocuments: Integer;
        DocWithError: Integer;
}