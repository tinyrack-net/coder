// Overrides the bootstrap script Flutter would otherwise generate, so the
// HTML boot splash in `index.html` can be dismissed at the one moment it is
// safe to: after `runApp`, when Dart is already painting its own splash.
//
// `serviceWorkerSettings` mirrors the generated default. `flutter build web`
// keeps its offline-first strategy, so dropping this block here would quietly
// disable the service worker the PWA manifest depends on.
{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}}
  },
  onEntrypointLoaded: async function (engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();

    const splash = document.getElementById('boot-splash');
    if (splash === null) return;
    // Fading rather than removing outright keeps the handoff invisible even if
    // Dart's first frame lands a frame later than this callback.
    splash.addEventListener('transitionend', () => splash.remove(), {
      once: true,
    });
    splash.setAttribute('data-loaded', '');
  },
});
