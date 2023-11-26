//
//  EZBingDictService.m
//  Easydict
//
//  Created by ChoiKarl on 2023/11/26.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZBingDictService.h"

@interface EZBingDictService ()<WKNavigationDelegate>
@property (nonatomic, strong) NSString *dictHost;
@property (nonatomic, strong) WKWebViewConfiguration *configuration;
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, copy) NSString *edge_s;
@property (nonatomic, copy) void(^fetchEDGE_S)(NSString *);
@end

@implementation EZBingDictService

- (instancetype)initWithHost:(NSString *)host {
    self = [super init];
    if (self) {
        _dictHost = [NSString stringWithFormat:@"%@/dict/", host];
        _configuration = [[WKWebViewConfiguration alloc] init];
        _webView = [[WKWebView alloc] initWithFrame:NSRectFromCGRect(CGRectZero) configuration:_configuration];
        _webView.navigationDelegate = self;
    }
    return self;
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if ([navigationAction.request.URL.absoluteString containsString:self.dictHost]) {
        mm_weakify(self)
        [self.configuration.websiteDataStore.httpCookieStore getAllCookies:^(NSArray<NSHTTPCookie *> * _Nonnull allCookies) {
            mm_strongify(self)
            for (NSHTTPCookie *cookie in allCookies) {
                NSLog(@"%@", cookie.name);
                if ([cookie.name isEqualToString:@"_EDGE_S"]) {
                    if (cookie.value.length) {
                        self.edge_s = cookie.value;
                        if (self.fetchEDGE_S) {
                            self.fetchEDGE_S(cookie.value);
                        }
                    }
                    
                    break;
                }
            }
        }];
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}


 /**
  
  @objc public func translate(word: String) {
      if word.isEmpty {
          return
      }
      if edge_s?.isEmpty ?? true {
          self.fetchEDGE_S = {[weak self] (edge_s) in
              self?.translate(word: word)
          }
          if let url = URL(string: dictHost) {
               webView.load(URLRequest(url: url))
          }
          return
      }
      
      guard let url = URL(string: "\(dictHost)?q=\(word)"), let edge_s = edge_s else {
          return
      }
      
      let session = URLSession.shared

      var request = URLRequest(url: url)
      request.httpMethod = "GET"
      request.allHTTPHeaderFields = [
          "Content-Type":"text/html; charset=utf-8",
          "User-Agent":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Safari/537.36 Edg/112.0.1700.00",
          "Cookie":"_EDGE_S=\(edge_s)&mkt=zh-CN;"
      ]
      
      let task = session.dataTask(with: request) {[weak self] data, respinse, error in
          guard let data = data else { return }
          if let s = String(data: data, encoding: String.Encoding.utf8) {
              print(s);
          }
          
      }
      
      task.resume()
  }
  */
    
    


- (void)translateWithWord:(NSString *)word {
    if (!word.length) {
        return;
    }
    
    if (!self.edge_s.length) {
        mm_weakify(self)
        self.fetchEDGE_S = ^(NSString *edge_s) {
            mm_strongify(self)
            [self translateWithWord:word];
        };
        
        NSURL *url = [NSURL URLWithString:self.dictHost];
        if (url) {
            [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
        }
        return;
    }
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?q=%@", self.dictHost, word]];
    if (!url || self.edge_s == nil) {
        return;
    }
    
    NSURLSession *session = [NSURLSession sharedSession];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"GET";
    [request setAllHTTPHeaderFields:@{
        @"Content-Type": @"text/html; charset=utf-8",
        @"User-Agent": @"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Safari/537.36 Edg/112.0.1700.00",
        @"Cookie": [NSString stringWithFormat:@"_EDGE_S=%@&mkt=zh-CN;", self.edge_s]
    }];
    
    mm_weakify(self)
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        mm_strongify(self)
        if (data) {
            NSString *stringData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"%@", stringData);
        }
    }];
    
    [task resume];
}


@end
