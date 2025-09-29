//
//  ImageCache.swift
//  PaulDemo
//
//  Created by Paul Davis on 28/09/2025.
//

import SwiftUI

struct ImageAsyncCache<Placeholder: View>: View {
    @StateObject private var loader: ImageLoader
    private let placeholder: Placeholder
    private let image: (UIImage) -> Image
    
    init(url: URL?,
         @ViewBuilder placeholder: () -> Placeholder,
         @ViewBuilder image: @escaping (UIImage) -> Image = Image.init(uiImage:)) {
        _loader = StateObject(wrappedValue: ImageLoader(url: url ?? URL(string: "https://example.com")!))
        self.placeholder = placeholder()
        self.image = image
    }
    
    var body: some View {
        content
            .onAppear {
                loader.load()
            }
            .onDisappear {
                loader.cancel()
            }
    }
    
    private var content: some View {
        Group {
            if let uiImage = loader.image {
                image(uiImage)
                    .resizable()
            } else {
                placeholder
            }
        }
    }
}
