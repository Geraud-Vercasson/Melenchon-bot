//
//  YoutubeController.swift
//  Melenchon_bot
//
//  Created by Géraud Vercasson on 08/06/2017.
//
//

import Foundation
import Vapor

func refreshYoutubeToken() -> String? {
    do {
        let response = try drop.client.post("https://www.googleapis.com/oauth2/v4/token",
                                            query: [
                                                "client_id": clientId,
                                                "grant_type": "refresh_token",
                                                "client_secret": clientSecret,
                                                "refresh_token": refreshToken],
                                            ["Content-Type":" application/x-www-form-urlencoded"])
        
        if let bodyBytes = response.body.bytes, let json = try? JSON(bytes: bodyBytes) {
            
            print("new access token:" + json["access_token"]!.string!)
            return json["access_token"]!.string!
        }
    } catch {
        // will print error catched in try calls
        print(error)
    }
    
    return nil
}

func getCaption(id: String) -> String? {
    do {
        let response = try drop.client.get("https://www.googleapis.com/youtube/v3/captions/" + id,
                                           query: [
                                            "key": apiKey,
                                            "tfmt":tfmt],
                                           ["authorization":"Bearer " + accessToken])
        
        if let bodyBytes = response.body.bytes, let captionString = String(bytes: bodyBytes, encoding: .utf8) {
            
            return captionString
        }
        
    } catch {
        // will print error catched in try calls
        print(error)
    }
    return nil
}


func getCaptionIds(videoId: String) -> [String]? {
    do {
        let response = try drop.client.get("https://www.googleapis.com/youtube/v3/captions/",
                                           query: [
                                            "videoId":videoId,
                                            "part":"id",
                                            "key": apiKey,
                                            ],
                                           ["authorization":"Bearer " + accessToken])
        
        if let bodyBytes = response.body.bytes, let json = try? JSON(bytes: bodyBytes) {
            
            return json["items"]?.array?
                .filter{ $0["id"]?.string != nil }
                .map{ ($0["id"]?.string)! }
            
        }
        
    } catch {
        // will print error catched in try calls
        print(error)
    }
    return nil
}

func getVideoIds(search: String, maxResults: Int = 20) -> [String]? {
    do {
        let response = try drop.client.get("https://www.googleapis.com/youtube/v3/search",
                                           query: [
                                            "q":search,
                                            "part":"snippet",
                                            "key": apiKey,
                                            "maxResults":maxResults,
                                            "type":"video",
                                            "videoCaption":"closedCaption"
            ])
        
        if let bodyBytes = response.body.bytes, let json = try? JSON(bytes: bodyBytes) {
            
            return json["items"]?.array?
                .filter{ $0["id"]?.object?["videoId"]?.string != nil }
                .map{ ($0["id"]?.object?["videoId"]?.string)! }
        }
        
    } catch {
        // will print error catched in try calls
        print(error)
    }
    return nil
}
