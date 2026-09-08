import { ObjectId } from "mongodb";

export interface PlatformDocument {
  _id: ObjectId;
  userId: ObjectId;
  createdAt: Date;
  updatedAt: Date;
}

export interface ScheduleDocument extends PlatformDocument {
  title: string;
  location?: string;
  dayOfWeek: string;
  startTime: string;
  endTime: string;
  date?: Date;
}

export type ScheduleInput = Omit<ScheduleDocument, "_id" | "userId" | "createdAt" | "updatedAt">;

export interface AnnouncementDocument extends PlatformDocument {
  title: string;
  body: string;
  pinned?: boolean;
  readAt?: Date;
}

export type AnnouncementInput = Omit<
  AnnouncementDocument,
  "_id" | "userId" | "createdAt" | "updatedAt"
>;

export interface AssignmentDocument extends PlatformDocument {
  title: string;
  description?: string;
  subject?: string;
  dueDate: Date;
  isCompleted?: boolean;
  completedAt?: Date;
}

export type AssignmentInput = Omit<
  AssignmentDocument,
  "_id" | "userId" | "createdAt" | "updatedAt"
>;

export interface ReminderDocument extends PlatformDocument {
  title: string;
  body?: string;
  remindAt: Date;
  isDone?: boolean;
  doneAt?: Date;
}

export type ReminderInput = Omit<
  ReminderDocument,
  "_id" | "userId" | "createdAt" | "updatedAt"
>;

export interface NotificationDocument extends PlatformDocument {
  type: string;
  title: string;
  body?: string;
  data?: Record<string, unknown>;
  readAt?: Date;
}

export type NotificationInput = Omit<
  NotificationDocument,
  "_id" | "userId" | "createdAt" | "updatedAt"
>;

export type PlatformInput =
  | ScheduleInput
  | AnnouncementInput
  | AssignmentInput
  | ReminderInput
  | NotificationInput;