//
//  ContentViewModel.swift
//  AdvancedTasks
//
//  Created by Jacob Bartlett on 24/09/2024.
//

import UIKit
import Vision
import PhotosUI
import _PhotosUI_SwiftUI

struct VisionResult: Identifiable {
    let id = UUID().uuidString
    let image: UIImage
    let prediction: String
    let confidence: String
}

final class ContentViewModel: ObservableObject {
    
    private let imageClassifier: ImagePredictor
    
    @Published private(set) var results: [VisionResult] = []
    
    private var imageProcessingTask: Task<Void, Error>?
    
    init() {
        let modelCache = ModelCache()
        imageClassifier = ImagePredictor(modelCache: ModelCache())
        modelCache.warmModelCache()
        
        dump(modelCache)
        
    }
    
    private func process(_ uiImage: UIImage) throws {
        try imageClassifier.makePredictions(
            for: uiImage,
            completionHandler: { [weak self] in
                guard let self,
                        let first = $0?.first else { return }
                updateResults(uiImage, prediction: first)
            }
        )
    }
    
    private func updateResults(_ image: UIImage, prediction: ImagePredictor.Prediction) {
        let result = VisionResult(
            image: image,
            prediction: prediction.classification,
            confidence: prediction.confidencePercentage
        )
        Task { @MainActor in
            results.append(result)
        }
    }
    
    @MainActor
    func process(items: [PhotosPickerItem]) {
        imageProcessingTask?.cancel()
        imageProcessingTask = Task {
            for item in items {
                guard !Task.isCancelled else { return }
                guard let data = try await item.loadTransferable(type: Data.self),
                      let uiImage = UIImage(data: data) else {
                    return
                }
                try process(uiImage)
            }
        }
    }
    
    @MainActor
    func process(images: [UIImage]) {
        imageProcessingTask?.cancel()
        imageProcessingTask = Task {
            for image in images {
                guard !Task.isCancelled else { return }
                try process(image)
                await Task.yield()
            }
        }
    }
}
