import Foundation

/// Language shown on the original site. Traditional Chinese is a display catalog
/// bundled with the app. The site itself stays Spanish until this is on.
enum DisplayLanguage: String, CaseIterable, Identifiable {
    case traditionalChinese = "zh-Hant"
    case original = "original"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .traditionalChinese: "繁體中文"
        case .original: "原文"
        }
    }

    var pageScript: String? {
        switch self {
        case .traditionalChinese: DisplayTranslator.traditionalChinese
        case .original: nil
        }
    }

    /// Keeps an existing 「繁體中文補丁」choice when upgrading from the download toggle.
    static func migrateStoredValue() {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: "displayLanguage") == nil else { return }
        let patchOn = (defaults.object(forKey: "patch.enabled") as? Bool) ?? true
        let language: DisplayLanguage = patchOn ? .traditionalChinese : .original
        defaults.set(language.rawValue, forKey: "displayLanguage")
    }
}

enum DisplayTranslator {
    static let markerExpression = "!!window[Symbol.for('pokesurvivor.zhHant.displayPatch')]"

    static let traditionalChinese: String? = {
        guard let json = bundledEntriesJSON else { return nil }
        return pageScript(entriesJSON: json)
    }()

    static var bundledEntriesJSON: String? {
        guard let url = Bundle.main.url(forResource: "zh-Hant", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = String(data: data, encoding: .utf8),
              json.first == "[" else { return nil }
        return json
    }

    static func pageScript(entriesJSON: String) -> String {
        #"""
        (() => {
          'use strict';
          if (!['pokesurvivor.com', 'www.pokesurvivor.com'].includes(location.hostname)) return;
          if (!/^\/(?:index\.html|en\/(?:index\.html)?)?$/.test(location.pathname)) return;
          const marker = Symbol.for('pokesurvivor.zhHant.displayPatch');
          if (window[marker]) return;
          window[marker] = true;
          \#(translationCore(entriesJSON: entriesJSON))
          const translatedNodes = new WeakMap();
          function isMoveElement(el) {
            return !el.closest('.type-chip, .type, .tag-chip') && !!el.closest('.card .nm, #scr-bond .ds, #bond-sub, .move-icons, #starter-info, #dex-detail p, #over-stats b');
          }
          const ATTRS = ['placeholder', 'title', 'alt', 'aria-label'];
          const skipped = el => !!el?.closest('[translate="no"], [contenteditable], script, style, code, textarea, [data-pszh-control]');
          function textNode(node) {
            if (!node.parentElement || skipped(node.parentElement)) return;
            const before = node.nodeValue;
            if (translatedNodes.get(node) === before) return;
            const after = translate(isMoveElement(node.parentElement) ? moveText(before) : before);
            translatedNodes.set(node, after);
            if (after !== before) node.nodeValue = after;
          }
          function element(el) {
            if (skipped(el)) return;
            for (const attr of ATTRS) {
              const before = el.getAttribute(attr);
              if (!before) continue;
              const after = translate(isMoveElement(el) ? moveText(before) : before);
              if (before !== after) el.setAttribute(attr, after);
            }
          }
          function walk(root) {
            if (root.nodeType === Node.TEXT_NODE) return textNode(root);
            if (root.nodeType !== Node.ELEMENT_NODE || skipped(root)) return;
            element(root);
            const walker = document.createTreeWalker(root, NodeFilter.SHOW_ELEMENT | NodeFilter.SHOW_TEXT);
            let node;
            while ((node = walker.nextNode())) {
              if (node.nodeType === Node.TEXT_NODE) textNode(node); else element(node);
            }
          }
          const proto = window.CanvasRenderingContext2D?.prototype;
          if (proto) for (const method of ['fillText', 'strokeText', 'measureText']) {
            const original = proto[method];
            proto[method] = function (text, ...args) {
              const font = this.font;
              this.font = font.replace(/Pixelify/g, '"Microsoft JhengHei", "PingFang TC", "Noto Sans TC", sans-serif');
              try {
                const value = typeof text === 'string' && /^(?:Psíquico|Psychic)(?: \+\d+)?$/iu.test(text.trim()) ? moveText(text) : text;
                return original.call(this, translate(value), ...args);
              } finally { this.font = font; }
            };
          }
          for (const method of ['alert', 'confirm']) {
            const original = window[method];
            window[method] = function (text) { return original.call(window, translate(text)); };
          }
          const style = document.createElement('style');
          style.id = 'pszh-style';
          style.textContent = 'html[data-pszh] { --font: "Microsoft JhengHei", "PingFang TC", "Noto Sans TC", system-ui, sans-serif; } html[data-pszh] .btn { letter-spacing: 0; } html[data-pszh] .sub { line-height: 1.55; }';
          document.head.appendChild(style);
          document.documentElement.setAttribute('data-pszh', 'zh-Hant');
          document.documentElement.lang = 'zh-Hant';
          if (document.body) {
            walk(document.body);
            document.title = translate(document.title);
            new MutationObserver(records => {
              for (const record of records) {
                if (record.type === 'characterData') textNode(record.target);
                else if (record.type === 'attributes') element(record.target);
                else { for (const node of record.addedNodes) walk(node); }
              }
            }).observe(document.body, { childList: true, subtree: true, characterData: true, attributes: true, attributeFilter: ATTRS });
          }
        })();
        """#
    }

    static func translationCore(entriesJSON: String) -> String {
        #"""
        const ENTRIES = \#(entriesJSON);
        const exact = new Map(), lower = new Map(), fragments = new Map(), patterns = [];
        const cache = new Map();
        const escapeRE = s => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
        for (const [source, target] of ENTRIES) {
          if (!target || source === target) continue;
          if (source.includes('{x}')) {
            patterns.push({ re: new RegExp('^' + source.split('{x}').map(escapeRE).join('(.+?)') + '$', 'iu'), target });
          } else {
            exact.set(source, target);
            lower.set(source.toLowerCase(), target);
            if (source.length >= 4 || /\s/.test(source)) fragments.set(source.toLowerCase(), target);
          }
        }
        const fragmentRE = new RegExp('(?<![\\p{L}\\p{N}])(' + [...fragments.keys()].sort((a, b) => b.length - a.length).map(escapeRE).join('|') + ')(?![\\p{L}\\p{N}])', 'giu');
        function translate(s, depth = 0) {
          if (typeof s !== 'string' || !/[A-Za-zÀ-ž]/u.test(s) || depth > 8) return s;
          if (cache.has(s)) return cache.get(s);
          const [, lead, middle, tail] = /^(\s*)([\s\S]*?)(\s*)$/.exec(s);
          const body = middle.replace(/\s+/g, ' ');
          let result = exact.get(body) ?? lower.get(body.toLowerCase());
          if (result === undefined) {
            for (const pattern of patterns) {
              const match = pattern.re.exec(body);
              if (!match) continue;
              let index = 1;
              result = pattern.target.replace(/\{x\}/g, () => translate(match[index++], depth + 1));
              break;
            }
          }
          if (result === undefined) result = body.replace(fragmentRE, word => fragments.get(word.toLowerCase()) || word);
          const output = result === body ? s : lead + result + tail;
          if (cache.size > 5000) cache.clear();
          cache.set(s, output);
          return output;
        }
        function moveText(s) {
          return typeof s === 'string' ? s.replace(/(?<![\p{L}\p{N}])(?:Psíquico|Psychic)(?![\p{L}\p{N}])/giu, '精神強念') : s;
        }
        """#
    }
}
