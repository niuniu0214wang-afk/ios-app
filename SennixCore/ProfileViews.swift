import SwiftUI
import PhotosUI
import UIKit

private enum ProfileDestination: Hashable {
    case edit, device, snore, about, feedback, help, account, version
}

struct PillowAlignedProfileView: View {
    @EnvironmentObject private var model: AppModel
    @AppStorage("profileName") private var name = "用户"
    @AppStorage("profileHeight") private var height = "175"
    @AppStorage("profileWeight") private var weight = "65"
    @State private var confirmLogout = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("我的").font(.system(size: 26, weight: .bold)).padding(.bottom, 4)
                    NavigationLink(value: ProfileDestination.edit) {
                        HStack(spacing: 14) {
                            ProfileAvatar(size: 58)
                            VStack(alignment: .leading, spacing: 5) {
                                Text(name.isEmpty ? "用户" : name).font(.system(size: 18, weight: .bold)).foregroundStyle(.white)
                                Text("身高 \(height.isEmpty ? "--" : height) · 体重 \(weight.isEmpty ? "--" : weight)").font(.system(size: 13)).foregroundStyle(AppTheme.secondary)
                            }
                            Spacer(); ProfileChevron()
                        }.profileCard()
                    }.buttonStyle(.plain)

                    ProfileSectionLabel("我的设备")
                    NavigationLink(value: ProfileDestination.device) {
                        HStack(spacing: 14) {
                            Image(systemName: pillowIcon).font(.system(size: 24)).foregroundStyle(AppTheme.cyan).frame(width: 42, height: 42).background(AppTheme.cyan.opacity(0.1)).clipShape(Circle())
                            VStack(alignment: .leading, spacing: 4) { Text("MJ-20").font(.system(size: 15, weight: .semibold)).foregroundStyle(.white); HStack(spacing: 5) { Circle().fill(isConnected ? AppTheme.green : Color.gray).frame(width: 6, height: 6); Text(isConnected ? "已连接" : "未连接").font(.system(size: 12)).foregroundStyle(isConnected ? AppTheme.green : AppTheme.secondary) } }
                            Spacer(); ProfileChevron()
                        }.profileCard()
                    }.buttonStyle(.plain)

                    ProfileSectionLabel("枕头设置")
                    NavigationLink(value: ProfileDestination.snore) {
                        ProfileMenuRow(icon: "waveform", title: "鼾声干预", detail: "枕头专属：强度、灵敏度、干预时段")
                    }.buttonStyle(.plain)

                    ProfileSectionLabel("系统设置")
                    VStack(spacing: 0) {
                        ProfileNavigationRow(destination: .version, icon: "info.circle", title: "APP 版本", detail: appVersion)
                        ProfileDivider()
                        ProfileNavigationRow(destination: .about, icon: "building.2", title: "关于我们")
                        ProfileDivider()
                        ProfileNavigationRow(destination: .feedback, icon: "bubble.left.and.bubble.right", title: "一键反馈")
                        ProfileDivider()
                        ProfileNavigationRow(destination: .help, icon: "questionmark.circle", title: "帮助与客服")
                    }.profileCard(padding: 0)

                    ProfileLogoutButton { confirmLogout = true }
                }.padding(20).padding(.bottom, 12)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationBarHidden(true)
            .navigationDestination(for: ProfileDestination.self, destination: destination)
            .alert("退出登录", isPresented: $confirmLogout) {
                Button("取消", role: .cancel) { }
                Button("退出", role: .destructive) { model.bluetooth.disconnect(); model.logout() }
            } message: { Text("确定要退出登录吗？") }
        }
    }

    @ViewBuilder private func destination(_ item: ProfileDestination) -> some View {
        switch item {
        case .edit: EditProfileView()
        case .device: DeviceSettingsView()
        case .snore: SnoreInterventionSettingsView()
        case .about: AboutProfileView()
        case .feedback: FeedbackView()
        case .help: HelpProfileView()
        case .account: AccountSecurityView()
        case .version: VersionView()
        }
    }

    private var isConnected: Bool { if case .connected = model.bluetooth.state { return true }; return false }
    private var appVersion: String { Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0" }
    private var pillowIcon: String { if #available(iOS 17, *) { return "pillow.fill" }; return "rectangle.fill" }
}

struct MattressAlignedProfileView: View {
    @EnvironmentObject private var model: AppModel
    @AppStorage("profileName") private var name = "用户"
    @AppStorage("profileHeight") private var height = "175"
    @AppStorage("profileWeight") private var weight = "65"
    @AppStorage("profileAge") private var age = "25"
    @AppStorage("profileGender") private var gender = "male"
    @AppStorage("profileSleep") private var sleep = "side"
    @State private var confirmLogout = false
    @State private var languageMessage = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack { Text("我的").font(.system(size: 20)); Spacer(); Button("EN") { languageMessage = true }.font(.system(size: 12)).foregroundStyle(AppTheme.secondary).frame(width: 54, height: 32).background(AppTheme.card).clipShape(RoundedRectangle(cornerRadius: 8)).overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.border)) }
                    NavigationLink(value: ProfileDestination.edit) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 12) { ProfileAvatar(size: 64); VStack(alignment: .leading, spacing: 4) { Text(name.isEmpty ? "用户" : name).font(.system(size: 20, weight: .bold)).foregroundStyle(.white); Text("SmartRest 用户").font(.system(size: 14)).foregroundStyle(AppTheme.secondary) }; Spacer() }
                            HStack(spacing: 6) { ProfileBadge(height); ProfileBadge(weight); ProfileBadge(age); ProfileBadge(gender == "female" ? "女" : "男"); ProfileBadge(sleepText) }
                            Text("编辑个人信息  →").font(.system(size: 14)).foregroundStyle(AppTheme.cyan)
                        }.profileCard()
                    }.buttonStyle(.plain)

                    ProfileSectionLabel("系统")
                    VStack(spacing: 0) {
                        ProfileNavigationRow(destination: .about, icon: "info.circle", title: "关于我们", detail: "隐私政策、用户协议、版本说明")
                        ProfileDivider()
                        ProfileNavigationRow(destination: .account, icon: "person.badge.key", title: "账号与安全", detail: "注销账号、隐私授权")
                        ProfileDivider()
                        ProfileNavigationRow(destination: .help, icon: "questionmark.circle", title: "帮助与客服", detail: "连接、报告和调节说明")
                    }.profileCard(padding: 0)
                    ProfileLogoutButton { confirmLogout = true }
                }.padding(20).padding(.bottom, 12)
            }.background(AppTheme.background.ignoresSafeArea()).navigationBarHidden(true)
            .navigationDestination(for: ProfileDestination.self) { item in
                switch item {
                case .edit: EditProfileView()
                case .about: AboutProfileView()
                case .account: AccountSecurityView()
                case .help: HelpProfileView()
                default: EmptyView()
                }
            }
            .alert("退出登录", isPresented: $confirmLogout) { Button("取消", role: .cancel) { }; Button("退出登录", role: .destructive) { model.bluetooth.disconnect(); model.logout() } } message: { Text("确认退出当前账号？") }
            .alert("语言设置", isPresented: $languageMessage) { Button("确定") { } } message: { Text("中英文切换入口已放置") }
        }
    }
    private var sleepText: String { sleep == "back" ? "仰睡" : sleep == "mix" ? "混合" : "侧睡" }
}

private struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("profileName") private var name = "用户"
    @AppStorage("profileHeight") private var height = "175"
    @AppStorage("profileWeight") private var weight = "65"
    @AppStorage("profileAge") private var age = "25"
    @AppStorage("profileGender") private var gender = "male"
    @AppStorage("profileSleep") private var sleep = "side"
    @State private var avatarItem: PhotosPickerItem?
    @State private var avatarData: Data?

    var body: some View {
        ProfilePage(title: "编辑个人信息") {
            HStack { Spacer(); PhotosPicker(selection: $avatarItem, matching: .images) { VStack(spacing: 8) { ProfileAvatar(size: 82); Text("更换头像").font(.system(size: 12)).foregroundStyle(AppTheme.cyan) } }; Spacer() }
            ProfileTextField("用户名", text: $name)
            HStack { ProfileTextField("身高 (cm)", text: $height, keyboard: .numberPad); ProfileTextField("体重 (kg)", text: $weight, keyboard: .numberPad) }
            ProfileTextField("年龄", text: $age, keyboard: .numberPad)
            ChoiceRow(title: "性别", options: [("男", "male"), ("女", "female")], selection: $gender)
            ChoiceRow(title: "睡眠偏好", options: [("侧睡", "side"), ("仰睡", "back"), ("混合", "mix")], selection: $sleep)
            Button("确定") { dismiss() }.buttonStyle(PrimaryButtonStyle())
        }.task(id: avatarItem) {
            guard let data = try? await avatarItem?.loadTransferable(type: Data.self) else { return }
            avatarData = data; UserDefaults.standard.set(data, forKey: "profileAvatarData")
        }
    }
}

private struct DeviceSettingsView: View {
    @EnvironmentObject private var model: AppModel
    @AppStorage("pillowAutoMode") private var mode = "standard"
    @AppStorage("pillowDND") private var dnd = false
    @AppStorage("pillowAlarm") private var alarm = false
    var body: some View { ProfilePage(title: "设备设置") {
        ProfileStaticRow(title: "设备名称", value: "MJ-20")
        ProfileSectionLabel("自动调节模式设定")
        ChoiceRow(title: "", options: [("轻柔模式", "gentle"), ("标准模式", "standard"), ("加强模式", "enhanced")], selection: $mode)
        Toggle("勿动模式", isOn: $dnd).profileCard().tint(AppTheme.cyan)
        if dnd { ProfileStaticRow(title: "停止调节时段", value: "22:00 至 06:00") }
        Toggle("体感闹钟", isOn: $alarm).profileCard().tint(AppTheme.cyan)
        if alarm { ProfileStaticRow(title: "闹钟时间", value: "07:30") }
        ProfileSectionLabel("设备信息")
        ProfileStaticRow(title: "APP 版本", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
        ProfileStaticRow(title: "固件版本", value: "--")
        Button("解除绑定", role: .destructive) { model.bluetooth.disconnect(); model.showDeviceList() }.frame(maxWidth: .infinity).padding().background(Color.red.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 12))
    } }
}

private struct SnoreInterventionSettingsView: View {
    @EnvironmentObject private var model: AppModel
    @AppStorage("snoreLevel") private var level = "medium"
    var body: some View { ProfilePage(title: "鼾声干预") {
        VStack(alignment: .leading, spacing: 12) { Toggle("启用鼾声干预", isOn: Binding(get: { model.snoreEnabled }, set: { model.snoreEnabled = $0; model.setFeature(1, enabled: $0) })).tint(AppTheme.cyan); Text("开启后，智能枕会根据鼾声强度进行柔性高度干预。").font(.system(size: 13)).foregroundStyle(AppTheme.secondary) }.profileCard()
        ProfileSectionLabel("干预强度")
        ChoiceRow(title: "", options: [("轻柔", "gentle"), ("中等", "medium"), ("加强", "strong")], selection: $level)
    } }
}

private struct AboutProfileView: View {
    var body: some View { ProfilePage(title: "关于我们") {
        VStack(spacing: 10) { Image("app_logo").resizable().scaledToFit().frame(width: 88, height: 88); Text("SennixCore").font(.title2.bold()); Text("SMART SLEEP SYSTEM").font(.system(size: 11)).tracking(1.8).foregroundStyle(AppTheme.secondary) }.frame(maxWidth: .infinity).padding(.vertical, 12)
        ProfileSectionLabel("版本信息")
        ProfileStaticRow(title: "APP 版本", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
        ProfileStaticRow(title: "隐私政策", value: "›")
        ProfileStaticRow(title: "用户协议", value: "›")
        Text("© 2024 SennixCore. All rights reserved.").font(.system(size: 11)).foregroundStyle(AppTheme.secondary).frame(maxWidth: .infinity).padding(.top, 20)
    } }
}

private struct FeedbackView: View {
    @State private var text = ""
    @State private var sent = false
    var body: some View { ProfilePage(title: "一键反馈") {
        TextEditor(text: $text).frame(minHeight: 180).padding(8).scrollContentBackground(.hidden).background(AppTheme.card).clipShape(RoundedRectangle(cornerRadius: 12)).overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.border))
        Button("提交反馈") { sent = true }.buttonStyle(PrimaryButtonStyle()).disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }.alert("提示", isPresented: $sent) { Button("确定") { text = "" } } message: { Text("反馈功能即将上线") } }
}

private struct HelpProfileView: View {
    var body: some View { ProfilePage(title: "帮助中心") {
        ProfileSectionLabel("常见问题")
        FAQ(title: "搜索不到需要连接的设备怎么办？", answer: "1. 确认设备已通电并处于配对模式。\n2. 将手机与设备距离保持在 1 米以内。\n3. 检查手机蓝牙 / Wi-Fi 是否已开启。\n4. 尝试重启设备后再次搜索。")
        FAQ(title: "绑定时提示绑定失败怎么办？", answer: "靠近设备后重新尝试；确认固件版本和网络状态正常，必要时长按复位键 5 秒后重试。")
        ProfileSectionLabel("联系我们")
        ProfileStaticRow(title: "客服热线", value: "400-XXX-XXXX")
        Text("如有更多问题，可在 APP 中通过「我的 → 帮助与客服」提交在线工单。").font(.system(size: 13)).foregroundStyle(AppTheme.secondary).profileCard()
    } }
}

private struct AccountSecurityView: View {
    @EnvironmentObject private var model: AppModel
    @State private var deleteConfirm = false
    @State private var revokeConfirm = false
    var body: some View { ProfilePage(title: "账号与安全") {
        ProfileSectionLabel("账号与安全")
        Button { deleteConfirm = true } label: { ProfileMenuRow(icon: "person.crop.circle.badge.xmark", title: "注销账号", detail: "需要二次确认") }.buttonStyle(.plain)
        Button { revokeConfirm = true } label: { ProfileMenuRow(icon: "hand.raised", title: "撤回隐私政策同意", detail: "撤回后部分联网功能停止使用") }.buttonStyle(.plain)
        Text("账号注销会删除个人资料及相关设备绑定信息，操作不可恢复。撤回隐私政策同意后，设备连接、睡眠报告等联网功能可能无法使用。").font(.system(size: 12)).foregroundStyle(AppTheme.secondary).lineSpacing(4)
    }.alert("注销账号", isPresented: $deleteConfirm) { Button("取消", role: .cancel) { }; Button("确认注销", role: .destructive) { model.bluetooth.disconnect(); model.logout() } } message: { Text("此操作不可恢复，确认继续吗？") }.alert("撤回隐私政策同意", isPresented: $revokeConfirm) { Button("取消", role: .cancel) { }; Button("确认撤回", role: .destructive) { UserDefaults.standard.set(false, forKey: "privacyConsent") } } message: { Text("撤回后设备连接、睡眠报告等部分联网功能将停止使用。") } }
}

private struct VersionView: View { var body: some View { ProfilePage(title: "APP 版本") { ProfileStaticRow(title: "当前版本", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0") } } }

private struct ProfilePage<Content: View>: View {
    let title: String; let content: Content
    init(title: String, @ViewBuilder content: () -> Content) { self.title = title; self.content = content() }
    var body: some View { ScrollView { VStack(alignment: .leading, spacing: 16) { content }.padding(20) }.background(AppTheme.background.ignoresSafeArea()).navigationTitle(title).navigationBarTitleDisplayMode(.inline) }
}

private struct ProfileAvatar: View {
    let size: CGFloat
    var body: some View { Group { if let data = UserDefaults.standard.data(forKey: "profileAvatarData"), let image = UIImage(data: data) { Image(uiImage: image).resizable().scaledToFill() } else { Image(systemName: "person.fill").resizable().scaledToFit().padding(size * 0.24).foregroundStyle(AppTheme.cyan) } }.frame(width: size, height: size).background(AppTheme.cyan.opacity(0.1)).clipShape(Circle()).overlay(Circle().stroke(AppTheme.border)) }
}

private struct ProfileSectionLabel: View { let text: String; init(_ text: String) { self.text = text }; var body: some View { Text(text).font(.system(size: 12)).tracking(1).foregroundStyle(AppTheme.secondary).padding(.top, 6) } }
private struct ProfileChevron: View { var body: some View { Image(systemName: "chevron.right").font(.system(size: 13)).foregroundStyle(AppTheme.secondary) } }
private struct ProfileDivider: View { var body: some View { Divider().overlay(AppTheme.border).padding(.leading, 52) } }
private struct ProfileBadge: View { let text: String; init(_ text: String) { self.text = text }; var body: some View { Text(text.isEmpty ? "--" : text).font(.system(size: 10)).foregroundStyle(AppTheme.secondary).frame(maxWidth: .infinity).padding(.vertical, 6).background(Color.white.opacity(0.05)).clipShape(Capsule()) } }

private struct ProfileNavigationRow: View {
    let destination: ProfileDestination, icon: String, title: String, detail: String?
    init(destination: ProfileDestination, icon: String, title: String, detail: String? = nil) { self.destination = destination; self.icon = icon; self.title = title; self.detail = detail }
    var body: some View { NavigationLink(value: destination) { ProfileMenuRow(icon: icon, title: title, detail: detail, card: false) }.buttonStyle(.plain) }
}

private struct ProfileMenuRow: View {
    let icon: String, title: String, detail: String?, card: Bool
    init(icon: String, title: String, detail: String? = nil, card: Bool = true) { self.icon = icon; self.title = title; self.detail = detail; self.card = card }
    var body: some View { HStack(spacing: 14) { Image(systemName: icon).foregroundStyle(AppTheme.cyan).frame(width: 28); VStack(alignment: .leading, spacing: 4) { Text(title).font(.system(size: 14)).foregroundStyle(.white); if let detail { Text(detail).font(.system(size: 11)).foregroundStyle(AppTheme.secondary) } }; Spacer(); ProfileChevron() }.padding(14).frame(minHeight: 58).modifier(OptionalProfileCard(enabled: card)) }
}

private struct ProfileStaticRow: View { let title: String, value: String; var body: some View { HStack { Text(title); Spacer(); Text(value).foregroundStyle(AppTheme.secondary) }.font(.system(size: 14)).profileCard() } }
private struct ProfileLogoutButton: View { let action: () -> Void; var body: some View { Button("退出登录", role: .destructive, action: action).frame(maxWidth: .infinity).frame(height: 54).background(Color.red.opacity(0.08)).clipShape(RoundedRectangle(cornerRadius: 12)).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.25))).padding(.top, 6) } }

private struct ProfileTextField: View {
    let title: String; @Binding var text: String; let keyboard: UIKeyboardType
    init(_ title: String, text: Binding<String>, keyboard: UIKeyboardType = .default) { self.title = title; _text = text; self.keyboard = keyboard }
    var body: some View { VStack(alignment: .leading, spacing: 7) { Text(title).font(.system(size: 12)).foregroundStyle(AppTheme.secondary); TextField(title, text: $text).keyboardType(keyboard).padding(12).background(AppTheme.card).clipShape(RoundedRectangle(cornerRadius: 10)).overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.border)) }.frame(maxWidth: .infinity) }
}

private struct ChoiceRow: View {
    let title: String; let options: [(String, String)]; @Binding var selection: String
    var body: some View { VStack(alignment: .leading, spacing: 8) { if !title.isEmpty { Text(title).font(.system(size: 12)).foregroundStyle(AppTheme.secondary) }; ForEach(options, id: \.1) { option in Button { selection = option.1 } label: { HStack { Image(systemName: selection == option.1 ? "largecircle.fill.circle" : "circle").foregroundStyle(AppTheme.cyan); Text(option.0).foregroundStyle(.white); Spacer() }.frame(height: 40) }.buttonStyle(.plain) } }.profileCard() }
}

private struct FAQ: View { let title: String, answer: String; @State private var expanded = false; var body: some View { Button { withAnimation { expanded.toggle() } } label: { VStack(alignment: .leading, spacing: 10) { HStack { Text(title).foregroundStyle(.white).multilineTextAlignment(.leading); Spacer(); Image(systemName: expanded ? "chevron.up" : "chevron.down").foregroundStyle(AppTheme.secondary) }; if expanded { Text(answer).font(.system(size: 12)).foregroundStyle(AppTheme.secondary).multilineTextAlignment(.leading).lineSpacing(4) } }.profileCard() }.buttonStyle(.plain) } }

private struct OptionalProfileCard: ViewModifier { let enabled: Bool; @ViewBuilder func body(content: Content) -> some View { if enabled { content.background(AppTheme.card).clipShape(RoundedRectangle(cornerRadius: 12)).overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.border)) } else { content } } }

private extension View {
    func profileCard(padding: CGFloat = 16) -> some View { self.padding(padding).background(AppTheme.card).clipShape(RoundedRectangle(cornerRadius: 12)).overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.border)) }
}
