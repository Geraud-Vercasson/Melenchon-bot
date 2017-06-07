//
//  GfycatController.swift
//  Melenchon_bot
//
//  Created by Géraud Vercasson on 05/06/2017.
//
//

import Foundation
import JSON


func getYoutubeGif (videoId: String, startDate: Double, endDate: Double, captionText: String = "") -> String {
    
    do {
        
        let duration = endDate - startDate
        var text = captionText
        
        
        if text.characters.count > 50 { // Taille arbitraire au delà de laquelle la phrase est coupée en 2 sans couper de mot
            
            let characters = text.characters.array
            let distanceMoyenne = characters.count / 2
            var distanceMin = characters.count
            
            for i in 0..<characters.count{
                
                if characters[i] == " " && abs(i - distanceMoyenne) < abs(distanceMin - distanceMoyenne) {
                    
                    distanceMin = i
                    
                }
             
                
            }
            text = text.replacingCharacters(in: text.index(text.startIndex, offsetBy: distanceMin)..<text.index(text.startIndex, offsetBy: distanceMin+1), with: "\\n")
        }
        
            let json = try JSON(node: [
                "grant_type":"client_credentials",
                "client_id":gfycatClientId,
                "client_secret":gfycatClientSecret])
            
            let gifJson = try JSON(node: [
                "fetchUrl":"https://www.youtube.com/watch?v=" + videoId,
                "cut" : ["duration":duration,"start":startDate],
                "captions": [["text":text, "fontHeight": 40]]])
            
            
            
            let tokenResponse = try drop.client.post("https://api.gfycat.com/v1/oauth/token", [:], json)
            
            if let bodyBytes = tokenResponse.body.bytes, let responseJson = try? JSON(bytes: bodyBytes) {
                if let accessToken = responseJson["access_token"]?.string {
                    
                    
                    let gifPost = try drop.client.post("https://api.gfycat.com/v1/gfycats",["Authorization" : "Bearer " + accessToken, "Content-Type" : "application/json"],gifJson)
                    
                    if let bodyBytes = gifPost.body.bytes, let responseJson = try? JSON(bytes: bodyBytes) {
                        
                        return (responseJson["gfyname"]?.string) ?? "error"
                    }
                    
                }
            }
            
        }
    catch {
        // will print error catched in try calls
        print("error")
    }
    return "error"
}





