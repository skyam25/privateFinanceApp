//
//  SimpleFINWebView.swift
//  GhostVault
//
//  WebView for SimpleFIN signup flow
//  Monitors for setup token in URL or page content
//

import SwiftUI
import WebKit

struct SimpleFINWebView: View {
    let onTokenDetected: (String) -> Void
    let onManualPaste: () -> Void
    let onCancel: () -> Void

    @State private var isLoading = true
    @State private var showManualPastePrompt = false

    var body: some View {
        VStack(spacing: 0) {
            // Header with cancel button
            HStack {
                Button("Cancel") {
                    onCancel()
                }
                Spacer()
                if isLoading {
                    ProgressView()
                }
                Spacer()
                Button("Manual Paste") {
                    onManualPaste()
                }
            }
            .padding()
            .background(Color(.systemBackground))

            // WebView
            SimpleFINWebViewRepresentable(
                onTokenDetected: onTokenDetected,
                onLoadingChanged: { loading in
                    isLoading = loading
                }
            )
        }
        .navigationBarHidden(true)
    }
}

// MARK: - WebView Representable

struct SimpleFINWebViewRepresentable: UIViewRepresentable {
    let onTokenDetected: (String) -> Void
    let onLoadingChanged: (Bool) -> Void

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true

        // Load SimpleFIN signup page
        if let url = URL(string: "https://bridge.simplefin.org/simplefin/create") {
            webView.load(URLRequest(url: url))
        }

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onTokenDetected: onTokenDetected, onLoadingChanged: onLoadingChanged)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        let onTokenDetected: (String) -> Void
        let onLoadingChanged: (Bool) -> Void

        init(onTokenDetected: @escaping (String) -> Void, onLoadingChanged: @escaping (Bool) -> Void) {
            self.onTokenDetected = onTokenDetected
            self.onLoadingChanged = onLoadingChanged
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            onLoadingChanged(true)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            onLoadingChanged(false)
            checkForToken(in: webView)
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // Check URL for token patterns
            if let url = navigationAction.request.url {
                if let token = extractTokenFromURL(url) {
                    onTokenDetected(token)
                    decisionHandler(.cancel)
                    return
                }
            }
            decisionHandler(.allow)
        }

        private func checkForToken(in webView: WKWebView) {
            // Check the current URL
            if let url = webView.url, let token = extractTokenFromURL(url) {
                onTokenDetected(token)
                return
            }

            // Check page content for token patterns
            // SimpleFIN typically shows the token in a specific element or format
            let javascript = """
            (function() {
                // Look for setup token in various places
                var tokenPatterns = [
                    // Look for base64-encoded URLs (setup tokens)
                    /[A-Za-z0-9+\\/=]{40,}/g
                ];

                // Check for elements that might contain the token
                var tokenElements = document.querySelectorAll('input[readonly], pre, code, .token, [data-token]');
                for (var el of tokenElements) {
                    var text = el.textContent || el.value || '';
                    if (text.length > 40 && /^[A-Za-z0-9+\\/=]+$/.test(text.trim())) {
                        return text.trim();
                    }
                }

                // Check for data attributes
                var dataToken = document.querySelector('[data-setup-token]');
                if (dataToken) {
                    return dataToken.getAttribute('data-setup-token');
                }

                return null;
            })();
            """

            webView.evaluateJavaScript(javascript) { [weak self] result, error in
                if let token = result as? String, !token.isEmpty {
                    self?.onTokenDetected(token)
                }
            }
        }

        private func extractTokenFromURL(_ url: URL) -> String? {
            // Check for token in URL path or query parameters
            let urlString = url.absoluteString

            // Look for common token patterns in SimpleFIN URLs
            // Example: https://bridge.simplefin.org/simplefin/token/BASE64_TOKEN
            if urlString.contains("/token/") {
                let components = urlString.components(separatedBy: "/token/")
                if components.count > 1 {
                    let tokenPart = components[1].components(separatedBy: "?").first ?? components[1]
                    if isValidTokenFormat(tokenPart) {
                        return tokenPart
                    }
                }
            }

            // Check query parameters
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let queryItems = components.queryItems {
                for item in queryItems {
                    if let value = item.value, isValidTokenFormat(value) {
                        if item.name.lowercased().contains("token") ||
                           item.name.lowercased().contains("setup") {
                            return value
                        }
                    }
                }
            }

            // Check fragment
            if let fragment = url.fragment, isValidTokenFormat(fragment) {
                return fragment
            }

            return nil
        }

        private func isValidTokenFormat(_ string: String) -> Bool {
            // Setup tokens are base64-encoded URLs, typically 40+ characters
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.count >= 40 else { return false }

            // Check if it's valid base64
            guard let data = Data(base64Encoded: trimmed) else { return false }

            // Check if it decodes to a valid URL
            guard let decodedString = String(data: data, encoding: .utf8),
                  let url = URL(string: decodedString),
                  let scheme = url.scheme?.lowercased(),
                  (scheme == "http" || scheme == "https") else {
                return false
            }

            return true
        }
    }
}

// MARK: - Preview

#Preview {
    SimpleFINWebView(
        onTokenDetected: { token in print("Token: \(token)") },
        onManualPaste: { print("Manual paste") },
        onCancel: { print("Cancelled") }
    )
}
