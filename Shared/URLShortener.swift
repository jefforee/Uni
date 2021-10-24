//
//  URLShortener.swift
//  Uni
//
//  Created by Abhik Ahuja on 10/24/21.
//

import Foundation

class URLShortener {
    
    static var G_TRACKING: [String] = [
                "sourceid",
                "aqs",
                "client",
                "source",
                "ust",
                "usg"
    ]
        
    static var UTM_PARAMS: [String] = [
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
    static var urlRegex = "(?i)\\b((?:[a-z][\\w-]+:(?:/{1,3}|[a-z0-9%])|www\\d{0,3}[.]|[a-z0-9.\\-]+[.][a-z]{2,10}/)(?:[^\\s()<>]+|\\(([^\\s()<>]+|(\\([^\\s()<>]+\\)))*\\))+(?:\\(([^\\s()<>]+|(\\([^\\s()<>]+\\)))*\\)|[^\\s`!()\\[\\]{};:'\".,<>?«»“”‘’]))"
    
    static func getJsonRules() -> Any? {
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
    
    static func shortenURL(string: String) -> String {
        var newString = string
        var shortenedLink: String
        if (string != "" && !string.hasPrefix("http")) {
            newString = "https://" + string
        }
        
        shortenedLink = removeTrackingParams(url: newString)
        shortenedLink = replaceDomains(string: shortenedLink)
        // followRedirects(link: shortenedLink)
        
        return shortenedLink
    }
    
    static func followRedirects(link: String) {
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
                _ = self.shortenURL(string: responseUrl.absoluteString) // TODO: This leads to a data race, need a counter and only update if counter > previous counter
            }
        }
        task.resume()
    }
    
    static func removeTrackingParams(url: String) -> String {
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
        
        for utm in URLShortener.UTM_PARAMS {
            var regex = try! NSRegularExpression(pattern: "&amp;" + utm + "=[0-9a-zA-Z._-]*")
            cleanedUrl = regex.stringByReplacingMatches(in: cleanedUrl, options: [], range: NSRange(location: 0, length:  cleanedUrl.count), withTemplate: "")
            
            regex = try! NSRegularExpression(pattern: "&" + utm + "=[0-9a-zA-Z._-]*")
            cleanedUrl = regex.stringByReplacingMatches(in: cleanedUrl, options: [], range: NSRange(location: 0, length:  cleanedUrl.count), withTemplate: "")
            
            regex = try! NSRegularExpression(pattern: "\\?" + utm + "=[0-9a-zA-Z._-]*")
            cleanedUrl = regex.stringByReplacingMatches(in: cleanedUrl, options: [], range: NSRange(location: 0, length:  cleanedUrl.count), withTemplate: "?")
            
            regex = try! NSRegularExpression(pattern: "/" + utm + "=" + URLShortener.urlRegex)
            cleanedUrl = regex.stringByReplacingMatches(in: cleanedUrl, options: [], range: NSRange(location: 0, length:  cleanedUrl.count), withTemplate: "/")
            
            regex = try! NSRegularExpression(pattern: "#" + utm + "=" + URLShortener.urlRegex)
            cleanedUrl = regex.stringByReplacingMatches(in: cleanedUrl, options: [], range: NSRange(location: 0, length:  cleanedUrl.count), withTemplate: "")
        }
        
        let url = URL(string: cleanedUrl)
        let domain = url?.host
        
        if domain != nil {
            for utm in URLShortener.G_TRACKING {
                cleanedUrl = cleanedUrl.replacingOccurrences(of: "&amp;" + utm + "=[0-9a-zA-Z._-]*", with: "")
                cleanedUrl = cleanedUrl.replacingOccurrences(of: "&" + utm + "=[0-9a-zA-Z._-]*", with: "")
                cleanedUrl = cleanedUrl.replacingOccurrences(of: "\\?" + utm + "=[0-9a-zA-Z._-]*", with: "?")
                cleanedUrl = cleanedUrl.replacingOccurrences(of: "/" + utm + "=" + URLShortener.urlRegex, with: "/")
            }
        }
        
        if (cleanedUrl.last == "&" || cleanedUrl.last == "?") {
            cleanedUrl = String(cleanedUrl.dropLast())
        }
        
        return cleanedUrl
    }
    
    static func getDomainMappings() -> Dictionary<String, String> {
        var domains: Dictionary<String, String> = [:]
        // TODO: Fix these hardcodings
        domains["twitter.com"] = "nitter.net"
        domains["reddit.com"] = "libredd.it"
        domains["youtube.com"] = "yewtu.be"
        domains["instagram.com"] = "bibliogram.ethibox.fr"
        return domains
    }
    
    static func replaceDomains(string: String) -> String {
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
    
    static func getURL(string: String) -> URL {
        let optionalURL: URL? = URL(string: string)
        if optionalURL != nil {
            return optionalURL!
        } else {
            return URL(string: "/")!
        }
    }
}
