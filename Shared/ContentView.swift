//
//  ContentView.swift
//  Shared
//
//  Created by Abhik Ahuja on 10/22/21.
//

import SwiftUI
import Foundation

let G_TRACKING: [String] = [
            "sourceid",
            "aqs",
            "client",
            "source",
            "ust",
            "usg"
]

let UTM_PARAMS: [String] = [
            "utm_\\w+",
            "ga_source",
            "ga_medium",
            "ga_term",
            "ga_content",
            "ga_campaign",
            "ga_place",
            "yclid",
            "_openstat",
            "fb_action_ids",
            "fb_action_types",
            "fb_source",
            "fb_ref",
            "fbclid",
            "action_object_map",
            "action_type_map",
            "action_ref_map",
            "gs_l",
            "mkt_tok",
            "hmb_campaign",
            "hmb_medium",
            "hmb_source",
            "[\\?|&]ref[\\_]?",
            "amp[_#\\w]+",
            "click"
            ]

let urlRegex = "(?i)\\b((?:[a-z][\\w-]+:(?:/{1,3}|[a-z0-9%])|www\\d{0,3}[.]|[a-z0-9.\\-]+[.][a-z]{2,10}/)(?:[^\\s()<>]+|\\(([^\\s()<>]+|(\\([^\\s()<>]+\\)))*\\))+(?:\\(([^\\s()<>]+|(\\([^\\s()<>]+\\)))*\\)|[^\\s`!()\\[\\]{};:'\".,<>?«»“”‘’]))"

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
                    shortenedLink = URLShortener.shortenURL(string: link)
                }
            Text("Shortened Link:")
            Link(shortenedLink == "" ? "https://example.com" : shortenedLink,
                 destination: URLShortener.getURL(string: shortenedLink))
                .disabled(shortenedLink == "")
                .foregroundColor(shortenedLink == "" ? Color(UIColor.darkGray) : .blue)
            HStack {
                Spacer()
                Button(action: shareButton) {
                    Text("Share Link")
                        .foregroundColor(shortenedLink == "" ? Color(UIColor.darkGray) : .white)
                }.disabled(shortenedLink == "")
                    .padding(16.0)
                    .background(shortenedLink == "" ? Color.gray : Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                Spacer()
            }
        }
        .padding()
    }
    
    
    func shareButton() {
        isShareSheetShowing.toggle()
        
        let url = URL(string: shortenedLink)
        let av = UIActivityViewController(activityItems: [url!],
            applicationActivities: nil)
        
        UIApplication.shared.windows.first?.rootViewController?
            .present(av, animated: true, completion: nil)
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().preferredColorScheme(.dark)
    }
}

