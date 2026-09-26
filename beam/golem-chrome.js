// ===================================================================
// GOLEM chrome script — the browser's privileged UI foundation.
//
// Landing pad for every "Firefox can't do that from CSS or prefs"
// feature. Shipped via the nixpkgs Firefox wrapper (golem-browser.nix:
// extraPrefs appends this to mozilla.cfg; extraAutoConfig disables the
// config sandbox that would block the privileged APIs).
//
// AUTOCONFIG EATS THE FIRST LINE — it MUST be a comment. (Cost a
// debugging round: a script starting with try { silently breaks. Also, with
// structuredAttrs, extraPrefs is sourced as shell — NEVER put a backtick in
// this file (in code or comments): it opens a command substitution + fails the build.)
//
// Hard-won facts (2026-09-12):
//   * Globals: Services, Components. NOT ChromeUtils.importESModule.
//   * Vertical-tab sidebar = <sidebar-main>; its shadow root holds:
//       #sidebar-tools-and-extensions-splitter  (the divider)
//       button-group.actions-list               (the tools row)
//         moz-button.tools-overflow ×N           (native tools)
//       button-group.actions-list.overflow-button (the ">>" chevron)
//     getElementById can't see shadow content — query the shadowRoot.
//   * The native tools are managed by the component; style.display
//     :none does NOT stick — .remove() them, and set sidebar.main.tools
//     = "" so they are never repopulated.
//   * XUL toolbarbuttons DON'T render in that HTML shadow tree; native
//     <moz-button> does. A moz-button wired to a win.* command is a
//     real clickable control (proven by synthetic-click self-test).
//
// FEATURE: the sidebar tools row holds ONLY Golem's 6 action buttons
// (save, downloads, private, new window, favorites, history) — divider,
// overflow chevron and Firefox's native tools removed, and the row moved
// to the TOP of the sidebar. Nav-bar keeps nav + uBlock.
//
// FEATURE: the launcher is forced EXPANDED (setAttribute("expanded")) so
// the vertical tabs render full-width WITH titles; userChrome.css slides
// that sidebar off-screen and reveals it on hover (the auto-hide stripe).
// ===================================================================
try {
  var GLOG="/tmp/golem-chrome.log";
  function L(m){try{var f=Components.classes["@mozilla.org/file/local;1"].createInstance(Components.interfaces.nsIFile);f.initWithPath(GLOG);var os=Components.classes["@mozilla.org/network/file-output-stream;1"].createInstance(Components.interfaces.nsIFileOutputStream);os.init(f,0x02|0x08|0x10,0o666,0);var s=m+"\n";os.write(s,s.length);os.close();}catch(e){}}

  function ACTIONS(win){ return [
    { id:"golem-save",     title:"Save page", icon:"chrome://browser/skin/save.svg",
      run:function(){ try{ win.saveBrowser(win.gBrowser.selectedBrowser); }catch(e){ win.saveDocument(win.content.document); } } },
    { id:"golem-downloads",title:"Downloads", icon:"chrome://browser/skin/downloads/downloads.svg",
      run:function(){ try{ win.openTrustedLinkIn("about:downloads","tab"); }catch(e){ try{ win.PlacesCommandHook.showPlacesOrganizer("Downloads"); }catch(e2){} } } },
    { id:"golem-private",  title:"New private window", icon:"chrome://browser/skin/privateBrowsing.svg",
      run:function(){ win.OpenBrowserWindow({private:true}); } },
    { id:"golem-newwin",   title:"New window", icon:"chrome://browser/skin/window.svg",
      run:function(){ win.OpenBrowserWindow(); } },
    { id:"golem-bookmarks",title:"Favorites", icon:"chrome://browser/skin/bookmark.svg",
      run:function(){ try{ win.SidebarController.show("viewBookmarksSidebar"); }catch(e){ try{win.PlacesCommandHook.showPlacesOrganizer("AllBookmarks");}catch(e2){} } } },
    { id:"golem-history",  title:"History", icon:"chrome://browser/skin/history.svg",
      run:function(){ try{ win.SidebarController.show("viewHistorySidebar"); }catch(e){ try{win.PlacesCommandHook.showPlacesOrganizer("History");}catch(e2){} } } },
  ]; }

  function build(win){
    var d=win.document;
    var sm=d.querySelector("sidebar-main");
    if(!sm||!sm.shadowRoot){ L("no shadow"); return; }
    var root=sm.shadowRoot;
    if(root.getElementById("golem-newwin")) return;

    // 1. the divider between tabs and tools
    var sp=root.getElementById("sidebar-tools-and-extensions-splitter");
    if(sp){ sp.remove(); L("removed divider"); }

    // 2. the ">>" overflow group
    var ovf=root.querySelector("button-group.overflow-button");
    if(ovf){ ovf.remove(); L("removed overflow"); }

    // 3. the native tools list — clear it, then fill with ours
    var list=root.querySelector("button-group.actions-list:not(.overflow-button)");
    if(!list){ L("no actions-list"); return; }
    Array.prototype.slice.call(list.children).forEach(function(c){ c.remove(); });
    L("cleared native tools");

    var made=0, newwinBtn=null;
    ACTIONS(win).forEach(function(a){
      var b=d.createElement("moz-button");
      b.id=a.id; b.setAttribute("type","icon-ghost"); b.setAttribute("title",a.title); b.setAttribute("iconsrc",a.icon);
      b.addEventListener("click", function(ev){ ev.preventDefault(); try{a.run();}catch(e){L("run "+a.id+":"+e);} });
      list.appendChild(b); if(a.id==="golem-newwin") newwinBtn=b; made++;
    });
    // Strip the button shapes (transparent bg+border) and shrink to icon-
    // only. moz-button lives in shadow DOM, so inject the style there.
    var st=d.createElement("style");
    st.textContent="button-group.actions-list{display:flex !important;justify-content:space-evenly !important;align-items:center !important;width:100% !important;box-sizing:border-box !important;padding:0 6px !important;}.buttons-wrapper{width:100% !important;}#golem-save,#golem-downloads,#golem-private,#golem-newwin,#golem-bookmarks,#golem-history{"+
      "--button-background-color:transparent;--button-background-color-hover:transparent;--button-background-color-active:transparent;"+
      "--button-border-color:transparent;--button-border-color-hover:transparent;--button-border-color-active:transparent;"+
      "--button-box-shadow:none;--button-outer-padding-inline:2px;--button-outer-padding-block:2px;"+
      "--button-size-icon:20px;--button-min-height:28px;box-shadow:none;vertical-align:middle;}";
    root.appendChild(st);
    // Move the button row to the TOP of the sidebar (above the tab slot).
    var wrap=root.querySelector(".wrapper");
    var bw=root.querySelector(".buttons-wrapper");
    if(wrap&&bw){ wrap.insertBefore(bw, wrap.firstChild); L("moved buttons to top"); }

    // Force the launcher EXPANDED so the vertical tabs render full-width
    // WITH titles. Left alone the launcher sits collapsed to an icon RAIL
    // (narrow rows, the close-X stamped on the favicon). userChrome.css's
    // auto-hide then slides this genuine full-width sidebar off-screen and
    // reveals it on hover. Re-assert once — Firefox can reset the launcher
    // state late in startup. Setting the ATTRIBUTE is what renders (the
    // .expanded property already reads true while still showing the rail).
    try{ sm.setAttribute("expanded","true"); win.setTimeout(function(){try{sm.setAttribute("expanded","true");}catch(e){}},1500); }catch(e){}

    L("built "+made+" buttons (only ours) + styled, launcher expanded");
  }

  Services.obs.addObserver({observe:function(w){try{w.setTimeout(function(){try{build(w)}catch(e){L("build:"+e)}},900)}catch(e){}}},"browser-delayed-startup-finished");
  L("golem foundation loaded");
} catch(e){}

// ===================================================================
// TAB OVERVIEW (exposé) — a macOS/GNOME-style grid of every open tab.
//
// A grid button at the FAR LEFT of the nav-bar (before back) opens a
// full-window overlay over the CONTENT area: one big card per tab (a live
// page thumbnail + favicon + title, current tab ringed). HOVER the button
// (140ms hover-intent) or click it to open; click a card to switch, the ✕
// to close that tab, Esc / the button again / the backdrop to dismiss.
// The toolbar stays put (Safari-style overview). It does NOT close on
// mouse-leave — you move the pointer down into the grid to pick a card.
//
// WAYLAND OCCLUSION — the make-or-break. Web content is an OPAQUE Wayland
// subsurface that paints OVER chrome, so a plain chrome overlay hides
// BEHIND the page (the wall that killed a see-through / round-cornered
// content decoration). We don't need to SEE content, only stand in for it:
// while the overview is open we deactivate the selected browser's docShell
// (this DROPS the content subsurface) and hide #tabbrowser-tabpanels with
// visibility:HIDDEN — never collapse, which zero-sizes the browser so the
// page reflows/resizes when it returns. Our chrome grid (an absolute child
// of #browser, which userChrome already makes position:relative) then paints
// unobstructed. Both restored on close.
//
// THUMBNAILS — Firefox keeps no live pixels for unloaded/background tabs
// (all tabs share ONE content surface; only the selected one paints), so
// there is nothing to grab for a background tab. We build our own cache
// the macOS way: whenever a tab is the selected/painting one we snapshot it
// (WindowGlobalParent.drawSnapshot(rect, scale, bgColor) → canvas → JPEG
// dataURL) and remember it per-tab. A tab shows its last-seen frame; a tab
// never viewed this session shows a big favicon (then a letter badge).
// Captures happen on TabSelect (after it settles), once at startup for the
// initial tab, and again for the active tab just before the overview hides
// it — and the snapshot MUST be taken while the browser is docShell-active,
// or it comes back blank.
//
// drawSnapshot signature gotcha: it is WindowGlobalParent.drawSnapshot(
// DOMRect rect, double scale, UTF8String backgroundColor, optional dict).
// Arg 2 is scale (finite double), arg 4 is an options DICTIONARY (not a
// boolean). Call it on browser.browsingContext.currentWindowGlobal.
//
// PALETTE tracks Beam: backdrop = the bar colour rgb(29,32,38); the
// current-tab ring uses the adaptive --lwt-accent-color (ATBC) with a blue
// fallback. Style is INLINE on every script-made node — userChrome.css
// does not reliably reach light-DOM nodes created at runtime.
// ===================================================================
try {
  var OV_HTML = "http://www.w3.org/1999/xhtml";
  // ---- Beam palette ----
  var OV_BACKDROP = "rgb(29,32,38)";      // new-tab / bar colour — keep in SYNC with userContent.css (blank-page bg) + userChrome.css (toolbar bg)
  var OV_CARD     = "rgb(39,43,52)";
  var OV_CARD_HOV = "rgb(48,53,63)";
  var OV_FOOTER   = "rgb(25,28,34)";
  var OV_THUMB_BG = "linear-gradient(160deg,rgb(47,52,63),rgb(30,33,40))";
  var OV_ACCENT   = "var(--lwt-accent-color, #4d9fff)";
  var OV_TEXT     = "#e7e9ef";
  var OV_MUTED    = "#9aa0ab";
  var OV_SNAP_BG  = "#20242c";
  // ---- card geometry ----
  var OV_CARD_H   = "360px";
  var OV_COL_MIN  = "440px";
  var OV_GAP      = "24px";
  var OV_SNAP_SCALE = 0.5;   // capture resolution — larger cards need sharper thumbs
  var OV_HOVER_MS = 140;     // hover-intent dwell before opening
  var OV_BT = String.fromCharCode(96);   // the backtick key — NEVER write a literal
  // backtick in this file: golem-browser.nix embeds it via extraPrefs and (with
  // structuredAttrs) sources it as shell, where a backtick opens a command
  // substitution and breaks the Firefox build. Same reason: no comments with backticks.
  // ---- persistent thumbnail cache ----
  var OV_THUMB_FILE = "golem-thumbs.json";  // in the profile dir
  var OV_THUMB_MAX  = 120;                   // cap entries (evict oldest) to bound file size
  var ovMap = null;                          // {url:{d:dataURL,t:ms}} — process-global (mozilla.cfg runs once)
  var ovSaveTimer = null, ovMapDirty = false, ovQuitObs = false, ovStartupDone = false;

  // Keep switched-away tabs' compositor layers ALIVE so returning to a tab you've
  // already viewed re-shows INSTANTLY. Without this, lifting the overview lands on a
  // tab that must re-render from scratch, and the last-composited frame (the tab you
  // were on) shows through until it does — the "previous tab flash". Web content is an
  // opaque Wayland subsurface above all chrome, so that gap can't be masked; the only
  // real cure is to make the picked tab paint with no gap, i.e. keep its layers warm.
  try{ pref("browser.tabs.remote.tabCacheSize", 16); }catch(e){}
  try{ pref("browser.tabs.remote.warmup.enabled", true); }catch(e){}
  try{ pref("browser.tabs.remote.warmup.maxTabs", 16); }catch(e){}

  // Debug trace to /tmp/golem-overview.log. OFF in production — flip OV_DEBUG to true
  // to re-enable when diagnosing (call sites are kept as a log of interesting events).
  var OV_DEBUG = false;   // flip to true for the switch-timeline deep debug (then ~/golem-swan.sh reads the log)
  function OVLOG(m){ if(!OV_DEBUG) return; try{var f=Components.classes["@mozilla.org/file/local;1"].createInstance(Components.interfaces.nsIFile);f.initWithPath("/tmp/golem-overview.log");var os=Components.classes["@mozilla.org/network/file-output-stream;1"].createInstance(Components.interfaces.nsIFileOutputStream);os.init(f,0x02|0x08|0x10,0o666,0);var s=m+"\n";os.write(s,s.length);os.close();}catch(e){}}
  function OVEL(win,tag,css){ var e=win.document.createElementNS(OV_HTML,tag); if(css) e.style.cssText=css; return e; }

  function ovHostEl(win){ return win.document.getElementById("browser"); }
  function ovTabs(win){
    var out=[]; try{ win.gBrowser.tabs.forEach(function(t){ if(!t.hidden && !t.closing) out.push(t); }); }catch(e){}
    return out;
  }
  function ovFavicon(win,tab){
    var f = tab.image; if(f) return f;
    try{ return win.gBrowser.getIcon(tab); }catch(e){}
    return null;
  }
  function ovDomainSafe(url){ try{ return Services.io.newURI(url).host || url; }catch(e){ return url||"?"; } }
  function ovLetterBadge(win,seed){
    var s = (seed||"?").replace(/^www\./,"");
    var c = OVEL(win,"div","width:72px;height:72px;border-radius:16px;display:flex;align-items:center;justify-content:center;background:rgba(255,255,255,.10);color:"+OV_TEXT+";font-size:34px;font-weight:600;");
    c.textContent = (s.charAt(0)||"?").toUpperCase();
    return c;
  }

  // ---- persistent thumbnail cache (URL -> {d:dataURL,t:ms}) in the profile ----
  // Keyed by URL (not tab) so it survives restart: session-restore recreates
  // tabs by URL, and a restored tab shows its last-session frame immediately.
  function ovThumbFile(){ var f=Services.dirsvc.get("ProfD",Components.interfaces.nsIFile); f.append(OV_THUMB_FILE); return f; }
  function ovReadText(f){
    var fis=Components.classes["@mozilla.org/network/file-input-stream;1"].createInstance(Components.interfaces.nsIFileInputStream); fis.init(f,0x01,0,0);
    var cis=Components.classes["@mozilla.org/intl/converter-input-stream;1"].createInstance(Components.interfaces.nsIConverterInputStream); cis.init(fis,"UTF-8",0,0);
    var s="",o={}; while(cis.readString(65536,o)!==0){ s+=o.value; } cis.close(); fis.close(); return s;
  }
  function ovWriteText(f,text){
    var fos=Components.classes["@mozilla.org/network/file-output-stream;1"].createInstance(Components.interfaces.nsIFileOutputStream); fos.init(f,0x02|0x08|0x20,0o600,0);
    var cos=Components.classes["@mozilla.org/intl/converter-output-stream;1"].createInstance(Components.interfaces.nsIConverterOutputStream); cos.init(fos,"UTF-8"); cos.writeString(text); cos.close(); fos.close();
  }
  function ovLoadMap(){
    if(ovMap!==null) return ovMap;
    ovMap={};
    try{ var f=ovThumbFile(); if(f.exists()){ var o=JSON.parse(ovReadText(f)); if(o&&typeof o==="object") ovMap=o; } }catch(e){ ovMap={}; }
    try{ OVLOG("loaded "+Object.keys(ovMap).length+" thumbnails from disk"); }catch(e){}
    return ovMap;
  }
  function ovMapGet(url){ if(!url) return null; var e=ovLoadMap()[url]; return e?e.d:null; }
  function ovMapSet(url,durl){
    var m=ovLoadMap(), ex=m[url];
    // never replace a good thumbnail with a much smaller one (a blank / still-
    // loading frame) — that was wiping the active tab's real preview on startup.
    if(ex && ex.d && durl.length < ex.d.length*0.5) return;
    m[url]={d:durl,t:Date.now()}; ovMapDirty=true;
  }
  function ovSaveNow(){
    try{
      var m=ovLoadMap(), keys=Object.keys(m);
      if(keys.length>OV_THUMB_MAX){ keys.sort(function(a,b){ return (m[b].t||0)-(m[a].t||0); }); var keep={}; keys.slice(0,OV_THUMB_MAX).forEach(function(k){ keep[k]=m[k]; }); ovMap=m=keep; }
      var json=JSON.stringify(m);
      // atomic write: temp file then rename over the target, so an interrupted
      // write (e.g. Beam killed mid-save) can never truncate/wipe the real cache.
      var dir=Services.dirsvc.get("ProfD",Components.interfaces.nsIFile);
      var tmp=dir.clone(); tmp.append(OV_THUMB_FILE+".tmp");
      ovWriteText(tmp, json);
      try{ if(ovThumbFile().exists()) ovThumbFile().remove(false); }catch(e){}
      try{ tmp.moveTo(dir, OV_THUMB_FILE); }catch(e){ ovWriteText(ovThumbFile(), json); }
      ovMapDirty=false;
    }catch(e){ OVLOG("thumbsave:"+e); }
  }
  // Off the UI thread (perf pass 2026-09-26): the sync save cost ~11ms of UI thread per tab
  // switch (stringify 5 + write 6, measured on the real build with a 3.9MB cache) = 2-3
  // dropped frames at 165Hz, more on slower machines. Now: stringify when the UI is idle,
  // write through IOUtils (its own I/O thread, atomic via tmpPath). The sync ovSaveNow
  // stays for quit only, where nothing is on screen to stutter.
  var ovSaving=false;
  function ovIdle(win,fn,timeout){ try{ win.requestIdleCallback(function(){ fn(); },{timeout:timeout||3000}); }catch(e){ win.setTimeout(fn,0); } }
  function ovSaveAsync(win){
    if(ovSaving){ ovScheduleSave(win); return; }
    try{
      var m=ovLoadMap(), keys=Object.keys(m);
      if(keys.length>OV_THUMB_MAX){ keys.sort(function(a,b){ return (m[b].t||0)-(m[a].t||0); }); var keep={}; keys.slice(0,OV_THUMB_MAX).forEach(function(k){ keep[k]=m[k]; }); ovMap=m=keep; }
      var path=ovThumbFile().path, json=JSON.stringify(m);
      ovMapDirty=false; ovSaving=true;
      win.IOUtils.writeUTF8(path,json,{tmpPath:path+".tmp"}).then(function(){ ovSaving=false; },function(e){ ovSaving=false; ovMapDirty=true; OVLOG("thumbsave:"+e); });
    }catch(e){ ovSaving=false; OVLOG("thumbsave:"+e); try{ ovSaveNow(); }catch(e2){} }
  }
  function ovScheduleSave(win){
    if(ovSaveTimer||!ovMapDirty) return;
    try{ ovSaveTimer=win.setTimeout(function(){ ovSaveTimer=null; if(ovMapDirty) ovIdle(win,function(){ if(ovMapDirty) ovSaveAsync(win); },5000); },2500); }catch(e){}
  }
  // Warm the cache at startup without blocking it: read on the I/O thread, parse when idle.
  // Anything that needs the map before then falls back to the sync ovLoadMap (never lost:
  // if that ran first, this result is simply dropped).
  function ovLoadMapAsync(win){
    if(ovMap!==null) return;
    try{
      var f=ovThumbFile(); if(!f.exists()){ ovLoadMap(); return; }
      win.IOUtils.readUTF8(f.path).then(function(txt){
        ovIdle(win,function(){ if(ovMap!==null) return;
          try{ var o=JSON.parse(txt); ovMap=(o&&typeof o==="object")?o:{}; }catch(e){ ovMap={}; }
          try{ OVLOG("loaded "+Object.keys(ovMap).length+" thumbnails from disk (async)"); }catch(e){} },2000);
      },function(){ ovLoadMap(); });
    }catch(e){ ovLoadMap(); }
  }
  // Snapshot bitmap -> JPEG data URL with the encode OFF the UI thread (toBlob encodes on a
  // worker; toDataURL encoded synchronously, ~5-6ms per capture).
  function ovEncode(win,bm,cb){
    try{
      var cv=win.document.createElementNS(OV_HTML,"canvas"); cv.width=bm.width; cv.height=bm.height;
      cv.getContext("2d").drawImage(bm,0,0); try{ bm.close(); }catch(e){}
      cv.toBlob(function(blob){
        if(!blob){ cb(null); return; }
        var fr=new win.FileReader(); fr.onload=function(){ cb(fr.result); }; fr.onerror=function(){ cb(null); }; fr.readAsDataURL(blob);
      },"image/jpeg",0.72);
    }catch(e){ try{ bm.close(); }catch(e2){} cb(null); }
  }

  // Snapshot a tab IF it is the painting (docShell-active) one; persist by URL
  // and live-refresh its card if the overview is open. Skips private + non-http.
  function ovCaptureTab(win,tab){
    try{
      if(!tab || tab.closing) return;
      if(tab.hasAttribute && tab.hasAttribute("busy")) return;   // still loading → skip the partial frame
      var b=tab.linkedBrowser; if(!b || !b.docShellIsActive) return;
      var bc=b.browsingContext; var wg=bc&&bc.currentWindowGlobal; if(!wg) return;
      if(bc.usePrivateBrowsing) return;                 // never snapshot/persist private tabs
      var url=""; try{ url=b.currentURI.spec; }catch(e){}
      if(!/^https?:/i.test(url)) return;                // real pages only
      var r=b.getBoundingClientRect(); var W=Math.round(r.width), H=Math.round(r.height);
      if(W<4||H<4) return;
      wg.drawSnapshot(new win.DOMRect(0,0,W,H), OV_SNAP_SCALE, OV_SNAP_BG).then(function(bm){
        ovEncode(win,bm,function(durl){ try{
          if(durl && durl.length>64){ ovMapSet(url,durl); ovScheduleSave(win); ovRefreshCardThumb(win,tab,durl); }
        }catch(e){} });
      },function(e){ /* deactivated mid-capture, ignore */ });
    }catch(e){}
  }
  function ovCaptureActive(win){ try{ ovCaptureTab(win, win.gBrowser.selectedTab); }catch(e){} }

  // Snapshot every LOADED background tab that has no cache entry yet, while the
  // overview is open (content is hidden, so briefly activating a bg tab's
  // docShell to render it for drawSnapshot does NOT composite to screen → no
  // flash). LAZY tabs (no currentWindowGlobal) are SKIPPED — activating them
  // would force a network load. This fills the cache far beyond just the tabs
  // you happened to view, so future reopens show many more thumbnails.
  function ovCaptureLoaded(win,pass){
    try{
      if(win.__ovCapBusy) return;   // one pass at a time
      pass=pass||0;
      var pending=[], anyPending=false;
      ovTabs(win).forEach(function(tab){
        try{
          if(tab.selected) return;                            // active tab is captured on dismiss (ovClose), not here
          var b=tab.linkedBrowser; if(!b) return;
          if(ovMapGet(ovTabUrl(tab))) return;                 // already have a thumbnail
          var bc=b.browsingContext, wg=bc&&bc.currentWindowGlobal;
          if(!wg){ anyPending=true; return; }                 // still loading / lazy → retry later
          if(bc.usePrivateBrowsing) return;
          var url=""; try{ url=b.currentURI.spec; }catch(e){}
          if(!/^https?:/i.test(url)){ if(url==="about:blank") anyPending=true; return; }
          pending.push({tab:tab,b:b,wg:wg,url:url});
        }catch(e){}
      });
      // Process ONE tab at a time (activate → snapshot → deactivate → wait), so at
      // most one bg docShell is active at once (no CPU spike / media storm), capped,
      // aborting the moment the overview is dismissed. Retry a few times so tabs
      // that finish loading AFTER the overview opened still get captured.
      var i=0, MAX=16; win.__ovCapBusy=true;
      var finish=function(){
        win.__ovCapBusy=false;
        if(anyPending && ovIsOpen(win) && pass<5) win.setTimeout(function(){ ovCaptureLoaded(win,pass+1); }, 1600);
      };
      (function next(){
        if(i>=pending.length || i>=MAX || !ovIsOpen(win)){ finish(); return; }
        var p=pending[i++]; var wasActive=p.b.docShellIsActive;
        // Switch the tab back off ONLY if it is still a background tab and the grid is
        // still up. The snapshot is async: if the user picked THIS tab meanwhile, the late
        // "off" landed on the tab they are now looking at → the random BLANK TABS
        // (reproduced headless 2/3 runs, 2026-09-25; test: race-picked-tab-rendering).
        var done=function(){ try{ if(!wasActive && p.tab!==win.gBrowser.selectedTab && ovIsOpen(win)) p.b.docShellIsActive=false; }catch(e){} win.setTimeout(next,150); };
        try{ p.b.docShellIsActive=true; }catch(e){}
        if(win.__ovCapHook){ try{ win.__ovCapHook(p.tab); }catch(e){} }   // self-test only: fires at the exact race instant
        try{
          p.wg.drawSnapshot(new win.DOMRect(0,0,1200,800), OV_SNAP_SCALE, OV_SNAP_BG).then(function(bm){
            ovEncode(win,bm,function(durl){ try{ if(durl&&durl.length>64){ ovMapSet(p.url,durl); ovScheduleSave(win); ovRefreshCardThumb(win,p.tab,durl); } }catch(e){} done(); });
          }, done);
        }catch(e){ done(); }
      })();
    }catch(e){ win.__ovCapBusy=false; OVLOG("capLoaded:"+e); }
  }
  function ovTabUrl(tab){ try{ return tab.linkedBrowser.currentURI.spec; }catch(e){ return ""; } }

  // ---- one card ----
  function ovCard(win,tab,idx){
    var gb=win.gBrowser;
    var url=""; try{ url=tab.linkedBrowser.currentURI.spec; }catch(e){}
    var title = tab.label || url || "New tab";
    var fav = ovFavicon(win,tab);
    var current = tab.selected;

    var card = OVEL(win,"div",
      "position:relative;display:flex;flex-direction:column;height:"+OV_CARD_H+";border-radius:14px;overflow:hidden;cursor:pointer;"+
      "background:"+OV_CARD+";border:2px solid "+(current?OV_ACCENT:"transparent")+";"+
      "box-shadow:0 5px 18px rgba(0,0,0,.30);transition:transform 120ms ease, background 120ms ease;");
    card.setAttribute("title", title + (url?("  —  "+url):""));
    card.__ovTab = tab;

    // number badge — the keyboard-jump hint (1–9) for the CURRENT page of nine.
    // Created hidden on every card; ovApplyBadges() picks which nine show given
    // the page offset (Shift pages forward, renumbering tab 10 → "1", …).
    var num = OVEL(win,"div","position:absolute;top:9px;left:9px;min-width:18px;height:18px;padding:0 5px;border-radius:5px;"+
      "background:rgba(16,18,22,.66);color:#c8ccd4;font-size:11px;font-weight:700;display:none;align-items:center;justify-content:center;z-index:2;pointer-events:none;");
    card.appendChild(num); card.__ovBadge=num; card.__ovIdx=idx;

    var thumb = OVEL(win,"div","flex:1;min-height:0;position:relative;display:flex;align-items:center;justify-content:center;background:"+OV_THUMB_BG+";overflow:hidden;");
    thumb.__ovThumb = true;
    var cached = ovMapGet(url);
    if(cached){
      var im=OVEL(win,"img","position:absolute;inset:0;width:100%;height:100%;object-fit:cover;object-position:top center;display:block;");
      im.setAttribute("src",cached); thumb.appendChild(im);
    } else if(fav){
      var big=OVEL(win,"img","width:72px;height:72px;object-fit:contain;filter:drop-shadow(0 3px 9px rgba(0,0,0,.45));");
      big.setAttribute("src",fav);
      big.addEventListener("error",function(){ try{big.remove();}catch(e){} thumb.appendChild(ovLetterBadge(win,ovDomainSafe(url))); });
      thumb.appendChild(big);
    } else { thumb.appendChild(ovLetterBadge(win,ovDomainSafe(url))); }

    var foot = OVEL(win,"div","display:flex;align-items:center;gap:9px;padding:11px 13px;background:"+OV_FOOTER+";");
    if(fav){
      var fico = OVEL(win,"img","width:17px;height:17px;flex:0 0 17px;object-fit:contain;");
      fico.setAttribute("src",fav);
      fico.addEventListener("error",function(){ fico.style.visibility="hidden"; });
      foot.appendChild(fico);
    }
    var tt = OVEL(win,"div","flex:1;min-width:0;color:"+OV_TEXT+";font-size:13px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;");
    tt.textContent = title; foot.appendChild(tt);

    var x = OVEL(win,"div","position:absolute;top:9px;right:9px;width:24px;height:24px;border-radius:50%;display:flex;align-items:center;justify-content:center;"+
      "background:rgba(18,20,24,.80);color:#d6d9e0;font-size:13px;line-height:1;opacity:0;transition:opacity 110ms ease;z-index:3;");
    x.textContent="✕";
    x.addEventListener("mouseenter",function(){ x.style.background="rgba(214,74,74,.94)"; x.style.color="#fff"; });
    x.addEventListener("mouseleave",function(){ x.style.background="rgba(18,20,24,.80)"; x.style.color="#d6d9e0"; });
    x.addEventListener("click",function(ev){ ev.stopPropagation(); ev.preventDefault(); try{ gb.removeTab(tab,{animate:false}); }catch(e){} win.setTimeout(function(){ ovRender(win); },0); });

    card.addEventListener("mouseenter",function(){ try{ gb.warmupTab(tab); }catch(e){} card.style.transform="translateY(-3px)"; card.style.background=OV_CARD_HOV; x.style.opacity="1"; });
    card.addEventListener("mouseleave",function(){ card.style.transform="none"; card.style.background=OV_CARD; x.style.opacity="0"; });
    card.addEventListener("click",function(){ ovSwitchTo(win,tab); });

    card.appendChild(x); card.appendChild(thumb); card.appendChild(foot);
    return card;
  }

  // live-swap a card's thumbnail when a fresh capture lands
  function ovRefreshCardThumb(win,tab,durl){
    var grid=win.document.getElementById("golem-ov-grid"); if(!grid) return;
    for(var i=0;i<grid.children.length;i++){
      var c=grid.children[i];
      if(c.__ovTab===tab){
        var thumb=null;
        for(var j=0;j<c.children.length;j++){ if(c.children[j].__ovThumb){ thumb=c.children[j]; break; } }
        if(thumb){
          while(thumb.firstChild) thumb.removeChild(thumb.firstChild);
          var im=OVEL(win,"img","position:absolute;inset:0;width:100%;height:100%;object-fit:cover;object-position:top center;display:block;");
          im.setAttribute("src",durl); thumb.appendChild(im);
        }
        return;
      }
    }
  }

  // Light refresh (NO grid rebuild): for each existing card, if a thumbnail is now
  // available for its tab's CURRENT url and the card isn't already showing it, swap it
  // in place. Used as tab URLs settle at startup (active tab: about:blank -> real url)
  // instead of a full ovRender — rebuilding every card is what made the grid flicker.
  function ovRefreshCards(win){
    var grid=win.document.getElementById("golem-ov-grid"); if(!grid) return;
    for(var i=0;i<grid.children.length;i++){
      var c=grid.children[i], tab=c.__ovTab; if(!tab) continue;
      var durl=ovMapGet(ovTabUrl(tab)); if(!durl) continue;
      var thumb=null;
      for(var j=0;j<c.children.length;j++){ if(c.children[j].__ovThumb){ thumb=c.children[j]; break; } }
      if(!thumb) continue;
      var cur=thumb.firstChild;
      if(cur && cur.tagName && cur.tagName.toLowerCase()==="img" && cur.getAttribute("src")===durl) continue;
      while(thumb.firstChild) thumb.removeChild(thumb.firstChild);
      var im=OVEL(win,"img","position:absolute;inset:0;width:100%;height:100%;object-fit:cover;object-position:top center;display:block;");
      im.setAttribute("src",durl); thumb.appendChild(im);
    }
  }

  // open a new tab (used by the New-tab tile AND the backtick/t shortcuts), switch to
  // it, dismiss the overview, and focus the address bar so you can type right
  // away. about:blank doesn't auto-focus the URL bar (about:newtab would), so
  // we focus it explicitly after the overlay closes + the tab reactivates.
  function ovNewTab(win){
    var gb=win.gBrowser;
    try{ gb.selectedTab = gb.addTrustedTab("about:blank"); }
    catch(e){ try{ win.BrowserCommands.openTab(); }catch(e2){} }
    ovClose(win, true);   // new tab is a tab change → delayed bar release (no old-tab flash)
    win.setTimeout(function(){ try{ win.gURLBar.focus(); win.gURLBar.select(); }catch(e){ try{ win.focusAndSelectUrlBar(); }catch(e2){} } }, 30);
  }

  function ovNewTile(win){
    var tile = OVEL(win,"div","display:flex;flex-direction:column;align-items:center;justify-content:center;gap:10px;height:"+OV_CARD_H+";border-radius:14px;cursor:pointer;"+
      "background:transparent;border:2px dashed rgba(255,255,255,.14);color:"+OV_MUTED+";font-size:14px;transition:background 120ms ease, color 120ms ease;");
    var plus = OVEL(win,"div","font-size:38px;line-height:1;font-weight:300;"); plus.textContent="+";
    var lbl = OVEL(win,"div"); lbl.textContent="New tab  ( t )";
    tile.appendChild(plus); tile.appendChild(lbl);
    tile.addEventListener("mouseenter",function(){ tile.style.background="rgba(255,255,255,.05)"; tile.style.color=OV_TEXT; });
    tile.addEventListener("mouseleave",function(){ tile.style.background="transparent"; tile.style.color=OV_MUTED; });
    tile.addEventListener("click",function(){ ovNewTab(win); });
    return tile;
  }

  function ovRender(win){
    var d=win.document;
    var grid=d.getElementById("golem-ov-grid"); if(!grid) return;
    while(grid.firstChild) grid.removeChild(grid.firstChild);
    var tabs=ovTabs(win);
    tabs.forEach(function(t,i){ grid.appendChild(ovCard(win,t,i)); });
    grid.appendChild(ovNewTile(win));
    var count=d.getElementById("golem-ov-count");
    if(count) count.textContent = tabs.length + (tabs.length===1?" tab":" tabs");
    ovApplyBadges(win);
  }

  // show the 1–9 badges on the nine cards of the current page (offset __golemPage)
  function ovApplyBadges(win){
    var grid=win.document.getElementById("golem-ov-grid"); if(!grid) return;
    var cards=[]; for(var i=0;i<grid.children.length;i++){ if(grid.children[i].__ovBadge) cards.push(grid.children[i]); }
    var page=win.__golemPage||0; if(page>=cards.length) page=win.__golemPage=0;   // clamp (e.g. after a tab close)
    cards.forEach(function(c){ var k=c.__ovIdx-page; if(k>=0&&k<9){ c.__ovBadge.textContent=(k+1); c.__ovBadge.style.display="flex"; } else c.__ovBadge.style.display="none"; });
  }

  // Shift tap: advance to the next page of nine, renumber badges, autoscroll to it.
  function ovShiftPage(win){
    try{
      var n=ovTabs(win).length, pages=Math.max(1,Math.ceil(n/9));
      if(pages<=1) return;                                   // one page — nothing to advance
      var cur=Math.floor((win.__golemPage||0)/9);
      win.__golemPage=((cur+1)%pages)*9;
      ovApplyBadges(win);
      var grid=win.document.getElementById("golem-ov-grid");
      if(grid){ for(var i=0;i<grid.children.length;i++){ var c=grid.children[i]; if(c.__ovIdx===win.__golemPage){ try{ c.scrollIntoView({block:"start",behavior:"smooth"}); }catch(e){ try{ c.scrollIntoView(); }catch(e2){} } break; } } }
    }catch(e){ OVLOG("shiftpage:"+e); }
  }

  // ---- hide/show the content subsurface (the Wayland trick) ----
  // What actually drops the content subsurface is docShellIsActive=false. ovPanel only
  // hides the (now-empty) content box so the overview overlay owns the area and a tab
  // reactivated mid-startup can't flash through. Use visibility:HIDDEN, never collapse:
  // collapse is XUL zero-sizing (it removes the browser's layout box), so the page
  // relayouts from the wrong size when the overview lifts — that was the "jump on open"
  // and the "page fills the window then resizes" on switch. hidden keeps it full-size.
  function ovPanel(win,hide){
    var tp=win.document.getElementById("tabbrowser-tabpanels");
    if(tp) tp.style.visibility = hide ? "hidden" : "";
  }
  function ovContent(win,hide){
    ovPanel(win,hide);
    try{ win.gBrowser.selectedBrowser.docShellIsActive = !hide; }catch(e){}
  }

  function ovIsOpen(win){ var o=win.document.getElementById("golem-overview"); return !!(o && o.style.display!=="none"); }

  // Load ONCE: an agent-level stylesheet that repaints the address-bar field to the
  // overview colour, but ONLY while :root carries [golem-ov]. ATBC tints the field by
  // setting --toolbar-field-background-color INLINE on the root and re-applies it async,
  // which wiped every inline override we tried (that was the red-field mess). It cannot
  // touch an agent sheet, and an agent !important rule outranks its inline var — so the
  // field stays put. Toggling only the attribute (below) leaves NO inline residue, so the
  // bar reverts perfectly when the overview closes.
  function ovInjectFieldStyle(win){
    try{
      if(win.__golemOvSheet) return; win.__golemOvSheet=true;
      // the pin colours are VARIABLES (our own, ATBC never touches them) so a switch can
      // pin the bar to the tab's PREDICTED colour instead of flat; fallback = flat
      var PF="var(--golem-pin-f,"+OV_BACKDROP+")", PA="var(--golem-pin-a,"+OV_BACKDROP+")";
      // TWO things ATBC tints: the address-bar FIELD (the child with class .urlbar-background —
      // a class, not an id, which is why id-based overrides never found it) AND the whole
      // top FRAME/toolbox (its frame colour shows straight through a transparent nav-bar, so
      // the bar reads red on a red page even when the field is fixed). Pin both.
      // (the #urlbar .urlbar-background form carries an id so the overview pin outranks the
      // focused-field rule below, in case the field is somehow focused while the grid is up)
      // colour pin keys on [golem-ov-pin]; the nav-chrome hide (below) keys on [golem-ov]
      var P=":root[golem-ov-pin] ";
      var fld=["#urlbar",".urlbar-background","#urlbar .urlbar-background","#urlbar-background",".urlbar-input-container","#urlbar-input-container"]
              .map(function(s){ return P+s; }).join(",");
      var top=["","#main-window","#navigator-toolbox","#nav-bar","#nav-bar-customization-target","#TabsToolbar","#titlebar",
               "#toolbar-menubar","#PersonalToolbar",".browser-toolbar",".toolbar-items"]
              .map(function(s){ return (P+s).trim(); }).join(",");
      // (A "blend the idle field into the bar" rule was tried here 2026-09-25 and REJECTED by
      // Max — the field must keep its normal, slightly-brighter look during browsing.)
      // Hide the navigation chrome that's useless while the grid is up — address bar,
      // back, forward, reload (Max, 2026-09-25). visibility:hidden, NOT display:none: it
      // keeps their layout space so the tool row and the toggle stay exactly where they
      // are (the toggle must not jump out from under the pointer that hover-opened it).
      var hide=":root[golem-ov] #back-button,:root[golem-ov] #forward-button,:root[golem-ov] #stop-reload-button,:root[golem-ov] #urlbar-container";
      var css=top+"{background-color:"+PA+"!important;background-image:none!important;border-color:"+PA+"!important;}"
            + fld+"{background-color:"+PF+"!important;background-image:none!important;border-color:"+PF+"!important;}"
            + hide+"{visibility:hidden!important;}"
            // Overview buttons are ALWAYS white (Max, 2026-09-25): the bar is flat dark while the
            // grid is up, but the icon colour follows the page's scheme (black on bright pages).
            // Declared on the toolbox, so it overrides the theme's root value for everything in it.
            + ":root[golem-ov] #navigator-toolbox{--toolbarbutton-icon-fill:#ffffff!important;--toolbarbutton-icon-fill-attention:#ffffff!important;"
            + "--toolbarbutton-background-color-hover:rgba(255,255,255,.1)!important;--toolbarbutton-background-color-active:rgba(255,255,255,.16)!important;color:#ffffff!important;}";
      var uri=Services.io.newURI("data:text/css;charset=utf-8,"+encodeURIComponent(css));
      win.windowUtils.loadSheet(uri, win.windowUtils.AGENT_SHEET);
      win.__golemOvSheetOK=true;
    }catch(e){ OVLOG("sheet:"+e); }
  }
  // Two root attributes the agent sheet keys on, so they can release at different times:
  //   golem-ov      overview-open chrome: nav buttons/address bar hidden (tool row shown)
  //   golem-ov-pin  the bar COLOUR pinned flat
  // On a tab switch the first releases instantly with the page; the second is held until
  // ATBC has re-tinted for the new tab. No inline styles anywhere → clean revert.
  function ovBarNav(win,on){ try{ var r=win.document.documentElement; if(on) r.setAttribute("golem-ov","1"); else r.removeAttribute("golem-ov"); }catch(e){} }
  function ovBarPin(win,on){ try{ var r=win.document.documentElement; if(on) r.setAttribute("golem-ov-pin","1"); else r.removeAttribute("golem-ov-pin"); }catch(e){} }
  function ovBarOverride(win,on){ try{ ovInjectFieldStyle(win); ovBarNav(win,on); ovBarPin(win,on); }catch(e){} }

  // ---- per-tab bar colour memory: makes a switch a SINGLE-frame change ----
  // Waiting for ATBC to re-tint after a switch is what produced a two-stage bar (flat,
  // then a pop to the new colour) — the flicker. So remember each tab's bar colour
  // (the two theme vars ATBC drives) whenever it is active, and on a switch to a tab
  // we've seen, paint its colour at the instant of the switch: the page, the nav chrome
  // and the correctly-tinted bar all land together. ATBC's own update follows and,
  // being the same colour, changes nothing visible. Never-seen tabs fall back to the
  // held pin. Only REAL colours are remembered (not the light-dark() placeholder).
  function ovReadBar(win){ try{ var rs=win.getComputedStyle(win.document.documentElement); return { f:(rs.getPropertyValue("--toolbar-field-background-color")||"").trim(), a:(rs.getPropertyValue("--lwt-accent-color")||"").trim() }; }catch(e){ return null; } }
  // Direct commit — only at switch time for the OUTGOING tab, whose colour has been sitting
  // settled for the whole overview.
  function ovCommitBar(win,tab){ try{ if(!tab) return; var c=ovReadBar(win); if(c && c.f && c.f.indexOf("light-dark(")===-1) tab.__golemBar=c; }catch(e){} }
  // Stable commit — for the async reads (after TabSelect, and the 4s tick). A value is
  // remembered only once it has been observed UNCHANGED across two reads at least 250ms
  // apart. Recording at a fixed delay could catch ATBC mid-update and cache the PREVIOUS
  // tab's colour onto this one — which then got painted on the next switch: the
  // "overlapped colours" that came back.
  function ovRememberBar(win,tab){ try{ if(!tab || (win.__gtHold && win.__gtHold.tab===tab)) return; var c=ovReadBar(win); if(!c||!c.f||c.f.indexOf("light-dark(")!==-1) return; var key=c.f+"|"+c.a, L=win.__golemBarLast, now=Date.now(); if(L && L.tab===tab && L.key===key){ if(now-L.t>=250) tab.__golemBar=c; } else win.__golemBarLast={tab:tab,key:key,t:now}; }catch(e){} }
  // Set what the pin paints: flat for the overview, or a tab's predicted colours on a switch.
  function ovBarPinColor(win,f,a){ try{ var s=win.document.documentElement.style; s.setProperty("--golem-pin-f",f||OV_BACKDROP); s.setProperty("--golem-pin-a",a||OV_BACKDROP); }catch(e){} }

  // TEMP diagnostic (OV_DEBUG): confirm the sheet took — read the field's ACTUAL painted
  // colour and the ATBC variable, so a miss is traced from the log, not guessed.
  function ovDiagBar(win){
    try{
      var d=win.document, rs=win.getComputedStyle(d.documentElement), out=[];
      out.push("attr="+(d.documentElement.hasAttribute("golem-ov")?"on":"off"));
      out.push("root="+rs.backgroundColor);
      // the whole top chrome: whichever of these is NOT rgb(29,32,38) is what reads as red
      ["navigator-toolbox","nav-bar","TabsToolbar","titlebar","toolbar-menubar","PersonalToolbar","urlbar"].forEach(function(id){
        var el=d.getElementById(id);
        out.push(id+"="+(el?win.getComputedStyle(el).backgroundColor:"(none)"));
      });
      var ub=d.getElementById("urlbar");
      if(ub){ var kids=ub.children||[]; for(var i=0;i<kids.length;i++){ var bg=win.getComputedStyle(kids[i]).backgroundColor; if(bg&&bg!=="rgba(0, 0, 0, 0)") out.push((kids[i].id||kids[i].className||kids[i].nodeName)+"="+bg); } }
      out.push("V:accent="+rs.getPropertyValue("--lwt-accent-color").trim());
      out.push("V:tf-bg="+rs.getPropertyValue("--toolbar-field-background-color").trim());
      OVLOG("DIAGBAR "+out.join("  "));
    }catch(e){ OVLOG("DIAGBAR-err:"+e); }
  }

  function ovOpenImpl(win){
    var d=win.document;
    var host=ovHostEl(win); if(!host){ return; }
    ovCaptureActive(win);   // refresh the active tab's thumb while it still paints
    var ov=d.getElementById("golem-overview");
    if(!ov){
      ov=OVEL(win,"div","position:absolute;inset:0;z-index:50;display:flex;flex-direction:column;background:"+OV_BACKDROP+";");
      ov.id="golem-overview";
      var scroll=OVEL(win,"div","flex:1;min-height:0;overflow-y:auto;padding:10px 30px 34px 30px;");
      ov.addEventListener("click",function(ev){ if(ev.target===ov || ev.target===scroll) ovClose(win); });

      var head=OVEL(win,"div","flex:0 0 auto;display:flex;align-items:center;gap:12px;padding:18px 30px 12px 30px;");
      var h=OVEL(win,"div","color:"+OV_TEXT+";font-size:16px;font-weight:600;"); h.textContent="Tabs";
      var count=OVEL(win,"div","color:"+OV_MUTED+";font-size:13px;"); count.id="golem-ov-count";
      var spacer=OVEL(win,"div","flex:1;");
      var close=OVEL(win,"div","width:30px;height:30px;border-radius:50%;display:flex;align-items:center;justify-content:center;background:rgba(255,255,255,.06);color:#cfd3db;cursor:pointer;font-size:14px;");
      close.textContent="✕";
      close.addEventListener("mouseenter",function(){ close.style.background="rgba(255,255,255,.13)"; });
      close.addEventListener("mouseleave",function(){ close.style.background="rgba(255,255,255,.06)"; });
      close.addEventListener("click",function(){ ovClose(win); });
      head.appendChild(h); head.appendChild(count); head.appendChild(spacer); head.appendChild(close);

      var grid=OVEL(win,"div","display:grid;grid-template-columns:repeat(auto-fill,minmax("+OV_COL_MIN+",1fr));gap:"+OV_GAP+";");
      grid.id="golem-ov-grid";
      scroll.appendChild(grid);

      ov.appendChild(head); ov.appendChild(scroll); host.appendChild(ov);
    }
    win.__golemPage=0;   // reset paging on each open
    ov.style.background = OV_BACKDROP;   // fixed new-tab colour (matches the bar)
    ovBarPinColor(win,OV_BACKDROP,OV_BACKDROP);   // the overview pins the bar FLAT
    ovBarOverride(win,true);             // make the bar the same colour, seamlessly, on open
    ovShowTools(win,true);               // reveal the app-action row left of the toggle
    if(OV_DEBUG){ ovDiagBar(win); win.setTimeout(function(){ ovDiagBar(win); }, 400); }  // TEMP: log field colours now + after ATBC settles
    ovRender(win);
    ovContent(win,true);
    ov.style.display="flex";
    win.setTimeout(function(){ try{ ovCaptureLoaded(win); }catch(e){} },120);   // fill cache from loaded bg tabs (content hidden → no flash)
    // Blur the address bar on open so the overview keyboard shortcuts win — e.g.
    // after backtick/t leaves the URL bar focused, reopening must not have the guard
    // below swallow q/t/1-9. (Deliberately clicking the URL bar re-focuses it,
    // and the guard then yields so you can type.)
    try{ if(win.gURLBar && win.gURLBar.focused) win.gURLBar.blur(); }catch(e){}

    // Keys while the overview is open:
    //   Esc            close
    //   backtick / t   new tab (+ focus address bar)
    //   q              close the hovered tab (stay open)
    //   1–9            jump to that tab within the CURRENT page of nine
    //   Shift (tapped) page forward — badges renumber (tab 10 → "1", 11 → "2", …)
    //                  and the grid autoscrolls to that page; wraps back to page 1.
    // backtick / t / q / 1-9 are skipped while the address bar is focused (so you can type).
    if(!win.__golemOvKey){
      win.__golemOvKey=function(ev){
        if(!ovIsOpen(win)) return;
        if(ev.key==="Escape"){ ev.preventDefault(); ev.stopPropagation(); ovClose(win); return; }
        if(ev.ctrlKey||ev.metaKey||ev.altKey) return;
        try{ if(win.gURLBar && win.gURLBar.focused) return; }catch(e){}
        // Shift is a SOLO tap → page forward (fires on keyup below); any other
        // key cancels the pending tap (so Shift+key never pages).
        if(ev.key==="Shift"){ if(!ev.repeat) win.__golemShiftTap=true; return; }
        win.__golemShiftTap=false;
        if(ev.key===OV_BT || ev.key==="t" || ev.key==="T"){ ev.preventDefault(); ev.stopPropagation(); ovNewTab(win); return; }
        if(ev.key==="q" || ev.key==="Q"){   // close the CURRENT tab — the one you're on, even a just-opened one; stay open. (Close a SPECIFIC other tab with its card's ✕.)
          var qt=win.gBrowser.selectedTab;
          if(qt){ ev.preventDefault(); ev.stopPropagation(); try{ win.gBrowser.removeTab(qt,{animate:false}); }catch(e){} win.setTimeout(function(){ ovRender(win); },0); }
          return;
        }
        if(ev.key>="1" && ev.key<="9"){     // jump within the current page of nine
          var oi=(win.__golemPage||0)+(ev.key.charCodeAt(0)-49), otabs=ovTabs(win);
          if(oi<otabs.length){ ev.preventDefault(); ev.stopPropagation(); ovSwitchTo(win,otabs[oi]); }
          return;
        }
      };
      win.addEventListener("keydown",win.__golemOvKey,true);
      win.__golemOvKeyUp=function(ev){
        if(!ovIsOpen(win)) return;
        if(ev.key==="Shift" && win.__golemShiftTap){ win.__golemShiftTap=false; ev.preventDefault(); ev.stopPropagation(); ovShiftPage(win); }
      };
      win.addEventListener("keyup",win.__golemOvKeyUp,true);
      win.__golemOvBlur=function(){ win.__golemShiftTap=false; };
      win.addEventListener("blur",win.__golemOvBlur,true);
    }
    var btn=d.getElementById("golem-overview-btn"); if(btn) btn.style.background="rgba(255,255,255,.14)";
    OVLOG("overview open ("+ovTabs(win).length+" tabs)");
  }

  // shared teardown: detach the overview-only key listeners + reset transient state.
  function ovTeardown(win){
    var d=win.document;
    if(win.__golemOvKey){ try{ win.removeEventListener("keydown",win.__golemOvKey,true); }catch(e){} win.__golemOvKey=null; }
    if(win.__golemOvKeyUp){ try{ win.removeEventListener("keyup",win.__golemOvKeyUp,true); }catch(e){} win.__golemOvKeyUp=null; }
    if(win.__golemOvBlur){ try{ win.removeEventListener("blur",win.__golemOvBlur,true); }catch(e){} win.__golemOvBlur=null; }
    win.__golemShiftTap=false; win.__golemPage=0;
    var btn=d.getElementById("golem-overview-btn"); if(btn) btn.style.background="transparent";
  }

  // Plain dismiss (Esc / backdrop / button / a card ✕): hide the grid and bring the
  // current tab back. No tab change, so its own last frame is already what shows.
  function ovCloseImpl(win, switching, pred){
    win.__golemUserActed=true;   // hand control to the user → stop the startup re-assert
    var d=win.document;
    var ov=d.getElementById("golem-overview");
    // Reveal INSTANTLY — overlay off, nav chrome back, tool row off, content live — in
    // one frame. (An earlier design held the content until the bar colour had settled;
    // that stalled the page for up to ~280ms and let its warm layers go stale, so it
    // flickered in. The page must never wait on ATBC.)
    if(ov) ov.style.display="none";
    ovBarNav(win,false);
    ovShowTools(win,false);
    ovContent(win,false);
    // the active tab just re-activated + is now visible — capture it (belt-and-
    // suspenders for the selected tab, which the overview kept deactivated)
    win.setTimeout(function(){ try{ ovCaptureActive(win); }catch(e){} },250);
    ovTeardown(win);
    OVLOG("overview closed");
    win.setTimeout(function(){ ovBlankCheck(win,"close"); },700);             // blank-tab watchdog
    if(!switching){ ovBarPin(win,false); return; }   // plain dismiss: the current tab's colour is already right
    // TAB CHANGE: the page is already showing and the bar is pinned to the PREDICTED
    // colour (the tab's remembered tint; flat if never seen). Hold that pin through
    // ATBC's own update — which passes through a default/reset frame before it lands —
    // so none of that churn is visible, and release only once ATBC's value MATCHES the
    // prediction: an invisible release. Unseen tab: release once the value has moved to
    // a real colour. Fallback so it can never hang.
    var done=false, mo=null, t0=Date.now(), settle=null, n=0;
    var root=d.documentElement, cur0=ovReadBar(win)||{f:"",a:""};
    OVLOG("SWITCH pred="+(pred?pred.f+" / "+pred.a:"none")+"  cur="+cur0.f+" / "+cur0.a);
    var go=function(via){
      if(done) return; done=true;
      try{ if(mo) mo.disconnect(); }catch(e){}
      if(settle) win.clearTimeout(settle);
      OVLOG("switch-release via="+via+" dt="+(Date.now()-t0)+"ms writes="+n);
      ovBarPin(win,false);
    };
    var ready=function(){ var c=ovReadBar(win); if(!c) return false; if(pred) return c.f===pred.f; return c.f!==cur0.f && c.f.indexOf("light-dark(")===-1; };
    try{
      mo=new win.MutationObserver(function(){ n++; if(!ready()) return; if(settle) win.clearTimeout(settle); settle=win.setTimeout(function(){ go("matched"); }, 30); });
      mo.observe(root,{attributes:true,attributeFilter:["style"]});
    }catch(e){}
    if(ready()) win.setTimeout(function(){ go("already"); }, 30);   // ATBC may have landed before we looked
    win.setTimeout(function(){ go("fallback"); }, 450);
    // DEEP-DEBUG timeline (OV_DEBUG): sample the bar vars every 16ms for 700ms after the
    // switch and log every change with the pin state — the exact sequence the bar went through.
    if(OV_DEBUG){ (function(){ var last="", s0=Date.now(); var iv=win.setInterval(function(){ try{ var c=ovReadBar(win)||{f:"?",a:"?"}; var k=c.f+"|"+c.a; if(k!==last){ last=k; OVLOG("  SW +"+(Date.now()-s0)+"ms  f="+c.f+"  a="+c.a+"  pin="+(root.hasAttribute("golem-ov-pin")?"on":"off")); } }catch(e){} if(Date.now()-s0>700) win.clearInterval(iv); },16); })(); }
  }

  // Switch to a tab from the overview. The picked tab was warmed on hover and its
  // layers are kept alive (tabCacheSize), so selecting it + lifting the overlay lands
  // straight on it. (An earlier attempt to pre-paint it behind the collapsed panel
  // could never work: visibility:collapse removes the layout box, so it can't render
  // while hidden — the fix has to be keeping the layers warm, not hiding cleverer.)
  function ovSwitchToImpl(win,tab){
    win.__golemUserActed=true;
    var gb=win.gBrowser;
    ovCommitBar(win, gb.selectedTab);     // the vars right now are the OUTGOING tab's settled colours
    if(tab){
      try{ gb.selectedTab=tab; }catch(e){}
      // verify it took: the gBrowser setter can silently refuse (proven in a headless
      // session, where tabContainer.selectedIndex still worked) — never leave the user
      // on the wrong tab after picking one
      if(gb.selectedTab!==tab){ try{ var i=Array.prototype.indexOf.call(gb.tabs,tab); if(i>=0) gb.tabContainer.selectedIndex=i; }catch(e){} }
    }
    var pred=(tab && !(win.__gtHold && win.__gtHold.tab===tab) && tab.__golemBar)||null;   // a tab that must load shows the Golem colour (loading hold), not a stale prediction
    if(pred) ovBarPinColor(win,pred.f,pred.a);   // pin the bar to the PREDICTED colour before anything shows
    ovClose(win, true, pred);             // hold that pin through ATBC's update; release when it matches
  }

  function ovToggle(win){ if(ovIsOpen(win)) ovClose(win); else ovOpen(win); }

  // ---- utility buttons REVEALED on the overview, immediately LEFT of the grid toggle ----
  // (Max, 2026-09-25: the address bar is useless while the grid is up; rather than hide
  // the bar, surface the vertical-tabs-sidebar set of app actions next to the toggle.)
  // Icons are Firefox's own chrome:// svgs, tinted via -moz-context-properties so they
  // match the toggle. Each button dismisses the overview, then fires its action; every
  // action has a fallback so a missing API can never leave a dead button.
  var OV_TOOLS=[
    ["Downloads","chrome://browser/skin/downloads/downloads.svg",function(w){ try{ w.DownloadsPanel.showDownloadsHistory(); }catch(e){ try{ w.switchToTabHavingURI("about:downloads",true); }catch(e2){} } }],
    ["History","chrome://browser/skin/history.svg",function(w){ try{ w.PlacesCommandHook.showPlacesOrganizer("History"); }catch(e){ try{ w.SidebarController.toggle("viewHistorySidebar"); }catch(e2){} } }],
    ["Bookmarks","chrome://browser/skin/bookmark.svg",function(w){ try{ w.PlacesCommandHook.showPlacesOrganizer("AllBookmarks"); }catch(e){ try{ w.SidebarController.toggle("viewBookmarksSidebar"); }catch(e2){} } }],
    ["New window","chrome://browser/skin/window.svg",function(w){ try{ w.OpenBrowserWindow(); }catch(e){} }],
    ["New private window","chrome://browser/skin/privateBrowsing.svg",function(w){ try{ w.OpenBrowserWindow({private:true}); }catch(e){} }]
  ];   // (a Settings button was here and REJECTED by Max 2026-09-25 — do not re-add)
  function ovTools(win){
    // Cached on the window, NOT looked up by id: at startup ovOpen runs before the nav-bar
    // button exists (+1100ms), so the box is created detached; a getElementById lookup
    // then can't find it and a second, hidden box gets inserted — the row was invisible
    // on first boot until a close/reopen toggled the attached one.
    if(win.__golemOvTools) return win.__golemOvTools;
    var box=OVEL(win,"div","display:none;align-items:center;gap:2px;margin:0 4px 0 2px;flex:0 0 auto;align-self:center;");
    box.id="golem-ov-tools";
    OV_TOOLS.forEach(function(t){
      var b=OVEL(win,"div","display:flex;align-items:center;justify-content:center;width:30px;height:28px;border-radius:6px;cursor:pointer;color:var(--toolbarbutton-icon-fill, currentColor);transition:background 110ms ease;");
      b.setAttribute("title",t[0]);
      var im=OVEL(win,"img","width:16px;height:16px;-moz-context-properties:fill;fill:currentColor;pointer-events:none;");
      im.setAttribute("src",t[1]); b.appendChild(im);
      b.addEventListener("mouseenter",function(){ b.style.background="var(--toolbarbutton-background-color-hover, rgba(255,255,255,.08))"; });
      b.addEventListener("mouseleave",function(){ b.style.background="transparent"; });
      b.addEventListener("click",function(ev){ ev.preventDefault(); ev.stopPropagation(); ovClose(win); try{ t[2](win); }catch(e){} });
      box.appendChild(b);
    });
    win.__golemOvTools=box;
    return box;
  }
  // keep the row pinned immediately LEFT of the grid toggle (re-asserted alongside it)
  function ovPlaceTools(win){
    try{
      var d=win.document, btn=d.getElementById("golem-overview-btn"), box=ovTools(win);
      if(btn && btn.parentNode && box.nextElementSibling!==btn) btn.parentNode.insertBefore(box, btn);
    }catch(e){}
  }
  // showing also (re)attaches it, so the row is placed as soon as the toggle exists
  function ovShowTools(win,on){ try{ ovTools(win).style.display = on ? "flex" : "none"; if(on) ovPlaceTools(win); }catch(e){} }

  // ---- the nav-bar button (far left, before back) — hover or click ----
  function ovButton(win){
    var d=win.document;
    if(d.getElementById("golem-overview-btn")) return;
    var navbar=d.getElementById("nav-bar"); if(!navbar) return;
    var b=OVEL(win,"div","display:flex;align-items:center;justify-content:center;align-self:center;width:30px;height:28px;margin:0 6px 0 2px;flex:0 0 auto;border-radius:6px;cursor:pointer;color:var(--toolbarbutton-icon-fill, currentColor);transition:background 110ms ease;");
    b.id="golem-overview-btn";
    b.setAttribute("title","Show all tabs");
    b.innerHTML='<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 16 16" fill="currentColor" aria-hidden="true"><rect x="1" y="1" width="6" height="6" rx="1.7"/><rect x="9" y="1" width="6" height="6" rx="1.7"/><rect x="1" y="9" width="6" height="6" rx="1.7"/><rect x="9" y="9" width="6" height="6" rx="1.7"/></svg>';
    // HOVER-TO-TOGGLE with hover-intent: dwelling ~140ms on the button TOGGLES the
    // overview — hover to open, hover again to close. A quick graze (on the way to
    // back/forward, or across the button while reaching into the grid) is cancelled by
    // mouseleave before the dwell elapses. Click toggles instantly too. Opening leaves
    // the pointer on the button with no re-fire (mouseenter needs a fresh crossing), so
    // it won't bounce; to close by hover you leave and come back onto the button.
    var ovHoverT=null;
    b.addEventListener("mouseenter",function(){
      b.style.background = ovIsOpen(win) ? "rgba(255,255,255,.20)" : "var(--toolbarbutton-background-color-hover, rgba(255,255,255,.08))";
      ovHoverT=win.setTimeout(function(){ ovHoverT=null; ovToggle(win); },OV_HOVER_MS);
    });
    b.addEventListener("mouseleave",function(){
      b.style.background = ovIsOpen(win) ? "rgba(255,255,255,.14)" : "transparent";
      if(ovHoverT){ win.clearTimeout(ovHoverT); ovHoverT=null; }
    });
    b.addEventListener("click",function(ev){ ev.preventDefault(); ev.stopPropagation(); if(ovHoverT){ win.clearTimeout(ovHoverT); ovHoverT=null; } ovToggle(win); });
    navbar.appendChild(b);
    OVLOG("overview button added");
    ovPlaceButton(win);
    win.setTimeout(function(){ ovPlaceButton(win); },1500);  // re-assert after CustomizableUI reflow
  }

  // The overview button sits between the ADDRESS BAR and uBlock, inside
  // #nav-bar-customization-target → [back][fwd][reload][address][overview][uBO].
  // It's a non-widget div in the widget target, so CustomizableUI can strip it —
  // hence the re-assert timer + re-run every startup. align-self:center keeps it
  // vertically centred with the toolbar buttons (verified: centre-y matches the
  // back button exactly; the target otherwise top-aligns a fixed-height div,
  // which read as "too high"). reload is left in place.
  function ovPlaceButton(win){
    try{
      var d=win.document;
      var target=d.getElementById("nav-bar-customization-target");
      var btn=d.getElementById("golem-overview-btn");
      if(!target||!btn) return;
      var ublock=d.getElementById("ublock0_raymondhill_net-browser-action");
      if(ublock && ublock.parentNode===target){
        if(btn.nextElementSibling!==ublock) target.insertBefore(btn, ublock);
      } else if(btn.parentNode!==target){
        target.appendChild(btn);   // no uBO found → end of target (still right of address)
      }
      ovPlaceTools(win);           // the revealed-on-overview row rides just left of the toggle
    }catch(e){ OVLOG("place:"+e); }
  }

  // ---- thumbnail capture wiring: snapshot a tab whenever it is the painting one ----
  function ovInit(win){
    if(win.__golemOvInit) return; win.__golemOvInit=true;
    try{
      ovLoadMapAsync(win);  // warm the persisted cache (off-thread) so restored tabs show thumbnails on first open
      if(!ovQuitObs){ ovQuitObs=true; try{ Services.obs.addObserver({observe:function(){ try{ if(ovMapDirty) ovSaveNow(); }catch(e){} }},"quit-application-granted"); }catch(e){} }
      var gb=win.gBrowser;
      gb.tabContainer.addEventListener("TabSelect",function(ev){
        var t=ev.target; win.setTimeout(function(){ ovCaptureTab(win,t); },350);   // capture on ENTER
        win.setTimeout(function(){ ovPaintNudge(win,t); },150);   // un-stick a never-presented tab
        win.setTimeout(function(){ ovBlankCheck(win,"select"); },700);            // blank-tab watchdog
        // and its bar colour — three reads, so it commits only once STABLE (see ovRememberBar)
        [500,800,1200].forEach(function(ms){ win.setTimeout(function(){ ovRememberBar(win,t); },ms); });
      });
      // When a tab's URL settles (e.g. the restored ACTIVE tab finishes loading —
      // it opens as about:blank then becomes the real URL), re-render the open
      // overview so its card's cache lookup uses the real URL and its thumbnail
      // appears. This is why the active tab alone showed a favicon at startup.
      try{ gb.addTabsProgressListener({ onLocationChange:function(aBrowser,aWebProgress,aRequest,aLocation,aFlags){
        try{ if(ovIsOpen(win) && !win.__ovReRenderT){ win.__ovReRenderT=win.setTimeout(function(){ win.__ovReRenderT=null; if(ovIsOpen(win)) ovRefreshCards(win); },200); } }catch(e){}
      }}); }catch(e){}
      win.setTimeout(function(){ ovCaptureActive(win); },1200);  // seed the first tab
      // Periodic capture of the ACTIVE tab (only while the overview is CLOSED, so
      // it's genuinely painting → a real frame, no activation trickery). This is
      // what catches the tab you're SITTING ON — including the startup-active tab
      // that never got a TabSelect — so whatever tab is active at quit already has
      // a recent thumbnail. Skips a tab captured in the last 20s (freshness window,
      // bounds disk writes).
      win.setInterval(function(){
        try{
          ovRememberBar(win, win.gBrowser.selectedTab);   // keep the active tab's bar colour current
          if(ovIsOpen(win)) return;
          var tab=win.gBrowser.selectedTab; if(!tab) return;
          var url=ovTabUrl(tab); if(!/^https?:/i.test(url)) return;
          // skip only if we already have a DECENT-sized thumbnail that's fresh;
          // a tiny one (<15KB) is a blank/partial from a bad capture → re-grab it.
          var e=ovLoadMap()[url]; if(e && e.d && e.d.length>=15000 && (Date.now()-(e.t||0))<20000) return;
          ovCaptureActive(win);
        }catch(e){}
      }, 4000);
      ovAltWire(win);
    }catch(e){}
  }

  // Tap Alt (alone) to toggle the overview. Alt is also a modifier (Alt+D,
  // Alt+<-, Alt+Tab...), so fire ONLY on a clean solo tap: Alt down -> Alt up
  // with no other key in between, released within 600ms, and not after a focus
  // loss (Alt+Tab). Suppress Firefox's default menu-bar-on-Alt.
  function ovAltWire(win){
    if(win.__golemAltWired) return; win.__golemAltWired=true;
    var pending=false, downAt=0;
    win.addEventListener("keydown",function(ev){
      if(ev.key==="Alt" && !ev.ctrlKey && !ev.metaKey && !ev.shiftKey){
        if(!ev.repeat){ pending=true; downAt=Date.now(); }
      } else { pending=false; }   // any other key (incl. Alt+X) cancels the solo tap
    },true);
    win.addEventListener("keyup",function(ev){
      if(ev.key!=="Alt") return;
      if(win.__golemOvDisabled){ pending=false; return; }   // degraded: Alt is Firefox's again
      if(pending && (Date.now()-downAt)<600){
        pending=false; ev.preventDefault(); ev.stopPropagation();
        ovToggle(win);
      } else { pending=false; }
    },true);
    win.addEventListener("blur",function(){ pending=false; },true);   // Alt+Tab / focus loss
    win.addEventListener("mousedown",function(){ pending=false; },true);
  }

  // ---- BEAM TINT — colour maths: an exact port of Adaptive Tab Bar Colour's (ATBC)
  // defaults, so the bar looks the same with ATBC removed. Verified bit-for-bit against
  // ATBC's own colour class (see ~/Golem/beam/README.md). Colours are [r,g,b] floats,
  // unrounded, exactly like ATBC.
  function gtLin(e){ return e<0?0:e<32?.1151*e:e<64?.2935*e-5.7074:e<96?.5236*e-20.4339:e<128?.788*e-45.8232:e<160?1.0811*e-83.3411:e<192?1.3992*e-134.2269:e<224?1.7395*e-199.5679:e<256?2.1001*e-280.341:255; }
  function gtLum(c){ return .2126*gtLin(c[0])+.7152*gtLin(c[1])+.0722*gtLin(c[2]); }
  function gtRatio(a,b){ var t=gtLum(a), n=gtLum(b); return t>n?(t+12.75)/(n+12.75):(n+12.75)/(t+12.75); }
  function gtClamp(v){ return Math.max(0,Math.min(255,v)); }
  function gtBright(c,t){
    var n=t/100;
    if(1<n) return [255,255,255];
    if(0<n && n<=1) return [gtClamp(n*255+(1-n)*c[0]),gtClamp(n*255+(1-n)*c[1]),gtClamp(n*255+(1-n)*c[2])];
    if(n===0) return [c[0],c[1],c[2]];
    if(-1<=n && n<0) return [gtClamp((n+1)*c[0]),gtClamp((n+1)*c[1]),gtClamp((n+1)*c[2])];
    if(n<-1) return [0,0,0];
    return [c[0],c[1],c[2]];
  }
  // browser scheme is dark; allowDarkLight=true, minContrast_light=90, minContrast_dark=45
  function gtCorrect(c){
    var s=gtRatio(c,[0,0,0]), w=gtRatio(c,[255,255,255]);
    if(s>9) return {c:c, scheme:"light"};
    if(w>4.5) return {c:c, scheme:"dark"};
    return {c:gtBright(c, 10*w*100/45-100), scheme:"dark"};
  }
  function gtRGBA(c){ return "rgba("+c[0]+", "+c[1]+", "+c[2]+", 1)"; }
  // the theme ATBC would apply for a page whose top colour is page, as CSS variables
  // (theme key -> Firefox 156 variable, per its ThemeVariableMap)
  function gtTheme(page){
    var cc=gtCorrect(page), c=cc.c, L=(cc.scheme==="light");
    var i=function(x){ return gtRGBA(gtBright(c,(L?-1.5:1)*x)); };
    var txt=L?"#000000":"#ffffff", soft=L?"#0000001c":"#ffffff1c";
    return { scheme:cc.scheme, vars:{
      "--lwt-accent-color":i(0), "--lwt-accent-color-inactive":i(0),       // frame
      "--toolbar-background-color":i(0),                                   // toolbar
      // default (non-lightweight) theme: the toolbox is painted from these, not --lwt-*
      "--toolbox-background-color":i(0), "--toolbox-background-color-inactive":i(0),
      "--toolbox-text-color":txt, "--toolbox-text-color-inactive":txt, "--toolbar-color":txt,
      "--toolbar-field-background-color":i(5),                             // toolbar_field
      "--toolbar-field-border-color":i(10),                                // toolbar_field_border
      "--toolbar-field-background-color-focus":i(5),                       // toolbar_field_focus
      "--toolbar-field-border-color-focus":"AccentColor",
      "--sidebar-background-color":i(0), "--lwt-sidebar-background-color":i(0),   // Golem: vertical tabs match the BAR (Max, 2026-09-25; ATBC used +5 = the field)
      "--sidebar-border-color":i(15),
      "--tab-background-color-selected":i(15), "--lwt-tab-line-color":i(15),
      "--toolbarbutton-background-color-active":i(15),
      "--toolbarbutton-background-color-hover":soft, "--toolbarseparator-color":soft,
      "--chrome-content-separator-color":i(0),
      "--panel-background-color":i(5), "--panel-border-color":i(15),
      "--urlbarview-background-color-selected":"AccentColor",
      "--lwt-text-color":txt, "--toolbar-text-color":txt, "--toolbar-field-text-color":txt,
      "--toolbar-field-text-color-focus":txt, "--tab-selected-textcolor":txt,
      "--sidebar-text-color":txt, "--panel-text-color":txt, "--toolbarbutton-icon-fill":txt
    }};
  }

  // ---- BEAM TINT — engine (replaces the ATBC extension; built-in, on by default). ATBC injected a script into EVERY page and re-sampled on every
  // scroll/click/resize/animation, rewriting the whole browser theme each time. Here:
  // no page script — the colour is read from the RENDERED page (2 px at top-centre,
  // ATBC's own sample point) once per load / in-page navigation, cached per tab and
  // per site, and applied through an agent sheet nothing can overwrite. Zero work
  // while scrolling.
  var GT_PREF="golem.beam.tint";
  var GT_VARS=Object.keys(gtTheme([0,0,0]).vars);
  var gtSite={};   // host -> [r,g,b], session memory only
  // DORMANT (2026-09-25): Max tried it live — "it sucks… wrong color". A raw pixel read at one
  // point lands on text/images/edges; ATBC reads the page's ELEMENT colours. ATBC is restored;
  // this engine stays OFF (and loads nothing) unless golem.beam.tint is set for development.
  function gtOn(){ try{ return Services.prefs.getBoolPref(GT_PREF,false); }catch(e){ return false; } }
  function gtKey(v){ return "--gt"+v.slice(1); }   // --lwt-accent-color -> --gt-lwt-accent-color
  function gtHost(tab){ try{ return tab.linkedBrowser.currentURI.host||""; }catch(e){ return ""; } }

  function gtSheet(win){
    if(win.__golemTintSheet) return; win.__golemTintSheet=true;
    try{
      var css=":root[golem-tint]{"+GT_VARS.map(function(v){ return v+":var("+gtKey(v)+")!important;"; }).join("")+"}";
      // The CONTENT area before a page paints (loading) is --tabpanel-background-color:
      // #2b2a33 in Firefox's dark theme and in ATBC's theme (its ntp_background), a purple
      // gradient in private windows. Always the Golem colour (Max, 2026-09-25). Agent
      // !important outranks Firefox's own !important variants. Pages themselves are
      // unaffected — this only shows before a document paints.
      css+=":root,:root[privatebrowsingmode]{--tabpanel-background-color:"+OV_BACKDROP+"!important;}";
      // Paint the bar itself: under the default theme the top bar is a NATIVE (GTK) surface,
      // so the variables alone only reached the address field. :where() keeps these rules
      // below the overview's flat pin (which must win while the grid is up).
      css+=":root[golem-tint] :where(#navigator-toolbox,#nav-bar,#nav-bar-customization-target,.browser-toolbar,.toolbar-items){"
         +"-moz-default-appearance:none!important;appearance:none!important;background-image:none!important;"
         +"background-color:var(--gt-toolbox-background-color)!important;color:var(--gt-toolbox-text-color)!important;}";
      win.windowUtils.loadSheet(Services.io.newURI("data:text/css;charset=utf-8,"+encodeURIComponent(css)), win.windowUtils.AGENT_SHEET);
    }catch(e){ OVLOG("tint sheet:"+e); }
  }
  function gtApply(win,page){
    try{
      var key=page.join(",");
      if(win.__gtLastKey===key && win.document.documentElement.hasAttribute("golem-tint")) return;
      win.__gtLastKey=key;
      var t=gtTheme(page), r=win.document.documentElement, s=r.style;
      for(var k in t.vars) s.setProperty(gtKey(k), t.vars[k]);
      if(r.getAttribute("golem-tint")!==t.scheme) r.setAttribute("golem-tint", t.scheme);
    }catch(e){ OVLOG("tint apply:"+e); }
  }
  function gtClear(win){
    win.__gtLastKey=null;
    try{ var r=win.document.documentElement; r.removeAttribute("golem-tint"); GT_VARS.forEach(function(v){ r.style.removeProperty(gtKey(v)); }); }catch(e){}
  }
  // read the page's top-centre colour from what is actually rendered
  function gtSample(win,tab,cb){
    try{
      if(!gtOn() || !tab || tab!==win.gBrowser.selectedTab || ovIsOpen(win)) return;
      var b=tab.linkedBrowser; if(!b || !b.docShellIsActive) return;
      var wg=b.browsingContext && b.browsingContext.currentWindowGlobal; if(!wg) return;
      var W=Math.round(b.getBoundingClientRect().width); if(W<8) return;
      if(win.__gtBusy){ win.__gtAgain=true; return; } win.__gtBusy=true;
      var fin=function(){ win.__gtBusy=false; if(win.__gtAgain){ win.__gtAgain=false; gtSample(win, win.gBrowser.selectedTab); } };
      // drawSnapshot's rect is DOCUMENT-relative (proven headless: after scrolling to y=3917 it
      // still read the top). ATBC's point is the top of the VIEWPORT, so offset by the tab's
      // last reported scroll position (0 for a fresh page).
      var sc=tab.__gtScroll||{x:0,y:0};
      wg.drawSnapshot(new win.DOMRect(sc.x+Math.floor(W/2)-1,sc.y+3,2,1),1,"rgb(255,255,255)").then(function(bm){
        try{
          var cv=win.document.createElementNS(OV_HTML,"canvas"); cv.width=bm.width; cv.height=bm.height;
          var cx=cv.getContext("2d"); cx.drawImage(bm,0,0); var p=cx.getImageData(0,0,1,1).data;
          try{ bm.close(); }catch(e){}
          var c=[p[0],p[1],p[2]];
          tab.__gtPage=c; var h=gtHost(tab); if(h) gtSite[h]=c;
          if(tab===win.gBrowser.selectedTab && gtOn()) gtApply(win,c);
          if(cb) cb(c);
        }catch(e){}
        fin();
      },fin);
    }catch(e){}
  }
  function gtShow(win,tab){   // switching: paint the known colour NOW, then re-check
    if(!gtOn()) return;
    var c=(tab&&tab.__gtPage)||gtSite[gtHost(tab)];
    if(c) gtApply(win,c);
    win.setTimeout(function(){ gtSample(win,tab); },150);
  }
  function gtInit(win){
    if(win.__golemTintInit) return; win.__golemTintInit=true;
    try{
      gtSheet(win);
      var gb=win.gBrowser;
      gb.tabContainer.addEventListener("TabSelect",function(ev){ gtShow(win,ev.target); });
      var WPL=Components.interfaces.nsIWebProgressListener;
      gb.addTabsProgressListener({
        onStateChange:function(br,wp,req,flags){
          try{ if(!(flags&WPL.STATE_STOP) || !(flags&WPL.STATE_IS_WINDOW) || !wp.isTopLevel) return;
               if(br!==gb.selectedBrowser) return;
               var t=gb.selectedTab; t.__gtScroll=null; win.setTimeout(function(){ gtSample(win,t); },100); win.setTimeout(function(){ gtSample(win,t); },900); }catch(e){}
        },
        onLocationChange:function(br,wp,req,loc,flags){
          try{ if(!wp.isTopLevel || br!==gb.selectedBrowser) return;
               var t=gb.selectedTab; win.setTimeout(function(){ gtSample(win,t); },400); }catch(e){}
        }
      });
      // ADAPTIVE ON SCROLL (Max: the bar must follow what is under it as you scroll).
      // A minimal frame script in each tab only says "scrolled" — throttled to one ping per
      // 120ms plus a trailing one when scrolling stops. No DOM queries in the page, unlike
      // ATBC; the colour is read from the rendered frame here and the bar restyles only
      // when the colour actually changes.
      var FS="data:application/javascript;charset=utf-8,"+encodeURIComponent(
        "(function(){var last=0,t=0;function ping(){last=Date.now();t=0;try{sendAsyncMessage('golem:scrolled',{x:content.scrollX,y:content.scrollY});}catch(e){}}"+
        "addEventListener('scroll',function(){var n=Date.now();if(n-last>=120)ping();"+
        "try{if(t)content.clearTimeout(t);t=content.setTimeout(ping,150);}catch(e){}},{capture:true,passive:true});addEventListener('pageshow',function(){ping();},true);})();");
      // off → no scroll script in any page at all (zero cost while dormant)
      if(gtOn() || OV_SELFTEST){ try{ win.messageManager.loadFrameScript(FS, true); }catch(e){ OVLOG("tint framescript:"+e); } }
      win.messageManager.addMessageListener("golem:scrolled",function(m){
        try{
          var tab=gb.getTabForBrowser(m.target); if(!tab) return;
          tab.__gtScroll={x:(m.data&&m.data.x)||0, y:(m.data&&m.data.y)||0};
          if(OV_SELFTEST){ (win.__gtPings=win.__gtPings||[]).push(tab.__gtScroll.y); }
          if(tab===gb.selectedTab) gtSample(win, tab, OV_SELFTEST?function(c){ (win.__gtSamples=win.__gtSamples||[]).push(c.join(",")); }:null);
        }catch(e){}
      });
      var obs={observe:function(){ if(gtOn()) gtShow(win,gb.selectedTab); else gtClear(win); }};
      Services.prefs.addObserver(GT_PREF,obs); win.__golemTintObs=obs;
      win.addEventListener("unload",function(){ try{ Services.prefs.removeObserver(GT_PREF,obs); }catch(e){} });
      if(gtOn()) gtShow(win,gb.selectedTab);
    }catch(e){ OVLOG("tint init:"+e); }
  }


  // ---- ATBC PLACEHOLDER → GOLEM COLOUR (2026-09-25). Where ATBC has no page colour it
  // paints its OWN built-ins: #1c1b22 (new tab / about:blank / protected pages; hard-coded)
  // and its fallback #2b2a33 (while a tab loads, before its page script reports) — the
  // "weird colour" Max saw flash on every load, and a new-tab bar that didn't match the
  // new-tab page. Watch ATBC's theme writes (inline on :root); when its frame colour is one
  // of those placeholders, apply the Golem colour instead through the tint sheet (full
  // derived theme, ATBC's exact maths); any real page colour → step aside. The observer
  // callback runs before the next paint, so the placeholder is never drawn. Cost: runs
  // only on theme writes, never while scrolling or idle.
  var GT_PLACEHOLDERS=["28,27,34","43,42,51","41,40,51","50,49,58"];   // #1c1b22 #2b2a33 #292833 #32313a
  function gtInlineAccent(win){
    try{ var v=win.document.documentElement.style.getPropertyValue("--lwt-accent-color"); var m=v&&v.match(/(\d+(?:\.\d+)?)/g); return m&&m.length>=3?[Math.round(+m[0]),Math.round(+m[1]),Math.round(+m[2])].join(","):""; }catch(e){ return ""; }
  }
  // ---- LOADING HOLD (Max, 2026-09-26): switching to a tab that still has to LOAD (restored
  // after launch / discarded → [pending], or busy and never shown) showed the Golem loading
  // colour in the content but kept the PREVIOUS tab's bar (red bar over a loading page):
  // ATBC has no colour until the new page reports, so it simply doesn't write. Such a tab
  // gets the Golem colour on the bar at the instant of the switch, held until ATBC reports
  // a real colour for it (any write that differs from what was showing), or 800ms after it
  // finishes loading (page turned out the same colour, so ATBC never wrote). Tabs that are
  // already loaded are NOT touched: their colours land fine and a flat bar in between was
  // explicitly not wanted.
  // Firefox drops [pending] BEFORE TabSelect fires (selecting a restored/discarded tab first
  // INSERTS its browser — proven headless: the attribute alone never matched). So the tab is
  // marked when its browser is inserted (TabBrowserInserted) and unmarked once a real page
  // has finished loading in it; a tab still marked at selection has never shown its page.
  // Background tabs opened normally are inserted, load and unmark long before you pick them.
  function gtNeedsLoad(win,tab){
    try{
      if(!tab) return false;
      if(tab.hasAttribute("pending") || tab.__gtFresh) return true;
      return tab.hasAttribute("busy") && !tab.__golemBar;
    }catch(e){ return false; }
  }
  function gtHoldStart(win,tab){
    try{
      if(gtOn() || !gtNeedsLoad(win,tab)) return false;
      win.__gtHold={tab:tab, from:gtInlineAccent(win)};
      gtApply(win,[29,32,38]); win.__gtPlaceholder="hold";
      return true;
    }catch(e){ return false; }
  }
  function gtHoldEnd(win){ win.__gtHold=null; win.__gtPlaceholder="hold"; gtPlaceholderSync(win); }   // hand the bar back to ATBC's current value
  function gtPlaceholderSync(win){
    try{
      if(gtOn()) return;   // the (dormant) tint engine owns the bar when enabled
      var H=win.__gtHold;
      if(H){
        if(H.tab!==win.gBrowser.selectedTab || H.tab.closing) win.__gtHold=null;
        else { var a0=gtInlineAccent(win);
          if(!a0 || a0===H.from || GT_PLACEHOLDERS.indexOf(a0)!==-1) return;   // still the old tab's / a placeholder → keep Golem
          win.__gtHold=null; }                                                  // the new page reported → its colour now
      }
      var a=gtInlineAccent(win);
      if(a && GT_PLACEHOLDERS.indexOf(a)!==-1){ gtApply(win,[29,32,38]); win.__gtPlaceholder=a; }
      else if(win.__gtPlaceholder!==undefined){ win.__gtPlaceholder=undefined; gtClear(win); }
    }catch(e){}
  }
  function gtPlaceholderWatch(win){
    if(win.__gtPhWatch) return; win.__gtPhWatch=true;
    try{
      gtSheet(win);
      new win.MutationObserver(function(){ gtPlaceholderSync(win); })
        .observe(win.document.documentElement,{attributes:true,attributeFilter:["style"]});
      gtPlaceholderSync(win);
      var gb=win.gBrowser, WPL=Components.interfaces.nsIWebProgressListener;
      gb.tabContainer.addEventListener("TabSelect",function(ev){
        if(win.__gtHold && win.__gtHold.tab!==ev.target) gtHoldEnd(win);
        gtHoldStart(win,ev.target);
      });
      gb.tabContainer.addEventListener("TabBrowserInserted",function(ev){ try{ ev.target.__gtFresh=true; }catch(e){} });
      gb.addTabsProgressListener({ onStateChange:function(br,wp,req,flags){
        try{ if(!(flags&WPL.STATE_STOP) || !(flags&WPL.STATE_IS_WINDOW) || !wp.isTopLevel) return;
             try{ if(br.currentURI && br.currentURI.spec!=="about:blank"){ var bt=gb.getTabForBrowser(br); if(bt) bt.__gtFresh=false; } }catch(e){}
             var H=win.__gtHold; if(!H || H.tab.linkedBrowser!==br) return;
             win.setTimeout(function(){ if(win.__gtHold===H) gtHoldEnd(win); },800); }catch(e){}
      }});
    }catch(e){ OVLOG("placeholder watch:"+e); }
  }

  // =================================================================
  // MEDIA REPORT (2026-09-26). Golem runs on varied hardware. Firefox tests each machine's
  // video driver itself at startup and turns hardware decoding on when it works; this only
  // RECORDS what it decided, per machine, so a machine silently decoding video on the CPU
  // (hot, battery-hungry, stuttery) is visible. Local file only (profile/golem-media.json),
  // nothing sent. Zero cost: one read ~1 min after startup, and one a few seconds after a
  // tab first starts playing sound (Firefox fills its codec report only once a video has
  // played). Stops once a report with codec data is written for this session.
  // =================================================================
  function mrCollect(){
    var r={at:new Date().toISOString(), firefox:Services.appinfo.version};
    try{
      var g=Components.classes["@mozilla.org/gfx/info;1"].getService(Components.interfaces.nsIGfxInfo);
      ["adapterVendorID","adapterDeviceID","adapterDriverVendor","adapterDriverVersion","adapterDescription","adapterVendorID2","adapterDeviceID2","isGPU2Active","windowProtocol"].forEach(function(k){ try{ var v=g[k]; if(v!==undefined && v!==null && v!=="") r[k]=v; }catch(e){} });
      var raw=""; try{ raw=g.CodecSupportInfo||""; }catch(e){}
      var codecs={};
      String(raw).split("\n").forEach(function(line){ var p=line.trim().split(" "); if(!p[0]) return;
        var c=codecs[p[0]]||(codecs[p[0]]={hw:false,sw:false}); if(p.indexOf("HWDEC")!==-1) c.hw=true; if(p.indexOf("SWDEC")!==-1) c.sw=true; });
      r.codecs=codecs; r.codecsKnown=Object.keys(codecs).length>0;
      var hw=Object.keys(codecs).filter(function(k){ return codecs[k].hw; });
      r.hardwareDecode=r.codecsKnown ? (hw.length ? hw.join(",") : "NONE (software only)") : "unknown until a video plays";
    }catch(e){ r.error=String(e); }
    ["media.ffmpeg.vaapi.enabled","media.hardware-video-decoding.enabled","media.hardware-video-decoding.force-enabled"].forEach(function(p){ try{ if(Services.prefs.getPrefType(p)) r[p]=Services.prefs.getBoolPref(p); }catch(e){} });
    try{ r.LIBVA_DRIVER_NAME=Services.env.get("LIBVA_DRIVER_NAME")||null; }catch(e){}
    if(nvOnly()){ r.nvidiaOnly={decode:nvMode, stamp:nvStamp(), crashesThisSession:nvState.crashes}; }
    return r;
  }
  // ---- NVIDIA HW DECODE + FALLBACK (2026-09-26, Max: "build the nvidia only... and a
  // fallback"). On an nvidia-ONLY machine Golem ships nvidia-vaapi-driver and sets
  // LIBVA_DRIVER_NAME=nvidia (system/Modular/gpu/nvidia/vaapi.nix). Firefox is conservative
  // with nvidia, so Beam asks it to use hardware decoding there (default branch, so a user
  // setting still wins). Two fallbacks:
  //  1. the driver fails to initialise -> Firefox itself decodes in software (built in);
  //  2. it initialises but the decoder process CRASHES while video plays -> after 2 such
  //     crashes in a session Beam turns it off for this machine (golem.beam.nvdec.failed =
  //     "<firefox>|<nvidia driver>"), so the next start decodes in software. It retries by
  //     itself once Firefox or the nvidia driver version changes. golem-media.json says which.
  // Sandbox untouched (Firefox 156 allows /dev/nvidia* in the media sandbox).
  var NV_FAIL="golem.beam.nvdec.failed", NV_FORCE="media.hardware-video-decoding.force-enabled";
  function nvOnly(){ try{ return Services.env.get("LIBVA_DRIVER_NAME")==="nvidia"; }catch(e){ return false; } }
  function nvDriver(){
    try{ var f=Components.classes["@mozilla.org/file/local;1"].createInstance(Components.interfaces.nsIFile); f.initWithPath("/proc/driver/nvidia/version");
      var m=/Kernel Module\s+(?:for\s+\S+\s+)?([0-9][0-9.]*)/.exec(ovReadText(f)); return m?m[1]:"?"; }catch(e){ return "?"; }
  }
  function nvStamp(){ return Services.appinfo.version+"|"+nvDriver(); }
  // decide: returns "hardware" or "software (fallback)"; clears a stale fallback after an update
  function nvDecide(stamp,failed){ if(failed && failed!==stamp) return {mode:"hardware", clear:true}; return failed ? {mode:"software (fallback)", clear:false} : {mode:"hardware", clear:false}; }
  var nvMode=null;
  (function nvInit(){
    try{
      if(!nvOnly()) return;
      var failed=""; try{ failed=Services.prefs.getStringPref(NV_FAIL,""); }catch(e){}
      var d=nvDecide(nvStamp(),failed); nvMode=d.mode;
      if(d.clear){ try{ Services.prefs.clearUserPref(NV_FAIL); }catch(e){} }
      if(d.mode==="hardware") Services.prefs.getDefaultBranch("").setBoolPref(NV_FORCE,true);
    }catch(e){}
  })();
  // crash watch: a decoder (RDD) pid that CHANGES between two checks while sound is playing =
  // it died mid-video (an idle shutdown can't happen mid-playback). Pure step for the test.
  function nvStep(st,pid,playing){
    if(!playing){ st.last=pid; return st; }
    if(st.last && pid && pid!==st.last) st.crashes++;
    st.last=pid; return st;
  }
  var nvState={last:0, crashes:0, tripped:false};
  function nvTrip(win){
    if(nvState.tripped) return; nvState.tripped=true;
    try{ Services.prefs.setStringPref(NV_FAIL,nvStamp()); Services.prefs.getDefaultBranch("").setBoolPref(NV_FORCE,false); }catch(e){}
    nvMode="software (fallback: the nvidia video decoder crashed "+nvState.crashes+"x; retried after the next Firefox or driver update)";
    try{ mrDone=false; mrWrite(); }catch(e){}
    try{ Components.classes["@mozilla.org/alerts-service;1"].getService(Components.interfaces.nsIAlertsService)
      .showAlertNotification(null,"Beam","Hardware video decoding was unstable on this machine, so videos now decode in software. Beam will try hardware again after the next update.",false,"",null,"golem-nvdec"); }catch(e){}
  }
  function nvWatch(win){
    if(!nvOnly() || nvMode!=="hardware" || win.__golemNvWatch) return;
    var tick=async function(){
      try{
        var playing=Array.prototype.some.call(win.gBrowser.tabs,function(t){ return t.soundPlaying; });
        var p=await ChromeUtils.requestProcInfo(), pid=0;
        (p.children||[]).forEach(function(c){ if(c.type==="rdd") pid=c.pid; });
        nvStep(nvState,pid,playing);
        if(nvState.crashes>=2) nvTrip(win);
        if(!playing || nvState.tripped){ win.clearInterval(win.__golemNvWatch); win.__golemNvWatch=null; }
      }catch(e){}
    };
    win.__golemNvWatch=win.setInterval(tick,5000); tick();
  }
  var mrDone=false;
  function mrWrite(){
    if(mrDone) return;
    try{
      var r=mrCollect();
      var f=Services.dirsvc.get("ProfD",Components.interfaces.nsIFile); f.append("golem-media.json");
      ovWriteText(f, JSON.stringify(r,null,1));
      if(r.codecsKnown) mrDone=true;
    }catch(e){}
  }
  function mrInit(win){
    if(win.__golemMrInit) return; win.__golemMrInit=true;
    try{
      win.setTimeout(mrWrite,60000);
      var onPlay=function(){ try{ nvWatch(win); }catch(e){} if(!mrDone) win.setTimeout(mrWrite,5000); };
      win.addEventListener("DOMAudioPlaybackStarted",onPlay,true);
    }catch(e){}
  }

  // =================================================================
  // WARM RESTORED TABS (2026-09-26, perf pass; Max: "build it"). Tabs from the last
  // session load only when you pick one — a heavy page then makes you wait. Once
  // startup has settled and the browser is idle, Beam quietly loads the N most recently
  // used restored tabs in the background, ONE at a time, most recent first, so switching
  // to them is instant (Chrome restores its tabs in the background too). The rest stay
  // unloaded (memory stays within budget). golem.beam.warmTabs = N (0 = off).
  // How: Firefox's own lazy-tab hook — reload() on an unloaded tab's browser creates it and
  // reloads once SessionStore reports SSTabRestoring, i.e. the same restore as selecting it
  // (Tabbrowser.sys.mjs lazy-browser "reload" getter). Checked by SSTabRestoring.
  // =================================================================
  var BW_PREF="golem.beam.warmTabs";
  function bwCount(){ try{ return Services.prefs.getIntPref(BW_PREF,5); }catch(e){ return 5; } }
  function bwPending(win){
    try{ return Array.prototype.filter.call(win.gBrowser.tabs,function(t){ return t.hasAttribute("pending") && !t.selected && !t.closing && !t.hidden; }); }catch(e){ return []; }
  }
  function bwWarmOne(win,tab,cb){
    var done=false, started=false;
    var fin=function(ok){ if(done) return; done=true; try{ tab.removeEventListener("SSTabRestoring",onStart); }catch(e){} cb(ok); };
    var onStart=function(){ started=true; };
    try{
      if(!tab.hasAttribute("pending") || tab.selected || tab.closing){ fin(false); return; }
      tab.addEventListener("SSTabRestoring",onStart);
      // Firefox's own lazy-tab hook: reload() on a not-yet-created browser inserts it and
      // reloads once SessionStore reports SSTabRestoring — i.e. the normal restore
      tab.linkedBrowser.reload();
      var tries=0;
      (function check(){
        if(done) return;
        if(started || !tab.hasAttribute("pending")){ bwAwaitLoad(win,tab,fin); return; }
        if(++tries>8){ fin(false); return; }   // ~4s and SessionStore never started it: give up on this one
        if(tries===4){ try{ tab.linkedBrowser.reload(); }catch(e){} }   // an inserted-but-unrestored browser: history reload = restore
        win.setTimeout(check,500);
      })();
    }catch(e){ OVLOG("warm:"+e); fin(false); }
  }
  function bwAwaitLoad(win,tab,fin){   // next tab only after this one finished (or 10s): one network burst at a time
    var t0=Date.now();
    (function wait(){
      try{ if(tab.closing || (!tab.hasAttribute("busy") && tab.linkedBrowser.currentURI && tab.linkedBrowser.currentURI.spec!=="about:blank") || Date.now()-t0>10000){ fin(true); return; } }catch(e){ fin(false); return; }
      win.setTimeout(wait,200);
    })();
  }
  function bwRun(win){
    if(win.__golemBwRan) return; win.__golemBwRan=true;
    try{
      var n=bwCount(); if(n<=0) return;
      if(win.gBrowser.selectedBrowser && win.gBrowser.selectedBrowser.contentPrincipal && win.gBrowser.selectedBrowser.contentPrincipal.privateBrowsingId) return;
      var list=bwPending(win).sort(function(a,b){ return (b.lastAccessed||0)-(a.lastAccessed||0); }).slice(0,n);
      if(!list.length) return;
      OVLOG("warm: loading "+list.length+" restored tab(s) in the background");
      var i=0, warmed=[];
      (function next(){
        if(i>=list.length || win.closed){ win.__golemBwDone=warmed; return; }
        var t=list[i++];
        // wait for the UI to be idle before each one, so it never competes with what you do
        try{ win.requestIdleCallback(function(){ bwWarmOne(win,t,function(ok){ if(ok) warmed.push(t); next(); }); },{timeout:4000}); }
        catch(e){ bwWarmOne(win,t,function(ok){ if(ok) warmed.push(t); next(); }); }
      })();
    }catch(e){ OVLOG("warm run:"+e); }
  }
  function bwInit(win){
    if(win.__golemBwInit) return; win.__golemBwInit=true;
    // after the session is back and the startup work (overview, restored active tab) settled
    var go=function(){ win.setTimeout(function(){ bwRun(win); },4000); };
    try{
      var ss=win.SessionStore;
      if(ss && ss.promiseAllWindowsRestored) ss.promiseAllWindowsRestored.then(go,go); else go();
    }catch(e){ go(); }
  }

  // =================================================================
  // SAFETY NET — Beam now takes every Firefox release automatically
  // (~/Golem/beam), and Firefox changes its chrome DOM without notice.
  // Rules: (1) the overview may FAIL, but it may never leave the browser
  // broken — any fault restores content, nav chrome and the bar; (2) if
  // the hooks it needs are gone, it switches itself off for this session
  // and the browser is plain, working Firefox (native vertical tabs; the
  // horizontal strip if even those are gone); (3) zero cost when healthy —
  // one check after startup, no polling; (4) local only — a status file in
  // the profile + one desktop notice per Firefox version, nothing sent.
  // =================================================================
  var OV_SELFTEST = "", OV_BREAK = "";
  try{ OV_SELFTEST = Services.env.get("BEAM_SELFTEST"); OV_BREAK = Services.env.get("BEAM_SELFTEST_BREAK"); }catch(e){}

  // Undo EVERYTHING the overview can have changed. Idempotent, each step
  // independent, so one broken hook can't stop the others from restoring.
  function ovRestore(win){
    var d=win.document, r=d.documentElement;
    try{ r.removeAttribute("golem-ov"); r.removeAttribute("golem-ov-pin"); }catch(e){}
    try{ r.style.removeProperty("--golem-pin-f"); r.style.removeProperty("--golem-pin-a"); }catch(e){}
    try{ var ov=d.getElementById("golem-overview"); if(ov) ov.style.display="none"; }catch(e){}
    try{ ovShowTools(win,false); }catch(e){}
    try{ var tp=d.getElementById("tabbrowser-tabpanels"); if(tp) tp.style.visibility=""; }catch(e){}
    try{ win.gBrowser.selectedBrowser.docShellIsActive=true; }catch(e){}
    try{ ovTeardown(win); }catch(e){}
  }

  function ovHealthFile(obj){
    try{ var f=Services.dirsvc.get("ProfD",Components.interfaces.nsIFile); f.append("golem-health.json"); ovWriteText(f, JSON.stringify(obj)); }catch(e){}
  }

  // Switch the overview off for this session and leave plain Firefox.
  function ovDisable(win,reason){
    if(win.__golemOvDisabled) return; win.__golemOvDisabled=reason||"fault";
    ovRestore(win);
    try{ var b=win.document.getElementById("golem-overview-btn"); if(b) b.remove(); }catch(e){}
    try{ if(win.__golemOvTools) win.__golemOvTools.remove(); }catch(e){}
    // native vertical tabs gone too → bring Firefox's horizontal tab strip back
    // (session only: user.js re-asserts vertical tabs at the next start)
    try{ if(!win.document.querySelector("sidebar-main")) Services.prefs.setBoolPref("sidebar.verticalTabs", false); }catch(e){}
    var ver=""; try{ ver=Services.appinfo.version; }catch(e){}
    OVLOG("SAFETY: overview disabled ("+reason+") on Firefox "+ver);
    ovHealthFile({firefox:ver, ok:false, disabled:reason, at:new Date().toISOString()});
    if(OV_SELFTEST) return;
    try{
      var P="golem.beam.degradedNotified";
      if(Services.prefs.getStringPref(P,"")!==ver){
        Services.prefs.setStringPref(P,ver);
        Components.classes["@mozilla.org/alerts-service;1"].getService(Components.interfaces.nsIAlertsService)
          .showAlertNotification(null,"Beam: tab overview paused",
            "Firefox "+ver+" changed something the overview relies on. Browsing is unaffected; the overview returns after the next Beam update.",false,"",null,"golem-beam-degraded");
      }
    }catch(e){}
  }
  function ovFault(win,where,e){ OVLOG("SAFETY fault in "+where+": "+e); ovDisable(win, where+": "+e); }

  // Guarded entry points — every call site (button, hover, Alt, keys, cards,
  // startup) goes through these, so no throw can leave content hidden.
  function ovOpen(win){
    if(win.__golemOvDisabled) return;
    try{ if(OV_BREAK==="throw-open") throw new Error("injected"); ovOpenImpl(win); }
    catch(e){ ovFault(win,"open",e); }
  }
  function ovClose(win, switching, pred){
    try{ ovCloseImpl(win, switching, pred); }
    catch(e){ ovRestore(win); ovFault(win,"close",e); }
  }
  function ovSwitchTo(win,tab){
    try{ ovSwitchToImpl(win,tab); }
    catch(e){ ovRestore(win); ovFault(win,"switch",e); }
  }

  // One check after startup: are the hooks the overview needs still there?
  function ovHealth(win){
    var d=win.document, miss=[];
    var need={"browser":1,"tabbrowser-tabpanels":1,"nav-bar":1,"nav-bar-customization-target":1,"golem-overview-btn":1};
    Object.keys(need).forEach(function(id){ if(!d.getElementById(id) || OV_BREAK===id) miss.push(id); });
    try{ if(!win.gBrowser || !win.gBrowser.selectedBrowser) miss.push("gBrowser"); }catch(e){ miss.push("gBrowser"); }
    ovInjectFieldStyle(win);   // load it NOW — it otherwise loads on first open, so a 1-tab start read as "missing"
    if(!win.__golemOvSheetOK || OV_BREAK==="agent-sheet") miss.push("agent-sheet");
    var soft=[];   // cosmetic only: reported, never disabling
    if(!d.querySelector("sidebar-main") || OV_BREAK==="sidebar-main") soft.push("sidebar-main");
    if(!d.getElementById("urlbar")) soft.push("urlbar");
    return {critical:miss, soft:soft};
  }
  function ovHealthCheck(win){
    try{
      var h=ovHealth(win), ver=""; try{ ver=Services.appinfo.version; }catch(e){}
      if(h.critical.length) { ovDisable(win, "missing "+h.critical.join(",")); return h; }
      if(h.soft.indexOf("sidebar-main")!==-1){ try{ Services.prefs.setBoolPref("sidebar.verticalTabs", false); }catch(e){} }
      ovHealthFile({firefox:ver, ok:true, soft:h.soft, at:new Date().toISOString()});
      // a stuck half-open state can't survive startup either
      win.setTimeout(function(){ try{ if(win.document.documentElement.hasAttribute("golem-ov") && !ovIsOpen(win)){ ovRestore(win); OVLOG("SAFETY: cleared stuck overview state"); } }catch(e){} }, 3000);
      return h;
    }catch(e){ ovFault(win,"health",e); return null; }
  }


  // Tint self-test: real pages with known top colours → the engine's real sample →
  // maths → sheet path; assert Firefox's COMPUTED theme vars equal the oracle-verified
  // values; then switch the pref off and assert the tint clears.
  function gtSelfTest(win,r,step,done){
    try{
      var gb=win.gBrowser, root=win.document.documentElement;
      var cs=function(v){ return (win.getComputedStyle(root).getPropertyValue(v)||"").trim(); };
      var sel=function(t){ try{ gb.selectedTab=t; }catch(e){} if(gb.selectedTab!==t){ var i=Array.prototype.indexOf.call(gb.tabs,t); if(i>=0) gb.tabContainer.selectedIndex=i; } };
      Services.prefs.setBoolPref(GT_PREF,true);
      var cases=[[192,43,59],[250,250,250],[20,20,24]], k=0; r.tint=[];
      var scrollCase=function(){
        var url="data:text/html,"+encodeURIComponent("<body style='margin:0'><div id='top' style='height:600px;background:rgb(192,43,59)'></div><div style='height:4000px;background:rgb(250,250,250)'></div><div id='b'></div></body>");
        var t=gb.addTrustedTab(url);
        win.setTimeout(function(){ sel(t); },200);
        win.setTimeout(function(){
          var top=cs("--lwt-accent-color");
          try{ t.linkedBrowser.loadURI(Services.io.newURI(url+"#b"),{triggeringPrincipal:Services.scriptSecurityManager.getSystemPrincipal()}); }catch(e){ r.scrollErr=String(e); }
          win.setTimeout(function(){
            var after=cs("--lwt-accent-color");
            r.scroll={top:top, afterScroll:after, scheme:root.getAttribute("golem-tint"), pings:win.__gtPings||null, samples:win.__gtSamples||null};
            step("tint-scroll-top-red", top===gtTheme([192,43,59]).vars["--lwt-accent-color"]);
            step("tint-scroll-follows", after===gtTheme([250,250,250]).vars["--lwt-accent-color"]);
            // back to the top → red again
            try{ t.linkedBrowser.loadURI(Services.io.newURI(url+"#top"),{triggeringPrincipal:Services.scriptSecurityManager.getSystemPrincipal()}); }catch(e){}
            win.setTimeout(function(){
              step("tint-scroll-back-up", cs("--lwt-accent-color")===gtTheme([192,43,59]).vars["--lwt-accent-color"]);
              // fixed header: stays under the bar while the page scrolls → keep the header colour
              var u2="data:text/html,"+encodeURIComponent("<body style='margin:0'><div style='position:fixed;top:0;left:0;right:0;height:60px;background:rgb(40,90,160)'></div><div style='height:5000px;background:rgb(250,250,250)'></div><div id='b'></div></body>");
              var t2=gb.addTrustedTab(u2);
              win.setTimeout(function(){ sel(t2); },200);
              win.setTimeout(function(){
                try{ t2.linkedBrowser.loadURI(Services.io.newURI(u2+"#b"),{triggeringPrincipal:Services.scriptSecurityManager.getSystemPrincipal()}); }catch(e){}
                win.setTimeout(function(){
                  r.scrollFixed=cs("--lwt-accent-color");
                  step("tint-fixed-header", r.scrollFixed===gtTheme([40,90,160]).vars["--lwt-accent-color"]);
                  finish();
                },1500);
              },2200);
            },1500);
          },1500);
        },2200);
      };
      var finish=function(){ next(); };
      var next=function(){
        if(k===cases.length){ k++; scrollCase(); return; }
        if(k>cases.length){
          Services.prefs.setBoolPref(GT_PREF,false);
          win.setTimeout(function(){ step("tint-off-clears", !root.hasAttribute("golem-tint")); done(); },150);
          return;
        }
        var c=cases[k++];
        var t=gb.addTrustedTab("data:text/html,"+encodeURIComponent("<body style='margin:0;background:rgb("+c.join(",")+")'></body>"));
        win.setTimeout(function(){ sel(t); },200);
        win.setTimeout(function(){
          var exp=gtTheme(c), keys=["--lwt-accent-color","--toolbar-field-background-color","--sidebar-background-color","--toolbar-text-color"];
          var got={}, ok=root.getAttribute("golem-tint")===exp.scheme;
          keys.forEach(function(v){ got[v]=cs(v); if(got[v]!==exp.vars[v]) ok=false; });
          var rgb="rgb("+c.join(", ")+")";
          (function(){ var ob=win.document.getElementById("golem-overview-btn"); var col=ob?win.getComputedStyle(ob).color:"(none)"; got["icon:golem-overview-btn"]=col; if(col!==(exp.scheme==="light"?"rgb(0, 0, 0)":"rgb(255, 255, 255)")) ok=false; })();
          got["sidebar=bar"]=(cs("--sidebar-background-color")===cs("--lwt-accent-color")); if(!got["sidebar=bar"]) ok=false;
          ["navigator-toolbox","nav-bar"].forEach(function(id){ var el=win.document.getElementById(id); var bg=el?win.getComputedStyle(el).backgroundColor:"(none)"; got["paint:"+id]=bg; if(bg!==rgb) ok=false; });
          r.tint.push({page:c, scheme:root.getAttribute("golem-tint"), sampled:t.__gtPage||null, got:got});
          step("tint-"+c.join("-"), ok); next();
        },2200);
      };
      next();
    }catch(e){ step("tint-threw:"+e,false); done(); }
  }




  // ---- PAINT NUDGE (2026-09-25). Max: switching with the sidebar / Alt+N sometimes shows the
  // tab's page area as the empty new-tab colour, no content. It never happened while the tint
  // took a snapshot ~150ms after every switch — a drawSnapshot forces the content to paint,
  // which un-sticks a tab that was selected but never presented. Keep exactly that effect,
  // without the colour logic: one 1x1 snapshot per switch, discarded. Negligible cost.
  function ovPaintNudge(win,tab){
    try{
      if(!tab || tab!==win.gBrowser.selectedTab || ovIsOpen(win)) return;
      var b=tab.linkedBrowser, wg=b && b.browsingContext && b.browsingContext.currentWindowGlobal; if(!wg) return;
      win.__golemNudges=(win.__golemNudges||0)+1;
      wg.drawSnapshot(new win.DOMRect(0,0,1,1),1,"rgb(255,255,255)").then(function(bm){ try{ bm.close(); }catch(e){} },function(){});
    }catch(e){}
  }

  // ---- BLANK-TAB WATCHDOG (2026-09-25). A second blank-tab cause surfaced once the tint
  // was switched off (its post-switch snapshot had been forcing a paint and masking it).
  // 700ms after every tab switch / overview close: if the selected tab is not rendering
  // while the grid is closed, heal it and RECORD the exact state locally so the cause is
  // diagnosed from data (profile/golem-blank.log). One cheap check per switch; no polling.
  function ovBlankLog(line){
    try{
      var f=Services.dirsvc.get("ProfD",Components.interfaces.nsIFile); f.append("golem-blank.log");
      if(f.exists() && f.fileSize>65536) f.remove(false);
      var os=Components.classes["@mozilla.org/network/file-output-stream;1"].createInstance(Components.interfaces.nsIFileOutputStream);
      os.init(f,0x02|0x08|0x10,0o600,0); var t=new Date().toISOString()+" "+line+"\n"; os.write(t,t.length); os.close();
    }catch(e){}
  }
  function ovBlankCheck(win,via){
    try{
      if(ovIsOpen(win)) return;
      var d=win.document, root=d.documentElement, b=win.gBrowser.selectedBrowser, tp=d.getElementById("tabbrowser-tabpanels");
      var st={via:via, active:b.docShellIsActive, layers:(typeof b.hasLayers==="boolean"?b.hasLayers:"?"), render:(typeof b.renderLayers==="boolean"?b.renderLayers:"?"),
              panel:(tp?tp.style.visibility:"?"), ovAttr:root.hasAttribute("golem-ov"), pin:root.hasAttribute("golem-ov-pin"),
              url:(function(){ try{ return b.currentURI.scheme; }catch(e){ return "?"; } })(), busy:win.gBrowser.selectedTab.hasAttribute("busy")};
      var bad = st.active===false || st.panel==="hidden" || st.panel==="collapse" || st.ovAttr || st.layers===false;
      if(!bad) return;
      if(st.panel) try{ tp.style.visibility=""; }catch(e){}
      try{ root.removeAttribute("golem-ov"); }catch(e){}
      try{ if(!b.docShellIsActive) b.docShellIsActive=true; else if(st.layers===false){ b.docShellIsActive=false; b.docShellIsActive=true; } }catch(e){}
      try{ b.renderLayers=true; }catch(e){}
      win.__golemBlankHeals=(win.__golemBlankHeals||0)+1;
      ovBlankLog("HEAL "+JSON.stringify(st));
      OVLOG("SAFETY: healed a non-rendering tab "+JSON.stringify(st));
    }catch(e){}
  }


  // Watchdog self-test: (1) no false positives across all the switching above; (2) a tab
  // deliberately left non-rendering after a switch is healed.
  function ovBlankTest(win,r,step,done){
    try{
      var gb=win.gBrowser;
      r.healsBeforeInject=win.__golemBlankHeals||0;
      step("watchdog-no-false-positives", r.healsBeforeInject===0); r.nudges=win.__golemNudges||0; step("paint-nudge-runs", r.nudges>0);
      var t=gb.addTrustedTab("about:blank");
      win.setTimeout(function(){
        try{ gb.selectedTab=t; }catch(e){} if(gb.selectedTab!==t){ var i=Array.prototype.indexOf.call(gb.tabs,t); if(i>=0) gb.tabContainer.selectedIndex=i; }
        // inject a stuck state Firefox does NOT self-correct (a docShell turned off is re-enabled by
        // its own tab switcher within ~100ms — verified — so that is not a faithful blank): our panel hidden
        var tp=win.document.getElementById("tabbrowser-tabpanels");
        win.setTimeout(function(){ try{ tp.style.visibility="hidden"; }catch(e){} },300);
        win.setTimeout(function(){
          step("watchdog-heals-blank", tp.style.visibility==="" && (win.__golemBlankHeals||0)===r.healsBeforeInject+1);
          done();
        },1300);
      },300);
    }catch(e){ step("watchdog-threw:"+e,false); done(); }
  }


  // Placeholder self-test: write what ATBC writes (inline theme var on :root) and assert
  // the bar shows the Golem colour for its placeholders, and steps aside for a real page.
  function gtPlaceholderTest(win,r,step,done){
    try{
      var root=win.document.documentElement, cs=function(v){ return (win.getComputedStyle(root).getPropertyValue(v)||"").trim(); };
      var golem=gtTheme([29,32,38]).vars;
      var nb=win.document.getElementById("nav-bar");
      // .browserContainer is what paints the content area before a page does
      var bc=win.gBrowser.selectedBrowser.closest(".browserContainer");
      r.loadingBg={var:cs("--tabpanel-background-color"), browserContainer:bc&&win.getComputedStyle(bc).backgroundColor};
      step("loading-content-golem", r.loadingBg.browserContainer==="rgb(29, 32, 38)");
      root.style.setProperty("--lwt-accent-color","rgb(43, 42, 51)");      // ATBC fallback (loading)
      win.setTimeout(function(){
        r.ph={fallback:{accent:cs("--lwt-accent-color"), field:cs("--toolbar-field-background-color"), bar:nb&&win.getComputedStyle(nb).backgroundColor}};
        step("placeholder-fallback→golem", r.ph.fallback.accent===golem["--lwt-accent-color"] && r.ph.fallback.field===golem["--toolbar-field-background-color"]);
        root.style.setProperty("--lwt-accent-color","rgb(28, 27, 34)");    // ATBC new tab / about:blank
        win.setTimeout(function(){
          r.ph.newtab=cs("--lwt-accent-color");
          step("placeholder-newtab→golem", r.ph.newtab===golem["--lwt-accent-color"]);
          root.style.setProperty("--lwt-accent-color","rgb(192, 43, 59)");  // a real page colour
          win.setTimeout(function(){
            r.ph.real=cs("--lwt-accent-color"); r.ph.attr=root.getAttribute("golem-tint");
            step("placeholder-real-page-untouched", r.ph.attr===null && r.ph.real==="rgb(192, 43, 59)");
            root.style.removeProperty("--lwt-accent-color"); done();
          },150);
        },150);
      },150);
    }catch(e){ step("placeholder-threw:"+e,false); done(); }
  }

  // Loading-hold self-test (needs BEAM_SELFTEST_HTTP): Max's case — on a RED tab, switch to a
  // tab that must load (discarded → [pending]). The bar must be the Golem colour at once, stay
  // so while the old red is all ATBC has, follow the page when it reports, and a switch to an
  // already-loaded tab must NOT get the Golem colour in between.
  function gtHoldTest(win,r,step,done){
    var base=""; try{ base=Services.env.get("BEAM_SELFTEST_HTTP"); }catch(e){}
    if(!base || gtOn()){ step("hold-skipped",true); done(); return; }
    try{
      var gb=win.gBrowser, root=win.document.documentElement, golem=gtTheme([29,32,38]).vars;
      var cs=function(v){ return (win.getComputedStyle(root).getPropertyValue(v)||"").trim(); };
      var home=gb.selectedTab, red="rgb(192, 43, 59)";
      var sel=function(t){ try{ gb.selectedTab=t; }catch(e){} if(gb.selectedTab!==t){ try{ gb.tabContainer.selectedIndex=Array.prototype.indexOf.call(gb.tabs,t); }catch(e){} } };
      var tl=gb.addTrustedTab(base+"/p1.html",{inBackground:true}), tp=gb.addTrustedTab(base+"/p2.html",{inBackground:true});
      var w0=Date.now(), ok=function(t){ try{ return !t.hasAttribute("busy") && t.linkedBrowser.browsingContext.currentWindowGlobal && /^http/.test(t.linkedBrowser.currentURI.spec); }catch(e){ return false; } };
      var fin=function(){ sel(home); try{ gb.removeTab(tl); gb.removeTab(tp); }catch(e){} root.style.removeProperty("--lwt-accent-color"); done(); };
      (function wait(){
        if(!(ok(tl)&&ok(tp)) && Date.now()-w0<10000){ win.setTimeout(wait,100); return; }
        try{ gb.discardBrowser(tp); }catch(e){}
        r.hold={pending:tp.hasAttribute("pending")};
        root.style.setProperty("--lwt-accent-color",red);          // we are on a RED page
        win.setTimeout(function(){
          sel(tp);                                                    // → a tab that must load
          r.hold.atSwitch={tint:root.getAttribute("golem-tint"), accent:cs("--lwt-accent-color")};
          step("hold-golem-at-switch", r.hold.pending && gb.selectedTab===tp && r.hold.atSwitch.accent===golem["--lwt-accent-color"]);
          root.style.setProperty("--lwt-accent-color",red);        // ATBC re-writes the old colour
          win.setTimeout(function(){
            r.hold.whileOld=cs("--lwt-accent-color");
            // never the OLD tab's red: Golem while loading, or the new page's own colour once it
            // has reported (a fast local page reports within this window — that is correct)
            step("hold-never-old-colour", r.hold.whileOld!==red && r.hold.whileOld!=="");
            step("hold-no-stale-remember", !tp.__golemBar || tp.__golemBar.a!==red);
            root.style.setProperty("--lwt-accent-color","rgb(10, 120, 200)");   // the new page reports
            win.setTimeout(function(){
              r.hold.reported={accent:cs("--lwt-accent-color"), tint:root.getAttribute("golem-tint")};
              step("hold-follows-page", r.hold.reported.accent==="rgb(10, 120, 200)" && r.hold.reported.tint===null);
              root.style.setProperty("--lwt-accent-color",red);
              win.setTimeout(function(){
                sel(tl);                                              // → an already-LOADED tab
                r.hold.loaded={tint:root.getAttribute("golem-tint"), accent:cs("--lwt-accent-color"), held:!!win.__gtHold};
                step("hold-not-on-loaded-tab", !r.hold.loaded.held && r.hold.loaded.tint===null);
                fin();
              },100);
            },100);
          },150);
        },100);
      })();
    }catch(e){ step("hold-threw:"+e,false); done(); }
  }

  // NVIDIA decode self-test (no nvidia here, so the pure logic): the decision + the crash watch.
  function nvTest(win,r,step,done){
    try{
      var a=nvDecide("156|580.1",""), b=nvDecide("156|580.1","156|580.1"), c=nvDecide("157|580.1","156|580.1");
      step("nv-default-hardware", a.mode==="hardware" && !a.clear);
      step("nv-fallback-sticks", b.mode==="software (fallback)" && !b.clear);
      step("nv-retry-after-update", c.mode==="hardware" && c.clear);
      var st={last:0,crashes:0};
      [[100,false],[100,true],[100,true],[0,false],[200,false],[200,true]].forEach(function(x){ nvStep(st,x[0],x[1]); });
      step("nv-idle-restart-not-a-crash", st.crashes===0);
      [[300,true],[300,true],[400,true]].forEach(function(x){ nvStep(st,x[0],x[1]); });
      step("nv-crash-mid-video-counted", st.crashes===2);
      step("nv-not-nvidia-machine-untouched", nvOnly() || nvMode===null);
      if(nvOnly()){ r.nv={mode:nvMode, force:Services.prefs.getBoolPref(NV_FORCE,false), report:mrCollect().nvidiaOnly||null};
        step("nv-nvidia-machine-forces-hw", nvMode==="hardware" && r.nv.force===true && !!r.nv.report);
        // trip the fallback for real, then check what the NEXT start would decide; clean up after
        nvState.crashes=2; nvTrip(win);
        var fl=Services.prefs.getStringPref(NV_FAIL,""), next=nvDecide(nvStamp(),fl);
        r.nvTrip={failed:fl, forceNow:Services.prefs.getBoolPref(NV_FORCE,false), next:next.mode, report:(mrCollect().nvidiaOnly||{}).decode};
        step("nv-trip-marks-machine", fl===nvStamp() && r.nvTrip.forceNow===false && /fallback/.test(r.nvTrip.report||""));
        step("nv-trip-next-start-software", next.mode==="software (fallback)");
        try{ Services.prefs.clearUserPref(NV_FAIL); }catch(e){} }
    }catch(e){ step("nv-threw:"+e,false); }
    done();
  }

  // Media-report self-test: collecting works on this build (the gfxInfo fields exist).
  function mrTest(win,r,step,done){
    try{ var m=mrCollect(); r.media={keys:Object.keys(m).length, hw:m.hardwareDecode, err:m.error||null};
      step("media-report-collects", !m.error && typeof m.codecs==="object" && !!m.hardwareDecode); }
    catch(e){ step("media-threw:"+e,false); }
    done();
  }

  // Warm-restored-tabs self-test (needs BEAM_SELFTEST_HTTP): 4 background tabs, unloaded
  // (discarded = the same lazy state a restored tab has); the 2 most recently used must load
  // in the background, the other 2 stay unloaded, and the tab you are on does not change.
  function bwTest(win,r,step,done){
    var base=""; try{ base=Services.env.get("BEAM_SELFTEST_HTTP"); }catch(e){}
    if(!base){ step("warm-skipped",true); done(); return; }
    try{
      var gb=win.gBrowser, home=gb.selectedTab, tabs=[], had=Services.prefs.prefHasUserValue(BW_PREF);
      for(var k=0;k<4;k++) tabs.push(gb.addTrustedTab(base+"/p"+k+".html",{inBackground:true}));
      var ok=function(t){ try{ return !t.hasAttribute("busy") && t.linkedBrowser.browsingContext.currentWindowGlobal && /^http/.test(t.linkedBrowser.currentURI.spec); }catch(e){ return false; } };
      var fin=function(){ try{ if(!had) Services.prefs.clearUserPref(BW_PREF); }catch(e){} tabs.forEach(function(t){ try{ gb.removeTab(t); }catch(e){} }); done(); };
      var w0=Date.now();
      (function wait(){
        if(!tabs.every(ok) && Date.now()-w0<10000){ win.setTimeout(wait,100); return; }
        tabs.forEach(function(t){ try{ gb.discardBrowser(t); }catch(e){} });
        var now=Date.now(); tabs.forEach(function(t,ix){ try{ t.updateLastAccessed(now-100000+ix*1000); }catch(e){} });   // tabs[3] most recent, then tabs[2]
        r.warm={pendingBefore:tabs.map(function(t){ return t.hasAttribute("pending"); })};
        Services.prefs.setIntPref(BW_PREF,2);
        win.__golemBwRan=false; win.__golemBwDone=null; bwRun(win);
        var t1=Date.now();
        (function poll(){
          if(!win.__golemBwDone && Date.now()-t1<15000){ win.setTimeout(poll,200); return; }
          r.warm.after=tabs.map(function(t){ return {pending:t.hasAttribute("pending"), url:String(t.linkedBrowser.currentURI&&t.linkedBrowser.currentURI.spec).slice(-8), loaded:ok(t)}; });
          r.warm.warmed=(win.__golemBwDone||[]).length;
          step("warm-all-were-unloaded", r.warm.pendingBefore.every(Boolean));
          step("warm-loads-most-recent", r.warm.after[3].loaded && r.warm.after[2].loaded && r.warm.warmed===2);
          step("warm-leaves-the-rest", r.warm.after[0].pending && r.warm.after[1].pending);
          step("warm-keeps-your-tab", gb.selectedTab===home);
          fin();
        })();
      })();
    }catch(e){ step("warm-threw:"+e,false); done(); }
  }

  // Race self-test (needs BEAM_SELFTEST_HTTP): pick a tab from the overview at the exact
  // moment the background-capture pass has it activated for a snapshot, then assert the
  // tab you picked is actually rendering (the "random blank tabs" failure).
  function ovRaceTest(win,r,step,done){
    var base=""; try{ base=Services.env.get("BEAM_SELFTEST_HTTP"); }catch(e){}
    if(!base){ step("race-skipped",true); done(); return; }
    try{
      var gb=win.gBrowser, tabs=[];
      for(var k=0;k<4;k++) tabs.push(gb.addTrustedTab(base+"/p"+k+".html",{inBackground:true}));
      var w0=Date.now();
      var loaded=function(){ return tabs.every(function(t){ try{ var b=t.linkedBrowser; return !t.hasAttribute("busy") && b.browsingContext && b.browsingContext.currentWindowGlobal && /^http/.test(b.currentURI.spec); }catch(e){ return false; } }); };
      var go=function(){
        if(!loaded() && Date.now()-w0<10000){ win.setTimeout(go,100); return; }
        r.raceLoadMs=Date.now()-w0;
        var fired=false;
        win.__ovCapHook=function(t){
          if(fired || tabs.indexOf(t)<0) return; fired=true; win.__ovCapHook=null;
          r.race={victimIndex:Array.prototype.indexOf.call(gb.tabs,t)};
          ovSwitchTo(win,t);   // pick it while its snapshot is in flight
          win.setTimeout(function(){
            step("race-selected", gb.selectedTab===t);
            step("race-picked-tab-rendering", gb.selectedBrowser.docShellIsActive===true);
            done();
          },900);
        };
        ovOpen(win);
        win.setTimeout(function(){ if(!fired){ win.__ovCapHook=null; step("race-capture-observed",false); try{ ovClose(win); }catch(e){} done(); } },4000);
      };
      win.setTimeout(go,300);
    }catch(e){ step("race-threw:"+e,false); done(); }
  }

  // Headless self-test (BEAM_SELFTEST=<result file>): health, then drive the
  // real open → close → switch path and assert the browser is left sane.
  function ovSelfTest(win){
    var r={firefox:"", steps:[], ok:true};
    r.btnEarlyMs=(win.__golemBtnAt&&win.__golemStartAt)?(win.__golemBtnAt-win.__golemStartAt):null;
    try{ r.firefox=Services.appinfo.version; }catch(e){}
    var d=win.document, root=d.documentElement, gb=win.gBrowser;
    var sane=function(){ var tp=d.getElementById("tabbrowser-tabpanels"); return !root.hasAttribute("golem-ov") && !ovIsOpen(win) && (!tp || tp.style.visibility==="") && gb.selectedBrowser.docShellIsActive; };
    var step=function(name,cond){ r.steps.push(name+"="+(cond?"ok":"FAIL")); if(!cond) r.ok=false; };
    var done=function(){ r.disabled=win.__golemOvDisabled||null; try{ ovWriteText((function(){ var f=Components.classes["@mozilla.org/file/local;1"].createInstance(Components.interfaces.nsIFile); f.initWithPath(OV_SELFTEST); return f; })(), JSON.stringify(r)); }catch(e){} try{ Services.startup.quit(Components.interfaces.nsIAppStartup.eForceQuit); }catch(e){} };
    try{
      var h=ovHealthCheck(win); r.health=h;
      if(win.__golemOvDisabled){ step("degraded-cleanly", sane() && !d.getElementById("golem-overview-btn")); done(); return; }
      root.style.setProperty("--toolbarbutton-icon-fill","#000000");   // simulate a bright page (ATBC → black icons)
      ovOpen(win);
      if(win.__golemOvDisabled){ step("open-fault-recovered", sane()); done(); return; }
      step("open", ovIsOpen(win) && root.hasAttribute("golem-ov"));
      step("buttons-at-startup", r.btnEarlyMs!==null && r.btnEarlyMs<50 && !!d.getElementById("golem-overview-btn") && !!(win.__golemOvTools&&win.__golemOvTools.parentNode) && win.__golemOvTools.style.display==="flex");
      // #nav-bar has a 0.1s background-color transition: read the flat bar AFTER it settles
      win.setTimeout(function(){ try{
      (function(){ var nb=d.getElementById("nav-bar"); var bg=nb?win.getComputedStyle(nb).backgroundColor:""; r.openBarBg=bg; step("open-bar-flat", bg==="rgb(29, 32, 38)"); })();
      (function(){ var ob=d.getElementById("golem-overview-btn"), tb=win.__golemOvTools&&win.__golemOvTools.firstChild;
        r.ovIcons={btn:ob&&win.getComputedStyle(ob).color, tool:tb&&win.getComputedStyle(tb).color};
        step("overview-icons-white", r.ovIcons.btn==="rgb(255, 255, 255)" && r.ovIcons.tool==="rgb(255, 255, 255)"); })();
      ovClose(win);
      step("close-sane", sane());
      (function(){ var ob=d.getElementById("golem-overview-btn"); r.iconAfterClose=ob&&win.getComputedStyle(ob).color;
        step("icons-follow-page-after-close", r.iconAfterClose==="rgb(0, 0, 0)"); root.style.removeProperty("--toolbarbutton-icon-fill"); })();
      var t2=gb.addTrustedTab("about:blank");
      win.setTimeout(function(){
        try{
          ovOpen(win); ovSwitchTo(win,t2);
          win.setTimeout(function(){
            step("switch-selected", gb.selectedTab===t2); step("switch-sane", sane() && !root.hasAttribute("golem-ov-pin")); gtSelfTest(win,r,step,function(){ ovRaceTest(win,r,step,function(){ ovBlankTest(win,r,step,function(){ gtPlaceholderTest(win,r,step,function(){ gtHoldTest(win,r,step,function(){ bwTest(win,r,step,function(){ mrTest(win,r,step,function(){ nvTest(win,r,step,done); }); }); }); }); }); }); }); }, 700);
        }catch(e){ step("switch-threw:"+e,false); done(); }
      }, 300);
      }catch(e){ step("open-phase-threw:"+e,false); done(); } }, 400);
    }catch(e){ step("threw:"+e,false); done(); }
  }

  Services.obs.addObserver({observe:function(w){
    // Start ON the overview at launch (first window, >1 tab). Two forces fight us:
    // session-restore may not have added the tabs yet at delayed-startup, and
    // Firefox's own startup RE-ACTIVATES the selected tab a moment after we open
    // (its content subsurface then paints OVER our grid → you'd see the tab, not
    // the overview). So: open as soon as the restored tab strip is present, then
    // RE-ASSERT the content-hide for ~2s so the grid stays on top; stop if the
    // user dismisses it. First tick is synchronous (earliest possible).
    // The grid button + tool row exist BEFORE the overview opens (Max: they took ~1s to
    // appear at launch — they used to be created only in the +1100ms step below, so the
    // row had nowhere to attach). The later step now just re-seats them if CustomizableUI
    // reflowed the toolbar.
    w.__golemStartAt=Date.now();
    try{ ovButton(w); w.__golemBtnAt=Date.now(); }catch(e){ OVLOG("button-early:"+e); }
    try{ gtPlaceholderWatch(w); }catch(e){ OVLOG("placeholder-early:"+e); }   // from the first tick: no placeholder at launch either
    try{ if(!ovStartupDone){ ovStartupDone=true;
      var _st=0, _opened=false;
      (function ovStartupStep(){
        try{
          if(_opened){
            if(!ovIsOpen(w) || w.__golemUserActed) return;   // dismissed or user took over → stop
            // keep content hidden while FF's startup keeps re-activating the tab; only
            // touch the docShell when it actually drifted back on (no redundant writes,
            // and a tighter 100ms cadence shrinks any composite that slips through).
            var b; try{ b=w.gBrowser.selectedBrowser; }catch(e){}
            if(b && b.docShellIsActive){ try{ b.docShellIsActive=false; }catch(e){} }
            ovPanel(w,true);
          } else if(ovTabs(w).length>1){
            OVLOG("startup: opening overview"); ovOpen(w); _opened=true;
            // as tab URLs settle (active tab: about:blank → real url) swap in thumbnails
            // IN PLACE — a full ovRender rebuilds every card and that was the open-flicker.
            [700,1500,2600].forEach(function(ms){ w.setTimeout(function(){ if(ovIsOpen(w)) ovRefreshCards(w); },ms); });
          }
        }catch(e){ OVLOG("startupopen:"+e); }
        if(++_st<22) w.setTimeout(ovStartupStep, 100);   // ~2.2s of tighter retries/re-asserts
      })();
    } }catch(e){}
    // button + capture wiring can settle a beat later
    try{ w.setTimeout(function(){
      try{ ovButton(w); ovPlaceButton(w); }catch(e){ OVLOG("button:"+e); }   // no-op create; re-seat after toolbar reflow
      try{ ovInit(w); }catch(e){ OVLOG("init:"+e); }
      try{ gtInit(w); }catch(e){ OVLOG("tint:"+e); }
      try{ gtPlaceholderWatch(w); }catch(e){ OVLOG("placeholder:"+e); }
      if(!OV_SELFTEST){ try{ bwInit(w); }catch(e){ OVLOG("warm init:"+e); } }   // the selftest drives it directly
      try{ mrInit(w); }catch(e){}
      if(OV_SELFTEST) w.setTimeout(function(){ ovSelfTest(w); }, 400);
      else ovHealthCheck(w);   // once, after the hooks are placed; no polling
    },1100); }catch(e){}
  }},"browser-delayed-startup-finished");
  OVLOG("tab-overview module loaded");
} catch(e){}
