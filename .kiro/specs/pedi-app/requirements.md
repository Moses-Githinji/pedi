# Requirements Document

## Introduction

Pedi is a React Native Expo mobile application for iOS and Android, backed by Firebase, designed for the Kenyan market. The name "Pedi" is derived from Sheng for "peddler" — positioning the app as the ultimate insider plug for all things Kenya. Pedi combines a TikTok-style full-screen vertical swipe feed with Facebook's familiar visual aesthetic to deliver a hyper-personalized, community-driven encyclopedia of Kenyan experiences: hidden gems, party spots, food, culture, music, outdoor activities, and more. Users discover, upload, vote on, and share location-based content called "Gems" (also called "Plugs"), earning ranks and points through engagement. The platform is built for fast adoption among young Kenyans by leveraging familiar UI patterns, phone-number-first authentication, and offline support for low-connectivity areas.

---

## Glossary

- **Pedi**: The app name; Sheng for "peddler." Also used to refer to a user of the app.
- **Gem**: A user-generated post consisting of a short video or high-resolution photo tied to a physical location or event. Also called a "Plug."
- **Plug**: Synonym for Gem; also used colloquially to mean an insider tip or connection.
- **Vouch**: A positive vote on a Gem meaning "I was here, it is legitimate." Equivalent to a Like.
- **Cap**: A negative flag on a Gem meaning "This place is fake, closed, or a scam."
- **Vibe-Meter**: The composite voting and verification system combining Vouch, Cap, and three quality dimensions.
- **Proof of Presence (PoP)**: GPS-based verification that a user is physically within 500 metres of a Gem's location before they can Vouch.
- **Form**: Sheng for "vibe" or "scene" — what is happening, what is good. Used in onboarding category names.
- **Sherehe**: Swahili/Sheng for "celebration/party." Represents the Party & Nightlife interest category.
- **Tembea Kenya**: Swahili for "Travel Kenya." Represents the Outdoors & Hiking interest category.
- **Mnyama**: Sheng for someone who loves meat/food. Used in the "Foodie/Mnyama" category.
- **Choma**: Short for "Nyama Choma" — Kenyan grilled meat. Represents food culture.
- **Nganya**: A highly customised, decorated Matatu (minibus). Plural: Nganyas.
- **Matatu**: A privately owned minibus used for public transport in Kenya, known for vibrant decoration and loud music.
- **Gengetone**: A Kenyan urban music genre that emerged around 2018, blending Sheng lyrics with trap and dancehall beats.
- **Benga**: A traditional Kenyan music genre originating from the Luo community, characterised by fast guitar rhythms.
- **Zilizopendwa**: Swahili for "those that were loved" — classic Kenyan oldies music.
- **Kenyan Drill**: A Kenyan adaptation of the UK/US Drill rap genre.
- **Mutura**: A traditional Kenyan sausage made from goat intestines, popular as street food.
- **Kahawa Tungu**: Swahili for "bitter coffee" — traditional Kenyan spiced coffee.
- **Githeri**: A traditional Kenyan dish of boiled maize and beans.
- **Pilau**: A Kenyan spiced rice dish, popular on the coast.
- **Ugali**: A stiff maize flour porridge; the staple food of Kenya.
- **Smokie Pasua**: A popular Kenyan street food — a smokies sausage split open and filled with kachumbari (tomato-onion salsa).
- **Pedi Points**: The in-app currency/reward points earned through engagement.
- **Junior Pedi**: The entry-level user rank.
- **Senior Pedi**: The second user rank.
- **The Plug**: The third user rank.
- **Chief Pedi**: The fourth user rank.
- **Governor**: The highest user rank.
- **Verified Plug**: A badge awarded to users with 50 or more highly-voted Gems.
- **Limited Time Form**: A Gem post that is only visible for 24 hours, designed to create FOMO.
- **Daily Plug Feed**: The hero full-screen vertical swipe feed, personalised per user.
- **Hustle Directory**: A directory of local guides, photographers, fixers, and service providers.
- **M-Pesa**: Kenya's dominant mobile money platform operated by Safaricom.
- **Kuna form gani?**: Sheng/Swahili for "What is the vibe?" or "What is happening?"
- **App**: The Pedi mobile application.
- **System**: The Pedi backend comprising Firebase Auth, Firestore, Cloud Storage, Cloud Functions, and App Check.
- **Feed Algorithm**: The Cloud Function-powered personalisation engine that ranks and orders Gems for each user's Daily Plug Feed.
- **Geofence**: A virtual geographic boundary defined by a GPS coordinate and a radius, used for Proof of Presence validation.
- **GeoPoint**: A Firestore data type storing latitude and longitude coordinates.
- **OTP**: One-Time Password, used for phone number authentication.
- **OAuth**: Open Authorisation protocol used for Google and Facebook sign-in.
- **Cloud Function**: A Firebase serverless function that runs backend logic in response to events or HTTP calls.
- **Firestore**: Firebase's NoSQL cloud database used as the primary data store.
- **Firebase Storage**: Firebase's cloud object storage used for media files (videos and images).
- **App Check**: Firebase's service that verifies requests originate from the official Pedi app.
- **preferenceWeights**: A per-user Firestore map of interest tags to numeric scores, updated by the Feed Algorithm.
- **vibeDimensions**: The three voting quality axes: Authenticity, Funness, and Pocket-Friendliness.
- **capCount**: The total number of Cap votes on a Gem.
- **vouchCount**: The total number of Vouch votes on a Gem.


---

## Requirements

### Requirement 1: Authentication and Onboarding

**User Story:** As a new user in Kenya, I want to sign up using my phone number, Google account, or Facebook account, so that I can access Pedi quickly without needing to remember a password.

#### Acceptance Criteria

1. THE App SHALL present three sign-in options on the authentication screen: Phone Number (OTP), Google OAuth, and Facebook OAuth.
2. WHEN a user selects Phone Number sign-in, THE App SHALL prompt the user to enter a valid phone number and send an OTP via Firebase Authentication within 10 seconds.
3. WHEN the user submits a valid OTP, THE App SHALL authenticate the user and create a Firestore user document if one does not already exist for that uid.
4. IF the user submits an incorrect OTP, THEN THE App SHALL display an error message and allow the user to request a new OTP after a 60-second cooldown.
5. IF the OTP is not submitted within 5 minutes of issuance, THEN THE App SHALL invalidate the OTP and require the user to request a new one.
6. WHEN a user selects Google OAuth, THE App SHALL initiate the Google sign-in flow via Firebase Authentication and, upon success, create or retrieve the corresponding Firestore user document.
7. WHEN a user selects Facebook OAuth, THE App SHALL initiate the Facebook sign-in flow via Firebase Authentication and, upon success, create or retrieve the corresponding Firestore user document.
8. IF a Firebase Authentication error occurs during any sign-in method, THEN THE App SHALL display a descriptive error message and allow the user to retry without losing entered data.
9. WHEN a new user successfully authenticates for the first time, THE App SHALL navigate the user to the Onboarding interest-selection screen.
10. WHEN a returning user successfully authenticates, THE App SHALL navigate the user directly to the Daily Plug Feed.
11. THE System SHALL enforce Firebase App Check on all Firestore and Firebase Storage requests to ensure only the official Pedi app can access backend resources.

### Requirement 2: Interest-Based Onboarding ("Select Your Form")

**User Story:** As a new user, I want to select my interests from visual category cards during onboarding, so that my Daily Plug Feed is personalised to what I love from the very first session.

#### Acceptance Criteria

1. WHEN a new user reaches the Onboarding screen, THE App SHALL display at least 7 interest category cards with high-quality visuals and Sheng/Swahili category names: Sherehe, Tembea Kenya, Foodie/Mnyama, Culture and Art, Sporty, Matatu Culture, and Music.
2. THE App SHALL require the user to select a minimum of 3 interest cards before the "Continue" button becomes active.
3. WHEN the user taps an interest card, THE App SHALL visually highlight the selected card with a primary colour border and a checkmark indicator.
4. WHEN the user taps a highlighted interest card a second time, THE App SHALL deselect it and remove the visual highlight.
5. WHEN the user taps "Continue" after selecting 3 or more interest cards, THE App SHALL store the selected categories as an array in the user's Firestore document under the preferences field.
6. WHEN the user taps "Continue" after selecting 3 or more interest cards, THE App SHALL initialise the preferenceWeights map in the user's Firestore document with equal weight values for each selected category.
7. WHEN onboarding is complete, THE App SHALL navigate the user to the Daily Plug Feed and seed the initial feed using the stored preferences.
8. IF the user attempts to proceed with fewer than 3 interest cards selected, THEN THE App SHALL display an inline message stating that at least 3 interests must be selected.

### Requirement 3: Daily Plug Feed (Hero Feature)

**User Story:** As a user, I want a full-screen vertical swipe feed of Gems personalised to my interests, so that I can discover new Kenyan experiences every time I open the app.

#### Acceptance Criteria

1. WHEN the user opens the App and is authenticated, THE App SHALL display the Daily Plug Feed as the default home screen with a full-screen vertical swipe layout.
2. THE App SHALL display each Gem as a full-screen card occupying 100% of the viewport, showing either an auto-playing video or a high-resolution image.
3. WHEN the user swipes upward, THE App SHALL transition to the next Gem in the feed with a smooth vertical scroll animation.
4. WHEN the user swipes downward, THE App SHALL transition to the previous Gem in the feed.
5. THE App SHALL display a right-side overlay on each Gem card containing: the creator's circular profile picture, a Vouch button with count, a Comment button with count, a Share button, and a Map Pin button.
6. WHEN the user double-taps a Gem card, THE App SHALL register a Vouch vote for that Gem, subject to Proof of Presence rules defined in Requirement 5.
7. THE App SHALL display a fixed Facebook-style Navy Blue header at the top of the feed screen containing the Pedi logo, a search icon, and a notification bell icon.
8. THE App SHALL display a bottom tab navigation bar with five tabs: Home (Feed), Explore, Upload, Notifications, and Profile.
9. WHEN a video Gem is displayed, THE App SHALL auto-play the video with sound off by default and loop it while it is the active full-screen card.
10. WHEN the user navigates away from a video Gem, THE App SHALL pause the video to conserve device resources.
11. THE Feed Algorithm SHALL order Gems in the feed based on a weighted score combining the user's preferenceWeights, Gem recency, Gem vouchCount, and proximity to the user's current location.
12. WHEN the user has viewed 10 consecutive Gems, THE App SHALL trigger a background call to the Feed Algorithm to pre-fetch the next batch of Gems.
13. WHERE the user has enabled location permissions, THE App SHALL display proximity alerts as push notifications when a new Gem matching the user's preferences is posted within 5 kilometres of the user's current location.
14. WHEN the current month is December, THE Feed Algorithm SHALL increase the weight of Gems tagged with coastal or upcountry categories for users whose location history includes those regions.
15. THE App SHALL display a "Limited Time Form" indicator badge on Gems where isLimitedTime is true, showing the remaining time until expiry.
16. WHEN a Limited Time Form Gem's expiresAt timestamp is reached, THE System SHALL set the Gem's status to "removed" and THE App SHALL no longer display it in the feed.

### Requirement 4: Gem Upload (User-Generated Content)

**User Story:** As a user, I want to upload a Gem with a photo or video, GPS location, and descriptive details, so that I can share hidden spots and experiences with the Pedi community.

#### Acceptance Criteria

1. WHEN the user taps the Upload tab in the bottom navigation, THE App SHALL open the Gem upload screen.
2. THE App SHALL require the user to attach either a short video (maximum 60 seconds) or a high-resolution image before the upload can be submitted.
3. THE App SHALL require the user to provide a title of between 3 and 80 characters before the upload can be submitted.
4. THE App SHALL require the user to select at least one category tag from the defined list before the upload can be submitted.
5. THE App SHALL require the user to provide a description of between 10 and 500 characters before the upload can be submitted.
6. THE App SHALL auto-detect the user's current GPS coordinates and pre-populate the location field when the user opens the upload screen and location permission is granted.
7. THE App SHALL allow the user to manually adjust the auto-detected location by tapping a map pin interface and dragging the pin to the correct position.
8. WHEN the user attempts to submit a Gem upload, THE System SHALL validate that the user's current GPS coordinates are within 500 metres of the selected Gem location.
9. IF the user's GPS coordinates are more than 500 metres from the selected Gem location at submission time, THEN THE App SHALL reject the upload and display a message stating that the user must be within 500 metres of the location to upload a Gem.
10. THE App SHALL allow the user to optionally provide a price range selection from: free, cheap, mid, or high.
11. THE App SHALL allow the user to optionally provide opening hours as a text field.
12. THE App SHALL allow the user to optionally attach an audio or music track to the Gem.
13. THE App SHALL allow the user to optionally mark a Gem as a Limited Time Form, which sets isLimitedTime to true and expiresAt to 24 hours from the upload timestamp.
14. WHEN the user submits a valid Gem upload, THE App SHALL upload the media file to Firebase Storage and store the returned mediaUrl in the Gem's Firestore document.
15. WHEN a Gem is successfully created in Firestore, THE System SHALL increment the user's gemsUploaded stat and award 20 Pedi Points to the uploader's stats.points field via a Cloud Function.
16. IF the media file upload to Firebase Storage fails, THEN THE App SHALL display an error message and retain all entered form data so the user can retry without re-entering information.
17. THE App SHALL display an upload progress indicator while the media file is being transferred to Firebase Storage.

### Requirement 5: The Vibe-Meter (Voting and Verification System)

**User Story:** As a user, I want to Vouch for or Cap a Gem based on my real-world experience, so that the community can trust the quality and authenticity of shared locations.

#### Acceptance Criteria

1. THE App SHALL display a Vouch button and a Cap button on each Gem's detail view and feed overlay.
2. WHEN the user taps the Vouch button, THE System SHALL verify that the user's current GPS coordinates are within 500 metres of the Gem's GeoPoint before recording the vote.
3. IF the user's GPS coordinates are more than 500 metres from the Gem's GeoPoint when tapping Vouch, THEN THE App SHALL display a message stating that Vouching requires Proof of Presence within 500 metres of the location.
4. WHEN a valid Vouch is submitted, THE System SHALL create a vote document in the Gem's votes subcollection with voteType "vouch" and proofOfPresence set to true, and increment the Gem's vouchCount by 1 via a Firestore transaction.
5. WHEN a valid Vouch is submitted, THE System SHALL award 5 Pedi Points to the vouching user's stats.points field via a Cloud Function.
6. WHEN the user taps the Cap button, THE System SHALL record a vote document in the Gem's votes subcollection with voteType "cap" and increment the Gem's capCount by 1 via a Firestore transaction.
7. THE System SHALL prevent a user from submitting more than one Vouch or one Cap vote per Gem per user account.
8. IF a user has already voted on a Gem, THEN THE App SHALL display the user's existing vote state on the Vouch and Cap buttons and disable re-voting.
9. THE App SHALL display the Vouch button with a Vouch count and the Cap button with a Cap count in real-time, reflecting the current Firestore values.
10. THE App SHALL allow the user to rate a Gem on three vibeDimensions when submitting a Vouch: Authenticity, Funness, and Pocket-Friendliness, each on a scale of 1 to 5.
11. WHEN a Vouch is submitted with vibeDimension ratings, THE System SHALL update the Gem's vibeDimensions averages in Firestore.
12. WHEN a Gem's capCount exceeds 30 percent of its vouchCount and the vouchCount is greater than 10, THE System SHALL automatically set the Gem's isFlagged field to true and status to "under_review" via a Cloud Function.
13. WHEN a Gem's status is set to "under_review", THE App SHALL hide the Gem from the Daily Plug Feed and Explore screens until the status is resolved.
14. WHEN the user double-taps a Gem card in the feed, THE App SHALL attempt to register a Vouch vote, applying the same Proof of Presence validation as a manual Vouch tap.

### Requirement 6: Gem Discovery and Encyclopedia

**User Story:** As a user, I want to browse and search for Gems by category, map location, and filters, so that I can find specific experiences that match my mood and budget.

#### Acceptance Criteria

1. WHEN the user taps the Explore tab, THE App SHALL display a Facebook-style grid and list view of Gems grouped by category.
2. THE App SHALL display the following category sections in the Explore screen: Hidden Gems, Party Spots, Food and Drink, Outdoor Activities, Culture and Art, Sports, Matatu Culture, and Music.
3. THE App SHALL provide a search bar at the top of the Explore screen that queries Gems by title, tags, locationName, and county fields.
4. WHEN the user enters a search query of at least 2 characters, THE App SHALL display matching Gem results within 500 milliseconds.
5. THE App SHALL provide filter controls on the Explore screen allowing the user to filter results by: category, vibeDimensions rating, price range, and proximity radius.
6. WHEN the user applies a proximity filter, THE App SHALL only display Gems whose GeoPoint is within the selected radius of the user's current location.
7. THE App SHALL provide a Map View toggle on the Explore screen that displays Gem locations as pins on an interactive map using GeoPoint data.
8. WHEN the user taps a map pin, THE App SHALL display a preview card for that Gem with title, category, vouchCount, and a button to open the full Gem detail view.
9. THE App SHALL display a "Limited Time Form" section at the top of the Explore screen showing only Gems where isLimitedTime is true and expiresAt is in the future.
10. WHEN a Limited Time Form Gem expires, THE App SHALL remove it from the Limited Time Form section in real-time without requiring a manual refresh.
11. THE App SHALL display each Gem's vouchCount, capCount, and vibeDimensions averages on the Gem detail view.
12. THE App SHALL display the Gem creator's display name, rank badge, and profile picture on the Gem detail view.
13. WHEN the user taps the Map Pin button on a Gem in the feed, THE App SHALL open the Map View centred on that Gem's GeoPoint.
