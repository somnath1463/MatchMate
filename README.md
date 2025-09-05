<table>
  <tr>
    <td>
      <img src="https://github.com/user-attachments/assets/c8e37d38-f22b-4243-9f8d-cd41edcebf52#gh-dark-mode-only" width="200" height="406" />
    </td>
    <td>
      <h2>MatchMate</h2>
      <p>A smart matching app with profile cards, accept/decline actions, and more.</p>
    </td>
  </tr>
</table>

## Overview

MatchMate is an iOS app built as part of a coding assignment.
It demonstrates modern SwiftUI architecture, offline persistence with Core Data, and network data fetching with pagination using the https://randomuser.me/api/
 API.

The app displays a list of user profiles and allows the user to accept or decline each match. User actions are stored persistently so decisions remain intact across app launches.

## Features

🔹 Core Functionality
- User List with Pagination
    - Profiles fetched from randomuser.me API.
    - Supports infinite scroll pagination.
    - Continues from last saved page when reopening the app.

- Offline Persistence
    - Profiles are cached in Core Data.
    - Decisions (accept/decline) are preserved across sessions.
    - App loads cached profiles instantly on launch.

- Accept / Decline Actions
  - Users can accept ✅ or decline ❌ a profile.
  - Once a decision is made, buttons are hidden and replaced by a status badge:
    - Green “Accepted”
    - Red “Declined”

- Reset
  - Reset clears all stored profiles and reloads fresh data.


## Architecture & Tech Stack
  - SwiftUI for UI
  - Combine for reactive data binding
  - Core Data for persistence
  - MVVM Architecture
  - AsyncImage for profile images
  - Pagination Handling
  - Offline Sync Service (queue actions if no internet)

## 📂 Project Structure

<img width="747" height="379" alt="Screenshot 2025-09-05 at 10 00 45 PM" src="https://github.com/user-attachments/assets/2781a014-4ece-4877-afc4-f8ed491671ce" />

## 🔧 Installation
  - Clone repo: git clone https://github.com/yourusername/MatchMate.git
  - Open MatchMate.xcodeproj in Xcode.
  - Run on iOS Simulator (iOS 16+ recommended).
## Author
Somnath Mandhare

