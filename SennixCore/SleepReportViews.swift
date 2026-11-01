import SwiftUI

private enum ReportPeriod: String, CaseIterable {
    case daily = "日报"
    case weekly = "周报"
}

private enum ReportPalette {
    static let orange = Color(red: 249 / 255, green: 115 / 255, blue: 22 / 255)
    static let blue = Color(red: 56 / 255, green: 189 / 255, blue: 248 / 255)
    static let purple = Color(red: 168 / 255, green: 85 / 255, blue: 247 / 255)
    static let muted = Color(red: 107 / 255, green: 114 / 255, blue: 128 / 255)
}

struct PillowSleepReportView: View {
    @State private var period: ReportPeriod = .daily
    @State private var selectedDay = 4

    private let days = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]
    private let scores = [78, 75, 80, 85, 82, 79, 76]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                reportHeader(title: "睡眠报告", trailing: "MJ-20", subtitle: "鼾声干预报告")
                ReportSegmentedPicker(selection: $period)
                if period == .daily { dailyReport } else { weeklyReport }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 28)
        }
        .background(AppTheme.background.ignoresSafeArea())
    }

    private var dailyReport: some View {
        VStack(alignment: .leading, spacing: 16) {
            DayPicker(days: days, selection: $selectedDay)
            ScoreSummary(score: scores[selectedDay], items: [
                ("7h 58m", "睡眠时长"), ("22%", "深睡占比")
            ])
            Text("过去 12 小时睡眠报告 · 22:00 - 06:00")
                .font(.system(size: 12)).foregroundStyle(AppTheme.secondary).frame(maxWidth: .infinity)
            ReportSectionTitle("睡姿时长分布")
            ReportGrid(items: [
                ("2h 24m", "仰睡时间", "30%"),
                ("4h 38m", "侧睡时间", "58%"),
                ("58 min", "离枕", "12%")
            ], columns: 3)
            ReportGrid(items: [
                ("14", "体位转动", "次"),
                ("22%", "深睡占比", ""),
                ("30%", "仰睡占比", ""),
                ("58%", "侧睡占比", "")
            ], columns: 2)
            ReportSectionTitle("鼾声分析")
            ReportGrid(items: [
                ("42 min", "鼾声总时长", ""),
                ("18", "打鼾频次", "次"),
                ("72 dB", "鼾声强度峰值", ""),
                ("8", "干预总次数", "次"),
                ("83%", "有效干预率", "")
            ], columns: 2)
            ReportCard {
                Label("温馨提示", systemImage: "info.circle.fill").foregroundStyle(ReportPalette.orange)
                Text("本次睡眠您有 42 分钟处于打鼾状态，占整体睡眠的 9%，鼾声较大。系统针对本次鼾声进行了 8 次干预，总干预时长为 21 分钟。")
                    .font(.system(size: 13)).foregroundStyle(AppTheme.secondary).lineSpacing(4)
            }
            ReportSectionTitle("健康小贴士")
            ReportCard {
                TipRow("侧睡有助于减少鼾声，建议继续保持侧卧睡姿。")
                TipRow("睡前避免饮酒，酒精会加重打鼾症状。")
                TipRow("当前枕高设置较适合您的体型，建议继续保持。")
            }
        }
    }

    private var weeklyReport: some View {
        VStack(alignment: .leading, spacing: 16) {
            ReportSectionTitle("趋势图表")
            ReportLineChart(title: "睡眠质量趋势", unit: "分", values: scores, color: AppTheme.cyan, labels: days)
            ReportLineChart(title: "鼾声变化趋势", unit: "min", values: [52, 38, 45, 58, 42, 35, 48], color: ReportPalette.orange, labels: days)
            ReportLineChart(title: "干预效果趋势", unit: "%", values: [75, 68, 80, 88, 83, 78, 85], color: AppTheme.green, labels: days)
            ReportSectionTitle("关键指标环比分析")
            ComparisonTable(rows: [
                ("睡眠评分", "79", "74", "+7%"),
                ("鼾声时长", "37min", "52min", "-29%"),
                ("干预次数", "3.1次", "4.2次", "-26%"),
                ("有效干预率", "81%", "71%", "+14%")
            ])
            ReportSectionTitle("个性化改善建议")
            AdviceCard(icon: "moon.zzz.fill", title: "保持侧睡习惯", text: "本周侧睡占比提升至 52%，鼾声显著减少，建议继续保持。")
            AdviceCard(icon: "arrow.up.and.down", title: "优化枕高设置", text: "根据本周数据，建议将侧睡高度微调到 10 cm，以获得更好的颈部支撑。")
            AdviceCard(icon: "clock.fill", title: "规律作息", text: "本周入睡时间波动较大，建议固定在 22:00 - 23:00 之间入睡。")
        }
    }
}

struct MattressSleepReportView: View {
    @EnvironmentObject private var model: AppModel
    @State private var period: ReportPeriod = .daily
    @State private var selectedDay = 3

    private let days = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]
    private let scores = [86, 76, 98, 88, 84, 66, 90]
    private let weekScores = [74, 76, 79, 82, 78, 84, 81]

    private var reportAvailable: Bool { model.mattressModel == "SCM-PRO" || model.mattressModel == "SCM-ULTRA" }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    reportHeader(title: "睡眠报告", trailing: model.mattressSide == 0 ? model.leftBedName : model.rightBedName)
                    ReportSegmentedPicker(selection: $period)
                    if period == .daily { dailyReport } else { weeklyReport }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 28)
            }
            .background(AppTheme.background.ignoresSafeArea())

            if !reportAvailable {
                Color.black.opacity(0.82).ignoresSafeArea()
                VStack(spacing: 10) {
                    Image(systemName: "chart.bar.xaxis").font(.system(size: 34)).foregroundStyle(AppTheme.secondary)
                    Text("此款暂无睡眠报告").font(.system(size: 17, weight: .bold))
                    Text("可在 SCM-PRO / SCM-ULTRA 中查看").font(.system(size: 13)).foregroundStyle(AppTheme.secondary)
                }
            }
        }
    }

    private var dailyReport: some View {
        VStack(alignment: .leading, spacing: 16) {
            DayPicker(days: days, selection: $selectedDay)
            ScoreSummary(score: scores[selectedDay], items: [
                ("56%", "睡眠质量"), ("86%", "睡眠环比"), ("8h 34m", "睡眠时长")
            ])
            ReportCard {
                Label("自动调节回顾", systemImage: "checkmark.circle.fill").foregroundStyle(AppTheme.green)
                Text("在您入睡期间，BOP 悄悄为您进行了 22 次自动调节，重点优化了肩背与腰臀支撑。")
                    .font(.system(size: 13)).foregroundStyle(AppTheme.secondary)
            }
            ReportSectionTitle("健康检查")
            HStack(spacing: 5) {
                ForEach(["心率", "坐起次数", "翻身次数", "睡眠阶段", "呼吸"], id: \.self) { item in
                    VStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(AppTheme.green)
                        Text(item).font(.system(size: 10)).foregroundStyle(AppTheme.secondary).lineLimit(1).minimumScaleFactor(0.7)
                    }.frame(maxWidth: .infinity)
                }
            }.padding(.vertical, 10)
            ReportSectionTitle("生理指标")
            ReportCard {
                ValueRow("静息心率", value: "61 bpm")
                ValueRow("翻身次数", value: "16次")
                ValueRow("坐起次数", value: "3次")
            }
            ReportSectionTitle("睡眠阶段")
            SleepStageBar()
            ReportSectionTitle("睡姿统计")
            ReportGrid(items: [
                ("5h 02m", "左侧睡", "59%"),
                ("2h 08m", "右侧睡", "25%"),
                ("1h 24m", "仰睡", "16%")
            ], columns: 3)
            ReportCard {
                Text("AI分析").font(.system(size: 14, weight: .semibold))
                Text("昨夜翻身次数较少，睡姿整体稳定，深度睡眠提升了 15%。自动调节系统在整夜进行了 20 次睡姿优化。")
                    .font(.system(size: 13)).foregroundStyle(AppTheme.secondary).lineSpacing(4)
                Text("基于睡眠健康模型与大规模睡眠数据建立的个性化分析引擎。")
                    .font(.system(size: 10)).foregroundStyle(ReportPalette.muted)
            }
        }
    }

    private var weeklyReport: some View {
        VStack(alignment: .leading, spacing: 16) {
            ReportGrid(items: [
                ("79", "周均评分", ""),
                ("8.0h", "周均睡眠时长", ""),
                ("15", "周均翻身次数", "次"),
                ("154", "自动调节总次数", "次")
            ], columns: 2)
            ReportSectionTitle("趋势图表")
            ReportLineChart(title: "睡眠评分趋势", unit: "分", values: weekScores, color: AppTheme.cyan, labels: days)
            ReportLineChart(title: "睡眠时长趋势", unit: "%", values: [71, 75, 82, 85, 79, 86, 81], color: AppTheme.green, labels: days)
            ReportLineChart(title: "翻身次数趋势", unit: "次", values: [19, 17, 16, 14, 15, 12, 13], color: ReportPalette.orange, labels: days)
            ReportLineChart(title: "自动调节趋势", unit: "次", values: [18, 20, 22, 24, 21, 26, 23], color: ReportPalette.blue, labels: days)
            ReportCard {
                Text("本周总结").font(.system(size: 14, weight: .semibold))
                TipRow("本周睡眠评分在周四和周六达到峰值，自动调节完成度与评分变化呈正相关。")
                TipRow("翻身次数整体呈下降趋势，说明床垫支撑逐步稳定。")
                TipRow("周末睡眠时长更长，但工作日的入睡效率更好，建议维持固定入睡时段。")
            }
        }
    }
}

private func reportHeader(title: String, trailing: String, subtitle: String? = nil) -> some View {
    HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.system(size: 26, weight: .bold))
            if let subtitle { Text(subtitle).font(.system(size: 12)).foregroundStyle(AppTheme.secondary) }
        }
        Spacer()
        Text(trailing).font(.system(size: 12, weight: .semibold)).padding(.horizontal, 12).frame(height: 30)
            .background(AppTheme.card).clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.border))
    }
}

private struct ReportSegmentedPicker: View {
    @Binding var selection: ReportPeriod
    var body: some View {
        HStack(spacing: 4) {
            ForEach(ReportPeriod.allCases, id: \.self) { item in
                Button(item.rawValue) { selection = item }
                    .font(.system(size: 14, weight: selection == item ? .semibold : .regular))
                    .foregroundStyle(selection == item ? .white : AppTheme.secondary)
                    .frame(maxWidth: .infinity).frame(height: 40)
                    .background(selection == item ? Color.white.opacity(0.1) : .clear)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }.padding(4).background(AppTheme.card).clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.border))
    }
}

private struct DayPicker: View {
    let days: [String]
    @Binding var selection: Int
    var body: some View {
        HStack(spacing: 5) {
            ForEach(days.indices, id: \.self) { index in
                Button(days[index]) { selection = index }
                    .font(.system(size: 11)).foregroundStyle(selection == index ? .white : ReportPalette.muted)
                    .frame(maxWidth: .infinity).frame(height: 30)
                    .background(selection == index ? Color.white.opacity(0.12) : .clear)
                    .clipShape(RoundedRectangle(cornerRadius: 7))
            }
        }
    }
}

private struct ScoreSummary: View {
    let score: Int
    let items: [(String, String)]
    var body: some View {
        ReportCard {
            HStack(spacing: 16) {
                ZStack {
                    Circle().stroke(Color.white.opacity(0.08), lineWidth: 10)
                    Circle().trim(from: 0, to: CGFloat(score) / 100).stroke(AppTheme.cyan, style: StrokeStyle(lineWidth: 10, lineCap: .round)).rotationEffect(.degrees(-90))
                    VStack(spacing: 1) { Text("\(score)").font(.system(size: 36, weight: .thin)); Text("睡眠评分").font(.system(size: 10)).foregroundStyle(AppTheme.secondary) }
                }.frame(width: 118, height: 118)
                VStack(spacing: 12) {
                    ForEach(items.indices, id: \.self) { index in
                        HStack { Text(items[index].1).foregroundStyle(AppTheme.secondary); Spacer(); Text(items[index].0).foregroundStyle(.white) }
                            .font(.system(size: 12))
                    }
                }
            }
        }
    }
}

private struct ReportSectionTitle: View {
    let title: String
    init(_ title: String) { self.title = title }
    var body: some View { Text(title).font(.system(size: 16, weight: .semibold)).padding(.top, 2) }
}

private struct ReportCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) { content }
            .padding(14).frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.card).clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.border))
    }
}

private struct ReportGrid: View {
    let items: [(String, String, String)]
    let columns: Int
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: columns), spacing: 10) {
            ForEach(items.indices, id: \.self) { index in
                VStack(spacing: 5) {
                    HStack(spacing: 3) { Text(items[index].0).font(.system(size: 18, weight: .semibold)).foregroundStyle(AppTheme.cyan); Text(items[index].2).font(.system(size: 10)).foregroundStyle(AppTheme.secondary) }
                    Text(items[index].1).font(.system(size: 11)).foregroundStyle(AppTheme.secondary).lineLimit(1).minimumScaleFactor(0.7)
                }.frame(maxWidth: .infinity).frame(minHeight: 64).background(AppTheme.card).clipShape(RoundedRectangle(cornerRadius: 12)).overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.border))
            }
        }
    }
}

private struct ReportLineChart: View {
    let title: String
    let unit: String
    let values: [Int]
    let color: Color
    let labels: [String]
    var body: some View {
        ReportCard {
            HStack { Text(title).font(.system(size: 13, weight: .semibold)); Spacer(); Text(unit).font(.system(size: 10)).foregroundStyle(AppTheme.secondary) }
            LineChart(values: values, color: color).frame(height: 115)
            HStack { ForEach(labels.indices, id: \.self) { index in Text(labels[index]).font(.system(size: 9)).foregroundStyle(AppTheme.secondary).frame(maxWidth: .infinity) } }
        }
    }
}

private struct LineChart: View {
    let values: [Int]
    let color: Color
    var body: some View {
        GeometryReader { proxy in
            let minimum = values.min() ?? 0
            let maximum = values.max() ?? 1
            let spread = max(maximum - minimum, 1)
            ZStack {
                VStack { ForEach(0..<4, id: \.self) { _ in Spacer(); Divider().overlay(Color.white.opacity(0.07)) } }
                Path { path in
                    for index in values.indices {
                        let x = values.count > 1 ? proxy.size.width * CGFloat(index) / CGFloat(values.count - 1) : proxy.size.width / 2
                        let normalized = CGFloat(values[index] - minimum) / CGFloat(spread)
                        let y = proxy.size.height - 12 - normalized * (proxy.size.height - 24)
                        if index == 0 { path.move(to: CGPoint(x: x, y: y)) } else { path.addLine(to: CGPoint(x: x, y: y)) }
                    }
                }.stroke(color, style: StrokeStyle(lineWidth: 2.5, lineJoin: .round))
                ForEach(values.indices, id: \.self) { index in
                    let x = values.count > 1 ? proxy.size.width * CGFloat(index) / CGFloat(values.count - 1) : proxy.size.width / 2
                    let normalized = CGFloat(values[index] - minimum) / CGFloat(spread)
                    let y = proxy.size.height - 12 - normalized * (proxy.size.height - 24)
                    Circle().fill(color).frame(width: 7, height: 7).position(x: x, y: y)
                }
            }
        }
    }
}

private struct ComparisonTable: View {
    let rows: [(String, String, String, String)]
    var body: some View {
        ReportCard {
            HStack { Text("指标"); Spacer(); Text("本周").frame(width: 52); Text("上周").frame(width: 52); Text("环比").frame(width: 52) }.font(.system(size: 11)).foregroundStyle(AppTheme.secondary)
            Divider().overlay(AppTheme.border)
            ForEach(rows.indices, id: \.self) { index in
                HStack { Text(rows[index].0); Spacer(); Text(rows[index].1).frame(width: 52); Text(rows[index].2).frame(width: 52); Text(rows[index].3).foregroundStyle(AppTheme.green).frame(width: 52) }.font(.system(size: 12))
                if index < rows.count - 1 { Divider().overlay(AppTheme.border) }
            }
        }
    }
}

private struct AdviceCard: View {
    let icon: String
    let title: String
    let text: String
    var body: some View {
        ReportCard {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: icon).foregroundStyle(AppTheme.cyan).frame(width: 30, height: 30).background(AppTheme.cyan.opacity(0.12)).clipShape(Circle())
                VStack(alignment: .leading, spacing: 5) { Text(title).font(.system(size: 13, weight: .semibold)); Text(text).font(.system(size: 12)).foregroundStyle(AppTheme.secondary).lineSpacing(3) }
            }
        }
    }
}

private struct TipRow: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View { HStack(alignment: .top, spacing: 8) { Text("•").foregroundStyle(AppTheme.cyan); Text(text).font(.system(size: 12)).foregroundStyle(AppTheme.secondary).lineSpacing(3) } }
}

private struct ValueRow: View {
    let label: String
    let value: String
    init(_ label: String, value: String) { self.label = label; self.value = value }
    var body: some View { HStack { Text(label).foregroundStyle(AppTheme.secondary); Spacer(); Text(value) }.font(.system(size: 13)).frame(height: 24) }
}

private struct SleepStageBar: View {
    var body: some View {
        ReportCard {
            GeometryReader { proxy in
                HStack(spacing: 3) {
                    Rectangle().fill(ReportPalette.purple).frame(width: proxy.size.width * 0.24)
                    Rectangle().fill(AppTheme.cyan).frame(width: proxy.size.width * 0.42)
                    Rectangle().fill(ReportPalette.blue).frame(width: proxy.size.width * 0.22)
                    Rectangle().fill(ReportPalette.orange)
                }.clipShape(Capsule())
            }.frame(height: 14)
            HStack { StageLegend(color: ReportPalette.purple, text: "深睡"); StageLegend(color: AppTheme.cyan, text: "浅睡"); StageLegend(color: ReportPalette.blue, text: "REM"); StageLegend(color: ReportPalette.orange, text: "清醒") }
        }
    }
}

private struct StageLegend: View {
    let color: Color
    let text: String
    var body: some View { HStack(spacing: 4) { Circle().fill(color).frame(width: 6, height: 6); Text(text).font(.system(size: 9)).foregroundStyle(AppTheme.secondary) }.frame(maxWidth: .infinity) }
}
