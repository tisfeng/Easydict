// MDict WebView helper script for iframe sizing and dark-mode text tuning.
var mdictResizeTimer = 0;

function getIframeDocument(iframe) {
  try {
    return iframe.contentDocument || iframe.contentWindow.document;
  } catch (error) {
    return null;
  }
}

function resizeIframes() {
  var iframes = document.querySelectorAll('iframe.mdict-iframe');
  for (var i = 0; i < iframes.length; i++) {
    var iframe = iframes[i];
    var iframeDocument = getIframeDocument(iframe);
    if (!iframeDocument || !iframeDocument.body || !iframeDocument.documentElement) {
      continue;
    }
    setStyleIfChanged(iframeDocument.body, 'margin', '8px');
    setStyleIfChanged(iframeDocument.body, 'padding', '0');
    improveIframeDarkText(iframeDocument);
    observeIframeContent(iframe, iframeDocument);
    var height = iframeContentHeight(iframeDocument);
    if (height > 0) {
      setStyleIfChanged(iframe, 'height', height + 'px');
    }
  }
}

function iframeContentHeight(iframeDocument) {
  var body = iframeDocument.body;
  var view = iframeDocument.defaultView;
  var bodyRect = body.getBoundingClientRect();
  var bodyTop = bodyRect.top;
  var height = Math.ceil(bodyRect.height);
  var elements = body.querySelectorAll('*');
  for (var i = 0; i < elements.length; i++) {
    var element = elements[i];
    var tagName = element.tagName ? element.tagName.toLowerCase() : '';
    if (['script', 'style', 'link', 'meta'].indexOf(tagName) >= 0) {
      continue;
    }
    var style = view.getComputedStyle(element);
    if (style.display === 'none' || style.position === 'fixed') {
      continue;
    }
    var rect = element.getBoundingClientRect();
    if (rect.width === 0 && rect.height === 0) {
      continue;
    }
    height = Math.max(height, Math.ceil(rect.bottom - bodyTop));
  }
  var bodyStyle = view.getComputedStyle(body);
  var marginBottom = parseFloat(bodyStyle.marginBottom) || 0;
  return Math.max(1, height + marginBottom);
}

function observeIframeContent(iframe, iframeDocument) {
  if (iframe.dataset.mdictContentObserved === 'true') {
    return;
  }
  iframe.dataset.mdictContentObserved = 'true';
  iframeDocument.addEventListener('click', scheduleIframeUpdate, true);
  iframeDocument.addEventListener('input', scheduleIframeUpdate, true);
  iframeDocument.addEventListener('transitionend', scheduleIframeUpdate, true);
  iframeDocument.addEventListener('animationend', scheduleIframeUpdate, true);
  if (iframe.contentWindow && iframe.contentWindow.MutationObserver) {
    var observer = new iframe.contentWindow.MutationObserver(scheduleIframeUpdate);
    observer.observe(iframeDocument.body, {
      attributes: true,
      childList: true,
      subtree: true,
      characterData: true
    });
  }
}

function scheduleIframeUpdate() {
  if (mdictResizeTimer) {
    clearTimeout(mdictResizeTimer);
  }
  mdictResizeTimer = setTimeout(function() {
    mdictResizeTimer = 0;
    updateAllIframeStyle();
  }, 80);
}

function setStyleIfChanged(element, property, value) {
  if (element.style[property] !== value) {
    element.style[property] = value;
  }
}

function isDarkMode() {
  return window.matchMedia &&
    window.matchMedia('(prefers-color-scheme: dark)').matches;
}

function improveIframeDarkText(iframeDocument) {
  if (!isDarkMode()) {
    return;
  }
  var elements = iframeDocument.body.querySelectorAll('*');
  improveElementTextColor(iframeDocument.body, iframeDocument);
  for (var i = 0; i < elements.length; i++) {
    improveElementTextColor(elements[i], iframeDocument);
  }
}

function improveElementTextColor(element, iframeDocument) {
  var tagName = element.tagName ? element.tagName.toLowerCase() : '';
  if (['img', 'svg', 'path', 'audio', 'video', 'source'].indexOf(tagName) >= 0) {
    return;
  }
  var style = iframeDocument.defaultView.getComputedStyle(element);
  var textColor = parseColor(style.color);
  if (!textColor || textColor.a === 0) {
    return;
  }
  var backgroundColor = nearestBackgroundColor(element, iframeDocument);
  var readableColor = readableTextColor(textColor, backgroundColor);
  if (!readableColor) {
    return;
  }
  setStyleIfChanged(element, 'color', readableColor);
}

function nearestBackgroundColor(element, iframeDocument) {
  var current = element;
  while (current && current.nodeType === 1) {
    var style = iframeDocument.defaultView.getComputedStyle(current);
    var backgroundColor = parseColor(style.backgroundColor);
    if (backgroundColor && backgroundColor.a > 0.05) {
      return backgroundColor;
    }
    current = current.parentElement;
  }
  return { r: 48, g: 49, b: 50, a: 1 };
}

function readableTextColor(textColor, backgroundColor) {
  if (contrastRatio(textColor, backgroundColor) >= 4.5) {
    return null;
  }
  var targetIsWhite = relativeLuminance(backgroundColor) < 0.45;
  for (var amount = 0.18; amount <= 0.9; amount += 0.08) {
    var mixed = targetIsWhite ?
      mixWithWhite(textColor, amount) :
      mixWithBlack(textColor, amount);
    if (contrastRatio(mixed, backgroundColor) >= 4.5) {
      return rgbString(mixed);
    }
  }
  return targetIsWhite ? 'rgb(224, 224, 224)' : 'rgb(38, 38, 38)';
}

function parseColor(value) {
  if (!value || value === 'transparent') {
    return null;
  }
  var match = value.match(/rgba?\(([^)]+)\)/i);
  if (!match) {
    return null;
  }
  var parts = match[1].split(',').map(function(part) {
    return part.trim();
  });
  if (parts.length < 3) {
    return null;
  }
  return {
    r: parseFloat(parts[0]),
    g: parseFloat(parts[1]),
    b: parseFloat(parts[2]),
    a: parts.length > 3 ? parseFloat(parts[3]) : 1
  };
}

function mixWithWhite(color, amount) {
  return {
    r: color.r + (255 - color.r) * amount,
    g: color.g + (255 - color.g) * amount,
    b: color.b + (255 - color.b) * amount,
    a: color.a
  };
}

function mixWithBlack(color, amount) {
  return {
    r: color.r * (1 - amount),
    g: color.g * (1 - amount),
    b: color.b * (1 - amount),
    a: color.a
  };
}

function rgbString(color) {
  return 'rgb(' + Math.round(color.r) + ', ' +
    Math.round(color.g) + ', ' + Math.round(color.b) + ')';
}

function contrastRatio(foreground, background) {
  var lighter = Math.max(relativeLuminance(foreground), relativeLuminance(background));
  var darker = Math.min(relativeLuminance(foreground), relativeLuminance(background));
  return (lighter + 0.05) / (darker + 0.05);
}

function relativeLuminance(color) {
  var values = [color.r, color.g, color.b].map(function(value) {
    value = value / 255;
    return value <= 0.03928 ? value / 12.92 : Math.pow((value + 0.055) / 1.055, 2.4);
  });
  return 0.2126 * values[0] + 0.7152 * values[1] + 0.0722 * values[2];
}

function notifyContentHeight() {
  if (!(window.webkit && window.webkit.messageHandlers)) {
    return;
  }
  var height = Math.max(
    document.body.scrollHeight,
    document.documentElement.scrollHeight,
    Math.ceil(document.body.getBoundingClientRect().height)
  );
  window.webkit.messageHandlers.objcHandler.postMessage({
    method: 'noteToUpdateScrollHeight',
    scrollHeight: height
  });
}

function updateAllIframeStyle() {
  resizeIframes();
  notifyContentHeight();
  [50, 250, 750, 1500].forEach(function(delay) {
    setTimeout(function() {
      resizeIframes();
      notifyContentHeight();
    }, delay);
  });
}

function changeIframeBodyFontSize(fontSizeRatio) {
  var percentFontSize = fontSizeRatio * 100 + '%';
  document.body.style.fontSize = percentFontSize;
  var iframes = document.querySelectorAll('iframe.mdict-iframe');
  for (var i = 0; i < iframes.length; i++) {
    var iframeDocument = getIframeDocument(iframes[i]);
    if (iframeDocument && iframeDocument.body) {
      iframeDocument.body.style.fontSize = percentFontSize;
    }
  }
}

function attachIframeLoadHandlers() {
  var iframes = document.querySelectorAll('iframe.mdict-iframe');
  for (var i = 0; i < iframes.length; i++) {
    if (iframes[i].dataset.mdictObserved === 'true') {
      continue;
    }
    iframes[i].dataset.mdictObserved = 'true';
    iframes[i].addEventListener('load', updateAllIframeStyle);
  }
}

document.addEventListener('DOMContentLoaded', function() {
  attachIframeLoadHandlers();
  updateAllIframeStyle();
});
window.addEventListener('load', updateAllIframeStyle);
window.addEventListener('resize', updateAllIframeStyle);
if (document.fonts && document.fonts.ready) {
  document.fonts.ready.then(updateAllIframeStyle);
}
