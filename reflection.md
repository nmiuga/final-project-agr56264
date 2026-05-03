# VisionBoard for Color — Project Reflection

Coming into this class, my background is mostly web — HTML, CSS, JavaScript, some React. I know how to build things for a browser but I'd never touched Swift or Xcode before this semester. So this project was genuinely me learning a new platform from scratch, and I leaned on AI a lot to bridge that gap.

## What Was Actually New for Me

The biggest mental shift was understanding that SwiftUI is not like building a webpage. In web development, you have the DOM, you reach in and change things, and the page updates. In SwiftUI everything is declarative and state-driven — you describe what the UI *should look like* given the current data, and the framework handles re-rendering. That clicked for me once I saw `@State` and `@Query` in action. It's actually closer to React than I expected, but the syntax and the tooling felt completely foreign at first.

Consuming the Met Museum API was familiar territory — it's just a REST API returning JSON, same as I'd use `fetch()` for in JavaScript. What was different was doing it in Swift with `async/await` and `Codable`. Instead of manually parsing a JSON response, you define a struct that matches the shape of the data and Swift decodes it automatically. That felt almost magical the first time it worked.

The part I was most curious about was Apple's on-device AI (`@Generable` and Foundation Models). I'd worked with APIs like OpenAI before, but this runs entirely on the device — no network call, no API key, and the output comes back as a typed Swift struct rather than a raw string you have to parse. The `@Generable` macro basically tells the compiler "this struct is something the LLM can fill in," which is a really different mental model than anything I'd seen in web development.

## What Was Hard

The hardest part honestly wasn't the Swift itself — it was Xcode. Coming from VS Code, the Xcode environment is a lot to take in. Build errors show up in weird places, the simulator has its own quirks, and when something goes wrong it's not always obvious whether the problem is your code, the build cache, or the IDE itself. I cleared DerivedData more than once just to get a clean build.

I also ran into a situation where duplicate files caused a cascade of "invalid redeclaration" compile errors — basically two versions of the same view or model existing at once. In a web project you'd just delete a file and move on, but in Xcode the project file tracks everything, so it took some careful cleanup to sort out which version of each file was the right one.

## How AI Helped Me Learn

I used AI throughout this project not just to write code but to explain *why* things work the way they do. When I didn't understand why `async let` was faster than two sequential `await` calls, I asked. When I couldn't figure out why my cards were zoomed in and cropping, I described what I was seeing and learned the difference between `scaledToFit` and `scaledToFill`. That back-and-forth — seeing the code, running it, noticing something was off, and then actually understanding the fix — is what made this feel like learning rather than just copying.

## If I Had More Time

I'd want to explore more of what makes native apps feel *native* — things like haptic feedback patterns, shared element transitions between screens, and offline caching so the app works without a connection. I'd also want to try building the color extraction with k-means clustering instead of the bucket approach, which would give more perceptually accurate results. But for a first iOS project, I'm genuinely happy with how it came together.
