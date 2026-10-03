// macOS staging copy of user-overrides.js - synced with the linux copy at
// .config/mozilla/firefox/dpr72wmm.defprofile/user-overrides.js.
// bootstrap/firefox deploys this file into the seeded macOS profile
// (~/Library/Application Support/Firefox/Profiles/<hash>.defprofile/).

// --- Base requirements (gwfox install) ---
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
user_pref("svg.context-properties.content.enabled", true);
user_pref("browser.newtabpage.activity-stream.nova.enabled", false);
user_pref("browser.nova.enabled", false);
user_pref("browser.tabs.allow_transparent_browser", true); // required by gwfox.newtab (transparent new tab)

// --- Customization toggles (gwfox.*) ---
user_pref("gwfox.newtab", true);    // transparent new tab page
user_pref("gwfox.urlbar", true);    // urlbar + controls into the sidebar (README look)
user_pref("gwfox.atbc", true);      // Adaptive Tab Bar Colour compatibility
user_pref("gwfox.icons", true);     // menu icons
user_pref("gwfox.ac", true);        // accent color (edit --bg0 in chrome/userChrome.css to recolor)
user_pref("gwfox.sidebar", 3);      // sidebar width: 1=173px, 2=default, 3=253px
user_pref("gwfox.msc", true);       // macOS-style tab close button
user_pref("gwfox.toolbar", true);   // auto-hide bookmarks bar (fades out, shows on hover)

// --- Sidebar: native vertical tabs (gwfox supported config) ---
user_pref("sidebar.verticalTabs", true);
user_pref("sidebar.visibility", "always-show");

// --- macOS: ---
user_pref("widget.macos.native-context-menus", false); // macOS: gwfox requires native context menus off
