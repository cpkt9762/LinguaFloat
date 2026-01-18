import SwiftUI

struct ErrorView: View {
    let error: TranslationError
    let onRetry: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.orange)
            
            Text("翻译失败")
                .font(.headline)
            
            Text(error.errorDescription ?? "未知错误")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 12) {
                Button("关闭", action: onDismiss)
                    .buttonStyle(.bordered)
                
                Button("重试", action: onRetry)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 280)
    }
}

struct NetworkErrorView: View {
    let onRetry: () -> Void
    let onOpenSettings: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 40))
                .foregroundStyle(.red)
            
            Text("网络不可用")
                .font(.headline)
            
            Text("请检查网络连接或代理设置")
                .font(.body)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 12) {
                Button("检查设置", action: onOpenSettings)
                    .buttonStyle(.bordered)
                
                Button("重试", action: onRetry)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 280)
    }
}

struct PermissionErrorView: View {
    let permissionType: String
    let onOpenSettings: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.shield")
                .font(.system(size: 40))
                .foregroundStyle(.blue)
            
            Text("需要权限")
                .font(.headline)
            
            Text("请授予「\(permissionType)」权限以使用此功能")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 12) {
                Button("稍后", action: onDismiss)
                    .buttonStyle(.bordered)
                
                Button("前往设置", action: onOpenSettings)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 300)
    }
}

struct ToastView: View {
    let message: String
    let type: ToastType
    
    enum ToastType {
        case success
        case error
        case info
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "xmark.circle.fill"
            case .info: return "info.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .success: return .green
            case .error: return .red
            case .info: return .blue
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: type.icon)
                .foregroundStyle(type.color)
            
            Text(message)
                .font(.body)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial)
        .clipShape(Capsule())
        .shadow(radius: 4)
    }
}
