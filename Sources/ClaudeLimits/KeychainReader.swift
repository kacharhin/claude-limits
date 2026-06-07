import Foundation
import Security

/// Reads the Claude Code OAuth access token from the login keychain.
/// The item is a generic password created by the `claude` CLI under the
/// service name "Claude Code-credentials"; its value is a JSON blob.
enum KeychainReader {
    static func claudeAccessToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "Claude Code-credentials",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }

        guard
            let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let oauth = obj["claudeAiOauth"] as? [String: Any],
            let token = oauth["accessToken"] as? String
        else { return nil }

        return token
    }
}
