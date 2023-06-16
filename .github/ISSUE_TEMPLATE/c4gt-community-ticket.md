---
name: C4GT Community Ticket
about: C4GT Community Ticket
title: C4GT
labels: C4GT Community
assignees: ''

---

## Description
There is a need for a commenting system that will allow users to interact with the blog posts. This will increase user engagement and provide feedback to the blog authors.

## Goals
- [ ] Add a comment section to each blog post
- [ ] Implement a moderation system for comments
- [ ] Ensure comments are tied to a registered user
- [ ] Implement spam and bot protection for the comments
- [ ] Add notification system for new comments

## Expected Outcome
- Users must be registered and logged in to leave a comment.
- Each comment should include the user's name, profile picture (if available), comment text, and timestamp.
- Comments should be displayed in chronological order, with the most recent comment at the top.
- An email notification should be sent to the blog post author when a new comment is made.
- Blog post authors and administrators should be able to moderate comments (approve, deny, delete).

## Acceptance Criteria
- [ ] A registered user can submit a comment on a blog post.
- [ ] The comment appears on the blog post after approval from the post author or administrator.
- [ ] An email notification is sent to the blog post author when a new comment is posted.
- [ ] Comments can be moderated by the blog post author and administrators.
- [ ] Commenting system is resistant to spam and bot attacks.

## Implementation Details
- Leverage Django's built-in commenting framework (if applicable)
- Use JavaScript and AJAX for real-time comment posting and updates
- Consider integrating with a service like Akismet for spam protection
- Use Django's built-in email function for the notification system

## Mockups / Wireframes
(Here, you can link to any visual aids, mockups, wireframes, or diagrams that help illustrate what the final product should look like. This is not always necessary, but can be very helpful in many cases.)

---

### Project
OpenBlog Platform

### Organization Name:
The name of the organization proposing the project.

### Domain
The area of governance the project pertains to (ex: agri, healthcare, ed etc).

### Tech Skills Needed:
Django, Typescript, NextJS, Akismet

### Mentor(s)
@ChakshuGautam @Shruti3004 @sukhpreetssekhon
