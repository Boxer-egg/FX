import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = AppSettings.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Particle Settings")
                .font(.headline)
            
            Group {
                VStack(alignment: .leading) {
                    Text("Density (Birth Rate): \(Int(settings.birthRate))")
                    Slider(value: $settings.birthRate, in: 0...200)
                }
                
                VStack(alignment: .leading) {
                    Text("Speed: \(Int(settings.speed))")
                    Slider(value: $settings.speed, in: 10...500)
                }
                
                VStack(alignment: .leading) {
                    Text("Scale: \(settings.scale, specifier: "%.2f")")
                    Slider(value: $settings.scale, in: 0.01...0.5)
                }
                
                VStack(alignment: .leading) {
                    Text("Opacity: \(Int(settings.opacity * 100))%")
                    Slider(value: $settings.opacity, in: 0.1...1.0)
                }
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 300, height: 400)
    }
}
