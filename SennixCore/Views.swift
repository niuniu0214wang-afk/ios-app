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
            ScrollView { VStack(spacing: 22) {
                Spacer(minLength: 45); Image(systemName: "moon.stars.fill").font(.system(size: 52)).foregroundStyle(AppTheme.cyan)
                Text(model.isRegistering ? "创建账户" : "欢迎").font(.largeTitle.bold())
                Text(model.isRegistering ? "开始您的智能睡眠之旅" : "登录您的睡眠账户").foregroundStyle(AppTheme.secondary)
                VStack(spacing: 12) {
                    TextField("手机号", text: $model.phone).textContentType(.telephoneNumber).keyboardType(.phonePad).textFieldStyle(.roundedBorder)
                    SecureField(model.isRegistering ? "设置密码" : "密码", text: $model.password).textFieldStyle(.roundedBorder)
                    if model.isRegistering { SecureField("确认密码", text: $model.confirmPassword).textFieldStyle(.roundedBorder) }
                }.padding(.top, 12)
                Button(model.isRegistering ? "立即注册" : "登录") { model.isRegistering ? model.register() : model.login() }.buttonStyle(PrimaryButtonStyle())
                Button(model.isRegistering ? "← 已有账户？返回登录" : "还没有账户？立即注册") { model.isRegistering.toggle() }.foregroundStyle(AppTheme.cyan)
                if !model.isRegistering { Button("演示模式") { model.enterDemo() }.foregroundStyle(AppTheme.secondary) }
            }.padding(24) }.navigationBarHidden(true)
                .alert("提示", isPresented: Binding(get: { model.toast != nil }, set: { if !$0 { model.toast = nil } })) { Button("确定") { model.toast = nil } } message: { Text(model.toast ?? "") }
        }
    }
}

struct DeviceListView: View {
    @EnvironmentObject var model: AppModel
    var body: some View {
        NavigationStack { VStack(alignment: .leading, spacing: 18) {
            HStack { VStack(alignment: .leading) { Text("设备清单").font(.largeTitle.bold()); Text("连接并管理您的智能设备").foregroundStyle(AppTheme.secondary) }; Spacer(); Button { model.bluetooth.scan() } label: { Image(systemName: "plus").font(.title2).foregroundStyle(AppTheme.cyan).frame(width: 44, height: 44).background(AppTheme.card).clipShape(Circle()) } }
            Text("我的设备").font(.caption).foregroundStyle(AppTheme.secondary)
            if model.bluetooth.devices.isEmpty { Spacer(); VStack(spacing: 10) { Image(systemName: "wave.3.right").font(.system(size: 48)).foregroundStyle(.gray); Text("暂无设备"); Text("点击右上角 + 添加设备").font(.caption).foregroundStyle(AppTheme.secondary); if case .scanning = model.bluetooth.state { ProgressView("正在扫描…") } }.frame(maxWidth: .infinity); Spacer() }
            else { ForEach(model.bluetooth.devices) { device in Button { model.bluetooth.connect(device) } label: { HStack { Image(systemName: "bed.double.fill").foregroundStyle(AppTheme.cyan); VStack(alignment: .leading) { Text(device.name); Text("RSSI \(device.rssi)").font(.caption).foregroundStyle(AppTheme.secondary) }; Spacer(); Image(systemName: "chevron.right") } }.appCard() } }
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
    var body: some View { VStack(alignment: .leading, spacing: 14) { Label("气囊调节", systemImage: "slider.horizontal.3").font(.headline); Text("选择气囊腔进行调节").foregroundStyle(AppTheme.secondary); HStack { ForEach(0..<5, id: \.self) { i in Button { model.selectedChamber = i + 1 } label: { VStack { Text(["左", "中1", "中2", "右", "后颈"][i]); Text(model.chamberPressures[i].map(String.init) ?? "--") } }.frame(maxWidth: .infinity).padding(8).background(model.selectedChamber == i + 1 ? AppTheme.cyan.opacity(0.2) : AppTheme.background).clipShape(RoundedRectangle(cornerRadius: 10)) } }; Text("气囊 \(model.selectedChamber) · \(model.chamberTargets[model.selectedChamber - 1])%"); Slider(value: Binding(get: { Double(model.chamberTargets[model.selectedChamber - 1]) }, set: { model.chamberTargets[model.selectedChamber - 1] = Int($0) }), in: 0...100, step: 1).tint(AppTheme.cyan); HStack { Button("应用调节") { model.setChamber(model.selectedChamber, value: model.chamberTargets[model.selectedChamber - 1]) }.buttonStyle(PrimaryButtonStyle()); Button("查询") { model.queryPressure() }.buttonStyle(.bordered) }; Button("保存当前压力") { model.savePressure() }.buttonStyle(.borderedProminent); Stepper("牵引循环次数  \(model.tractionCycles)", value: $model.tractionCycles, in: 1...15); Button("启动牵引") { model.traction(start: true) }.buttonStyle(PrimaryButtonStyle()) }.appCard() }
}

struct SleepReportView: View { var body: some View { ScrollView { VStack(alignment: .leading, spacing: 16) { Text("睡眠报告").font(.largeTitle.bold()); Text("过去 12 小时睡眠报告 · 22:00 - 06:00").foregroundStyle(AppTheme.secondary); HStack { Metric(title: "82", subtitle: "睡眠评分"); Metric(title: "7h 58m", subtitle: "睡眠时长"); Metric(title: "22%", subtitle: "深睡占比") }; Text("鼾声分析").font(.title3.bold()); HStack { Metric(title: "42 min", subtitle: "鼾声总时长"); Metric(title: "8", subtitle: "干预总次数") }; Text("健康小贴士").font(.title3.bold()); Text("侧睡有助于减少鼾声，建议继续保持侧卧睡姿。\n睡前避免饮酒，规律作息。 ").foregroundStyle(AppTheme.secondary).appCard() }.padding(20) }.background(AppTheme.background) } }

struct Metric: View { let title: String; let subtitle: String; var body: some View { VStack(spacing: 5) { Text(title).font(.title2.bold()).foregroundStyle(AppTheme.cyan); Text(subtitle).font(.caption).foregroundStyle(AppTheme.secondary) }.frame(maxWidth: .infinity).appCard() } }

struct ProfileView: View { @EnvironmentObject var model: AppModel; var body: some View { ScrollView { VStack(alignment: .leading, spacing: 16) { Text("我的").font(.largeTitle.bold()); HStack { Image(systemName: "person.circle.fill").font(.system(size: 52)).foregroundStyle(AppTheme.cyan); VStack(alignment: .leading) { Text(model.displayName).font(.title3.bold()); Text("身高 -- · 体重 --").foregroundStyle(AppTheme.secondary) }; Spacer() }.appCard(); Text("我的设备").font(.headline); HStack { Image(systemName: "bed.double.fill").foregroundStyle(AppTheme.cyan); Text("MJ-20"); Spacer(); Text("已连接").foregroundStyle(AppTheme.green) }.appCard(); Text("系统设置").font(.headline); ForEach(["APP 版本  1.0.0", "关于我们", "一键反馈", "帮助与客服"], id: \.self) { Text($0).frame(maxWidth: .infinity, alignment: .leading).appCard() }; Button("退出登录") { model.logout() }.foregroundStyle(.red).frame(maxWidth: .infinity).padding() }.padding(20) }.background(AppTheme.background) } }

