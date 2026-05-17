import SwiftUI
import HazakuraLLMManagerCore

struct ContentView: View {
    @ObservedObject var controller: ServerController

    var body: some View {
        VStack(spacing: 0) {
            StatusHeaderView(controller: controller)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ProfileView(controller: controller)
                    ConfigurationView(controller: controller)
                    EndpointView(controller: controller)
                    CommandPreviewView(controller: controller)
                    LogsView(controller: controller)
                }
                .padding(20)
            }
        }
    }
}
