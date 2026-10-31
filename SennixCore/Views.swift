import SwiftUI
import UIKit
import ImageIO

struct RootView: View {
    @EnvironmentObject var model: AppModel
    var body: some View {
        Group { switch model.route { case .login: LoginView(); case .devices: DeviceListView(); case .main: MainTabView(); case .mattressMain: MattressMainView() } }
            .background(AppTheme.background.ignoresSafeArea())
            .preferredColorScheme(.dark)
    }
}

struct LoginView: View {
    @EnvironmentObject var model: AppModel
    var body: some View {
        NavigationStack {
            ScrollView {
                Group {
                    switch model.authScreen {
                    case .login: LoginForm()
                    case .register: RegisterForm()
                    case .resetPassword: ResetPasswordForm()
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .padding(.bottom, 48)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color(red: 13/255, green: 13/255, blue: 13/255).ignoresSafeArea())
            .navigationBarHidden(true)
                .alert("提示", isPresented: Binding(get: { model.toast != nil }, set: { if !$0 { model.toast = nil } })) { Button("确定") { model.toast = nil } } message: { Text(model.toast ?? "") }
        }
    }
}

private struct LoginForm: View {
    @EnvironmentObject var model: AppModel
    var body: some View {
        VStack(spacing: 0) {
            AuthHeading(title: "欢迎", subtitle: "登录您的睡眠账户", centered: true)
                .padding(.bottom, 48)
            AuthField("手机号", icon: "phone.fill", text: $model.phone, keyboard: .phonePad)
                .padding(.bottom, 20)
            if model.usesLoginCode {
                VerificationRow(text: $model.verificationCode, seconds: model.loginCodeSeconds, action: model.sendLoginCode)
            } else {
                AuthSecureField("密码", text: $model.password)
            }
            HStack {
                if !model.usesLoginCode {
                    Button("忘记密码？") { model.showAuthScreen(.resetPassword) }
                }
                Spacer()
                Button(model.usesLoginCode ? "使用密码登录" : "使用验证码登录") { model.toggleLoginMethod() }
            }
            .font(.system(size: 12))
            .foregroundStyle(AuthPalette.secondary)
            .padding(.top, 12)
            .padding(.bottom, 20)
            Button("登录", action: model.login).buttonStyle(AuthPrimaryButtonStyle())
                .padding(.bottom, 32)
            Button("还没有账户？立即注册") { model.showAuthScreen(.register) }
                .font(.system(size: 14))
                .foregroundStyle(AuthPalette.secondary)
        }
    }
}

private struct RegisterForm: View {
    @EnvironmentObject var model: AppModel
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button("← 已有账户？返回登录") { model.showAuthScreen(.login) }
                .font(.system(size: 14)).foregroundStyle(AuthPalette.secondary).padding(.bottom, 40)
            AuthHeading(title: "创建账户", subtitle: "开始您的智能睡眠之旅")
                .padding(.bottom, 40)
            AuthField("手机号", icon: "phone.fill", text: $model.phone, keyboard: .phonePad).padding(.bottom, 20)
            VerificationRow(text: $model.verificationCode, seconds: model.registerCodeSeconds, action: model.sendRegisterCode).padding(.bottom, 20)
            AuthSecureField("设置密码", text: $model.password).padding(.bottom, 20)
            AuthSecureField("确认密码", text: $model.confirmPassword).padding(.bottom, 16)
            Button("立即注册", action: model.register).buttonStyle(AuthPrimaryButtonStyle())
        }
    }
}

private struct ResetPasswordForm: View {
    @EnvironmentObject var model: AppModel
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button("← 返回登录") { model.showAuthScreen(.login) }
                .font(.system(size: 14)).foregroundStyle(AuthPalette.secondary).padding(.bottom, 40)
            AuthHeading(title: "重置密码", subtitle: "验证身份后设置新密码", titleSize: 30)
                .padding(.bottom, 40)
            AuthField("手机号", icon: "phone.fill", text: $model.phone, keyboard: .phonePad).padding(.bottom, 20)
            VerificationRow(text: $model.verificationCode, seconds: model.resetCodeSeconds, action: model.sendResetCode).padding(.bottom, 20)
            AuthSecureField("新密码", text: $model.newPassword).padding(.bottom, 16)
            Button("确认重置", action: model.resetPassword).buttonStyle(AuthPrimaryButtonStyle())
        }
    }
}

private enum AuthPalette {
    static let input = Color(red: 17/255, green: 17/255, blue: 17/255)
    static let border = Color(red: 42/255, green: 42/255, blue: 42/255)
    static let secondary = Color(red: 148/255, green: 163/255, blue: 184/255)
    static let placeholder = Color(red: 100/255, green: 116/255, blue: 139/255)
}

private struct AuthHeading: View {
    let title: String
    let subtitle: String
    var centered = false
    var titleSize: CGFloat = 36
    var body: some View {
        VStack(alignment: centered ? .center : .leading, spacing: 8) {
            Text(title).font(.system(size: titleSize, weight: .thin)).tracking(1.8).foregroundStyle(.white)
            Text(subtitle).font(.system(size: 16)).foregroundStyle(AuthPalette.secondary)
        }.frame(maxWidth: .infinity, alignment: centered ? .center : .leading)
    }
}

private struct AuthField: View {
    let title: String
    let icon: String
    @Binding var text: String
    let keyboard: UIKeyboardType
    init(_ title: String, icon: String, text: Binding<String>, keyboard: UIKeyboardType = .default) {
        self.title = title; self.icon = icon; _text = text; self.keyboard = keyboard
    }
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.system(size: 14)).foregroundStyle(AuthPalette.secondary).frame(width: 16)
            TextField("", text: $text, prompt: Text(title).foregroundStyle(AuthPalette.placeholder))
                .keyboardType(keyboard)
                .textInputAutocapitalization(.never).autocorrectionDisabled().foregroundStyle(.white)
        }.authInputStyle()
    }
}

private struct AuthSecureField: View {
    let title: String
    @Binding var text: String
    init(_ title: String, text: Binding<String>) { self.title = title; _text = text }
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "lock.fill").font(.system(size: 14)).foregroundStyle(AuthPalette.secondary).frame(width: 16)
            SecureField("", text: $text, prompt: Text(title).foregroundStyle(AuthPalette.placeholder)).textContentType(.password).foregroundStyle(.white)
        }.authInputStyle()
    }
}

private struct VerificationRow: View {
    @Binding var text: String
    let seconds: Int
    let action: () -> Void
    var body: some View {
        HStack(spacing: 12) {
            AuthField("验证码", icon: "number", text: $text, keyboard: .numberPad)
            Button(seconds > 0 ? "\(seconds)s后重发" : "发送验证码", action: action)
                .disabled(seconds > 0).font(.system(size: 14)).foregroundStyle(AuthPalette.secondary)
                .padding(.horizontal, 14).frame(height: 50)
                .background(AuthPalette.input).clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AuthPalette.border, lineWidth: 1)).opacity(0.6)
        }
    }
}

private extension View {
    func authInputStyle() -> some View {
        self.font(.system(size: 16)).padding(.horizontal, 14).frame(height: 50)
            .background(AuthPalette.input).clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AuthPalette.border, lineWidth: 1))
    }
}

private struct AuthPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 16)).foregroundStyle(.black).frame(maxWidth: .infinity).frame(height: 50)
            .background(Color.white.opacity(configuration.isPressed ? 0.75 : 1)).clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct DeviceListView: View {
    @EnvironmentObject var model: AppModel
    var body: some View {
        Group { switch model.deviceScreen { case .list: BoundDeviceListView(); case .catalog: DeviceCatalogView(); case .scan: DeviceScanView() } }
    }
}

private struct BoundDeviceListView: View {
    @EnvironmentObject var model: AppModel
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 5) { Text("设备清单").font(.system(size: 26, weight: .bold)); Text("连接并管理您的智能设备").font(.system(size: 13)).foregroundStyle(AppTheme.secondary) }
                Spacer()
                Button { model.openDeviceCatalog() } label: { Text("+").font(.system(size: 32)).foregroundStyle(AppTheme.cyan).frame(width: 48, height: 48).background(AppTheme.card).clipShape(RoundedRectangle(cornerRadius: 8)) }
            }.padding(.top, 12).padding(.bottom, 20)
            Text("我的设备").font(.system(size: 12)).tracking(1.4).foregroundStyle(AppTheme.secondary).padding(.bottom, 10)
            if model.boundDevices.isEmpty {
                Spacer()
                VStack(spacing: 12) { Text("⌁").font(.system(size: 54)).foregroundStyle(Color(red: 55/255, green: 65/255, blue: 81/255)); Text("暂无设备").font(.system(size: 16)).foregroundStyle(AppTheme.secondary); Text("点击右上角 + 添加设备").font(.system(size: 13)).foregroundStyle(Color(red: 75/255, green: 85/255, blue: 99/255)) }.frame(maxWidth: .infinity)
                Spacer()
            } else {
                ScrollView { VStack(spacing: 10) { ForEach(model.boundDevices, id: \.self) { name in Button { model.openBoundDevice(name) } label: { HStack(spacing: 12) { DeviceProductIcon(isPillow: name.hasPrefix("MJ-20"), compact: true); VStack(alignment: .leading, spacing: 5) { Text(displayName(name)).font(.system(size: 16, weight: .bold)); Text(name.hasPrefix("MJ-20") ? "智能枕" : "智能床垫").font(.system(size: 12)).foregroundStyle(AppTheme.secondary) }; Spacer(); Text("›").font(.system(size: 28)).foregroundStyle(AppTheme.secondary) } }.buttonStyle(.plain).padding(.horizontal, 16).padding(.vertical, 10).background(AppTheme.card).clipShape(RoundedRectangle(cornerRadius: 10)) } } }
            }
        }.padding(20).background(AppTheme.background.ignoresSafeArea()).onAppear { model.loadBoundDevices() }
    }
    private func displayName(_ name: String) -> String { if name.contains("MJ-01") { return "SCM-BASIC" }; if name.contains("MJ-02") { return "SCM-MAX" }; if name.contains("MJ-06") { return "SCM-PRO" }; if name.contains("MJ-08") { return "SCM-ULTRA" }; return name }
}

private struct DeviceCatalogView: View {
    @EnvironmentObject var model: AppModel
    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) { Button { model.returnToDeviceList() } label: { Image(systemName: "chevron.left").foregroundStyle(.white).frame(width: 32, height: 32) }.padding(.top, 8).padding(.bottom, 60); Button("智能床垫") { model.selectDeviceCategory("mattress") }.frame(width: 74, height: 74).foregroundStyle(model.deviceCategory == "mattress" ? .white : Color.gray).background(model.deviceCategory == "mattress" ? Color(red: 26/255, green: 26/255, blue: 26/255) : .clear); Button("智能枕") { model.selectDeviceCategory("pillow") }.frame(width: 74, height: 74).foregroundStyle(model.deviceCategory == "pillow" ? .white : Color.gray).background(model.deviceCategory == "pillow" ? Color(red: 26/255, green: 26/255, blue: 26/255) : .clear); Spacer() }.frame(width: 74).background(AppTheme.background)
            VStack(alignment: .leading, spacing: 0) { Text("所有设备").font(.system(size: 24, weight: .bold)); Text("选择设备型号开始搜索").font(.system(size: 13)).foregroundStyle(AppTheme.secondary).padding(.top, 5); ScrollView { LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) { ForEach(Array(catalogItems.enumerated()), id: \.offset) { _, item in Button { model.beginDeviceScan() } label: { VStack(spacing: 10) { DeviceProductIcon(isPillow: model.deviceCategory == "pillow", compact: false); Text(item.name).font(.system(size: 14, weight: .bold)).foregroundStyle(.white).multilineTextAlignment(.center); Text(item.type).font(.system(size: 11)).foregroundStyle(AppTheme.secondary) }.frame(maxWidth: .infinity).padding(10).background(Color(red: 24/255, green: 24/255, blue: 27/255)) }.buttonStyle(.plain) } }.padding(.top, 20) }.padding(.horizontal, 16).padding(.top, 28).background(AppTheme.background)
        }.ignoresSafeArea()
    }
    private var catalogItems: [(name: String, model: String, type: String)] { model.deviceCategory == "mattress" ? [("SCM-BASIC", "MJ-01", "SCM"), ("SCM-MAX", "MJ-02", "SCM"), ("SCM-PRO", "MJ-06", "SCM"), ("SCM-ULTRA", "MJ-08", "SCM")] : [("DreamPillow Pro", "MJ-20", "DreamPillow"), ("DreamPillow Lite", "MJ-20", "DreamPillow")] }
}

private struct DeviceProductIcon: View {
    let isPillow: Bool
    let compact: Bool
    @ViewBuilder
    var body: some View {
        if isPillow {
            if #available(iOS 17.0, *) {
                systemIcon("pillow.fill")
            } else {
                systemIcon("rectangle.fill")
            }
        } else {
            systemIcon("bed.double.fill")
        }
    }
    private func systemIcon(_ name: String) -> some View {
        Image(systemName: name)
            .resizable()
            .scaledToFit()
            .foregroundStyle(AppTheme.cyan)
            .frame(width: compact ? 32 : 64, height: compact ? 24 : 58)
            .frame(maxWidth: compact ? 42 : .infinity, minHeight: compact ? 32 : 78)
    }
}

private struct DeviceScanView: View {
    @EnvironmentObject var model: AppModel
    @State private var pulse = false
    var body: some View {
        VStack(spacing: 0) {
            HStack { Button("‹  返回设备清单") { model.leaveDeviceScan() }.font(.system(size: 15)).foregroundStyle(AppTheme.cyan); Spacer() }.frame(height: 44)
            Spacer()
            Image("app_logo").resizable().scaledToFit().frame(width: 112, height: 112).padding(.bottom, 16)
            Text("SMART SLEEP SYSTEM").font(.system(size: 11)).tracking(1.9).foregroundStyle(Color(red: 107/255, green: 114/255, blue: 128/255)).padding(.bottom, 48)
            ZStack {
                Circle().stroke(AppTheme.cyan, lineWidth: 2).frame(width: 120, height: 120).scaleEffect(pulse ? 1.3 : 1).opacity(pulse ? 0.1 : 0.3)
                Circle().stroke(AppTheme.cyan, lineWidth: 2).frame(width: 90, height: 90).scaleEffect(pulse ? 1.2 : 1).opacity(pulse ? 0.2 : 0.5)
                Circle().fill(Color(red: 9/255, green: 36/255, blue: 44/255)).overlay(Circle().stroke(AppTheme.cyan, lineWidth: 1)).frame(width: 60, height: 60)
                Image(systemName: "bolt.fill").font(.system(size: 30)).foregroundStyle(AppTheme.cyan)
            }.frame(height: 120).padding(.bottom, 32)
            if case .connecting = model.bluetooth.state { Text("连接中…").font(.system(size: 18)).foregroundStyle(.white); Text("正在建立安全连接，请稍候").font(.system(size: 12)).foregroundStyle(AppTheme.secondary).padding(.top, 8) }
            else if case .connected = model.bluetooth.state { Text("设备已连接").font(.system(size: 18)).foregroundStyle(.white); Text("正在初始化服务").font(.system(size: 12)).foregroundStyle(AppTheme.secondary).padding(.top, 8) }
            else { Text(model.deviceScanStopped ? "扫描已停止" : "正在搜索设备...").font(.system(size: 18)).foregroundStyle(.white); Text(model.deviceScanStopped ? (model.bluetooth.devices.isEmpty ? "未发现设备，请重试" : "点击连接按钮连接设备") : "请确保设备已开机并在附近").font(.system(size: 12)).foregroundStyle(AppTheme.secondary).padding(.top, 8) }
            if !model.bluetooth.devices.isEmpty { VStack(alignment: .leading, spacing: 12) { Text("发现的设备").font(.system(size: 11)).tracking(1.7).foregroundStyle(AppTheme.secondary); ForEach(model.bluetooth.devices) { device in Button { model.connectDiscovered(device) } label: { HStack { Image(systemName: "bolt.fill").foregroundStyle(AppTheme.cyan).frame(width: 48, height: 48).background(Color(red: 9/255, green: 36/255, blue: 44/255)).clipShape(Circle()); VStack(alignment: .leading) { Text(device.name).font(.system(size: 16, weight: .bold)).foregroundStyle(.white); Text(model.deviceCategory == "pillow" ? "智能枕头" : "智能床垫").font(.system(size: 12)).foregroundStyle(AppTheme.secondary) }; Spacer(); Text("连接").font(.system(size: 13, weight: .bold)).foregroundStyle(.black).frame(width: 80, height: 42).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 10)) }.padding(16).background(AppTheme.card).clipShape(RoundedRectangle(cornerRadius: 12)) }.buttonStyle(.plain) } }.padding(.top, 22) }
            if model.deviceScanStopped && model.bluetooth.devices.isEmpty { Button { model.enterVirtualDevice() } label: { Text("进入演示设备").font(.system(size: 14, weight: .bold)).foregroundStyle(.black).frame(maxWidth: .infinity).frame(height: 50).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 10)) }.padding(.top, 16) }
            Spacer()
            Button(model.deviceScanStopped ? "开始扫描" : "停止扫描") { model.deviceScanStopped ? model.beginDeviceScan() : model.stopDeviceScan() }.buttonStyle(AuthPrimaryButtonStyle()).padding(.bottom, 30)
        }.padding(.horizontal, 32).background(Color(red: 13/255, green: 13/255, blue: 13/255).ignoresSafeArea()).onAppear { pulse = true; model.beginDeviceScan() }.onChange(of: model.bluetooth.state) { state in if case .connected = state, model.pendingDeviceName != nil { model.finishDeviceConnection() } }.animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulse)
    }
}

struct MattressMainView: View {
    @EnvironmentObject var model: AppModel
    var body: some View {
        VStack(spacing: 0) {
            Group { switch model.mattressTab { case 1: MattressReportView(); case 2: MattressProfileView(); default: MattressControlView() } }.frame(maxWidth: .infinity, maxHeight: .infinity)
            HStack(spacing: 0) { MattressBottomTab(index: 0, normal: "mattress_nav_home", selected: "mattress_nav_home_selected"); MattressBottomTab(index: 1, normal: "mattress_nav_sleep", selected: "mattress_nav_sleep_selected"); MattressBottomTab(index: 2, normal: "mattress_nav_mine", selected: "mattress_nav_mine_selected") }.frame(height: 72).background(Color(red: 13/255, green: 13/255, blue: 13/255))
        }.background(AppTheme.background.ignoresSafeArea()).preferredColorScheme(.dark)
    }
}

private struct MattressBottomTab: View {
    @EnvironmentObject var model: AppModel
    let index: Int, normal: String, selected: String
    var body: some View { Button { model.mattressTab = index } label: { VStack(spacing: 4) { Image(model.mattressTab == index ? selected : normal).resizable().scaledToFit().frame(width: 24, height: 24); Circle().fill(AppTheme.cyan).frame(width: 5, height: 5).opacity(model.mattressTab == index ? 1 : 0) }.frame(maxWidth: .infinity, maxHeight: .infinity).padding(.top, 10).padding(.bottom, 8) }.buttonStyle(.plain) }
}

private struct MattressControlView: View {
    @EnvironmentObject var model: AppModel
    var body: some View {
        VStack(spacing: 0) {
            MattressHeader()
            MattressModeSelector()
            ScrollView { if model.mattressAutomatic { MattressAutomaticView() } else { MattressManualView() } }.padding(.top, 10)
        }.background(AppTheme.background.ignoresSafeArea()).alert("提示", isPresented: Binding(get: { model.toast != nil }, set: { if !$0 { model.toast = nil } })) { Button("确定") { model.toast = nil } } message: { Text(model.toast ?? "") }
    }
}

private struct MattressHeader: View {
    @EnvironmentObject var model: AppModel
    var body: some View {
        HStack(spacing: 6) {
            Button { model.showDeviceList() } label: { Image(systemName: "chevron.left").frame(width: 32, height: 32) }
            Text("BOP").font(.system(size: 18)); Spacer()
            Button { } label: { Image(systemName: "pencil").foregroundStyle(AppTheme.secondary).frame(width: 28, height: 30) }
            HStack(spacing: 2) { ForEach(0..<2) { side in Button(side == 0 ? model.leftBedName : model.rightBedName) { model.mattressSide = side }.font(.system(size: 12)).foregroundStyle(model.mattressSide == side ? .white : AppTheme.secondary).frame(maxWidth: .infinity, minHeight: 24).background(model.mattressSide == side ? Color(red: 40/255, green: 45/255, blue: 54/255) : .clear).clipShape(RoundedRectangle(cornerRadius: 5)) } }.padding(3).frame(width: 108, height: 30).background(Color(red: 18/255, green: 21/255, blue: 27/255)).clipShape(RoundedRectangle(cornerRadius: 7))
            Button { } label: { Image(systemName: "gearshape.fill").foregroundStyle(AppTheme.secondary).frame(width: 32, height: 32) }
            if !model.mattressAutomatic { Button { model.toast = "拖动滑块调节各分区压力，完成后可保存为记忆。" } label: { Text("?").font(.system(size: 14)).foregroundStyle(AppTheme.secondary).frame(width: 28, height: 28).background(AppTheme.card).clipShape(Circle()) } }
        }.padding(.horizontal, 20).frame(height: 48)
    }
}

private struct MattressModeSelector: View {
    @EnvironmentObject var model: AppModel
    var body: some View {
        HStack(spacing: 8) { modeButton("自动模式", selected: model.mattressAutomatic) { model.mattressAutomatic = true }; modeButton("手动调节", selected: !model.mattressAutomatic) { model.mattressAutomatic = false } }.padding(4).frame(height: 48).background(Color(red: 17/255, green: 20/255, blue: 26/255)).clipShape(RoundedRectangle(cornerRadius: 10)).padding(.horizontal, 20).padding(.top, 4)
    }
    private func modeButton(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(title, action: action).font(.system(size: 14)).foregroundStyle(selected ? .white : AppTheme.secondary).frame(maxWidth: .infinity, maxHeight: .infinity).background(selected ? Color(red: 38/255, green: 43/255, blue: 51/255) : .clear).clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct MattressAutomaticView: View {
    @EnvironmentObject var model: AppModel
    private var zoneNames: [String] { model.mattressSupportsSixZones ? ["肩", "背", "腰", "腰/臀", "臀", "腿"] : ["肩/背", "腰", "臀"] }
    var body: some View {
        VStack(spacing: 12) {
            if model.mattressSupportsVitals { MattressVitalsView(showValues: false) }
            MattressBodyAnimation().frame(height: 150).frame(maxWidth: .infinity).background(Color(red: 8/255, green: 12/255, blue: 24/255)).clipShape(RoundedRectangle(cornerRadius: 12))
            HStack(spacing: 6) { ForEach(0..<model.mattressZoneCount, id: \.self) { i in VStack(spacing: 3) { Text(zoneNames[i]).font(.system(size: 11)).foregroundStyle(Color(red: 209/255, green: 213/255, blue: 219/255)); Text("\(model.mattressZones[i])").font(.system(size: 11)).foregroundStyle(.white) }.frame(maxWidth: .infinity).frame(height: 62).background(AppTheme.card).clipShape(RoundedRectangle(cornerRadius: 9)) } }
            Text(model.activeMattressFunction == nil ? "自适应调节中" : "自动功能运行中").font(.system(size: 13, weight: .bold)).foregroundStyle(AppTheme.cyan).frame(maxWidth: .infinity).frame(height: 42).background(AppTheme.cyan.opacity(0.08)).clipShape(RoundedRectangle(cornerRadius: 10))
            Text("自动功能").font(.system(size: 12)).foregroundStyle(AppTheme.secondary).frame(maxWidth: .infinity, alignment: .leading).padding(.top, 4)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible())], spacing: 12) { ForEach(0..<4) { index in MattressFunctionCard(index: index) } }
        }.padding(.horizontal, 20).padding(.bottom, 24)
    }
}

private struct MattressBodyAnimation: UIViewRepresentable {
    func makeUIView(context: Context) -> UIImageView {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        if let url = Bundle.main.url(forResource: "mattress_body_animation", withExtension: "gif"),
           let data = try? Data(contentsOf: url), let source = CGImageSourceCreateWithData(data as CFData, nil) {
            var frames: [UIImage] = []; var duration = 0.0
            for index in 0..<CGImageSourceGetCount(source) {
                if let image = CGImageSourceCreateImageAtIndex(source, index, nil) { frames.append(UIImage(cgImage: image)) }
                let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any]
                let gif = properties?[kCGImagePropertyGIFDictionary] as? [CFString: Any]
                duration += gif?[kCGImagePropertyGIFUnclampedDelayTime] as? Double ?? gif?[kCGImagePropertyGIFDelayTime] as? Double ?? 0.1
            }
            view.animationImages = frames; view.animationDuration = max(duration, 0.1); view.startAnimating()
        }
        return view
    }
    func updateUIView(_ uiView: UIImageView, context: Context) {}
}

private struct MattressVitalsView: View {
    var showValues = true
    var body: some View { HStack(spacing: 12) { MattressVitalCard(icon: "heart.fill", label: "心率", value: showValues ? "68" : "--", unit: "BPM"); MattressVitalCard(icon: "lungs.fill", label: "呼吸频率", value: showValues ? "16" : "--", unit: "次/分") }.frame(height: 58) }
}
private struct MattressVitalCard: View {
    let icon: String, label: String, value: String, unit: String
    var body: some View { HStack { VStack(spacing: 2) { Image(systemName: icon).font(.system(size: 14)).foregroundStyle(AppTheme.cyan); Text(label).font(.system(size: 10)).foregroundStyle(AppTheme.secondary) }.frame(width: 48); Text(value).font(.system(size: 26, weight: .thin)); Text(unit).font(.system(size: 10)).foregroundStyle(AppTheme.secondary); Spacer() }.padding(.horizontal, 10).background(AppTheme.card).clipShape(RoundedRectangle(cornerRadius: 10)) }
}

private struct MattressFunctionCard: View {
    @EnvironmentObject var model: AppModel
    let index: Int
    private let names = ["牵引模式", "悬浮模式", "怀抱模式", "海浪模式"]
    private let details = ["分区拉伸支撑", "降低局部压迫", "柔和包裹承托", "循环起伏放松"]
    private let icons = ["mattress_traction", "mattress_float", "mattress_hug", "mattress_wave"]
    private let iconBackgrounds = [Color(red: 0/255, green: 212/255, blue: 255/255).opacity(0.14), Color.purple.opacity(0.16), Color.orange.opacity(0.16), Color.green.opacity(0.16)]
    var body: some View { VStack(spacing: 5) { Button { model.setMattressFunction(index) } label: { HStack { Image(icons[index]).resizable().scaledToFit().frame(width: 16, height: 16).padding(8).background(iconBackgrounds[index]).clipShape(RoundedRectangle(cornerRadius: 8)); VStack(alignment: .leading) { Text(names[index]).font(.system(size: 14)).foregroundStyle(.white); Text(details[index]).font(.system(size: 10)).foregroundStyle(AppTheme.secondary) }; Spacer() } }.buttonStyle(.plain); HStack { Button("−") { model.adjustMattressMinutes(index, -5) }.frame(width: 28, height: 22); Spacer(); Text(model.mattressTimeText(index)).font(.system(size: 11)).foregroundStyle(AppTheme.secondary); Spacer(); Button("+") { model.adjustMattressMinutes(index, 5) }.frame(width: 28, height: 22) }.foregroundStyle(AppTheme.secondary) }.padding(14).frame(height: 86).background(model.activeMattressFunction == index ? AppTheme.cyan.opacity(0.15) : AppTheme.card).clipShape(RoundedRectangle(cornerRadius: 10)) }
}

private struct MattressManualView: View {
    @EnvironmentObject var model: AppModel
    private var labels: [String] { model.mattressSupportsSixZones ? ["肩", "背", "腰", "腰/臀", "臀", "腿"] : ["肩/背", "腰", "臀"] }
    var body: some View { VStack(spacing: 12) { if model.mattressSupportsVitals { MattressVitalsView(showValues: true) }; ZStack(alignment: .topLeading) { Image("mattress_manual_bed").resizable().scaledToFit().frame(height: 150); HStack(spacing: 8) { Circle().fill(AppTheme.cyan).frame(width: 8, height: 8); Text("手动气压调节").font(.system(size: 12)).foregroundStyle(AppTheme.secondary) }.padding(.leading, 18).padding(.top, 14) }.frame(maxWidth: .infinity).background(AppTheme.card).clipShape(RoundedRectangle(cornerRadius: 12)); VStack(spacing: 0) { Text("分区压力").font(.system(size: 12)).foregroundStyle(AppTheme.secondary).frame(maxWidth: .infinity, alignment: .leading); ForEach(0..<model.mattressZoneCount, id: \.self) { i in HStack { Text(labels[i]).font(.system(size: 13)).frame(width: 48, alignment: .leading); AndroidPressureSlider(value: Binding(get: { model.mattressZones[i] }, set: { model.mattressZones[i] = $0 })); Text("\(model.mattressZones[i])").font(.system(size: 13)).foregroundStyle(AppTheme.secondary).frame(width: 34, alignment: .trailing) }.frame(height: 52) }; HStack(spacing: 12) { Button("重置") { model.resetMattressZones() }.buttonStyle(MattressSecondaryButtonStyle()); Button("记忆") { model.toast = "压力设置已记忆" }.buttonStyle(AuthPrimaryButtonStyle()) } }.padding(16).background(AppTheme.card).clipShape(RoundedRectangle(cornerRadius: 12)) }.padding(.horizontal, 20).padding(.bottom, 28) }
}

private struct AndroidPressureSlider: View {
    @Binding var value: Int
    var body: some View {
        GeometryReader { proxy in
            let width = max(proxy.size.width, 1)
            let thumb: CGFloat = 14
            let usable = max(width - thumb, 1)
            let x = thumb / 2 + usable * CGFloat(value) / 100
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.15)).frame(height: 4)
                Capsule().fill(Color(red: 140/255, green: 159/255, blue: 163/255)).frame(width: x, height: 4)
                Circle().fill(Color(red: 140/255, green: 159/255, blue: 163/255)).overlay(Circle().stroke(Color.white.opacity(0.7), lineWidth: 1)).frame(width: thumb, height: thumb).position(x: x, y: proxy.size.height / 2)
            }.frame(maxWidth: .infinity, maxHeight: .infinity).contentShape(Rectangle()).gesture(DragGesture(minimumDistance: 0).onChanged { gesture in
                let proposed = min(max(gesture.location.x - thumb / 2, 0), usable)
                value = Int((proposed / usable * 100).rounded())
            })
        }.frame(height: 28)
    }
}

private struct MattressSecondaryButtonStyle: ButtonStyle { func makeBody(configuration: Configuration) -> some View { configuration.label.frame(maxWidth: .infinity).frame(height: 44).foregroundStyle(AppTheme.secondary).background(Color(red: 27/255, green: 31/255, blue: 38/255)).clipShape(RoundedRectangle(cornerRadius: 10)).overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(red: 52/255, green: 58/255, blue: 69/255))) } }

private struct MattressReportView: View { var body: some View { ScrollView { VStack(alignment: .leading, spacing: 16) { Text("睡眠报告").font(.system(size: 26, weight: .bold)); Text("昨晚睡眠概览").foregroundStyle(AppTheme.secondary); HStack { Metric(title: "86", subtitle: "睡眠评分"); Metric(title: "7h 42m", subtitle: "睡眠时长") }; Text("自动调节回顾").font(.headline); Text("在您入睡期间，BOP 悄悄为您进行了 8 次自动调节，重点优化了肩背与腰臀支撑。").foregroundStyle(AppTheme.secondary).appCard() }.padding(20) }.background(AppTheme.background) } }

private struct MattressProfileView: View { @EnvironmentObject var model: AppModel; var body: some View { ScrollView { VStack(alignment: .leading, spacing: 16) { Text("我的").font(.system(size: 26, weight: .bold)); Text("我的设备").foregroundStyle(AppTheme.secondary); HStack { Image(systemName: "bed.double.fill").foregroundStyle(AppTheme.cyan); VStack(alignment: .leading) { Text(model.mattressModel).font(.headline); Text("智能床垫").font(.caption).foregroundStyle(AppTheme.secondary) }; Spacer(); Text("已连接").foregroundStyle(AppTheme.green) }.appCard(); Text("系统设置").foregroundStyle(AppTheme.secondary); ForEach(["设备设置", "睡眠偏好", "帮助与客服", "关于我们"], id: \.self) { Text($0).frame(maxWidth: .infinity, alignment: .leading).appCard() }; Button("退出登录") { model.logout() }.foregroundStyle(.red).frame(maxWidth: .infinity).padding() }.padding(20) }.background(AppTheme.background) } }

struct MainTabView: View {
    @EnvironmentObject var model: AppModel
    var body: some View { TabView(selection: $model.selectedTab) { ControlView().tabItem { Label("控制", systemImage: "slider.horizontal.3") }.tag(0); SleepReportView().tabItem { Label("报告", systemImage: "chart.bar.fill") }.tag(1); ProfileView().tabItem { Label("我的", systemImage: "person.fill") }.tag(2) }.tint(AppTheme.cyan) }
}

struct ControlView: View {
    @EnvironmentObject var model: AppModel
    var body: some View {
        NavigationStack { ScrollView { VStack(alignment: .leading, spacing: 16) {
            HStack { VStack(alignment: .leading) { Text("智能枕头").font(.title2.bold()); Text(connectionText).font(.caption).foregroundStyle(AppTheme.green) }; Spacer(); Button("设备") { model.showDeviceList() }.foregroundStyle(AppTheme.cyan) }
            Picker("模式", selection: Binding(get: { model.controlMode }, set: { model.setMode($0) })) { ForEach(AppModel.ControlMode.allCases, id: \.self) { Text($0.rawValue).tag($0) } }.pickerStyle(.segmented)
            if model.controlMode == .automatic { AutomaticPanel() } else { ManualPanel() }
            if !model.bluetooth.log.isEmpty { DisclosureGroup("BLE 活动记录") { ForEach(model.bluetooth.log.prefix(10), id: \.self) { Text($0).font(.system(.caption, design: .monospaced)).foregroundStyle(AppTheme.secondary) } }.appCard() }
        }.padding(20) }.background(AppTheme.background).navigationTitle("") }
    }
    private var connectionText: String { if case .connected = model.bluetooth.state { return "● 已连接" }; return "○ 演示/未连接" }
}

struct AutomaticPanel: View {
    @EnvironmentObject var model: AppModel
    var body: some View { VStack(alignment: .leading, spacing: 14) { Label("睡姿调节", systemImage: "person.fill").font(.headline); Text("支撑度  78 / 100 · 状态良好").foregroundStyle(AppTheme.secondary); HStack { ForEach(0..<3, id: \.self) { i in VStack(spacing: 6) { Text(["左卧", "仰卧", "右卧"][i]); Text(model.postureTargets[i].map(String.init) ?? "--").font(.title3.bold()).foregroundStyle(AppTheme.cyan); Button("学习") { model.learn(posture: i + 1, target: 60) }.font(.caption) }.frame(maxWidth: .infinity).padding(10).background(AppTheme.background).clipShape(RoundedRectangle(cornerRadius: 12)) } }; Toggle("鼾声检测", isOn: Binding(get: { model.snoreEnabled }, set: { model.snoreEnabled = $0; model.setFeature(1, enabled: $0) })).tint(AppTheme.cyan); Toggle("睡姿/压力自适应", isOn: Binding(get: { model.adaptiveEnabled }, set: { model.adaptiveEnabled = $0; model.setFeature(2, enabled: $0) })).tint(AppTheme.cyan); if model.snoreDetected { Text("正在检测鼾声").foregroundStyle(.orange).appCard() } }.appCard() }
}

struct ManualPanel: View {
    @EnvironmentObject var model: AppModel
    var body: some View { VStack(alignment: .leading, spacing: 14) { Label("气囊调节", systemImage: "slider.horizontal.3").font(.headline); Text("选择气囊腔进行调节").foregroundStyle(AppTheme.secondary); ZStack { Image("pillow_base").resizable().scaledToFit(); if model.selectedChamber <= 4 { Image("pillow_airbag_\(model.selectedChamber)").resizable().scaledToFit() } else { Image("pillow_airbag_back").resizable().scaledToFit() } }.frame(maxWidth: .infinity).aspectRatio(580 / 320, contentMode: .fit); HStack { ForEach(0..<5, id: \.self) { i in Button { model.selectedChamber = i + 1 } label: { VStack { Text(["左", "中1", "中2", "右", "后颈"][i]); Text(model.chamberPressures[i].map(String.init) ?? "--") } }.frame(maxWidth: .infinity).padding(8).background(model.selectedChamber == i + 1 ? AppTheme.cyan.opacity(0.2) : AppTheme.background).clipShape(RoundedRectangle(cornerRadius: 10)) } }; Text("气囊 \(model.selectedChamber) · \(model.chamberTargets[model.selectedChamber - 1])%"); Slider(value: Binding(get: { Double(model.chamberTargets[model.selectedChamber - 1]) }, set: { model.chamberTargets[model.selectedChamber - 1] = Int($0) }), in: 0...100, step: 1).tint(AppTheme.cyan); HStack { Button("应用调节") { model.setChamber(model.selectedChamber, value: model.chamberTargets[model.selectedChamber - 1]) }.buttonStyle(PrimaryButtonStyle()); Button("查询") { model.queryPressure() }.buttonStyle(.bordered) }; Button("保存当前压力") { model.savePressure() }.buttonStyle(.borderedProminent); Stepper("牵引循环次数  \(model.tractionCycles)", value: $model.tractionCycles, in: 1...15); Button("启动牵引") { model.traction(start: true) }.buttonStyle(PrimaryButtonStyle()) }.appCard() }
}

struct SleepReportView: View { var body: some View { ScrollView { VStack(alignment: .leading, spacing: 16) { Text("睡眠报告").font(.largeTitle.bold()); Text("过去 12 小时睡眠报告 · 22:00 - 06:00").foregroundStyle(AppTheme.secondary); HStack { Metric(title: "82", subtitle: "睡眠评分"); Metric(title: "7h 58m", subtitle: "睡眠时长"); Metric(title: "22%", subtitle: "深睡占比") }; Text("鼾声分析").font(.title3.bold()); HStack { Metric(title: "42 min", subtitle: "鼾声总时长"); Metric(title: "8", subtitle: "干预总次数") }; Text("健康小贴士").font(.title3.bold()); Text("侧睡有助于减少鼾声，建议继续保持侧卧睡姿。\n睡前避免饮酒，规律作息。 ").foregroundStyle(AppTheme.secondary).appCard() }.padding(20) }.background(AppTheme.background) } }

struct Metric: View { let title: String; let subtitle: String; var body: some View { VStack(spacing: 5) { Text(title).font(.title2.bold()).foregroundStyle(AppTheme.cyan); Text(subtitle).font(.caption).foregroundStyle(AppTheme.secondary) }.frame(maxWidth: .infinity).appCard() } }

struct ProfileView: View { @EnvironmentObject var model: AppModel; var body: some View { ScrollView { VStack(alignment: .leading, spacing: 16) { Text("我的").font(.largeTitle.bold()); HStack { Image(systemName: "person.circle.fill").font(.system(size: 52)).foregroundStyle(AppTheme.cyan); VStack(alignment: .leading) { Text(model.displayName).font(.title3.bold()); Text("身高 -- · 体重 --").foregroundStyle(AppTheme.secondary) }; Spacer() }.appCard(); Text("我的设备").font(.headline); HStack { Image(systemName: "bed.double.fill").foregroundStyle(AppTheme.cyan); Text("MJ-20"); Spacer(); Text("已连接").foregroundStyle(AppTheme.green) }.appCard(); Text("系统设置").font(.headline); ForEach(["APP 版本  1.0.0", "关于我们", "一键反馈", "帮助与客服"], id: \.self) { Text($0).frame(maxWidth: .infinity, alignment: .leading).appCard() }; Button("退出登录") { model.logout() }.foregroundStyle(.red).frame(maxWidth: .infinity).padding() }.padding(20) }.background(AppTheme.background) } }

