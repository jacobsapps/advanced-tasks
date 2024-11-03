//
//  ModelCache.swift
//  AdvancedTasks
//
//  Created by Jacob Bartlett on 24/09/2024.
//

import Foundation
import Vision
import ImageIO

final class ModelCache {
    
    /// A common image classifier instance that all Image Predictor instances use to generate predictions.
    ///
    /// Share one ``VNCoreMLModel`` instance --- for each Core ML model file --- across the app,
    /// since each can be expensive in time and resources.
    /// The model is cached but gets removed from memory after ~5 minutes.
    ///
    private var model: VNCoreMLModel?
    
    /// - Tag: name
    func getImageClassifierModel() -> VNCoreMLModel {
        if let model {
            return model
        }
        
        // Use a default model configuration.
        let defaultConfig = MLModelConfiguration()
        
        // Create an instance of the image classifier's wrapper class.
        let imageClassifierWrapper = try? MobileNet(configuration: defaultConfig)
        
        // Alt: Fetch model from remote file storage to save storage
        // let imageClassifierWrapper = try? await fetchRemoteVisionModel()
 
        guard let imageClassifier = imageClassifierWrapper else {
            fatalError("App failed to create an image classifier model instance.")
        }
        
        // Get the underlying model instance.
        let imageClassifierModel = imageClassifier.model
        
        // Create a Vision instance using the image classifier's model instance.
        guard let imageClassifierVisionModel = try? VNCoreMLModel(for: imageClassifierModel) else {
            fatalError("App failed to create a `VNCoreMLModel` instance.")
        }
        
        self.model = imageClassifierVisionModel
        return imageClassifierVisionModel
    }
    
    init() {}
    
    public func warmModelCache() {
        Task(priority: .high) {
            _ = try? await getImageClassifierModel()
        }
        coolModelCache()
    }

    public func classifyImage(_ data: Data) async throws {
        let model = try await getImageClassifierModel()
        coolModelCache()
    }
    
    private var coolModelCacheTask: Task<Void, Never>?
    
    /// - Creates a task running in the background
    /// - After waiting a while without being used, it removes the cached model from memory
    /// - When cache is re-warmed, the task is cancelled and the cooldown timer is reset
    ///
    private func coolModelCache() {
        coolModelCacheTask?.cancel()
        coolModelCacheTask = Task(priority: .background) {
            try? await Task.sleep(for: .seconds(300))
            guard !Task.isCancelled else { return }
            model = nil
        }
    }
}
