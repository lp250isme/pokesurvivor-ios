import Foundation

enum ShellScripts {
    static let viewport = """
    (() => {
      const content = "width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no, viewport-fit=cover";
      let meta = document.querySelector('meta[name="viewport"]');
      if (!meta) {
        meta = document.createElement("meta");
        meta.setAttribute("name", "viewport");
        (document.head || document.documentElement).appendChild(meta);
      }
      meta.setAttribute("content", content);
      const style = document.createElement("style");
      style.textContent = "html,body{background:#0a1430;overscroll-behavior:none;-webkit-user-select:none;user-select:none;-webkit-touch-callout:none;-webkit-tap-highlight-color:transparent}input,textarea{user-select:text;-webkit-user-select:text}";
      (document.head || document.documentElement).appendChild(style);
    })();
    """

    /// Rewrites the patch's Tampermonkey hint. This string is ours; the patch source is not edited.
    static let statusNote = """
    (() => {
      const rewrite = () => {
        const note = document.querySelector("#pszh-status");
        if (!note || note.dataset.psios) return;
        note.dataset.psios = "1";
        note.textContent = "繁體中文補丁已啟用。翻譯作者 Kai5106，遊戲與存檔仍是原站。可在 App 設定關閉。";
      };
      rewrite();
      new MutationObserver(rewrite).observe(document.documentElement, { childList: true, subtree: true });
    })();
    """

    static let patchMarker = "!!window[Symbol.for('pokesurvivor.zhHant.displayPatch')]"
}
