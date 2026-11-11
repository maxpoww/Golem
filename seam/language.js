// Golem: Seam speaks the session's language (seam/sources.json "langpacks", README "Languages").
// intl.locale.requested = "" is Firefox's own "use the OS locale": on Linux that is ONE locale,
// ICU's default (setlocale LC_MESSAGES, else the LC_ALL, LC_MESSAGES, LANG variables; LANGUAGE
// is never read), negotiated against the packs: fr_CA to fr, de_AT to de, pt_PT to pt-PT,
// en_US and en_GB to en-US (Firefox's own). One Golem refinement: Spanish of a country with no
// pack of its own goes to Spain's Spanish in Firefox (es_BO to es-ES, CLDR's likely subtags);
// Golem gives it the Latin American pack, es-MX. A DEFAULT pref, set at every start: the next
// start follows a new language. (Spliced into mozilla.cfg through an unquoted shell heredoc in
// nixpkgs' wrapper: keep this file free of the dollar sign, the backtick and the backslash.)
(function(){
  var want="", m=/^es_([A-Z]{2})/.exec(getenv("LC_ALL")||getenv("LC_MESSAGES")||getenv("LANG")||"");
  if(m && m[1]!=="ES") want="es-MX";
  defaultPref("intl.locale.requested", want);
})();
