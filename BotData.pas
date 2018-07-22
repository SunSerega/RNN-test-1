unit BotData;

interface

uses RNNData;

type
  Bot = class
    
    public brain: RNN;
    
    public tanining_k := 1/10;
    
    
    {$region Train}
    
    procedure Train(inp,otp:sequence of array of real);
    
    procedure Train(inp,otp:sequence of object) :=
    Train(
      inp.Select(o->brain.obj_to_h(o)),
      otp.Select(o->brain.obj_to_h(o))
    );
    
    procedure Train(inp,otp:string) :=
    Train(
      inp.Select(ch->object(ch)),
      otp.Select(ch->object(ch))
    );
    
    {$endregion Train}
    
    {$region GetResult}
    
    {$endregion GetResult}
    
    {$region constructor's}
    
    constructor(l:integer);
    begin
      brain := RNN.GetNew(l);
    end;
    
    constructor(texts: sequence of string);
    begin
      brain := RNN.GetNew(texts.SelectMany(s->s));
    end;
    
    {$endregion constructor's}
    
  end;

implementation

procedure Bot.Train(inp,otp:sequence of array of real);
begin
  
  var n_b_ih: array of real := Copy(brain.b_ih);
  var n_mtx_ih: array[,] of real := Copy(brain.mtx_ih);
  
  var n_b_hh: array of real := Copy(brain.b_hh);
  var n_mtx_hh: array[,] of real := Copy(brain.mtx_hh);
  
  var n_b_ho: array of real := Copy(brain.b_ho);
  var n_mtx_ho: array[,] of real := Copy(brain.mtx_ho);
  
  
  var c := 4;
  if inp is IList<array of real>(var l1) then
    if otp is IList<array of real>(var l2) then
      c := l1.Count + l2.Count;
  
  var h_states := new Stack<array of real>(c);
  var data_states := new Stack<array of real>(c);
  
  var paf_states := new Stack<array of real>(c);
  
  
  
  foreach var data in inp do
  begin
    h_states.Push(Copy(brain.h));
    data_states.Push(data);
    
    var nh := Copy(brain.b_hh);
    
    for var i1 := 0 to brain.l - 1 do
    begin
      nh[i1] += brain.b_ih[i1];
      
      for var i2 := 0 to brain.l - 1 do
        nh[i1] +=
          brain.mtx_hh[i2,i1] * brain.h[i2]+
          brain.mtx_ih[i2,i1] * data[i2];
    end;
    
    paf_states.Push(Copy(nh));//nh.ConvertAll(r->brain.d_act_func(r)));
    
    for var i1 := 0 to brain.l - 1 do
      nh[i1] := brain.act_func(nh[i1]);
    
    brain.h := nh;
    
  end;
  
  
  var otp_data_l := 0;
  
  foreach var data in otp do
  begin
    otp_data_l += 1;
    
    var nh := Copy(brain.b_hh);
    
    for var i1 := 0 to brain.l - 1 do
      for var i2 := 0 to brain.l - 1 do
        nh[i1] += 
          brain.mtx_hh[i2,i1] * brain.h[i2];
    
    paf_states.Push(Copy(nh));//nh.ConvertAll(r->brain.d_act_func(r)));
    
    for var i1 := 0 to brain.l - 1 do
      nh[i1] := brain.act_func(nh[i1]);
    
    brain.h := nh;
    
    var ndata := Copy(brain.b_ho);
    
    for var i1 := 0 to brain.l - 1 do
      for var i2 := 0 to brain.l - 1 do
        ndata[i1] +=
          brain.mtx_ho[i2,i1]*brain.h[i2];
    
    var res_paf := Copy(ndata);//.ConvertAll(r->brain.d_act_func(r));
    
    for var i1 := 0 to brain.l - 1 do
      ndata[i1] := brain.act_func(ndata[i1]);
    
    
    
    //writeln(Round(ndata,2));
    var cost_mlt := data.Select((r,i)->sqr(r-ndata[i])).Sum;
    writeln($'cost     is {cost_mlt}');
    if cost_mlt >= 1 then     cost_mlt := 1 else
    if cost_mlt >= 0.05 then {cost_mlt := cost_mlt} else
    if cost_mlt >= 0 then     cost_mlt := 0.0025/Power(cost_mlt,1.5);
    if cost_mlt > 10 then cost_mlt := 10;
    writeln($'cost_mlt is {cost_mlt}');
    
    
    var data_inf := new real[brain.l];
    
    for var i1 := 0 to brain.l-1 do
    begin
      begin//ToDo delete
        var rp := res_paf[i1];
        var drp := brain.d_act_func(res_paf[i1]);
        var nd := ndata[i1];
        var kd := (2*(data[i1]-ndata[i1]));
      end;
      
      var d :=
        tanining_k *
        brain.d_act_func(res_paf[i1]) *
        (2*(data[i1]-ndata[i1])) *
        cost_mlt;
      
      if abs(d) < 0.1 then d := Sign(d)*0.1;
      
      n_b_ho[i1] += d;//*1;
      
      for var i2 := 0 to brain.l-1 do
      begin
        n_mtx_ho[i1,i2] += d * res_paf[i2];  //(abs(res_paf[i2])>0.01? res_paf[i2] : Sign(res_paf[i2])*0.01);
        data_inf[i2] += d * n_mtx_ho[i1,i2]; //(abs(n_mtx_ho[i2,i1])>0.01? res_paf[i2] : Sign(n_mtx_ho[i2,i1])*0.01);
      end;
    end;
    
    var n_otp_data_l := otp_data_l;
    
    foreach var t:(array of real, array of real, array of real) in h_states.ZipTuple(data_states, paf_states) do
    begin
      var h_state := t.Item1;
      var data_state := t.Item2;
      var paf_state := t.Item3;
      
      if n_otp_data_l = 0 then
      begin
        
        //ToDo
        
      end else n_otp_data_l -= 1;
      
      //ToDo
      
    end;
    
  end;//of foreach var data in otp do
  
  brain.b_ho := n_b_ho;
  brain.mtx_ho := n_mtx_ho;
  
end;



end.