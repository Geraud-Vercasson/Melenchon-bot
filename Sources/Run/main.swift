import App
import HTTP
import SlackKit
import Foundation
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


let config = try Config(prioritized: [.directory(root: workingDirectory + "../Config/")])
print(workingDirectory + "../Config/")

let clientId = config["bot-config", "clientId"]!.string!
    let clientSecret = config["bot-config", "clientSecret"]!.string!
    let refreshToken = config["bot-config", "refreshToken"]!.string!
    let apiKey = config["bot-config", "apiKey"]!.string!
    let slackBotToken = config["bot-config", "slackBotToken"]!.string!
    let gfycatClientId = config["bot-config", "gfycatClientId"]!.string!
    let gfycatClientSecret = config["bot-config", "gfycatClientSecret"]!.string!

    var accessToken = ""

//  let clientId = ""
//  let clientSecret = ""
//  let refreshToken = ""
//  let apiKey = ""
//  var accessToken = ""
//  let gfycatClientId = ""
//  let gfycatClientSecret = ""
//  let slackBotToken = ""

let tfmt = "srt"

// Instantiate a Drop
//let config = try Config()
try config.setup()
let drop = try Droplet(config)
let queue =  DispatchQueue(label: "waiting for encoding")


// Declaring Methods

func getStatus(gfyToken: String, gfycatId: String) -> String? {
    do {
        let response = try drop.client.get("https://api.gfycat.com/v1/gfycats/fetch/status/" + gfycatId,
                                           query: [:], ["Authorization" : "Bearer " + gfyToken, "Content-Type" : "application/json"])
        
        if let bodyBytes = response.body.bytes, let json = try? JSON(bytes: bodyBytes) {
            return json["task"]?.string
        }
        
    } catch {
        // will print error catched in try calls
        print(error)
    }
    return nil
}

func tryUntilIsComplete(gfyToken: String, gfycatId: String, channel: String) {
    
    queue.asyncAfter(deadline: .now() + 10, execute:  {
        
        if let status = getStatus(gfyToken: gfyToken, gfycatId: gfycatId) {
            if status == "complete" {
                print("\n\n\n🎁🎁🎁\nhttp://gfycat.com/\(gfycatId)\n🎁🎁🎁\n\n\n")
                print("\n\n\n🎁🎁🎁\nhttps://thumbs.gfycat.com/\(gfycatId)-size_restricted.gif\n🎁🎁🎁\n\n\n")
                
                let reaction = "https://thumbs.gfycat.com/\(gfycatId)-size_restricted.gif"
                
                bot.webAPI?.sendMessage(channel: channel, text: reaction, success: nil, failure: nil)
                
            } else if status == "encoding" {
                print("\n😒 video is encoding\n")
                tryUntilIsComplete(gfyToken: gfyToken, gfycatId: gfycatId, channel: channel)
            } else {
                print("\n\n💥 There is no video !\n\n")
                
            }
        }
    })
}
// Call methods

let bot = SlackKit()

bot.addRTMBotWithAPIToken(slackBotToken)
bot.addWebAPIAccessWithToken(slackBotToken)

bot.notificationForEvent(.message) {(event, client) in
    
    
    guard
        let message = event.message,
        let id = client?.authenticatedUser?.id,
        message.text?.contains(id) == true
        else {
            return
    }
    
    
    
    
    if let newToken = refreshYoutubeToken(), var searchedText: String = event.message?.text, let channel = message.channel {
        accessToken = newToken
        
        searchedText.removeSubrange(searchedText.startIndex...searchedText.characters.index(of: " ")!)
        
        while searchedText.characters[searchedText.startIndex] == " " {
            
            searchedText.remove(at: searchedText.startIndex)
            
        }
        
        
        
        
        
        var bestCaptions = [Caption]()
        if let videoIdArray = getVideoIds(search: searchedText,maxResults: 10){
            
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
        if let randomCaption = bestCaptions.random() {
            
            print(randomCaption.videoId)
            
            let punchlines = randomCaption.subtitlesWithWord(word: searchedText)   // extraction des sous-titres contenant le mot cherché dans un Caption random de bestCaptions
            
            if let randomPunchline = punchlines.random(), let gfyResponse = getYoutubeGif(videoId: (randomCaption.videoId), startDate: randomPunchline.startDateNumber(), endDate: randomPunchline.endDateNumber(), captionText: randomPunchline.text){
                
                
                let gfycatID = "https://thumbs.gfycat.com/" + gfyResponse.idGif + "-size_restricted.gif"//getyoutubeGif sur une "punchline" random
                
                tryUntilIsComplete(gfyToken: gfyResponse.gfyToken, gfycatId: gfyResponse.idGif, channel: channel)
                
                
                return
            }
            
            
        }
        bot.webAPI?.addReaction(name: "Pardon?", channel: channel, timestamp: message.ts, success: nil, failure: nil)
        return
    }
    
    
}




// Start HTTP Server with no routes
//try drop.run()

RunLoop.main.run()


