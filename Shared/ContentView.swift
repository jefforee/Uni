//
//  ContentView.swift
//  Shared
//
//  Created by Abhik Ahuja on 10/22/21.
//

import SwiftUI


struct ContentView: View {
    @State private var link: String = ""
    @State private var shortenedLink: String = ""
    @State private var isShareSheetShowing = false
    @State private var textBoxHeight: CGFloat = 38
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Uni")
                .font(.title)
                .bold()
            Text("Enter link to shorten")
                .font(.title2)
                .multilineTextAlignment(.center)
            ResizableTF(txt: self.$link, height: self.$textBoxHeight)
                .frame(height: self.textBoxHeight)
                .overlay(RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(UIColor.darkGray), lineWidth: 1))
                .onChange(of: link) { link in
                    shortenURL(string: link)
                }
            Text("Shortened Link:")
            Link(shortenedLink == "" ? "https://example.com" : shortenedLink,
                 destination: getURL(string: shortenedLink))
                .disabled(shortenedLink == "")
                .foregroundColor(shortenedLink == "" ? Color(UIColor.darkGray) : .blue)
            HStack {
                Spacer()
                Button(action: shareButton) {
                    Text("Share Link")
                        .foregroundColor(shortenedLink == "" ? Color(UIColor.darkGray) : .white)
                }.disabled(shortenedLink == "")
                    .padding(10.0)
                    .background(shortenedLink == "" ? Color.gray : Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                Spacer()
            }
        }
        .padding()
    }
    
    func shortenURL(string: String) {
        shortenedLink = String(string.prefix(22)) // TODO: Process string
    }
    
    func shareButton() {
        isShareSheetShowing.toggle()
        
        let url = URL(string: shortenedLink)
        let av = UIActivityViewController(activityItems: [url!],
            applicationActivities: nil)
        
        UIApplication.shared.windows.first?.rootViewController?
            .present(av, animated: true, completion: nil)
    }
    
    func getURL(string: String) -> URL {
        let optionalURL: URL? = URL(string: string)
        if optionalURL != nil {
            return optionalURL!
        } else {
            return URL(string: "/")!
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().preferredColorScheme(.dark)
    }
}


// Resizable Text Field
struct ResizableTF: UIViewRepresentable {
    
    @Binding var txt: String
    @Binding var height: CGFloat
    
    func makeCoordinator() -> Coordinator {
        return ResizableTF.Coordinator(parent1: self)
    }
    
    func makeUIView(context: Context) -> UITextView {
        
        let view = UITextView()
        view.isEditable = true
        view.isScrollEnabled = true
        view.text = "https://example.com"
        view.font = .systemFont(ofSize: 18)
        view.textColor = .gray
        view.delegate = context.coordinator
        view.autocapitalizationType = .none
        view.autocorrectionType = UITextAutocorrectionType.no
                
        return view
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        
    }
    
    class Coordinator: NSObject,UITextViewDelegate {
        var parent: ResizableTF
        
        init(parent1: ResizableTF) {
            
            parent = parent1
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            if self.parent.txt == "" {
                textView.text = ""
                textView.textColor = .white
            }
        }
        
        func textViewDidChange(_ textView: UITextView) {
            DispatchQueue.main.async {
                self.parent.height = textView.contentSize.height
                self.parent.txt = textView.text
            }
        }
    }
    
}
