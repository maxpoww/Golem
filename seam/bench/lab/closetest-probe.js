// ---- close-button path test probe (never shipped) ----
try { (function(){
  var out=Services.env.get("NT_OUT"), phase=Services.env.get("NB_PHASE"); if(!out) return;
  var Ci=Components.interfaces, Cc=Components.classes, timers=[], log=[];
  function later(ms,fn){ var t=Cc["@mozilla.org/timer;1"].createInstance(Ci.nsITimer); t.initWithCallback({notify:function(){ try{fn();}catch(e){log.push("ERR "+e);} }},ms,0); timers.push(t); }
  function write(o){ var f=Cc["@mozilla.org/file/local;1"].createInstance(Ci.nsIFile); f.initWithPath(out); var os=Cc["@mozilla.org/network/file-output-stream;1"].createInstance(Ci.nsIFileOutputStream); os.init(f,0x02|0x08|0x20,420,0); var s=JSON.stringify(o); os.write(s,s.length); os.close(); }
  function tabs(w){ return w.gBrowser.tabs.map(function(t){ var u="?"; try{ u=t.linkedBrowser.currentURI.spec; }catch(e){} return u+(t.hasAttribute("pending")?"(pending)":""); }); }
  var started=false, SP=Services.scriptSecurityManager.getSystemPrincipal();
  Services.obs.addObserver({observe:function(w){ if(started) return; started=true;
    if(phase=="2"){ later(10000,function(){ write({phase:2,tabs:tabs(w)}); later(300,function(){ Services.startup.quit(Ci.nsIAppStartup.eForceQuit); }); }); return; }
    var steps=[
      [5000,function(){ w.gBrowser.selectedBrowser.fixupAndLoadURIString("https://example.com/",{triggeringPrincipal:SP}); }],
      [6000,function(){ w.gBrowser.addTab("https://www.wikipedia.org/",{triggeringPrincipal:SP}); }],
      [6000,function(){ w.BrowserCommands.openTab(); }],
      [2500,function(){ log.push("with a new tab: "+tabs(w)); w.gBrowser.selectedTab=w.gBrowser.tabs[0]; }],
      [1500,function(){ log.push("left it waiting: "+tabs(w)); write({phase:1,log:log}); }]
    ];
    var i=0; (function next(){ if(i>=steps.length) return; var s=steps[i++]; later(s[0],function(){ s[1](); next(); }); })();
  }},"browser-delayed-startup-finished");
})(); } catch(e) {}
