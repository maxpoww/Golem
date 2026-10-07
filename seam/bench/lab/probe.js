// ---- SEAM LAB PROBE (test rig only, never shipped) ----
try { (function(){
  var out=""; try{ out=Services.env.get("SEAM_PROBE"); }catch(e){}
  if(!out) return;
  var Ci=Components.interfaces, Cc=Components.classes, Cu=Components.utils;
  var wait=parseInt(Services.env.get("SEAM_PROBE_MS")||"40000",10);
  var urls=(Services.env.get("SEAM_PROBE_URLS")||"").split(" ").filter(function(x){return x;});
  var T0=Date.now(), paths={}, hosts={}, nreq=0, bytes=0, loads=[], notes=[];
  Services.obs.addObserver({observe:function(s){ try{ var ch=s.QueryInterface(Ci.nsIHttpChannel); var h=ch.URI.host; hosts[h]=(hosts[h]||0)+1; nreq++; var k=h+ch.URI.filePath.split("/").slice(0,6).join("/"); paths[k]=(paths[k]||0)+1; }catch(e){} }},"http-on-modify-request");
  Services.obs.addObserver({observe:function(s){ try{ var ch=s.QueryInterface(Ci.nsIHttpChannel); bytes+=ch.transferSize||0; }catch(e){} }},"http-on-stop-request");
  function write(o){ try{ var f=Cc["@mozilla.org/file/local;1"].createInstance(Ci.nsIFile); f.initWithPath(out);
    var os=Cc["@mozilla.org/network/file-output-stream;1"].createInstance(Ci.nsIFileOutputStream); os.init(f,0x02|0x08|0x20,420,0);
    var s=JSON.stringify(o,null,1); var c=Cc["@mozilla.org/intl/converter-output-stream;1"].createInstance(Ci.nsIConverterOutputStream); c.init(os,"UTF-8"); c.writeString(s); c.close(); }catch(e){} }
  var timers=[]; function later(ms,fn){ var t=Cc["@mozilla.org/timer;1"].createInstance(Ci.nsITimer); t.initWithCallback({notify:function(){ try{fn();}catch(e){notes.push("ERR "+e);} }},ms,0); timers.push(t); }
  function topWin(){ var e=Services.wm.getEnumerator("navigator:browser"); return e.hasMoreElements()?e.getNext():null; }
  function pv(n){ try{ var t=Services.prefs.getPrefType(n); if(t==32) return Services.prefs.getStringPref(n); if(t==64) return Services.prefs.getIntPref(n); if(t==128) return Services.prefs.getBoolPref(n); }catch(e){} return null; }
  function collect(){
    var r={ t:Date.now()-T0, nreq:nreq, kb:Math.round(bytes/1024), hosts:hosts, paths:paths, loads:loads, notes:notes };
    try{ var si=Services.startup.getStartupInfo(), p=si.process.getTime(); r.startup={}; for(var k in si){ try{ r.startup[k]=si[k].getTime()-p; }catch(e){} } }catch(e){ r.startupErr=""+e; }
    try{ var m=Cu.loadedESModules; r.esm=m.length; var g={}; m.forEach(function(u){ var k=u.replace(/^(resource|chrome|moz-src):\/\/+/,"").split("/").slice(0,3).join("/"); g[k]=(g[k]||0)+1; }); r.esmGroups=g; r.esmAll=m; }catch(e){ r.esmErr=""+e; }
    try{ r.wins=[]; var e=Services.wm.getEnumerator(null); while(e.hasMoreElements()){ var w=e.getNext(); var o={ type:w.document.documentElement.getAttribute("windowtype"), url:w.location.href };
        if(w.gBrowser){ o.tabs=w.gBrowser.tabs.map(function(t){ return t.linkedBrowser.currentURI.spec.slice(0,80); }); o.titles=w.gBrowser.tabs.map(function(t){ return t.linkedBrowser.contentTitle; }); o.dialog=!!(w.gDialogBox&&w.gDialogBox.isOpen); try{ o.gfx=w.windowUtils.layerManagerType; }catch(e){}
          o.sidebarBtn=!!w.document.getElementById("sidebar-button"); o.navbar=Array.prototype.map.call(w.document.querySelectorAll("#nav-bar-customization-target > *"),function(n){return n.id;}); }
        r.wins.push(o); } }catch(e){ r.winErr=""+e; }
    try{ var mr=Cc["@mozilla.org/memory-reporter-manager;1"].getService(Ci.nsIMemoryReporterManager); r.mem={}; ["residentUnique","heapAllocated","JSMainRuntimeGCHeap","JSMainRuntimeRealmsSystem","JSMainRuntimeRealmsUser","imagesContentUsedUncompressed","storageSQLite"].forEach(function(k){ try{ r.mem[k]=Math.round(mr[k]/1048576); }catch(e){} }); }catch(e){}
    try{ r.cfgErrors=Services.console.getMessageArray().map(function(m){ try{ var e=m.QueryInterface(Ci.nsIScriptError); return (e.sourceName||"").indexOf("mozilla.cfg")>=0 ? ((e.flags&1)?"warn: ":"ERROR: ")+e.errorMessage+" @"+e.lineNumber : null; }catch(x){ var t=""+(m.message||m); return t.indexOf("mozilla.cfg")>=0?t.slice(0,200):null; } }).filter(function(x){return x;}).slice(0,40); }catch(e){ r.cfgErrors=["collect: "+e]; }
    r.prefs={}; (Services.env.get("SEAM_PROBE_PREFS")||"").split(" ").forEach(function(n){ if(n) r.prefs[n]=pv(n); });
    var done0=function(){ write(r); if(Services.env.get("SEAM_PROBE_QUIT")=="1") later(500,function(){ Services.startup.quit(Ci.nsIAppStartup.eAttemptQuit); }); };
    var done=function(){ var pf=""; try{ pf=Services.env.get("SEAM_PROBE_PROFILE"); }catch(e){}
      if(pf && Services.profiler && Services.profiler.IsActive()){ Services.profiler.dumpProfileToFileAsync(pf).then(function(){ r.profile="written"; done0(); },function(e){ r.profile="ERR "+e; done0(); }); } else done0(); };
    var pend=2, fin=function(){ if(--pend==0) done(); };
    var snap=function(pi){ var o={}; [{pid:pi.pid,type:"parent",memory:pi.memory,cpuTime:pi.cpuTime,windows:[]}].concat(pi.children).forEach(function(c){ o[c.pid]={type:c.type,mb:Math.round(c.memory/1048576),cpu:Math.round(c.cpuTime/1e6),origin:c.origin||"",docs:(c.windows||[]).map(function(w){ try{return w.documentURI.spec.slice(0,50);}catch(e){return "?";} })}; }); return o; };
    try{ ChromeUtils.requestProcInfo().then(function(pi){ var a=snap(pi); later(10000,function(){ ChromeUtils.requestProcInfo().then(function(pi2){ var b=snap(pi2); r.procs=Object.keys(b).map(function(k){ var x=b[k]; x.idle10=a[k]?x.cpu-a[k].cpu:-1; return x; }); fin(); },function(e){ r.procErr=""+e; fin(); }); }); },function(e){ r.procErr=""+e; fin(); }); }catch(e){ r.procErr=""+e; fin(); }
    try{ var AM=ChromeUtils.importESModule("resource://gre/modules/AddonManager.sys.mjs").AddonManager; AM.getAllAddons().then(function(a){ r.addons=a.filter(function(x){return x.type=="extension";}).map(function(x){ return x.id+(x.isActive?"":" (off)")+(x.isBuiltin?" [builtin]":""); }); fin(); },function(e){ fin(); }); }catch(e){ r.addonErr=""+e; fin(); }
  }
  // per-load navigation phases from the page (PerformanceNavigationTiming): DNS / connect / TLS / first byte / DCL / load / FCP
  var PH_FS='data:,'+encodeURIComponent('(function(){ addMessageListener("probe:phases",function(m){ try{ var T=content.performance.timing, N=content.performance.getEntriesByType("navigation")[0], P=content.performance.getEntriesByType("paint").filter(function(e){ return e.name==="first-contentful-paint"; })[0]; var r={id:m.data.id, rs:T.responseStart-T.navigationStart, dcl:T.domContentLoadedEventEnd-T.navigationStart, load:T.loadEventEnd>0?T.loadEventEnd-T.navigationStart:0, fcp:P?Math.round(P.startTime):0}; if(N){ r.dns=Math.round(N.domainLookupEnd-N.domainLookupStart); r.connect=Math.round(N.connectEnd-N.connectStart); r.tls=N.secureConnectionStart?Math.round(N.connectEnd-N.secureConnectionStart):0; r.ttfb=Math.round(N.responseStart-N.requestStart); r.proto=N.nextHopProtocol; r.transfer=N.transferSize; r.fetchStart=Math.round(N.fetchStart); r.redirect=Math.round(N.redirectEnd-N.redirectStart); r.workerStart=Math.round(N.workerStart); r.requestStart=Math.round(N.requestStart); r.respEnd=Math.round(N.responseEnd); } sendAsyncMessage("probe:phases:answer",r); }catch(e){ sendAsyncMessage("probe:phases:answer",{id:m.data.id,err:""+e}); } }); })();');
  var phasesOn=false, phaseWait={};
  function phasesInit(){ if(phasesOn) return; phasesOn=true; try{ Services.mm.loadFrameScript(PH_FS,true); Services.mm.addMessageListener("probe:phases:answer",function(m){ var d=m.data||{}; var e=phaseWait[d.id]; if(!e) return; delete phaseWait[d.id]; delete d.id; e.phases=d; }); }catch(e){ notes.push("phases ERR "+e); } }
  function loadNext(i){
    var w=topWin(); if(!w||i>=urls.length){ later(wait,collect); return; }
    phasesInit();
    var t1=Date.now(), fired=false, tab=null;
    var doneOne=function(why){ if(fired) return; fired=true; var entry={url:urls[i],ms:Date.now()-t1,why:why}; loads.push(entry);
      later(400,function(){ try{ var id=i+":"+t1; phaseWait[id]=entry; tab.linkedBrowser.messageManager.sendAsyncMessage("probe:phases",{id:id}); }catch(e){ entry.phases={err:""+e}; } });
      later(1500,function(){ loadNext(i+1); }); };
    try{ tab=w.gBrowser.addTab(urls[i],{triggeringPrincipal:Services.scriptSecurityManager.getSystemPrincipal()}); w.gBrowser.selectedTab=tab;
      var lis={ QueryInterface:ChromeUtils.generateQI(["nsIWebProgressListener","nsISupportsWeakReference"]),
        onStateChange:function(wp,req,fl){ if(wp.isTopLevel && (fl&Ci.nsIWebProgressListener.STATE_STOP) && (fl&Ci.nsIWebProgressListener.STATE_IS_NETWORK)){ var u=""; try{u=tab.linkedBrowser.currentURI.spec;}catch(e){} if(u.indexOf("about:")!=0) doneOne("stop"); } },
        onLocationChange:function(){},onProgressChange:function(){},onStatusChange:function(){},onSecurityChange:function(){},onContentBlockingEvent:function(){} };
      tab.__probeLis=lis; tab.linkedBrowser.addProgressListener(lis,Ci.nsIWebProgress.NOTIFY_STATE_ALL);
    }catch(e){ notes.push("load ERR "+e); }
    later(30000,function(){ doneOne("timeout"); });
  }
  var started=false;
  Services.obs.addObserver({observe:function(){ if(started) return; started=true; notes.push("delayed-startup +"+(Date.now()-T0)); if(urls.length) later(6000,function(){ loadNext(0); }); else later(wait,collect); }},"browser-delayed-startup-finished");
})(); } catch(e) {}
