// MDict appearance adapter backed by the bundled Dark Reader runtime.
(function() {
  var initialized = false;

  function updateMDictStyle() {
    if (initialized || !window.DarkReader) {
      return;
    }
    DarkReader.auto({
      brightness: 100,
      contrast: 100,
      sepia: 0
    });
    initialized = true;
  }

  window.updateMDictStyle = updateMDictStyle;
})();
