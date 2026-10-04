// ---- traffic lights test probe (never shipped) ----
try { (function(){
  var D=Services.env.get("TL_DIR"); if(!D) return;
  var Ci=Components.interfaces, Cc=Components.classes, timers=[];
  function later(ms,fn){ var t=Cc["@mozilla.org/timer;1"].createInstance(Ci.nsITimer); t.initWithCallback({notify:function(){ try{fn();}catch(e){ mark("ERR",{e:""+e}); } }},ms,0); timers.push(t); }
  function file(n){ var f=Cc["@mozilla.org/file/local;1"].createInstance(Ci.nsIFile); f.initWithPath(D+"/"+n); return f; }
  function mark(n,o){ var f=file("out-"+n+".json"); var os=Cc["@mozilla.org/network/file-output-stream;1"].createInstance(Ci.nsIFileOutputStream); os.init(f,0x02|0x08|0x20,420,0); var s=JSON.stringify(o); os.write(s,s.length); os.close(); }
  function state(w){ var d=w.document, box=d.getElementById("golem-traffic"), bk=d.getElementById("back-button"); var o={lights:!!box};
    if(box){ var r=box.getBoundingClientRect(), b=bk?bk.getBoundingClientRect():null; o.display=box.style.display; o.x=Math.round(r.left); o.w=Math.round(r.width); o.backX=b?Math.round(b.left):null; o.first=(d.getElementById("nav-bar").firstChild===box);
      o.colors=Array.prototype.map.call(box.querySelectorAll("div"),function(n){ return w.getComputedStyle(n).backgroundColor+" "+Math.round(n.getBoundingClientRect().width); }); }
    o.active=(Services.focus.activeWindow===w); return o; }
  function click(w,k){ var n=w.document.querySelector('#golem-traffic [data-golem-tl="'+k+'"]'); if(!n) throw new Error("no light "+k); n.click(); }
  function waitFor(n,fn){ var tries=0; (function p(){ if(file(n).exists()) fn(); else if(++tries<80) later(500,p); else mark("TIMEOUT-"+n,{}); })(); }
  var started=false;
  Services.obs.addObserver({observe:function(w){ if(started) return; started=true;
    later(9000,function(){ mark("A",state(w));
      waitFor("go-B",function(){ click(w,"tile"); later(3000,function(){ mark("B",state(w));
        waitFor("go-C",function(){ var s=state(w); click(w,"min"); later(3500,function(){ mark("C",s);
          waitFor("go-D",function(){ mark("D",state(w)); later(500,function(){ click(w,"close"); }); }); }); }); }); });
    });
  }},"browser-delayed-startup-finished");
})(); } catch(e) {}
