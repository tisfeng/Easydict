//
//  AppleDictionary+Translate.swift
//  Easydict
//
//  Created by tisfeng on 2024/7/25.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation
import WebKit

private var navigationDelegateAssociatedObjectKey: UInt8 = 0

// MARK: - AppleDictionary + WKNavigationDelegate

extension AppleDictionary: WKNavigationDelegate {
    private var navigationDelegateHolder: NavigationDelegate? {
        get {
            objc_getAssociatedObject(self, &navigationDelegateAssociatedObjectKey) as? NavigationDelegate
        }
        set {
            objc_setAssociatedObject(
                self,
                &navigationDelegateAssociatedObjectKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    // Currently this method isn't used.

    @MainActor
    @objc
    func loadHtmlAndGetBodyText(html: String, from webView: WKWebView) async -> String? {
        webView.loadHTMLString(html, baseURL: nil)

        // Wait for the webView to finish loading.
        await withCheckedContinuation { continuation in
            self.navigationDelegateHolder = NavigationDelegate {
                continuation.resume(returning: ())
                self.navigationDelegateHolder = nil
            }
            webView.navigationDelegate = self.navigationDelegateHolder
        }

        webView.navigationDelegate = self

        return await getBodyInnerText(from: webView)
    }

    @MainActor
    func getBodyInnerText(from webView: WKWebView) async -> String? {
        await withCheckedContinuation { continuation in
            let script = """
            var iframes = document.querySelectorAll('iframe');
            var text = '';
            for (var i = 0; i < iframes.length; i++) {
                text += iframes[i].contentDocument.body.innerText;
                text += '\\n\\n';
            };
            text;
            """
            webView.evaluateJavaScript(script) { result, error in
                if let error {
                    logError(String(describing: error))
                }

                if let innerText = result as? String {
                    continuation.resume(returning: innerText)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}

// MARK: - NavigationDelegate

class NavigationDelegate: NSObject, WKNavigationDelegate {
    // MARK: Lifecycle

    init(onNavigationFinished: @escaping () -> ()) {
        self.onNavigationFinished = onNavigationFinished
    }

    // MARK: Internal

    let onNavigationFinished: () -> ()

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        onNavigationFinished()
    }
}
