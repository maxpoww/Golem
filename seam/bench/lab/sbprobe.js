// ---- SCROLL BENCH PROBE (test rig only, never shipped) ----
try { (function(){
  var D=Services.env.get("SB_DIR"), url=Services.env.get("SB_URL"); if(!D||!url) return;
  var Ci=Components.interfaces, Cc=Components.classes, timers=[], log=[];
  function later(ms,fn){ var t=Cc["@mozilla.org/timer;1"].createInstance(Ci.nsITimer); t.initWithCallback({notify:function(){ try{fn();}catch(e){ log.push("ERR "+e); write("result",{err:""+e,log:log}); } }},ms,0); timers.push(t); }
  function write(n,o){ var f=Cc["@mozilla.org/file/local;1"].createInstance(Ci.nsIFile); f.initWithPath(D+"/"+n+".json"); var os=Cc["@mozilla.org/network/file-output-stream;1"].createInstance(Ci.nsIFileOutputStream); os.init(f,0x02|0x08|0x20,420,0); var s=JSON.stringify(o); os.write(s,s.length); os.close(); }
  function snap(cb){ ChromeUtils.requestProcInfo().then(function(pi){ var o={}; o["parent"]={cpu:pi.cpuTime,mem:pi.memory}; pi.children.forEach(function(c){ var k=c.type+(c.origin?":"+c.origin.replace(/^https?:\/\//,""):""); o[k]={cpu:c.cpuTime,mem:c.memory}; }); cb(o); },function(e){ cb({err:""+e}); }); }
  function pv(n){ try{ var t=Services.prefs.getPrefType(n); if(t==32) return Services.prefs.getStringPref(n); if(t==64) return Services.prefs.getIntPref(n); if(t==128) return Services.prefs.getBoolPref(n); }catch(e){} return null; }
  var started=false;
  Services.obs.addObserver({observe:function(w){ if(started) return; started=true;
    later(3000,function(){
      var b=w.gBrowser.selectedBrowser;
      b.fixupAndLoadURIString(url,{triggeringPrincipal:Services.scriptSecurityManager.getSystemPrincipal()});
      var n=0; (function waitReady(){ var t=""; try{ t=b.contentTitle; }catch(e){}
        if(t==="READY"){
          later(1500,function(){
            var feats=["js","cpu","processcpu"], thr=["GeckoMain","Renderer","Compositor","RenderBackend"];
            try{ Services.profiler.StartProfiler(20000000, 1, feats, thr); }catch(e){ log.push("profiler start: "+e); }
            snap(function(s0){
              var st={}; try{ st.active=b.docShellIsActive; st.ov=w.document.documentElement.hasAttribute("golem-ov"); st.panel=(w.document.getElementById("tabbrowser-tabpanels")||{}).style.visibility; st.tabs=w.gBrowser.tabs.length; st.sel=w.gBrowser.selectedBrowser===b; st.url=b.currentURI.spec; st.focused=Services.focus.activeWindow===w; st.remote=b.isRemoteBrowser; }catch(e){ st.err=""+e; }
              var o={at:Date.now(), state:st, gfx:w.windowUtils.layerManagerType, prefs:{vsync:pv("widget.wayland.vsync.enabled"),partial:pv("gfx.webrender.max-partial-present-rects"),rate:pv("layout.frame_rate"),tabCache:pv("browser.tabs.remote.tabCacheSize")}, procs0:s0, inner:[w.innerWidth,w.innerHeight], outer:[w.outerWidth,w.outerHeight], screenX:w.screenX, screenY:w.screenY};
              w.__sbT0=w.performance.now(); write("ready",o);
              var m=0; (function waitDone(){ var t2=""; try{ t2=b.contentTitle; }catch(e){}
                if(t2.indexOf("BENCH")===0){
                  var t1=w.performance.now();
                  snap(function(s1){
                    var res={title:t2, ms:Math.round(t1-w.__sbT0), procs0:s0, procs1:s1, log:log};
                    try{ Services.profiler.Pause(); }catch(e){}
                    Services.profiler.dumpProfileToFileAsync(D+"/profile.json").then(function(){ res.profile="written"; try{ Services.profiler.StopProfiler(); }catch(e){} write("result",res); later(400,function(){ Services.startup.quit(Ci.nsIAppStartup.eForceQuit); }); },
                      function(e){ res.profile="ERR "+e; write("result",res); later(400,function(){ Services.startup.quit(Ci.nsIAppStartup.eForceQuit); }); });
                  });
                } else if(++m<120) later(250,waitDone); else { var o2={err:"no BENCH",title:t2,log:log}; try{ o2.active=b.docShellIsActive; o2.ov=w.document.documentElement.hasAttribute("golem-ov"); }catch(e){} write("result",o2); later(300,function(){ Services.startup.quit(Ci.nsIAppStartup.eForceQuit); }); }
              })();
            });
          });
        } else if(++n<240) later(250,waitReady); else { write("result",{err:"no READY",title:t,log:log}); later(300,function(){ Services.startup.quit(Ci.nsIAppStartup.eForceQuit); }); }
      })();
    });
  }},"browser-delayed-startup-finished");
})(); } catch(e) {}
