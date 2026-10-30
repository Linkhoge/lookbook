# Notes

This is the first version of LookBook. Some parts are still demos or
not finished yet.

## What is there

- Sign up, login and logout using Firebase.
- Home feed with a demo post.
- Profile screens.
- Demo likes, friend requests, hiding posts and blocking.
- A campus challenges section.

## Services added

- Firebase Authentication for signing up, logging in and logging out.
- Demo social state service for likes, friend requests, hiding posts
  and blocking.
- In-app notification service for sending test notifications to the
  banner shown inside the app.

## What needs fixing

- The notification is triggered, but the banner gives an error when
  trying to show it. This still needs fixing.
- Likes and friend requests are only saved for the current session.
- The feed still uses a placeholder image.

## What needs adding

- Uploading clothes and outfit photos.
- Wardrobe and Lookbook screens.
- Saving social interactions to the database.
- More work on the campus challenges.
- More testing on phones and different screen sizes.

## Services added

- demo_social_state.dart — handles the demo likes, friend requests,
  blocking and hiding posts.
- in_app_notification_service.dart — sends notification events to the
  in-app banner. The banner still has a display bug that needs fixing.

## Iteration 2

- Add the GPS tracking system for campus discovery and challenges.