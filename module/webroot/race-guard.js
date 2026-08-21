(() => {
  "use strict";

  const originalFetch = globalThis.fetch.bind(globalThis);
  const root = document.documentElement;
  let statusReady = false;
  let mutationBusy = false;
  let mutationRelease = "";
  let releaseTimer = 0;
  let logSequence = 0;
  let statusSequence = 0;
  let latestLogPromise = null;
  let latestStatusPromise = null;

  const mutationSelectors = [
    "#saveConfigButton",
    "#actionCards button",
    "#jobLaunchers button",
    "[data-webui-mutation]",
  ];

  function syncSurface() {
    root.dataset.webuiStatusReady = statusReady ? "true" : "false";
    root.dataset.webuiMutationBusy = mutationBusy ? "true" : "false";
  }

  function endpoint(input) {
    try {
      const raw = typeof input === "string" ? input : input?.url || "";
      return new URL(raw, globalThis.location?.href || "http://127.0.0.1/").pathname;
    } catch (_) {
      return "";
    }
  }

  function methodOf(input, options) {
    const method = options?.method || input?.method || "GET";
    return String(method).toUpperCase();
  }

  function guardedButton(target) {
    const button = target?.closest?.("button");
    if (!button) return null;
    return mutationSelectors.some(selector => button.matches?.(selector) || button.closest?.(selector)) ? button : null;
  }

  function releaseMutation() {
    if (releaseTimer) globalThis.clearTimeout(releaseTimer);
    releaseTimer = 0;
    mutationBusy = false;
    mutationRelease = "";
    syncSurface();
  }

  function armFallbackRelease() {
    if (releaseTimer) globalThis.clearTimeout(releaseTimer);
    releaseTimer = globalThis.setTimeout(releaseMutation, 8000);
  }

  function beginMutation(path) {
    if (!statusReady || mutationBusy) return false;
    mutationBusy = true;
    mutationRelease = path === "/api/v1/jobs" ? "jobs" : "status";
    syncSurface();
    armFallbackRelease();
    return true;
  }

  function blockedResponse() {
    const error = statusReady ? "another operation is still completing" : "module status is not ready";
    return new Response(JSON.stringify({ ok: false, error }), {
      status: 409,
      headers: { "Content-Type": "application/json" },
    });
  }

  function sequenceResponse(path, promise) {
    if (path === "/api/v1/log") {
      const sequence = ++logSequence;
      const latest = promise.then(response => response.clone());
      latestLogPromise = latest;
      return promise.then(async response => {
        if (sequence !== logSequence && latestLogPromise) {
          try { return (await latestLogPromise).clone(); } catch (_) {}
        }
        return response;
      });
    }

    if (path === "/api/v1/status") {
      const sequence = ++statusSequence;
      const latest = promise.then(response => response.clone());
      latestStatusPromise = latest;
      return promise.then(async response => {
        let selected = response;
        if (sequence !== statusSequence && latestStatusPromise) {
          try { selected = (await latestStatusPromise).clone(); } catch (_) {}
        }
        if (sequence === statusSequence && selected.ok) {
          statusReady = true;
          if (mutationBusy && mutationRelease === "status") releaseMutation();
          syncSurface();
        }
        return selected;
      });
    }

    if (path === "/api/v1/jobs") {
      return promise.then(response => {
        if (response.ok && mutationBusy && mutationRelease === "jobs") releaseMutation();
        return response;
      });
    }

    return promise;
  }

  globalThis.fetch = function guardedFetch(input, options = {}) {
    const path = endpoint(input);
    const method = methodOf(input, options);

    const coordinatedMutation = path === "/api/v1/action" || path === "/api/v1/config" || path === "/api/v1/jobs";
    if (method === "POST" && coordinatedMutation) {
      if (!beginMutation(path)) return Promise.resolve(blockedResponse());
      return originalFetch(input, options).then(response => {
        if (!response.ok) releaseMutation();
        return response;
      }, error => {
        releaseMutation();
        throw error;
      });
    }

    return sequenceResponse(path, originalFetch(input, options));
  };

  document.addEventListener("click", event => {
    const button = guardedButton(event.target);
    if (!button || (statusReady && !mutationBusy)) return;
    event.preventDefault();
    event.stopImmediatePropagation();
  }, true);

  globalThis.addEventListener?.("pagehide", () => {
    if (releaseTimer) globalThis.clearTimeout(releaseTimer);
  });

  syncSurface();
})();
