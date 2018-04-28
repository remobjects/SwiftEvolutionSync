namespace SwiftEvolutionSync;

const SWIFT_PROPOSALS = "/Users/mh/Code/Others/swift-evolution/proposals"; // folder with propoals
const LEGACY = "/Users/mh/Code/ElementsDocs/Silver/__SwiftEvolution_Legacy.md"; // old MD file, for one-time import
const STATUS_OUT = "/Users/mh/Code/ElementsDocs/Silver/__SwiftEvolutionElementsStatus2.txt"; // generated status file for comparisson

const STATUS_IN = "/Users/mh/Code/ElementsDocs/Silver/__SwiftEvolutionElementsStatus.txt";
const OUTPUT = "/Users/mh/Code/ElementsDocs/Silver/__SwiftEvolutionStatus";
const SWIFT_ORG_BASE_URL = "https://github.com/apple/swift-evolution/blob/master/proposals/";

type
  Sync = public class

    fProposals: Dictionary<String, Proposal>;

    method LoadProposals();
    begin
      fProposals := new Dictionary<String, Proposal>;
      for each f in Folder.GetFiles(SWIFT_PROPOSALS) do begin
        var lProposal := new Proposal withFileName(f);
        fProposals[lProposal.ID] := lProposal;
        //writeLn(String.Format("SE-{0} {1}", lProposal.ID, lProposal.Name));
      end;
    end;

    method ParseLegacy();
    begin
      var lLegacy := File.ReadLines(LEGACY);
      for each l in lLegacy do begin
        if l.StartsWith("* SE-") then begin
          l := l.Substring(5);
          var lID := l.Substring(0, 4);
          var lProposal := fProposals[lID];
          if assigned(lProposal) then begin
            lProposal.Known := true;
            var lSplit := l.SplitAtFirstOccurrenceOf("&mdash;");
            if lSplit.Count > 1 then begin
              var lStatus := lSplit[1].Trim;
              if lStatus.Contains("not applicable") then begin
                lProposal.NotApplicable := true;
              end
              else if lStatus.Contains("SBL") then begin
                lProposal.SwiftBaseLibrary := true
              end
              else if lStatus.Contains("done") then begin
                lProposal.Implemented := true;
                lSplit := lStatus.SplitAtFirstOccurrenceOf(",");
                if lSplit.Count > 1 then
                  lProposal.ImplementedIn := lSplit[1].Trim();
              end;

              if lStatus.StartsWith("#") then begin
                lProposal.IssueID := lStatus.Substring(1);
              end
              else if lStatus.Contains("#") then begin
                lProposal.IssueID := lStatus.Substring(lStatus.IndexOf("#")+1, 5).Trim;
              end;
              //else
                //writeLn(String.Format("KNOWN   SE-{0} {1}", lID, lStatus));
            end
            else begin
              //writeLn(String.Format("KNOWN   SE-{0} NO STATUS: {1}", lID, l));
            end;
          end
          else begin
            writeLn(String.Format("UNKNOWN SE-{0}", lID));
          end;

        end;
      end;

    end;

    method ParseStatus();
    begin
      var lLegacy := File.ReadLines(STATUS_IN);
      for each l in lLegacy do begin
        if length(l) > 0 then begin
          var lSplit := l.SPlit(",");
          var lID := lSplit[0];
          var lProposal := fProposals[lID];
          if assigned(lProposal) then begin
            lProposal.Known := true;

            for each s in lSplit index i do begin
              if i = 0 then
                continue;

              s := s.Trim.ToLower;
              if s = "not applicable" then
                lProposal.NotApplicable := true
              else if s in ["SBL", "swift base library"] then begin
                lProposal.SwiftBaseLibrary := true
              end
              else if s = "implemented" then
                lProposal.Implemented := true
              else if s.StartsWith("in=") then
                lProposal.ImplementedIn := s.SubString(3)
              else if s.StartsWith("id=") then
                lProposal.IssueID := s.SubString(3)
              else
                writeLn(String.Format("Unknown value for SE-{0}: {1}", lID, s));

            end;

            if l ≠ lProposal.GetElementsStatusString then begin
              writeLn(String.Format("Data changed for SE-{0}", lID));
              writeLn("  "+l);
              writeLn("  "+lProposal.GetElementsStatusString);
            end;

          end
          else begin
            writeLn(String.Format("Unkown SE-{0}", lID));
          end;

        end;
      end;

    end;

    method PrintPlain(): String;
    begin
      result := "";
      for each from p in fProposals.Values order by p.ID desc do begin
        result := result+String.Format("* SE-{0} {1} ({2})", p.ID, p.Name, p.GetElementsStatusString);
        result := result+Environment.LineBreak;
      end;

      writeLn(result);
    end;

    method PrintMarkdown;
    begin
      writeLn(GetMarkdownByStatus());
    end;

    //
    // Status
    //

    method SaveStatus;
    begin
      File.WriteText(STATUS_OUT, GetStatus());
    end;

    method GetStatus: String;
    begin
      result := "";
      for each from p in fProposals.Values order by p.ID desc do
        result := result+p.GetElementsStatusString+Environment.LineBreak;
    end;

    //
    // Markdown
    //

    method SaveDocs;
    begin
      File.WriteText(OUTPUT+"_ByID.md", GetMarkdown());
      File.WriteText(OUTPUT+"_ByAppleStatus.md", GetMarkdownByStatus());
    end;

    method GetMarkdown: String;
    begin
      result := "";
      for each from p in fProposals.Values order by p.ID desc do
        result := result+p.GetMarkdown+Environment.LineBreak;
    end;

    method GetMarkdownByStatus: String;
    begin
      result := "";
      var lKnownAppleStatusValues := ["Review", "Accepted", "Implemented", "Deferred", "Rejected", "Returned" ,"Withdrawn"];

      //writeLn("==");
      //var lAppleStatusValues := fProposals.Values.Select(p -> p.AppleStatus).Distinct;
      //for each s in lAppleStatusValues do
        //writeLn(s);
      //writeLn("==");

      for each s in lKnownAppleStatusValues do begin
        if s = "Implemented" then begin
          var lAppleSwiftVersions := fProposals.Values.Select(p -> p.AppleImplementedIn).Distinct.OrderByDescending(v -> v);
          for each v in lAppleSwiftVersions do begin
            result := result+Environment.LineBreak+"### "+s+" in "+v+Environment.LineBreak+Environment.LineBreak;
            for each from p in fProposals.Values where (p.AppleStatus = s) and (p.AppleImplementedIn = v) order by p.ID desc do
              result := result+p.GetMarkdown+Environment.LineBreak;
          end;
        end
        else begin
          result := result+Environment.LineBreak+"### "+s+Environment.LineBreak+Environment.LineBreak;
          for each from p in fProposals.Values where p.AppleStatus = s order by p.ID desc do
            result := result+p.GetMarkdown+Environment.LineBreak;
        end;
      end;
    end;


    method Sync();
    begin

    end;


  end;



end.