import Foundation
import Security
import CryptoKit

enum LicenseType: String, Codable {
    case trial
    case personal
    case professional
    case lifetime
}

enum LicenseStatus {
    case valid(LicenseInfo)
    case expired
    case invalid
    case notActivated
}

struct LicenseInfo: Codable {
    let licenseKey: String
    let email: String
    let type: LicenseType
    let activatedAt: Date
    let expiresAt: Date?
    let machineId: String
    
    var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date() > expiresAt
    }
}

@MainActor
final class LicenseManager: ObservableObject {
    static let shared = LicenseManager()
    
    @Published private(set) var status: LicenseStatus = .notActivated
    @Published private(set) var licenseInfo: LicenseInfo?
    @Published var isProFeatureEnabled: Bool = false
    
    private let keychainService = "com.pingzi.LinguaFloat.license"
    private let trialDays = 7
    
    private init() {
        loadStoredLicense()
    }
    
    var isActivated: Bool {
        if case .valid = status { return true }
        return false
    }
    
    var remainingTrialDays: Int {
        let installDate = getInstallDate()
        let daysSinceInstall = Calendar.current.dateComponents([.day], from: installDate, to: Date()).day ?? 0
        return max(0, trialDays - daysSinceInstall)
    }
    
    var isTrialExpired: Bool {
        return remainingTrialDays <= 0 && !isActivated
    }
    
    func activate(licenseKey: String, email: String) async throws {
        let trimmedKey = licenseKey.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        guard isValidKeyFormat(trimmedKey) else {
            throw LicenseError.invalidFormat
        }
        
        let licenseType = try await verifyLicense(key: trimmedKey, email: email)
        
        let machineId = getMachineId()
        let now = Date()
        
        let expiresAt: Date? = {
            switch licenseType {
            case .trial:
                return Calendar.current.date(byAdding: .day, value: trialDays, to: now)
            case .personal:
                return Calendar.current.date(byAdding: .year, value: 1, to: now)
            case .professional:
                return Calendar.current.date(byAdding: .year, value: 1, to: now)
            case .lifetime:
                return nil
            }
        }()
        
        let info = LicenseInfo(
            licenseKey: trimmedKey,
            email: email,
            type: licenseType,
            activatedAt: now,
            expiresAt: expiresAt,
            machineId: machineId
        )
        
        try saveLicense(info)
        licenseInfo = info
        status = .valid(info)
        updateProFeatures()
    }
    
    func deactivate() {
        deleteLicense()
        licenseInfo = nil
        status = .notActivated
        isProFeatureEnabled = false
    }
    
    func checkLicense() {
        loadStoredLicense()
    }
    
    private func loadStoredLicense() {
        guard let data = loadFromKeychain(),
              let info = try? JSONDecoder().decode(LicenseInfo.self, from: data) else {
            status = .notActivated
            return
        }
        
        if info.machineId != getMachineId() {
            status = .invalid
            return
        }
        
        if info.isExpired {
            status = .expired
            licenseInfo = info
            return
        }
        
        licenseInfo = info
        status = .valid(info)
        updateProFeatures()
    }
    
    private func updateProFeatures() {
        guard let info = licenseInfo else {
            isProFeatureEnabled = false
            return
        }
        
        switch info.type {
        case .trial:
            isProFeatureEnabled = !info.isExpired
        case .personal, .professional, .lifetime:
            isProFeatureEnabled = !info.isExpired
        }
    }
    
    private func isValidKeyFormat(_ key: String) -> Bool {
        let pattern = "^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$"
        return key.range(of: pattern, options: .regularExpression) != nil
    }
    
    private func verifyLicense(key: String, email: String) async throws -> LicenseType {
        try await Task.sleep(nanoseconds: 500_000_000)
        
        if key.hasPrefix("TRIAL") { return .trial }
        if key.hasPrefix("PERS") { return .personal }
        if key.hasPrefix("PROF") { return .professional }
        if key.hasPrefix("LIFE") { return .lifetime }
        
        throw LicenseError.invalidKey
    }
    
    private func getMachineId() -> String {
        let platformExpert = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceMatching("IOPlatformExpertDevice")
        )
        
        defer { IOObjectRelease(platformExpert) }
        
        guard platformExpert != 0,
              let serialNumber = IORegistryEntryCreateCFProperty(
                platformExpert,
                kIOPlatformSerialNumberKey as CFString,
                kCFAllocatorDefault,
                0
              )?.takeRetainedValue() as? String else {
            return UUID().uuidString
        }
        
        let data = Data(serialNumber.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined().prefix(32).uppercased()
    }
    
    private func getInstallDate() -> Date {
        let key = "LinguaFloat.InstallDate"
        if let date = UserDefaults.standard.object(forKey: key) as? Date {
            return date
        }
        let now = Date()
        UserDefaults.standard.set(now, forKey: key)
        return now
    }
    
    private func saveLicense(_ info: LicenseInfo) throws {
        let data = try JSONEncoder().encode(info)
        saveToKeychain(data)
    }
    
    private func deleteLicense() {
        deleteFromKeychain()
    }
    
    private func saveToKeychain(_ data: Data) {
        deleteFromKeychain()
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: "license",
            kSecValueData as String: data
        ]
        
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private func loadFromKeychain() -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: "license",
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }
    
    private func deleteFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: "license"
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}

enum LicenseError: LocalizedError {
    case invalidFormat
    case invalidKey
    case alreadyActivated
    case networkError
    case serverError
    
    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "许可证格式无效，请检查输入"
        case .invalidKey:
            return "许可证密钥无效"
        case .alreadyActivated:
            return "此许可证已在其他设备激活"
        case .networkError:
            return "网络错误，请检查网络连接"
        case .serverError:
            return "服务器错误，请稍后重试"
        }
    }
}
