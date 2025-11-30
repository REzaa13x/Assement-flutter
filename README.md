# Donation Application

A complete Flutter application with 12 UI screens for a donation platform, featuring a modern design and complete navigation system.

## Features

- 12 fully implemented UI screens
- Modern, clean design with blue (#2972FF) as primary color
- Responsive UI that works on different screen sizes
- Complete navigation between all screens
- Reusable widgets for consistent design
- Null safety enabled

## Screens Included

1. **HomePage** - Hero banner with donation statistics and navigation
2. **ListCampaignPage** - Grid/list view of donation campaigns
3. **CampaignDetailPage** - Detailed view of a specific campaign
4. **DonationFormPage** - Form for donation information
5. **PaymentSuccessPage** - Success confirmation screen
6. **AboutUsPage** - Information about the platform
7. **HowItWorksPage** - Step-by-step guide on how the platform works
8. **VolunteerPage** - Volunteer recruitment information
9. **StartCampaignPage** - Form to create a new donation campaign
10. **ProfilePage** - User profile information
11. **EditProfilePage** - Form to edit profile information
12. **DonationHistoryPage** - List of user's donation history

## Folder Structure

```
lib/
├── models.dart                 # Data models (Campaign, DonationHistoryItem, User)
├── main.dart                   # Main application entry point with routing
├── pages/                      # All screen widgets
│   ├── home_page.dart
│   ├── list_campaign_page.dart
│   ├── campaign_detail_page.dart
│   ├── donation_form_page.dart
│   ├── payment_success_page.dart
│   ├── about_us_page.dart
│   ├── how_it_works_page.dart
│   ├── volunteer_page.dart
│   ├── start_campaign_page.dart
│   ├── profile_page.dart
│   ├── edit_profile_page.dart
│   └── donation_history_page.dart
└── widgets/                    # Reusable UI components
    └── custom_widgets.dart     # Custom AppBar, CampaignCard, StatCard
```

## How to Run

1. Make sure you have Flutter installed on your system
2. Clone or download this project
3. Navigate to the project directory
4. Run the following commands:

```bash
flutter pub get
flutter run
```

## Dependencies

This project uses only the default Flutter dependencies:
- flutter: sdk: flutter
- cupertino_icons: ^1.0.2
- flutter_lints: ^2.0.0

## Navigation

All screens are connected with proper navigation:
- Named routes are defined in main.dart
- Data is passed between screens using route arguments
- Back navigation is properly implemented
- All buttons navigate to appropriate screens

## Design Elements

- Primary color: Blue (#2972FF)
- Clean, modern UI with appropriate spacing
- Responsive design that adapts to different screen sizes
- Consistent typography and styling
- Card-based layouts for content
- Appropriate use of images from Unsplash
- Proper use of icons for visual cues

## Notes

- This is a UI-only implementation (no backend integration)
- All form submissions show appropriate feedback
- Dummy data is used throughout the application
- Image URLs are from Unsplash and are safe to use
- The application follows Flutter best practices