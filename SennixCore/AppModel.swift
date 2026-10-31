import Foundation

@MainActor
final class AppModel: ObservableObject {
    enum Route { case login, devices, main }
    enum AuthScreen { case login, register, resetPassword }
    enum ControlMode: String, CaseIterable { case automatic = "自动模式", manual = "手动模式" }

    @Published var route: Route
    @Published var authScreen: AuthScreen = .login
    @Published var usesLoginCode = false
    @Published var selectedTab = 0
    @Published var controlMode: ControlMode = .automatic
    @Published var selectedChamber = 1
    @Published var chamberTargets = [0, 0, 0, 0, 0]
    @Published var chamberPressures: [Int?] = [nil, nil, nil, nil, nil]
    @Published var postureTargets: [Int?] = [nil, nil, nil]
    @Published var learningPosture: Int?
    @Published var tractionCycles = 8
    @Published var snoreDetected = false
    @Published var snoreEnabled = false
    @Published var adaptiveEnabled = true
    @Published var displayName = "用户"
    @Published var phone = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var verificationCode = ""
    @Published var newPassword = ""
    @Published var loginCodeSeconds = 0
    @Published var registerCodeSeconds = 0
    @Published var resetCodeSeconds = 0
    @Published var toast: String?
    private var loginGeneratedCode: String?
    private var registerGeneratedCode: String?
    private var resetGeneratedCode: String?
    let bluetooth = BluetoothService()

    init() {
        route = UserDefaults.standard.bool(forKey: "signedIn") ? .devices : .login
        bluetooth.onFrame = { [weak self] command, payload in self?.handle(command: command, payload: payload) }
    }

    private var accounts: [String: String] {
        get { UserDefaults.standard.dictionary(forKey: "accounts") as? [String: String] ?? [:] }
        set { UserDefaults.standard.set(newValue, forKey: "accounts") }
    }

    func login() {
        guard phone.count == 11 else { toast = phone.isEmpty ? "请输入手机号" : "请输入有效的11位手机号"; return }
        guard let savedPassword = accounts[phone] else { toast = "该手机号尚未注册"; return }
        if usesLoginCode {
            guard !verificationCode.isEmpty else { toast = "请输入验证码"; return }
            guard verificationCode == loginGeneratedCode else { toast = "验证码不正确"; return }
        } else {
            guard !password.isEmpty else { toast = "请输入密码"; return }
            guard password == savedPassword else { toast = "密码错误"; return }
        }
        completeLogin()
    }

    func register() {
        guard phone.count == 11 else { toast = "请输入有效的11位手机号"; return }
        guard !verificationCode.isEmpty else { toast = "请输入验证码"; return }
        guard verificationCode == registerGeneratedCode else { toast = "验证码不正确"; return }
        guard password.count >= 6 else { toast = "密码不能少于6位"; return }
        guard password == confirmPassword else { toast = "两次密码不一致"; return }
        guard accounts[phone] == nil else { toast = "该手机号已注册，请直接登录"; return }
        var updatedAccounts = accounts
        updatedAccounts[phone] = password
        accounts = updatedAccounts
        completeLogin()
    }

    func sendLoginCode() {
        guard phone.count == 11 else { toast = "请先输入有效的11位手机号"; return }
        guard accounts[phone] != nil else { toast = "该手机号尚未注册"; return }
        loginGeneratedCode = makeCode()
        verificationCode = loginGeneratedCode ?? ""
        toast = "验证码已发送（测试模式：已自动填入）"
        startCountdown(\.loginCodeSeconds)
    }

    func sendRegisterCode() {
        guard phone.count == 11 else { toast = "请先输入有效的11位手机号"; return }
        registerGeneratedCode = makeCode()
        verificationCode = registerGeneratedCode ?? ""
        toast = "验证码已发送（测试模式：已自动填入）"
        startCountdown(\.registerCodeSeconds)
    }

    func sendResetCode() {
        guard phone.count == 11 else { toast = "请先输入有效的11位手机号"; return }
        guard accounts[phone] != nil else { toast = "该手机号尚未注册"; return }
        resetGeneratedCode = makeCode()
        verificationCode = resetGeneratedCode ?? ""
        toast = "验证码已发送（测试模式：已自动填入）"
        startCountdown(\.resetCodeSeconds)
    }

    func resetPassword() {
        guard phone.count == 11 else { toast = "请输入有效的11位手机号"; return }
        guard !verificationCode.isEmpty else { toast = "请输入验证码"; return }
        guard verificationCode == resetGeneratedCode else { toast = "验证码不正确"; return }
        guard newPassword.count >= 6 else { toast = "新密码不能少于6位"; return }
        var updatedAccounts = accounts
        updatedAccounts[phone] = newPassword
        accounts = updatedAccounts
        password = ""
        newPassword = ""
        showAuthScreen(.login)
        toast = "密码已重置，请重新登录"
    }

    func showAuthScreen(_ screen: AuthScreen) {
        authScreen = screen
        usesLoginCode = false
        verificationCode = ""
        password = ""
        confirmPassword = ""
        newPassword = ""
    }

    func toggleLoginMethod() {
        usesLoginCode.toggle()
        verificationCode = ""
        password = ""
    }

    private func completeLogin() {
        UserDefaults.standard.set(true, forKey: "signedIn")
        UserDefaults.standard.set(phone, forKey: "signedInPhone")
        route = .devices
    }

    private func makeCode() -> String { String(format: "%06d", Int.random(in: 0...999_999)) }

    private func startCountdown(_ keyPath: ReferenceWritableKeyPath<AppModel, Int>) {
        self[keyPath: keyPath] = 60
        Task { @MainActor [weak self] in
            while let self, self[keyPath: keyPath] > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { return }
                self[keyPath: keyPath] -= 1
            }
        }
    }
    func enterDemo() { route = .main }
    func logout() { UserDefaults.standard.set(false, forKey: "signedIn"); route = .login; selectedTab = 0 }

    func setMode(_ mode: ControlMode) {
        controlMode = mode
        bluetooth.send(command: 0xF7, payload: [mode == .automatic ? 0x02 : 0x01])
        if mode == .automatic { bluetooth.send(command: 0xE7) } else { queryPressure() }
    }

    func setOverall(_ value: Int) { bluetooth.send(command: 0xF4, payload: [0x01, UInt8(value)]) }
    func setChamber(_ index: Int, value: Int) {
        chamberTargets[index - 1] = value; bluetooth.send(command: 0xF3, payload: [UInt8(index), UInt8(value)])
    }
    func queryPressure() { bluetooth.send(command: 0xF2) }
    func savePressure() { bluetooth.send(command: 0xF5) }
    func traction(start: Bool) { bluetooth.send(command: 0xFD, payload: [start ? 0x01 : 0x00, UInt8(tractionCycles)]) }
    func learn(posture: Int, target: Int) {
        learningPosture = posture; bluetooth.send(command: 0xE6, payload: [0x01, UInt8(posture), UInt8(target)])
    }
    func clear(posture: Int) { bluetooth.send(command: 0xE6, payload: [0x04, UInt8(posture), 0]) }
    func setFeature(_ feature: UInt8, enabled: Bool) { bluetooth.send(command: 0xE7, payload: [feature, enabled ? 1 : 0]) }

    private func handle(command: UInt8, payload: [UInt8]) {
        switch command {
        case 0xF8: if let value = payload.first { snoreDetected = value == 1 }
        case 0xE7 where payload.count >= 2:
            snoreEnabled = payload[0] == 1; adaptiveEnabled = payload[1] == 1
        case 0xF2 where payload.count >= 5:
            chamberPressures = payload.prefix(5).reversed().map { $0 == 0xFF ? nil : Int($0) }
        case 0xE6 where payload.count >= 3:
            postureTargets = payload.suffix(3).map { $0 == 0xFF ? nil : Int($0) }; learningPosture = nil
        default: break
        }
    }
}

