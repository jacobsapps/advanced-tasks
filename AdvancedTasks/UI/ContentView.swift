//
//  ContentView.swift
//  AdvancedTasks
//
//  Created by Jacob Bartlett on 24/09/2024.
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    
    @StateObject var viewModel = ContentViewModel()
    @State private var selectedItems: [PhotosPickerItem] = []
    
    var body: some View {
        List {
            ForEach(viewModel.results) { result in
                VStack {
                    Image(uiImage: result.image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                    
                    HStack(spacing: 4) {
                        Text(result.prediction)
                        Text("(\(result.confidence)%)")
                            .foregroundStyle(.secondary)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    .padding()
                }
            }
            
            PhotosPicker(selection: $selectedItems, matching: .images) {
                Text("Select Photo")
            }
            .onChange(of: selectedItems) { newItems in
                viewModel.process(items: newItems)
            }
        }
    }
}

struct CameraView: UIViewControllerRepresentable {
    var completion: (UIImage?) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var completion: (UIImage?) -> Void
        
        init(completion: @escaping (UIImage?) -> Void) {
            self.completion = completion
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let image = info[.originalImage] as? UIImage
            completion(image)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            completion(nil)
        }
    }
}

#Preview {
    ContentView()
}
