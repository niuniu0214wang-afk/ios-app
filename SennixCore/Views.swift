import SwiftUI

struct RootView: View {
    @EnvironmentObject var model: AppModel
    var body: some View {
        Group { switch model.route { case .login: LoginView(); case .devices: DeviceListView(); case .main: MainTabView() } }
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
                .keyboardType(keyboard).textContentType(keyboard == .phonePad ? .telephoneNumber : nil)
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
        NavigationStack { VStack(alignment: .leading, spacing: 18) {
            HStack { VStack(alignment: .leading) { Text("设备清单").font(.largeTitle.bold()); Text("连接并管理您的智能设备").foregroundStyle(AppTheme.secondary) }; Spacer(); Button { model.bluetooth.scan() } label: { Image(systemName: "plus").font(.title2).foregroundStyle(AppTheme.cyan).frame(width: 44, height: 44).background(AppTheme.card).clipShape(Circle()) } }
            Text("我的设备").font(.caption).foregroundStyle(AppTheme.secondary)
            if model.bluetooth.devices.isEmpty { Spacer(); VStack(spacing: 10) { Image(systemName: "wave.3.right").font(.system(size: 48)).foregroundStyle(.gray); Text("暂无设备"); Text("点击右上角 + 添加设备").font(.caption).foregroundStyle(AppTheme.secondary); if case .scanning = model.bluetooth.state { ProgressView("正在扫描…") } }.frame(maxWidth: .infinity); Spacer() }
            else { ForEach(model.bluetooth.devices) { device in Button { model.bluetooth.connect(device) } label: { HStack { Image("pillow_base").resizable().scaledToFit().frame(width: 64, height: 42); VStack(alignment: .leading) { Text(device.name); Text("RSSI \(device.rssi)").font(.caption).foregroundStyle(AppTheme.secondary) }; Spacer(); Image(systemName: "chevron.right") } }.appCard() } }
            Button("使用演示设备") { model.enterDemo() }.buttonStyle(PrimaryButtonStyle())
        }.padding(20).navigationTitle("").toolbar { ToolbarItem(placement: .topBarTrailing) { if case .scanning = model.bluetooth.state { Button("停止") { model.bluetooth.stopScan() } } } }.background(AppTheme.background) }
    }
}

struct MainTabView: View {
    @EnvironmentObject var model: AppModel
    var body: some View { TabView(selection: $model.selectedTab) { ControlView().tabItem { Label("控制", systemImage: "slider.horizontal.3") }.tag(0); SleepReportView().tabItem { Label("报告", systemImage: "chart.bar.fill") }.tag(1); ProfileView().tabItem { Label("我的", systemImage: "person.fill") }.tag(2) }.tint(AppTheme.cyan) }
}

struct ControlView: View {
    @EnvironmentObject var model: AppModel
    var body: some View {
        NavigationStack { ScrollView { VStack(alignment: .leading, spacing: 16) {
            HStack { VStack(alignment: .leading) { Text("智能枕头").font(.title2.bold()); Text(connectionText).font(.caption).foregroundStyle(AppTheme.green) }; Spacer(); Button("设备") { model.route = .devices }.foregroundStyle(AppTheme.cyan) }
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

