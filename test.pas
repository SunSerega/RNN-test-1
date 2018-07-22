//uses BotData;
uses RNNData;

begin
  
  var key := Random(10000);
  //key := 0;
  writeln($'key is {key}');
  writeln;
  Randomize(key);
  
  
  
  var inp :=
  System.IO.Directory.EnumerateFiles('input')
  .Select(
    fname->
    System.IO.File.ReadAllText(fname)
  ).ToArray;
  
  var rnn1 := RNN.GetNew(char(0)+inp.SelectMany(s->s));
  
  
  
  while true do
  begin
    var in_text := inp[Random(inp.Length)];
    
    //writeln('training_on:');
    //writeln(in_text);
    writeln;
    
    rnn1.Train(in_text);
    rnn1.StepSentences.Println;
  end;
  
end.