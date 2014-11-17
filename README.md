what_when
=========

- A wrapper for Redis sorted sets, the Organizer class can be hooked up to a cron job to tell you what to do, when to do it.
- Redis isn't necessarily the best tool for this, but just wanted to mess with it.

todo
----

- hook this bad boy up to a server and then to Twilio
- ~~add the concept of repetition so reminders can recur every month/year/day, etc.~~
- actually hook up to Heroku dyno running cron
- ~~allow users to toggle recurrences~~
- ~~allow users to delete the reminders~~ can now delete by rank
- add tests _of course of course_!
