page 60116 "ClearComp MaxITC Payment block"
{
    PageType = List;
    SourceTable = "ClearComp MaxITC Payment block";
    Caption = 'Clear MAXITC payment block';
    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(DocumentID; Rec.DocumentID)
                {
                    ApplicationArea = all;
                }
                field(DocumentReferenceNo; Rec.DocumentReferenceNo)
                {
                    ApplicationArea = all;
                }
                field(PaymentAction; Rec.PaymentAction)
                {
                    ApplicationArea = all;
                }
                field("Created Date time"; Rec."Created Date time")
                {
                    ApplicationArea = all;
                }
            }
        }
    }

    actions
    {
        area(creation)
        {
            action("View Logs")
            {
                RunObject = Page "ClearComp MaxITC Payment Log";
                RunPageLink = DocumentID = FIELD(DocumentID);
                RunPageMode = View;
                ApplicationArea = all;
            }
        }
    }
}

