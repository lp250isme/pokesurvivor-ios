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

    /// Document-start bridge. Google's COOP drops `window.opener`, so the handler cannot
    /// hand the auth event to the game. This exchanges that event in the sign-in window
    /// and lets the app call `signInWithCredential` on the game page.
    static let authBridge = #"""
    (() => {
      if (window.__psAuthBridge) return;
      window.__psAuthBridge = true;
      const host = (location.hostname || "").toLowerCase();
      const path = location.pathname || "";
      const game = host === "pokesurvivor.com" || host.endsWith(".pokesurvivor.com");
      const handler = (host === "firebaseapp.com" || host.endsWith(".firebaseapp.com") || game)
        && (path === "/__/auth/handler" || path.indexOf("/__/auth/handler/") === 0);

      const post = (body) => {
        try { webkit.messageHandlers.psAuth.postMessage(body); } catch (e) {}
      };

      if (handler) {
        const prefix = "ps-session:";
        const hasCode = location.search.indexOf("code=") >= 0;
        const proto = Storage.prototype;
        const write = proto.setItem;
        const drop = proto.removeItem;
        try { drop.call(sessionStorage, "setItem"); } catch (e) {}
        try { drop.call(localStorage, prefix + "setItem"); } catch (e) {}
        const mirrored = () => {
          const keys = [];
          for (let i = 0; i < localStorage.length; i++) {
            const key = localStorage.key(i);
            if (key && key.indexOf(prefix) === 0) keys.push(key);
          }
          return keys;
        };
        let storage = 0;
        try {
          for (let i = 0; i < sessionStorage.length; i++) {
            if ((sessionStorage.key(i) || "").indexOf("firebase:") === 0) storage++;
          }
          if (!hasCode) {
            mirrored().forEach((key) => drop.call(localStorage, key));
          } else if (storage === 0) {
            mirrored().forEach((key) => {
              write.call(sessionStorage, key.slice(prefix.length), localStorage.getItem(key));
              storage++;
            });
          }
        } catch (e) {}
        let exchangeEvent = () => {};
        if (!proto.__psMirror) {
          proto.setItem = function (key, value) {
            const out = write.call(this, key, value);
            if (this === window.sessionStorage) {
              try { write.call(window.localStorage, prefix + key, String(value)); } catch (e) {}
            }
            if (this === window.localStorage && String(key).indexOf("firebase:authEvent:") === 0) {
              exchangeEvent(String(key), String(value));
            }
            return out;
          };
          proto.__psMirror = true;
        }
        post({ ready: true, host: host, path: path, hasCode: hasCode, storage: storage });
        window.addEventListener("unhandledrejection", (event) => {
          const reason = event.reason;
          const msg = (reason && (reason.code || reason.message)) || "";
          post({ jserror: String(msg).slice(0, 120) });
        });

        // The handler never exchanges the code. It postMessages the opener, which COOP
        // has already cleared, then window.close(). Hold that close until we exchange.
        let finishClose = () => {};
        if (hasCode) {
          const realClose = window.close.bind(window);
          let hold = true;
          window.close = function () {
            if (!hold) return realClose();
          };
          finishClose = () => {
            if (!hold) return;
            hold = false;
            try { realClose(); } catch (e) {}
          };
          setTimeout(() => {
            if (window.__psAuthSent) return;
            post({ jserror: "exchange-timeout" });
            post({ close: true });
            finishClose();
          }, 12000);
        }

        const send = (json) => {
          if (!json || typeof json !== "object") return;
          const id = json.oauthIdToken || "";
          const access = json.oauthAccessToken || "";
          if (!id && !access) {
            if (!window.__psAuthMissing) {
              window.__psAuthMissing = true;
              post({ missing: true });
            }
            return;
          }
          if (window.__psAuthSent) return;
          window.__psAuthSent = true;
          post({ id: id, access: access });
        };
        const noteExchangeError = (message) => {
          if (window.__psAuthSent || window.__psExchangeNoted) return;
          window.__psExchangeNoted = true;
          post({ jserror: String(message || "exchange-failed").slice(0, 80) });
          post({ close: true });
          finishClose();
        };
        const look = (url, text) => {
          const u = String(url || "");
          if (u.indexOf("verifyAssertion") === -1 && u.indexOf("signInWithIdp") === -1) return;
          let json = null;
          try { json = JSON.parse(text); } catch (e) {}
          const id = json && (json.oauthIdToken || "");
          const access = json && (json.oauthAccessToken || "");
          if (id || access) {
            send(json);
            finishClose();
            return;
          }
          const err = json && json.error && json.error.message;
          noteExchangeError(err || "exchange-failed");
        };
        const origOpen = XMLHttpRequest.prototype.open;
        const origSend = XMLHttpRequest.prototype.send;
        XMLHttpRequest.prototype.open = function (method, url) {
          this.__psUrl = url;
          return origOpen.apply(this, arguments);
        };
        XMLHttpRequest.prototype.send = function () {
          this.addEventListener("load", function () {
            try {
              const u = String(this.__psUrl || "");
              const text = this.responseText || (typeof this.response === "string" ? this.response : "");
              look(u, text);
            } catch (e) {}
          });
          return origSend.apply(this, arguments);
        };
        if (typeof fetch === "function") {
          const origFetch = fetch;
          window.fetch = function (input) {
            const url = typeof input === "string" ? input : (input && input.url) || "";
            const pending = origFetch.apply(this, arguments);
            if (String(url).indexOf("verifyAssertion") === -1 && String(url).indexOf("signInWithIdp") === -1) return pending;
            return pending.then((res) => {
              res.clone().text().then((text) => look(url, text)).catch(() => {});
              return res;
            });
          };
        }
        exchangeEvent = (key, value) => {
          if (!hasCode || window.__psExchange) return;
          window.__psExchange = true;
          try {
            let event = JSON.parse(value);
            if (typeof event === "string") event = JSON.parse(event);
            const apiKey = key.split(":")[2] || "";
            if (!event || event.error || !event.sessionId || !event.urlResponse || !apiKey) {
              noteExchangeError("exchange-missing-session");
              return;
            }
            const body = {
              requestUri: event.urlResponse,
              sessionId: event.sessionId,
              returnSecureToken: true,
              returnIdpCredential: true
            };
            if (event.postBody) body.postBody = event.postBody;
            if (event.tenantId) body.tenantId = event.tenantId;
            fetch("https://identitytoolkit.googleapis.com/v1/accounts:signInWithIdp?key=" + encodeURIComponent(apiKey), {
              method: "POST",
              headers: { "Content-Type": "application/json" },
              referrerPolicy: "strict-origin-when-cross-origin",
              body: JSON.stringify(body)
            }).catch(() => noteExchangeError("exchange-network"));
          } catch (e) {
            noteExchangeError("exchange-throw");
          }
        };
        return;
      }

      if (!game) return;

      const settle = (pending, fn) => {
        if (!pending || pending.settled) return;
        pending.settled = true;
        fn();
      };

      window.__psCompleteGoogle = (payload) => {
        const run = (attempt) => {
          let auth = null;
          try { auth = firebase.auth && firebase.auth(); } catch (e) {}
          const pending = window.__psGoogleLogin;
          const target = (pending && pending.auth) || auth;
          if (!target || !firebase.auth.GoogleAuthProvider) {
            if (attempt < 40) setTimeout(() => run(attempt + 1), 50);
            return;
          }
          const cred = firebase.auth.GoogleAuthProvider.credential(payload.id || null, payload.access || null);
          const task = pending && pending.mode === "reauth" && pending.user
            ? pending.user.reauthenticateWithCredential(cred)
            : target.signInWithCredential(cred);
          Promise.resolve(task).then((result) => {
            post({ signedIn: true });
            settle(pending, () => pending.resolve(result));
          }).catch((err) => {
            const code = (err && err.code) || "";
            if (attempt < 8 && /popup|cancelled|pending/i.test(code)) {
              setTimeout(() => run(attempt + 1), 250);
              return;
            }
            post({ jserror: String(code || "credential").slice(0, 80) });
            settle(pending, () => pending.reject(err));
          });
        };
        run(0);
      };

      window.__psCancelGoogle = () => {
        settle(window.__psGoogleLogin, () => window.__psGoogleLogin.reject({ code: "auth/popup-closed-by-user" }));
      };

      const arm = (mode, target, original, arg) => new Promise((resolve, reject) => {
        let auth = null;
        try { auth = firebase.auth(); } catch (e) {}
        window.__psGoogleLogin = {
          resolve: resolve,
          reject: reject,
          auth: mode === "reauth" ? auth : target,
          user: mode === "reauth" ? target : null,
          mode: mode,
          settled: false
        };
        Promise.resolve(original.call(target, arg)).then((cred) => {
          settle(window.__psGoogleLogin, () => resolve(cred));
        }).catch((err) => {
          const code = (err && err.code) || "";
          if (code === "auth/popup-closed-by-user" || code === "auth/cancelled-popup-request") return;
          settle(window.__psGoogleLogin, () => reject(err));
        });
      });

      const install = () => {
        let auth = null;
        try { auth = firebase.auth && firebase.auth(); } catch (e) { return false; }
        if (!auth) return false;
        const proto = Object.getPrototypeOf(auth);
        const orig = proto && proto.signInWithPopup;
        if (typeof orig !== "function" || proto.__psPatched) return true;
        proto.signInWithPopup = function (provider) {
          if (!provider || provider.providerId !== "google.com") return orig.apply(this, arguments);
          return arm("signIn", this, orig, provider);
        };
        proto.__psPatched = true;
        const watchUser = () => {
          let user = null;
          try { user = firebase.auth().currentUser; } catch (e) {}
          if (!user) {
            setTimeout(watchUser, 1000);
            return;
          }
          const userProto = Object.getPrototypeOf(user);
          const origRe = userProto && userProto.reauthenticateWithPopup;
          if (typeof origRe !== "function" || userProto.__psRePatched) return;
          userProto.reauthenticateWithPopup = function (provider) {
            if (!provider || provider.providerId !== "google.com") return origRe.apply(this, arguments);
            return arm("reauth", this, origRe, provider);
          };
          userProto.__psRePatched = true;
        };
        watchUser();
        return true;
      };

      if (!install()) {
        const timer = setInterval(() => {
          if (install()) clearInterval(timer);
        }, 20);
        setTimeout(() => clearInterval(timer), 20000);
      }
    })();
    """#

    /// Puts an app-settings button inside the game's own settings and pause screens.
    /// The game page posts `settings`; nothing floats over the playfield.
    static let appSettings = #"""
    (() => {
      if (window.__psAppSettings) return;
      window.__psAppSettings = true;
      const host = (location.hostname || "").toLowerCase();
      if (host !== "pokesurvivor.com" && host !== "www.pokesurvivor.com") return;

      const open = (event) => {
        event.preventDefault();
        event.stopPropagation();
        try { webkit.messageHandlers.psChrome.postMessage("settings"); } catch (e) {}
      };

      const button = (id, className) => {
        const btn = document.createElement("button");
        btn.id = id;
        btn.type = "button";
        btn.className = className;
        btn.dataset.pszhControl = "";
        btn.textContent = "App 設定";
        btn.addEventListener("click", open);
        return btn;
      };

      const place = () => {
        const close = document.getElementById("set-close");
        if (close && !document.getElementById("ps-app-settings")) {
          const group = document.createElement("div");
          group.className = "row";
          close.before(group);
          group.append(button("ps-app-settings", "btn small ghost"), close);
        }
        const pause = document.getElementById("btn-pause-settings");
        if (pause && !document.getElementById("ps-app-settings-pause")) {
          pause.after(button("ps-app-settings-pause", "btn"));
        }
      };

      place();
      new MutationObserver(place).observe(document.documentElement, { childList: true, subtree: true });
    })();
    """#

    /// Insets the site's fixed pages away from the notch, Dynamic Island, and home indicator.
    /// The values come from `env(safe-area-inset-*)`, then the app overwrites them with the
    /// web view's real insets so every device and rotation uses the same rules.
    /// The playfield canvas stays full-bleed: combat touch events use viewport `clientX`,
    /// so the canvas itself is not moved. The canvas HUD is shifted by those same insets,
    /// and its hit targets move with it.
    static let safeArea = #"""
    (() => {
      if (window.__psSafeArea) return;
      window.__psSafeArea = true;
      const host = (location.hostname || "").toLowerCase();
      if (host !== "pokesurvivor.com" && host !== "www.pokesurvivor.com") return;

      window.__psSetSafe = (top, right, bottom, left) => {
        window.__psSafe = { t: top, r: right, b: bottom, l: left };
        const root = document.documentElement;
        root.style.setProperty("--ps-safe-top", top + "px");
        root.style.setProperty("--ps-safe-right", right + "px");
        root.style.setProperty("--ps-safe-bottom", bottom + "px");
        root.style.setProperty("--ps-safe-left", left + "px");
      };

      const style = document.createElement("style");
      style.id = "ps-safe-style";
      style.textContent = [
        ":root{",
        "--ps-safe-top:env(safe-area-inset-top,0px);",
        "--ps-safe-right:env(safe-area-inset-right,0px);",
        "--ps-safe-bottom:env(safe-area-inset-bottom,0px);",
        "--ps-safe-left:env(safe-area-inset-left,0px)",
        "}",
        ".scr,#pull-fx,.tapstart,.boot{",
        "top:var(--ps-safe-top)!important;",
        "right:var(--ps-safe-right)!important;",
        "bottom:var(--ps-safe-bottom)!important;",
        "left:var(--ps-safe-left)!important",
        "}",
        ".scr>.box,.box.settings,.box.news-box,.profile-box{max-height:100%!important}",
        ".topbar{margin-top:var(--ps-safe-top)!important;margin-right:var(--ps-safe-right)!important;align-items:center!important}",
        ".topbar .pill,.topbar .btn{height:30px!important;min-height:0!important;box-sizing:border-box!important;display:inline-flex!important;align-items:center!important;justify-content:center!important;line-height:1!important;box-shadow:none!important;white-space:nowrap!important}",
        ".topbar .btn{padding:0 8px!important}",
        ".topbar .pill{padding:0 10px!important}",
        ".topbar .btn img,.topbar .coin{height:18px!important;width:auto!important}",
        "#btn-sound,#btn-full,#btn-settings,#btn-support{width:30px!important;padding:0!important}",
        ".credits-line{margin-left:var(--ps-safe-left)!important;margin-bottom:var(--ps-safe-bottom)!important}",
        ".sound-panel{margin-top:var(--ps-safe-top)!important;margin-right:var(--ps-safe-right)!important}",
        ".toast{margin-bottom:var(--ps-safe-bottom)!important}",
        ".ach-pop{margin-top:var(--ps-safe-top)!important;margin-bottom:var(--ps-safe-bottom)!important}",
        ".invite-pop{margin-right:var(--ps-safe-right)!important;margin-bottom:var(--ps-safe-bottom)!important}"
      ].join("");
      (document.head || document.documentElement).appendChild(style);

      const installHud = () => {
        const hud = window.G && G.HUD;
        const touch = window.G && G.Touch;
        if (!hud || !touch || typeof hud.draw !== "function" || typeof touch.addButton !== "function") return false;
        if (hud.draw.__psSafe) return true;
        const orig = hud.draw;
        const wrapped = function (ctx, width, height, player, data) {
          const safe = window.__psSafe || { t: 0, r: 0, b: 0, l: 0 };
          const l = safe.l || 0, t = safe.t || 0, r = safe.r || 0, b = safe.b || 0;
          if (l + t + r + b < 0.5) return orig.call(this, ctx, width, height, player, data);
          const add = touch.addButton;
          touch.addButton = function (x, y, w, h, fn, pad) {
            return add.call(this, x + l, y + t, w, h, fn, pad);
          };
          ctx.save();
          ctx.translate(l, t);
          try {
            return orig.call(this, ctx, Math.max(1, width - l - r), Math.max(1, height - t - b), player, data);
          } finally {
            touch.addButton = add;
            ctx.restore();
          }
        };
        wrapped.__psSafe = true;
        hud.draw = wrapped;
        return true;
      };
      if (!installHud()) {
        const timer = setInterval(() => {
          if (installHud()) clearInterval(timer);
        }, 50);
        setTimeout(() => clearInterval(timer), 20000);
      }
    })();
    """#
}
