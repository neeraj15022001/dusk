import Foundation
import IOKit.hid
import QuartzCore
import DuskCore

/// Owns all IOKit handles on one worker queue; a slow HID read cannot freeze the UI.
final class HingeSensor {
    struct Reading {
        let angle: Double?
        let message: String
        let time: TimeInterval
    }

    private let queue = DispatchQueue(label: "app.dusk.hinge", qos: .userInitiated)
    private var timer: DispatchSourceTimer?
    private var device: IOHIDDevice?
    private var nextDiscovery: TimeInterval = 0
    private var failureCount = 0
    private let onReading: (Reading) -> Void

    init(onReading: @escaping (Reading) -> Void) { self.onReading = onReading }

    func start() {
        queue.async { [self] in
            guard timer == nil else { return }
            nextDiscovery = 0
            let source = DispatchSource.makeTimerSource(queue: queue)
            source.schedule(deadline: .now(), repeating: 1.0 / 30, leeway: .milliseconds(3))
            source.setEventHandler { [weak self] in self?.poll() }
            timer = source
            source.resume()
        }
    }

    func stop() {
        queue.async { [self] in
            timer?.cancel()
            timer = nil
            closeDevice()
        }
    }

    private func closeDevice() {
        if let device { IOHIDDeviceClose(device, IOOptionBits(kIOHIDOptionsTypeNone)) }
        device = nil
        failureCount = 0
    }

    private func discover() -> String? {
        let matching: [String: Any] = [
            "IOProviderClass": "IOHIDDevice",
            "PrimaryUsagePage": 0x20,
            "PrimaryUsage": 0x8A,
            "VendorID": 0x05AC
        ]
        var iterator: io_iterator_t = 0
        let result = IOServiceGetMatchingServices(kIOMainPortDefault, matching as CFDictionary, &iterator)
        guard result == KERN_SUCCESS else { return "Cannot discover hinge sensor (\(result))." }
        defer { IOObjectRelease(iterator) }
        var openError: IOReturn?
        while case let service = IOIteratorNext(iterator), service != 0 {
            let candidate = IOHIDDeviceCreate(kCFAllocatorDefault, service)
            IOObjectRelease(service)
            guard let candidate else { continue }
            let status = IOHIDDeviceOpen(candidate, IOOptionBits(kIOHIDOptionsTypeNone))
            if status == kIOReturnSuccess {
                device = candidate
                return nil
            }
            openError = status
        }
        if let openError { return "Hinge sensor could not open (\(openError)). Quit other hinge utilities and retry." }
        return "No supported hinge sensor. You can still try the preview."
    }

    private func poll() {
        let now = CACurrentMediaTime()
        if device == nil {
            guard now >= nextDiscovery else { return }
            nextDiscovery = now + 3
            if let message = discover() {
                onReading(Reading(angle: nil, message: message, time: now))
                return
            }
        }
        guard let device else { return }
        var bytes = [UInt8](repeating: 0, count: 8)
        var length = CFIndex(bytes.count)
        let status = IOHIDDeviceGetReport(device, kIOHIDReportTypeFeature, 1, &bytes, &length)
        guard status == kIOReturnSuccess,
              let angle = HingeReport.angle(from: Array(bytes.prefix(max(0, min(length, bytes.count))))) else {
            failureCount += 1
            onReading(Reading(angle: nil, message: "Hinge reading interrupted. Retrying…", time: now))
            if failureCount >= 3 { closeDevice() }
            return
        }
        failureCount = 0
        onReading(Reading(angle: angle, message: "Hinge sensor connected", time: now))
    }
}
