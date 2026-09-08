import { PlatformController } from "../controllers/platform.controller.js";

export const platformControllers = {
  schedules: new PlatformController("schedules"),
  announcements: new PlatformController("announcements", { read: true }),
  assignments: new PlatformController("assignments", { done: true }),
  reminders: new PlatformController("reminders", { read: true, done: true }),
  notifications: new PlatformController("notifications", { read: true }),
};