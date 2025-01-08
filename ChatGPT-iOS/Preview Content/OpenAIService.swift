import Foundation
import UIKit

class OpenAIService {
    private let apiKey = "YOUR_OPENAI_API_KEY"
    private let endpoint = "https://api.openai.com/v1/chat/completions"
    
    // 既存: テキストチャット用
    func sendChatRequest(messages: [ChatMessage], model: String = "gpt-3.5-turbo") async throws -> String {
        let messageDictionaries: [[String: String]] = messages.map { msg in
            [
                "role": msg.role.rawValue,
                "content": msg.content
            ]
        }
        let requestBody: [String: Any] = [
            "model": model,
            "messages": messageDictionaries,
            "temperature": 0.7
        ]
        
        return try await callOpenAIAPI(requestBody: requestBody)
    }
    
    // 新規追加: Visionモデル用
    func sendVisionChatRequest(image: UIImage,
                               question: String = "What is in this image?",
                               model: String = "gpt-4o-mini") async throws -> String {
        
        // 画像を base64 に変換
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "ImageConversionError", code: 0, userInfo: nil)
        }
        let base64Image = imageData.base64EncodedString()
        
        // Visionモデルが必要とするJSON構造を想定
        // "content" フィールドには text + image_url のように複数要素を含める場合がある
        let userMessage: [String: Any] = [
            "role": "user",
            "content": [
                [
                    "type": "text",
                    "text": question
                ],
                [
                    "type": "image_url",
                    "image_url": [
                        "url": "data:image/jpeg;base64,\(base64Image)"
                    ]
                ]
            ]
        ]
        
        let requestBody: [String: Any] = [
            "model": model,
            "messages": [userMessage],
            "temperature": 0.2
        ]
        
        return try await callOpenAIAPI(requestBody: requestBody)
    }
    
    /// 実際に OpenAI API を呼び出す共通メソッド
    private func callOpenAIAPI(requestBody: [String: Any]) async throws -> String {
        guard let url = URL(string: endpoint),
              let httpBody = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw NSError(domain: "Invalid Request", code: 0, userInfo: nil)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = httpBody
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        guard let json = try? JSONSerialization.jsonObject(with: data),
              let dict = json as? [String: Any],
              let choices = dict["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String
        else {
            throw NSError(domain: "ChatGPT Error", code: 0, userInfo: nil)
        }
        
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
