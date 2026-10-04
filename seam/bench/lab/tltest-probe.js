// ---- traffic lights test probe (never shipped) ----
try { (function(){
  var D=Services.env.get("TL_DIR"); if(!D) return;
  var Ci=Components.interfaces, Cc=Components.classes, timers=[];
  function later(ms,fn){ var t=Cc["@mozilla.org/timer;1"].createInstance(Ci.nsITimer); t.initWithCallback({notify:function(){ try{fn();}catch(e){ mark("ERR",{e:""+e}); } }},ms,0); timers.push(t); }
  function file(n){ var f=Cc["@mozilla.org/file/local;1"].createInstance(Ci.nsIFile); f.initWithPath(D+"/"+n); return f; }
  function mark(n,o){ var f=file("out-"+n+".json"); var os=Cc["@mozilla.org/network/file-output-stream;1"].createInstance(Ci.nsIFileOutputStream); os.init(f,0x02|0x08|0x20,420,0); var s=JSON.stringify(o); os.write(s,s.length); os.close(); }
  function r1(v){ return Math.round(v*10)/10; }
  function ev(w,n,type,x,y){ n.dispatchEvent(new w.MouseEvent(type,{bubbles:true,cancelable:true,view:w,button:0,clientX:x,clientY:y})); }
  function col(w,k){ return w.document.querySelector('#golem-traffic>div[data-golem-tl="'+k+'"]'); }
  function state(w){ var d=w.document, box=d.getElementById("golem-traffic"), bk=d.getElementById("back-button"); var o={lights:!!box};
    if(box){ o.display=box.style.display; o.first=(d.getElementById("nav-bar").firstChild===box); o.backX=bk?r1(bk.getBoundingClientRect().left):null;
      o.cols=Array.prototype.map.call(box.querySelectorAll(":scope>div"),function(n){ var q=n.getBoundingClientRect(); return [r1(q.left),r1(q.top),r1(q.width),r1(q.height)].join(" "); });
      o.discs=Array.prototype.map.call(box.querySelectorAll(":scope>div>i"),function(n){ var q=n.getBoundingClientRect(); return [r1(q.left),r1(q.top),r1(q.width),w.getComputedStyle(n).backgroundColor].join(" "); }); }
    o.active=(Services.focus.activeWindow===w); return o; }
  // where the hand would be: move the pointer to a point of a column and read what it answers
  function aim(w,k,x,y){ var c=col(w,k), i=c.querySelector("i"); ev(w,c,"mousemove",x,y); var cs=w.getComputedStyle(c);
    var o={at:[x,y],on:c.hasAttribute("data-on"),cursor:cs.cursor,disc:w.getComputedStyle(i).backgroundColor,grow:w.getComputedStyle(i).transform}; ev(w,c,"mouseleave",x,y); c.removeAttribute("data-on"); return o; }
  function aims(w){ var o={}; o.gap_between_red_and_orange=aim(w,"min",26,28); o.orange_bottom_of_bar=aim(w,"min",37,30); o.green_top_edge=aim(w,"tile",60,1);
    o.red_disc_centre=aim(w,"close",14,15); o.red_corner_miss=aim(w,"close",2,2); o.red_right_of_20px=aim(w,"close",23,29);
    var c=col(w,"close"); ev(w,c,"mousedown",2,2); o.press_in_corner_closed_window=w.closed; return o; }
  function click(w,k){ var c=col(w,k); if(!c) throw new Error("no light "+k); var q=c.querySelector("i").getBoundingClientRect(); ev(w,c,"mousedown",q.left+q.width/2,q.top+q.height/2); }
  function waitFor(n,fn){ var tries=0; (function p(){ if(file(n).exists()) fn(); else if(++tries<80) later(500,p); else mark("TIMEOUT-"+n,{}); })(); }
  var started=false;
  Services.obs.addObserver({observe:function(w){ if(started) return; started=true;
    later(9000,function(){ var sA=state(w); try{ sA.aim=aims(w); }catch(e){ sA.aimErr=""+e; } mark("A",sA);
      waitFor("go-B",function(){ click(w,"tile"); later(3000,function(){ mark("B",state(w));
        waitFor("go-C",function(){ var s=state(w); click(w,"min"); later(3500,function(){ mark("C",s);
          waitFor("go-D",function(){ mark("D",state(w)); later(500,function(){ click(w,"close"); }); }); }); }); }); });
    });
  }},"browser-delayed-startup-finished");
})(); } catch(e) {}
