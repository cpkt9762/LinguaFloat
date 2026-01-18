import SwiftUI

struct LicenseView: View {
    @ObservedObject var licenseManager = LicenseManager.shared
    
    @State private var licenseKey = ""
    @State private var email = ""
    @State private var isActivating = false
    @State private var errorMessage: String?
    @State private var showSuccessAlert = false
    
    var body: some View {
        VStack(spacing: 20) {
            headerView
            
            Divider()
            
            if licenseManager.isActivated {
                activatedView
            } else {
                activationFormView
            }
            
            Spacer()
        }
        .padding(24)
        .frame(width: 450, height: 400)
        .alert("激活成功", isPresented: $showSuccessAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text("许可证已成功激活")
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            Image(systemName: "key.fill")
                .font(.system(size: 40))
                .foregroundStyle(.blue)
            
            Text("许可证管理")
                .font(.title2)
                .fontWeight(.semibold)
            
            if !licenseManager.isActivated {
                Text("剩余试用天数: \(licenseManager.remainingTrialDays) 天")
                    .font(.caption)
                    .foregroundStyle(licenseManager.remainingTrialDays <= 3 ? .red : .secondary)
            }
        }
    }
    
    private var activatedView: some View {
        VStack(spacing: 16) {
            if let info = licenseManager.licenseInfo {
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        LicenseInfoRow(label: "许可证类型", value: licenseTypeName(info.type))
                        LicenseInfoRow(label: "邮箱", value: info.email)
                        LicenseInfoRow(label: "激活日期", value: formatDate(info.activatedAt))
                        
                        if let expiresAt = info.expiresAt {
                            LicenseInfoRow(label: "到期日期", value: formatDate(expiresAt))
                        } else {
                            LicenseInfoRow(label: "到期日期", value: "永久")
                        }
                        
                        LicenseInfoRow(label: "许可证密钥", value: maskKey(info.licenseKey))
                    }
                    .padding(8)
                }
                
                Button("取消激活", role: .destructive) {
                    licenseManager.deactivate()
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    private var activationFormView: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("邮箱地址")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                TextField("your@email.com", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.emailAddress)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("许可证密钥")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                TextField("XXXX-XXXX-XXXX-XXXX", text: $licenseKey)
                    .textFieldStyle(.roundedBorder)
                    .textCase(.uppercase)
                    .onChange(of: licenseKey) { _, newValue in
                        licenseKey = formatLicenseKey(newValue)
                    }
            }
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            
            HStack(spacing: 12) {
                Link("购买许可证", destination: URL(string: "https://linguafloat.com/buy")!)
                    .buttonStyle(.link)
                
                Spacer()
                
                Button("激活") {
                    Task {
                        await activate()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isActivating || !isValidInput)
            }
        }
    }
    
    private var isValidInput: Bool {
        !email.isEmpty && email.contains("@") && licenseKey.count == 19
    }
    
    private func activate() async {
        isActivating = true
        errorMessage = nil
        
        do {
            try await licenseManager.activate(licenseKey: licenseKey, email: email)
            showSuccessAlert = true
            licenseKey = ""
            email = ""
        } catch let error as LicenseError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isActivating = false
    }
    
    private func formatLicenseKey(_ input: String) -> String {
        let cleaned = input.uppercased().filter { $0.isLetter || $0.isNumber }
        var result = ""
        
        for (index, char) in cleaned.prefix(16).enumerated() {
            if index > 0 && index % 4 == 0 {
                result += "-"
            }
            result.append(char)
        }
        
        return result
    }
    
    private func licenseTypeName(_ type: LicenseType) -> String {
        switch type {
        case .trial: return "试用版"
        case .personal: return "个人版"
        case .professional: return "专业版"
        case .lifetime: return "终身版"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func maskKey(_ key: String) -> String {
        let parts = key.split(separator: "-")
        guard parts.count == 4 else { return key }
        return "\(parts[0])-****-****-\(parts[3])"
    }
}

struct LicenseInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    LicenseView()
}
