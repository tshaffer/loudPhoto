import SwiftUI

struct SettingsView: View {
    @Binding var audioDuration: Double
    @Environment(\.dismiss) private var dismiss

    private let options: [Double] = [5, 10, 15]

    var body: some View {
        NavigationStack {
            Form {
                Section("Audio Capture Duration") {
                    Picker("Duration", selection: $audioDuration) {
                        ForEach(options, id: \.self) { value in
                            Text("\(Int(value))s").tag(value)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text("Audio recording starts the instant you take a photo and lasts up to this long. Tap the shutter again while it's recording to stop early.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
