import SwiftUI
import PhotosUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    
    // フォトライブラリから選択したアイテム
    @State private var selectedItem: PhotosPickerItem?
    // 実際のUIImage
    @State private var selectedImage: UIImage?
    
    // 画像拡大表示用
    @State private var isShowingFullImage = false
    @State private var fullScreenImage: UIImage?
    
    var body: some View {
        ZStack {
            VStack {
                // メッセージ一覧
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        LazyVStack(alignment: .leading) {
                            ForEach(viewModel.messages) { message in
                                MessageBubble(message: message) { tappedImage in
                                    // 画像タップ時にシート表示
                                    fullScreenImage = tappedImage
                                    isShowingFullImage = true
                                }
                            }
                        }
                        .padding()
                    }
                    // メッセージ追加時に下までスクロール
                    .onChange(of: viewModel.messages.count) { _ in
                        withAnimation {
                            scrollProxy.scrollTo(viewModel.messages.last?.id,
                                                 anchor: .bottom)
                        }
                    }
                }
                
                // 入力欄 & ボタン
                HStack(spacing: 8) {
                    // 選択後のサムネイル表示
                    if let uiImage = selectedImage {
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 50, height: 50)
                                .cornerRadius(8)
                                .clipped()
                            
                            // キャンセルボタン
                            Button {
                                selectedImage = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white)
                                    .shadow(radius: 2)
                            }
                            .offset(x: 5, y: -5)
                        }
                    }
                    
                    // テキストフィールド
                    TextField("メッセージを入力", text: $viewModel.inputText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    // 画像選択アイコン (小さめ)
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.blue)
                    }
                    
                    // 送信ボタン
                    Button("送信") {
                        if let uiImage = selectedImage {
                            // 画像＋テキストをVisionモデルへ
                            viewModel.sendVisionMessage(image: uiImage,
                                                        question: viewModel.inputText)
                            // 画像&入力クリア
                            selectedImage = nil
                        } else {
                            // テキストのみ
                            viewModel.sendMessage()
                        }
                    }
                    .disabled(viewModel.isLoading)
                    .padding(.horizontal, 4)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            // 背景タップでキーボードを隠す
            .onTapGesture {
                hideKeyboard()
            }
            
            // PhotoPicker で画像が選ばれたら取り込み
            .onChange(of: selectedItem) { newItem in
                Task {
                    if let newItem,
                       let data = try? await newItem.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        selectedImage = uiImage
                    }
                }
            }
            
            // ローディングインジケータ
            if viewModel.isLoading {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                VStack {
                    ProgressView("回答を待っています...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding()
                        .background(Color.secondary.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
        }
        // 画像拡大表示シート
        .sheet(isPresented: $isShowingFullImage) {
            if let image = fullScreenImage {
                ImageFullScreenView(image: image)
            }
        }
        .navigationTitle("Chat(\(viewModel.modelNameText)) + Vision(\(viewModel.modelNameVision))")
    }
}

/// 拡大画像をフルスクリーンで表示
struct ImageFullScreenView: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // 大きく表示 & スクロール可能にしたいなら ScrollView + zoom 対応してもOK
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .onTapGesture {
                    dismiss()
                }
        }
    }
}

/// チャットメッセージバブル
struct MessageBubble: View {
    let message: ChatMessage
    let onImageTap: (UIImage) -> Void
    
    var body: some View {
        HStack {
            if message.role == .assistant {
                // アシスタントは左寄せ
                assistantBubble
                Spacer()
            } else {
                // ユーザーは右寄せ
                Spacer()
                userBubble
            }
        }
        .padding(.vertical, 4)
        .id(message.id)
    }
    
    // MARK: - アシスタント用
    private var assistantBubble: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 改行込みMarkdownを反映
            if let attributedStr = try? AttributedString(markdown: message.content) {
                Text(attributedStr)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(8)
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(12)
            } else {
                // Markdown変換できなかったらプレーンテキスト
                Text(message.content)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(8)
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
        }
    }
    
    // MARK: - ユーザー用
    private var userBubble: some View {
        VStack(alignment: .trailing, spacing: 6) {
            // テキスト
            Text(message.content)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .padding(8)
                .foregroundColor(.white)
                .background(Color.green)
                .cornerRadius(12)
            
            // ユーザーが送信した画像があればサムネイル表示
            if let image = message.image {
                Button {
                    onImageTap(image) // タップで拡大表示
                } label: {
                    // チャット欄では「一部だけ表示」する例 (200x200)
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 200, height: 200)
                        .clipped()
                        .cornerRadius(8)
                }
            }
        }
    }
}



#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}
#endif
