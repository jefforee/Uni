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
        var newString = string
        if (string != "" && !string.hasPrefix("http")) {
            newString = "https://" + string
        }
        
        shortenedLink = removeTrackingParams(url: newString)
        shortenedLink = replaceDomains(string: shortenedLink)
        // followRedirects(link: shortenedLink)
    }
    
    func followRedirects(link: String) {
        guard let url = URL(string: link) else {
            return
        }
        
        // Only visit HTTPS links
        if url.scheme != "https" {
            return
        }

        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            guard error == nil else {
                return
            }
            guard let response = response else {
                return
            }
            guard let responseUrl = response.url else {
                return
            }
            if (responseUrl.absoluteString != link) {
                shortenURL(string: responseUrl.absoluteString) // TODO: This leads to a data race, need a counter and only update if counter > previous counter
            }
        }
        task.resume()
    }
    
    func removeTrackingParams(url: String) -> String {
        var cleanedUrl = url
        guard let jsonRules = getJsonRules() as? [String: Any] else {
            return cleanedUrl
        }
        
        guard let providers = jsonRules["providers"] as? [String: [String: Any]] else {
            return cleanedUrl
        }

        for (_, providerVal) in providers {
            guard let urlPattern = providerVal["urlPattern"] as? String else {
                continue
            }
            
            // Check that URL matches pattern
            guard cleanedUrl.range(of: urlPattern, options: [.regularExpression, .caseInsensitive]) != nil else {
                continue
            }
            
            guard let exceptions = providerVal["exceptions"] as? [String] else {
                continue
            }
            
            // Check if we match an exception
            for exception: String in exceptions {
                if cleanedUrl.range(of: exception, options: [.regularExpression, .caseInsensitive]) != nil {
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
                cleanedUrl = cleanedUrl.replacingOccurrences(of: rule, with: "", options: [.regularExpression, .caseInsensitive])
            }
        }
        
        for utm in UTM_PARAMS {
            var regex = try! NSRegularExpression(pattern: "&amp;" + utm + "=[0-9a-zA-Z._-]*")
            cleanedUrl = regex.stringByReplacingMatches(in: cleanedUrl, options: [], range: NSRange(location: 0, length:  cleanedUrl.count), withTemplate: "")
            
            regex = try! NSRegularExpression(pattern: "&" + utm + "=[0-9a-zA-Z._-]*")
            cleanedUrl = regex.stringByReplacingMatches(in: cleanedUrl, options: [], range: NSRange(location: 0, length:  cleanedUrl.count), withTemplate: "")
            
            regex = try! NSRegularExpression(pattern: "\\?" + utm + "=[0-9a-zA-Z._-]*")
            cleanedUrl = regex.stringByReplacingMatches(in: cleanedUrl, options: [], range: NSRange(location: 0, length:  cleanedUrl.count), withTemplate: "?")
            
            regex = try! NSRegularExpression(pattern: "/" + utm + "=" + urlRegex)
            cleanedUrl = regex.stringByReplacingMatches(in: cleanedUrl, options: [], range: NSRange(location: 0, length:  cleanedUrl.count), withTemplate: "/")
            
            regex = try! NSRegularExpression(pattern: "#" + utm + "=" + urlRegex)
            cleanedUrl = regex.stringByReplacingMatches(in: cleanedUrl, options: [], range: NSRange(location: 0, length:  cleanedUrl.count), withTemplate: "")
        }
        
        let url = URL(string: cleanedUrl)
        let domain = url?.host
        
        if domain != nil {
            for utm in G_TRACKING {
                cleanedUrl = cleanedUrl.replacingOccurrences(of: "&amp;" + utm + "=[0-9a-zA-Z._-]*", with: "")
                cleanedUrl = cleanedUrl.replacingOccurrences(of: "&" + utm + "=[0-9a-zA-Z._-]*", with: "")
                cleanedUrl = cleanedUrl.replacingOccurrences(of: "\\?" + utm + "=[0-9a-zA-Z._-]*", with: "?")
                cleanedUrl = cleanedUrl.replacingOccurrences(of: "/" + utm + "=" + urlRegex, with: "/")
            }
        }
        
        if (cleanedUrl.last == "&" || cleanedUrl.last == "?") {
            cleanedUrl = String(cleanedUrl.dropLast())
        }
        
        return cleanedUrl
    }
    
    func getDomainMappings() -> Dictionary<String, String> {
        var domains: Dictionary<String, String> = [:]
        // TODO: Fix these hardcodings
        domains["twitter.com"] = "nitter.net"
        domains["reddit.com"] = "libredd.it"
        domains["youtube.com"] = "yewtu.be"
        domains["instagram.com"] = "bibliogram.ethibox.fr"
        return domains
    }
    
    func replaceDomains(string: String) -> String {
        guard let url = URL(string: string) else {
            return string
        }
        
        guard let oldDomain = url.host else {
            return string
        }

        for (from, to) in getDomainMappings() {
            let newDomain = oldDomain.replacingOccurrences(of: from, with: to)
            if newDomain != oldDomain {
                guard let scheme = url.scheme else {
                    break
                }
                return scheme + "://" + newDomain + url.path
            }
        }
        return string
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
