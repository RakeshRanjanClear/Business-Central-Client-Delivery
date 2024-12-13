codeunit 50110 "ClearComp GST JobQueue Unit"
{
    trigger OnRun()
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"ClearComp GST Management Unit");
        if JobQueueEntry.FindFirst() then
            if JobQueueEntry.Status = JobQueueEntry.Status::Error then begin
                JobQueueEntry.Status := JobQueueEntry.Status::Ready;
                JobQueueEntry.Modify();
            end;
    end;

    var
        JobQueueEntry: Record "Job Queue Entry";
}