import Foundation
import UIKit
import Combine

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    
    // テキスト用とビジョン用モデル名の例
    let modelNameText: String = "gpt-3.5-turbo"
    let modelNameVision: String = "gpt-4o-mini"
    
    private let openAIService = OpenAIService()
    
    func sendMessage() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let userMessage = ChatMessage(role: .user, content: trimmed)
        messages.append(userMessage)
        inputText = ""
        
        Task {
            isLoading = true
            defer { isLoading = false }
            
            trimMessagesIfNeeded()
            
            do {
                let responseText = try await openAIService.sendChatRequest(
                    messages: messages,
                    model: modelNameText
                )
                let assistantMessage = ChatMessage(role: .assistant,
                                                   content: responseText)
                messages.append(assistantMessage)
            } catch {
                let errorMessage = ChatMessage(role: .assistant,
                                               content: "エラー: \(error.localizedDescription)")
                messages.append(errorMessage)
            }
        }
    }
    
    /// 画像＋テキストをまとめてビジョンモデルへ送信
    func sendVisionMessage(image: UIImage, question: String) {
        let userMessage = ChatMessage(role: .user,
                                      content: question,
                                      image: image)
        messages.append(userMessage)
        inputText = ""
        
        Task {
            isLoading = true
            defer { isLoading = false }
            
            do {
                let responseText = try await openAIService.sendVisionChatRequest(
                    image: image,
                    question: question,
                    model: modelNameVision
                )
                let assistantMessage = ChatMessage(role: .assistant,
                                                   content: responseText)
                messages.append(assistantMessage)
            } catch {
                let errorMessage = ChatMessage(role: .assistant,
                                               content: "ビジョンAPIエラー: \(error.localizedDescription)")
                messages.append(errorMessage)
            }
        }
    }
    
    private func trimMessagesIfNeeded() {
        let maxCharacterCount = 6000
        var totalCount = messages.reduce(0) { $0 + $1.content.count }
        
        while totalCount > maxCharacterCount && messages.count > 2 {
            let removed = messages.removeFirst()
            totalCount -= removed.content.count
        }
    }
}
