// ---- look probe (never shipped): geometry of the top bar ----
try { (function(){
  var D=Services.env.get("TL_DIR"); if(!D) return;
  var Ci=Components.interfaces, Cc=Components.classes, timers=[];
  function later(ms,fn){ var t=Cc["@mozilla.org/timer;1"].createInstance(Ci.nsITimer); t.initWithCallback({notify:function(){ try{fn();}catch(e){ mark({e:""+e}); } }},ms,0); timers.push(t); }
  function mark(o){ var f=Cc["@mozilla.org/file/local;1"].createInstance(Ci.nsIFile); f.initWithPath(D+"/out.json"); var os=Cc["@mozilla.org/network/file-output-stream;1"].createInstance(Ci.nsIFileOutputStream); os.init(f,0x02|0x08|0x20,420,0); var s=JSON.stringify(o); os.write(s,s.length); os.close(); }
  function R(n){ if(!n) return null; var q=n.getBoundingClientRect(), r=function(v){ return Math.round(v*10)/10; }; return {x:r(q.left),top:r(q.top),h:r(q.height),w:r(q.width),cy:r(q.top+q.height/2)}; }
  var started=false;
  Services.obs.addObserver({observe:function(w){ if(started) return; started=true;
    later(9000,function(){ var d=w.document, o={};
      o.navbar=R(d.getElementById("nav-bar")); o.toolbox=R(d.getElementById("navigator-toolbox"));
      var bk=d.getElementById("back-button"); o.back=R(bk); o.backIcon=R(bk&&bk.querySelector(".toolbarbutton-icon"));
      var rl=d.getElementById("stop-reload-button"); o.reloadIcon=R(rl&&rl.querySelector("#reload-button .toolbarbutton-icon"));
      o.urlbarContainer=R(d.getElementById("urlbar-container")); o.urlbar=R(d.getElementById("urlbar")); o.urlbarBg=R(d.querySelector("#urlbar .urlbar-background")); o.urlbarInput=R(d.getElementById("urlbar-input"));
      o.ov=R(d.getElementById("golem-overview-btn")); o.ubo=R(d.getElementById("ublock0_raymondhill_net-browser-action"));
      var box=d.getElementById("golem-traffic"); o.lightsDisplay=box?box.style.display:null; o.light0=R(box&&box.querySelector("div")); o.content=R(d.getElementById("tabbrowser-tabbox"));
      var cs=w.getComputedStyle(d.documentElement); o.vars={}; ["--urlbar-min-height","--urlbar-container-padding","--toolbarbutton-inner-padding","--toolbarbutton-outer-padding","--toolbar-start-end-padding","--urlbar-height"].forEach(function(k){ o.vars[k]=cs.getPropertyValue(k); });
      var nb=w.getComputedStyle(d.getElementById("nav-bar")); o.navPad=[nb.paddingTop,nb.paddingBottom,nb.minHeight]; var uc=d.getElementById("urlbar-container"); if(uc){ var u=w.getComputedStyle(uc); o.ucPad=[u.paddingTop,u.paddingBottom,u.marginTop,u.marginBottom,u.getPropertyValue("--urlbar-container-padding"),u.getPropertyValue("--urlbar-min-height"),u.getPropertyValue("--urlbar-height")]; }
      mark(o); });
  }},"browser-delayed-startup-finished");
})(); } catch(e) {}
