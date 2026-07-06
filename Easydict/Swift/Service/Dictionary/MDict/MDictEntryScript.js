// MDict page helper script for audio, in-page anchors, and height reporting.
document.addEventListener('click', function(event) {
  var link = event.target && event.target.closest ? event.target.closest('a[href]') : null;
  if (!link) {
    return;
  }
  var href = link.getAttribute('href') || '';
  if (event.defaultPrevented) {
    return;
  }
  var source = audioSource(link, href);
  if (source) {
    event.preventDefault();
    playAudio(source);
    return;
  }
  if (isEmptyHashLink(href) || handleAnchorLink(href)) {
    event.preventDefault();
  }
}, false);

function audioSource(link, href) {
  if (link.matches('a[href^="data:audio"],a[href^="mdict-sound://"],a[href^="sound://"]')) {
    return href;
  }
  var match = href.match(/^\\s*javascript:\\s*new\\s+Audio\\s*\\(\\s*(['"])(data:[^'"]+)\\1\\s*\\)/i);
  return match ? match[2] : null;
}

function playAudio(source) {
  if (!source) {
    return;
  }
  window.__mdictAudio = new Audio(source);
  window.__mdictAudio.play();
}

function handleAnchorLink(href) {
  var hash = samePageHash(href);
  if (!hash || hash.length < 2) {
    return false;
  }
  var id = decodeHash(hash.slice(1));
  var target = document.getElementById(id) || document.getElementsByName(id)[0];
  if (!target) {
    return false;
  }
  setTimeout(function() {
    target.scrollIntoView({ block: 'start' });
    notifyContentHeight();
  }, 0);
  return true;
}

function isEmptyHashLink(href) {
  var trimmed = href.trim();
  return trimmed === '#' ||
    /^javascript:\\s*(?:void\\s*\\(\\s*0\\s*\\)|;?)\\s*;?$/i.test(trimmed);
}

function samePageHash(href) {
  var trimmed = href.trim();
  if (trimmed.charAt(0) === '#') {
    return trimmed;
  }
  if (/^[a-z][a-z0-9+.-]*:/i.test(trimmed)) {
    return '';
  }
  var hashIndex = trimmed.indexOf('#');
  return hashIndex >= 0 ? trimmed.slice(hashIndex) : '';
}

function decodeHash(value) {
  try {
    return decodeURIComponent(value);
  } catch (error) {
    return value;
  }
}

function changeIframeBodyFontSize(fontSizeRatio) {
  document.body.style.fontSize = (fontSizeRatio * 100) + '%';
}

function updateAllIframeStyle() {
  scheduleContentHeight();
}

var pendingHeightUpdate = false;

function scheduleContentHeight() {
  if (pendingHeightUpdate) {
    return;
  }
  pendingHeightUpdate = true;
  window.requestAnimationFrame(function() {
    pendingHeightUpdate = false;
    notifyContentHeight();
  });
}

function notifyContentHeight() {
  var body = document.body;
  var element = document.documentElement;
  var scrollHeight = Math.max(
    body ? body.scrollHeight : 0,
    element ? element.scrollHeight : 0,
    body ? body.offsetHeight : 0,
    element ? element.offsetHeight : 0
  );
  if (!window.webkit ||
      !window.webkit.messageHandlers ||
      !window.webkit.messageHandlers.objcHandler) {
    return;
  }
  window.webkit.messageHandlers.objcHandler.postMessage({
    method: 'noteToUpdateScrollHeight',
    scrollHeight: scrollHeight
  });
}

function observeContentChanges() {
  document.addEventListener('toggle', scheduleContentHeight, true);

  if (!window.ResizeObserver) {
    return;
  }

  var observer = new ResizeObserver(scheduleContentHeight);
  if (document.documentElement) {
    observer.observe(document.documentElement);
  }
  if (document.body) {
    observer.observe(document.body);
  }
  var entries = document.querySelectorAll('.mdict-entry');
  for (var index = 0; index < entries.length; index += 1) {
    observer.observe(entries[index]);
  }
}

document.addEventListener('DOMContentLoaded', function() {
  observeContentChanges();
  updateAllIframeStyle();
});
window.addEventListener('load', updateAllIframeStyle);
window.addEventListener('resize', updateAllIframeStyle);

if (document.fonts && document.fonts.ready) {
  document.fonts.ready.then(updateAllIframeStyle);
}
