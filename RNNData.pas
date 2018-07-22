unit RNNData;

interface

function Round(a:sequence of real; digits:integer):sequence of real;

type
  RNNLayer=class
    
    const tanining_k = 0.01;
    
    public l_from, l_to: integer;
    
    public h:array of real;
    public prev:array of real;//only pointer
    
    public b: array of real;
    
    public mtx_ih: array[,] of real;
    public mtx_hh: array[,] of real;
    
    
    public bp_inp: array of real;
    public bp_ph: array of real;
    public bp_paf_h: array of real;
    
    
    
    public function act_func(x: real) := System.Math.Tanh(x);
    public function d_act_func(x: real) := 1/Sqr(System.Math.Cosh(x));
    
    
    
    public procedure Calc;
    begin
      
      var nh := Copy(b);
      
      for var i1 := 0 to l_to - 1 do
      begin
        
        for var i2 := 0 to l_from - 1 do
          nh[i1] +=
            mtx_ih[i2,i1] * prev[i2];
        
        for var i2 := 0 to l_to - 1 do
          nh[i1] +=
            mtx_hh[i2,i1] * h[i2];
        
        nh[i1] := act_func(nh[i1]);
      end;
      
      h := nh;
      
    end;
    
    public procedure BackPropCalc;
    begin
      
      var nh := Copy(b);
      
      for var i1 := 0 to l_to - 1 do
      begin
        
        for var i2 := 0 to l_from - 1 do
          nh[i1] +=
            mtx_ih[i2,i1] * prev[i2];
        
        for var i2 := 0 to l_to - 1 do
          nh[i1] +=
            mtx_hh[i2,i1] * h[i2];
        
      end;
      
      bp_ph := h;//Copy(h);
      bp_inp := prev;//Copy(prev);
      bp_paf_h := Copy(nh);
      
      for var i1 := 0 to l_to - 1 do
        nh[i1] := act_func(nh[i1]);
      
      h := nh;
      
    end;
    
    public function BackProp(dh:array of real):array of real;
    begin
      Result := new real[l_from];
      
      for var i1 := 0 to l_to-1 do
      begin
        
        var d :=
          d_act_func(bp_paf_h[i1]) *
          ( 2*dh[i1] ) *
          tanining_k;
        
        b[i1] += d;//*1
        
        for var i2 := 0 to l_to - 1 do
          mtx_hh[i2, i1] += d * bp_ph[i2];
        
        for var i2 := 0 to l_from - 1 do
        begin
          
          Result[i2] += d * mtx_ih[i2,i1];
          mtx_ih[i2,i1] += d * bp_inp[i2];
          
        end;
        
      end;
      
    end;
    
    
    procedure Clear :=
    h := new real[l_to];
    
    
    
    public constructor(l_from, l_to:integer);
    begin
      self.l_from := l_from;
      self.l_to := l_to;
      
      h := new real[l_to];
      
      b := new real[l_to];
      mtx_ih := new real[l_from, l_to];
      mtx_hh := new real[l_to,   l_to];
      
      for var i2 := 0 to l_to-1 do
      begin
        
        b[i2] := (Random*2-1);//*1;
        
        for var i1 := 0 to l_from-1 do
          mtx_ih[i1,i2] := (Random*2-1);//*1;
        
        for var i1 := 0 to l_to-1 do
          mtx_hh[i1,i2] := (Random*2-1);//*1;
        
      end;
      
    end;
    
  end;
  
  RNN = class
    
    public l_from, l_to: integer;
    public lrs: array of RNNLayer;
    
    public obj_to_h: object->array of real;
    public h_to_obj: function(a:array of real):object;
    
    
    
    {$region I/O}
    
    public function Step(inp:array of real): array of real;
    begin
      
      lrs[0].prev := inp;
      
      foreach var lr in lrs do
        lr.Calc;
      
      Result := lrs[lrs.Length-1].h;
      
    end;
    
    public function Step(inp:sequence of array of real):=
    inp.Select(a->Step(a));
    
    public function StepObj(o:object): object := h_to_obj(Step(obj_to_h(o)));
    
    public function StepText(length: integer): string;
    begin
      var sb := new StringBuilder(length);
      var last := new real[l_from];
      
      loop length do
      begin
        last := Step(last);
        
        sb += char(h_to_obj(last));
      end;
      
      Result := sb.ToString;
    end;
    
    public function StepWords(words_c: integer := 1): string;
    begin
      {$ifdef DEBUG}
      
      if words_c < 1 then raise new System.ArgumentException($'words_c было {words_c}');
      
      {$endif DEBUG}
      
      var sb := new StringBuilder;
      var last := new real[l_from];
      
      while true do
      begin
        last := Step(last);
        
        var ch := char(h_to_obj(last));
        if ch = ' ' then
        begin
          words_c -= 1;
          if words_c = 0 then break;
        end;
        sb += ch;
      end;
      
      Result := sb.ToString;
    end;
    
    public function StepSentences(sentenc_c: integer := 1): string;
    begin
      {$ifdef DEBUG}
      
      if sentenc_c < 1 then raise new System.ArgumentException($'sentenc_c было {sentenc_c}');
      
      {$endif DEBUG}
      
      var sb := new StringBuilder;
      var last := new real[l_from];
      
      while true do
      begin
        last := Step(last);
        
        var ch := char(h_to_obj(last));
        if char.IsPunctuation(ch) and (ch <> ',') then
        begin
          sentenc_c -= 1;
          if sentenc_c = 0 then break;
        end;
        sb += ch;
      end;
      
      Result := sb.ToString;
    end;
    
    
    public function BackPropStep(inp:array of real): array of real;
    begin
      
      lrs[0].prev := inp;
      
      foreach var lr in lrs do
        lr.BackPropCalc;
      
      Result := lrs[lrs.Length-1].h;
      
    end;
    
    public procedure BackProp(otp, exp: array of real);
    begin
      
      var dh := exp;
      for var i := 0 to l_to-1 do
        dh[i] -= otp[i];
      
      for var i := lrs.Length-1 downto 0 do
        dh := lrs[i].BackProp(dh);
      
    end;
    
    public procedure Train(inp, otp: array of real) :=
    BackProp(BackPropStep(inp),otp);
    
    public procedure Train(inp, otp: sequence of char);
    begin
      var i_enm := inp.GetEnumerator;
      var o_enm := inp.GetEnumerator;
      
      while i_enm.MoveNext and o_enm.MoveNext do
        Train(
          obj_to_h(i_enm.Current),
          obj_to_h(o_enm.Current)
        );
    end;
    
    public procedure Train(text: sequence of char) := Train(char(0)+text, text);
    
    procedure Clear :=
    foreach var lr in lrs do
      lr.Clear;
    
    {$endregion I/O}
    
    {$region New}
    
    private constructor := exit;
    
    public class function GetNew(lrs: array of integer; obj_to_h: object->array of real; h_to_obj: function(a:array of real):object): RNN;
    begin
      Result := new RNN;
      
      Result.l_from := lrs[0];
      Result.l_to := lrs[lrs.Length-1];
      
      Result.obj_to_h := obj_to_h;
      Result.h_to_obj := h_to_obj;
      
      Result.lrs := new RNNLayer[lrs.Length-1];
      for var i := 0 to lrs.Length-2 do
      begin
        Result.lrs[i] := new RNNLayer(lrs[i],lrs[i+1]);
        
        if i <> 0 then
          Result.lrs[i].prev := Result.lrs[i-1].h;
      end;
      
      //var lr0 := Result.lrs[0];
      //var lr1 := Result.lrs[1];
      //var lr2 := Result.lrs[2];
      
    end;
    
    public class function GetNew(lrs: array of integer): RNN := GetNew(lrs, nil, nil);
    
    public class function GetNew(d:IDictionary<char,integer>) := GetNew(
    Arr(
      d.Count,
      d.Count + d.Count div 2,
      d.Count + d.Count div 2,
      d.Count
    ),
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