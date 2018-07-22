uses BotData;
uses RNNData;

begin
  
  Randomize(1);
  
  var l := 10;
  var b := new Bot(l);
  var inp := ArrGen(l,i->real(Random(2)));;
  
  writeln('created bot');
  writeln;
  
  while true do
  begin
    
    b.brain.Clear;
    b.brain.AddInp(inp);
    
    Writeln(Round(inp,2));
    Writeln(Round(b.brain.Step,2));
    
    b.brain.Clear;
    b.Train(Seq&<array of real>(inp),Seq&<array of real>(inp));
    
    readln;
    
  end;
  
end.
{
  
  var inp :=
  System.IO.Directory.EnumerateFiles('input')
  .Select(
    fname->
    System.IO.File.ReadAllText(fname)
  ).ToArray;
  
  var b := new Bot(inp);
  
end.