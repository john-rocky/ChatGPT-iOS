import Foundation
import UIKit

/// ChatGPT が想定する role は "system" | "user" | "assistant" など
/// 画像を保持できるように、image: UIImage? を追加
struct ChatMessage: Identifiable {
    enum Role: String {
        case user
        case assistant
    }
    
    let id = UUID()
    let role: Role
    let content: String
    var image: UIImage? = nil
}
