unit RNNData;

interface

function Round(a:sequence of real; digits:integer):sequence of real;

type
  RNN = class
    
    public h: array of real;
    
    public b_ih: array of real;
    public mtx_ih: array[,] of real;
    
    public b_hh: array of real;
    public mtx_hh: array[,] of real;
    
    public b_ho: array of real;
    public mtx_ho: array[,] of real;
    
    
    public l: integer;
    public obj_to_h: object->array of real;
    public h_to_obj: function(a:array of real):object;
    
    
    
    public function act_func(x: real) := System.Math.Tanh(x);
    public function d_act_func(x: real) := 1/Sqr(System.Math.Cosh(x));
    
    
    
    {$region I/O}
    
    {$region AddInp}
    
    public procedure AddInp(data: array of real);
    begin
      
      var nh := Copy(b_hh);
      
      for var i1 := 0 to l - 1 do
      begin
        nh[i1] += b_ih[i1];
        
        for var i2 := 0 to l - 1 do
          nh[i1] += 
            mtx_hh[i2,i1] * h[i2]+
            mtx_ih[i2,i1] * data[i2];
        
        nh[i1] := act_func(nh[i1]);
      end;
      
      h := nh;
      
    end;
    
    public procedure AddInp(o: object) := AddInp(obj_to_h(o));
    
    public procedure AddInp(text: string) :=
    foreach var ch in text do
      AddInp(ch);
    
    {$endregion AddInp}
    
    {$region Step}
    
    public function Step: array of real;
    begin
      
      var nh := Copy(b_hh);
      
      for var i1 := 0 to l - 1 do
      begin
        for var i2 := 0 to l - 1 do
          nh[i1] += 
            mtx_hh[i2,i1] * h[i2];
        
        nh[i1] := act_func(nh[i1]);
      end;
      
      h := nh;
      
      Result := Copy(b_ho);
      
      for var i1 := 0 to l - 1 do
      begin
        for var i2 := 0 to l - 1 do
          Result[i1] +=
            mtx_ho[i2,i1]*h[i2];
        
        Result[i1] := act_func(Result[i1]);
      end;
      
    end;
    
    public function Step(c:integer): sequence of array of real;
    begin
      loop c do yield Step;
    end;
    
    public function StepObj: object := h_to_obj(Step);
    
    public function StepText(length: integer): string;
    begin
      var sb := new StringBuilder(length);
      
      loop length do
        sb += char(StepObj);
      
      Result := sb.ToString;
    end;
    
    public function StepWords(words_c: integer := 1): string;
    begin
      {$ifdef DEBUG}
      
      if words_c < 1 then raise new System.ArgumentException($'words_c было {words_c}');
      
      {$endif DEBUG}
      
      var sb := new StringBuilder;
      
      while true do
      begin
        var ch := char(StepObj);
        if ch = ' ' then
        begin
          words_c -= 1;
          if words_c = 0 then break;
        end;
        sb += ch;
      end;
      
      Result := sb.ToString;
    end;
    
    public function StepSentence(sentenc_c: integer := 1): string;
    begin
      {$ifdef DEBUG}
      
      if sentenc_c < 1 then raise new System.ArgumentException($'sentenc_c было {sentenc_c}');
      
      {$endif DEBUG}
      
      var sb := new StringBuilder;
      
      while true do
      begin
        var ch := char(StepObj);
        if char.IsPunctuation(ch) and (ch <> ',') then
        begin
          sentenc_c -= 1;
          if sentenc_c = 0 then break;
        end;
        sb += ch;
      end;
      
      Result := sb.ToString;
    end;
    
    {$endregion Step}
    
    procedure Clear;
    begin
      h := new real[l];
    end;
    
    {$endregion I/O}
    
    {$region New}
    
    private constructor := exit;
    
    public class function GetNew(l: integer; obj_to_h: object->array of real; h_to_obj: function(a:array of real):object): RNN;
    begin
      Result := new RNN;
      
      Result.l := l;
      Result.obj_to_h := obj_to_h;
      Result.h_to_obj := h_to_obj;
      
      Result.h := new real[l];
      
      Result.b_hh := new real[l];
      Result.mtx_hh := new real[l,l];
      
      Result.b_ih := new real[l];
      Result.mtx_ih := new real[l,l];
      
      Result.b_ho := new real[l];
      Result.mtx_ho := new real[l,l];
      
      for var x := 0 to l-1 do
      begin
        Result.b_hh[x] := (Random*2-1)*1;
        Result.b_ih[x] := (Random*2-1)*1;
        Result.b_ho[x] := (Random*2-1)*1;
        
        for var y := 0 to l-1 do
        begin
          var todo_uncomment := 0;
          Result.mtx_hh[x,y] := (Random*2-1)*1;
          Result.mtx_ih[x,y] := (Random*2-1)*1;
          Result.mtx_ho[x,y] := (Random*2-1)*1;
        end;
      end;
    end;
    
    public class function GetNew(l: integer): RNN := GetNew(l, nil, nil);
    
    public class function GetNew(d:IDictionary<char,integer>) := GetNew(d.Count,
    o->
    begin
      Result := new real[d.Count];
      Result[d[char(o)]] := 1;
    end,
    h->
    begin
      var el := d.ElementAt(h.IndexMax);
      Result := object(el.Key);
    end);
    
    public class function GetNew(text: sequence of char): RNN;
    begin
      
      var d := new Dictionary<char,integer>;
      foreach var ch in text do
        if not d.ContainsKey(ch) then
          d[ch] := d.Count;
      
      Result := GetNew(d);
      
    end;
    
    {$endregion New}
    
  end;


implementation

function Round(a:sequence of real; digits:integer) := a.Select(x->Round(x,digits));

end.