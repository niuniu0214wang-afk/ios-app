import SwiftUI

struct ControlSecondarySheet: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    let sheet: AppModel.ControlSheet

    var body: some View {
        NavigationStack {
            Group {
                switch sheet {
                case .postureLearning: PostureLearningSheet()
                case .postureStatus: PostureStatusSheet()
                case .wifiSetup: WiFiSetupSheet()
                case .adjusting: ProgressSheet(title: model.adjustmentMessage, autoDismiss: true)
                case .traction: TractionSheet()
                case .bedName: BedNameSheet()
                case .bedSelect: BedSelectSheet()
                case .mattressSettings: MattressSettingsSheet()
                case .manualHelp: ManualHelpSheet()
                case .memoryName: MemoryNameSheet()
                }
            }
            .background(AppTheme.background.ignoresSafeArea())
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("关闭") { dismiss() }.foregroundStyle(AppTheme.cyan) } }
        }.preferredColorScheme(.dark)
    }
}

private struct PostureLearningSheet: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var target = 60.0
    @State private var clearConfirm = false
    private var index: Int { model.selectedLearningPosture - 1 }
    private var posture: String { ["左卧", "仰卧", "右卧"][index] }
    var body: some View {
        VStack(spacing: 24) {
            Text("睡姿学习").font(.title2.bold())
            Text("\(posture) · 拖动滑块选择支撑度数值").foregroundStyle(AppTheme.secondary)
            Text("\(Int(target))").font(.system(size: 48, weight: .thin)).foregroundStyle(AppTheme.cyan)
            Slider(value: $target, in: 0...100, step: 20).tint(AppTheme.cyan)
            HStack { Text("0"); Spacer(); Text("60"); Spacer(); Text("100（每档20）") }.font(.caption).foregroundStyle(AppTheme.secondary)
            if model.postureTargets[index] != nil { Button("清除已有记忆", role: .destructive) { clearConfirm = true }.frame(maxWidth: .infinity).padding() }
            HStack { Button("取消") { dismiss() }.buttonStyle(.bordered); Button("记忆") { model.learn(posture: model.selectedLearningPosture, target: Int(target)); model.adjustmentMessage = "调节中…"; dismiss(); Task { @MainActor in try? await Task.sleep(nanoseconds: 300_000_000); model.controlSheet = .adjusting } }.buttonStyle(PrimaryButtonStyle()) }
            Spacer()
        }.padding(24).alert("清除睡姿记忆", isPresented: $clearConfirm) { Button("取消", role: .cancel) { }; Button("清除", role: .destructive) { model.clear(posture: model.selectedLearningPosture); dismiss() } } message: { Text("确认清除\(posture)记忆？") }
    }
}

private struct PostureStatusSheet: View {
    @EnvironmentObject private var model: AppModel
    var body: some View { VStack(alignment: .leading, spacing: 16) { Text("睡姿学习状态").font(.title2.bold()); ForEach(0..<3, id: \.self) { i in HStack { VStack(alignment: .leading, spacing: 5) { Text(["左卧", "仰卧", "右卧"][i]).font(.headline); Text(model.postureTargets[i] == nil ? "未完成" : "已完成").font(.caption).foregroundStyle(model.postureTargets[i] == nil ? .orange : AppTheme.green) }; Spacer(); Text("高度: \(model.postureTargets[i].map(String.init) ?? "--")").foregroundStyle(AppTheme.secondary) }.padding(16).background(AppTheme.card).clipShape(RoundedRectangle(cornerRadius: 12)).overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.border)) }; Button("重新查询") { model.queryPressure() }.buttonStyle(PrimaryButtonStyle()); Spacer() }.padding(24) }
}

private struct WiFiSetupSheet: View {
    @EnvironmentObject private var model: AppModel
    @State private var ssid = ""
    @State private var password = ""
    @State private var connecting = false
    @State private var result: String?
    var body: some View { ScrollView { VStack(alignment: .leading, spacing: 18) { Text("WiFi 配网").font(.title2.bold()); Text("连接家庭 WiFi").font(.headline); Text("通过蓝牙将网络信息发送给枕头。请使用 2.4 GHz WiFi，并保持手机靠近设备。").font(.system(size: 13)).foregroundStyle(AppTheme.secondary); TextField("WiFi 名称", text: $ssid).controlInput(); SecureField("WiFi 密码", text: $password).controlInput(); Text("当前固件的 WiFi 名称仅支持字母、数字、下划线和短横线。").font(.caption).foregroundStyle(AppTheme.secondary); if connecting { HStack { ProgressView(); Text("正在连接 WiFi…") }.frame(maxWidth: .infinity).padding() }; if let result { Text(result).foregroundStyle(result.contains("成功") ? AppTheme.green : .red).frame(maxWidth: .infinity) }; Button("开始配网") { start() }.buttonStyle(PrimaryButtonStyle()).disabled(ssid.isEmpty || connecting) }.padding(24) } }
    private func start() { guard ssid.range(of: "^[A-Za-z0-9_-]+$", options: .regularExpression) != nil else { result = "WiFi 名称格式不支持"; return }; connecting = true; result = nil; let bytes = Array((ssid + "\0" + password).utf8.prefix(250)); model.bluetooth.send(command: 0xFA, payload: bytes); Task { @MainActor in try? await Task.sleep(nanoseconds: 1_500_000_000); connecting = false; result = "配网信息已发送" } }
}

private struct ProgressSheet: View {
    @Environment(\.dismiss) private var dismiss
    let title: String; let autoDismiss: Bool
    var body: some View { VStack(spacing: 22) { Spacer(); ProgressView().scaleEffect(1.4).tint(AppTheme.cyan); Text(title).font(.headline); Spacer() }.task { if autoDismiss { try? await Task.sleep(nanoseconds: 900_000_000); dismiss() } } }
}

private struct TractionSheet: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var running = true
    var body: some View { VStack(spacing: 22) { Spacer(); Image(systemName: "arrow.up.and.down.circle.fill").font(.system(size: 68)).foregroundStyle(AppTheme.cyan); Text(running ? "牵引模式运行中" : "牵引已停止").font(.title3.bold()); Text("循环次数：\(model.tractionCycles)").foregroundStyle(AppTheme.secondary); Button(running ? "停止牵引" : "完成") { if running { model.traction(start: false); running = false } else { dismiss() } }.buttonStyle(PrimaryButtonStyle()); Spacer() }.padding(24) }
}

private struct BedNameSheet: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    var body: some View { VStack(alignment: .leading, spacing: 18) { Text("修改\(model.mattressSide == 0 ? "左床" : "右床")名称").font(.title2.bold()); Text("输入一个便于识别的床位名称").foregroundStyle(AppTheme.secondary); TextField("床位名称", text: $name).controlInput(); HStack { Button("床位管理") { dismiss(); Task { @MainActor in try? await Task.sleep(nanoseconds: 250_000_000); model.controlSheet = .bedSelect } }.buttonStyle(.bordered); Button("保存") { model.renameCurrentBed(name); dismiss() }.buttonStyle(PrimaryButtonStyle()).disabled(name.trimmingCharacters(in: .whitespaces).isEmpty) }; Spacer() }.padding(24).onAppear { name = model.mattressSide == 0 ? model.leftBedName : model.rightBedName } }
}

private struct BedSelectSheet: View {
    @EnvironmentObject private var model: AppModel
    var body: some View { VStack(alignment: .leading, spacing: 18) { Text("选择床位").font(.title2.bold()); bedCard(0, title: model.leftBedName, user: "用户 A", detail: "侧睡 · 深睡"); bedCard(1, title: model.rightBedName, user: "用户 B", detail: "仰睡 · 浅睡"); Text("选择床位后，控制和报告数据将切换到对应一侧。").font(.caption).foregroundStyle(AppTheme.secondary); Spacer() }.padding(24) }
    private func bedCard(_ side: Int, title: String, user: String, detail: String) -> some View { Button { model.mattressSide = side } label: { HStack { Image(systemName: "bed.double.fill").font(.title2).foregroundStyle(AppTheme.cyan); VStack(alignment: .leading) { Text(title).font(.headline).foregroundStyle(.white); Text("\(user) · \(detail)").font(.caption).foregroundStyle(AppTheme.secondary) }; Spacer(); Image(systemName: model.mattressSide == side ? "checkmark.circle.fill" : "circle").foregroundStyle(AppTheme.cyan) }.padding(18).background(AppTheme.card).clipShape(RoundedRectangle(cornerRadius: 12)).overlay(RoundedRectangle(cornerRadius: 12).stroke(model.mattressSide == side ? AppTheme.cyan : AppTheme.border)) }.buttonStyle(.plain) }
}

private struct MattressSettingsSheet: View {
    @EnvironmentObject private var model: AppModel
    @AppStorage("mattressDND") private var dnd = false
    @AppStorage("mattressAlarm") private var alarm = false
    var body: some View { ScrollView { VStack(alignment: .leading, spacing: 16) { Text("设备设置").font(.title2.bold()); ControlRow(title: "设备名称", value: model.mattressModel); Toggle("勿动模式", isOn: $dnd).controlCard().tint(AppTheme.cyan); if dnd { ControlRow(title: "停止调节时段", value: "22:00 至 06:00") }; Toggle("体感闹钟", isOn: $alarm).controlCard().tint(AppTheme.cyan); if alarm { ControlRow(title: "闹钟时间", value: "07:30") }; ControlRow(title: "固件版本", value: "--"); Button("返回设备列表") { model.showDeviceList() }.buttonStyle(.bordered).frame(maxWidth: .infinity) }.padding(24) } }
}

private struct ManualHelpSheet: View { var body: some View { VStack(alignment: .leading, spacing: 18) { Text("手动调节说明").font(.title2.bold()); Text("拖动滑块可单独调节肩、腰、臀、腿等区域支撑。\n\n一键变硬、适中、变软会同步全部区域的目标压力。\n\n调节完成后可点击记忆保存当前配置。").foregroundStyle(AppTheme.secondary).lineSpacing(4); Spacer() }.padding(24) } }

private struct MemoryNameSheet: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    var body: some View { VStack(alignment: .leading, spacing: 18) { Text("命名当前记忆").font(.title2.bold()); Text("输入一个便于识别的记忆名称").foregroundStyle(AppTheme.secondary); TextField("记忆名称", text: $name).controlInput(); Button("保存") { model.saveMattressMemory(name); dismiss() }.buttonStyle(PrimaryButtonStyle()).disabled(name.trimmingCharacters(in: .whitespaces).isEmpty); Spacer() }.padding(24) }
}

private struct ControlRow: View { let title: String, value: String; var body: some View { HStack { Text(title); Spacer(); Text(value).foregroundStyle(AppTheme.secondary) }.controlCard() } }
private extension View { func controlCard() -> some View { padding(16).background(AppTheme.card).clipShape(RoundedRectangle(cornerRadius: 12)).overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.border)) }; func controlInput() -> some View { padding(14).background(AppTheme.card).clipShape(RoundedRectangle(cornerRadius: 10)).overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.border)) } }
