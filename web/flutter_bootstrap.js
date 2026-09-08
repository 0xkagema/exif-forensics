{{flutter_js}}
{{flutter_build_config}}

// Use Flutter's loader API to control initialization stages
_flutter.loader.load({
  onEntrypointLoaded: async function(engineInitializer) {
    // 1. Initialize the Flutter Web Engine
    const appRunner = await engineInitializer.initializeEngine();
    
    // 2. Run the application
    await appRunner.runApp();

    // 3. Smoothly fade out and remove the loader from the DOM
    const loader = document.getElementById('loading-indicator');
    if (loader) {
      loader.style.opacity = '0';
      setTimeout(() => {
        loader.remove();
      }, 400); // Matches the 0.4s CSS transition duration
    }
  }
});
