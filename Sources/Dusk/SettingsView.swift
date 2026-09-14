import SwiftUI
import DuskCore

private enum DuskStyle {
    static let ink = Color(red: 0.12, green: 0.16, blue: 0.20)
    static let teal = Color(red: 0.15, green: 0.43, blue: 0.46)
    static let paper = Color(red: 0.95, green: 0.96, blue: 0.97)
}

struct SettingsView: View {
    @ObservedObject var model: AppModel
    @State private var simulatedAngle = 110.0
    @State private var simulating = false

    private var displayAngle: Double { simulating ? simulatedAngle : (model.angle ?? 110) }
    private var previewProgress: Double { model.curve.progress(angle: displayAngle) }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                HStack(spacing: 12) {
                    Image(systemName: "moon.haze.fill")
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(DuskStyle.teal)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Dusk").font(.system(size: 29, weight: .semibold, design: .rounded))
                        Text("A softer way to close your Mac.").font(.system(size: 13)).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Toggle("Enabled", isOn: $model.enabled)
                    .toggleStyle(.switch).controlSize(.small)
                    .tint(DuskStyle.teal).padding(.top, 10)
            }

            HStack(alignment: .top, spacing: 28) {
                VStack(alignment: .leading, spacing: 10) {
                    DesktopPreview(output: model.curve.output(progress: previewProgress, style: model.effectiveStyle))
                        .frame(height: 210)
                    HStack(spacing: 8) {
                        Image(systemName: model.effectStyle.symbol).foregroundStyle(DuskStyle.teal)
                        Text(model.effectStyle.title).font(.system(size: 14, weight: .semibold))
                        Spacer()
                    }
                    Text(model.effectStyle.detail).font(.system(size: 12)).foregroundStyle(.secondary)
                        .frame(height: 32, alignment: .topLeading)
                    HStack {
                        Label(simulating ? "Try an angle" : "Live hinge angle", systemImage: simulating ? "slider.horizontal.3" : "sensor.fill")
                            .font(.system(size: 12, weight: .medium))
                        Spacer()
                        Text("\(Int(displayAngle))°").font(.system(size: 16, weight: .medium, design: .rounded)).monospacedDigit()
                    }
                    Slider(value: Binding(get: { displayAngle }, set: { simulating = true; simulatedAngle = $0 }), in: 0...140, step: 1)
                        .tint(DuskStyle.teal)
                        .accessibilityLabel("Preview hinge angle")
                        .accessibilityValue("\(Int(displayAngle)) degrees")
                    HStack {
                        Text("Closed").font(.caption).foregroundStyle(.secondary)
                        Spacer()
                        if simulating {
                            Button("Return to live") { simulating = false }.buttonStyle(.link).font(.caption)
                        } else {
                            Text("Open").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Text("Drag to explore the effect here. Your desktop stays clear.")
                        .font(.system(size: 12)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    if model.reduceMotion {
                        Label("Reduce Motion is on. Using Fade.", systemImage: "accessibility")
                            .font(.system(size: 11)).foregroundStyle(.secondary).frame(height: 48)
                    }
                }.frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 18) {
                    Text("Choose your effect").font(.system(size: 17, weight: .semibold))
                    Picker("Effect", selection: $model.effectStyle) {
                        ForEach(EffectStyle.allCases) { style in
                            Text(style.title).tag(style)
                        }
                    }.labelsHidden().pickerStyle(.menu).controlSize(.large).accessibilityLabel("Closing effect")
                    setting("Start fading", detail: "Screen stays clear above this angle.",
                            value: $model.startAngle, range: 30...100, label: "\(Int(model.startAngle))°")
                    setting("Reach darkness", detail: "Full effect near the closed position.",
                            value: $model.darkAngle, range: 2...25, label: "\(Int(model.darkAngle))°")
                    setting("Darkness", detail: nil, value: $model.maximumDim, range: 0.3...0.98,
                            label: "\(Int((model.maximumDim * 100).rounded()))%", step: 0.01)
                    setting("Blur", detail: nil, value: $model.blurStrength, range: 0...1,
                            label: "\(Int((model.blurStrength * 100).rounded()))%", step: 0.01)
                        .disabled(!model.effectiveStyle.usesBlur)
                    Button("Restore defaults") { model.resetDefaults() }
                        .buttonStyle(.link).font(.system(size: 12))
                }.frame(width: 240)
            }

            Divider()
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 6) {
                        Circle().fill(model.angle != nil && model.enabled ? DuskStyle.teal : Color.secondary).frame(width: 6, height: 6)
                        Text(model.status).font(.system(size: 12, weight: .semibold))
                    }
                    Text(model.angle == nil ? model.sensorMessage : "Built-in display only. Reopen your lid to clear.")
                        .font(.system(size: 11)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Button(model.previewing ? "Stop preview" : "Preview on screen") {
                    if model.previewing { model.stopPreview() } else { model.preview() }
                }
                .buttonStyle(.borderedProminent).tint(DuskStyle.teal).controlSize(.large)
                .help("Runs the selected effect for four seconds, then returns to the live hinge angle.")
            }
            HStack {
                Text(model.hotkeyAvailable ? "Pause anytime with ⌃⌥⌘K" : "Pause anytime from the Dusk menu bar icon")
                Spacer()
                Text("Preview returns to live after 4 seconds")
            }.font(.system(size: 10)).foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(width: 780, height: 640, alignment: .top)
        .background(DuskStyle.paper)
        .foregroundStyle(DuskStyle.ink)
        .preferredColorScheme(.light)
        .onExitCommand { model.pause() }
    }

    private func setting(_ title: String, detail: String?, value: Binding<Double>,
                         range: ClosedRange<Double>, label: String, step: Double = 1) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title).font(.system(size: 13, weight: .medium))
                Spacer()
                Text(label).font(.system(size: 13, weight: .medium)).monospacedDigit().foregroundStyle(DuskStyle.teal)
            }
            Slider(value: value, in: range, step: step).tint(DuskStyle.teal)
                .accessibilityLabel(title).accessibilityValue(label)
            if let detail { Text(detail).font(.system(size: 11)).foregroundStyle(.secondary) }
        }
    }
}
