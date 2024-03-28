/**
 * nodejs 爬取百度翻译
 */
const axios = require("axios");

async function fetchHtml(url, headers) {
  try {
    return await axios.get(url, { headers });
  } catch (error) {
    throw new Error(error);
  }
}

async function postData(url, data, headers) {
  try {
    const response = await axios.post(url, data, { headers });
    return response.data;
  } catch (error) {
    throw new Error(error);
  }
}

function n(t, e) {
  for (var n = 0; n < e.length - 2; n += 3) {
    var r = e.charAt(n + 2);
    (r = "a" <= r ? r.charCodeAt(0) - 87 : Number(r)),
      (r = "+" === e.charAt(n + 1) ? t >>> r : t << r),
      (t = "+" === e.charAt(n) ? (t + r) & 4294967295 : t ^ r);
  }
  return t;
}

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

async function translate(t) {
  try {
    const url = "https://fanyi.baidu.com/";
    // 第一轮取cookie
    const htmlResp = await fetchHtml(url);
    const cookie = htmlResp.headers.get("set-cookie")[0];
    console.log("cookie: ", cookie);
    // console.log(htmlResp.text.match(/Set-Cookie:\s*(.*?);/i))
    // 第二轮取gtk,token
    const htmlResp2 = await fetchHtml(url, { Cookie: cookie });
    // console.log(html2)
    // const specialChar = html.match(/<input type="hidden" name="special_char" value="(.+?)" \/>/)[1];
    // console.log(htmlResp2.data)
    const gtkMatch = htmlResp2.data.match(/window\.gtk\s*=\s*"([\d.]+)"/);
    const token = htmlResp2.data.match(/token:\s*'(\w+)'/)[1];
    const gtk = gtkMatch ? gtkMatch[1] : null;
    console.log("token: ", token);
    console.log("gtk: ", gtk);
    const headers = {
      Cookie: cookie,
      "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
      "User-Agent":
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Safari/537.36",
    };
    const _encrypt = encrypt(t, gtk);
    console.log("encrypt: ", _encrypt);
    const data = {
      from: "en",
      to: "zh",
      query: t,
      transtype: "realtime",
      simple_means_flag: "3",
      sign: _encrypt,
      token: token,
    };
    const response = await postData(
      "https://fanyi.baidu.com/v2transapi?from=zh&to=en",
      data,
      headers
    );
    console.log(response.trans_result.data[0].dst);
  } catch (error) {
    console.error(error);
  }
}

const t =
  "The API reference documentation provides detailed information about a function or object in Node.js. This documentation indicates what arguments a method accepts, the return value of that method, and what errors may be related to that method. It also indicates which methods are available for different versions of Node.js.";

// translate(t);
translate("good ");
