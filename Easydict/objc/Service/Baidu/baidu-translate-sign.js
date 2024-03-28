/*
 * @author: tisfeng
 * @createTime: 2023-02-10 21:53
 * @lastEditor: tisfeng
 * @lastEditTime: 2023-04-22 23:30
 * @fileName: baidu-translate-sign.js
 *
 * Copyright (c) 2023 by ${git_name}, All Rights Reserved.
 */


function n(t, e) {
  for (var n = 0; n < e.length - 2; n += 3) {
    var r = e.charAt(n + 2);
    (r = "a" <= r ? r.charCodeAt(0) - 87 : Number(r)),
      (r = "+" === e.charAt(n + 1) ? t >>> r : t << r),
      (t = "+" === e.charAt(n) ? (t + r) & 4294967295 : t ^ r);
  }
  return t;
}

var C = null;

var token = function (r, _gtk) {
  var o = r.length;
  o > 30 &&
    (r =
      "" +
      r.substr(0, 10) +
      r.substr(Math.floor(o / 2) - 5, 10) +
      r.substring(r.length, r.length - 10));
  var t = void 0,
    t = null !== C ? C : (C = _gtk || "") || "";
  for (
    var e = t.split("."),
      h = Number(e[0]) || 0,
      i = Number(e[1]) || 0,
      d = [],
      f = 0,
      g = 0;
    g < r.length;
    g++
  ) {
    var m = r.charCodeAt(g);
    128 > m
      ? (d[f++] = m)
      : (2048 > m
          ? (d[f++] = (m >> 6) | 192)
          : (55296 === (64512 & m) &&
            g + 1 < r.length &&
            56320 === (64512 & r.charCodeAt(g + 1))
              ? ((m = 65536 + ((1023 & m) << 10) + (1023 & r.charCodeAt(++g))),
                (d[f++] = (m >> 18) | 240),
                (d[f++] = ((m >> 12) & 63) | 128))
              : (d[f++] = (m >> 12) | 224),
            (d[f++] = ((m >> 6) & 63) | 128)),
        (d[f++] = (63 & m) | 128));
  }
  for (var S = h, u = "+-a^+6", l = "+-3^+b+-f", s = 0; s < d.length; s++)
    (S += d[s]), (S = n(S, u));

  return (
    (S = n(S, l)),
    (S ^= i),
    0 > S && (S = (2147483647 & S) + 2147483648),
    (S %= 1e6),
    S.toString() + "." + (S ^ h)
  );
};

// Ref: https://github.com/akl7777777/bob-plugin-akl-baidu-free-translate/blob/main/node_js/bd.js#L34
function encrypt(t, gtk) {
  // window.gtk = "320305.131321201";
  //   console.log(t, gtk);
  let r = gtk;
  var o,
    i = t.match(/[\uD800-\uDBFF][\uDC00-\uDFFF]/g);
  if (null === i) {
    var a = t.length;
    a > 30 &&
      (t = ""
        .concat(t.substr(0, 10))
        .concat(t.substr(Math.floor(a / 2) - 5, 10))
        .concat(t.substr(-10, 10)));
  } else {
    for (
      var s = t.split(/[\uD800-\uDBFF][\uDC00-\uDFFF]/),
        c = 0,
        l = s.length,
        u = [];
      c < l;
      c++
    )
      "" !== s[c] &&
        u.push.apply(
          u,
          (function (t) {
            if (Array.isArray(t)) return e(t);
          })((o = s[c].split(""))) ||
            (function (t) {
              if (
                ("undefined" != typeof Symbol && null != t[Symbol.iterator]) ||
                null != t["@@iterator"]
              )
                return Array.from(t);
            })(o) ||
            (function (t, n) {
              if (t) {
                if ("string" == typeof t) return e(t, n);
                var r = Object.prototype.toString.call(t).slice(8, -1);
                return (
                  "Object" === r && t.constructor && (r = t.constructor.name),
                  "Map" === r || "Set" === r
                    ? Array.from(t)
                    : "Arguments" === r ||
                      /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(r)
                    ? e(t, n)
                    : void 0
                );
              }
            })(o) ||
            (function () {
              throw new TypeError(
                "Invalid attempt to spread non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."
              );
            })()
        ),
        c !== l - 1 && u.push(i[c]);
    var p = u.length;
    p > 30 &&
      (t =
        u.slice(0, 10).join("") +
        u.slice(Math.floor(p / 2) - 5, Math.floor(p / 2) + 5).join("") +
        u.slice(-10).join(""));
  }
  for (
    var d = ""
        .concat(String.fromCharCode(103))
        .concat(String.fromCharCode(116))
        .concat(String.fromCharCode(107)),
      h = (null !== r ? r : (r = window[d] || "") || "").split("."),
      f = Number(h[0]) || 0,
      m = Number(h[1]) || 0,
      g = [],
      y = 0,
      v = 0;
    v < t.length;
    v++
  ) {
    var _ = t.charCodeAt(v);
    _ < 128
      ? (g[y++] = _)
      : (_ < 2048
          ? (g[y++] = (_ >> 6) | 192)
          : (55296 == (64512 & _) &&
            v + 1 < t.length &&
            56320 == (64512 & t.charCodeAt(v + 1))
              ? ((_ = 65536 + ((1023 & _) << 10) + (1023 & t.charCodeAt(++v))),
                (g[y++] = (_ >> 18) | 240),
                (g[y++] = ((_ >> 12) & 63) | 128))
              : (g[y++] = (_ >> 12) | 224),
            (g[y++] = ((_ >> 6) & 63) | 128)),
        (g[y++] = (63 & _) | 128));
  }
  for (
    var b = f,
      w =
        ""
          .concat(String.fromCharCode(43))
          .concat(String.fromCharCode(45))
          .concat(String.fromCharCode(97)) +
        ""
          .concat(String.fromCharCode(94))
          .concat(String.fromCharCode(43))
          .concat(String.fromCharCode(54)),
      k =
        ""
          .concat(String.fromCharCode(43))
          .concat(String.fromCharCode(45))
          .concat(String.fromCharCode(51)) +
        ""
          .concat(String.fromCharCode(94))
          .concat(String.fromCharCode(43))
          .concat(String.fromCharCode(98)) +
        ""
          .concat(String.fromCharCode(43))
          .concat(String.fromCharCode(45))
          .concat(String.fromCharCode(102)),
      x = 0;
    x < g.length;
    x++
  )
    b = n((b += g[x]), w);
  return (
    (b = n(b, k)),
    (b ^= m) < 0 && (b = 2147483648 + (2147483647 & b)),
    "".concat((b %= 1e6).toString(), ".").concat(b ^ f)
  );
}
