import SwiftUI

struct RingOverviewView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("全部胶卷 · 年轮总览")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(0 ..< 3) { _ in
                            RingOverviewRow(year: 2026, filled: 19, total: 210)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("FilmYears")
        }
    }
}

private struct RingOverviewRow: View {
    let year: Int
    let filled: Int
    let total: Int

    var body: some View {
        HStack(spacing: 16) {
            RingPreview(size: 40)
                .frame(width: 40, height: 40)

            VStack(alignment: .leading) {
                Text("\(year)")
                    .font(.body).fontWeight(.semibold)
                Text("\(filled)/\(total) 帧")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

private struct RingPreview: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 4)
            Circle()
                .trim(from: 0, to: 0.3)
                .stroke(Color.accentColor, lineWidth: 4)
        }
        .frame(width: size, height: size)
    }
}
