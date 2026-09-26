
// ===================================================================
// BEAM BENCH HOOK — appended to mozilla.cfg ONLY by bench.sh, identically for every
// browser variant (stock Firefox and Beam), so the measurement itself is the same.
// Inert unless BEAM_BENCH=<result file>. Measures: startup timestamps, page-load times
// over a local corpus, memory across processes, and scroll smoothness + CPU (all
// processes) while scrolling a heavy page. Never shipped in Beam.
// ===================================================================
try {
  var BB_OUT="", BB_BASE="";
  try{ BB_OUT=Services.env.get("BEAM_BENCH"); BB_BASE=Services.env.get("BEAM_BENCH_HTTP"); }catch(e){}
  if(BB_OUT){
    var bbWrite=function(obj){ try{ var f=Components.classes["@mozilla.org/file/local;1"].createInstance(Components.interfaces.nsIFile); f.initWithPath(BB_OUT);
      var os=Components.classes["@mozilla.org/network/file-output-stream;1"].createInstance(Components.interfaces.nsIFileOutputStream); os.init(f,0x02|0x08|0x20,0o644,0);
      var s=JSON.stringify(obj); os.write(s,s.length); os.close(); }catch(e){} };
    var bbProc=async function(){ var p=await ChromeUtils.requestProcInfo(); var cpu=p.cpuTime, rss=p.memory, n=1, web=0, ext=0;
      (p.children||[]).forEach(function(c){ cpu+=c.cpuTime; rss+=c.memory; n++; if(/^web/.test(c.type)||c.type==="withCoopCoep") web+=c.cpuTime; if(c.type==="extension") ext+=c.cpuTime; });
      return {cpuMs:cpu/1e6, memMB:rss/1048576, procs:n, parentMs:p.cpuTime/1e6, webMs:web/1e6, extMs:ext/1e6}; };
    Services.obs.addObserver({observe:function(w){
      if(w.__bbDone) return; w.__bbDone=true;
      var R={startup:{}, loads:[], errors:[]};
      try{ var si=Services.startup.getStartupInfo(); var t0=si.process.getTime();
        ["main","firstPaint","sessionRestored"].forEach(function(k){ if(si[k]) R.startup[k+"Ms"]=si[k].getTime()-t0; });
        R.startup.delayedStartupMs=Date.now()-t0; }catch(e){ R.errors.push("startup:"+e); }
      var gb=w.gBrowser, pages=["p-text","p-dom","p-img","p-css","p-long"], i=0;
      var loadOne=function(url,cb){
        var b=gb.selectedBrowser, t=Date.now(), done=false;
        var L={ onStateChange:function(wp,req,fl){ var W=Components.interfaces.nsIWebProgressListener;
          if(!done && (fl&W.STATE_STOP) && (fl&W.STATE_IS_WINDOW) && wp.isTopLevel){ done=true; b.removeProgressListener(L); cb(Date.now()-t); } },
          QueryInterface:ChromeUtils.generateQI(["nsIWebProgressListener","nsISupportsWeakReference"]) };
        b.addProgressListener(L, Components.interfaces.nsIWebProgress.NOTIFY_STATE_WINDOW);
        b.loadURI(Services.io.newURI(url),{triggeringPrincipal:Services.scriptSecurityManager.getSystemPrincipal()});
        w.setTimeout(function(){ if(!done){ done=true; try{ b.removeProgressListener(L); }catch(e){} cb(-1); } },30000);
      };
      var scrollTest=function(cb){
        // frame script in the page: rAF loop scrolling 40px/frame for 240 frames, reports frame deltas
        var FS="data:application/javascript,"+encodeURIComponent(
          "(function(){var d=[],last=0,n=0;function f(ts){if(last)d.push(ts-last);last=ts;content.scrollBy(0,40);if(++n<240)content.requestAnimationFrame(f);else sendAsyncMessage('bb:scroll',{d:d});}content.requestAnimationFrame(f);})();");
        var before=null, writes=0, blocked=0, mon=true, last=w.performance.now(), notifies=0, props={};
        var sk0=(function(){ try{ return ChromeUtils.importESModule("resource://gre/modules/LightweightThemeConsumer.sys.mjs").LightweightThemeConsumer.prototype.__golemSkipped||0; }catch(e){ return 0; } })();
        var tobs={observe:function(){ if(mon) notifies++; }}; Services.obs.addObserver(tobs,"lightweight-theme-styling-update");
        var mo=new w.MutationObserver(function(ms){ writes+=ms.length; ms.forEach(function(m){ var st=m.oldValue||""; }); });
        var prevStyle=w.document.documentElement.getAttribute("style")||"";
        var mo2=new w.MutationObserver(function(){ var cur=w.document.documentElement.getAttribute("style")||""; var a=prevStyle.split(";"), b=cur.split(";"); b.forEach(function(x){ if(a.indexOf(x)===-1){ var k=x.split(":")[0].trim(); if(k) props[k]=(props[k]||0)+1; } }); prevStyle=cur; });
        mo2.observe(w.document.documentElement,{attributes:true,attributeFilter:["style"]}); mo.observe(w.document.documentElement,{attributes:true,attributeFilter:["style"]});
        (function tick(){ if(!mon) return; var n=w.performance.now(), late=n-last-4; if(late>6) blocked+=late; last=n; w.setTimeout(tick,4); })();
        gb.selectedBrowser.messageManager.addMessageListener("bb:scroll",async function(m){
          var after=await bbProc(); var d=m.data.d.slice().sort(function(a,b){return a-b;});
          var q=function(p){ return d.length?Math.round(d[Math.min(d.length-1,Math.floor(p*d.length))]*10)/10:null; };
          mon=false; try{ mo.disconnect(); mo2.disconnect(); Services.obs.removeObserver(tobs,"lightweight-theme-styling-update"); }catch(e){}
          cb({frames:d.length, p50:q(.5), p95:q(.95), max:d.length?Math.round(d[d.length-1]*10)/10:null, janky:d.filter(function(x){return x>25;}).length,
              cpuMs:Math.round(after.cpuMs-before.cpuMs), parentMs:Math.round(after.parentMs-before.parentMs), webMs:Math.round(after.webMs-before.webMs), extMs:Math.round(after.extMs-before.extMs),
              rootWrites:writes, uiBlockedMs:Math.round(blocked), themeSkipped:(function(){ try{ return (ChromeUtils.importESModule("resource://gre/modules/LightweightThemeConsumer.sys.mjs").LightweightThemeConsumer.prototype.__golemSkipped||0)-sk0; }catch(e){ return null; } })(),
              themeNotifies:notifies, themeProps:props});
        });
        R.preScroll={active:gb.selectedBrowser.docShellIsActive, renderLayers:gb.selectedBrowser.renderLayers, panelVis:(w.document.getElementById("tabbrowser-tabpanels")||{style:{}}).style.visibility, ovAttr:w.document.documentElement.hasAttribute("golem-ov"), ovOpen:!!(w.document.getElementById("golem-overview")&&w.document.getElementById("golem-overview").style.display!=="none")};
        gb.selectedBrowser.messageManager.addMessageListener("bb:vis",function(m){ R.pageVis=m.data; bbWrite(R); });
        gb.selectedBrowser.messageManager.loadFrameScript("data:application/javascript,"+encodeURIComponent("sendAsyncMessage('bb:vis',{vis:content.document.visibilityState,hidden:content.document.hidden});"),false);
        bbWrite(R);
        bbProc().then(function(p){ before=p; gb.selectedBrowser.messageManager.loadFrameScript(FS,false); });
      };
      R.stage="started"; bbWrite(R);
      // ---- REAL-SITES mode (BEAM_BENCH_URLS=comma list): cold-cache loads over the network
      var SITES=""; try{ SITES=Services.env.get("BEAM_BENCH_URLS"); }catch(e){}
      if(SITES){
        var urls=SITES.split(","), k=0, cpu0=null; R.sites=[];
        // count at the source: every HTTP response the browser actually receives (blocked
        // requests never get here; sizes are real regardless of CORS/TAO)
        var NET={n:0,kb:0,n3:0,kb3:0,host:"",hosts:{}};
        Services.obs.addObserver({observe:function(ch){ try{ ch.QueryInterface(Components.interfaces.nsIHttpChannel);
          var h=ch.URI.host, len=0; try{ len=ch.contentLength; }catch(e){} if(len<0) len=0;
          NET.n++; NET.kb+=len/1024; if(NET.host && h!==NET.host && !h.endsWith("."+NET.host)){ NET.n3++; NET.kb3+=len/1024; NET.hosts[h]=(NET.hosts[h]||0)+Math.round(len/1024); } }catch(e){} }},"http-on-examine-response");
        var perf=function(cb){
          var FS="data:application/javascript,"+encodeURIComponent("(function(){try{var n=content.performance.getEntriesByType('navigation')[0]||{};var rs=content.performance.getEntriesByType('resource');var b=(n.transferSize||0);rs.forEach(function(r){b+=(r.transferSize||0);});var fcp=(content.performance.getEntriesByType('paint')||[]).filter(function(e){return e.name==='first-contentful-paint';})[0];sendAsyncMessage('bb:perf',{dcl:Math.round(n.domContentLoadedEventEnd||0),load:Math.round(n.loadEventEnd||0),fcp:fcp?Math.round(fcp.startTime):null,req:rs.length+1,kb:Math.round(b/1024)});}catch(e){sendAsyncMessage('bb:perf',{err:String(e)});}})();");
          var mm=gb.selectedBrowser.messageManager, h=function(m){ mm.removeMessageListener("bb:perf",h); cb(m.data); };
          mm.addMessageListener("bb:perf",h); mm.loadFrameScript(FS,false);
          w.setTimeout(function(){ try{ mm.removeMessageListener("bb:perf",h); }catch(e){} cb({err:"no-perf"}); },4000);
        };
        var site=function(){
          // "measure" + a 4s hold: the harness reads CPU/memory from /proc NOW, with the same meter
          // it uses for Chrome (proctree.py), before the browser quits
          if(k>=urls.length){ bbProc().then(function(p){ R.memEnd=p; R.cpuMsTotal=Math.round(p.cpuMs-cpu0.cpuMs); R.stage="measure"; bbWrite(R);
            w.setTimeout(function(){ R.stage="done"; bbWrite(R); try{ Services.startup.quit(Components.interfaces.nsIAppStartup.eForceQuit); }catch(e){} },4000); }); return; }
          var u=urls[k++];
          NET.n=0; NET.kb=0; NET.n3=0; NET.kb3=0; NET.hosts={}; try{ NET.host=Services.io.newURI(u).host.replace(/^www\./,""); }catch(e){ NET.host=""; }
          loadOne(u,function(ms){ w.setTimeout(function(){ perf(function(p){ var once=false; if(once) return; once=true; p.url=u; p.wallMs=ms; p.resp=NET.n; p.respKB=Math.round(NET.kb); p.resp3p=NET.n3; p.resp3pKB=Math.round(NET.kb3); p.hosts3p=NET.hosts; R.sites.push(p); bbWrite(R); site(); }); },2500); });
        };
        // start the way a user would: ONE tab, overview dismissed (as every other mode does —
        // without it Beam loaded every page BEHIND its startup overview, content not painting)
        w.setTimeout(function(){ try{ gb.removeAllTabsBut(gb.selectedTab); }catch(e){}
          try{ w.dispatchEvent(new w.KeyboardEvent("keydown",{key:"Escape",bubbles:true,cancelable:true})); }catch(e){} },2000);
        w.setTimeout(function(){ R.preSites={ov:w.document.documentElement.hasAttribute("golem-ov"), tabs:gb.tabs.length, active:gb.selectedBrowser.docShellIsActive};
          bbProc().then(function(p){ cpu0=p; R.stage="sites-start"; bbWrite(R); site(); }); },(function(){ try{ return parseInt(Services.env.get("BEAM_BENCH_SETTLE"))||3500; }catch(e){ return 3500; } })());
        return;
      }
      // ---- BACK mode (BEAM_BENCH_BACK=reps): for each kind of page: open it, go to another page,
      // press BACK; time from goBack() to the page's pageshow, and whether it came from the
      // back-forward cache (pageshow.persisted) or had to load again.
      var BK=0; try{ BK=parseInt(Services.env.get("BEAM_BENCH_BACK"))||0; }catch(e){}
      if(BK){
        w.setTimeout(function(){ try{ gb.removeAllTabsBut(gb.selectedTab); }catch(e){}
          try{ w.dispatchEvent(new w.KeyboardEvent("keydown",{key:"Escape",bubbles:true,cancelable:true})); }catch(e){} },2000);
        var kinds=["b-plain","b-unload","b-beforeunload","b-nostore","b-heavy"], jobs=[];
        for(var rp=0;rp<BK;rp++) kinds.forEach(function(k){ jobs.push(k); });
        R.back=[]; var ji=0, pending=null;
        w.messageManager.addMessageListener("bb:ps",function(m){ if(pending && m.data.u.indexOf(pending.page)!==-1){ var p=pending; pending=null; p.cb(m.data.p); } });
        w.messageManager.loadFrameScript("data:application/javascript,"+encodeURIComponent("addEventListener('pageshow',function(e){try{if(e.target!==content.document)return;sendAsyncMessage('bb:ps',{u:content.location.href,p:e.persisted});}catch(x){}},true);"),true);
        var job=function(){
          if(ji>=jobs.length){ R.stage="done"; bbWrite(R); try{ Services.startup.quit(Components.interfaces.nsIAppStartup.eForceQuit); }catch(e){} return; }
          var k=jobs[ji++], u=BB_BASE+"/"+k+".html?"+(k==="b-nostore"?"nostore&":"")+"r="+ji;
          loadOne(u,function(){ w.setTimeout(function(){
            loadOne(BB_BASE+"/b-next.html?r="+ji,function(){ w.setTimeout(function(){
              var t0=Date.now(), fired=false;
              pending={page:k, cb:function(persisted){ fired=true; R.back.push({page:k, ms:Date.now()-t0, persisted:persisted}); bbWrite(R); w.setTimeout(job,500); }};
              gb.selectedBrowser.goBack();
              w.setTimeout(function(){ if(!fired){ pending=null; R.back.push({page:k, ms:-1}); bbWrite(R); job(); } },8000);
            },700); });
          },700); });
        };
        w.setTimeout(job,3500);
        return;
      }
      // ---- RESTORE mode (BEAM_BENCH_RESTORE=seed|check): seed = open 6 local pages, use them in
      // order (so recency is known), quit NORMALLY (session saved); check = the next start of the
      // same profile: after 20s record which restored tabs are loaded vs still unloaded.
      var RS=""; try{ RS=Services.env.get("BEAM_BENCH_RESTORE"); }catch(e){}
      if(RS==="seed"){
        w.setTimeout(function(){
          try{ w.dispatchEvent(new w.KeyboardEvent("keydown",{key:"Escape",bubbles:true,cancelable:true})); }catch(e){}
          var pg=["p-text","p-dom","p-img","p-css","p-long","p-scroll"], tabs=[gb.selectedTab];
          try{ gb.removeAllTabsBut(gb.selectedTab); }catch(e){}
          gb.selectedBrowser.loadURI(Services.io.newURI(BB_BASE+"/p-text.html"),{triggeringPrincipal:Services.scriptSecurityManager.getSystemPrincipal()});
          for(var k=1;k<pg.length;k++) tabs.push(gb.addTrustedTab(BB_BASE+"/"+pg[k]+".html",{inBackground:true}));
          var k2=0; w.setTimeout(function visit(){   // select each in turn: p-scroll ends most recent, p-text selected last
            var order=[1,2,3,4,5,0]; if(k2<order.length){ var t=tabs[order[k2++]]; gb.selectedTab=t; if(gb.selectedTab!==t) gb.tabContainer.selectedIndex=Array.prototype.indexOf.call(gb.tabs,t); w.setTimeout(visit,800); return; }
            R.stage="seeded"; bbWrite(R);
            w.setTimeout(function(){ try{ Services.startup.quit(Components.interfaces.nsIAppStartup.eAttemptQuit); }catch(e){} },1500);
          },5000);
        },3000);
        return;
      }
      if(RS==="check"){
        w.setTimeout(function(){
          R.restore=Array.prototype.map.call(gb.tabs,function(t){ var u=""; try{ u=t.linkedBrowser.currentURI.spec.replace(BB_BASE,""); }catch(e){}
            return {url:u, pending:t.hasAttribute("pending"), selected:t.selected, busy:t.hasAttribute("busy"), lastAccessed:t.lastAccessed}; });
          R.stage="done"; bbWrite(R); try{ Services.startup.quit(Components.interfaces.nsIAppStartup.eForceQuit); }catch(e){}
        },20000);
        return;
      }
      // ---- CLICK mode (BEAM_BENCH_CLICK=n, BEAM_BENCH_PROXY=first port): link-click latency to
      // an origin whose NEW connections cost BENCH_PROXY_DELAY ms (a delaying proxy = the
      // TCP+TLS handshake of a real site). Real (trusted) input via windowUtils.sendMouseEvent.
      // Per trial a fresh origin (own port): "hover" = same-site link hovered 300ms then clicked;
      // "click" = cross-site link (127.0.0.2), pointer lands and clicks at once (mousedown ->
      // 90ms -> mouseup). Latency = mouseup -> destination load finished.
      var CK=0, PX=0; try{ CK=parseInt(Services.env.get("BEAM_BENCH_CLICK"))||0; PX=parseInt(Services.env.get("BEAM_BENCH_PROXY"))||0; }catch(e){}
      if(CK && PX){
        w.setTimeout(function(){ try{ gb.removeAllTabsBut(gb.selectedTab); }catch(e){}
          try{ w.dispatchEvent(new w.KeyboardEvent("keydown",{key:"Escape",bubbles:true,cancelable:true})); }catch(e){} },2000);
        // hosts: Firefox never preconnects to LOOPBACK, so a real run passes the machine's LAN
        // address (BENCH_CLICK_HOST, same-site with the source page) and a second address
        // (BENCH_CLICK_HOST2, e.g. an IPv6 one = cross-site)
        var H1="127.0.0.1", H2="127.0.0.2"; try{ H1=Services.env.get("BEAM_BENCH_CLICKHOST")||H1; H2=Services.env.get("BEAM_BENCH_CLICKHOST2")||H2; }catch(e){}
        var SRC=BB_BASE.replace("127.0.0.1",H1);
        var trials=[]; for(var q=0;q<CK;q++){ trials.push({kind:"hover",host:H1,port:PX+2*q}); trials.push({kind:"click",host:H2,port:PX+2*q+1}); }
        R.clicks=[]; var ti=0; w.__pcLog=[];
        var didL=function(m){ (R.did=R.did||[]).push(m.data.a); };
        var DRV="data:application/javascript,"+encodeURIComponent(
          "addMessageListener('bb:do',function(m){var d=m.data,err='';try{var S=function(t,b,c){content.synthesizeMouseEvent(t,d.x,d.y,{button:0,buttons:b,clickCount:c},{isDOMEventSynthesized:false});};"+
          "if(d.a==='move'){S('mousemove',0,0);}"+
          "else if(d.a==='down'){S('mousedown',1,1);}"+
          "else if(d.a==='up'){S('mouseup',0,1);}}catch(x){err=String(x);}sendAsyncMessage('bb:did',{a:d.a+(err?' ERR '+err:'')});});sendAsyncMessage('bb:did',{a:'drv-loaded'});");
        var mmLoaded=false;
        var trial=function(){
          if(ti>=trials.length){ R.stage="done"; R.pcLog=w.__pcLog||null; try{ R.specLimit=Services.prefs.getIntPref("network.http.speculative-parallel-limit"); R.specLimitUser=Services.prefs.prefHasUserValue("network.http.speculative-parallel-limit"); R.dnsPrefetchOff=Services.prefs.getBoolPref("network.dns.disablePrefetch"); }catch(e){} bbWrite(R); try{ Services.startup.quit(Components.interfaces.nsIAppStartup.eForceQuit); }catch(e){} return; }
          var T=trials[ti++], dest="http://"+T.host+":"+T.port+"/p-text.html?t="+ti;
          var src=SRC+"/c-src.html?d="+encodeURIComponent(dest);
          loadOne(src,function(){
            var b=gb.selectedBrowser, mm=b.messageManager;
            if(!mmLoaded){ w.messageManager.addMessageListener("bb:did",didL); w.messageManager.loadFrameScript(DRV,true); mmLoaded=true; }
            var act=function(a){ mm.sendAsyncMessage("bb:do",{a:a,x:120,y:60}); };
            var measure=function(){
              var t0=Date.now(), done=false;
              var L={ onStateChange:function(wp,req,fl){ var W=Components.interfaces.nsIWebProgressListener;
                if(!done && (fl&W.STATE_STOP) && (fl&W.STATE_IS_WINDOW) && wp.isTopLevel){ var u=""; try{ u=b.currentURI.spec; }catch(e){}
                  if(u.indexOf(T.host+":"+T.port)===-1) return; done=true; b.removeProgressListener(L); R.clicks.push({kind:T.kind,ms:Date.now()-t0}); bbWrite(R); w.setTimeout(trial,400); } },
                QueryInterface:ChromeUtils.generateQI(["nsIWebProgressListener","nsISupportsWeakReference"]) };
              b.addProgressListener(L, Components.interfaces.nsIWebProgress.NOTIFY_STATE_WINDOW);
              R.upAt=(R.upAt||[]); R.upAt.push((Date.now()/1000).toFixed(3)); act("up");
              w.setTimeout(function(){ if(!done){ done=true; try{ b.removeProgressListener(L); }catch(e){} var cu=""; try{ cu=b.currentURI.spec; }catch(e){} R.clicks.push({kind:T.kind,ms:-1,at:cu}); bbWrite(R); trial(); } },8000);
            };
            w.setTimeout(function(){
              act("move");
              if(T.kind==="hover") w.setTimeout(function(){ act("down"); w.setTimeout(measure,90); },300);
              else w.setTimeout(function(){ act("down"); w.setTimeout(measure,90); },10);
            },500);
          });
        };
        w.setTimeout(trial,3500);
        return;
      }
      // ---- TAB-SWITCH mode (BEAM_BENCH_SWITCH=n switches): 6 loaded tabs, switch every 900ms.
      // Measures what a user feels: switch latency (TabSelect -> TabSwitchDone, i.e. the new tab's
      // layers are on screen) and chrome main-thread stalls (a 4ms timer chain; lateness = jank)
      // over the whole window, including the after-switch work (captures, saves) that lands later.
      var SW=0; try{ SW=parseInt(Services.env.get("BEAM_BENCH_SWITCH"))||0; }catch(e){}
      if(SW){
        w.setTimeout(function(){ try{ gb.removeAllTabsBut(gb.selectedTab); }catch(e){}
          try{ w.dispatchEvent(new w.KeyboardEvent("keydown",{key:"Escape",bubbles:true,cancelable:true})); }catch(e){} },2000);
        w.setTimeout(function(){
          var pg=["p-text","p-dom","p-img","p-css","p-long","p-scroll"], tabs=[];
          pg.forEach(function(p,ix){ var t= ix===0 ? gb.selectedTab : gb.addTab("about:blank",{triggeringPrincipal:Services.scriptSecurityManager.getSystemPrincipal()});
            tabs.push(t); t.linkedBrowser.loadURI(Services.io.newURI(BB_BASE+"/"+p+".html"),{triggeringPrincipal:Services.scriptSecurityManager.getSystemPrincipal()}); });
          w.setTimeout(function(){
            // visit each once untimed (first presentation of a background tab is a different cost)
            var v=0; (function visit(){ if(v<tabs.length){ gb.selectedTab=tabs[v++]; w.setTimeout(visit,700); return; }
              R.stage="switching"; bbWrite(R);
              var stalls=[], last=w.performance.now(), mon=true;
              (function tick(){ if(!mon) return; var n=w.performance.now(), late=n-last-4; if(late>6) stalls.push(late); last=n; w.setTimeout(tick,4); })();
              var lat=[], k=0, t0=0, pend=false;
              // switch done = the selected browser's layers are presented (what AsyncTabSwitcher waits
              // for before it drops the old tab); polled on rAF, independent of the switcher's events
              var poll=function(){ if(!pend) return; var b=gb.selectedBrowser; if(b.renderLayers && b.hasLayers && gb.selectedTab===R.__want){ pend=false; lat.push(Date.now()-t0); return; } w.requestAnimationFrame(poll); };
              bbProc().then(function(c0){
                (function sw(){
                  if(k>=SW){ w.setTimeout(function(){ mon=false; bbProc().then(function(c1){
                      var srt=function(a){ return a.slice().sort(function(x,y){return x-y;}); }, q=function(a,p){ a=srt(a); return a.length?a[Math.min(a.length-1,Math.floor(p*a.length))]:null; };
                      delete R.__want; R.switch={n:lat.length, k:k, timeouts:R.switchTimeouts||0, latP50:q(lat,.5), latP95:q(lat,.95), latMax:q(lat,1),
                        stalls:stalls.length, stalls16:stalls.filter(function(x){return x>16;}).length, stalls50:stalls.filter(function(x){return x>50;}).length, stallMax:stalls.length?Math.max.apply(null,stalls):0,
                        blockedMs:stalls.reduce(function(a,b){return a+b;},0), cpuMs:Math.round(c1.cpuMs-c0.cpuMs), memMB:c1.memMB};
                      try{ var tf=Services.dirsvc.get("ProfD",Components.interfaces.nsIFile); tf.append("golem-thumbs.json"); if(tf.exists()){ R.thumbs={bytes:tf.fileSize, ageMs:Date.now()-tf.lastModifiedTime};
                        var fis=Components.classes["@mozilla.org/network/file-input-stream;1"].createInstance(Components.interfaces.nsIFileInputStream); fis.init(tf,1,0,0); var sis=Components.classes["@mozilla.org/scriptableinputstream;1"].createInstance(Components.interfaces.nsIScriptableInputStream); sis.init(fis); var txt=sis.read(tf.fileSize); sis.close();
                        var o=JSON.parse(txt); R.thumbs.n=Object.keys(o).length; R.thumbs.local=Object.keys(o).filter(function(u){ return u.indexOf(BB_BASE)===0; }).map(function(u){ return u.slice(BB_BASE.length)+" "+o[u].d.slice(0,23)+" "+Math.round(o[u].d.length/1024)+"KB"; }); } }catch(e){ R.thumbs={err:String(e)}; }
                      R.stage="done"; bbWrite(R); try{ Services.startup.quit(Components.interfaces.nsIAppStartup.eForceQuit); }catch(e){} }); },6000); return; }
                  var t=tabs[(k*5+1)%tabs.length]; if(t===gb.selectedTab) t=tabs[(k+2)%tabs.length];   // jump around, never a no-op
                  k++; pend=true; t0=Date.now(); R.__want=t; gb.selectedTab=t; w.requestAnimationFrame(poll); w.setTimeout(function(){ if(pend){ pend=false; R.switchTimeouts=(R.switchTimeouts||0)+1; } },880); w.setTimeout(sw,900);
                })();
              });
            })();
          },6000);
        },3500);
        return;
      }
      // start both browsers the way a user would: ONE tab (uBO's first-run welcome tab would
      // otherwise add a page — and makes Beam auto-open its tab overview, hiding the page),
      // overview dismissed (Escape: no-op in stock Firefox, closes Beam's overview)
      w.setTimeout(function(){ try{ gb.removeAllTabsBut(gb.selectedTab); }catch(e){}
        try{ w.dispatchEvent(new w.KeyboardEvent("keydown",{key:"Escape",bubbles:true,cancelable:true})); }catch(e){} },2000);
      w.setTimeout(function next(){
        R.stage="loading"; bbWrite(R);
        if(i<pages.length){ var pg=pages[i++]; loadOne(BB_BASE+"/"+pg+".html",function(ms){ R.loads.push({page:pg,ms:ms}); bbWrite(R); w.setTimeout(next,300); }); return; }
        R.stage="memory"; bbWrite(R);
        bbProc().then(function(mem){ R.memAfterLoads=mem; R.stage="scroll-page"; bbWrite(R);
          var quick=""; try{ quick=Services.env.get("BEAM_BENCH_QUICK"); }catch(e){}
          if(quick){ R.stage="done"; bbWrite(R); try{ Services.startup.quit(Components.interfaces.nsIAppStartup.eForceQuit); }catch(e){} return; }
          loadOne(BB_BASE+"/p-scroll.html",function(){ R.stage="scrolling"; bbWrite(R); w.setTimeout(function(){ scrollTest(function(sc){ R.scroll=sc; R.stage="done";
            bbProc().then(function(m2){ R.memEnd=m2; bbWrite(R); try{ Services.startup.quit(Components.interfaces.nsIAppStartup.eForceQuit); }catch(e){} }); }); },1500); });
        });
      },2500);   // let startup work (extensions, restore) settle
    }},"browser-delayed-startup-finished");
  }
} catch(e){}
