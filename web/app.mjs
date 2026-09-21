import { solve_demo } from '/solver.mjs';
const el = id => document.getElementById(id);
const presets = {
  sqrt: { target: 2, text: '教学：求 x² = 目标值 的非负根。返回位置 x，无量纲。' },
  calibration: { target: 2.375, text: '模拟标定：y = 1 + 0.5x + 0.02x²，x ∈ [0,10]。目标响应范围 [1,8]，输入与响应均为归一化无量纲值。' },
  cooling: { target: 50, text: '模拟冷却：T(t) = 20 + 60 exp(-0.1t)，搜索 [0,60] 分钟。目标单位 °C，根和绝对位置容差单位为分钟。' },
};
let latest;
function text(tag, value, parent) { const node = document.createElement(tag); node.textContent = value; parent.append(node); return node; }
function svg(tag, attributes) { const node = document.createElementNS('http://www.w3.org/2000/svg', tag); for (const [k,v] of Object.entries(attributes)) node.setAttribute(k, v); el('plot').append(node); return node; }
function draw(trace) {
  el('plot').replaceChildren();
  const values = trace.map(b => Math.log10(b.upper - b.lower));
  const finite = values.filter(Number.isFinite);
  const high = Math.max(...finite, 0), low = Math.min(...finite, high - 1);
  const x = i => 64 + 714 * i / Math.max(trace.length - 1, 1);
  const y = v => Number.isFinite(v) ? 22 + 178 * (high - v) / (high - low) : 208;
  for (let i=0;i<4;i++) {
    const value = high - (high-low)*i/3, position = y(value);
    svg('line', {x1:64,x2:778,y1:position,y2:position,stroke:'#e0e8ed'});
    svg('text', {x:54,y:position+4,'text-anchor':'end',fill:'#526372','font-size':11}).textContent = value.toFixed(1);
  }
  svg('polyline', {points:values.map((v,i)=>`${x(i)},${y(v)}`).join(' '),fill:'none',stroke:'#136d71','stroke-width':2});
  values.forEach((v,i)=>{ if (!Number.isFinite(v)) svg('circle',{cx:x(i),cy:y(v),r:4,fill:'white',stroke:'#136d71','stroke-width':2}); });
  svg('text',{x:64,y:233,fill:'#526372','font-size':11}).textContent='0';
  svg('text',{x:778,y:233,'text-anchor':'end',fill:'#526372','font-size':11}).textContent=String(Math.max(trace.length-1,0));
}
function clearResult() {
  latest = undefined;
  for (const id of ['metrics','trace','plot']) el(id).replaceChildren();
  el('table-note').textContent='';
  el('json').disabled = el('csv').disabled = true;
}
function run(event) {
  event?.preventDefault(); clearResult();
  const target = Number(el('target').value), budget = Number(el('budget').value);
  const atol = Number(el('atol').value), rtol = Number(el('rtol').value);
  try {
    if (!el('form').checkValidity() || ![target,atol,rtol].every(Number.isFinite) || !Number.isInteger(budget) || budget < 0 || budget > 10000) throw Error('请填写有限数值；演示页迭代预算为 0–10000 的整数。');
    const result = JSON.parse(solve_demo(el('scenario').value,target,el('method').value,atol,rtol,budget));
    if (!result.ok) throw Error(result.error);
    const s = result.solution;
    latest = { ...result, input: { scenario: el('scenario').value, target, algorithm: el('method').value, atol, rtol, budget } };
    el('status').textContent = `${s.converged ? '已满足停止条件' : '尚未收敛，请检查预算与容差'} · ${s.reason}`;
    el('status').className = s.converged ? '' : 'error';
    for (const [label,value] of [['根估计',s.root],['函数残差',s.value],['迭代 / 求值次数',`${s.iterations} / ${s.evaluations}`],['最终下界',s.bracket.lower],['最终上界',s.bracket.upper],['区间宽度',s.bracket.upper-s.bracket.lower]]) {
      const group = text('div','',el('metrics')); text('dt',label,group); text('dd',String(value),group);
    }
    draw(s.trace);
    s.trace.slice(0,200).forEach((b,i)=>{ const row=text('tr','',el('trace')); for (const value of [i,b.lower,b.upper,b.f_lower,b.f_upper]) text('td',String(value),row); });
    el('table-note').textContent = `共 ${s.trace.length} 条快照；表格最多显示前 200 条，导出包含完整轨迹。`;
    el('json').disabled = el('csv').disabled = false;
  } catch (error) { el('status').textContent = `输入或模型错误：${error.message}`; el('status').className='error'; }
}
el('form').addEventListener('submit',run);
el('form').addEventListener('input',()=>{
  clearResult(); el('status').textContent='参数已更改，请运行求解。'; el('status').className='';
});
el('scenario').addEventListener('change',()=>{ const preset=presets[el('scenario').value]; el('target').value=preset.target; el('model').textContent=preset.text; run(); });
for (const format of ['json','csv']) el(format).addEventListener('click',()=>{
  if (!latest) return;
  const blob=new Blob([format==='json' ? JSON.stringify(latest,null,2) : latest.csv],{type:format==='json'?'application/json':'text/csv'});
  const url=URL.createObjectURL(blob), a=document.createElement('a');
  a.href=url; a.download=`bracket-root-${latest.input.scenario}.${format}`; a.click(); setTimeout(()=>URL.revokeObjectURL(url),1000);
});
el('model').textContent=presets.sqrt.text;
run();
