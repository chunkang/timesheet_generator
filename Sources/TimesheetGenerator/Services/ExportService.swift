import Foundation
import AppKit

enum ExportFormat: String, CaseIterable, Identifiable {
    case csv = "CSV"
    case pdf = "PDF"

    var id: String { rawValue }

    var fileExtension: String {
        switch self {
        case .csv: "csv"
        case .pdf: "pdf"
        }
    }
}

struct ExportService {
    static func generateCSV(entries: [TimesheetEntry]) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        var lines: [String] = []
        lines.append("Date,Source,Project,Description,Duration (hours),Category")

        let sorted = entries.sorted { $0.date < $1.date }
        for entry in sorted {
            let date = dateFormatter.string(from: entry.date)
            let source = entry.source.rawValue
            let project = csvEscape(entry.project)
            let description = csvEscape(entry.description)
            let hours = String(format: "%.2f", entry.duration / 3600)
            let category = csvEscape(entry.category)
            lines.append("\(date),\(source),\(project),\(description),\(hours),\(category)")
        }

        return lines.joined(separator: "\n")
    }

    static func generatePDF(entries: [TimesheetEntry], from startDate: Date, to endDate: Date) -> Data {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 50
        let pdfData = NSMutableData()
        var mediaBox = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            return Data()
        }

        var currentY: CGFloat = pageHeight - margin

        func startNewPage() {
            if currentY < pageHeight - margin {
                context.endPage()
            }
            context.beginPage(mediaBox: &mediaBox)
            currentY = pageHeight - margin
        }

        func drawText(_ text: String, x: CGFloat, y: CGFloat, font: NSFont, color: NSColor = .black) {
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: color
            ]
            let attrString = NSAttributedString(string: text, attributes: attributes)
            let line = CTLineCreateWithAttributedString(attrString)

            context.saveGState()
            context.textMatrix = .identity
            context.translateBy(x: 0, y: 0)
            context.textPosition = CGPoint(x: x, y: y)
            CTLineDraw(line, context)
            context.restoreGState()
        }

        func drawLine(from: CGPoint, to: CGPoint) {
            context.move(to: from)
            context.addLine(to: to)
            context.setStrokeColor(NSColor.gray.cgColor)
            context.setLineWidth(0.5)
            context.strokePath()
        }

        func checkPageBreak(needed: CGFloat) {
            if currentY - needed < margin {
                startNewPage()
            }
        }

        // Page 1
        startNewPage()

        // Title
        let title = "Timesheet Report"
        drawText(title, x: margin, y: currentY, font: .boldSystemFont(ofSize: 20))
        currentY -= 25

        let dateRange = "\(dateFormatter.string(from: startDate)) to \(dateFormatter.string(from: endDate))"
        drawText(dateRange, x: margin, y: currentY, font: .systemFont(ofSize: 12), color: .gray)
        currentY -= 30

        drawLine(from: CGPoint(x: margin, y: currentY), to: CGPoint(x: pageWidth - margin, y: currentY))
        currentY -= 20

        // Group entries by date
        let grouped = Dictionary(grouping: entries.sorted { $0.date < $1.date }) { entry -> String in
            dateFormatter.string(from: entry.date)
        }.sorted { $0.key < $1.key }

        for (dateKey, dayEntries) in grouped {
            let dailyHours = dayEntries.reduce(0) { $0 + $1.duration } / 3600

            checkPageBreak(needed: CGFloat(30 + dayEntries.count * 18))

            // Date header
            let dateHeader = "\(dateKey)  —  \(String(format: "%.1f hrs", dailyHours))"
            drawText(dateHeader, x: margin, y: currentY, font: .boldSystemFont(ofSize: 13))
            currentY -= 20

            // Column headers
            let colX: [CGFloat] = [margin, margin + 120, margin + 220, margin + 420]
            drawText("Source", x: colX[0], y: currentY, font: .boldSystemFont(ofSize: 9), color: .gray)
            drawText("Project", x: colX[1], y: currentY, font: .boldSystemFont(ofSize: 9), color: .gray)
            drawText("Description", x: colX[2], y: currentY, font: .boldSystemFont(ofSize: 9), color: .gray)
            drawText("Hours", x: colX[3], y: currentY, font: .boldSystemFont(ofSize: 9), color: .gray)
            currentY -= 14

            for entry in dayEntries {
                checkPageBreak(needed: 18)

                let hours = String(format: "%.2f", entry.duration / 3600)
                let desc = String(entry.description.prefix(40))

                drawText(entry.source.rawValue, x: colX[0], y: currentY, font: .systemFont(ofSize: 10))
                drawText(String(entry.project.prefix(15)), x: colX[1], y: currentY, font: .systemFont(ofSize: 10))
                drawText(desc, x: colX[2], y: currentY, font: .systemFont(ofSize: 10))
                drawText(hours, x: colX[3], y: currentY, font: .systemFont(ofSize: 10))
                currentY -= 16
            }

            currentY -= 10
        }

        // Summary section
        checkPageBreak(needed: 80)
        currentY -= 10
        drawLine(from: CGPoint(x: margin, y: currentY), to: CGPoint(x: pageWidth - margin, y: currentY))
        currentY -= 25

        drawText("Summary", x: margin, y: currentY, font: .boldSystemFont(ofSize: 14))
        currentY -= 22

        let totalHours = entries.reduce(0) { $0 + $1.duration } / 3600
        drawText("Total Hours: \(String(format: "%.1f", totalHours))", x: margin, y: currentY, font: .systemFont(ofSize: 12))
        currentY -= 18

        let bySource = Dictionary(grouping: entries) { $0.source }
        for (source, sourceEntries) in bySource.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            let sourceHours = sourceEntries.reduce(0) { $0 + $1.duration } / 3600
            drawText("  \(source.rawValue): \(String(format: "%.1f hrs", sourceHours))", x: margin, y: currentY, font: .systemFont(ofSize: 11), color: .darkGray)
            currentY -= 16
        }

        context.endPage()
        context.closePDF()

        return pdfData as Data
    }

    static func defaultFilename(from startDate: Date, to endDate: Date, format: ExportFormat) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "Timesheet_\(formatter.string(from: startDate))_to_\(formatter.string(from: endDate)).\(format.fileExtension)"
    }

    @MainActor
    static func saveWithPanel(data: Data, defaultName: String, fileExtension: String) async -> Bool {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = defaultName
        panel.allowedContentTypes = fileExtension == "pdf"
            ? [.pdf]
            : [.commaSeparatedText]
        panel.canCreateDirectories = true

        let response = panel.runModal()
        guard response == .OK, let url = panel.url else { return false }

        do {
            try data.write(to: url)
            return true
        } catch {
            return false
        }
    }

    private static func csvEscape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return value
    }
}
