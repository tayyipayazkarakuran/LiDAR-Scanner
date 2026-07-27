import SwiftUI

struct ExportView: View {
    @ObservedObject var viewModel: ScanViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedFormats: Set<ExportFormat> = [.obj, .stl, .ply]
    @State private var isExporting = false
    @State private var exportError: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                headerSection
                formatSelectionSection
                exportButtonSection
            }
            .padding()
            .navigationTitle("Dışa Aktar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
            }
            .sheet(isPresented: $viewModel.showExportSheet) {
                if let url = viewModel.exportURL {
                    ShareSheet(activityItems: [url])
                }
            }
            .alert("Hata", isPresented: .constant(exportError != nil)) {
                Button("Tamam") { exportError = nil }
            } message: {
                Text(exportError ?? "")
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "square.and.arrow.down.on.square")
                .font(.system(size: 48))
                .foregroundColor(.blue)

            Text("3D Modeli Dışa Aktar")
                .font(.title2)
                .fontWeight(.semibold)

            if let mesh = viewModel.scannedMesh {
                Text("\(mesh.vertexCount) vertex • \(mesh.triangleCount) triangle")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var formatSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Çıktı Formatı")
                .font(.headline)

            ForEach(ExportFormat.allCases) { format in
                Button {
                    if selectedFormats.contains(format) {
                        if selectedFormats.count > 1 {
                            selectedFormats.remove(format)
                        }
                    } else {
                        selectedFormats.insert(format)
                    }
                } label: {
                    HStack {
                        Image(systemName: selectedFormats.contains(format)
                            ? "checkmark.circle.fill"
                            : "circle")
                            .foregroundColor(selectedFormats.contains(format) ? .blue : .gray)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(format.rawValue)
                                .fontWeight(.medium)
                            Text(format.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if let mesh = viewModel.scannedMesh {
                            Text(formatSize(mesh.estimatedFileSize(format: format)))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var exportButtonSection: some View {
        VStack(spacing: 12) {
            Button {
                exportSelectedFormats()
            } label: {
                HStack {
                    if isExporting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "square.and.arrow.down")
                        Text("Dışa Aktar (\(selectedFormats.count) dosya)")
                    }
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isExporting || selectedFormats.isEmpty)

            Text("Dosyalar geçici olarak kaydedilecek\nve paylaşım menüsü açılacak.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private func exportSelectedFormats() {
        guard let mesh = viewModel.scannedMesh else { return }
        isExporting = true

        DispatchQueue.global(qos: .userInitiated).async {
            var exportedURLs: [URL] = []
            var exportErrorOccurred: Error?

            for format in selectedFormats {
                let fileName = "Scan_\(formattedDate()).\(format.fileExtension)"
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

                do {
                    switch format {
                    case .obj: try OBJExporter.export(mesh: mesh, to: tempURL)
                    case .stl: try STLExporter.export(mesh: mesh, to: tempURL)
                    case .ply: try PLYExporter.export(mesh: mesh, to: tempURL)
                    }
                    exportedURLs.append(tempURL)
                } catch {
                    exportErrorOccurred = error
                    break
                }
            }

            DispatchQueue.main.async {
                isExporting = false

                if let error = exportErrorOccurred {
                    exportError = error.localizedDescription
                } else if !exportedURLs.isEmpty {
                    if exportedURLs.count == 1 {
                        viewModel.exportURL = exportedURLs.first
                    } else {
                        viewModel.exportURL = exportedURLs.first
                    }
                    viewModel.showExportSheet = true
                    dismiss()
                }
            }
        }
    }

    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter.string(from: Date())
    }

    private func formatSize(_ bytes: UInt64) -> String {
        if bytes < 1024 { return "\(bytes) B" }
        if bytes < 1024 * 1024 { return String(format: "%.1f KB", Double(bytes) / 1024) }
        return String(format: "%.1f MB", Double(bytes) / (1024 * 1024))
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
