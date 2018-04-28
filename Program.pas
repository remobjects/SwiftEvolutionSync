namespace SwiftEvolutionSync;

type
  Program = class
  public
    class method Main(args: array of String): Int32;
    begin
      var lSync := new Sync();
      lSync.LoadProposals();
      lSync.ParseStatus();
      lSync.SaveDocs();
      //lSync.SaveStatus();
    end;
  end;

end.