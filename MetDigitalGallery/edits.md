# Reflection
## MET Inspo — Project Twoa

New reflection for Final Project in Assets Folder 

---

## Overall Learnings

The biggest thing I learned was how API calls work in Swift. You're essentially sending a request to a URL, getting back a blob of JSON text, and then telling Swift exactly how to read it using Codable structs.

The Codable structs were a big concept for me. Basically, you define a Swift struct where each property name matches a key in the JSON response. Swift then automatically maps the values over so if the API returns "artistDisplayName": "Claude Monet", your struct just needs a var artistDisplayName: String and it handles the rest. The ObservableObject ViewModel was the middle layer that made the fetch happen and pushed the data down to the views using @Published.

---

## How I Built It

I started in Google Stitch to mock out the design before writing a single line of code. Having a visual reference made everything way easier. I knew what screens I needed and what data to display on each one. From there, I used Claude to help me write a detailed prompt.md that broke down the API structure, the Codable models, the ViewModel logic, and every view with specific colors and fonts from my Stitch design. That prompt became my blueprint.

---

## Challenges

Running the prompt through Codex didn't go perfectly. It generated some structs I didn't need and the models had extra fields that weren't in the API response, which caused decoding errors. I had to manually go in and clean up the structs, removing properties that didn't match the JSON. That was actually useful so it forced me to really read through the code and understand what each piece was doing instead of just running it blindly.


