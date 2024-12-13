page 60120 "ClearComp MaxITC Trans. List"
{
    CardPageID = "Clearcomp MaxITC Trans. Data";
    InsertAllowed = false;
    PageType = List;
    SourceTable = "ClearComp MaxITC Trans. Header";
    Caption = 'Clear MAXITC Trans. list';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Selected; Rec.Selected)
                {
                    Visible = Actionvisible;
                    ApplicationArea = all;
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = all;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = all;
                }
                field("Posting date"; Rec."Posting date")
                {
                    ApplicationArea = all;
                }
                field("Credit/Debit Note No."; Rec."Credit/Debit Note No.")
                {
                    ApplicationArea = all;
                }
                field("Credit/Debit Note date"; Rec."Credit/Debit Note date")
                {
                    ApplicationArea = all;
                }
                field("Reason for Issuing CDN"; Rec."Reason for Issuing CDN")
                {
                    ApplicationArea = all;
                }
                field("Is Bill of Supply"; Rec."Is Bill of Supply")
                {
                    ApplicationArea = all;
                }
                field("Is Advance"; Rec."Is Advance")
                {
                    ApplicationArea = all;
                }
                field(WorkFlowID; Rec.WorkFlowID)
                {
                    Visible = fieldVisible;
                    ApplicationArea = all;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("Send Data and Trigger MaxITC")
            {
                PromotedCategory = Process;
                Promoted = true;
                PromotedIsBig = true;
                PromotedOnly = true;
                Visible = Actionvisible;
                ApplicationArea = all;
                trigger OnAction()
                var
                    ClearCompMaxITC: Codeunit "ClearComp MaxITC Management";
                begin
                    ClearCompMaxITC.SendDataAndTriggerMaxITC(Rec);
                end;
            }
            action("Check Status")
            {
                PromotedCategory = Process;
                Promoted = true;
                PromotedOnly = true;
                PromotedIsBig = true;
                Visible = Fieldvisible;
                ApplicationArea = all;
                trigger OnAction()
                var
                    ClearCompMaxITCJobQueue: Codeunit "ClearComp MaxITC Job Queue";
                    JobQueueEntry: Record "Job Queue Entry";
                begin
                    JobQueueEntry.SETRANGE("Parameter String", Rec.WorkFlowID);
                    IF JobQueueEntry.FINDFIRST THEN
                        ClearCompMaxITCJobQueue.RUN(JobQueueEntry);
                end;
            }
            action("Download Recon results file")
            {
                PromotedCategory = Process;
                PromotedIsBig = true;
                Promoted = true;
                PromotedOnly = true;
                Visible = Fieldvisible;
                ApplicationArea = all;
                trigger OnAction()
                var
                    ClearCompMaxITCmgmt: Codeunit "ClearComp MaxITC Management";
                    ReconResults: Record "ClearComp ReconResults Blobs";
                begin
                    if ReconResults.Get(Rec."Document Type", Rec."Document No.") then
                        if ReconResults.ReconResults.HasValue then
                            ClearCompMaxITCmgmt.DownloadReconFile(ReconResults);
                end;
            }
            action("download Recon Error file")
            {
                PromotedCategory = Process;
                PromotedIsBig = true;
                Promoted = true;
                PromotedOnly = true;
                Visible = Fieldvisible;
                ApplicationArea = all;
                trigger OnAction()
                var
                    ClearCompMaxITCmgmt: Codeunit "ClearComp MaxITC Management";
                    ReconResults: Record "ClearComp ReconResults Blobs";
                begin
                    if ReconResults.Get(Rec."Document Type", Rec."Document No.") then
                        if ReconResults.ErrorFile.HasValue then
                            ClearCompMaxITCmgmt.DownloadReconFile(ReconResults);
                end;
            }
        }
    }

    trigger OnClosePage()
    begin
        Rec.MODIFYALL(Selected, FALSE);
    end;

    var
        FieldVisible: Boolean;
        ActionVisible: Boolean;

    procedure SetFieldVisibility()
    begin
        FieldVisible := TRUE;
    end;

    procedure SetActionVisibility()
    begin
        ActionVisible := TRUE;
    end;
}

