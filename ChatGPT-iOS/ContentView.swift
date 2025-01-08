//
//  ContentView.swift
//  ChatGPT-iOS
//
//  Created by 間嶋大輔 on 2025/01/07.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            ChatView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
