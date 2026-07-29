import SwiftUI

struct ReelView: View {
    let roll: FilmRoll

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(roll.frames.sorted(by: { $0.date < $1.date })) { frame in
                    FilmFrameCard(frame: frame)
                }
            }
            .padding()
        }
        .navigationTitle("\(roll.year) 年")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    RingView(year: roll.year)
                } label: {
                    Image(systemName: "circle.dotted")
                }
            }
        }
    }
}
