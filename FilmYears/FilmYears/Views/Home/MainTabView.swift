import SwiftUI

enum HomeTab: String, CaseIterable {
    case list = "🎞️ 胶卷列表"
    case ring = "◎ 年轮总览"
}

struct MainTabView: View {
    @State private var selectedTab: HomeTab = .list

    var body: some View {
        TabView(selection: $selectedTab) {
            FilmRollListView()
                .tabItem {
                    Label("胶卷列表", systemImage: "film.stack")
                }
                .tag(HomeTab.list)
                .tint(.accentColor)

            RingOverviewView()
                .tabItem {
                    Label("年轮总览", systemImage: "circle.dotted")
                }
                .tag(HomeTab.ring)
                .tint(.accentColor)
        }
    }
}
