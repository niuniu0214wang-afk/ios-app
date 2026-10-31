import Foundation

@MainActor
final class AppModel: ObservableObject {
    enum Route { case login, devices, main }
    enum ControlMode: String, CaseIterable { case automatic = "自动模式", manual = "手动模式" }

    @Published var route: Route
    @Published var isRegistering = false
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
    @Published var toast: String?
    let bluetooth = BluetoothService()

    init() {
        route = UserDefaults.standard.bool(forKey: "signedIn") ? .devices : .login
        bluetooth.onFrame = { [weak self] command, payload in self?.handle(command: command, payload: payload) }
    }

    func login() {
        guard !phone.isEmpty, !password.isEmpty else { toast = "请输入手机号和密码"; return }
        UserDefaults.standard.set(true, forKey: "signedIn"); route = .devices
    }

    func register() {
        guard password == confirmPassword else { toast = "两次输入的密码不一致"; return }
        login()
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

