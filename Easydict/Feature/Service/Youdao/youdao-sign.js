var config = require('./config.js');
var utils = require('./utils.js');
var CryptoJS = require("crypto-js");

const r = "fanyideskweb", i = "webfanyi";
function m(e) {
    return CryptoJS.MD5(e).toString(CryptoJS.enc.Hex);
}
function p(e) {
    return CryptoJS.MD5(e.toString()).toString(CryptoJS.enc.Hex);
}

function b(e, t) {
  const r = "fanyideskweb", i = "webfanyi";
  
  return p('client=' + r + '&mysticTime=' + e + '&product=' + i + '&key=' + t)
}

function sign() {
    const r = "fanyideskweb", i = "webfanyi";

    const e = 'fsdsogkndfokasodnaso', s = 'client,mysticTime,product', u = 'fanyi.web', l = '1.0.0', d = 'web';

    const t = (new Date).getTime();
    
    return b(t, e)
}


function f() {
  const r = "fanyideskweb", i = "webfanyi";

  const e = 'fsdsogkndfokasodnaso', s = 'client,mysticTime,product', u = 'fanyi.web', l = '1.0.0', d = 'web';

  const t = (new Date).getTime();

  return {
    sign: b(t, e),
    client: r,
    product: i,
    appVersion: l,
    vendor: d,
    pointParam: s,
    mysticTime: t,
    keyfrom: u
  }
}

function A (t, o, n) {
  o = "ydsecret://query/key/BRGygVywfNBwpmBaZgWT7SIOUP2T0C9WHMZN39j^DAdaZhAnxvGcCY6VYFwnHl"
  n = "ydsecret://query/iv/C@lZe2YzHtZ2CYgaXKSVfsb7Y4QWHjITPPZ0nQp87fBeJ!Iv6v^6fvi2WN@bYpJ4"
  if (!t)
      return null;
  const a = CryptoJS.enc.Hex.parse(m(o)),
      r = CryptoJS.enc.Hex.parse(m(n)),
      i = CryptoJS.AES.decrypt(t, a, {
          iv: r
      });
  return i.toString(CryptoJS.enc.Utf8);
}

function decrypt (t, o, n) {
  o = "ydsecret://query/key/BRGygVywfNBwpmBaZgWT7SIOUP2T0C9WHMZN39j^DAdaZhAnxvGcCY6VYFwnHl"
  n = "ydsecret://query/iv/C@lZe2YzHtZ2CYgaXKSVfsb7Y4QWHjITPPZ0nQp87fBeJ!Iv6v^6fvi2WN@bYpJ4"
  if (!t)
      return null;
  const a = CryptoJS.enc.Hex.parse(m(o)),
      r = CryptoJS.enc.Hex.parse(m(n)),
      i = CryptoJS.AES.decrypt(t, a, {
          iv: r
      });
  return i.toString(CryptoJS.enc.Utf8);
}

function translate(query, completion) {
  // const apiClient = new api.Api($option.apikey, $option.service);

  (async () => {
    const targetLanguage = utils.langMap.get(query.detectTo);
    const sourceLanguage = utils.langMap.get(query.detectFrom);
    if (!targetLanguage) {
      const err = new Error();
      Object.assign(err, {
        _type: 'unsupportLanguage',
        _message: '不支持该语种',
      });
      throw err;
    }
    $log.info('***********==>' + 82)

    const source_lang = sourceLanguage || 'ZH';
    const target_lang = targetLanguage || 'EN';
    const translate_text = query.text || '';
    let response;
    $log.info('***********==>' + 88)

    if (translate_text !== '') {
      const url = 'https://dict.youdao.com/webtranslate';
      $log.info('***********==>' + 92)
      try {

        $log.info('***********url==>' + url)
        const originData = {
          'i': translate_text,
          'from': 'AUTO',
          'to': 'AUTO',
          'domain': '0',
          'dictResult': 'true',
          'keyid': 'webfanyi'
        }
        let fData = {}
        try {
          $log.info('***********CryptoJS.HmacSHA1==>' + CryptoJS.HmacSHA1("Message", "Key"));
          $log.info('***********CryptoJS.MD5(e).toString(CryptoJS.enc.Hex)==>' + CryptoJS.MD5("Message").toString(CryptoJS.enc.Hex));
          $log.info('***********typeof f()==>' + typeof f);

          fData = f()
        } catch (error) {

          $log.info('***********error==>' + JSON.stringify(error))
        }
        const body = Object.assign(originData, fData);
        $log.info('***********body==>' + JSON.stringify(body))

        $http.request({
          method: "POST",
          url: url,
          header: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36 Edg/108.0.1462.54',
            'Cookie': 'OUTFOX_SEARCH_USER_ID_NCOO=976405377.6815147; OUTFOX_SEARCH_USER_ID=-198948307@211.83.126.235; _ga=GA1.2.1162596953.1667349221; search-popup-show=12-2',
            'Referer': 'https://fanyi.youdao.com/'
          },
          body: body,
          handler: function (resp) {
            $log.error('***********response==>' + JSON.stringify(resp))
            $log.error('***********resp.data==>' + JSON.stringify(resp.data))
            let rs = A(resp.data)
            $log.error('***********rs==>' + rs)
            completion({
              result: {
                from: query.detectFrom,
                to: query.detectTo,
                toParagraphs: rs.split('\n'),
              },
            });
          }
        });
      }
      catch (e) {
        $log.error('接口请求错误 ==> ' + JSON.stringify(e))
        Object.assign(e, {
          _type: 'network',
          _message: '接口请求错误 - ' + JSON.stringify(e),
        });
        throw e;
      }
    }
  })().catch((err) => {
    $log.error('***********解析返回值异常==>' + JSON.stringify(err))
    completion({
      error: {
        type: err._type || 'unknown',
        message: err._message || '未知错误',
        addtion: err._addtion,
      },
    });
  });
}

function supportLanguages() {
  $log.error('***********' + JSON.stringify(config.supportedLanguages))
  return config.supportedLanguages.map(([standardLang]) => standardLang);
}

exports.supportLanguages = supportLanguages;
exports.translate = translate;
