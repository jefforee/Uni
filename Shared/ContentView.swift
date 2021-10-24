//
//  ContentView.swift
//  Shared
//
//  Created by Abhik Ahuja on 10/22/21.
//

import SwiftUI
import Foundation


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
    
    func getJsonRules() -> Any? {
        do {
            if let bundlePath = Bundle.main.path(forResource: "rules", ofType: "json") {
                if let jsonData = try String(contentsOfFile: bundlePath).data(using: .utf8) {
                    return try? JSONSerialization.jsonObject(with: jsonData, options: [])
                }
            }
        } catch {
            print(error)
        }
        return nil
    }
    
    func shortenURL(string: String) {
        shortenedLink = string
        
        guard let jsonRules = getJsonRules() as? [String: Any] else {
            return
        }
        
        guard let providers = jsonRules["providers"] as? [String: [String: Any]] else {
            return
        }

        for (_, providerVal) in providers {
            guard let urlPattern = providerVal["urlPattern"] as? String else {
                continue
            }
            
            // Check that URL matches pattern
            guard shortenedLink.range(of: urlPattern, options: [.regularExpression, .caseInsensitive]) != nil else {
                continue
            }
            
            guard let exceptions = providerVal["exceptions"] as? [String] else {
                continue
            }
            
            // Check if we match an exception
            for exception: String in exceptions {
                if shortenedLink.range(of: exception, options: [.regularExpression, .caseInsensitive]) != nil {
                    continue
                }
            }
            
            guard let completeProvider = providerVal["completeProvider"] as? Bool else {
                continue
            }
            
            guard !completeProvider else {
                // TODO: Figure what to do here, UntrackMe doesn't do anything either
                continue
            }
            
            guard let rules = providerVal["rules"] as? [String] else {
                continue
            }
            
            /*
            guard let redirections = providerVal["redirections"] as? [String] else {
                continue
            }
             */
            
            for rule: String in rules {
                shortenedLink = shortenedLink.replacingOccurrences(of: rule, with: "", options: [.regularExpression, .caseInsensitive])
            }
        }
        
        // TODO: Define these 2 as static variables
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
        
        for utm in UTM_PARAMS {
            var regex = try! NSRegularExpression(pattern: "&amp;" + utm + "=[0-9a-zA-Z._-]*")
            shortenedLink = regex.stringByReplacingMatches(in: shortenedLink, options: [], range: NSRange(location: 0, length:  shortenedLink.count), withTemplate: "")
            
            regex = try! NSRegularExpression(pattern: "&" + utm + "=[0-9a-zA-Z._-]*")
            shortenedLink = regex.stringByReplacingMatches(in: shortenedLink, options: [], range: NSRange(location: 0, length:  shortenedLink.count), withTemplate: "")
            
            regex = try! NSRegularExpression(pattern: "\\?" + utm + "=[0-9a-zA-Z._-]*")
            shortenedLink = regex.stringByReplacingMatches(in: shortenedLink, options: [], range: NSRange(location: 0, length:  shortenedLink.count), withTemplate: "?")
            
            regex = try! NSRegularExpression(pattern: "/" + utm + "=" + urlRegex)
            shortenedLink = regex.stringByReplacingMatches(in: shortenedLink, options: [], range: NSRange(location: 0, length:  shortenedLink.count), withTemplate: "/")
            
            regex = try! NSRegularExpression(pattern: "#" + utm + "=" + urlRegex)
            shortenedLink = regex.stringByReplacingMatches(in: shortenedLink, options: [], range: NSRange(location: 0, length:  shortenedLink.count), withTemplate: "")
        }
        
        // TODO: Make this static
        let G_TRACKING: [String] = [
                    "sourceid",
                    "aqs",
                    "client",
                    "source",
                    "ust",
                    "usg"
        ]
        
        let url = URL(string: shortenedLink)
        let domain = url?.host
        
        if domain != nil {
            for utm in G_TRACKING {
                shortenedLink = shortenedLink.replacingOccurrences(of: "&amp;" + utm + "=[0-9a-zA-Z._-]*", with: "")
                shortenedLink = shortenedLink.replacingOccurrences(of: "&" + utm + "=[0-9a-zA-Z._-]*", with: "")
                shortenedLink = shortenedLink.replacingOccurrences(of: "\\?" + utm + "=[0-9a-zA-Z._-]*", with: "?")
                shortenedLink = shortenedLink.replacingOccurrences(of: "/" + utm + "=" + urlRegex, with: "/")
            }
        }
        
        if (shortenedLink.last == "&" || shortenedLink.last == "?") {
            shortenedLink = String(shortenedLink.dropLast())
        }
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
