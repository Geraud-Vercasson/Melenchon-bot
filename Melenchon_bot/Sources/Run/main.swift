import App
import HTTP
/// We have isolated all of our App's logic into
/// the App module because it makes our app
/// more testable.
///
/// In general, the executable portion of our App
/// shouldn't include much more code than is presented
/// here.
///
/// We simply initialize our Droplet, optionally
/// passing in values if necessary
/// Then, we pass it to our App's setup function
/// this should setup all the routes and special
/// features of our app
///
/// .run() runs the Droplet's commands,
/// if no command is given, it will default to "serve"

// Declaring vars

let tfmt = "srt"


// Instantiate a Drop
let config = try Config()
try config.setup()
let drop = try Droplet(config)



// Declaring Methods
func refreshToken() -> String? {
    do {
        let response = try drop.client.post("https://www.googleapis.com/oauth2/v4/token",
                                            query: [
                                                "client_id": Client_id,
                                                "grant_type": "refresh_token",
                                                "client_secret": Client_secret,
                                                "refresh_token": Refresh_token],
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
                                            "key": API_Key,
                                            "tfmt":tfmt],
                                           ["authorization":"Bearer " + Access_token])
        
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
                                            "key": API_Key,
                                            ],
                                           ["authorization":"Bearer " + Access_token])
        
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

func getVideoIds(search: String, maxResults: Int = 10) -> [String]? {
    do {
        let response = try drop.client.get("https://www.googleapis.com/youtube/v3/search",
                                           query: [
                                            "q":search,
                                            "part":"snippet",
                                            "key": API_Key,
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



// Call methods
if let newToken = refreshToken() {
    Access_token = newToken
    let searchedText = "république"
    var bestCaptions = [Caption]()
    if let videoIdArray = getVideoIds(search: "Melenchon",maxResults: 25){
        
        videoIdArray.forEach({ (my_videoId) in
            
            
            if let captionIds = getCaptionIds(videoId: my_videoId){
                
                captionIds.forEach{ (captionId) in
                    
                    if let captionString = getCaption(id: captionId) {
                        
                        if let caption = Caption(id: captionId, subtitleRaw: captionString, videoId: my_videoId){
                            
                            let numberOfIteration = caption.countOfWord(searchedText)
                            
                            
                            if numberOfIteration != 0  {
                                bestCaptions.append(caption)
                            }
                            print (numberOfIteration)
                            
                        }
                    }
                }
            }
        })
    }
    
    bestCaptions = bestCaptions
        .filter({caption -> Bool in caption.countOfWord(searchedText) != 0})
        .sorted(by: { (caption1, caption2) -> Bool in
            caption1.countOfWord(searchedText) > caption2.countOfWord(searchedText)
            
        })
    let randomCaption = bestCaptions.random()
    
    print(randomCaption?.videoId ?? "no match")
    
    if let punchlines = randomCaption?.subtitlesWithWord(word: searchedText) {   // extraction des sous-titres contenant le mot cherché dans un Caption random de bestCaptions
        
        if punchlines.count != 0 {
            
            let randomPunchline = punchlines.random()
            
            print("https://gfycat.com/gifs/detail/" + getYoutubeGif(videoId: (randomCaption!.videoId), startDate: (randomPunchline?.startDateNumber())!, endDate: (randomPunchline?.endDateNumber())!, captionText: (punchlines.first?.text)!))  //getyoutubeGif sur une "punchline" random
            
            // print(getYoutubeGif(videoId: (bestCaptions.first?.videoId)!, startDate: (punchlines.last?.startDateNumber())!, endDate: (punchlines.last?.endDateNumber())!, captionText: (punchlines.last?.text)!)) //getyoutubeGif sur la dernière "punchline"
            
        }
        
        
    }
    
    
    
    
    
}


// Start HTTP Server with no routes
try drop.run()


