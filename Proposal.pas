namespace SwiftEvolutionSync;

type
  Proposal = public class
  public

    constructor withFileName(aFileName: String);
    begin
      ID := aFileName.LastPathComponent.SplitAtFirstOccurrenceOf("-")[0];
      //Name :=
      Text := File.ReadText(aFileName);
      var lLines := Text.Replace(#13, #10).Split(#10);
      Name := lLines[0].Substring(1).Trim;
      SwiftOrgLink := SWIFT_ORG_BASE_URL+aFileName.LastPathComponent;

      for each l in lLines index i do begin
        if i = 0 then
          continue;
        if l.StartsWith("##") then
          break;
        if l.StartsWith("* Status:") then begin
          AppleStatus := l.SplitAtFirstOccurrenceOf(":")[1].Trim.Replace("*", "");
          if AppleStatus.StartsWith("Implemented ") then begin
            AppleImplementedIn := AppleStatus.SplitAtFirstOccurrenceOf(" ")[1].Trim.Trim(['(', ')']);
            AppleImplementedIn := AppleImplementedIn.Replace("for ", "").Trim();
            AppleStatus := AppleStatus.SplitAtFirstOccurrenceOf(" ")[0];
          end;
          if AppleStatus.ToLower.Contains("review") then
            AppleStatus := "Review";
          if AppleStatus.ToLower.Contains("accepted") then
            AppleStatus := "Accepted";
          if AppleStatus.ToLower.Contains("accepted") then
            AppleStatus := "Accepted";
          if AppleStatus.ToLower.Contains("returned") then
            AppleStatus := "Returned";
        end;


      end;
    end;

    property ID: String; readonly;
    property Name: String; readonly;
    property Text: String; readonly;
    property SwiftOrgLink: String; readonly;

    property Known: Boolean;
    property NotApplicable: Boolean;
    property SwiftBaseLibrary: Boolean;
    property Implemented: Boolean;
    property ImplementedIn: String;
    property IssueID: String;
    property Comment: String;

    property AppleStatus: String; readonly;
    property AppleImplementedIn: String; readonly;

    property Tracked: Boolean read NotApplicable or SwiftBaseLibrary or Implemented or (length(IssueID) > 0);

    method GetElementsStatusString: String;
    begin
      result := ID;
      if NotApplicable then
        result := result+", Not Applicable";
      if SwiftBaseLibrary then
        result := result+", Swift Base Library";

      if length(IssueID) > 0 then
        result := result+", ID="+IssueID;

      if Implemented then
        result := result + ", Implemented";
      if length(ImplementedIn) > 0 then
        result := result + ", In="+ImplementedIn;

      if length(Comment) > 0 then
        result := result + ", Comment="+Comment;

      result := result.Trim();
    end;

    method GetMarkdown: String;
    begin
      result := "* ";
      if NotApplicable or Implemented then
        result := result+"<s>"
      else if not Tracked then
        result := result+"<span style=""color: red;"">";

      var lName := Name;
      if length(lName) > 75 then
        lName :=lName.Substring(0, 75)+"&hellip;";
      result := result+String.Format("[SE-{0}]({1}) {2}", ID, SwiftOrgLink, lName);

      if NotApplicable or Implemented then
        result := result+"</s>"
      else if not Tracked then
        result := result+"</span>";

      if NotApplicable then
        result := result+" &mdash; (Not applicable)";
      if Implemented then begin
        if length(ImplementedIn) > 0 then
          result := result+" &mdash; <b>(done, "+ImplementedIn+")</b>"
        else
          result := result+" &mdash; <b>(done)</b>";
      end
      else if length(IssueID) > 0 then begin
        result := result+" &mdash; <b>(#"+IssueID+")</b>"
      end
      else if SwiftBaseLibrary then begin
        result := result+" &mdash; <b>(SBL)</b>"
      end;


    end;

  end;

end.