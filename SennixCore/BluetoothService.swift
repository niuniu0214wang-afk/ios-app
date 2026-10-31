import CoreBluetooth
import Foundation

struct DiscoveredDevice: Identifiable, Equatable {
    let id: UUID
    let name: String
    let rssi: Int
}

@MainActor
final class BluetoothService: NSObject, ObservableObject {
    enum State: Equatable { case unavailable, idle, scanning, connecting(String), connected(String), failed(String) }

    @Published private(set) var state: State = .idle
    @Published private(set) var devices: [DiscoveredDevice] = []
    @Published private(set) var log: [String] = []
    var onFrame: ((UInt8, [UInt8]) -> Void)?

    private let serviceID = CBUUID(string: "FFF0")
    private let characteristicID = CBUUID(string: "FFF2")
    private var central: CBCentralManager!
    private var peripherals: [UUID: CBPeripheral] = [:]
    private var connectedPeripheral: CBPeripheral?
    private var channel: CBCharacteristic?
    private var scanFilter: String?

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: nil)
    }

    func scan(filter: String? = nil) {
        guard central.state == .poweredOn else { state = .unavailable; return }
        devices.removeAll(); peripherals.removeAll(); state = .scanning
        scanFilter = filter
        central.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        addLog("开始扫描 \(filter == "mattress" ? "智能床垫" : "智能枕头")")
    }

    func stopScan() { central.stopScan(); if case .scanning = state { state = .idle } }

    func connect(_ device: DiscoveredDevice) {
        guard let peripheral = peripherals[device.id] else { return }
        stopScan(); state = .connecting(device.name); connectedPeripheral = peripheral
        central.connect(peripheral)
    }

    func disconnect() {
        if let connectedPeripheral { central.cancelPeripheralConnection(connectedPeripheral) }
    }

    func send(command: UInt8, payload: [UInt8] = []) {
        guard let p = connectedPeripheral, let c = channel else { addLog("发送失败：设备未就绪"); return }
        let frame = MJ20Codec.build(command: command, payload: payload)
        p.writeValue(frame, for: c, type: c.properties.contains(.write) ? .withResponse : .withoutResponse)
        addLog("TX  \(MJ20Codec.hex(frame))")
    }

    private func addLog(_ text: String) {
        log.insert(text, at: 0); if log.count > 80 { log.removeLast(log.count - 80) }
    }
}

extension BluetoothService: CBCentralManagerDelegate {
    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Task { @MainActor in self.state = central.state == .poweredOn ? .idle : .unavailable }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                                    advertisementData: [String: Any], rssi RSSI: NSNumber) {
        Task { @MainActor in
            let name = peripheral.name ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? "未知设备"
            let isPillow = name.localizedCaseInsensitiveContains("MJ-20")
            let isMattress = ["MJ-01", "MJ-02", "MJ-06", "MJ-08"].contains(where: { name.localizedCaseInsensitiveContains($0) })
            guard isPillow || isMattress else { return }
            if let filter = self.scanFilter, (filter == "pillow") != isPillow { return }
            self.peripherals[peripheral.identifier] = peripheral
            let item = DiscoveredDevice(id: peripheral.identifier, name: name, rssi: RSSI.intValue)
            if let i = self.devices.firstIndex(where: { $0.id == item.id }) { self.devices[i] = item } else { self.devices.append(item) }
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        Task { @MainActor in peripheral.delegate = self; peripheral.discoverServices([self.serviceID]); self.addLog("已连接 \(peripheral.name ?? "MJ-20")") }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        Task { @MainActor in self.state = .failed(error?.localizedDescription ?? "连接失败") }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        Task { @MainActor in self.channel = nil; self.state = .idle; self.addLog("设备已断开") }
    }
}

extension BluetoothService: CBPeripheralDelegate {
    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        Task { @MainActor in peripheral.services?.filter { $0.uuid == self.serviceID }.forEach { peripheral.discoverCharacteristics([self.characteristicID], for: $0) } }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        Task { @MainActor in
            guard let c = service.characteristics?.first(where: { $0.uuid == self.characteristicID }) else { self.state = .failed("未找到 FFF2 特征"); return }
            self.channel = c; peripheral.setNotifyValue(true, for: c)
            self.state = .connected(peripheral.name ?? "MJ-20")
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }
        Task { @MainActor in
            self.addLog("RX  \(MJ20Codec.hex(data))")
            if let frame = MJ20Codec.parse(data) { self.onFrame?(frame.command, frame.payload) }
        }
    }
}

