//
//  ContentView.swift
//  VideoEdit
//
//  Created by Jigar on 02/10/23.
//

import SwiftUI
import UniformTypeIdentifiers
import QuickLook

struct ContentView: View {
    @State private var selectedURL: URL?
    @State private var isImagePickerPresented: Bool = false
    @State private var isDocumentPickerPresented: Bool = false

    var body: some View {
        VStack {
            if let url = selectedURL {
                FileViewer(url: url)
            } else {
                Button("Select Photo or File") {
                    isImagePickerPresented.toggle()
                }
                .padding()
                .fileImporter(
                    isPresented: $isDocumentPickerPresented,
                    allowedContentTypes: [UTType.data],
                    onCompletion: { result in
                        do {
                            selectedURL = try result.get() as? URL
                        } catch {
                            print("Error importing document: \(error)")
                        }
                    }
                )

                .onChange(of: isImagePickerPresented) { newValue in
                    if newValue {
                        isDocumentPickerPresented = true
                    }
                }
            }
        }
        .navigationTitle("File Viewer")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct FileViewer: View {
    let url: URL

    var body: some View {
        QuickLookView(url: url)
    }
}

struct QuickLookView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: UIViewControllerRepresentableContext<QuickLookView>) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: UIViewControllerRepresentableContext<QuickLookView>) {
        // Update the view controller
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, QLPreviewControllerDataSource {
        var parent: QuickLookView

        init(_ parent: QuickLookView) {
            self.parent = parent
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return 1
        }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return parent.url as QLPreviewItem
        }
    }
}
